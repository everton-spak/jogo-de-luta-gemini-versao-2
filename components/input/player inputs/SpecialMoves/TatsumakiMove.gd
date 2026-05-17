class_name TatsumakiMove
extends MoveComponent

# Meia-lua para trás (D, DB, B) + chute. Chão, agachado e ar.
func _ready() -> void:
	allowed_tags = ["Cancellable"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	if not buffer.motions.is_sequence_buffered(["D", "DB", "B"], true):
		return {}

	var btn = _resolve_strength_button(buffer, "kick", buffer_window_msec)
	if btn.is_empty(): return {}

	buffer.history.consume_action(btn.button)
	return {"type": "tatsumaki", "strength": btn.strength, "stance": _detect_stance(buffer)}
