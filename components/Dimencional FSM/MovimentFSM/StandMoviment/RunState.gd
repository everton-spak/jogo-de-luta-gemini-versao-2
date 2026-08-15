class_name RunState
extends State

@export_group("Configuração da Corrida (Física KOF)")
@export var run_speed: float = 680.0

var _current_dir: float = 1.0 

func _ready() -> void:
	type_dim = "movement"
	stance_dim = "ground"
	direction_dim = "forward"
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_current_dir = query_dict.get("dir_x", 1.0)
	
	if fighter:
		fighter.velocity.x = run_speed * _current_dir
		fighter.velocity.y = 0
		if posture: posture.apply("stand")
		
	if anim:
		anim.play("run")

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)
	if not fighter: return
	
	# 1. Aplica a física contínua
	fighter.velocity.x = run_speed * _current_dir

	# 2. Verifica o Input do jogador
	var input_comp = fighter.get_component("InputComponent")
	var is_holding_forward = false
	
	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		if sign(current_input.x) == sign(_current_dir) and current_input.x != 0:
			is_holding_forward = true

	# 3. Condição de Saída: Soltou o botão OU bateu na parede
	if not is_holding_forward or fighter.is_on_wall():
		fighter.velocity.x = 0 
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	return ["Ground", "Movement", "Run"]
