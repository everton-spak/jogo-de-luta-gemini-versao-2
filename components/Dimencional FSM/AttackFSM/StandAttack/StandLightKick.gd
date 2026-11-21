class_name StandLightKick
extends AttackStateBase

func _init() -> void:
	anim_close = "lk_close"
	offset_close = Vector2(75, -25)
	size_close = Vector2(65, 48)
	anim_far = "lk_far"
	offset_far = Vector2(98, -30)
	size_far = Vector2(85, 50)
	damage = 50
	hitstun = 0.24
	knockback = Vector2(180, 0)
	attack_level = "mid"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "kick"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
