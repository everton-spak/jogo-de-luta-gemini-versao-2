class_name StandJoudanLight
extends AttackStateBase

@export var step_speed: float = 80.0
@export var travel_speed: float = 500.0
@export var travel_decel: float = 300.0
@export var travel_anim_frames: int = 4

var _stopped: bool = false
var _resumed: bool = false

func _init() -> void:
	animation_name = "joudan_stand"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "joudan"
	strength_dim = "light"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	_stopped = false
	_resumed = false
	if movement: movement.stop_horizontal()

func _select_and_play_animation() -> void:
	super._select_and_play_animation()
	_connect_frame_changed(_on_frame_changed)

func _during_startup(delta: float) -> void:
	if movement: movement.apply_attack_step(step_speed, delta)

func _on_launch() -> void:
	if attack: attack.enable_hitbox()
	if movement: movement.apply_facing_impulse(travel_speed)

func _during_active(delta: float) -> void:
	if not _stopped:
		if movement: movement.apply_friction(travel_decel, delta)
	elif not _resumed:
		_resumed = true
		if anim: anim.resume()

func _should_end_on_anim_end() -> bool:
	# Enquanto paused (entre pause e resume) suprime a transição
	return not (_stopped and not _resumed)

func _on_frame_changed() -> void:
	if anim and anim.get_current_frame() >= travel_anim_frames:
		anim.pause()
		if movement: movement.stop_horizontal()
		_stopped = true
		_disconnect_frame_changed(_on_frame_changed)

func exit() -> void:
	super.exit()
	_disconnect_frame_changed(_on_frame_changed)
