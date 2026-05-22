class_name State
extends Component

signal transition_requested(new_state_name: String, payload: Dictionary)
var input_buffer: Component

@export_group("Dimensões do Estado (Deixe 'any' nas pastas/filtros)")
@export_enum("any", "ground", "air", "crouch") var stance_dim: String = "any"
@export_enum("any", "light", "heavy", "none") var strength_dim: String = "any"
@export_enum("any", "neutral", "forward", "backward") var direction_dim: String = "any"
@export var type_dim: String = "any" # Ex: "punch", "kick", "dash", "special"
@export_enum("any", "close", "far") var proximity_dim: String = "any"

@export_group("Regras de Cancelamento")
@export var cancel_tier_dim: int = 0 # 0=Passivo, 1=Fraco, 2=Forte, 3=Especial, 4=Super
@export var can_cancel_self: bool = false # Para Chain Combos (Rapid Fire)

@export_group("Lifecycle Frames (lidos pelo AttackComponent)")
@export var startup_frames: int = 3
@export var active_frames: int = 0
@export var recovery_frames: int = 0

@export_group("Animação")
@export var animation_name: String = ""
# Se vazio: roteia por stance_dim — "FallState" no ar, "CrouchState" agachado, "IdleState" no resto.
@export var recovery_state: String = ""

@export_group("Charge (motion moves)")
# Frame onde a animação pausa se o jogador continuar segurando o botão de carga.
# -1 = sem charge phase. Hadouken/Shoryuken/Tatsumaki/Joudan setam isso em _init().
@export var charge_pause_frame: int = -1

@export_group("Close (opcional — se setado, usa proximity)")
@export var anim_close: String = ""
@export var offset_close: Vector2 = Vector2.ZERO
@export var size_close: Vector2 = Vector2.ZERO

@export_group("Far")
@export var anim_far: String = ""
@export var offset_far: Vector2 = Vector2.ZERO
@export var size_far: Vector2 = Vector2.ZERO

@export_group("Hitbox")
@export var hitbox_offset: Vector2 = Vector2(60, -80)
@export var hitbox_size: Vector2 = Vector2(50, 40)
@export var damage: int = 5
@export var hitstun: float = 0.2
@export var knockback: Vector2 = Vector2(150, -50)
@export_enum("high", "mid", "low") var attack_level: String = "high"

# Componentes Internos
var anim: Component
var facing: Component
var hitbox: Component
var hurtbox: Component
var proximity: Component
var input: Component
var movement: Component
var health: Component
var vfx: Component
var combo_scaling : Component
var attack: AttackComponent # executor de ciclo de ataque (composição)
var special: SpecialMechanicComponent # regras de macro-cancel + tiers de carga

var state_time_sec: float = 0.0
var state_frames: int = 0

# Multiplier de carga — lido do SpecialMechanicComponent (a lógica vive lá).
# Usado por ProjectileAttackState pra escalar o projétil.
var _charge_multiplier: float:
	get:
		return special.charge_multiplier if special else 1.0

func _on_initialized() -> void:
	if not fighter:
		var current_node = get_parent()
		while current_node != null:
			if current_node is CharacterBody2D:
				fighter = current_node
				break
			current_node = current_node.get_parent()

	if not fighter:
		push_error("ERRO: Estado " + name + " não encontrou o Fighter!")
		return

	var found_anim = fighter.get_component("AnimatedSpriteComponent")
	if found_anim is AnimatedSpriteComponent:
		anim = found_anim

	input_buffer = fighter.get_component("InputBufferComponent")
	facing = fighter.get_component("FacingComponent")
	hitbox = fighter.get_component("HitboxComponent")
	hurtbox = fighter.get_component("HurtBoxComponent")
	proximity = fighter.get_component("ProximityBoxComponent")
	input = fighter.get_component("InputComponent")
	movement = fighter.get_component("MovementComponent")
	health = fighter.get_component("HealthComponent")
	vfx = fighter.get_component("VfxComponent")
	combo_scaling = fighter.get_component("ScalingComboComponent")
	attack = fighter.get_component("AttackComponent") as AttackComponent
	special = fighter.get_component("SpecialMechanicComponent") as SpecialMechanicComponent

# ==========================================
# Lifecycle base — só counters.
# Estados de ataque delegam pra AttackComponent (ver AttackStateBase).
# Estados de movimento sobrescrevem enter/physics_update/exit livremente.
# ==========================================

func enter(_payload: Dictionary = {}) -> void:
	state_time_sec = 0.0
	state_frames = 0

func exit() -> void:
	state_time_sec = 0.0
	state_frames = 0

func physics_update(delta: float) -> void:
	state_time_sec += delta
	state_frames += 1

# ==========================================
# Hooks de ciclo de ataque — DELEGADOS pro AttackComponent.
# A lógica default vive lá (default_*); aqui são só forwards finos (mesmo padrão
# da charge phase → SpecialMechanicComponent). Estados de ataque sobrescrevem o
# hook que precisarem e o override vence o forward (dispatch virtual do GDScript).
# Estados de movimento herdam mas nunca disparam (não passam por AttackStateBase).
# ==========================================

func _apply_enter_velocity() -> void:
	if attack: attack.default_apply_enter_velocity(self)

func _select_and_play_animation() -> void:
	if attack: attack.default_select_and_play_animation(self)

func _during_startup(_delta: float) -> void: pass
func _during_active(_delta: float) -> void: pass
func _during_recovery(_delta: float) -> void: pass

func _on_launch() -> void:
	if attack: attack.default_on_launch(self)

func _on_active_end() -> void:
	if attack: attack.default_on_active_end(self)

func _on_recovered() -> void:
	if attack: attack.default_on_recovered(self)

func _should_end_on_anim_end() -> bool:
	return true

func _resolve_recovery_state() -> String:
	return attack.default_resolve_recovery_state(self) if attack else "IdleState"

# ==========================================
# Cancel routing — MECÂNICA em StateMachine.passes_cancel_gate (achar leaf ativo/alvo),
# POLÍTICA no CancelComponent.can_cancel (usa cancel_tier_dim/can_cancel_self abaixo).
# O Fighter chama o gate antes de aplicar a query de input.
# ==========================================

# ==========================================
# Charge phase (motion moves) — DELEGADO pro SpecialMechanicComponent.
# A lógica vive em ChargeCancel.gd; aqui são só forwards finos pros estados
# de ataque (AttackStateBase, ProjectileAttackState, Shoryukens) chamarem.
# ==========================================

func _reset_charge() -> void:
	if special: special.reset_charge()

func _tick_charge(charging_btn: String) -> bool:
	return special.tick_charge(self, charging_btn) if special else false

func _check_macro(charging_btn: String) -> bool:
	return special.process_macro(self, charging_btn) if special else false

func _get_charging_button() -> String:
	return special.charging_button_for(self) if special else ""

# ==========================================
# Helpers de animação — DELEGADOS pro AnimatedSpriteComponent.
# Forwards finos; a guarda anti-duplicata vive lá.
# ==========================================

func _connect_frame_changed(cb: Callable) -> void:
	if anim: anim.connect_frame_changed(cb)

func _disconnect_frame_changed(cb: Callable) -> void:
	if anim: anim.disconnect_frame_changed(cb)

func get_tags() -> Array[String]:
	return []
