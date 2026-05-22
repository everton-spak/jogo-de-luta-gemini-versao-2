class_name CrouchLightPunch
extends AttackStateBase

func _init() -> void:
	animation_name = "lp_crouch"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "punch"
	strength_dim = "light"
	cancel_tier_dim = 1 # fraco
