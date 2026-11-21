class_name DashMove
extends MoveComponent

# Configuração opcional se quiser usar allowed_tags no Inspector
func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Ground", "Neutral"]
	buffer_window_msec = 220

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	if not fighter or not fighter.is_on_floor():
		return {}

	# Descobre para que lado o personagem está a olhar
	var facing = 1.0
	var fsm = null
	if buffer.fighter:
		fsm = buffer.fighter.get_component("StateMachine")
		var f_comp = buffer.fighter.get_component("FacingComponent")
		if f_comp:
			facing = f_comp.current_facing
			
	# Bloqueio Anti-Spam: Não permite dash se já estiver em dash, corrida ou dodge!
	if fsm:
		var tags = fsm.get_tags()
		if "Dashing" in tags or "Run" in tags or "Dodge" in tags:
			return {}

	# 1. Verifica Forward Dash (Frente -> Neutro -> Frente) dentro da janela de tap
	if buffer.motions.is_sequence_buffered(["F", "N", "F"], false, buffer_window_msec):
		buffer.history.consume_all_action("F")
		buffer.history.consume_all_action("N")
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dash_dir": "forward",
			"dir_x": 1.0 * facing
		}
		
	# 2. Verifica Backdash (Trás -> Neutro -> Trás)
	if buffer.motions.is_sequence_buffered(["B", "N", "B"], false, buffer_window_msec):
		buffer.history.consume_all_action("B")
		buffer.history.consume_all_action("N")
		return {
			"type": "movement",
			"stance": "ground",
			"direction": "any",
			"dash_dir": "backward",
			"dir_x": -1.0 * facing
		}
		
	return {}
