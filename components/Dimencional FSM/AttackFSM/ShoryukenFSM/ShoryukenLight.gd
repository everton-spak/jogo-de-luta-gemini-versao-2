class_name ShoryukenLight
extends State

@export var animation_name: String = "shoryuken"
@export var velocity_x: float = 80.0
@export var velocity_y: float = -900.0

func _ready() -> void:
	type_dim = "shoryuken"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(velocity_x * f_dir, velocity_y)
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	# A gravidade e a aterrissagem são gerenciados pelo ShoryukenFSM pai
