class_name KnockdownStateMachine
extends StateMachine

# Sub-FSM do ciclo de derrubada: KnockdownState (caindo) → GroundedState (deitado,
# escolhe wakeup) → WakeupState (levantando com i-frames) → IdleState.
#
# Entrada: AirHurtState e ThrownState emitem transition_requested("KnockdownState")
# em vez de IdleState ao terminarem (transição resolvida via global_state_map).
#
# Cancel tier 5 — input do jogador não pode quebrar o ciclo. As escolhas de wakeup
# (quick/back/no_tech) são lidas no GroundedState via input direto, não via FSM.

func _ready() -> void:
	stance_dim = "any"
	type_dim = "any"
	cancel_tier_dim = 5

func get_machine_tags() -> Array[String]:
	return ["Knockdown"]
