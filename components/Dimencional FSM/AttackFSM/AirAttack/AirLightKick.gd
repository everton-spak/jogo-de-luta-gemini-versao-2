class_name AirLightKick
extends AttackStateBase

func _init() -> void:
	animation_name = "lk_air"
	hitbox_offset = Vector2(82, 42)
	hitbox_size = Vector2(90, 68)
	damage = 55
	hitstun = 0.26
	knockback = Vector2(180, 0)
	attack_level = "high"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
