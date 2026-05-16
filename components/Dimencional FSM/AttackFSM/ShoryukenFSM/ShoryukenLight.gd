class_name ShoryukenLight
extends State

@export var animation_name: String = "shoryuken"
@export var ground_distance: float = 80.0
@export var ground_velocity_x: float = 250.0
@export var ground_anim_frames: int = 2
@export var velocity_y: float = -900.0

var _launched: bool = false
var _launched_up: bool = false
var _start_x: float = 0.0

func _ready() -> void:
	type_dim = "shoryuken"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	_launched_up = false
	var f_dir = facing.current_facing if facing else 1.0
	_start_x = fighter.global_position.x
	fighter.velocity = Vector2(ground_velocity_x * f_dir, 0.0)
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		anim.play(animation_name)
		if anim.sprite and not anim.sprite.frame_changed.is_connected(_on_frame_changed):
			anim.sprite.frame_changed.connect(_on_frame_changed)

func _on_frame_changed() -> void:
	if anim and anim.get_current_frame() >= ground_anim_frames:
		anim.pause()
		if anim.sprite and anim.sprite.frame_changed.is_connected(_on_frame_changed):
			anim.sprite.frame_changed.disconnect(_on_frame_changed)

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

	var dist = abs(fighter.global_position.x - _start_x)

	if not _launched_up:
		if fighter.is_on_floor():
			fighter.velocity.y = 0.0

		if dist >= ground_distance:
			_launched_up = true
			fighter.velocity = Vector2(0.0, velocity_y)
			if anim and anim.sprite and anim.sprite.frame_changed.is_connected(_on_frame_changed):
				anim.sprite.frame_changed.disconnect(_on_frame_changed)
			if anim: anim.resume()
		return

	if not _launched and state_frames >= startup_frames:
		_launched = true
		if hitbox: hitbox.enable_box()

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
	if anim and anim.sprite and anim.sprite.frame_changed.is_connected(_on_frame_changed):
		anim.sprite.frame_changed.disconnect(_on_frame_changed)
