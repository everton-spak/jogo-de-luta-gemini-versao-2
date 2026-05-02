class_name IdleState
extends State

func enter(_payload: Dictionary = {}) -> void:
	# Toca a animação de repouso
	if anim:
		anim.play("idle")

func physics_update(delta: float) -> void:
	if movement:
		movement.apply_friction(3000.0, delta)
		movement.commit_movement()

	if not input: 
		return
	
	var dir = input.get_movement_direction().x
	
	# Se o jogador apertar algo, o Idle avisa-nos!
	if dir != 0.0:
		print("🚶‍♂️ [IdleState] Li o direcional: ", dir, ". Pedindo transição para 'Walk'!")
		transition_requested.emit("WalkState", {})
