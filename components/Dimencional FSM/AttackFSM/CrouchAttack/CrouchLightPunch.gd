class_name CrouchLightPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "lp_crouch"
	hitbox_offset = Vector2(95, 10)
	hitbox_size = Vector2(75, 48)
	damage = 40
	hitstun = 0.20
	knockback = Vector2(150, 0)
	attack_level = "mid"
	can_cancel_self = true

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "punch"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
