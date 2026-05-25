class_name MeterChargeState
extends State

# Animação de carga de meter: jogador segura LP+HK pra encher a MeterBar.
# Solta qualquer um dos dois → volta pro IdleState.
#
# Tier 0 (Cancellable): jogador VULNERÁVEL e INTERROMPÍVEL — qualquer ataque
# do oponente pega, e o jogador pode cancelar com qualquer move dele próprio
# (qualquer normal/special interrompe a carga e sai do state).
#
# A MeterBar é um BarComponent genérico (configurado como "Super" no Inspector).
# Busca por nome de nó "MeterBar" — se renomear na cena, atualizar METER_BAR_NAME.

@export var anim_name: String = "meter_charge"
# Quanto a MeterBar enche por segundo enquanto LP+HK estão segurados.
# 25/s → 4 segundos pra encher uma barra de 100 do zero. Tunar pra balancear.
@export var charge_rate_per_sec: float = 25.0
# Ajuste vertical do sprite enquanto o state ativo (corrige anim que afunda).
# NEGATIVO = sobe o sprite. 0 = sem ajuste. Restaura no exit.
@export var sprite_y_offset: float = 0.0

@export_group("VFX de Carga")
# Cor única do pulse durante a carga. Default roxo HDR (com glow do ambient).
# Valores > 1.0 em canais geram bright bloom; pra mais sutil, fique entre 0-1.
@export var pulse_color: Color = Color(1.0, 0.0, 3.0)
# Intervalo entre pulses (frames @ 60fps). 15 = ~250ms (mesmo ritmo dos
# motion moves pra consistência).
@export var pulse_interval_frames: int = 15
# Fade-back-to-white de cada pulse, em segundos.
@export var pulse_fade_sec: float = 0.25

# Botões que precisam estar segurados pra manter o state. Se qualquer um for
# solto, sai pro Idle.
const HOLD_BUTTONS: Array[String] = ["punch_light", "kick_heavy"]
# Nome do nó BarComponent que representa o super meter.
const METER_BAR_NAME: String = "MeterBar"

# BarComponent não tem class_name específico além de Component — usa Variant.
var meter_bar: Component
# Y do sprite ANTES do offset — usado pra restaurar no exit.
var _base_sprite_y: float = 0.0

func _ready() -> void:
	type_dim = "meter_charge"
	stance_dim = "ground"
	direction_dim = "any"
	cancel_tier_dim = 0
	recovery_state = "IdleState"

func _on_initialized() -> void:
	super._on_initialized()
	# Busca o nó BarComponent pelo nome (resource_name="Super" no Inspector).
	if fighter:
		meter_bar = fighter.get_component(METER_BAR_NAME)

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	if fighter:
		fighter.velocity = Vector2.ZERO
	# Captura o Y atual do sprite e aplica o offset (corrige afundar da anim).
	if posture and sprite_y_offset != 0.0:
		_base_sprite_y = posture.get_sprite_y()
		posture.set_sprite_y(_base_sprite_y + sprite_y_offset)
	if anim:
		anim.play(anim_name)

func exit() -> void:
	super.exit()
	# Restaura o Y original do sprite ao sair.
	if posture and sprite_y_offset != 0.0:
		posture.set_sprite_y(_base_sprite_y)
	# Limpa o modulate de carga (volta pra branco caso tenha ficado tingido).
	if vfx and vfx.has_method("clear_charge_pulse"):
		vfx.clear_charge_pulse()

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Mantém colado no chão (sem deslizar).
	if fighter.is_on_floor():
		fighter.velocity = Vector2.ZERO

	# Soltou algum dos botões? Sai.
	if not _holding_required():
		transition_requested.emit(recovery_state, {})
		return

	# Ainda segurando: incrementa a barra (charge_rate_per_sec * delta).
	# call() pra ser duck-typed (meter_bar é Component, add é de BarComponent).
	if meter_bar:
		meter_bar.call("add", charge_rate_per_sec * delta)

	# VFX: pulse periódico na cor única (roxo default).
	if vfx and pulse_interval_frames > 0 and state_frames % pulse_interval_frames == 0:
		if vfx.has_method("play_color_pulse"):
			vfx.play_color_pulse(pulse_color, pulse_fade_sec)

func _holding_required() -> bool:
	if not input:
		return false
	for btn in HOLD_BUTTONS:
		if not input.is_action_pressed(btn):
			return false
	return true

func get_tags() -> Array[String]:
	# "Cancellable" permite que NormalMoves e outros moves firam durante a carga
	# (jogador pode cancelar pra se defender). "MeterCharging" previne re-entrar
	# no próprio state via MeterChargeMove.
	return ["Grounded", "Cancellable", "MeterCharging"]
