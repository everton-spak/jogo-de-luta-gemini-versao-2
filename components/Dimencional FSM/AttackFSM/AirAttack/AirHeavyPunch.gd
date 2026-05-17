class_name AirHeavyPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "hp_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "punch"
	strength_dim = "heavy"
