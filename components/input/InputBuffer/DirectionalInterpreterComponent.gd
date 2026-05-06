class_name DirectionalInterpreterComponent
extends Component

var input: Component
var facing_component: Component

func _on_initialized() -> void:
	# Localiza os componentes irmãos necessários
	input = get_component("InputComponent")
	facing_component = get_component("FacingComponent")

# Converte o vetor do comando em string (ex: Vector2(1,1) -> "DF")
func get_direction_string() -> String:
	if not input: return "N"
	var v = input.get_movement_direction()
	
	# Se não houver direção, é Neutro
	if v == Vector2.ZERO: return "N"
	
	# Determina para onde o personagem está a olhar (1 ou -1)
	var facing = 1.0
	if facing_component:
		facing = facing_component.current_facing
		
	# Inverte o eixo X se o personagem estiver virado para a esquerda
	var forward = v.x * facing
	
	# Mapeamento Geométrico (Lógica original do teu buffer)
	if v.y > 0.5 and forward > 0.5: return "DF"
	if v.y > 0.5 and forward < -0.5: return "DB"
	if v.y < -0.5 and forward > 0.5: return "UF"
	if v.y < -0.5 and forward < -0.5: return "UB"
	if v.y > 0.5: return "D"
	if v.y < -0.5: return "U"
	if forward > 0.5: return "F"
	if forward < -0.5: return "B"
	
	return "N"
