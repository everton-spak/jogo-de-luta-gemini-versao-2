class_name CrouchHadoukenHeavy
extends ProjectileAttackState

func _init() -> void:
	animation_name = "hadouken_crouch"
	proj_speed = 650.0
	proj_damage = 15
	proj_hitstun = 0.45
	proj_knockback = Vector2(280, -80)

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "hadouken"
	strength_dim = "heavy"
	cancel_tier_dim = 3
