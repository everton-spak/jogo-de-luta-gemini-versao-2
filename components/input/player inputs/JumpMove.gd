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
			
		# RESTAURAÇÃO DE INPUT (Ultimate Forgiveness)
		# Se o jogador apertou um soco/chute no exato frame anterior, ele foi consumido
		# por um Ground Attack. Como agora o jogador pulou, cancelamos o Ground Attack e
		# devolvemos o soco/chute ao buffer para que no próximo frame ele saia como Air Attack!
		if buffer.history:
			buffer.history.restore_last_consumed(50) # 50ms de tolerância (cerca de 3 frames)
			
		# Enviamos "any" para a FSM, forçando-a a achar o seu único nó de Jump
		return {
			"type": "movement",
			"stance": "air",
			"direction": "any", 
			"dir_x": dir_x
		}
		
	return {}
