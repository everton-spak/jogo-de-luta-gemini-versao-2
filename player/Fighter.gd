class_name Fighter
extends CharacterBody2D

@export var target_fighter: CharacterBody2D

# VERIFIQUE O NOME DO SEU NÓ (Se é $Component ou $ComponentManager)
@onready var component_manager: Component = $Component
@onready var root_fsm: StateMachine = $Component/StateMachine
@export_group("Collision Sizes")
@export var stand_size: Vector2 = Vector2(60, 120)
@export var stand_pos: Vector2 = Vector2(0, -60) # Ajusta o Y para colar no chão

@export var crouch_size: Vector2 = Vector2(60, 70)
@export var crouch_pos: Vector2 = Vector2(0, -35) # Metade da altura, desliza para baixo

# (Certifica-te que tens a referência à tua CollisionShape2D do corpo)
@onready var main_collider: CollisionShape2D = $CollisionShape2D

# Nova variável de segurança
var _is_ready_to_fight: bool = false

func _ready() -> void:
	# Espera exatamente 1 frame de física para garantir que TUDO foi inicializado
	# (Filhos, netos e variáveis)
	await get_tree().physics_frame
	_ignite_fsm()

# Função dedicada para ligar o motor em segurança
func _ignite_fsm() -> void:
	if root_fsm:
		print("SUCESSO: Injetando Lutador e Componentes em toda a FSM...")
		
		# ---> MUDANÇA AQUI: Agora começamos pelo pai de todos (ComponentManager)
		if component_manager:
			_force_deep_setup(component_manager)
		
		root_fsm.enter()
		_is_ready_to_fight = true
		
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
		
	var hitstop = get_component("HitstopComponent")
	
	if hitstop and hitstop.is_stopped():
		return
		
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
func set_posture_collision(is_crouching: bool) -> void:
	if not main_collider or not main_collider.shape is RectangleShape2D:
		return
		
	# Para não alterar os recursos globais (bug do Godot), duplicamos a shape 
	# na primeira vez que alteramos o tamanho
	if main_collider.shape.resource_local_to_scene == false:
		main_collider.shape = main_collider.shape.duplicate()
		main_collider.shape.resource_local_to_scene = true

	if is_crouching:
		main_collider.shape.size = crouch_size
		main_collider.position = crouch_pos
	else:
		main_collider.shape.size = stand_size
		main_collider.position = stand_pos
