class_name AttackComponent
extends Component

# Executor do ciclo startup → active → recovery dos golpes.
# Composição: o State detém os dados e os hooks (animation_name, hitbox_offset,
# damage, _on_launch, _during_active, etc.); o AttackComponent é UM nó compartilhado
# no Fighter que executa o ciclo lendo do State e chamando os hooks no momento certo.

# Refs cacheadas
var hitbox: Component
var facing: Component

# Lifecycle state (válido entre begin/end)
# Tipado como Node pra evitar ciclo State ↔ AttackComponent no parser do GDScript.
# Em runtime sempre é um State; acessos a _state.xxx são duck-typed.
var _state: Node = null
var _frames: int = 0
var _launched: bool = false
var _active_ended: bool = false
var _recovered: bool = false

func _on_initialized() -> void:
	hitbox = get_component("HitboxComponent")
	facing = get_component("FacingComponent")

# ==========================================
# API pública chamada pelo State (via AttackStateBase ou enter() custom)
# ==========================================

func begin(state) -> void:
	_state = state
	_frames = 0
	_launched = false
	_active_ended = false
	_recovered = false

	state._apply_enter_velocity()
	state._select_and_play_animation()
	setup_hitbox(state)
	disable_hitbox()

# Retorna true quando o ciclo terminou. AttackStateBase ignora o retorno —
# a transição é emitida pelo hook _on_recovered() do próprio State.
func tick(delta: float) -> bool:
	if _state == null:
		return false
	_frames += 1

	# Fase 1: startup
	if not _launched:
		_state._during_startup(delta)
		if _frames >= _state.startup_frames:
			_launched = true
			_state._on_launch()
		return false

	# Fase 2: active
	if not _active_ended:
		_state._during_active(delta)
		if _state.active_frames > 0 and _frames >= _state.startup_frames + _state.active_frames:
			_active_ended = true
			_state._on_active_end()
			if _state.recovery_frames == 0:
				_recovered = true
				_state._on_recovered()
				return true
			return false
		# Fallback: active_frames=0 + animação tocada acabou → encerra active
		if _state.active_frames == 0 and (_state.animation_name != "" or _state.anim_close != ""):
			var s_anim = _state.anim
			if s_anim and s_anim.has_method("is_playing") and not s_anim.is_playing():
				if _state._should_end_on_anim_end():
					_active_ended = true
					_state._on_active_end()
					if _state.recovery_frames == 0:
						_recovered = true
						_state._on_recovered()
						return true
		return false

	# Fase 3: recovery
	if not _recovered:
		_state._during_recovery(delta)
		if _state.recovery_frames > 0 and _frames >= _state.startup_frames + _state.active_frames + _state.recovery_frames:
			_recovered = true
			_state._on_recovered()
			return true

	return false

func end() -> void:
	disable_hitbox()
	_state = null

# ==========================================
# Hitbox helpers — públicos pra fluxos custom (Shoryuken)
# ==========================================

func setup_hitbox(state) -> void:
	if not hitbox: return
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.damage = state.damage
	hitbox.hitstun_duration = state.hitstun
	hitbox.knockback_force = Vector2(state.knockback.x * f_dir, state.knockback.y)
	hitbox.attack_level = state.attack_level
	if hitbox.area_2d:
		hitbox.area_2d.position = Vector2(state.hitbox_offset.x * f_dir, state.hitbox_offset.y)
	if hitbox.collision_shape:
		if hitbox.collision_shape.shape is RectangleShape2D:
			hitbox.collision_shape.shape.size = state.hitbox_size
		hitbox.collision_shape.debug_color = Color(1.0, 0.0, 0.0, 0.4)

func enable_hitbox() -> void:
	if hitbox: hitbox.enable_box()

func disable_hitbox() -> void:
	if hitbox: hitbox.disable_box()

# Escala dano e tamanho da hitbox atual pelo multiplier informado.
# Usado pelo charge phase dos motion moves (State._tick_charge) após capturar o tier.
# Aplica em cima da config feita por setup_hitbox no begin() — então só chamar após begin().
func apply_multiplier(mult: float) -> void:
	if not hitbox or mult == 1.0: return
	hitbox.damage = int(hitbox.damage * mult)
	if hitbox.collision_shape and hitbox.collision_shape.shape is RectangleShape2D:
		hitbox.collision_shape.shape.size *= mult
