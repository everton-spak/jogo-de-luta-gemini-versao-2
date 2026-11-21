class_name AirLightPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "lp_air"
	damage = 55
	hitstun = 0.26
	knockback = Vector2(180, 0)
	attack_level = "high"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "punch"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
