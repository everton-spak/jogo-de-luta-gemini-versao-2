class_name CrouchHeavyKick
extends State

func _init() -> void:
	animation_name = "hk_crouch"

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "kick"
	strength_dim = "heavy"
