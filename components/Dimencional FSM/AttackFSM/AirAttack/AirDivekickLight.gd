class_name AirDivekickLight
extends AttackStateBase

@export var dive_speed_x: float = 350.0
@export var dive_speed_y: float = 700.0

func _init() -> void:
	animation_name = "joudan_air"
	hitbox_offset = Vector2(78, 65)
	hitbox_size = Vector2(90, 75)
	damage = 75
	hitstun = 0.30
	knockback = Vector2(240, 0)
	attack_level = "high"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "divekick"
	strength_dim = "light"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(dive_speed_x * f_dir, dive_speed_y)
