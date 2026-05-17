class_name DashState
extends State

@export_group("Configuração do Forward Dash")
@export var dash_speed: float = 750.0
@export var dash_distance: float = 200.0 
@export var run_state: String = "RunState"

@export_group("Configuração do Backdash")
@export var backdash_speed: float = 550.0
@export var backdash_distance: float = 140.0
#@export var recovery_state: String = "IdleState"

# Variáveis internas
var _current_dir: float = 1.0 
var _distance_travelled: float = 0.0
var _current_dash_speed: float = 0.0
var _current_dash_distance: float = 0.0
var _is_backdash: bool = false

func _ready() -> void:
	# Configurações para a FSM achar este estado
	type_dim = "movement"
	stance_dim = "ground"
	direction_dim = "any"
	recovery_state = "IdleState"
	# tier = 0 (Pode ser interrompido por golpes, se você quiser permitir Dash-Cancels!)

func enter(payload: Dictionary = {}) -> void:
	#print("💨 [DashState] Iniciando Dash!")
	
	# 1. PEGAR A DIREÇÃO DO PAYLOAD
	var query_dict = payload.get("query", {})
	_current_dir = query_dict.get("dir_x", 1.0)
	var direction_type = query_dict.get("dash_dir", "forward")
	_is_backdash = (direction_type == "backward")
	
	# Configura as propriedades do dash atual
	if _is_backdash:
		_current_dash_speed = backdash_speed
		_current_dash_distance = backdash_distance
	else:
		_current_dash_speed = dash_speed
		_current_dash_distance = dash_distance
		
	# Zera a distância sempre que um novo dash começar
	_distance_travelled = 0.0
	
	# 2. APLICAR VELOCIDADE INICIAL
	if fighter:
		fighter.velocity.x = _current_dash_speed * _current_dir
		fighter.velocity.y = 0 # Garante que o dash é colado no chão
		
	# 3. TOCAR ANIMAÇÃO CORRETA
	if anim:
		if not _is_backdash:
			anim.play("dash_forward")
		else:
			anim.play("dash_backward")

func physics_update(_delta: float) -> void:
	# 1. DESACELERAÇÃO SUAVE NO FINAL DO DASH (Friction)
	# Se já percorreu 70% do caminho, começa a diminuir a velocidade para um pouso mais natural
	var progress = _distance_travelled / max(1.0, _current_dash_distance)
	var speed_multiplier = 1.0
	if progress > 0.7:
		# Transição suave de 1.0 para 0.3 na reta final
		speed_multiplier = lerp(1.0, 0.3, (progress - 0.7) / 0.3)
		
	var actual_speed = _current_dash_speed * speed_multiplier

	if fighter:
		fighter.velocity.x = actual_speed * _current_dir

	# 2. A MÁGICA DA DISTÂNCIA:
	_distance_travelled += actual_speed * _delta

	# 3. CONDIÇÃO DE SAÍDA DUPLA:
	if _distance_travelled >= _current_dash_distance or fighter.is_on_wall():
			fighter.velocity.x = 0 
			_check_next_state() # 👈 Chama o inspetor de estado
			
# 👇 A MÁGICA DA TRANSIÇÃO CONTÍNUA
func _check_next_state() -> void:
	# 1. Se for um Backdash (para trás), volta pro Idle sempre! Não existe correr de costas.
	if _is_backdash:
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
		#print("🔄 [DashState] Emendando Dash direto na Corrida!")
		# aPassa o payload com a direção para a Corrida saber para onde ir
		var run_payload = {"query": {"dir_x": _current_dir}}
		transition_requested.emit(run_state, run_payload)
	else:
		#print("🛑 [DashState] Jogador soltou o botão. Voltando ao Idle.")
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	# "Dashing" diz ao InputBuffer que estamos no meio de um dash
	return ["Dashing", "Ground", "Movement"]
