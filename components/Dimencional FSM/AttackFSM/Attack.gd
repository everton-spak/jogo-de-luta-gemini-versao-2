class_name AttackStateMachine
extends StateMachine

# Esta FSM é um "funil" dimensional para ataques.
# O seu papel é injetar a tag "Attacking" em todos os estados filhos
# e filtrar as queries por postura (Stance).

func get_machine_tags() -> Array[String]:
	# Sempre que o personagem estiver dentro de qualquer estado desta FSM,
	# ele será considerado em estado de ataque.
	return ["Attacking"]

# Opcional: Podes adicionar lógica aqui para resetar o combo_scaling
# se esta for a FSM de "Attack" raiz e entrar num estado vindo do Idle.
