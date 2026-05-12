class_name HadoukenMove
extends MoveComponent

# Detector de Hadouken: Meia-lua para frente (D, DF, F) + soco
# Funciona nos chão, agachado e no ar.
func _ready() -> void:
	allowed_tags = ["Cancellable"]
	buffer_window_msec = 350

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	var seq_ok = buffer.motions.is_sequence_buffered(["D", "DF", "F"], true, buffer_window_msec)
	if not seq_ok:
		return {}

	var button := ""
	var strength := ""
	if buffer.history.is_action_buffered("punch_heavy", buffer_window_msec):
		button = "punch_heavy"; strength = "heavy"
	elif buffer.history.is_action_buffered("punch_light", buffer_window_msec):
		button = "punch_light"; strength = "light"

	if button == "":
		return {}

	var stance := "ground"
	if fighter and not fighter.is_on_floor():
		stance = "air"
	elif buffer.input:
		var dir = buffer.input.get_movement_direction()
		if dir.y > 0.5:
			stance = "crouch"

	buffer.history.consume_action(button)
	return {"type": "hadouken", "strength": strength, "stance": stance}
