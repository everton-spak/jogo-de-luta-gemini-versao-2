class_name ShoryukenMove
extends MoveComponent

# Detector de Shoryuken: F, D, DF + soco
# Apenas no chão. O Shoryuken lança o personagem para cima.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 600

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Aceita F,D,F e também F,D,DF (quando o jogador termina no diagonal)
	var seq_ok = buffer.motions.is_sequence_buffered(["F", "D", "F"], true, buffer_window_msec) \
			or buffer.motions.is_sequence_buffered(["F", "D", "DF"], true, buffer_window_msec)
	if not seq_ok:
		return {}

	if fighter and not fighter.is_on_floor():
		return {}

	var button := ""
	var strength := ""
	if buffer.history.is_action_buffered("punch_heavy", buffer_window_msec):
		button = "punch_heavy"; strength = "heavy"
	elif buffer.history.is_action_buffered("punch_light", buffer_window_msec):
		button = "punch_light"; strength = "light"

	if button == "":
		return {}

	buffer.history.consume_action(button)
	return {"type": "shoryuken", "strength": strength, "stance": "ground"}
