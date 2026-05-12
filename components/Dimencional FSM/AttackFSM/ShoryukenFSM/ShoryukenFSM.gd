class_name ShoryukenFSM
extends StateMachine

# O Shoryuken vive FORA do StandAttack para não ser interrompido pelo
# floor-check do StandAttack (o personagem sai do chão durante o DP).
# type_dim = "shoryuken" garante que esta FSM ganha mais pontos que StandAttack
# quando a query for de shoryuken.
func _ready() -> void:
	stance_dim = "ground"
	type_dim = "shoryuken"
	cancel_tier_dim = 3

func get_machine_tags() -> Array[String]:
	return ["Attacking", "Airborne"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not fighter:
		return

	fighter.velocity.y += 2000.0 * delta

	if current_state == null or current_state.state_time_sec <= 0.1:
		return

	# Quando a animação do DP termina, vai para FallState (ar) ou Idle (chão)
	if anim and not anim.is_playing():
		if fighter.is_on_floor():
			transition_requested.emit("IdleState", {})
		else:
			transition_requested.emit("FallState", {})
		return

	# Segurança: se aterrou antes da animação acabar (DP muito curto), volta ao Idle
	if fighter.is_on_floor():
		transition_requested.emit("IdleState", {})
