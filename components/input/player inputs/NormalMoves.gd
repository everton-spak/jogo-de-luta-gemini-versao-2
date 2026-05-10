class_name NormalMoves
extends MoveComponent # Certifique-se de que a classe MoveComponent existe

# Este componente não precisa de tags específicas, pois normais 
# costumam ser permitidos em quase qualquer estado neutro.
func _ready() -> void:
	allowed_tags = [] 

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# 1. Detectar qual botão foi apertado (Prioridade: Fortes > Fracos)
	var button = ""
	var strength = ""
	var type = ""

	if buffer.history.is_action_buffered("punch_heavy"):
		button = "punch_heavy"; strength = "heavy"; type = "punch"
	elif buffer.history.is_action_buffered("kick_heavy"):
		button = "kick_heavy"; strength = "heavy"; type = "kick"
	elif buffer.history.is_action_buffered("punch_light"):
		button = "punch_light"; strength = "light"; type = "punch"
	elif buffer.history.is_action_buffered("kick_light"):
		button = "kick_light"; strength = "light"; type = "kick"

	# 2. Se nenhum botão foi apertado, retorna vazio
	if button == "":
		return {}
		
	# 👇 ADICIONE ESTA LINHA PARA TESTE
	print("🎯 [NormalMoves] Botão detectado: ", button)

	# 3. Identificar a Postura (Stance)
	var stance = "ground"
	if fighter and not fighter.is_on_floor():
		stance = "air"
	elif buffer.input and buffer.input.get_movement_direction().y > 0.5:
		stance = "crouch"
	
	# 4. Consumir o input para não repetir o golpe no próximo frame
	buffer.history.consume_action(button)

	# 5. RETORNAR A QUERY (O envelope que a FSM vai ler)
	return {
		"type": type,
		"strength": strength,
		"stance": stance
	}
