class_name InputHistoryComponent
extends Component

# Janela de tempo (ms) que um input permanece no buffer
@export var buffer_window_msec: int = 250

# A lista bruta de inputs: [{"input": "F", "timestamp": 12345}, ...]
var _buffer: Array[Dictionary] = []

func _physics_process(_delta: float) -> void:
	_clean_old_inputs()

# Adiciona um novo comando à lista com o tempo atual
func _add_to_buffer(input_name: String) -> void:
	_buffer.append({
		"input": input_name,
		"timestamp": Time.get_ticks_msec()
	})

# Remove inputs que já passaram do tempo limite (msec)
func _clean_old_inputs() -> void:
	var current_time = Time.get_ticks_msec()
	_buffer = _buffer.filter(func(item): return current_time - item["timestamp"] <= buffer_window_msec)

# Verifica se um botão específico existe no histórico
func is_action_buffered(action_name: String) -> bool:
	for item in _buffer:
		if item["input"] == action_name:
			return true
	return false

# Remove um input do buffer (usado para o golpe não sair duas vezes)
func consume_action(action_name: String) -> void:
	for i in range(_buffer.size() - 1, -1, -1):
		if _buffer[i]["input"] == action_name:
			_buffer.remove_at(i)
			break
