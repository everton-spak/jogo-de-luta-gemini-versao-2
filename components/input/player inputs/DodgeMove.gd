class_name DodgeMove
extends MoveComponent

# Double-tap pra baixo (D, N, D) → esquiva/cambalhota pra trás (oposto do facing).
# Distinto do crouch (que é segurar pra baixo) por exigir o N entre os toques.

func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Ground", "Neutral"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var facing := 1.0
	var fsm = null
	if buffer.fighter:
		fsm = buffer.fighter.get_component("StateMachine")
		var f_comp = buffer.fighter.get_component("FacingComponent")
		if f_comp:
			facing = f_comp.current_facing

	# Anti-spam: não inicia dodge se já estiver em movimento especial (dash/dodge).
	if fsm and "Dashing" in fsm.get_tags():
		return {}

	if buffer.motions.is_sequence_buffered(["D", "N", "D"]):
		buffer.history._buffer.clear()
		return {
			"type": "dodge",
			"stance": "ground",
			"direction": "any",
			"dir_x": -1.0 * facing # rola pra trás (afasta do oponente)
		}

	return {}
