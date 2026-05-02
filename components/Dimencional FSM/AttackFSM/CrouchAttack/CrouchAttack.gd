class_name CrouchAttack
extends StateMachine

func _ready() -> void:
	# Define a dimensão de postura como agachado
	stance_dim = "crouch"

func get_machine_tags() -> Array[String]:
	# Injeta as tags necessárias para o sistema de colisão e animação.
	# "Crouched" avisa o sistema de defesa que este golpe pode ser um "Low" 
	# ou que o personagem deve usar a Hurtbox de agachado.
	return ["Attacking", "Crouched"]

func physics_update(delta: float) -> void:
	# 1. Executa a lógica do golpe filho (ex: CrouchLightKick, CrouchHeavyPunch)
	super.physics_update(delta)
	
	# 2. Física Global de Agachado:
	# Mantém o personagem fixo no lugar durante o golpe agachado.
	if movement:
		movement.apply_friction(4000.0, delta) # Atrito geralmente maior que em pé
		movement.commit_movement()

	# 3. Verificação de Integridade:
	# Se o lutador perder o contato com o chão durante o ataque agachado,
	# ele deve entrar em estado de queda imediatamente.
	if fighter and not fighter.is_on_floor():
		transition_requested.emit("Fall", {})
