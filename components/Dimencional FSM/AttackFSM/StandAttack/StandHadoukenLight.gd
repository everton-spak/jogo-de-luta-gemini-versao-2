class_name StandHadoukenLight
extends ProjectileAttackState

func _init() -> void:
	animation_name = "hadouken_stand"
	recovery_time = 0.25

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "hadouken"
	strength_dim = "light"
	cancel_tier_dim = 3
