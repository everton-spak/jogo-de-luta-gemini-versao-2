class_name MovementStateMachine
extends StateMachine

func _ready() -> void:
	# Como esta é a pasta RAIZ de movimentação, ela precisa ser um "Coringa" absoluto.
	# Ela aceita qualquer postura (stance) e qualquer tipo (type), 
	# deixando a filtragem pesada para as sub-pastas (Stand, Air, Crouch).
	stance_dim = "any"
	type_dim = "any" 
	
	# O nível de cancelamento mais baixo possível. 
	# Qualquer ataque (Tier 1+) pode interromper a movimentação!
	cancel_tier_dim = 0 

func get_machine_tags() -> Array[String]:
	# Não precisamos injetar "Grounded" ou "Airborne" aqui, porque 
	# as pastas filhas (StandMovement, AirMovement) já farão isso.
	# Mas podemos injetar uma tag de controle geral para a IA ou debug:
	return ["Mobility"]

func physics_update(delta: float) -> void:
	# Apenas repassa o ciclo de física para a pasta filha que estiver ativa 
	# (ex: para o StandMovement aplicar o atrito, ou AirMovement aplicar gravidade).
	super.physics_update(delta)
