class_name InputComponent
extends Component

# Este prefixo é o segredo para ter Multiplayer local!
# No Input Map da Godot (Project Settings), você criará ações como:
# "p1_up", "p1_down", "p1_punch" para o Jogador 1.
# "p2_up", "p2_down", "p2_punch" para o Jogador 2.
@export var player_prefix: String = "p1_"

# Retorna a direção pura apertada no D-Pad ou Analógico
func get_movement_direction() -> Vector2:
	# Lemos os eixos diretamente do Input Map da Godot, juntando o prefixo ("p1_") com a direção ("left")
	var x = Input.get_axis(player_prefix + "left", player_prefix + "right")
	var y = Input.get_axis(player_prefix + "up", player_prefix + "down")
	
	# Em jogos de luta (8-way movement), não queremos valores quebrados como 0.3 do analógico.
	# Usamos sign() para forçar os valores a serem sempre -1.0, 0.0 ou 1.0.
	var dir = Vector2(sign(x), sign(y))
	
	return dir

# Verifica se o botão acabou de ser pressionado neste exato frame
func is_action_just_pressed(action_name: String) -> bool:
	return Input.is_action_just_pressed(player_prefix + action_name)

# Verifica se o botão está sendo segurado (útil caso queira criar mecânicas de pulo maior se segurar o botão)
func is_action_pressed(action_name: String) -> bool:
	return Input.is_action_pressed(player_prefix + action_name)
	
# Verifica se o botão acabou de ser solto (útil para golpes de "Negative Edge", como o soco do Balrog/Zato)
func is_action_just_released(action_name: String) -> bool:
	return Input.is_action_just_released(player_prefix + action_name)
