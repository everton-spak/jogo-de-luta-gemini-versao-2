class_name JoudanMove
extends MoveComponent

# QCF + chute: D, DF, F + kick_light ou kick_heavy. Apenas no chão.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 400

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var seq_ok = buffer.motions.is_sequence_buffered(["D", "DF", "F"], true, buffer_window_msec)
	if not seq_ok:
		return {}

	if fighter and not fighter.is_on_floor():
		return {}

	var button := ""
	var strength := ""
	if buffer.history.is_action_buffered("kick_heavy", buffer_window_msec):
		button = "kick_heavy"; strength = "heavy"
	elif buffer.history.is_action_buffered("kick_light", buffer_window_msec):
		button = "kick_light"; strength = "light"

	if button == "":
		return {}

	buffer.history.consume_action(button)
	return {"type": "joudan", "strength": strength, "stance": "ground"}
