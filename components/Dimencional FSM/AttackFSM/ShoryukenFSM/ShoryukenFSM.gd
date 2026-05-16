class_name ShoryukenFSM
extends StateMachine

# O Shoryuken vive FORA do StandAttack para não ser interrompido pelo
# floor-check do StandAttack (o personagem sai do chão durante o DP).
# type_dim = "shoryuken" garante que esta FSM ganha mais pontos que StandAttack
# quando a query for de shoryuken.

var _was_airborne: bool = false

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "shoryuken"
	cancel_tier_dim = 3

func enter(payload: Dictionary = {}) -> void:
	_was_airborne = false
	super.enter(payload)

func get_machine_tags() -> Array[String]:
	return ["Attacking", "Airborne"]

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not fighter:
		return

	fighter.velocity.y += 2000.0 * delta

	if not fighter.is_on_floor():
		_was_airborne = true

	# Só monitora pouso depois de ter saído do chão
	if not _was_airborne:
		return

	# Quando começa a descer ou a animação termina, passa para Fall
	var anim_done = anim and not anim.is_playing()
	var descending = fighter.velocity.y >= 0.0

	if anim_done or descending:
		if fighter.is_on_floor():
			transition_requested.emit("IdleState", {})
		else:
			transition_requested.emit("FallState", {})
		return
