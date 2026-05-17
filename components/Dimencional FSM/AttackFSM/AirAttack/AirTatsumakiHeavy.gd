class_name AirTatsumakiHeavy
extends AttackStateBase

@export var travel_speed: float = 420.0
@export var travel_lift: float = -120.0

func _init() -> void:
	animation_name = "tatsu_air_heavy"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "tatsumaki"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, travel_lift)
