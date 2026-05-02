class_name DivekickMove
extends MoveComponent

func _ready() -> void:
	target_state_name = "DivekickState"
	
	# O SEGREDO ESTÁ AQUI: Este golpe só sai se o estado atual tiver a tag "Airborne"
	allowed_tags = ["Airborne"] 

func check_execution(buffer: InputBuffer) -> bool:
	# O jogador segurou Baixo e apertou o Chute Forte?
	if buffer.is_motion_with_buttons(["D"], ["kick_strong"]):
		buffer.consume_sequence()
		return true
	return false
