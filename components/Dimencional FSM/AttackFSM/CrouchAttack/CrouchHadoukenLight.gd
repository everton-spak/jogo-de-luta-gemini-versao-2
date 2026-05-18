class_name CrouchHadoukenLight
extends ProjectileAttackState

func _init() -> void:
	animation_name = "hadouken_crouch"
	charge_pause_frame = 3

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "hadouken"
	strength_dim = "light"
	cancel_tier_dim = 3
