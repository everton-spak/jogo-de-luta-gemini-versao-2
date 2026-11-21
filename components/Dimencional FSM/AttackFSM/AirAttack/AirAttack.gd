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
	
	# 2. Física Global Aérea (mesma gravidade KOF configurada no MovementComponent)
	if movement:
		movement.apply_gravity(delta)
	elif fighter:
		fighter.velocity.y += 2900.0 * delta

	# 3. Verificação de Aterrissagem (Landing):
	# Se o lutador tocar no chão ANTES do ataque aéreo terminar,
	# a animação é cortada imediatamente.
	if fighter and fighter.is_on_floor():
		fighter.velocity = Vector2.ZERO
		var input_comp = get_component("InputComponent")
		if input_comp and input_comp.is_action_pressed("down"):
			if posture: posture.apply("crouch")
			transition_requested.emit("CrouchState", {})
		else:
			if posture: posture.apply("stand")
			transition_requested.emit("IdleState", {})
