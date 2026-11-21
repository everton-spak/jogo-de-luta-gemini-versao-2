class_name CrouchHeavyKick
extends AttackStateBase

func _init() -> void:
	animation_name = "hk_crouch"
	hitbox_offset = Vector2(115, 95)
	hitbox_size = Vector2(105, 48)
	damage = 90
	hitstun = 0.36
	knockback = Vector2(220, -360)
	attack_level = "low"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "kick"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
