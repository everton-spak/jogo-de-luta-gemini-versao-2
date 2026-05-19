class_name StandJoudanLight
extends AttackStateBase

@export var step_speed: float = 80.0
@export var travel_speed: float = 500.0
@export var travel_decel: float = 300.0
@export var travel_anim_frames: int = 4
# Mínimo de physics frames de dash antes do _on_frame_changed STOP poder disparar.
# Evita que o stop ative imediatamente após o launch quando a anim foi avançada
# via charge phase (sai do pause direto no travel_anim_frames).
@export var min_dash_frames: int = 8

var _stopped: bool = false
var _resumed: bool = false
var _frames_since_launch: int = -1 # -1 = ainda não lançou

func _init() -> void:
	animation_name = "joudan_stand"
	charge_pause_frame = 2

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "joudan"
	strength_dim = "light"
	cancel_tier_dim = 3

func _apply_enter_velocity() -> void:
	_stopped = false
	_resumed = false
	_frames_since_launch = -1
	if movement: movement.stop_horizontal()

func _select_and_play_animation() -> void:
	super._select_and_play_animation()
	_connect_frame_changed(_on_frame_changed)

func _during_startup(delta: float) -> void:
	# Se o jogador está segurando pra carregar, não avança no startup —
	# segura o passo até soltar (mesmo antes da anim chegar no charge_pause_frame).
	var btn := _get_charging_button()
	if btn != "" and input and input.is_action_pressed(btn):
		return
	if movement: movement.apply_attack_step(step_speed, delta)

func _on_launch() -> void:
	if attack: attack.enable_hitbox()
	if movement: movement.apply_facing_impulse(travel_speed)
	_frames_since_launch = 0

func _during_active(delta: float) -> void:
	if _frames_since_launch >= 0:
		_frames_since_launch += 1
	if not _stopped:
		if movement: movement.apply_friction(travel_decel, delta)
	elif not _resumed:
		_resumed = true
		if anim: anim.resume()

func _should_end_on_anim_end() -> bool:
	# Enquanto paused (entre pause e resume) suprime a transição
	return not (_stopped and not _resumed)

func _on_frame_changed() -> void:
	if anim and anim.get_current_frame() >= travel_anim_frames:
		# Garante mínimo de dash frames antes do stop. Necessário porque o charge
		# avança a anim até charge_pause_frame; ao soltar, o anim pula direto pro
		# travel_anim_frames e mataria o dash antes dele acontecer.
		if _frames_since_launch >= 0 and _frames_since_launch < min_dash_frames:
			return
		anim.pause()
		if movement: movement.stop_horizontal()
		_stopped = true
		_disconnect_frame_changed(_on_frame_changed)

func exit() -> void:
	super.exit()
	_disconnect_frame_changed(_on_frame_changed)
