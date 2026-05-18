class_name InputBuffer
extends Component

# Referências aos sub-componentes
var history: InputHistoryComponent
var interpreter: DirectionalInterpreterComponent
var motions: MotionInterpreterComponent
var charge: ChargeTrackerComponent
var simultaneous: SimultaneousInterpreterComponent
var input: Component

# Última query detectada (para debug)
var last_query: Dictionary = {}

# Debounce direcional: evita registrar transições de 1 frame ao soltar diagonais
var _pending_dir: String = ""
var _pending_dir_start_ms: int = 0
var _last_added_dir: String = ""
# ~2 frames a 60fps; impede que o "F" de 1 frame ao soltar DF vire Hadoken acidental
const MIN_DIR_HOLD_MS: int = 33

func _on_initialized() -> void:
	history = get_component("InputHistoryComponent")
	interpreter = get_component("DirectionalInterpreterComponent")
	motions = get_component("MotionInterpreterComponent")
	charge = get_component("ChargeTrackerComponent")
	simultaneous = get_component("SimultaneousInterpreterComponent")
	input = get_component("InputComponent")

# IMPORTANTE: chamado EXPLICITAMENTE por Fighter._physics_process antes do FSM rodar.
# Não usamos _process (Godot) porque _process roda DEPOIS de _physics_process no mesmo
# frame — isso fazia consume_action falhar (buffer ainda não tinha o input quando o FSM
# tentava consumir). Capturar aqui garante: capture → check_special_moves → physics_update.
func capture(_delta: float) -> void:
	if not input or not history: return

	# 1. Captura Botões de Ação (Just Pressed e Just Released para Negative Edge)
	for action in motions.ACTION_BUTTONS:
		if input.is_action_just_pressed(action):
			history._add_to_buffer(action)
		if input.is_action_just_released(action):
			history._add_to_buffer(action + "_up")

	# 2. Captura Direcionais com debounce mínimo
	# Direcionais precisam ser segurados por MIN_DIR_HOLD_MS antes de entrar no buffer.
	# Isso evita que "F" de 1 frame (ao soltar DF liberando uma tecla por vez)
	# complete acidentalmente uma sequência de Hadoken.
	var dir_string = interpreter.get_direction_string()
	var now = Time.get_ticks_msec()

	if dir_string != _pending_dir:
		_pending_dir = dir_string
		_pending_dir_start_ms = now
	elif (now - _pending_dir_start_ms) >= MIN_DIR_HOLD_MS and dir_string != _last_added_dir:
		history._add_to_buffer(dir_string)
		_last_added_dir = dir_string

# --- SISTEMA DE BUSCA RECURSIVA ---

func check_special_moves(current_state_tags: Array[String] = []) -> Dictionary:
	if current_state_tags == null: return {}
	# Inicia a busca a partir de si mesmo
	var result = _evaluate_moves_recursively(self, current_state_tags)
	if not result.is_empty():
		last_query = result
	return result

func _evaluate_moves_recursively(node_to_search: Node, tags: Array[String]) -> Dictionary:
	# Prioriza os movimentos de pulo para permitir "Instant Air Attacks"
	# (quando o jogador aperta Pulo + Soco no exato mesmo frame)
	var move_list = node_to_search.get_children()
	var ordered_list = []
	
	for child in move_list:
		if child.name == "JumpMove" or child is JumpMove:
			ordered_list.insert(0, child)
		else:
			ordered_list.append(child)
			
	for child in ordered_list:
		# Se for um golpe (MoveComponent ou herdeiro)
		if child is MoveComponent:
			if _check_tags(child, tags):
				var result = child.check_execution_query(self)
				if result and not result.is_empty():
					return {"query": result}
		# Se for uma pasta (Node simples ou organizador com filhos)
		elif child.get_child_count() > 0:
			var nested_result = _evaluate_moves_recursively(child, tags)
			if not nested_result.is_empty():
				return nested_result
				
	return {}

func _check_tags(move: MoveComponent, current_tags: Array[String]) -> bool:
	if move.allowed_tags.is_empty(): return true
	for t in current_tags:
		if t in move.allowed_tags: return true
	return false
