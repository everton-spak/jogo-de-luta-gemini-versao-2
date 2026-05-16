class_name StandJoudanHeavy
extends State

@export var animation_name: String = "joudan_stand"
@export var step_speed: float = 120.0
@export var travel_speed: float = 700.0
@export var travel_decel: float = 200.0
@export var travel_anim_frames: int = 4
@export var recoil_force: float = 150.0

var _launched: bool = false
var _stopped: bool = false
var _resumed: bool = false

func _ready() -> void:
	type_dim = "joudan"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	_stopped = false
	_resumed = false
	if movement: movement.stop_horizontal()
	_setup_hitbox()
	if hitbox: hitbox.disable_box()
	if anim:
		if anim.sprite and not anim.sprite.frame_changed.is_connected(_on_frame_changed):
			anim.sprite.frame_changed.connect(_on_frame_changed)
		anim.play(animation_name)

func _on_frame_changed() -> void:
	if anim and anim.get_current_frame() >= travel_anim_frames:
		anim.pause()
		if movement: movement.stop_horizontal()
		_stopped = true
		if anim.sprite and anim.sprite.frame_changed.is_connected(_on_frame_changed):
			anim.sprite.frame_changed.disconnect(_on_frame_changed)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	# Startup: pequeno avanço antes do golpe
	if not _launched:
		if movement: movement.apply_attack_step(step_speed, delta)
		if state_frames >= startup_frames:
			_launched = true
			if movement: movement.apply_facing_impulse(travel_speed)
			if hitbox: hitbox.enable_box()
		return

	# Fase de avanço: desliza enquanto animação não chegou no frame limite
	if not _stopped:
		if movement: movement.apply_friction(travel_decel, delta)
		return

	# Retoma animação uma vez após parar
	if not _resumed:
		_resumed = true
		if anim: anim.resume()
		return

	# Espera animação terminar
	if anim and not anim.is_playing():
		if hitbox: hitbox.disable_box()
		if movement: movement.apply_knockback_self(recoil_force)
		transition_requested.emit("IdleState", {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()
	if anim and anim.sprite and anim.sprite.frame_changed.is_connected(_on_frame_changed):
		anim.sprite.frame_changed.disconnect(_on_frame_changed)

func get_tags() -> Array[String]:
	return ["Attacking", "Grounded", "Cancellable"]
