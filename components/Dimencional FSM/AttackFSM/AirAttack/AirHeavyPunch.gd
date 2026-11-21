class_name AirHeavyPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "hp_air"
	hitbox_offset = Vector2(80, 32)
	hitbox_size = Vector2(85, 72)
	damage = 90
	hitstun = 0.35
	knockback = Vector2(260, 0)
	attack_level = "high"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "punch"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
