class_name JumpMove
extends MoveComponent

func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Ground"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var dir = buffer.input.get_movement_direction()
	
	if dir.y < -0.5:
		# Lemos a direção do eixo X
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
				
		# Detecção de pulo durante Corrida (RunState)
		var from_run: bool = false
		if fighter:
			var sm = fighter.get_component("StateMachine")
			if sm and sm.current_state and sm.current_state.name == "RunState":
				from_run = true
				super_buffered = true
				
		# RESTAURAÇÃO DE INPUT (Ultimate Forgiveness)
		# Se o jogador apertou um soco/chute no exato frame anterior, ele foi consumido
		# por um Ground Attack. Como agora o jogador pulou, cancelamos o Ground Attack e
		# devolvemos o soco/chute ao buffer para que no próximo frame ele saia como Air Attack!
		if buffer.history:
			buffer.history.restore_last_consumed(50) # 50ms de tolerância (cerca de 3 frames)
			
		# Enviamos a query para a FSM com os dados do salto KOF
		return {
			"type": "movement",
			"stance": "air",
			"direction": "any", 
			"dir_x": dir_x,
			"super_buffered": super_buffered,
			"from_run": from_run
		}
		
	return {}
