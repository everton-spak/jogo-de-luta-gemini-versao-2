class_name GuardBrokenState
extends State

# Guard quebrou — fica vulnerável e parado por `duration_sec` enquanto o
# oponente pune. Diferente de Dizzy (origem stun), origem é EXCESSO de defesa.
#
# Tier 5 — input do jogador não cancela. Hits durante consomem HP normalmente
# (sem block possível porque tags não tem "Grounded"), mas NÃO consomem mais
# guard (já está quebrado — GuardMeterComponent skipa via tag "GuardBroken").
#
# No exit: notify_guard_break_resolved → barra cheia de volta (recompensa
# por aguentar o castigo).

@export var anim_name: String = "guard_broken"
# Duração do guard break. Mais curto que dizzy clássico — guard break é
# castigo direto, não tem mecânica de "acordar" recuperando aos poucos.
@export var duration_sec: float = 2.0

func _ready() -> void:
	type_dim = "guard_broken"
	stance_dim = "any" # cobre quebra em stand E crouch block
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "IdleState"

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	if fighter:
		fighter.velocity = Vector2.ZERO
	if anim:
		anim.play(anim_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	if fighter.is_on_floor():
		fighter.velocity = Vector2.ZERO

	if state_time_sec >= duration_sec:
		# Pode ter morrido por combo durante o castigo — checa KO.
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func exit() -> void:
	super.exit()
	# Recompensa: barra de guard restaurada cheia.
	if fighter:
		var guard_sys = fighter.get_component("GuardMeterComponent")
		if guard_sys and guard_sys.has_method("notify_guard_break_resolved"):
			guard_sys.notify_guard_break_resolved()

func get_tags() -> Array[String]:
	# "Hurt" pra herdar bloqueios de input dos outros estados de reação;
	# "GuardBroken" é checado pelo GuardMeter pra NÃO consumir guard de novo.
	# SEM "Grounded" → bloqueio de detecção de block no HurtboxComponent.
	return ["Hurt", "GuardBroken"]
