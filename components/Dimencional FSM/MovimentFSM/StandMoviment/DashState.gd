class_name DashState
extends State

@export_group("Configuração do Forward Dash")
@export var dash_speed: float = 750.0
@export var dash_distance: float = 200.0 
@export var run_state: String = "RunState"

@export_group("Configuração do Backdash")
@export var backdash_speed: float = 550.0
@export var backdash_distance: float = 140.0

@export_group("Curvas de Física")
@export var dash_curve: Curve

var _current_dir: float = 1.0 
var _distance_travelled: float = 0.0
var _current_dash_speed: float = 0.0
var _current_dash_distance: float = 0.0
var _is_backdash: bool = false

func _ready() -> void:
	type_dim = "movement"
	stance_dim = "ground"
	direction_dim = "any"
	recovery_state = "IdleState"
	if not dash_curve:
		dash_curve = PhysicsCurves.create_dash_burst_curve()

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_current_dir = query_dict.get("dir_x", 1.0)
	var direction_type = query_dict.get("dash_dir", "forward")
	_is_backdash = (direction_type == "backward")
	
	if _is_backdash:
		_current_dash_speed = backdash_speed
		_current_dash_distance = backdash_distance
	else:
		_current_dash_speed = dash_speed
		_current_dash_distance = dash_distance
		
	_distance_travelled = 0.0
	
	if fighter:
		var initial_mult = dash_curve.sample_baked(0.0) if dash_curve else 1.0
		fighter.velocity.x = _current_dash_speed * initial_mult * _current_dir
		fighter.velocity.y = 0.0
		if posture: posture.apply("stand")
		
	if anim:
		if not _is_backdash:
			anim.play("dash_forward")
		else:
			anim.play("dash_backward")

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)
	if not fighter: return

	# Velocidade modulada por curva (Arranque explosivo + frenagem no final)
	var progress = clamp(_distance_travelled / max(1.0, _current_dash_distance), 0.0, 1.0)
	var speed_multiplier = dash_curve.sample_baked(progress) if dash_curve else 1.0
	var actual_speed = _current_dash_speed * speed_multiplier

	fighter.velocity.x = actual_speed * _current_dir
	_distance_travelled += actual_speed * _delta

	# Condição de término do dash
	if _distance_travelled >= _current_dash_distance or fighter.is_on_wall():
		fighter.velocity.x = 0.0
		_check_next_state()

func _check_next_state() -> void:
	if _is_backdash:
		transition_requested.emit(recovery_state, {})
		return
		
	var is_holding_forward = false
	var input_comp = fighter.get_component("InputComponent")
	
	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		if sign(current_input.x) == sign(_current_dir) and current_input.x != 0:
			is_holding_forward = true

	if is_holding_forward:
		var run_payload = {"query": {"dir_x": _current_dir}}
		transition_requested.emit(run_state, run_payload)
	else:
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	return ["Dashing", "Ground", "Movement"]
