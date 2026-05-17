class_name StandHeavyPunch
extends State

func _init() -> void:
	anim_close = "hp_close"
	offset_close = Vector2(75, -95)
	size_close = Vector2(55, 45)
	anim_far = "hp_far"
	offset_far = Vector2(100, -85)
	size_far = Vector2(70, 50)

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "punch"
	strength_dim = "heavy"
