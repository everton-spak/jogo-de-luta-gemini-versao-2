class_name AirTatsumakiHeavy
extends AttackStateBase

@export var travel_speed: float = 420.0
@export var travel_lift: float = -120.0

func _init() -> void:
	animation_name = "tatsumaki"
	charge_pause_frame = 2
	hitbox_offset = Vector2(90, -20)
	hitbox_size = Vector2(100, 75)
	damage = 125
	hitstun = 0.42
	knockback = Vector2(420, -360)
	attack_level = "mid"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "tatsumaki"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, travel_lift)
