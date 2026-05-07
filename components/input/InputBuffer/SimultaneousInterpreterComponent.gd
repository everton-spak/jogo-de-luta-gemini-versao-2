class_name SimultaneousInterpreterComponent
extends Component

# Janela para considerar botões apertados "ao mesmo tempo" (ex: Agarrão, Golpes EX)
@export var simultaneous_tolerance_msec: int = 50

var history: InputHistoryComponent

func _on_initialized() -> void:
	history = get_component("InputHistoryComponent")

# Verifica se múltiplos botões foram apertados dentro da janela de tolerância
func is_simultaneous_buffered(actions: Array) -> bool:
	if not history or history._buffer.is_empty(): return false
	
	var timestamps: Array[int] = []
	for action in actions:
		var found = false
		# Procura de trás para a frente (mais recentes primeiro)
		for i in range(history._buffer.size() - 1, -1, -1):
			if history._buffer[i]["input"] == action:
				timestamps.append(history._buffer[i]["timestamp"])
				found = true
				break
		if not found: return false
			
	# Se a diferença entre o botão mais antigo e o mais novo for menor que a tolerância, é simultâneo!
	return (timestamps.max() - timestamps.min()) <= simultaneous_tolerance_msec

# Limpa todos os botões que foram usados juntos para não saírem golpes extra
func consume_simultaneous(actions: Array) -> void:
	if not history: return
	for action in actions:
		history.consume_action(action)
