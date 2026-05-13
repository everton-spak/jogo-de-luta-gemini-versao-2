class_name StandJoudanHeavy
extends State

@export var animation_name: String = "joudan_stand"
@export var travel_speed: float = 700.0

var _launched: bool = false

func _ready() -> void:
	type_dim = "joudan"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	fighter.velocity.x = 0.0
	_setup_hitbox()
	if hitbox:
		hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _launched:
		fighter.velocity.x = 0.0
		if state_frames >= startup_frames:
			_launched = true
			var f_dir = facing.current_facing if facing else 1.0
			fighter.velocity.x = travel_speed * f_dir
			if hitbox: hitbox.enable_box()
		return

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		fighter.velocity.x = 0.0
		if hitbox: hitbox.disable_box()
		transition_requested.emit("IdleState", {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()

func get_tags() -> Array[String]:
	return ["Attacking", "Grounded", "Cancellable"]
