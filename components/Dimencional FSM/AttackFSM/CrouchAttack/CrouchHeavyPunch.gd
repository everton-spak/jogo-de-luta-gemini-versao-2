class_name CrouchHeavyPunch
extends AttackStateBase

# Y offset per frame to keep feet exactly on floor (floor contact = y+100, scale_y = 2.3113208)
# Formula: 116.5 - (frame_height_px * 2.3113208 / 2)
const FRAME_Y_OFFSETS: Array[float] = [27.5, 23.0, 14.9, -33.7, -24.5, -23.4, -7.1, 4.4, 18.3]

var _base_sprite_y: float = 0.0

func _init() -> void:
	animation_name = "hp_crouch"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "punch"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte

func _apply_enter_velocity() -> void:
	if fighter:
		fighter.velocity = Vector2.ZERO
		fighter.set_posture_collision("stand")
		_base_sprite_y = fighter.get_sprite_position_y()
		_apply_frame_offset(0)
	_connect_frame_changed(_on_frame_changed)

func exit() -> void:
	super.exit()
	_disconnect_frame_changed(_on_frame_changed)
	if fighter:
		fighter.set_posture_collision("crouch")

func _on_frame_changed() -> void:
	if anim:
		_apply_frame_offset(anim.get_current_frame())

func _apply_frame_offset(frame: int) -> void:
	if fighter and frame < FRAME_Y_OFFSETS.size():
		fighter.set_sprite_position_y(_base_sprite_y + FRAME_Y_OFFSETS[frame])
