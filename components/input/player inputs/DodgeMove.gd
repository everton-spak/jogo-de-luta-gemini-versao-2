class_name DodgeMove
extends MoveComponent

# Esquiva: LP + LK apertados SIMULTANEAMENTE (janela do SimultaneousInterpreter).
# Direção lida com LENIENCY em 3 camadas:
#   1. Input atual segurado (caso mais comum: jogador segura direção e aperta botões).
#   2. Tap tracker próprio — captura is_action_just_pressed("left"/"right") sem debounce,
#      pra pegar taps curtos que NÃO entram no InputBuffer (MIN_DIR_HOLD_MS=33ms).
#      Isto é crítico pra esquiva pra trás, onde o tap costuma ser muito curto.
#   3. Buffer direcional F/B do InputHistory — converte facing-relativo pra mundo.
#
# Não confunde com hybrid_dash (LP+LK durante CHARGE de motion move): aquele
# vive no SpecialMechanicComponent.process_macro e roda em outro contexto.

# Janela de tolerância pra detectar direção tapada que já voltou pro neutro.
# 300ms (~18 frames @ 60fps) cobre presses defensivos lentos sem virar "memória
# longa demais". Tunar no Inspector: 200 é apertado, 400+ pega direções antigas.
@export var dir_leniency_msec: int = 300

# Cooldown contado a partir do FIM do dodge anterior. 1000ms = 1 segundo INTEIRO
# de espera após o recovery do DodgeState antes de poder dodgear de novo.
# A duração do dodge em si vem do DodgeState.duration_sec (fetchado abaixo),
# então não precisa duplicar valor aqui se mexer no DodgeState.
@export var cooldown_msec: int = 1000

# Timestamp do último dodge disparado — base pro cálculo de cooldown.
var _last_dodge_start_ms: int = 0
# Cache do nó DodgeState (lazy load) pra ler duration_sec sem hardcode.
var _dodge_state_ref: Node = null

# Tap tracker — atualizado todo _physics_process via input direto.
var _last_lr_tap_ms: int = 0
var _last_lr_tap_x: float = 0.0

func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Grounded"]

# Capta taps esquerda/direita SEM o debounce do InputBuffer (que perde taps <33ms).
func _physics_process(_delta: float) -> void:
	if not fighter:
		return
	var input_comp = fighter.get_component("InputComponent")
	if not input_comp:
		return
	if input_comp.is_action_just_pressed("left"):
		_last_lr_tap_ms = Time.get_ticks_msec()
		_last_lr_tap_x = -1.0
	elif input_comp.is_action_just_pressed("right"):
		_last_lr_tap_ms = Time.get_ticks_msec()
		_last_lr_tap_x = 1.0

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var fsm = null
	if buffer.fighter:
		fsm = buffer.fighter.get_component("StateMachine")

	# Anti-spam 1: não inicia dodge se já estiver em movimento especial.
	if fsm:
		var current_tags = fsm.get_tags()
		if "Dashing" in current_tags or ("Movement" in current_tags and "Invincible" in current_tags):
			return {}

	# Anti-spam 2: cooldown a partir do FIM do dodge anterior.
	# Calcula o "lockout total" = duração do dodge + cooldown.
	var now: int = Time.get_ticks_msec()
	if _last_dodge_start_ms > 0:
		var dodge_duration_ms: int = _get_dodge_duration_ms(buffer)
		var total_lockout_ms: int = dodge_duration_ms + cooldown_msec
		if (now - _last_dodge_start_ms) < total_lockout_ms:
			return {}

	# Trigger: LP+LK simultâneos (dentro da tolerância do interpreter).
	if not buffer.simultaneous or not buffer.simultaneous.is_simultaneous_buffered(["punch_light", "kick_light"]):
		return {}

	# Direção: resolve com 3 camadas de leniency.
	var dir_x: float = _resolve_dir_x(buffer)

	# Consume os dois botões pra não disparar normais (LP/LK) no mesmo frame.
	buffer.simultaneous.consume_simultaneous(["punch_light", "kick_light"])

	# Marca o início do dodge pra o cooldown contar a partir daqui.
	_last_dodge_start_ms = now

	return {
		"type": "dodge",
		"stance": "ground",
		"direction": "any",
		"dir_x": dir_x,
	}

# Resolve a direção do dodge (mundo: -1=esquerda, 0=parado, +1=direita).
# 1. Direção segurada AGORA → vence (caso mais comum).
# 2. Tap recente esquerda/direita (sem debounce) → cobre taps curtos defensivos.
# 3. Buffer F/B do InputHistory → fallback pra strings combinadas (DF/DB/etc).
func _resolve_dir_x(buffer: InputBuffer) -> float:
	# 1. Direção atualmente segurada.
	if buffer.input:
		var x: float = sign(buffer.input.get_movement_direction().x)
		if x != 0.0:
			return x

	var now: int = Time.get_ticks_msec()

	# 2. Tap tracker próprio (sem debounce do InputBuffer).
	if _last_lr_tap_ms > 0 and (now - _last_lr_tap_ms) <= dir_leniency_msec:
		return _last_lr_tap_x

	# 3. Buffer direcional F/B (facing-relativo).
	if not buffer.history:
		return 0.0
	var facing: float = _get_facing(buffer)
	for i in range(buffer.history._buffer.size() - 1, -1, -1):
		var item: Dictionary = buffer.history._buffer[i]
		var age: int = now - int(item["timestamp"])
		if age > dir_leniency_msec:
			break
		var inp: String = str(item["input"])
		if inp == "F" or inp == "DF" or inp == "UF":
			return facing
		if inp == "B" or inp == "DB" or inp == "UB":
			return -facing

	return 0.0

func _get_facing(buffer: InputBuffer) -> float:
	if not buffer.fighter:
		return 1.0
	var fc = buffer.fighter.get_component("FacingComponent")
	if fc:
		return float(fc.current_facing)
	return 1.0

# Lazy fetch do DodgeState pra ler duration_sec (single source of truth).
# Fallback: 600ms se não achar (mesmo valor do default do DodgeState).
func _get_dodge_duration_ms(buffer: InputBuffer) -> int:
	if not _dodge_state_ref and buffer.fighter:
		var fsm = buffer.fighter.get_component("StateMachine")
		if fsm and fsm.has_method("find_state_recursive"):
			_dodge_state_ref = fsm.find_state_recursive("DodgeState")
	if _dodge_state_ref and "duration_sec" in _dodge_state_ref:
		return int(_dodge_state_ref.duration_sec * 1000.0)
	return 600
