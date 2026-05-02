class_name SlideMove
extends MoveComponent

func _ready() -> void:
	target_state_name = "SlideState"
	
	# O jogador pode fazer o Slide de pé (Idle/Walk) ou já agachado (Crouching)
	allowed_tags = ["Grounded", "Crouching"] 

func check_execution(buffer: InputBuffer) -> bool:
	# O comando clássico do Slide: Diagonal Baixo-Frente + Chute Forte
	if buffer.is_motion_with_buttons(["DF"], ["kick_strong"]):
		buffer.consume_sequence()
		return true
		
	return false
