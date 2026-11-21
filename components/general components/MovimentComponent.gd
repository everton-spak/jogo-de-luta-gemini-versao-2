class_name MovementComponent
extends Component

# --- CONFIGURAÇÕES GERAIS (FÍSICA KOF) ---
@export_group("Physics Settings")
@export var default_gravity: float = 2900.0
@export var max_fall_speed: float = 1600.0
@export var max_jump_fall_speed: float = 2400.0

# --- CONTEXTO DO PULO ATIVO (sincroniza JumpState, AirAttack e FallState) ---
var has_active_jump: bool = false
var active_air_gravity: float = 2900.0
var active_air_speed_x: float = 500.0
var active_air_dir: float = 0.0
var active_is_super: bool = false
var active_is_hop: bool = false
var active_air_anim_mode: String = "neutral"
var active_ascent_time: float = 0.0
var active_ascent_duration: float = 0.35
var active_fall_time: float = 0.0
var active_fall_duration: float = 0.35
var active_ascent_curve: Curve = null
var active_descent_curve: Curve = null
var _active_jump_left_floor: bool = false

func _physics_process(_delta: float) -> void:
	if not has_active_jump or not fighter:
		return
	if not fighter.is_on_floor():
		_active_jump_left_floor = true
	elif _active_jump_left_floor:
		clear_active_jump()
		return
	var fsm = fighter.get("root_fsm")
	if fsm and fsm.has_method("get_tags"):
		var tags: Array[String] = fsm.get_tags()
		if "Hurt" in tags or "Juggling" in tags or "Knockdown" in tags or "KO" in tags or "Ground" in tags or "Crouching" in tags:
			clear_active_jump()

# ==========================================
# 1. EIXO Y (GRAVIDADE E PULO)
# ==========================================
func apply_gravity(delta: float, gravity_multiplier: float = 1.0) -> void:
	if not fighter.is_on_floor():
		fighter.velocity.y += default_gravity * gravity_multiplier * delta
		fighter.velocity.y = minf(fighter.velocity.y, max_fall_speed)

func set_active_jump(
	gravity: float,
	speed_x: float,
	dir_x: float,
	is_super: bool,
	is_hop: bool,
	anim_mode: String,
	ascent_duration: float,
	ascent_curve: Curve = null,
	descent_curve: Curve = null,
	fall_duration: float = 0.35
) -> void:
	has_active_jump = true
	_active_jump_left_floor = false
	active_air_gravity = gravity
	active_air_speed_x = speed_x
	active_air_dir = dir_x
	active_is_super = is_super
	active_is_hop = is_hop
	active_air_anim_mode = anim_mode
	active_ascent_time = 0.0
	active_ascent_duration = maxf(0.01, ascent_duration)
	active_fall_time = 0.0
	active_fall_duration = maxf(0.01, fall_duration)
	active_ascent_curve = ascent_curve
	active_descent_curve = descent_curve

func update_active_jump_gravity(gravity: float, is_hop: bool = false) -> void:
	if not has_active_jump:
		return
	active_air_gravity = gravity
	if is_hop:
		active_is_hop = true

func clear_active_jump() -> void:
	has_active_jump = false
	_active_jump_left_floor = false
	active_air_gravity = default_gravity
	active_air_speed_x = 0.0
	active_air_dir = 0.0
	active_is_super = false
	active_is_hop = false
	active_air_anim_mode = "neutral"
	active_ascent_time = 0.0
	active_fall_time = 0.0
	active_ascent_curve = null
	active_descent_curve = null

# Gravidade dedicada para AirAttack — mantém exatamente o mesmo arco do pulo/hop ativo
# sem alterar default_gravity usado por AirHurtState / KnockdownState / Shoryuken.
func apply_air_gravity(delta: float) -> void:
	if not fighter or fighter.is_on_floor():
		return
	if not has_active_jump:
		apply_gravity(delta)
		return
	var curve_mult: float = 1.0
	if fighter.velocity.y < 0.0:
		active_ascent_time += delta
		var t_asc: float = clampf(active_ascent_time / maxf(0.01, active_ascent_duration), 0.0, 1.0)
		curve_mult = active_ascent_curve.sample_baked(t_asc) if active_ascent_curve else lerpf(0.95, 1.05, t_asc)
	else:
		active_fall_time += delta
		var t_fall: float = clampf(active_fall_time / maxf(0.01, active_fall_duration), 0.0, 1.0)
		curve_mult = active_descent_curve.sample_baked(t_fall) if active_descent_curve else lerpf(1.05, 1.28, t_fall)
	fighter.velocity.y = minf(fighter.velocity.y + active_air_gravity * curve_mult * delta, max_jump_fall_speed)

func apply_jump_force(jump_force: float) -> void:
	fighter.velocity.y = -jump_force

# ==========================================
# 2. EIXO X (CAMINHADA E ATRITO)
# ==========================================
func move_horizontal(direction: float, max_speed: float, acceleration: float, delta: float) -> void:
	fighter.velocity.x = move_toward(fighter.velocity.x, direction * max_speed, acceleration * delta)

func apply_friction(friction_amount: float, delta: float) -> void:
	fighter.velocity.x = move_toward(fighter.velocity.x, 0, friction_amount * delta)

# Trava o X instantaneamente — útil no enter() de ataques que não devem carregar momentum
func stop_horizontal() -> void:
	fighter.velocity.x = 0.0

# Desaceleração no ar — para ataques aéreos que perdem momentum gradualmente
func apply_air_decel(decel: float, delta: float) -> void:
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, decel * delta)

# ==========================================
# 3. MOVIMENTO BURST (DASH / IMPULSO)
# ==========================================
func apply_impulse(force_vector: Vector2) -> void:
	fighter.velocity = force_vector

# Impulso que aplica facing no eixo X automaticamente
# Ex: apply_facing_impulse(300, -500) lança para frente e para cima
func apply_facing_impulse(speed_x: float, speed_y: float = 0.0) -> void:
	var f_dir = _get_facing()
	fighter.velocity = Vector2(speed_x * f_dir, speed_y)

# Avanço suave em direção ao oponente — útil no startup de golpes normais
# Chame a cada frame no physics_update enquanto quiser o avanço
func apply_attack_step(speed: float, delta: float) -> void:
	var f_dir = _get_facing()
	fighter.velocity.x = move_toward(fighter.velocity.x, speed * f_dir, speed * 8.0 * delta)

# Recuo do próprio personagem ao conectar um golpe pesado (recoil)
# Aplica na direção CONTRÁRIA ao facing
func apply_knockback_self(force_x: float, force_y: float = 0.0) -> void:
	var f_dir = _get_facing()
	fighter.velocity = Vector2(-force_x * f_dir, force_y)

# ==========================================
# 4. TELEPORTE (POSIÇÃO INSTANTÂNEA)
# ==========================================
func teleport_to(target_global_position: Vector2, reset_velocity: bool = true) -> void:
	fighter.global_position = target_global_position
	if reset_velocity:
		fighter.velocity = Vector2.ZERO

func teleport_forward(distance_x: float, distance_y: float = 0.0, reset_velocity: bool = true) -> void:
	var f_dir = _get_facing()
	fighter.global_position += Vector2(distance_x * f_dir, distance_y)
	if reset_velocity:
		fighter.velocity = Vector2.ZERO

# ==========================================
# 5. A EXECUÇÃO FINAL
# ==========================================
func commit_movement() -> void:
	pass

# ==========================================
# INTERNO
# ==========================================
func _get_facing() -> float:
	var facing_comp = get_component("FacingComponent")
	if facing_comp:
		return facing_comp.current_facing
	return 1.0
