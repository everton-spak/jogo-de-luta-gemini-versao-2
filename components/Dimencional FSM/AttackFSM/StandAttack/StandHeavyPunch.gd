class_name StandHeavyPunch
extends AttackStateBase

func _init() -> void:
	anim_close = "hp_close"
	offset_close = Vector2(78, -65)
	size_close = Vector2(70, 60)
	anim_far = "hp_far"
	offset_far = Vector2(105, -60)
	size_far = Vector2(85, 60)
	damage = 90
	hitstun = 0.34
	knockback = Vector2(300, 0)
	attack_level = "mid"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "punch"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
