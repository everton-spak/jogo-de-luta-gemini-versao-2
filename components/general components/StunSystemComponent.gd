class_name StunSystemComponent
extends Component

# Sistema de stun: acumula com cada hit, decai passivamente quando não toma hit,
# e quando enche dispara entrada em DizzyState. Camada de dano "soft" por cima
# do HP que recompensa golpes pesados e pune defesa ruim.
#
# Driver externo: HurtboxComponent chama add_from_hit(attack_level) ANTES de
# decidir target_type da reação. Se retornar true (barra encheu), Hurtbox roteia
# pra "dizzy" em vez de "hurt".
#
# Reset: DizzyState.exit chama notify_dizzy_resolved() pra zerar a barra.

signal stun_critical(level: float) # 0-1, emite UMA VEZ ao cruzar threshold pra cima

@export_group("Barra de Stun")
# Nome do nó BarComponent que representa o stun (resource_name="Stun").
@export var stun_bar_name: String = "StunBar"

@export_group("Resistance (per-character)")
# Multiplier global de stun recebido. <1.0 = tank (toma menos), >1.0 = frágil.
@export var resistance: float = 1.0

@export_group("Gain por Attack Level")
@export var gain_high: float = 10.0
@export var gain_mid: float = 8.0
@export var gain_low: float = 6.0

@export_group("Diminishing Returns por Combo")
# Cada hit subsequente dá MENOS stun. 0.85 = -15% por hit.
@export var diminish_per_hit: float = 0.85
# Combo "termina" se ficar sem hit por este tempo — contador zera.
@export var combo_timeout_msec: int = 800

@export_group("Decay Passivo")
# Quanto a barra reduz por segundo quando não está tomando hit.
@export var decay_rate_per_sec: float = 5.0
# Espera N ms sem hit antes de começar a decair (evita "tomar 1 hit e curar").
@export var decay_delay_msec: int = 2000

@export_group("Telegraphing")
# Fração (0-1) do max que dispara stun_critical. 0.8 = alerta aos 80%.
@export var critical_threshold: float = 0.8
# Auto-conecta o signal pra VfxComponent.play_flash("counter") quando cruzar
# critical. Flash vermelho discreto. Desligue se quiser controlar via HUD/SFX
# externos (o signal continua emitindo de qualquer jeito).
@export var auto_flash_on_critical: bool = true

# State runtime
var stun_bar: Component
var _hits_in_combo: int = 0
var _last_hit_ms: int = 0
var _was_critical: bool = false

func _on_initialized() -> void:
	if fighter:
		stun_bar = fighter.get_component(stun_bar_name)
	# Auto-flash vermelho na entrada do estado crítico (opt-in).
	if auto_flash_on_critical and not stun_critical.is_connected(_on_stun_critical):
		stun_critical.connect(_on_stun_critical)

func _on_stun_critical(_level: float) -> void:
	if not fighter:
		return
	var vfx = fighter.get_component("VfxComponent")
	if vfx and vfx.has_method("play_flash"):
		vfx.play_flash("counter") # vermelho intenso, fade default (~0.15s)

# Adiciona stun por um hit. Retorna true se a barra ENCHEU NESTE hit (caller
# deve rotear pra DizzyState). False se ainda há espaço ou se foi skipado
# (já em dizzy → não acumula).
func add_from_hit(attack_level: String) -> bool:
	if not stun_bar:
		return false

	# Skip se JÁ está em Dizzy — não há "dizzy of dizzy", combo de castigo só dá dano.
	if fighter:
		var fsm = fighter.get_component("StateMachine")
		if fsm and "Dizzy" in fsm.get_tags():
			return false

	var now: int = Time.get_ticks_msec()
	# Reseta contador de combo se passou do timeout.
	if (now - _last_hit_ms) > combo_timeout_msec:
		_hits_in_combo = 0
	_hits_in_combo += 1
	_last_hit_ms = now

	# Calcula amount: base por nível × resistance × diminishing.
	var base: float = _gain_for_level(attack_level)
	var falloff: float = pow(diminish_per_hit, max(0, _hits_in_combo - 1))
	var amount: float = base * resistance * falloff

	# Add com tracking de transição pra cheio.
	var prev: float = stun_bar.current_value
	var max_val: float = stun_bar.max_value
	stun_bar.add(amount)
	var new_val: float = stun_bar.current_value

	# Critical telegraphing — emite UMA VEZ ao cruzar o threshold pra cima.
	var crit_value: float = critical_threshold * max_val
	if not _was_critical and new_val >= crit_value:
		_was_critical = true
		stun_critical.emit(new_val / max_val)

	# Retorna true se ENCHEU nesse hit (passou de não-cheio pra cheio).
	return prev < max_val and new_val >= max_val

# Chamado pelo DizzyState.exit pra drenar a barra e resetar combo.
func notify_dizzy_resolved() -> void:
	if stun_bar:
		stun_bar.subtract(stun_bar.max_value)
	_hits_in_combo = 0
	_was_critical = false

func _physics_process(delta: float) -> void:
	if not stun_bar or stun_bar.current_value <= 0.0:
		return
	# Decay só começa após decay_delay_msec sem tomar hit.
	var now: int = Time.get_ticks_msec()
	if (now - _last_hit_ms) < decay_delay_msec:
		return

	stun_bar.subtract(decay_rate_per_sec * delta)

	# Reset flag de critical se caiu abaixo do threshold (próximo cruzamento re-emite).
	if _was_critical:
		var max_val: float = stun_bar.max_value
		if stun_bar.current_value < critical_threshold * max_val:
			_was_critical = false

func _gain_for_level(level: String) -> float:
	match level:
		"high": return gain_high
		"low": return gain_low
		_: return gain_mid # "mid" e qualquer outro fallback
