class_name AirLightPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "lp_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "punch"
	strength_dim = "light"
