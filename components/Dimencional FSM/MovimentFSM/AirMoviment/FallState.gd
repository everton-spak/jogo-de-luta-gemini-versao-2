class_name FallState
extends State

@export_group("Configuração da Queda (Física KOF)")
@export var default_gravity: float = 2900.0
@export var default_horizontal_speed: float = 380.0
@export var landing_state: String = "IdleState"
@export var landing_recovery_frames: int = 2

var _locked_dir: float = 0.0
var _current_gravity: float = 2900.0
var _current_horizontal_speed: float = 380.0
var _jump_type: int = 0
var _landing_timer: int = 0
var _is_landing: bool = false
var _ghost_spawn_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_is_landing = false
	_landing_timer = 0
	_ghost_spawn_timer = 0.0
	
	if query_dict.has("dir_x"):
		_locked_dir = query_dict.get("dir_x", 0.0)
	elif fighter:
		if fighter.velocity.x > 10:
			_locked_dir = 1.0
		elif fighter.velocity.x < -10:
			_locked_dir = -1.0
		else:
			_locked_dir = 0.0
	else:
		_locked_dir = 0.0
		
	_current_gravity = query_dict.get("gravity", default_gravity)
	_current_horizontal_speed = query_dict.get("horizontal_speed", default_horizontal_speed)
	_jump_type = query_dict.get("jump_type", 0)
	
	if fighter:
		if posture: posture.apply("air")
	if anim:
		anim.play("fall")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return
	
	# Landing Recovery pós-queda
	if _is_landing:
		_landing_timer += 1
		fighter.velocity.x = 0.0
		fighter.velocity.y = 0.0
		if _landing_timer >= landing_recovery_frames:
			transition_requested.emit(landing_state, {})
		return

	fighter.velocity.y += _current_gravity * delta
	fighter.velocity.x = _current_horizontal_speed * _locked_dir
	
	# Spawn de ghost durante queda de Super Jump ou Hyper Hop
	if _jump_type == 1 or _jump_type == 3: # SUPER ou HYPER_HOP
		_ghost_spawn_timer += delta
		if _ghost_spawn_timer >= 0.07:
			_ghost_spawn_timer = 0.0
			if vfx: vfx.spawn_ghost("cancel", 0.15)

	if fighter.is_on_floor():
		fighter.velocity.x = 0.0
		fighter.velocity.y = 0.0
		if posture: posture.apply("stand")
		_is_landing = true
		_landing_timer = 0
		if landing_recovery_frames <= 0:
			transition_requested.emit(landing_state, {})

func get_tags() -> Array[String]:
	return ["Air", "Movement"]
