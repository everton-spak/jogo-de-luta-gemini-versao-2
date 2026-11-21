class_name JumpState
extends State

@export_group("Física de Pulo KOF")
@export var prejump_frames: int = 3
@export var normal_jump_force: float = 1920.0
@export var super_jump_force: float = 1980.0
@export var hop_jump_force: float = 1320.0
@export var normal_speed_x: float = 500.0
@export var super_speed_x: float = 810.0
@export var normal_gravity: float = 5600.0
@export var hop_gravity: float = 6200.0
@export var hop_convert_max_air_frames: int = 2
@export var hop_convert_gravity: float = 9200.0
@export var hop_convert_ramp_rate: float = 45000.0
@export var fall_state: String = "FallState"

@export_group("Curvas de Física")
@export var ascent_curve: Curve

var _locked_dir: float = 0.0
var _is_super: bool = false
var _is_hop: bool = false
var _from_run: bool = false
var _in_prejump: bool = true
var _up_released_in_prejump: bool = false
var _hop_converting: bool = false
var _air_frames: int = 0
var _air_time_sec: float = 0.0
var _current_speed_x: float = 500.0
var _current_gravity: float = 5600.0
var _jump_initial_force: float = 1920.0
var _jump_ascent_time: float = 0.34
var _anim_mode: String = "neutral"
var _ghost_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"
	type_dim = "movement"
	if not ascent_curve:
		ascent_curve = PhysicsCurves.create_jump_ascent_curve()

func is_prejump() -> bool:
	return _in_prejump

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict: Dictionary = payload.get("query", {})
	_locked_dir = float(query_dict.get("dir_x", 0.0))
	# _is_super é definido imediatamente no enter() (inclusive durante o pre-jump)
	_is_super = bool(query_dict.get("super_buffered", false))
	_from_run = bool(query_dict.get("from_run", false))
	_is_hop = false
	_in_prejump = prejump_frames > 0
	_up_released_in_prejump = false
	_hop_converting = false
	_air_frames = 0
	_air_time_sec = 0.0
	_ghost_timer = 0.0
	_anim_mode = "neutral"

	if fighter:
		fighter.velocity = Vector2.ZERO
		# Mantém postura "stand" no squat aterrado para não afundar o sprite (+22.75px)
		if posture:
			posture.apply("stand")

	if _in_prejump:
		# Pose de squat pré-pulo (frame 0 de jump_neutral = 41-0.png)
		if anim:
			anim.play("jump_neutral")
			anim.seek_frame(0)
			anim.pause()
	else:
		_perform_liftoff()

func exit() -> void:
	super.exit()
	_in_prejump = false
	_hop_converting = false

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# FASE 1: Pre-jump squat aterrado (3 frames clássicos KOF).
	# Classifica Short/Hyper Hop vs Normal/Super Jump ANTES da decolagem -> zero snap no ar!
	if _in_prejump:
		fighter.velocity = Vector2.ZERO
		if input:
			var cur_input: Vector2 = input.get_movement_direction()
			if cur_input.y >= -0.3:
				_up_released_in_prejump = true
			if absf(cur_input.x) > 0.5:
				_locked_dir = signf(cur_input.x)

		if state_frames > prejump_frames:
			_perform_liftoff()
		return

	# FASE 2: Subida aérea contínua com integração suave de gravidade (zero overwrite de vy)
	_air_frames += 1
	_air_time_sec += delta

	# Conversão suave opcional para taps de teclado levemente mais longos (4-5 frames totais):
	# aumenta a gravidade em rampa suave sem NUNCA cortar ou dar snap em velocity.y.
	if not _is_hop and not _hop_converting and _air_frames <= hop_convert_max_air_frames + 1 and input:
		var air_input: Vector2 = input.get_movement_direction()
		if air_input.y >= -0.3:
			_hop_converting = true
			_is_hop = true

	if _hop_converting:
		_current_gravity = move_toward(_current_gravity, hop_convert_gravity, hop_convert_ramp_rate * delta)
		if movement and movement.has_method("update_active_jump_gravity"):
			movement.update_active_jump_gravity(_current_gravity, true)

	var t_norm: float = clampf(_air_time_sec / maxf(0.01, _jump_ascent_time), 0.0, 1.0)
	var curve_mult: float = ascent_curve.sample_baked(t_norm) if ascent_curve else lerpf(0.95, 1.05, t_norm)

	fighter.velocity.y += _current_gravity * curve_mult * delta
	fighter.velocity.x = _current_speed_x * _locked_dir
	if movement and "active_ascent_time" in movement:
		movement.active_ascent_time = _air_time_sec

	# Rastro de Ghost em Super Jump / Hyper Hop
	if _is_super:
		_ghost_timer += delta
		if _ghost_timer >= 0.05:
			_ghost_timer = 0.0
			if vfx:
				vfx.spawn_ghost("cancel", 0.16)

	# Ápice natural (vy cruza 0.0 suavemente em 1 frame): transiciona para FallState
	if fighter.velocity.y >= 0.0:
		var fall_payload: Dictionary = {
			"query": {
				"dir_x": _locked_dir,
				"horizontal_speed": _current_speed_x,
				"gravity": _current_gravity,
				"is_super": _is_super,
				"is_hop": _is_hop,
				"anim_mode": _anim_mode,
				"preserve_anim": (_anim_mode == "forward" or _anim_mode == "backward")
			}
		}
		transition_requested.emit(fall_state, fall_payload)

func _perform_liftoff() -> void:
	_in_prejump = false
	_air_frames = 1
	_air_time_sec = 0.0
	_is_hop = _up_released_in_prejump

	_current_speed_x = super_speed_x if _is_super else normal_speed_x
	if _is_hop:
		_current_gravity = hop_gravity
		_jump_initial_force = hop_jump_force
	else:
		_current_gravity = normal_gravity
		_jump_initial_force = super_jump_force if _is_super else normal_jump_force
	_jump_ascent_time = _jump_initial_force / maxf(1.0, _current_gravity)

	if fighter:
		fighter.velocity.y = -_jump_initial_force
		fighter.velocity.x = _current_speed_x * _locked_dir
		if posture:
			posture.apply("air")

	# Animação relativa ao facing do lutador (funciona igualmente para P1=+1 e P2=-1)
	var f_dir: float = float(facing.current_facing) if facing else 1.0
	var rel_dir: float = _locked_dir * f_dir
	if rel_dir > 0.1:
		_anim_mode = "forward"
	elif rel_dir < -0.1:
		_anim_mode = "backward"
	else:
		_anim_mode = "neutral"

	if anim:
		if _anim_mode == "forward":
			anim.play("jump_forward", 1.35 if _is_hop else 1.0)
		elif _anim_mode == "backward":
			anim.play_reverse("jump_forward", 1.35 if _is_hop else 1.0)
		else:
			anim.play("jump_neutral", 1.25 if _is_hop else 1.0)
			anim.seek_frame(1)

	# Sincroniza o contexto aéreo no MovementComponent (para AirAttack e FallState pós-ataque)
	if movement and movement.has_method("set_active_jump"):
		var desc_curve: Curve = _resolve_descent_curve()
		var fall_dur: float = _resolve_fall_curve_duration()
		movement.set_active_jump(
			_current_gravity,
			_current_speed_x,
			_locked_dir,
			_is_super,
			_is_hop,
			_anim_mode,
			_jump_ascent_time,
			ascent_curve,
			desc_curve,
			fall_dur
		)

	# Efeito visual de Super Jump / Hyper Hop no momento da decolagem
	if _is_super and vfx:
		vfx.play_flash("cancel", 0.08)
		vfx.spawn_ghost("cancel", 0.2)

func _resolve_descent_curve() -> Curve:
	var p: Node = get_parent()
	if p:
		var fs: Node = p.get_node_or_null(fall_state)
		if fs and "descent_curve" in fs and fs.get("descent_curve") is Curve:
			return fs.get("descent_curve") as Curve
	return PhysicsCurves.create_jump_descent_curve()

func _resolve_fall_curve_duration() -> float:
	var p: Node = get_parent()
	if p:
		var fs: Node = p.get_node_or_null(fall_state)
		if fs and "fall_curve_duration" in fs:
			return float(fs.get("fall_curve_duration"))
	return 0.35

func get_tags() -> Array[String]:
	if _in_prejump:
		return ["Movement"]
	return ["Air", "Movement", "Airborne"]
