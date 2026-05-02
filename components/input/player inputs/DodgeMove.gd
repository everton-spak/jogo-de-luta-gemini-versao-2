class_name DodgeMove
extends MoveComponent

func _ready() -> void:
	target_state_name = "DodgeState"
	
	# O jogador pode esquivar se estiver parado, andando ou agachado!
	allowed_tags = ["Grounded", "Crouching"] 

func check_execution(buffer: InputBuffer) -> bool:
	var input = get_component("Input")
	if not input: return false
	
	# Aqui assumimos que você tem uma Action "dodge" no Input Map da Godot.
	# (Ou você poderia checar se ele apertou soco_fraco e chute_fraco no mesmo frame)
	if input.is_action_just_pressed("dodge"):
		# Não precisamos dar consume_sequence() aqui porque a esquiva geralmente 
		# é um botão reativo imediato e não consome motions como meia-lua.
		return true
		
	return false
