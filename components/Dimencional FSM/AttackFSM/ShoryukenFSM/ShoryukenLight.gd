class_name ShoryukenLight
extends State

@export var animation_name: String = "shoryuken"
@export var velocity_x: float = 80.0
@export var velocity_y: float = -900.0

var _launched: bool = false

func _ready() -> void:
	type_dim = "shoryuken"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(velocity_x * f_dir, velocity_y)
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _launched and state_frames >= startup_frames:
		_launched = true
		if hitbox: hitbox.enable_box()

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
