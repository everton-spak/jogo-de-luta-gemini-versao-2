class_name StandJoudanHeavy
extends AttackStateBase

@export var velocity: float = 700.0
@export var distance: float = 220.0
# Frame onde a anim PAUSA (freeze pose) enquanto o personagem ainda avança.
# Não afeta a distância — após atingir `distance`, a anim retoma e toca o resto.
@export var travel_anim_frames: int = 3

var _start_x: float = 0.0
var _stopped: bool = false
var _anim_paused: bool = false

func _init() -> void:
	animation_name = "joudan_stand"
	charge_pause_frame = 2

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "joudan"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	_stopped = false
	_anim_paused = false
	if movement: movement.stop_horizontal()
	if fighter: _start_x = fighter.global_position.x

func _on_launch() -> void:
	if attack: attack.enable_hitbox()
	if movement: movement.apply_facing_impulse(velocity)

func _during_active(_delta: float) -> void:
	if _stopped or not fighter: return

	# Pausa a anim no travel_anim_frames (freeze pose), personagem segue avançando.
	if not _anim_paused and anim != null and anim.get_current_frame() >= travel_anim_frames:
		anim.pause()
		_anim_paused = true

	var traveled: float = abs(fighter.global_position.x - _start_x)
	if traveled >= distance:
		_stopped = true
		if movement: movement.stop_horizontal()
		if anim != null: anim.resume()
		return

	if movement: movement.apply_facing_impulse(velocity)

func _should_end_on_anim_end() -> bool:
	return _stopped
