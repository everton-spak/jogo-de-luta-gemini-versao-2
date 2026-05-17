class_name StandTatsumakiLight
extends State

@export var travel_speed: float = 300.0

func _init() -> void:
	animation_name = "tatsu_light"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "tatsumaki"
	strength_dim = "light"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, 0.0)
