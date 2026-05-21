class_name SpecialMechanicComponent
extends Component

# Detém só o que é EXCLUSIVO desta mecânica:
#   1. Tabela MACRO_CANCELS — regras de "botão segurado + botão complementar"
#   2. Classificação de tiers (normal/strong/super) por tempo de carga
#
# O tracking de tempo de botão segurado fica no ChargeTrackerComponent.
# Detecção genérica de botões simultâneos fica no SimultaneousInterpreterComponent.

# Regras de macro-cancel: "botão segurado" → {"complementar apertado": "resultado"}.
# Disparado quando charging_btn está sendo segurado AGORA e complement_btn foi
# pressionado NESTE frame (just_pressed). Não é a mesma coisa que "simultâneo
# dentro de uma janela" — esse caso usa SimultaneousInterpreterComponent.
const MACRO_CANCELS := {
	"punch_light": {
		"kick_light": "hybrid_dash"
	},
	"kick_light": {
		"punch_light": "hybrid_dash",
		"punch_heavy": "special_throw"
	},
	"punch_heavy": {
		"kick_light": "special_throw"
	}
}

@export_group("Tiers da Carga")
# Limiares em ms (alinhado com a unidade do ChargeTrackerComponent).
@export var min_charge_msec: float = 200.0
@export var max_charge_msec: float = 1500.0
@export var normal_multiplier: float = 1.0
@export var strong_multiplier: float = 1.5
@export var super_multiplier: float = 2.5

var input: Component
var charge_tracker: ChargeTrackerComponent
var history: InputHistoryComponent

# ==========================================
# Estado de charge (uma carga ativa por vez no fighter).
# Movido do State.gd — o State agora só delega via _tick_charge/_check_macro/etc.
# ==========================================
var _is_charging: bool = false
# Multiplier capturado no release. Lido pelo State via getter (_charge_multiplier).
var charge_multiplier: float = 1.0
# Velocity salva ao começar o charge — restaurada ao soltar (trava o avanço).
var _pre_charge_velocity: Vector2 = Vector2.ZERO
# Marca lifecycle bloqueado por hold (pode ser antes da anim atingir charge_pause_frame).
var _charge_blocked: bool = false
# Último tier pulsado — força pulse imediato em transição de tier.
var _last_pulse_tier: String = ""

func _on_initialized() -> void:
	input = get_component("InputComponent")
	charge_tracker = get_component("ChargeTrackerComponent") as ChargeTrackerComponent
	history = get_component("InputHistoryComponent") as InputHistoryComponent

# Retorna {"macro": "hybrid_dash", "complement": "kick_light"} no acerto, ou {} no vazio.
# Self-contained: exige que charging_btn esteja sendo segurado AGORA e que
# o complemento tenha sido pressionado NESTE frame (is_action_just_pressed).
# O caller é responsável por consumir o complement do buffer pra não duplicar input.
func check_macro(charging_btn: String) -> Dictionary:
	if not input: return {}
	if not MACRO_CANCELS.has(charging_btn): return {}
	if not input.is_action_pressed(charging_btn): return {}

	var possible_cancels = MACRO_CANCELS[charging_btn]
	for complement_btn in possible_cancels:
		if input.is_action_just_pressed(complement_btn):
			return {"macro": possible_cancels[complement_btn], "complement": complement_btn}
	return {}

# Classifica a carga acumulada de um botão em tiers normal/strong/super.
# Lê o tempo direto do ChargeTrackerComponent. Caller normalmente chama isto
# após is_action_just_released(btn) pra avaliar o que sai no release.
func classify_charge(btn: String) -> Dictionary:
	var t := 0.0
	if charge_tracker:
		t = charge_tracker.get_button_charge_time(btn)

	if t >= max_charge_msec:
		return {"status": "super", "multiplier": super_multiplier, "time_msec": t}
	if t >= min_charge_msec:
		return {"status": "strong", "multiplier": strong_multiplier, "time_msec": t}
	return {"status": "normal", "multiplier": normal_multiplier, "time_msec": t}

# ==========================================
# Charge phase (motion moves)
# Recebe o `state` (State node) e opera sobre ele. Antes vivia no State.gd.
# ==========================================

# Reseta o estado de charge no início do golpe. Chamar no enter() do state.
func reset_charge() -> void:
	_is_charging = false
	charge_multiplier = 1.0
	_pre_charge_velocity = Vector2.ZERO
	_charge_blocked = false
	_last_pulse_tier = ""

# Inferência do botão de carga a partir das dimensões do golpe.
# Hadouken/Shoryuken → punch_*; Tatsumaki/Joudan → kick_*.
func charging_button_for(state) -> String:
	var prefix := ""
	if state.type_dim == "hadouken" or state.type_dim == "shoryuken":
		prefix = "punch"
	elif state.type_dim == "tatsumaki" or state.type_dim == "joudan":
		prefix = "kick"
	if prefix == "" or (state.strength_dim != "light" and state.strength_dim != "heavy"):
		return ""
	return prefix + "_" + state.strength_dim

# Processa a fase de charge. Retorna `true` se o state está pausado (caller deve
# pular sua própria física neste frame).
func tick_charge(state, charging_btn: String) -> bool:
	if state.charge_pause_frame < 0 or not state.anim:
		return false

	var is_held: bool = false
	if input != null:
		is_held = input.is_action_pressed(charging_btn)

	# Botão segurado: bloqueia o lifecycle imediatamente (mesmo antes da anim
	# atingir o pause_frame) pra _on_launch não disparar cedo.
	if is_held:
		if not _charge_blocked:
			_charge_blocked = true
			if state.fighter:
				_pre_charge_velocity = state.fighter.velocity
		if state.fighter:
			state.fighter.velocity = Vector2.ZERO

		if not _is_charging and state.anim.get_current_frame() >= state.charge_pause_frame:
			_is_charging = true
			state.anim.pause()

		# Pulse: a cada 30 frames (~500ms) OU imediato quando o tier muda.
		if _is_charging and state.vfx:
			var pulse_data: Dictionary = classify_charge(charging_btn)
			var tier_status: String = str(pulse_data.get("status", "normal"))
			if tier_status != _last_pulse_tier or state.state_frames % 30 == 0:
				_last_pulse_tier = tier_status
				state.vfx.play_charge_pulse(tier_status)
		return true

	# Botão NÃO segurado.
	if not _charge_blocked:
		return false

	# Botão soltou após bloquear — restaura cor + velocity, captura multiplier.
	if state.vfx:
		state.vfx.clear_charge_pulse()
	if state.fighter:
		state.fighter.velocity = _pre_charge_velocity

	# Captura o tier ANTES do ChargeTracker zerar.
	var classification: Dictionary = classify_charge(charging_btn)
	charge_multiplier = float(classification.get("multiplier", 1.0))

	if state.attack and charge_multiplier > 1.0:
		state.attack.apply_multiplier(charge_multiplier)

	_is_charging = false
	_charge_blocked = false
	state.anim.resume()
	return false

# Processa o macro-cancel. Retorna `true` se disparou (caller deve `return`).
func process_macro(state, charging_btn: String) -> bool:
	var result: Dictionary = check_macro(charging_btn)
	if result.is_empty():
		return false

	# Limpa modulate da carga antes de transicionar.
	if state.vfx:
		state.vfx.clear_charge_pulse()

	# Consume os dois botões pra evitar duplo-input após o cancel.
	var complement: String = result["complement"]
	if state.input_buffer and state.input_buffer.history:
		state.input_buffer.history.consume_all_action(complement)
		state.input_buffer.history.consume_all_action(charging_btn)

	var macro_name: String = result["macro"]
	match macro_name:
		"hybrid_dash":
			state.transition_requested.emit("HybridDashState", {})
		"special_throw":
			var is_near: bool = false
			if state.proximity != null:
				is_near = state.proximity.is_target_near
			if is_near:
				state.transition_requested.emit("SuperThrowState", {})
			else:
				state.transition_requested.emit(state._resolve_recovery_state(), {})
	return true
