class_name CrouchAttack
extends StateMachine

func _ready() -> void:
	stance_dim = "crouch"

func enter(payload: Dictionary = {}) -> void:
	if fighter:
		if posture: posture.apply("crouch")
	super.enter(payload)

func get_machine_tags() -> Array[String]:
	# Injeta as tags necessárias para o sistema de colisão e animação.
	# "Crouched" avisa o sistema de defesa que este golpe pode ser um "Low" 
	# ou que o personagem deve usar a Hurtbox de agachado.
	return ["Attacking", "Crouched"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if fighter:
		if fighter.is_on_floor():
			fighter.velocity.y = 0
		else:
			fighter.velocity.y += 2000.0 * delta
			transition_requested.emit("Fall", {})

	if movement:
		movement.apply_friction(4000.0, delta)
		movement.commit_movement()
