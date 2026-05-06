class_name MotionInterpreterComponent
extends Component

# Janela para considerar botões apertados "ao mesmo tempo" (ex: para golpes EX)
@export var simultaneous_tolerance_msec: int = 50

# Lista de botões que devem ser ignorados ao ler sequências direcionais
const ACTION_BUTTONS = ["punch_heavy", "kick_heavy", "punch_light", "kick_light"]

var history: InputHistoryComponent

func _on_initialized() -> void:
	history = get_component("InputHistoryComponent")

# Verifica se uma sequência (ex: ["D", "DF", "F"]) foi realizada na ordem correta
func is_sequence_buffered(sequence: Array) -> bool:
	if history._buffer.size() < sequence.size(): return false
	
	var seq_index = sequence.size() - 1
	# Percorre o buffer de trás para frente para achar o comando mais recente primeiro
	for i in range(history._buffer.size() - 1, -1, -1):
		if history._buffer[i]["input"] == sequence[seq_index]:
			seq_index -= 1
			if seq_index < 0: return true
	return false

# Mesma lógica, mas ignora botões de ataque amassados no meio da sequência
func is_motion_with_buttons(motion: Array, buttons: Array) -> bool:
	# Primeiro verifica se os botões foram apertados juntos
	if not is_simultaneous_buffered(buttons): return false
	
	var motion_index = motion.size() - 1
	for i in range(history._buffer.size() - 1, -1, -1):
		var input_name = history._buffer[i]["input"]
		
		# Pula botões de ataque para não quebrar a leitura da "meia-lua"
		if input_name in ACTION_BUTTONS: continue
			
		if input_name == motion[motion_index]:
			motion_index -= 1
			if motion_index < 0: return true
	return false

# Verifica se múltiplos botões foram apertados dentro da janela de tolerância
func is_simultaneous_buffered(actions: Array) -> bool:
	var timestamps: Array[int] = []
	for action in actions:
		var found = false
		for i in range(history._buffer.size() - 1, -1, -1):
			if history._buffer[i]["input"] == action:
				timestamps.append(history._buffer[i]["timestamp"])
				found = true
				break
		if not found: return false
			
	return (timestamps.max() - timestamps.min()) <= simultaneous_tolerance_msec
