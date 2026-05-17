class_name StandHeavyKick
extends AttackStateBase

func _init() -> void:
	anim_close = "hk_close"
	offset_close = Vector2(80, -65)
	size_close = Vector2(65, 45)
	anim_far = "hk_far"
	offset_far = Vector2(110, -70)
	size_far = Vector2(80, 50)

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "kick"
	strength_dim = "heavy"
