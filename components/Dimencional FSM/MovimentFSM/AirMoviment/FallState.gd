class_name FallState
extends State

@export_group("Configuração da Queda")
@export var default_gravity: float = 2800.0
@export var default_horizontal_speed: float = 420.0
@export var landing_state: String = "IdleState"

var _locked_dir: float = 0.0
var _current_gravity: float = 2800.0
var _current_horizontal_speed: float = 420.0
var _is_super: bool = false
var _ghost_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_ghost_timer = 0.0
	
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
	_is_super = query_dict.get("is_super", false)
	
	if fighter:
		if posture: posture.apply("air")
	if anim:
		anim.play("fall")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return

	fighter.velocity.y += _current_gravity * delta
	fighter.velocity.x = _current_horizontal_speed * _locked_dir
	
	# Spawn de ghost durante queda de Super Jump
	if _is_super:
		_ghost_timer += delta
		if _ghost_timer >= 0.07:
			_ghost_timer = 0.0
			if vfx: vfx.spawn_ghost("cancel", 0.15)

	# Aterrissagem no chão
	if fighter.is_on_floor():
		fighter.velocity.x = 0.0
		fighter.velocity.y = 0.0
		if posture: posture.apply("stand")
		transition_requested.emit(landing_state, {})

func get_tags() -> Array[String]:
	return ["Air", "Movement", "Airborne"]
