class_name AirHeavyKick
extends State

func _init() -> void:
	animation_name = "hk_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "heavy"
