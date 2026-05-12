class_name TatsumakiMove
extends MoveComponent

# Detector de Tatsumaki: Meia-lua para trás (D, DB, B) + chute
# Funciona no chão, agachado e no ar.
func _ready() -> void:
	allowed_tags = ["Cancellable"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	if not buffer.motions.is_sequence_buffered(["D", "DB", "B"], true):
		return {}

	var button := ""
	var strength := ""
	if buffer.history.is_action_buffered("kick_heavy"):
		button = "kick_heavy"; strength = "heavy"
	elif buffer.history.is_action_buffered("kick_light"):
		button = "kick_light"; strength = "light"

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
	return {"type": "tatsumaki", "strength": strength, "stance": stance}
