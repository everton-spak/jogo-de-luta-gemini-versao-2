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
func is_sequence_buffered(sequence: Array, ignore_action_buttons: bool = false, window_msec: int = 0) -> bool:
	if not history: return false

	var cutoff = Time.get_ticks_msec() - (window_msec if window_msec > 0 else history.buffer_window_msec)
	var seq_index = sequence.size() - 1

	for i in range(history._buffer.size() - 1, -1, -1):
		var entry = history._buffer[i]
		if entry["timestamp"] < cutoff:
			break
		var input_name = entry["input"]
		if ignore_action_buttons and input_name in ACTION_BUTTONS:
			continue
		if input_name == sequence[seq_index]:
			seq_index -= 1
			if seq_index < 0:
				return true

	return false

# Nota: is_motion_with_buttons foi removido! 
# Agora usamos apenas is_sequence_buffered com o parâmetro 'true'.
