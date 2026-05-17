class_name AirDivekickHeavy
extends State

@export var dive_speed_x: float = 500.0
@export var dive_speed_y: float = 900.0

func _init() -> void:
	animation_name = "joudan_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "divekick"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(dive_speed_x * f_dir, dive_speed_y)
