class_name MoveComponent
extends Component

@export_group("Configurações de Estado")
@export var target_state_name: String
@export var allowed_tags: Array[String] = ["Grounded"]
# Janela de tempo (ms) para detectar a sequência deste golpe. 0 = usa o global
@export var buffer_window_msec: int = 0

@export_group("Negative Edge (Release)")
# Se ativado, o golpe pode ser disparado ao soltar o botão
@export var allow_negative_edge: bool = false
# Janela de tempo específica para o Negative Edge (geralmente menor que a do buffer)
@export var negative_edge_window_msec: int = 100

var attack_component: Component

# --- FUNÇÃO DE INTERFACE ---
# Esta função será sobrescrita pelos filhos (NormalMove, SpecialMove, etc.)
# Ela retorna um Dictionary com os dados do golpe ou um Dictionary vazio {} se falhar.
func check_execution_query(_buffer: InputBuffer) -> Dictionary:
	return {}

# Detecta postura atual: "air", "crouch" ou "ground"
func _detect_stance(buffer: InputBuffer) -> String:
	if fighter and not fighter.is_on_floor():
		return "air"
	if buffer.input:
		var dir = buffer.input.get_movement_direction()
		if dir.y > 0.5:
			return "crouch"
	return "ground"

# Resolve botão e strength a partir do prefix ("punch" ou "kick").
# Retorna {} se nenhum botão buffered. Caller consome o botão se quiser.
func _resolve_strength_button(buffer: InputBuffer, prefix: String, window: int = 0) -> Dictionary:
	var w = window if window > 0 else buffer_window_msec
	if buffer.history.is_action_buffered(prefix + "_heavy", w):
		return {"button": prefix + "_heavy", "strength": "heavy"}
	if buffer.history.is_action_buffered(prefix + "_light", w):
		return {"button": prefix + "_light", "strength": "light"}
	return {}
