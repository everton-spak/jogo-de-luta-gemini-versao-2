class_name HurtStateMachine
extends StateMachine

# Sub-FSM dos estados REATIVOS (recebendo dano/block/throw). Sibling de
# MovementStateMachine e AttackStateMachine sob a StateMachine raiz.
#
# Driver: HurtboxComponent (hits normais) e ThrowHurtboxComponent (throws).
# Ambos chamam root_fsm.enter(payload) com payload["query"]["react"] = "yes".
# Isso faz o scoring da root FSM rotear pra cá em vez de Movement/Attack
# (porque react_dim="yes" aqui dá +10 enquanto os outros têm react_dim="any" +1).
#
# Cancel tier 5 (acima do super=4) — bloqueia o jogador de interromper a reação
# via input. A saída acontece via transition_requested do próprio leaf (bubble
# pra root, que resolve hierarquicamente pra IdleState/FallState/etc).

func _ready() -> void:
	stance_dim = "any"
	type_dim = "any"
	react_dim = "yes" # marcador único pro routing da root
	cancel_tier_dim = 5

func get_machine_tags() -> Array[String]:
	# Tag genérica; cada leaf adiciona a sua específica ("Hurt"/"Blocking"/etc).
	return ["Reacting"]
