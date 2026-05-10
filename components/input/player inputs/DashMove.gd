class_name DashMove
extends MoveComponent

# Configuração opcional se quiser usar allowed_tags no Inspector
func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Ground", "Neutral"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Descobre para que lado o personagem está a olhar
	var facing = 1.0
	var fsm = null
	if buffer.fighter:
		fsm = buffer.fighter.get_component("StateMachine")
		var f_comp = buffer.fighter.get_component("FacingComponent")
		if f_comp:
			facing = f_comp.current_facing
			
	# Bloqueio Anti-Spam: Não permite iniciar um novo Dash se já estiver no meio de um!
	if fsm and "Dashing" in fsm.get_tags():
		return {}

	# 1. Verifica Forward Dash (Frente -> Neutro -> Frente)
	if buffer.motions.is_sequence_buffered(["F", "N", "F"]):
		buffer.history._buffer.clear() # Limpa para não dar dashes infinitos
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dash_dir": "forward",
			"dir_x": 1.0 * facing # Direção global corrigida!
		}
		
	# 2. Verifica Backdash (Trás -> Neutro -> Trás)
	if buffer.motions.is_sequence_buffered(["B", "N", "B"]):
		buffer.history._buffer.clear() # Limpa o buffer
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dash_dir": "backward",
			"dir_x": -1.0 * facing # Direção global corrigida!
		}
		
	# Se não fez a sequência, retorna dicionário vazio
	return {}
