class_name CrouchMove
extends MoveComponent

func _ready() -> void:
	# Só podemos agachar se já estivermos no chão
	if allowed_tags.is_empty():
		allowed_tags = ["Ground", "Neutral"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Pegamos o vetor do direcional
	var dir = buffer.input.get_movement_direction()
	
	# No Godot 2D, Y positivo significa para baixo
	if dir.y > 0.5:
		return {
			"type": "movement",
			"stance": "crouch",
			"direction": "any", # Aceita Baixo, Diagonal-Frente e Diagonal-Trás
			"dir_x": 0.0
		}
		
	return {}
