class_name GuardMeterComponent
extends Component

# Sistema de Guard Meter: barra começa CHEIA e esgota com cada bloqueio.
# Quando zera → GuardBrokenState (vulnerável por X segundos, opponent tem free hit).
# Regen passivo quando não está bloqueando.
#
# RAMPING (mecânica de pressão): cada block CONSECUTIVO custa MAIS que o anterior.
# Combo de blocks "termina" se ficar combo_timeout_msec sem bloquear — counter zera.
#
# Driver externo: HurtboxComponent chama consume_from_block(attack_level) APÓS
# detectar block. Se retornar true (barra quebrou), Hurtbox roteia pra
# "guard_broken" em vez de "block".

signal guard_critical(level: float) # 0-1, emite UMA VEZ ao cruzar threshold pra baixo

@export_group("Barra de Guard")
# Nome do nó BarComponent que representa o guard (resource_name="Guard").
@export var guard_bar_name: String = "GuardBar"

@export_group("Resistance (per-character)")
# Multiplier global do custo. <1.0 = guard sólido (tank), >1.0 = guard frágil.
@export var resistance: float = 1.0

@export_group("Custo por Attack Level")
@export var cost_high: float = 15.0
@export var cost_mid: float = 12.0
@export var cost_low: float = 10.0

@export_group("Ramping por Combo de Blocks (Pressão)")
# Cada block consecutivo custa MAIS que o anterior. 1.2 = +20% por block.
# 1.0 = sem ramping. >1 punee "blocking turtle" — defender combo longo quebra.
@export var ramp_per_block: float = 1.2
# Combo de blocks "termina" se ficar sem block por este tempo — counter zera.
@export var combo_timeout_msec: int = 800

@export_group("Regen Passivo")
# Quanto a barra REPÕE por segundo quando não está bloqueando.
@export var regen_rate_per_sec: float = 8.0
# Espera N ms sem block antes de começar a regenerar.
@export var regen_delay_msec: int = 1500

@export_group("Telegraphing")
# Fração (0-1) do max — quando a barra cai ABAIXO, dispara guard_critical.
# 0.25 = alerta aos 25% restantes ("guard quase quebrando").
@export var critical_threshold: float = 0.25
# Auto-conecta no signal pra VfxComponent.play_flash("buster") (dourado) na crítica.
@export var auto_flash_on_critical: bool = true

# State runtime
var guard_bar: Component
var _blocks_in_combo: int = 0
var _last_block_ms: int = 0
var _was_critical: bool = false

func _on_initialized() -> void:
	if fighter:
		guard_bar = fighter.get_component(guard_bar_name)
	if auto_flash_on_critical and not guard_critical.is_connected(_on_guard_critical):
		guard_critical.connect(_on_guard_critical)

# Chamado pelo HurtboxComponent quando bloqueia. Consome guard com ramping.
# Retorna true se a barra QUEBROU neste block (caller deve rotear pra GuardBrokenState).
func consume_from_block(attack_level: String) -> bool:
	if not guard_bar:
		return false

	# Skip se já em GuardBroken (não pode "quebrar de novo").
	if fighter:
		var fsm = fighter.get_component("StateMachine")
		if fsm and "GuardBroken" in fsm.get_tags():
			return false

	var now: int = Time.get_ticks_msec()
	# Reseta contador de combo de blocks se passou do timeout.
	if (now - _last_block_ms) > combo_timeout_msec:
		_blocks_in_combo = 0
	_blocks_in_combo += 1
	_last_block_ms = now

	# Custo: base × resistance × ramp (INCREASING — cada block custa mais).
	var base: float = _cost_for_level(attack_level)
	var ramp: float = pow(ramp_per_block, max(0, _blocks_in_combo - 1))
	var amount: float = base * resistance * ramp

	# Subtract com tracking de transição pra zero.
	var prev: float = guard_bar.current_value
	var max_val: float = guard_bar.max_value
	guard_bar.subtract(amount)
	var new_val: float = guard_bar.current_value

	# Critical telegraphing — emite UMA VEZ ao cruzar threshold pra BAIXO.
	var crit_value: float = critical_threshold * max_val
	if not _was_critical and new_val < crit_value:
		_was_critical = true
		guard_critical.emit(new_val / max_val)

	# Retorna true se ZEROU nesse block.
	return prev > 0.0 and new_val <= 0.0

# Chamado pelo GuardBrokenState.exit — restaura barra cheia (recompensa por
# aguentar o castigo do guard break).
func notify_guard_break_resolved() -> void:
	if guard_bar:
		guard_bar.add(guard_bar.max_value)
	_blocks_in_combo = 0
	_was_critical = false

func _physics_process(delta: float) -> void:
	if not guard_bar or guard_bar.current_value >= guard_bar.max_value:
		return
	# Regen só começa após regen_delay_msec sem bloquear.
	var now: int = Time.get_ticks_msec()
	if (now - _last_block_ms) < regen_delay_msec:
		return

	guard_bar.add(regen_rate_per_sec * delta)

	# Reset flag de critical se subiu acima do threshold (próximo cruzamento re-emite).
	if _was_critical:
		var max_val: float = guard_bar.max_value
		if guard_bar.current_value >= critical_threshold * max_val:
			_was_critical = false

func _cost_for_level(level: String) -> float:
	match level:
		"high": return cost_high
		"low": return cost_low
		_: return cost_mid

func _on_guard_critical(_level: float) -> void:
	if not fighter:
		return
	var vfx = fighter.get_component("VfxComponent")
	if vfx and vfx.has_method("play_flash"):
		vfx.play_flash("buster") # dourado/laranja — guard prestes a quebrar
