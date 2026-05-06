class_name InputBuffer
extends Component

# Referências aos sub-componentes
var history: InputHistoryComponent
var interpreter: DirectionalInterpreterComponent
var motions: MotionInterpreterComponent
var charge: ChargeTrackerComponent
var input: Component

func _on_initialized() -> void:
	history = get_component("InputHistoryComponent")
	interpreter = get_component("DirectionalInterpreterComponent")
	motions = get_component("MotionInterpreterComponent")
	charge = get_component("ChargeTrackerComponent")
	input = get_component("InputComponent")

func _process(_delta: float) -> void:
	if not input or not history: return
	
	# 1. Captura Botões de Ação (Just Pressed e Just Released para Negative Edge)
	for action in motions.ACTION_BUTTONS:
		if input.is_action_just_pressed(action):
			history._add_to_buffer(action)
		if input.is_action_just_released(action):
			history._add_to_buffer(action + "_up")
			
	# 2. Captura Direcionais (Lógica de Neutro "N")
	var dir_string = interpreter.get_direction_string()
	# Só adiciona se for diferente do último input (evita flood de repetidos)
	if history._buffer.is_empty() or history._buffer.back()["input"] != dir_string:
		history._add_to_buffer(dir_string)

# --- SISTEMA DE BUSCA RECURSIVA ---

func check_special_moves(current_state_tags: Array[String] = []) -> Dictionary:
	if current_state_tags == null: return {}
	# Inicia a busca a partir de si mesmo
	return _evaluate_moves_recursively(self, current_state_tags)

func _evaluate_moves_recursively(node_to_search: Node, tags: Array[String]) -> Dictionary:
	for child in node_to_search.get_children():
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
