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

var state_time_sec: float = 0.0
var state_frames: int = 0

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
# Hooks de ciclo de ataque (chamados pelo AttackComponent).
# Defaults sensatos aqui; estados de ataque sobrescrevem o que precisarem.
# Estados de movimento herdam mas nunca disparam (não passam por AttackStateBase).
# ==========================================

func _apply_enter_velocity() -> void:
	if fighter and stance_dim != "air":
		fighter.velocity = Vector2.ZERO

func _select_and_play_animation() -> void:
	if anim_close != "":
		var is_near = proximity and proximity.is_target_near
		if is_near:
			hitbox_offset = offset_close
			hitbox_size = size_close
			if anim: anim.play(anim_close)
		else:
			hitbox_offset = offset_far
			hitbox_size = size_far
			if anim: anim.play(anim_far)
	elif animation_name != "":
		if anim: anim.play(animation_name)

func _during_startup(_delta: float) -> void: pass
func _during_active(_delta: float) -> void: pass
func _during_recovery(_delta: float) -> void: pass

func _on_launch() -> void:
	if attack: attack.enable_hitbox()

func _on_active_end() -> void:
	if attack: attack.disable_hitbox()

func _on_recovered() -> void:
	transition_requested.emit(_resolve_recovery_state(), {})

func _should_end_on_anim_end() -> bool:
	return true

func _resolve_recovery_state() -> String:
	if recovery_state != "":
		return recovery_state
	if stance_dim == "air":
		return "FallState"
	if stance_dim == "crouch":
		return "CrouchState"
	return "IdleState"

# ==========================================
# Cancel routing
# ==========================================

func process_cancel_routes() -> bool:
	if input_buffer == null: return false
	var command = input_buffer.check_special_moves(get_tags())
	if command.is_empty(): return false

	if command.has("query"):
		var query = command["query"]
		var root_fsm = get_component("StateMachine")

		if root_fsm and root_fsm is StateMachine:
			var target_node = root_fsm._simulate_leaf_routing(query)

			if target_node:
				var next_tier = target_node.cancel_tier_dim
				var current_tier = self.cancel_tier_dim

				if next_tier > current_tier or (target_node.name == self.name and can_cancel_self):
					transition_requested.emit(target_node.name, command)
					return true
	return false

# ==========================================
# Helpers de animação (úteis pra Shoryukens que pausam frame específico)
# ==========================================

func _connect_frame_changed(cb: Callable) -> void:
	if anim and anim.sprite and not anim.sprite.frame_changed.is_connected(cb):
		anim.sprite.frame_changed.connect(cb)

func _disconnect_frame_changed(cb: Callable) -> void:
	if anim and anim.sprite and anim.sprite.frame_changed.is_connected(cb):
		anim.sprite.frame_changed.disconnect(cb)

func get_tags() -> Array[String]:
	return []
