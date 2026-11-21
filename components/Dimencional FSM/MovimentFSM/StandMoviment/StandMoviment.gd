class_name StandMovement
extends StateMachine

func _ready() -> void:
	# Define as dimensões da pasta (type_dim = "any" pra permitir Dodge/MeterCharge além de Movement)
	stance_dim = "ground"
	type_dim = "any"
	cancel_tier_dim = 0 # Nível mais baixo. Qualquer ataque ou especial pode cancelar isto!

func get_machine_tags() -> Array[String]:
	# Todos os filhos (Idle, Walk, Dash) herdam "Grounded" e "Cancellable"
	return ["Grounded", "Cancellable"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Trava de Segurança Universal do Chão:
	# Se o jogador estiver a andar (Walk) e o chão acabar, esta FSM pai
	# deteta a queda e aborta o movimento, mandando o lutador para o ar.
	if fighter and not fighter.is_on_floor():
		transition_requested.emit("FallState", {})
