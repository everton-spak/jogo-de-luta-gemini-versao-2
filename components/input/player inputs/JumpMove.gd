class_name JumpMove
extends MoveComponent

@export var down_super_buffer_frames: int = 18 # ~300ms @ 60fps

var _down_buffer_frames: int = 0

func _ready() -> void:
	# Tags de solo que autorizam o pulo (exclui Dodge e Dash pra não cancelar o roll).
	allowed_tags = ["Neutral", "Stand", "Run", "Crouching"]

# Rastreia toques rápidos em Baixo por frame de física (sem depender do debounce MIN_DIR_HOLD_MS
# do InputBuffer), garantindo Super Jump / Hyper Hop confiáveis até em taps de 1 frame.
func _physics_process(_delta: float) -> void:
	if _down_buffer_frames > 0:
		_down_buffer_frames -= 1
	if not fighter or not fighter.is_on_floor():
		return
	var input_comp = fighter.get_component("InputComponent")
	if not input_comp:
		return
	var dir: Vector2 = input_comp.get_movement_direction()
	if dir.y > 0.5 or input_comp.is_action_pressed("down") or input_comp.is_action_just_pressed("down"):
		_down_buffer_frames = down_super_buffer_frames

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Só pode pular se o lutador estiver no chão
	if not fighter or not fighter.is_on_floor():
		return {}

	var dir: Vector2 = buffer.input.get_movement_direction()

	if dir.y < -0.5:
		var dir_x: float = 0.0
		if dir.x > 0.5:
			dir_x = 1.0
		elif dir.x < -0.5:
			dir_x = -1.0

		# Detecção de Super Jump / Hyper Hop via toque prévio em Baixo (D, DB, DF)
		var super_buffered: bool = (_down_buffer_frames > 0)
		var down_from_history: bool = false
		if buffer.history:
			if buffer.history.is_action_buffered("D", 300) or buffer.history.is_action_buffered("DB", 300) or buffer.history.is_action_buffered("DF", 300):
				super_buffered = true
				down_from_history = true

		# Detecção de pulo vindo de Corrida (RunState)
		# Obs: root_fsm.current_state é a pasta de topo (ex: MovementStateMachine),
		# então precisamos descer até o estado folha ativo para saber se é RunState.
		var from_run: bool = false
		var root_fsm = fighter.get("root_fsm")
		if root_fsm and root_fsm.has_method("get_active_leaf"):
			var leaf = root_fsm.get_active_leaf()
			if leaf and leaf.name == "RunState":
				from_run = true
				super_buffered = true
				if dir_x == 0.0 and "_current_dir" in leaf:
					dir_x = float(leaf.get("_current_dir"))

		# RESTAURAÇÃO DE INPUT (Ultimate Forgiveness) antes de limpar D/DB/DF
		if buffer.history:
			buffer.history.restore_last_consumed(50)

		# Consome o buffer de Baixo usado neste pulo para não vazar para o pulo seguinte
		_down_buffer_frames = 0
		if down_from_history and buffer.history:
			buffer.history.consume_all_action("D")
			buffer.history.consume_all_action("DB")
			buffer.history.consume_all_action("DF")

		return {
			"type": "movement",
			"stance": "air",
			"direction": "any",
			"dir_x": dir_x,
			"super_buffered": super_buffered,
			"from_run": from_run
		}

	return {}
