class_name AirHeavyKick
extends AttackStateBase

func _init() -> void:
	animation_name = "hk_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "heavy"
	cancel_tier_dim = 2 # forte
