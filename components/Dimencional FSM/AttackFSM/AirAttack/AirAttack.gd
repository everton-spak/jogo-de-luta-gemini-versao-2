class_name AirAttack
extends StateMachine

func _ready() -> void:
	# Define a dimensão de postura como aéreo
	stance_dim = "air"

func get_machine_tags() -> Array[String]:
	# Injeta as tags no golpe filho.
	# "Airborne" é crucial para o HurtboxComponent saber que se o lutador
	# sofrer dano agora, ele deve ser arremessado num "Juggle" (combo aéreo).
	return ["Attacking", "Airborne"]

func physics_update(delta: float) -> void:
	# 1. Executa a lógica do golpe filho (ex: AirHeavyPunch, AirLightKick)
	super.physics_update(delta)
	
	# 2. Física Global Aérea:
	# Aplica a gravidade para que o personagem continue a cair enquanto bate.
	# IMPORTANTE: A gravidade do pulo é 1800. Devemos manter a mesma gravidade
	# para ele não voar para cima quando socar.
	if fighter:
		fighter.velocity.y += 1800.0 * delta

	# 3. Verificação de Aterrissagem (Landing):
	# Se o lutador tocar no chão ANTES do ataque aéreo terminar, 
	# a animação é cortada imediatamente.
	if fighter and fighter.is_on_floor():
		# Num jogo mais avançado, poderias enviar para um estado "LandingLag".
		# Por agora, voltamos ao Idle ou CrouchIdle com segurança.
		var facing_comp = get_component("InputComponent")
		if facing_comp and facing_comp.is_action_pressed("down"):
			transition_requested.emit("CrouchIdle", {})
		else:
			transition_requested.emit("IdleState", {})
