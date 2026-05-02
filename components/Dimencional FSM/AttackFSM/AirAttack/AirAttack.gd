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
	if movement:
		# Dica Pro: Se quiser que o golpe dê a sensação de impacto pesado nos ares,
		# pode diminuir a gravidade durante o ataque passando um multiplicador.
		# Ex: movement.apply_gravity(delta, 0.8) fará ele cair 20% mais devagar.
		movement.apply_gravity(delta)
		movement.commit_movement()

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
			transition_requested.emit("Idle", {})
