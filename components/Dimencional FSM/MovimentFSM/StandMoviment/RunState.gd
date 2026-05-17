class_name RunState
extends State

@export_group("Configuração da Corrida")
@export var run_speed: float = 600.0
#@export var recovery_state: String = "IdleState"


var _current_dir: float = 1.0 

func _ready() -> void:
	type_dim = "movement"
	stance_dim = "ground"
	direction_dim = "forward" # Em jogos 2D, geralmente só se corre para frente
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	var query_dict = payload.get("query", {})
	_current_dir = query_dict.get("dir_x", 1.0)
	
	print("🏃 [RunState] Iniciando Corrida! Direção: ", _current_dir)
	
	if fighter:
		fighter.velocity.x = run_speed * _current_dir
		fighter.velocity.y = 0
		
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		anim.play("run") # Certifique-se de que este nome bate com o seu AnimatedSprite2D

func physics_update(_delta: float) -> void:
	if not fighter: return
	
	# 1. Aplica a física contínua
	fighter.velocity.x = run_speed * _current_dir
	


	# 2. Verifica o Input do jogador
	var input_comp = fighter.get_component("InputComponent")
	var is_holding_forward = false
	
	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		
		# Verifica se o jogador AINDA está segurando a direção original da corrida
		# Usamos sign() para ignorar a força de joysticks analógicos, olhando só o lado
		if sign(current_input.x) == sign(_current_dir) and current_input.x != 0:
			is_holding_forward = true

	# 3. Condição de Saída Dupla: 
	# Soltou o botão OU bateu no canto da tela
	if not is_holding_forward or fighter.is_on_wall():
		fighter.velocity.x = 0 
		transition_requested.emit(recovery_state, {})
