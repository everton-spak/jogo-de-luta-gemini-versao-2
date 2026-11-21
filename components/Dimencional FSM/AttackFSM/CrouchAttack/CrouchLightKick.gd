class_name CrouchLightKick
extends AttackStateBase

func _init() -> void:
	animation_name = "lk_crouch"
	hitbox_offset = Vector2(105, 95)
	hitbox_size = Vector2(90, 45)
	damage = 45
	hitstun = 0.22
	knockback = Vector2(165, 0)
	attack_level = "low"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "kick"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
