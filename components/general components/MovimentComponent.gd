class_name MovementComponent
extends Component

# --- CONFIGURAÇÕES GERAIS ---
@export_group("Physics Settings")
@export var default_gravity: float = 980.0
@export var max_fall_speed: float = 1200.0

# ==========================================
# 1. EIXO Y (GRAVIDADE E PULO)
# ==========================================
func apply_gravity(delta: float, gravity_multiplier: float = 1.0) -> void:
	if not fighter.is_on_floor():
		fighter.velocity.y += default_gravity * gravity_multiplier * delta
		# Limita a velocidade de queda para não atravessar o chão
		fighter.velocity.y = min(fighter.velocity.y, max_fall_speed)

func apply_jump_force(jump_force: float) -> void:
	fighter.velocity.y = -jump_force

# ==========================================
# 2. EIXO X (CAMINHADA E ATRITO)
# ==========================================
func move_horizontal(direction: float, max_speed: float, acceleration: float, delta: float) -> void:
	# Acelera suavemente ou instantaneamente até a velocidade alvo
	fighter.velocity.x = move_toward(fighter.velocity.x, direction * max_speed, acceleration * delta)

func apply_friction(friction_amount: float, delta: float) -> void:
	# Freia o personagem (útil para o IdleState ou fim de golpes)
	fighter.velocity.x = move_toward(fighter.velocity.x, 0, friction_amount * delta)

# ==========================================
# 3. MOVIMENTO BURST (DASH / IMPULSO)
# ==========================================
func apply_impulse(force_vector: Vector2) -> void:
	# Útil para Dash, recuo de magia ou tomar dano (Knockback)
	fighter.velocity = force_vector

# ==========================================
# 4. TELEPORTE (POSIÇÃO INSTANTÂNEA)
# ==========================================
# Teleporta para um ponto global exato da fase
func teleport_to(target_global_position: Vector2, reset_velocity: bool = true) -> void:
	fighter.global_position = target_global_position
	if reset_velocity:
		fighter.velocity = Vector2.ZERO

# Teleporta X pixels para frente/trás, respeitando o lado que está olhando
func teleport_forward(distance_x: float, distance_y: float = 0.0, reset_velocity: bool = true) -> void:
	var facing = 1.0
	var facing_comp = get_component("FacingComponent")
	if facing_comp:
		facing = facing_comp.current_facing
		
	fighter.global_position += Vector2(distance_x * facing, distance_y)
	if reset_velocity:
		fighter.velocity = Vector2.ZERO

# ==========================================
# 5. A EXECUÇÃO FINAL
# ==========================================
# Os estados chamam isso no final do seu physics_update
func commit_movement() -> void:
	fighter.move_and_slide()
