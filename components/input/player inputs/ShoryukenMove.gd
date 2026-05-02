class_name ShoryukenMove
extends MoveComponent

@export var allowed_buttons: Array[String] = ["punch_weak", "punch_strong"]

func _ready() -> void:
	target_state_name = "ShoryukenState"
	# Geralmente, Shoryuken só pode ser feito no chão, mas pode cancelar ataques normais!
	allowed_tags = ["Grounded", "Cancellable"]

func check_execution(buffer: InputBuffer) -> bool:
	# A clássica movimentação "Z": Frente, Baixo, Diagonal Baixo-Frente + Soco
	if buffer.is_motion_with_buttons(["F", "D", "DF"], allowed_buttons):
		buffer.consume_sequence()
		return true
		
	return false
