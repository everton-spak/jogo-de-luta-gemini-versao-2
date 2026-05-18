class_name Fighter
extends CharacterBody2D

@export var target_fighter: CharacterBody2D

# VERIFIQUE O NOME DO SEU NÓ (Se é $Component ou $ComponentManager)
@onready var component_manager: Component = $Component
@onready var root_fsm: StateMachine = $Component/StateMachine
@export_group("Collision Sizes")
@export var stand_size: Vector2 = Vector2(60, 120)
@export var stand_pos: Vector2 = Vector2(0, -60)
@export var sprite_y_adjustment: float = 0.0

@export var crouch_size: Vector2 = Vector2(60, 70)
@export var crouch_pos: Vector2 = Vector2(0, -35)

@export var air_size: Vector2 = Vector2(60, 100)
@export var air_pos: Vector2 = Vector2(0, -50)

# (Certifica-te que tens a referência à tua CollisionShape2D do corpo)
@onready var main_collider: CollisionShape2D = $CollisionShape2D
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _sprite_offset: Vector2 = Vector2.ZERO
# Nova variável de segurança
var _is_ready_to_fight: bool = false

func _ready() -> void:
	if _sprite and main_collider:
		_sprite_offset = _sprite.position - main_collider.position
	# Espera exatamente 1 frame de física para garantir que TUDO foi inicializado
	# (Filhos, netos e variáveis)
	await get_tree().physics_frame
	_ignite_fsm()

# Função dedicada para ligar o motor em segurança
func _ignite_fsm() -> void:
	if root_fsm:
		#print("🔥 [Fighter] Motor de combate ligado!")
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
	var history = get_component("InputHistoryComponent")
	if buffer and root_fsm:
		# Pegamos as tags do estado atual (ex: "Neutral") para saber se podemos atacar
		var current_tags = root_fsm.get_tags()
		var move_payload = buffer.check_special_moves(current_tags)
		
		# Se o buffer encontrou uma Query (um soco), ele manda para a FSM!
		if not move_payload.is_empty():
			root_fsm.enter(move_payload)
			# REMOVIDO: history._buffer.clear() 
			# Limpar o buffer globalmente destrói inputs simultâneos (ex: Pulo + Soco).
			# Os próprios MoveComponents (como NormalMoves ou DashMove) devem consumir os inputs que usam.
		
	if root_fsm:
		root_fsm.physics_update(delta)

	move_and_slide()
	
	#print("No Chão: ", is_on_floor(), " | Velocidade Y: ", velocity.y)

# ==========================================
# 🌉 A PONTE PARA OS COMPONENTES
# ==========================================
func get_component(component_name: String) -> Component:
	if component_manager:
		return component_manager.get_component(component_name)
	return null
	
	
# ==========================================
# NOVA FUNÇÃO: MUDAR POSTURA FÍSICA
# ==========================================
func set_posture_collision(posture: String) -> void:
	if not main_collider or not main_collider.shape is RectangleShape2D:
		return

	if main_collider.shape.resource_local_to_scene == false:
		main_collider.shape = main_collider.shape.duplicate()
		main_collider.shape.resource_local_to_scene = true

	match posture:
		"crouch":
			main_collider.shape.size = crouch_size
			main_collider.position = crouch_pos
		"air":
			main_collider.shape.size = air_size
			main_collider.position = air_pos
		_: # "stand" e qualquer outro
			main_collider.shape.size = stand_size
			main_collider.position = stand_pos

	if _sprite:
		_sprite.position = main_collider.position + _sprite_offset + Vector2(0, sprite_y_adjustment)

func get_sprite_position_y() -> float:
	if _sprite:
		return _sprite.position.y
	return 0.0

func set_sprite_position_y(y: float) -> void:
	if _sprite:
		_sprite.position.y = y
