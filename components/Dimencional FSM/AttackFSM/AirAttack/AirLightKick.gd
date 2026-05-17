class_name AirLightKick
extends State

func _init() -> void:
	animation_name = "lk_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "light"
