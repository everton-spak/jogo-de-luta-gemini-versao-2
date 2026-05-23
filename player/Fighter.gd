class_name Fighter
extends CharacterBody2D

@export var target_fighter: CharacterBody2D

# VERIFIQUE O NOME DO SEU NÓ (Se é $Component ou $ComponentManager)
@onready var component_manager: Component = $Component
@onready var root_fsm: StateMachine = $Component/StateMachine

# Trava de segurança: bloqueia _physics_process até a injeção dos componentes terminar.
var _is_ready_to_fight: bool = false

func _ready() -> void:
	# Espera exatamente 1 frame de física para garantir que TUDO foi inicializado
	# (Filhos, netos e variáveis)
	await get_tree().physics_frame
	_ignite_fsm()

# Função dedicada para ligar o motor em segurança
func _ignite_fsm() -> void:
	if root_fsm:
		if component_manager:
			_force_deep_setup(component_manager)
		root_fsm.enter()
		_is_ready_to_fight = true
	else:
		print("❌ [Fighter] ERRO: root_fsm não encontrada no nó $Component/StateMachine")

# ==========================================
# 💉 FUNÇÃO RECURSIVA DE INJEÇÃO
# ==========================================
func _force_deep_setup(node: Node) -> void:
	# 1. Entrega o lutador de bandeja!
	if "fighter" in node:
		node.fighter = self

	# 2. Agora que o nó tem o lutador, manda ele buscar a animação, inputs, etc.
	if node.has_method("_on_initialized"):
		node._on_initialized()

	# 3. Repete o processo para todos os filhos (GroundState, Idle, Hadouken, etc)
	for child in node.get_children():
		_force_deep_setup(child)

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

	move_and_slide()

# ==========================================
# 🌉 A PONTE PARA OS COMPONENTES
# ==========================================
func get_component(component_name: String) -> Component:
	if component_manager:
		return component_manager.get_component(component_name)
	return null
