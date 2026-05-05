class_name AirMovement
extends StateMachine

func _ready() -> void:
	stance_dim = "air"
	type_dim = "movement"
	cancel_tier_dim = 0

func get_machine_tags() -> Array[String]:
	# A tag Airborne diz ao sistema de hit que ele pode levar juggle
	return ["Airborne", "Cancellable"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Física Universal Aérea:
	# Não precisamos colocar gravidade no "Jump" e depois no "Fall".
	# Colocamos na FSM, e todos os estados aéreos caem automaticamente!
	if movement:
		movement.apply_gravity(delta)
		movement.commit_movement()

	# Aterrissagem Universal:
	# Se ele tocar no chão, seja num Jump ou num Fall, a FSM manda-o de volta à base.
	if fighter and fighter.is_on_floor():
		# Se quiser ser detalhista, pode verificar o input para ver se cai agachado
		var input_comp = get_component("InputComponent")
		if input_comp and input_comp.is_action_pressed("down"):
			transition_requested.emit("CrouchState", {})
		else:
			transition_requested.emit("IdleState", {})
