class_name HadoukenMove
extends MoveComponent

# Meia-lua para frente (D, DF, F) + soco. Chão, agachado e ar.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 350

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	if not buffer.motions.is_sequence_buffered(["D", "DF", "F"], true, buffer_window_msec):
		return {}

	var btn = _resolve_strength_button(buffer, "punch", buffer_window_msec)
	if btn.is_empty(): return {}

	buffer.history.consume_action(btn.button)
	return {"type": "hadouken", "strength": btn.strength, "stance": _detect_stance(buffer)}
