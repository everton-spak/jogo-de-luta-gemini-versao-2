class_name ChargeTrackerComponent
extends Component

# A "janela de tolerância" (em milissegundos). 
# Permite que o jogador solte o direcional para fazer o golpe final 
# sem perder a carga imediatamente.
@export var charge_grace_msec: int = 250

# --- CARGAS DE DIREÇÃO ---
# _dir_charge_time: Guarda quantos milissegundos o jogador já acumulou.
var _dir_charge_time: Dictionary = {"B": 0.0, "D": 0.0}

# _dir_drop_time: Regista o exato momento (timestamp) em que o jogador 
# SOLTOU a direção. É usado em conjunto com a charge_grace_msec.
var _dir_drop_time: Dictionary = {"B": 0, "D": 0}

# --- CARGAS DE BOTÃO ---
# Aqui só precisamos guardar o tempo acumulado de cada botão de ataque. 
# Não usamos janela de tolerância para botões (geralmente, soltou o botão = disparou o golpe).
var _btn_charge_time: Dictionary = {}

# Referências para sabermos de onde puxar a informação
var interpreter: DirectionalInterpreterComponent 
var input: Component

func _on_initialized() -> void:
	# O ComponentManager chama isto. Vamos buscar o Tradutor de Direções 
	# e o Capturador de Input Bruto automaticamente[cite: 3, 4].
	interpreter = get_component("DirectionalInterpreterComponent")
	input = get_component("InputComponent")
	
func _physics_process(delta: float) -> void:
	# Captura o tempo atual do motor do jogo (ex: 15400 milissegundos desde que o jogo abriu)
	var current_time = Time.get_ticks_msec()
	
	# ==========================================
	# PARTE 1: PROCESSAMENTO DE DIREÇÕES
	# ==========================================
	if interpreter:
		# Pega a direção atual como string (Ex: "DB" para Diagonal Trás-Baixo)[cite: 3]
		var dir_string = interpreter.get_direction_string()
		
		# Testamos tanto o "B" (Trás) quanto o "D" (Baixo)
		for key in ["B", "D"]:
			# A mágica do 'in': Se o jogador segurar "DB", o "B" está dentro de "DB" e o "D" também!
			# Assim ele carrega os dois golpes (Sonic Boom e Flash Kick) ao mesmo tempo[cite: 2].
			if key in dir_string:
				# delta é o tempo do frame (ex: 0.016s). Multiplicamos por 1000 para virar ms.
				_dir_charge_time[key] += delta * 1000.0
				
				# Continua a atualizar a "última vez que segurou" para AGORA
				_dir_drop_time[key] = current_time
			else:
				# SE SOLTOU A DIREÇÃO:
				# Verifica se o tempo que passou desde que soltou já ultrapassou a tolerância.
				# Se sim, zera a carga. Se não, a carga é mantida viva por um triz![cite: 2]
				if current_time - _dir_drop_time[key] > charge_grace_msec:
					_dir_charge_time[key] = 0.0

	# ==========================================
	# PARTE 2: PROCESSAMENTO DE BOTÕES
	# ==========================================
	if input:
		# Lemos os botões brutos diretamente do hardware/sistema de input[cite: 4, 6]
		for btn in ["punch_light", "punch_heavy", "kick_light", "kick_heavy"]:
			if input.is_action_pressed(btn):
				# O .get(btn, 0.0) previne erros caso o botão ainda não exista no dicionário.
				# Vai somando o tempo que o jogador fica a segurar o soco/chute.
				_btn_charge_time[btn] = _btn_charge_time.get(btn, 0.0) + (delta * 1000.0)
			else:
				# Ao contrário das direções, se soltar o botão de ataque, a carga zera na hora.
				# (O golpe já vai ler esse valor antes de zerar através do histórico de _up)
				_btn_charge_time[btn] = 0.0
				
				
# Usado por golpes como o Sonic Boom do Guile.
# Pergunta: "A direção 'B' já foi segurada por pelo menos 600 milissegundos?"[cite: 2]
func is_dir_charge_ready(dir: String, msec: float) -> bool:
	return _dir_charge_time.get(dir, 0.0) >= msec

# Usado por golpes como o Turn Punch do Balrog.
# Pergunta: "Quantos milissegundos o jogador segurou o Soco Forte antes de soltar?"
func get_button_charge_time(btn: String) -> float:
	return _btn_charge_time.get(btn, 0.0)
