class_name AIInputComponent
extends Component

# A Inteligência Artificial MENTE para o InputBuffer!
# Em vez de ler o teclado, ela gera direções baseadas na distância do jogador.

func get_movement_direction() -> Vector2:
	# Exemplo: A IA decide andar para a frente sempre
	return Vector2(1, 0) 

func is_action_just_pressed(action_name: String) -> bool:
	# Exemplo: A IA tem 2% de chance de apertar soco a cada frame
	if action_name == "punch" and randf() < 0.02:
		return true
	return false
