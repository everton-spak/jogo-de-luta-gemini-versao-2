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

# Estado de charge (válido durante o ciclo do golpe).
var _is_charging: bool = false
var _charge_multiplier: float = 1.0
# Velocity salva ao começar o charge — restaurada ao soltar o botão.
# Trava o avanço (Tatsumaki, Shoryuken) sem perder o impulso programado.
var _pre_charge_velocity: Vector2 = Vector2.ZERO

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
# Charge phase (motion moves)
# ==========================================

# Reseta o estado de charge no início do golpe. Chamar no enter() do state.
func _reset_charge() -> void:
	_is_charging = false
	_charge_multiplier = 1.0
	_pre_charge_velocity = Vector2.ZERO

# Processa a fase de charge. Retorna `true` se o state está pausado (caller deve
# pular sua própria física neste frame).
# - Se charge_pause_frame < 0, retorna false (sem charge).
# - Se ainda não chargou e o frame ainda não chegou, retorna false.
# - Se o frame chegou e o botão ainda segurado: pausa anim, retorna true (toca pulse VFX).
# - Se já está chargando e botão ainda segurado: mantém pausado, retorna true.
# - Se já está chargando e botão soltou: lê o multiplier do classify_charge,
#   aplica no AttackComponent (se houver), resume anim, retorna false.
func _tick_charge(charging_btn: String) -> bool:
	if charge_pause_frame < 0 or not anim:
		return false

	var is_held: bool = false
	if input != null:
		is_held = input.is_action_pressed(charging_btn)

	if not _is_charging:
		if anim.get_current_frame() >= charge_pause_frame and is_held:
			_is_charging = true
			anim.pause()
			# Trava o avanço: salva a velocity programada e zera enquanto carrega.
			if fighter:
				_pre_charge_velocity = fighter.velocity
				fighter.velocity = Vector2.ZERO
			return true
		return false

	if is_held:
		# Reafirma a trava (caso outro sistema mexa na velocity entre frames).
		if fighter:
			fighter.velocity = Vector2.ZERO
		# Pulso visual a cada 6 frames (~100ms) com cor por tier (azul/verde/vermelho).
		if vfx and special and state_frames % 6 == 0:
			var pulse_data: Dictionary = special.classify_charge(charging_btn)
			var tier_status: String = str(pulse_data.get("status", "normal"))
			vfx.play_charge_pulse(tier_status)
		return true

	# Botão soltou — restaura a velocity programada antes do attack continuar.
	if fighter:
		fighter.velocity = _pre_charge_velocity

	# Captura o tier ANTES do ChargeTracker zerar (ordem de _physics_process
	# garante isso: Fighter roda antes dos componentes filhos).
	if special:
		var classification: Dictionary = special.classify_charge(charging_btn)
		_charge_multiplier = float(classification.get("multiplier", 1.0))

	# Aplica o multiplier na hitbox já configurada no begin().
	if attack and _charge_multiplier > 1.0:
		attack.apply_multiplier(_charge_multiplier)

	_is_charging = false
	anim.resume()
	return false

# Processa o macro-cancel. Retorna `true` se um macro disparou e a transição
# foi emitida — caller deve `return` imediatamente após.
func _check_macro(charging_btn: String) -> bool:
	if not special:
		return false
	var result: Dictionary = special.check_macro(charging_btn)
	if result.is_empty():
		return false

	# Consume os dois botões pra evitar duplo-input após o cancel.
	var complement: String = result["complement"]
	if input_buffer and input_buffer.history:
		input_buffer.history.consume_all_action(complement)
		input_buffer.history.consume_all_action(charging_btn)

	var macro_name: String = result["macro"]
	match macro_name:
		"hybrid_dash":
			transition_requested.emit("HybridDashState", {})
		"special_throw":
			# Super throw só existe na variante de perto. Longe = cancela pra recovery.
			var is_near: bool = false
			if proximity != null:
				is_near = proximity.is_target_near
			if is_near:
				transition_requested.emit("SuperThrowState", {})
			else:
				transition_requested.emit(_resolve_recovery_state(), {})
	return true

# Inferência do botão de carga a partir das dimensões do golpe.
# Hadouken/Shoryuken → punch_*; Tatsumaki/Joudan → kick_*.
# Override em estados que precisam de regra custom (ex: divekick herda do Joudan).
func _get_charging_button() -> String:
	var prefix := ""
	if type_dim == "hadouken" or type_dim == "shoryuken":
		prefix = "punch"
	elif type_dim == "tatsumaki" or type_dim == "joudan":
		prefix = "kick"
	if prefix == "" or (strength_dim != "light" and strength_dim != "heavy"):
		return ""
	return prefix + "_" + strength_dim

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
