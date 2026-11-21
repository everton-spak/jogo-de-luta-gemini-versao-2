class_name AirTatsumakiLight
extends AttackStateBase

@export var travel_speed: float = 280.0
@export var travel_lift: float = -100.0

func _init() -> void:
	animation_name = "tatsumaki"
	charge_pause_frame = 2
	hitbox_offset = Vector2(85, -20)
	hitbox_size = Vector2(95, 72)
	damage = 90
	hitstun = 0.36
	knockback = Vector2(340, -280)
	attack_level = "mid"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "tatsumaki"
	strength_dim = "light"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, travel_lift)
