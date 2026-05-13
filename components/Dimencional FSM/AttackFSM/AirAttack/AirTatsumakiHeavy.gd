class_name AirTatsumakiHeavy
extends State

@export var animation_name: String = "tatsu_air_heavy"
@export var travel_speed: float = 420.0

var _launched: bool = false

func _ready() -> void:
	stance_dim = "air"
	type_dim = "tatsumaki"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(travel_speed * f_dir, -120.0)
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _launched:
		if state_frames >= startup_frames:
			_launched = true
			if hitbox: hitbox.enable_box()
		return

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		if hitbox: hitbox.disable_box()
		transition_requested.emit("FallState", {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
