class_name AirMovement
extends StateMachine

func _ready() -> void:
	stance_dim = "air"
	type_dim = "movement"
	cancel_tier_dim = 0

func get_machine_tags() -> Array[String]:
	if current_state is JumpState and (current_state as JumpState).is_prejump():
		return []
	return ["Airborne", "Cancellable"]
