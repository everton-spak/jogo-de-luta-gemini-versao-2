class_name CrouchMovement
extends StateMachine

func _ready() -> void:
	stance_dim = "crouch"
	type_dim = "movement"
	cancel_tier_dim = 0

func get_machine_tags() -> Array[String]:
	# A tag "Crouched" é essencial aqui para a Hurtbox saber que ele está pequeno
	return ["Crouched", "Cancellable"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	
	# Física: Garante atrito constante para ele não deslizar se agachar num pulo/dash
	if movement:
		movement.apply_friction(4000.0, delta)
		movement.commit_movement()

	if fighter and not fighter.is_on_floor():
		transition_requested.emit("Fall", {})
