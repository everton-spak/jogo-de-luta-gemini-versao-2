class_name DashState
extends State

@export_group("Configuração do Dash")
@export var dash_speed: float = 600.0
## Distância exata (em pixels) que o personagem vai percorrer
@export var dash_distance: float = 180.0 
@export var recovery_state: String = "IdleState"
@export var run_state: String = "RunState"

# Variável interna para lembrar a direção durante o frame update
var _current_dir: float = 1.0 
var _distance_travelled: float = 0.0 # 👈 Novo contador de distância

func _ready() -> void:
	# Configurações para a FSM achar este estado
	type_dim = "movement"
	stance_dim = "ground"
	direction_dim = "any"
	# tier = 0 (Pode ser interrompido por golpes, se você quiser permitir Dash-Cancels!)

func enter(payload: Dictionary = {}) -> void:
	print("💨 [DashState] Iniciando Dash!")
	
	# 1. PEGAR A DIREÇÃO DO PAYLOAD
	# Assumimos que o InputBuffer envia "dir_x" (1 para direita, -1 para esquerda)
	var query_dict = payload.get("query", {})
	_current_dir = query_dict.get("dir_x", 1.0)
	# 1. Zera a distância sempre que um novo dash começar
	_distance_travelled = 0.0
	
	# 2. APLICAR VELOCIDADE INICIAL
	if fighter:
		fighter.velocity.x = dash_speed * _current_dir
		fighter.velocity.y = 0 # Garante que o dash é colado no chão
		
	# 3. TOCAR ANIMAÇÃO CORRETA
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		# 💡 DICA: Como você tem um 'FacingComponent' na sua árvore, 
		# num futuro próximo você pode comparar _current_dir com o lado que o 
		# boneco está virado para saber se é "forward" ou "backward".
		# Por enquanto, vamos usar uma lógica simples direita/esquerda:
		if _current_dir > 0:
			anim.play("dash_forward")
		else:
			anim.play("dash_backward")

func physics_update(_delta: float) -> void:
	# 1. MANTER A VELOCIDADE (Atrito zero durante o dash)
	if fighter:
		fighter.velocity.x = dash_speed * _current_dir

	# 2. CONDIÇÃO DE SAÍDA (Baseado na duração da animação)
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	
			
	# 2. A MÁGICA DA DISTÂNCIA:
		# Velocidade * Delta = Pixels percorridos no exato frame atual
		_distance_travelled += dash_speed * _delta

		# 3. CONDIÇÃO DE SAÍDA DUPLA:
		# Termina o dash se atingiu a distância limite OU se bateu numa parede/oponente
		if _distance_travelled >= dash_distance or fighter.is_on_wall():
			fighter.velocity.x = 0 
			_check_next_state() # 👈 Chama o inspetor de estado
			
# 👇 A MÁGICA DA TRANSIÇÃO CONTÍNUA
func _check_next_state() -> void:
	# 1. Se for um Backdash (para trás), volta pro Idle sempre! Não existe correr de costas.
	if _current_dir < 0:
		transition_requested.emit(recovery_state, {})
		return
		
	# 2. Se for para frente, verifica se o botão AINDA está pressionado
	var is_holding_forward = false
	var input_comp = fighter.get_component("InputComponent")
	
	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		# Verifica se a direção do analógico/teclado é a mesma do dash original
		if sign(current_input.x) == sign(_current_dir) and current_input.x != 0:
			is_holding_forward = true

	# 3. Faz o roteamento
	if is_holding_forward:
		print("🔄 [DashState] Emendando Dash direto na Corrida!")
		# Passa o payload com a direção para a Corrida saber para onde ir
		var run_payload = {"query": {"dir_x": _current_dir}}
		transition_requested.emit(run_state, run_payload)
	else:
		print("🛑 [DashState] Jogador soltou o botão. Voltando ao Idle.")
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	# "Dashing" diz ao InputBuffer que estamos no meio de um dash
	return ["Dashing", "Ground", "Movement"]
