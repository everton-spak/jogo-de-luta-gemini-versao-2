class_name StandHeavyKick
extends AttackStateBase

func _init() -> void:
	anim_close = "hk_close"
	offset_close = Vector2(82, -45)
	size_close = Vector2(75, 55)
	anim_far = "hk_far"
	offset_far = Vector2(115, -45)
	size_far = Vector2(95, 55)
	damage = 95
	hitstun = 0.36
	knockback = Vector2(340, 0)
	attack_level = "mid"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "kick"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
