class_name WakeupState
extends State

# Fase LEVANTANDO: aplica i-frames via BoxComponent.start_invuln no hurtbox
# (e throw_hurtbox se existir). Anim e duração variam pelo wakeup_type que
# o GroundedState escolheu (quick/back/no_tech).

@export_group("Animações por tipo")
@export var anim_quick: String = "wakeup_quick"
@export var anim_back: String = "wakeup_back"
@export var anim_no_tech: String = "wakeup_no_tech"

@export_group("Duração da animação por tipo (frames)")
@export var quick_duration_frames: int = 14
@export var back_duration_frames: int = 18
@export var no_tech_duration_frames: int = 22

@export_group("Janela de i-frames por tipo (frames)")
@export var quick_invuln_frames: int = 6
@export var back_invuln_frames: int = 10
@export var no_tech_invuln_frames: int = 14

@export_group("Back rise")
# Velocidade horizontal pra trás aplicada no back rise (recua do oponente).
@export var back_rise_velocity: float = 200.0

var _wakeup_type: String = "quick"
var _total_frames: int = 14

func _ready() -> void:
	type_dim = "wakeup"
	stance_dim = "ground"
	cancel_tier_dim = 5
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	_wakeup_type = str(payload.get("wakeup_type", "quick"))

	# Resolve anim, duração e invul pelo tipo escolhido.
	var anim_name: String
	var invul_frames: int
	match _wakeup_type:
		"back":
			anim_name = anim_back
			_total_frames = back_duration_frames
			invul_frames = back_invuln_frames
			if fighter:
				var f_dir: float = facing.current_facing if facing else 1.0
				fighter.velocity.x = -back_rise_velocity * f_dir
		"no_tech":
			anim_name = anim_no_tech
			_total_frames = no_tech_duration_frames
			invul_frames = no_tech_invuln_frames
		_:
			anim_name = anim_quick
			_total_frames = quick_duration_frames
			invul_frames = quick_invuln_frames

	# I-frames via BoxComponent.start_invuln (frames → segundos).
	var invul_sec: float = invul_frames / 60.0
	if hurtbox:
		hurtbox.start_invuln(invul_sec, "wakeup_" + _wakeup_type)
	# Throw hurtbox também — wakeup invul cobre tanto strike quanto throw.
	if fighter:
		var thb = fighter.get_component("ThrowHurtboxComponent")
		if thb:
			thb.start_invuln(invul_sec, "wakeup_" + _wakeup_type)

	if anim:
		anim.play(anim_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Mantém colado no chão.
	if fighter.is_on_floor():
		fighter.velocity.y = 0.0

	# Friction horizontal só pra back rise não voar pra sempre.
	if _wakeup_type == "back":
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 800.0 * delta)

	if state_frames >= _total_frames:
		transition_requested.emit(_resolve_recovery_state(), {})

func get_tags() -> Array[String]:
	# Tag "Invincible" enquanto a janela de invul do hurtbox está ativa.
	# Outros sistemas (AI, cancel rules) podem ler isso.
	var tags: Array[String] = ["Knockdown", "Waking"]
	if hurtbox and hurtbox.is_invuln():
		tags.append("Invincible")
	return tags
