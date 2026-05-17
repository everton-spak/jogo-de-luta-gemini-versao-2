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

@export_group("Lifecycle Frames")
# Frames antes do _on_launch disparar (hitbox liga). Conta a partir do enter().
@export var startup_frames: int = 3
# Frames da fase ativa após o launch. 0 = sem auto-fim (usa fallback de animação se houver).
@export var active_frames: int = 0
# Frames da recovery após o active_end. 0 = transita imediatamente após active_end.
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

var state_time_sec: float = 0.0
var state_frames: int = 0
var launched: bool = false
var active_ended: bool = false
var recovered: bool = false

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

# ==========================================
# Lifecycle: enter → startup → active → recovery → exit
# ==========================================

func enter(_payload: Dictionary = {}) -> void:
	state_time_sec = 0.0
	state_frames = 0
	launched = false
	active_ended = false
	recovered = false
	_apply_enter_velocity()
	_select_and_play_animation()
	_setup_hitbox()
	_disable_hitbox()

func exit() -> void:
	state_time_sec = 0.0
	state_frames = 0
	_disable_hitbox()

func physics_update(delta: float) -> void:
	state_time_sec += delta
	state_frames += 1

	# Fase 1: startup
	if not launched:
		_during_startup(delta)
		if state_frames >= startup_frames:
			launched = true
			_on_launch()
		return

	# Fase 2: active
	if not active_ended:
		_during_active(delta)
		if active_frames > 0 and state_frames >= startup_frames + active_frames:
			active_ended = true
			_on_active_end()
			if recovery_frames == 0 and not recovered:
				recovered = true
				_on_recovered()
			return
		# Fallback: se active_frames=0 e a animação tocada acabou, encerra active
		if active_frames == 0 and (animation_name != "" or anim_close != ""):
			if anim and anim.has_method("is_playing") and not anim.is_playing():
				if _should_end_on_anim_end():
					active_ended = true
					_on_active_end()
					if recovery_frames == 0 and not recovered:
						recovered = true
						_on_recovered()
		return

	# Fase 3: recovery
	if not recovered:
		_during_recovery(delta)
		if recovery_frames > 0 and state_frames >= startup_frames + active_frames + recovery_frames:
			recovered = true
			_on_recovered()

# ==========================================
# Hooks por frame
# ==========================================

func _during_startup(_delta: float) -> void:
	pass

func _during_active(_delta: float) -> void:
	pass

func _during_recovery(_delta: float) -> void:
	pass

# ==========================================
# Hooks de transição entre fases
# ==========================================

# state_frames >= startup_frames
func _on_launch() -> void:
	_enable_hitbox()

# state_frames >= startup + active (ou fim da animação se active_frames=0)
func _on_active_end() -> void:
	_disable_hitbox()

# state_frames >= startup + active + recovery
func _on_recovered() -> void:
	transition_requested.emit(_resolve_recovery_state(), {})

# ==========================================
# Hooks customizáveis
# ==========================================

# Velocidade no enter: default zera no chão, mantém momentum no ar.
func _apply_enter_velocity() -> void:
	if fighter and stance_dim != "air":
		fighter.velocity = Vector2.ZERO

# Escolha de animação: close/far se anim_close definido, senão animation_name.
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

# Suprime o fallback por fim-de-animação (ex: Joudan pausa anim no meio).
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
# Helpers
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

func _setup_hitbox() -> void:
	if not hitbox: return
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.damage = damage
	hitbox.hitstun_duration = hitstun
	hitbox.knockback_force = Vector2(knockback.x * f_dir, knockback.y)
	hitbox.attack_level = attack_level
	if hitbox.area_2d:
		hitbox.area_2d.position = Vector2(hitbox_offset.x * f_dir, hitbox_offset.y)
	if hitbox.collision_shape:
		if hitbox.collision_shape.shape is RectangleShape2D:
			hitbox.collision_shape.shape.size = hitbox_size
		hitbox.collision_shape.debug_color = Color(1.0, 0.0, 0.0, 0.4)

func _enable_hitbox() -> void:
	if hitbox: hitbox.enable_box()

func _disable_hitbox() -> void:
	if hitbox: hitbox.disable_box()

func _connect_frame_changed(cb: Callable) -> void:
	if anim and anim.sprite and not anim.sprite.frame_changed.is_connected(cb):
		anim.sprite.frame_changed.connect(cb)

func _disconnect_frame_changed(cb: Callable) -> void:
	if anim and anim.sprite and anim.sprite.frame_changed.is_connected(cb):
		anim.sprite.frame_changed.disconnect(cb)

func get_tags() -> Array[String]:
	return []
