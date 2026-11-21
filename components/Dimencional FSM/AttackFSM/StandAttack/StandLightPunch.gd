class_name StandLightPunch
extends AttackStateBase

func _init() -> void:
	anim_close = "lp_close"
	offset_close = Vector2(70, -120)
	size_close = Vector2(45, 35)
	anim_far = "lp_far"
	offset_far = Vector2(90, -90)
	size_far = Vector2(60, 38)
	damage = 45
	hitstun = 0.22
	knockback = Vector2(160, 0)
	attack_level = "mid"
	can_cancel_self = true

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "punch"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
