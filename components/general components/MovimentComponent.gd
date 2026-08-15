class_name MovementComponent
extends Component

# --- CONFIGURAÇÕES GERAIS (FÍSICA KOF) ---
@export_group("Physics Settings")
@export var default_gravity: float = 2900.0
@export var max_fall_speed: float = 1600.0

# ==========================================
# 1. EIXO Y (GRAVIDADE E PULO)
# ==========================================
func apply_gravity(delta: float, gravity_multiplier: float = 1.0) -> void:
	if not fighter.is_on_floor():
		fighter.velocity.y += default_gravity * gravity_multiplier * delta
		fighter.velocity.y = min(fighter.velocity.y, max_fall_speed)

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
