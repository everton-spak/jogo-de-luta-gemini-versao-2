class_name StandLightKick
extends State

func _init() -> void:
	anim_close = "lk_close"
	offset_close = Vector2(65, -55)
	size_close = Vector2(55, 35)
	anim_far = "lk_far"
	offset_far = Vector2(90, -60)
	size_far = Vector2(70, 40)

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "kick"
	strength_dim = "light"
