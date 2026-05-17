class_name JoudanMove
extends MoveComponent

# QCF + chute. No chão = joudan; no ar = divekick.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 400

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	if not buffer.motions.is_sequence_buffered(["D", "DF", "F"], true, buffer_window_msec):
		return {}

	var btn = _resolve_strength_button(buffer, "kick", buffer_window_msec)
	if btn.is_empty(): return {}

	buffer.history.consume_action(btn.button)

	if fighter and not fighter.is_on_floor():
		return {"type": "divekick", "strength": btn.strength, "stance": "air"}
	return {"type": "joudan", "strength": btn.strength, "stance": "ground"}
