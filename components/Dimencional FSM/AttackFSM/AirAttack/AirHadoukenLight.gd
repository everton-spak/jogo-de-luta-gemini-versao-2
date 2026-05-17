class_name AirHadoukenLight
extends ProjectileAttackState

func _init() -> void:
	animation_name = "hadouken_air"
	proj_speed_y = 280.0

func _ready() -> void:
	stance_dim = "air"
	type_dim = "hadouken"
	strength_dim = "light"
	cancel_tier_dim = 3
	spawn_marker_alt = "ProjectileSpawnAir"
