class_name WallSplatComponent
extends Component

# Detecta colisão com parede da arena enquanto em estado de reação (Hurt/Juggling/
# Thrown) com velocity horizontal suficiente, e dispara o WALL SPLAT:
# hitstop dramático + VFX spark + transição pra WallSplatState (pin no muro).
#
# Versão AVANÇADA (Tekken-like): use_splat_state=true transiciona pra
# WallSplatState que prende o fighter na parede por pin_duration_frames,
# dando combo grátis garantido pro atacante.
#
# Pré-requisito: a arena precisa ter PAREDES físicas (StaticBody2D ou TileMap
# com collision nas laterais) pra fighter.is_on_wall() detectar.

signal wall_splat(point: Vector2, intensity: float)

@export_group("Detecção")
# Velocidade horizontal mínima pra triggar. Abaixo disso, encostou na parede mas
# não é "splat" — só pára naturalmente.
@export var min_splat_velocity: float = 250.0
# Anti re-trigger no mesmo contato. 300ms = ~18 frames.
@export var cooldown_msec: int = 300
# Em quais tags do estado atual o splat pode disparar.
@export var allowed_tags: Array[String] = ["Hurt", "Juggling", "Thrown"]

@export_group("Efeitos")
# Hitstop pra dar peso ao impacto. 0.1s = SF clássico.
@export var hitstop_duration: float = 0.1
# Spawna hit spark vermelho no ponto de impacto.
@export var auto_hitspark: bool = true

@export_group("Modo de operação")
# TRUE = avançado (transiciona pra WallSplatState com pin).
# FALSE = MVP (só aplica bounce vertical, sem state — fica no estado atual).
@export var use_splat_state: bool = true

@export_group("MVP fallback (use_splat_state=false)")
# Velocity Y aplicada no bounce (negativo = pra cima).
@export var bounce_velocity_y: float = -400.0
# Multiplier do velocity X após o splat. -0.3 = leve rebound pra dentro da arena.
# -1.0 = bounce elástico pleno. 0 = só zera velocidade horizontal.
@export var rebound_velocity_x_ratio: float = -0.3

var _last_splat_ms: int = 0

func _physics_process(_delta: float) -> void:
	if not fighter or not fighter.is_on_wall():
		return
	if abs(fighter.velocity.x) < min_splat_velocity:
		return

	var fsm = fighter.get_component("StateMachine") as StateMachine
	if not fsm:
		return
	var tags: Array[String] = fsm.get_tags()

	# Skip se já em WallSplat (anti re-trigger durante o pin).
	if "WallSplat" in tags:
		return

	# Gate por tag elegível (só em estados de reação).
	var has_eligible := false
	for t in allowed_tags:
		if t in tags:
			has_eligible = true
			break
	if not has_eligible:
		return

	var now: int = Time.get_ticks_msec()
	if (now - _last_splat_ms) < cooldown_msec:
		return
	_last_splat_ms = now

	var impact_point: Vector2 = fighter.global_position
	var intensity: float = abs(fighter.velocity.x) / max(min_splat_velocity, 1.0)

	# Hitstop pra peso dramático.
	var hitstop = fighter.get_component("HitstopComponent")
	if hitstop and hitstop.has_method("start_hitstop"):
		hitstop.start_hitstop(hitstop_duration)

	# Hit spark VFX (vermelho/grande).
	if auto_hitspark:
		var vfx = fighter.get_component("VfxComponent")
		if vfx and vfx.has_method("spawn_hit_spark"):
			vfx.spawn_hit_spark(impact_point + Vector2(0, -60), true)

	if use_splat_state:
		# AVANÇADO: transiciona pra WallSplatState (pin no muro).
		fsm.enter({
			"query": {
				"type": "wall_splat",
				"stance": "any",
				"direction": "any",
				"react": "yes",
			},
			"hit_data": {
				"impact_point": impact_point,
			}
		})
	else:
		# MVP: só bounce vertical + rebound horizontal, sem state.
		fighter.velocity.x *= rebound_velocity_x_ratio
		fighter.velocity.y = bounce_velocity_y

	wall_splat.emit(impact_point, intensity)
