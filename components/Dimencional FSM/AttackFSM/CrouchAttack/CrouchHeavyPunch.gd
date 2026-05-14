class_name CrouchHeavyPunch
extends State

@export var animation_name: String = "hp_crouch"
@export var recovery_state: String = "CrouchState"

# Y offset per frame to keep feet exactly on floor (floor contact = y+100, scale_y = 2.3113208)
# Formula: 116.5 - (frame_height_px * 2.3113208 / 2)
const FRAME_Y_OFFSETS: Array[float] = [27.5, 23.0, 14.9, -33.7, -24.5, -23.4, -7.1, 4.4, 18.3]

var _launched: bool = false
var _base_sprite_y: float = 0.0

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "punch"
	strength_dim = "heavy"

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	if fighter:
		fighter.velocity = Vector2.ZERO
		fighter.set_posture_collision("stand")
		_base_sprite_y = fighter.get_sprite_position_y()
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
	if fighter:
		fighter.set_posture_collision("crouch")

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

	if fighter and anim:
		var frame = anim.get_frame()
		if frame < FRAME_Y_OFFSETS.size():
			fighter.set_sprite_position_y(_base_sprite_y + FRAME_Y_OFFSETS[frame])

	if not _launched:
		if state_frames >= startup_frames:
			_launched = true
			if hitbox: hitbox.enable_box()
		return

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		if hitbox: hitbox.disable_box()
		var target = recovery_state if recovery_state != "" else "CrouchState"
		transition_requested.emit(target, {})
