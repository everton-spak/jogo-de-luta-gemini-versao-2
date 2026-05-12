class_name CrouchTatsumakiLight
extends State

@export var animation_name: String = "tatsu_crouch_light"
@export var travel_speed: float = 300.0

func _ready() -> void:
	type_dim = "tatsumaki"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, 0.0)
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if movement:
		movement.commit_movement()

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		transition_requested.emit("IdleState", {})
