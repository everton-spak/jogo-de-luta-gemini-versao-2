class_name AirHeavyKick
extends AttackStateBase

func _init() -> void:
	animation_name = "hk_air"
	hitbox_offset = Vector2(92, 48)
	hitbox_size = Vector2(105, 74)
	damage = 90
	hitstun = 0.35
	knockback = Vector2(260, 0)
	attack_level = "high"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
