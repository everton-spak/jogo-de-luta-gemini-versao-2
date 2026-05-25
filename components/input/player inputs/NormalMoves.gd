class_name NormalMoves
extends MoveComponent # Certifique-se de que a classe MoveComponent existe

# Normais exigem que o estado atual permita cancelamentos (Cancellable).
# Estados neutros (Idle, Walk, Jump, Fall) dão essa tag.
# Estados de ataque NÃO dão essa tag por padrão, impedindo spam.

# TODOS os normais aguardam este tempo no buffer ANTES de firarem — dá tempo
# de detectar macros simultâneos (LP+LK = dodge, LP+HK = meter_charge, etc.)
# sem que NormalMoves consuma o primeiro botão antes do complemento chegar.
# Aplica-se a heavy E light igualmente pra simetria entre todos os macros.
const NORMAL_DELAY_MSEC: int = 34 # ~2 frames @ 60fps

func _ready() -> void:
	allowed_tags = ["Cancellable"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# 1. Detectar qual botão foi apertado (Prioridade: Fortes > Fracos).
	# Cada um precisa ter envelhecido NORMAL_DELAY_MSEC no buffer pra firar.
	var button = ""
	var strength = ""
	var type = ""

	if buffer.history.is_action_buffered("punch_heavy") and _is_aged_enough(buffer.history, "punch_heavy"):
		button = "punch_heavy"; strength = "heavy"; type = "punch"
	elif buffer.history.is_action_buffered("kick_heavy") and _is_aged_enough(buffer.history, "kick_heavy"):
		button = "kick_heavy"; strength = "heavy"; type = "kick"
	elif buffer.history.is_action_buffered("punch_light") and _is_aged_enough(buffer.history, "punch_light"):
		button = "punch_light"; strength = "light"; type = "punch"
	elif buffer.history.is_action_buffered("kick_light") and _is_aged_enough(buffer.history, "kick_light"):
		button = "kick_light"; strength = "light"; type = "kick"

	# 2. Se nenhum botão foi apertado, retorna vazio
	if button == "":
		return {}
		
	# 👇 ADICIONE ESTA LINHA PARA TESTE
	#print("🎯 [NormalMoves] Botão detectado: ", button)

	# 3. Identificar a Postura (Stance) e Pre-Jump Forgiveness
	var stance = "ground"
	
	if fighter and not fighter.is_on_floor():
		stance = "air"
	else:
		# Se o lutador está no chão, verificamos se ele está tentando pular (segurando para cima)
		var dir = buffer.input.get_movement_direction() if buffer.input else Vector2.ZERO
		if dir.y < -0.2:
			# INTENÇÃO DE PULO DETECTADA!
			# O jogador apertou soco 1 frame antes do pulo sair, ou o analógico ainda não chegou no topo.
			# Abortamos o soco no chão e NÃO consumimos o input!
			# Assim, no próximo frame o JumpMove fará o pulo, e no frame seguinte este NormalMoves fará o Soco Aéreo!
			return {}
			
		elif dir.y > 0.5:
			stance = "crouch"
	
	# 4. Consumir o input para não repetir o golpe no próximo frame
	buffer.history.consume_action(button)

	# 5. RETORNAR A QUERY (O envelope que a FSM vai ler)
	return {
		"type": type,
		"strength": strength,
		"stance": stance
	}

# Procura a entrada mais antiga deste action no buffer e checa se já passaram
# NORMAL_DELAY_MSEC desde então. Se sim, libera o firing do normal.
func _is_aged_enough(history: InputHistoryComponent, action: String) -> bool:
	var now: int = Time.get_ticks_msec()
	for item in history._buffer:
		if item["input"] == action:
			return (now - int(item["timestamp"])) >= NORMAL_DELAY_MSEC
	return false
