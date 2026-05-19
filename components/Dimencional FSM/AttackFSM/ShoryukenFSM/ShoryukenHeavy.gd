class_name ShoryukenHeavy
extends State

@export var ground_distance: float = 120.0
@export var ground_velocity_x: float = 300.0
@export var ground_anim_frames: int = 2
@export var velocity_y: float = -1100.0

var _launched_up: bool = false
var _hitbox_active: bool = false
var _start_x: float = 0.0

func _init() -> void:
	animation_name = "shoryuken"
	charge_pause_frame = 2

func _ready() -> void:
	type_dim = "shoryuken"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_reset_charge()
	_launched_up = false
	_hitbox_active = false
	var f_dir = facing.current_facing if facing else 1.0
	_start_x = fighter.global_position.x
	fighter.velocity = Vector2(ground_velocity_x * f_dir, 0.0)
	fighter.set_posture_collision("crouch")
	if attack:
		attack.setup_hitbox(self)
		attack.disable_hitbox()
	if anim: anim.play(animation_name)
	_connect_frame_changed(_on_frame_changed)

func _on_frame_changed() -> void:
	if anim and anim.get_current_frame() >= ground_anim_frames:
		anim.pause()
		_disconnect_frame_changed(_on_frame_changed)

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

	# Motion move: macro-cancel + charge phase antes do fluxo de slide/launch.
	var charging_btn := _get_charging_button()
	if _check_macro(charging_btn):
		return
	if _tick_charge(charging_btn):
		return

	var dist = abs(fighter.global_position.x - _start_x)

	if not _launched_up:
		if fighter.is_on_floor():
			fighter.velocity.y = 0.0

		if dist >= ground_distance:
			_launched_up = true
			fighter.velocity = Vector2(0.0, velocity_y)
			fighter.set_posture_collision("air")
			_disconnect_frame_changed(_on_frame_changed)
			if anim: anim.resume()
		return

	if not _hitbox_active and state_frames >= startup_frames:
		_hitbox_active = true
		if attack: attack.enable_hitbox()

func exit() -> void:
	super.exit()
	if attack: attack.disable_hitbox()
	_disconnect_frame_changed(_on_frame_changed)
