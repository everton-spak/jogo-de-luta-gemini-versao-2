class_name StandHeavyPunch
extends State

@export var recovery_state: String = "IdleState"

@export_group("Close")
@export var anim_close: String = "hp_close"
@export var offset_close: Vector2 = Vector2(75, -95)
@export var size_close: Vector2 = Vector2(55, 45)

@export_group("Far")
@export var anim_far: String = "hp_far"
@export var offset_far: Vector2 = Vector2(100, -85)
@export var size_far: Vector2 = Vector2(70, 50)

var _launched: bool = false

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "punch"
	strength_dim = "heavy"

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
