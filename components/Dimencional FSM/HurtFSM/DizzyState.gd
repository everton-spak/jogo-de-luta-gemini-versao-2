class_name DizzyState
extends State

# Dizzy/Stagger: jogador FICA PARADO e vulnerável por `duration_sec` quando a
# StunBar enche. Oponente tem free hits durante esse tempo. No exit, a stun bar
# é DRENADA (via StunSystemComponent.notify_dizzy_resolved) — combate volta ao
# normal sem stun residual.
#
# Tier 5 — input do jogador não cancela o dizzy. Hits durante o dizzy aplicam
# DANO normalmente (HP) mas NÃO adicionam mais stun (StunSystem checa a tag
# "Dizzy" e pula stun gain).

@export var anim_name: String = "dizzy"
# Duração do dizzy em segundos. 2.5s = SF clássico — opponent tem combo grátis.
@export var duration_sec: float = 2.5

func _ready() -> void:
	type_dim = "dizzy"
	stance_dim = "ground"
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

	# Cola no chão (sem deslizar).
	if fighter.is_on_floor():
		fighter.velocity = Vector2.ZERO

	if state_time_sec >= duration_sec:
		# Checa KO primeiro — pode ter morrido por combo durante o dizzy.
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func exit() -> void:
	super.exit()
	# Drena a stun bar via StunSystemComponent.
	if fighter:
		var stun_sys = fighter.get_component("StunSystemComponent")
		if stun_sys and stun_sys.has_method("notify_dizzy_resolved"):
			stun_sys.notify_dizzy_resolved()

func get_tags() -> Array[String]:
	# "Hurt" pra herdar bloqueios de input dos outros estados de reação;
	# "Dizzy" é checado pelo StunSystem pra NÃO acumular mais stun durante isso.
	return ["Hurt", "Dizzy"]
