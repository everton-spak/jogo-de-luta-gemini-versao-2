class_name ShoryukenMove
extends MoveComponent

# F, D, DF (ou F, D, F) + soco. Apenas no chão.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 600

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var seq_ok = buffer.motions.is_sequence_buffered(["F", "D", "F"], true, buffer_window_msec) \
			or buffer.motions.is_sequence_buffered(["F", "D", "DF"], true, buffer_window_msec)
	if not seq_ok:
		return {}

	if fighter and not fighter.is_on_floor():
		return {}

	var btn = _resolve_strength_button(buffer, "punch", buffer_window_msec)
	if btn.is_empty(): return {}

	buffer.history.consume_action(btn.button)
	return {"type": "shoryuken", "strength": btn.strength, "stance": "ground"}
