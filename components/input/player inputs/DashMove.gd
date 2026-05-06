class_name DashMove
extends MoveComponent

# Configuração opcional se quiser usar allowed_tags no Inspector
func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Ground", "Neutral"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# 1. Verifica Forward Dash (Frente -> Neutro -> Frente)
	if buffer.motions.is_sequence_buffered(["F", "N", "F"]):
		buffer.history._buffer.clear() # Limpa para não dar dashes infinitos
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dir_x": 1.0 # Embutimos a direção na própria Query
		}
		
	# 2. Verifica Backdash (Trás -> Neutro -> Trás)
	if buffer.motions.is_sequence_buffered(["B", "N", "B"]):
		buffer.history._buffer.clear() # Limpa o buffer
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dir_x": -1.0
		}
		
	# Se não fez a sequência, retorna dicionário vazio (nada acontece)[cite: 3]
	return {}
