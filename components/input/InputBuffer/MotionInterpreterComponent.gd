class_name MotionInterpreterComponent
extends Component

# A lista de botões que o leitor de movimentos pode ignorar 
# se o jogador "esbarrar" neles enquanto faz uma meia-lua[cite: 6]
const ACTION_BUTTONS = ["punch_heavy", "kick_heavy", "punch_light", "kick_light"]

var history: InputHistoryComponent

func _on_initialized() -> void:
	history = get_component("InputHistoryComponent")

# Verifica se uma sequência (ex: ["D", "DF", "F"]) foi realizada na ordem correta.
# Adicionamos um parâmetro opcional 'ignore_action_buttons' para golpes mais complexos.
func is_sequence_buffered(sequence: Array, ignore_action_buttons: bool = false) -> bool:
	if not history or history._buffer.size() < sequence.size(): return false
	
	var seq_index = sequence.size() - 1
	for i in range(history._buffer.size() - 1, -1, -1):
		var input_name = history._buffer[i]["input"]
		
		# Se a opção estiver ativa, ele "pula" os botões de ataque
		# e continua procurando apenas as direções da meia-lua
		if ignore_action_buttons and input_name in ACTION_BUTTONS:
			continue
			
		if input_name == sequence[seq_index]:
			seq_index -= 1
			if seq_index < 0: 
				return true
				
	return false

# Nota: is_motion_with_buttons foi removido! 
# Agora usamos apenas is_sequence_buffered com o parâmetro 'true'.
