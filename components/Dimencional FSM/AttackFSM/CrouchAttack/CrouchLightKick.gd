class_name CrouchLightKick
extends State

func _init() -> void:
	animation_name = "lk_crouch"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "kick"
	strength_dim = "light"
