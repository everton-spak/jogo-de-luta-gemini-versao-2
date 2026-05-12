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
