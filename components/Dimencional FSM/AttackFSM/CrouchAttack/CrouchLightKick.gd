class_name CrouchLightKick
extends AttackStateBase

func _init() -> void:
	animation_name = "lk_crouch"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "kick"
	strength_dim = "light"
