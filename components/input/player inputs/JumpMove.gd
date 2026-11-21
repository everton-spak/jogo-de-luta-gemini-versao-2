class_name JumpMove
extends MoveComponent

func _ready() -> void:
	# Tags de solo que autorizam o pulo (exclui Dodge e Dash pra não cancelar o roll).
	allowed_tags = ["Neutral", "Stand", "Run", "Crouching"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Só pode pular se o lutador estiver no chão
	if not fighter or not fighter.is_on_floor():
		return {}
		
	var dir = buffer.input.get_movement_direction()
	
	if dir.y < -0.5:
		var dir_x = 0.0
		if dir.x > 0.5:
			dir_x = 1.0
		elif dir.x < -0.5:
			dir_x = -1.0
			
		# Detecção de Super Jump / Hyper Hop via toque prévio em Baixo (D, DB, DF)
		var super_buffered: bool = false
		if buffer.history:
			if buffer.history.is_action_buffered("D", 300) or buffer.history.is_action_buffered("DB", 300) or buffer.history.is_action_buffered("DF", 300):
				super_buffered = true
				
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
				
		# RESTAURAÇÃO DE INPUT (Ultimate Forgiveness)
		if buffer.history:
			buffer.history.restore_last_consumed(50)
			
		return {
			"type": "movement",
			"stance": "air",
			"direction": "any", 
			"dir_x": dir_x,
			"super_buffered": super_buffered,
			"from_run": from_run
		}
		
	return {}
