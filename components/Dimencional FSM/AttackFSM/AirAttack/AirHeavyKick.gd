class_name AirHeavyKick
extends State

@export var animation_name: String = "hk_air"

var _launched: bool = false

func _ready() -> void:
	stance_dim = "air"
	type_dim = "kick"
	strength_dim = "heavy"

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

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
