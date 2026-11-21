class_name Fighter
extends CharacterBody2D

@export var target_fighter: CharacterBody2D

# VERIFIQUE O NOME DO SEU NÓ (Se é $Component ou $ComponentManager)
@onready var component_manager: Component = $Component
@onready var root_fsm: StateMachine = $Component/StateMachine

const ARENA_MIN_X: float = 45.0
const ARENA_MAX_X: float = 1875.0
const PUSHBOX_MIN_DIST: float = 110.0
const PUSHBOX_MAX_VERT_DIST: float = 240.0

# Trava de segurança: bloqueia _physics_process até a injeção dos componentes terminar.
var _is_ready_to_fight: bool = false
# Velocidade capturada imediatamente antes de move_and_slide() (usada por WallSplatComponent).
var pre_slide_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Espera exatamente 1 frame de física para garantir que TUDO foi inicializado
	# (Filhos, netos e variáveis)
	await get_tree().physics_frame
	_ignite_fsm()

# Função dedicada para ligar o motor em duas passagens seguras:
# Passagem 1 garante que TODOS os nós tenham fighter e sub_components registrados;
# Passagem 2 inicializa cada nó exatamente uma vez.
func _ignite_fsm() -> void:
	if root_fsm:
		if component_manager:
			_inject_fighter_recursive(component_manager)
			_init_recursive(component_manager)
		root_fsm.enter()
		_is_ready_to_fight = true
	else:
		print("❌ [Fighter] ERRO: root_fsm não encontrada no nó $Component/StateMachine")

func _inject_fighter_recursive(node: Node) -> void:
	if "fighter" in node:
		node.fighter = self
	if node is Component:
		node.sub_components.clear()
		node._register_sub_components(node)
	for child in node.get_children():
		_inject_fighter_recursive(child)

func _init_recursive(node: Node) -> void:
	if node.has_method("initialize_once"):
		node.initialize_once()
	elif node.has_method("_on_initialized"):
		node._on_initialized()
	for child in node.get_children():
		_init_recursive(child)

func _physics_process(delta: float) -> void:
	# 🚨 TRAVA DE SEGURANÇA: Se ainda não carregou, ignora a física!
	if not _is_ready_to_fight:
		return

	# CAPTURA SÍNCRONA: garante que o histórico tem os inputs deste frame ANTES
	# da FSM rodar. Roda mesmo durante hitstop pra não perder inputs bufferizados.
	# Sem isso, consume_action em macro-cancel falharia (o buffer ainda estaria
	# vazio porque _process roda depois de _physics_process no mesmo frame).
	var buffer = get_component("InputBufferComponent")
	if buffer:
		buffer.capture(delta)

	var hitstop = get_component("HitstopComponent")
	if hitstop and hitstop.is_stopped():
		return

	# 🥊 A PONTE DE COMANDO:
	# Antes de rodar a física, perguntamos ao Buffer se há um soco/chute
	if buffer and root_fsm:
		# Pegamos as tags do estado atual (ex: "Neutral") para saber se podemos atacar
		var current_tags = root_fsm.get_tags()
		var move_payload = buffer.check_special_moves(current_tags)

		# Achou uma Query: passa pelo GATE DE TIER antes de mandar pra FSM.
		# O gate barra cancelamentos ilegais (ex: special de volta num normal).
		# Ver StateMachine.passes_cancel_gate.
		if not move_payload.is_empty() and root_fsm.passes_cancel_gate(move_payload.get("query", {})):
			root_fsm.enter(move_payload)
			# Os MoveComponents (NormalMoves/DashMove/etc) consomem o input que usam —
			# não dá pra limpar o buffer global aqui senão destrói inputs simultâneos (Pulo+Soco).

	if root_fsm:
		root_fsm.physics_update(delta)

	pre_slide_velocity = velocity
	move_and_slide()
	_resolve_pushbox_separation()

func _resolve_pushbox_separation() -> void:
	if not target_fighter or not is_instance_valid(target_fighter):
		return
	if not target_fighter.get("_is_ready_to_fight"):
		return
	if root_fsm:
		var my_tags: Array[String] = root_fsm.get_tags()
		if "Invincible" in my_tags or "Dodge" in my_tags or "KO" in my_tags:
			return
	var opp_fsm = target_fighter.get("root_fsm")
	if opp_fsm:
		var opp_tags: Array[String] = opp_fsm.get_tags()
		if "Invincible" in opp_tags or "Dodge" in opp_tags or "KO" in opp_tags:
			return

	var dy: float = absf(global_position.y - target_fighter.global_position.y)
	if dy >= PUSHBOX_MAX_VERT_DIST:
		return

	var dx: float = global_position.x - target_fighter.global_position.x
	var overlap: float = PUSHBOX_MIN_DIST - absf(dx)
	if overlap <= 0.0:
		return

	var sep_dir: float = signf(dx)
	if sep_dir == 0.0:
		var fc = get_component("FacingComponent")
		if fc and fc.current_facing != 0.0:
			sep_dir = -fc.current_facing
		else:
			sep_dir = 1.0 if get_instance_id() < target_fighter.get_instance_id() else -1.0

	# Se cair do ar bem em cima da cabeça do oponente, escorrega lateralmente com suavidade.
	if not is_on_floor() and velocity.y >= 0.0:
		var old_x: float = global_position.x
		global_position.x = clampf(old_x + sep_dir * overlap, ARENA_MIN_X, ARENA_MAX_X)
		return

	var half: float = overlap * 0.5
	var old_self_x: float = global_position.x
	var old_opp_x: float = target_fighter.global_position.x

	var new_self_x: float = clampf(old_self_x + sep_dir * half, ARENA_MIN_X, ARENA_MAX_X)
	var applied_self: float = absf(new_self_x - old_self_x)
	var rem_opp: float = overlap - applied_self
	var new_opp_x: float = clampf(old_opp_x - sep_dir * rem_opp, ARENA_MIN_X, ARENA_MAX_X)
	var applied_opp: float = absf(new_opp_x - old_opp_x)
	if applied_self + applied_opp < overlap:
		new_self_x = clampf(old_self_x + sep_dir * (overlap - applied_opp), ARENA_MIN_X, ARENA_MAX_X)

	global_position.x = new_self_x
	target_fighter.global_position.x = new_opp_x

# ==========================================
# 🌉 A PONTE PARA OS COMPONENTES
# ==========================================
func get_component(component_name: String) -> Component:
	if component_manager:
		return component_manager.get_component(component_name)
	return null
