class_name FallState
extends State

@export_group("Configuração da Queda")
@export var default_gravity: float = 2900.0
@export var default_horizontal_speed: float = 500.0
@export var max_fall_speed: float = 2400.0
@export var fall_curve_duration: float = 0.35
@export var landing_state: String = "IdleState"

@export_group("Curvas de Física")
@export var descent_curve: Curve

var _locked_dir: float = 0.0
var _current_gravity: float = 2900.0
var _current_horizontal_speed: float = 500.0
var _is_super: bool = false
var _is_hop: bool = false
var _fall_time_sec: float = 0.0
var _ghost_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"
	if not descent_curve:
		descent_curve = PhysicsCurves.create_jump_descent_curve()

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict: Dictionary = payload.get("query", {})
	var has_active_jump: bool = (movement != null and "has_active_jump" in movement and bool(movement.get("has_active_jump")))
	_ghost_timer = 0.0

	# Gravidade: prioriza payload explícito do JumpState, depois contexto do pulo ativo
	# (ex: retorno de AirAttack -> FallState({})), e por fim default_gravity (ex: Shoryuken).
	if query_dict.has("gravity"):
		_current_gravity = float(query_dict.get("gravity", default_gravity))
	elif has_active_jump:
		_current_gravity = float(movement.get("active_air_gravity"))
	else:
		_current_gravity = default_gravity

	# Velocidade horizontal: preserva exatamente o momentum ao voltar de AirAttack
	if query_dict.has("dir_x") and query_dict.has("horizontal_speed"):
		_locked_dir = float(query_dict.get("dir_x", 0.0))
		_current_horizontal_speed = float(query_dict.get("horizontal_speed", default_horizontal_speed))
	elif fighter:
		var vx: float = fighter.velocity.x
		if absf(vx) > 5.0:
			_locked_dir = signf(vx)
			_current_horizontal_speed = absf(vx)
		else:
			_locked_dir = 0.0
			_current_horizontal_speed = 0.0
	else:
		_locked_dir = 0.0
		_current_horizontal_speed = 0.0

	if query_dict.has("is_super"):
		_is_super = bool(query_dict.get("is_super", false))
	elif has_active_jump:
		_is_super = bool(movement.get("active_is_super"))
	else:
		_is_super = false

	if query_dict.has("is_hop"):
		_is_hop = bool(query_dict.get("is_hop", false))
	elif has_active_jump:
		_is_hop = bool(movement.get("active_is_hop"))
	else:
		_is_hop = false

	# Progresso na curva de descida: reinicia no ápice vindo do JumpState,
	# mas continua suavemente onde o AirAttack parou (zero re-stall pós-ataque).
	if query_dict.has("gravity"):
		_fall_time_sec = 0.0
		if has_active_jump:
			movement.set("active_fall_time", 0.0)
	elif has_active_jump:
		_fall_time_sec = float(movement.get("active_fall_time"))
	else:
		_fall_time_sec = 0.0

	if fighter:
		if posture:
			posture.apply("air")

	# Transição visual contínua: mantém o giro diagonal (jump_forward / reverse) sem cortar
	# abruptamente no ápice; usa "fall" para pulo neutro ou retorno de AirAttack/Shoryuken.
	var preserve_anim: bool = bool(query_dict.get("preserve_anim", false))
	if anim and not (preserve_anim and anim.is_playing()):
		anim.play("fall")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Aterrissagem no chão (suporta aterrizar agachado segurando baixo, igual ao AirAttack)
	if fighter.is_on_floor():
		_handle_landing()
		return

	# Integração contínua C1 de gravidade modulada pela curva de descida (1.05 -> 1.28)
	var has_active_jump: bool = (movement != null and "has_active_jump" in movement and bool(movement.get("has_active_jump")))
	if has_active_jump:
		_fall_time_sec = float(movement.get("active_fall_time")) + delta
		movement.set("active_fall_time", _fall_time_sec)
	else:
		_fall_time_sec += delta

	var t_fall: float = clampf(_fall_time_sec / maxf(0.01, fall_curve_duration), 0.0, 1.0)
	var curve_mult: float = descent_curve.sample_baked(t_fall) if descent_curve else lerpf(1.05, 1.28, t_fall)

	fighter.velocity.y = minf(fighter.velocity.y + _current_gravity * curve_mult * delta, max_fall_speed)
	fighter.velocity.x = _current_horizontal_speed * _locked_dir

	# Spawn de ghost durante queda de Super Jump / Hyper Hop
	if _is_super:
		_ghost_timer += delta
		if _ghost_timer >= 0.06:
			_ghost_timer = 0.0
			if vfx:
				vfx.spawn_ghost("cancel", 0.15)

func _handle_landing() -> void:
	fighter.velocity = Vector2.ZERO
	if movement and movement.has_method("clear_active_jump"):
		movement.clear_active_jump()
	if input and input.is_action_pressed("down"):
		if posture:
			posture.apply("crouch")
		transition_requested.emit("CrouchState", {})
	else:
		if posture:
			posture.apply("stand")
		transition_requested.emit(landing_state, {})

func get_tags() -> Array[String]:
	return ["Air", "Movement", "Airborne"]
