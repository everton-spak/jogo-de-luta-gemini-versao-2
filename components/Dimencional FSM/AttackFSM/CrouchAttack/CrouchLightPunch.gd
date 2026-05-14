class_name CrouchLightPunch
extends State

@export var animation_name: String = "lp_crouch"
@export var recovery_state: String = "CrouchState"

var _launched: bool = false

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "punch"
	strength_dim = "light"

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	if fighter:
		fighter.velocity = Vector2.ZERO
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
		var target = recovery_state if recovery_state != "" else "CrouchState"
		transition_requested.emit(target, {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
