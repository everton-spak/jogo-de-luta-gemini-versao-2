class_name AirAttack
extends StateMachine

func _ready() -> void:
	# Define a dimensão de postura como aéreo
	stance_dim = "air"

func _on_initialized() -> void:
	super._on_initialized()
	_resolve_air_components()

func _resolve_air_components() -> void:
	if not fighter:
		return
	if not movement:
		movement = fighter.get_component("MovementComponent")
	if not posture:
		posture = fighter.get_component("PostureComponent") as PostureComponent
	if not input:
		input = fighter.get_component("InputComponent")

func get_machine_tags() -> Array[String]:
	# Injeta as tags no golpe filho.
	# "Airborne" é crucial para o HurtboxComponent saber que se o lutador
	# sofrer dano agora, ele deve ser arremessado num "Juggle" (combo aéreo).
	return ["Attacking", "Airborne"]

func physics_update(delta: float) -> void:
	if not movement or not posture or not input:
		_resolve_air_components()

	# 1. Verificação de Aterrissagem (Landing):
	# Se o lutador tocar no chão ANTES do ataque aéreo terminar,
	# a animação é cortada imediatamente sem tick extra no solo.
	if fighter and fighter.is_on_floor():
		_handle_landing()
		return

	# 2. Executa a lógica do golpe filho (ex: AirHeavyPunch, AirLightKick)
	super.physics_update(delta)

	# 3. Física Global Aérea sincronizada com a gravidade do pulo/hop ativo
	if movement and movement.has_method("apply_air_gravity"):
		movement.apply_air_gravity(delta)
	elif movement:
		movement.apply_gravity(delta)
	elif fighter:
		fighter.velocity.y += 2900.0 * delta

func _handle_landing() -> void:
	fighter.velocity = Vector2.ZERO
	if movement and movement.has_method("clear_active_jump"):
		movement.clear_active_jump()
	if input and input.is_action_pressed("down"):
		if posture:
			posture.apply("crouch")
		transition_requested.emit("CrouchState", {})
	else:
		if posture:
			posture.apply("stand")
		transition_requested.emit("IdleState", {})
