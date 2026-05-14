class_name StandLightKick
extends State

@export var recovery_state: String = "IdleState"

@export_group("Close")
@export var anim_close: String = "lk_close"
@export var offset_close: Vector2 = Vector2(65, -55)
@export var size_close: Vector2 = Vector2(55, 35)

@export_group("Far")
@export var anim_far: String = "lk_far"
@export var offset_far: Vector2 = Vector2(90, -60)
@export var size_far: Vector2 = Vector2(70, 40)

var _launched: bool = false

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "kick"
	strength_dim = "light"

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	if fighter:
		fighter.velocity = Vector2.ZERO

	var is_near = proximity and proximity.is_target_near
	if is_near:
		hitbox_offset = offset_close
		hitbox_size = size_close
		if anim: anim.play(anim_close)
	else:
		hitbox_offset = offset_far
		hitbox_size = size_far
		if anim: anim.play(anim_far)

	_setup_hitbox()
	if hitbox: hitbox.disable_box()

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

	if not _launched:
		if state_frames >= startup_frames:
			_launched = true
			if hitbox: hitbox.enable_box()
		return

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		if hitbox: hitbox.disable_box()
		var target = recovery_state if recovery_state != "" else "IdleState"
		transition_requested.emit(target, {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
