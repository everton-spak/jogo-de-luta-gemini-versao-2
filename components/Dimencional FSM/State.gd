class_name State
extends Component

signal transition_requested(new_state_name: String, payload: Dictionary)
var input_buffer: Component

@export_group("Dimensões do Estado (Deixe 'any' nas pastas/filtros)")
@export_enum("any", "ground", "air", "crouch") var stance_dim: String = "any"
@export_enum("any", "light", "heavy", "none") var strength_dim: String = "any"
@export_enum("any", "neutral", "forward", "backward") var direction_dim: String = "any"
@export var type_dim: String = "any" # Ex: "punch", "kick", "dash", "special"
@export_enum("any", "close", "far") var proximity_dim: String = "any"

@export_group("Regras de Cancelamento")
@export var cancel_tier_dim: int = 0 # 0=Passivo, 1=Fraco, 2=Forte, 3=Especial, 4=Super
@export var can_cancel_self: bool = false # Para Chain Combos (Rapid Fire)

@export_group("Hitbox")
@export var startup_frames: int = 3
@export var hitbox_offset: Vector2 = Vector2(60, -80)
@export var hitbox_size: Vector2 = Vector2(50, 40)
@export var damage: int = 5
@export var hitstun: float = 0.2
@export var knockback: Vector2 = Vector2(150, -50)
@export_enum("high", "mid", "low") var attack_level: String = "high"

# Componentes Internos
var anim: Component
var facing: Component
var hitbox: Component
var hurtbox: Component
var proximity: Component
var input: Component
var movement: Component
var health: Component
var vfx: Component
var combo_scaling : Component

var state_time_sec: float = 0.0
var state_frames: int = 0

func _on_initialized() -> void:
	# 1. Acha o Fighter subindo na árvore (se a injeção falhar)
	if not fighter:
		var current_node = get_parent()
		while current_node != null:
			if current_node is CharacterBody2D:
				fighter = current_node
				break
			current_node = current_node.get_parent()
			
	if not fighter:
		push_error("ERRO: Estado " + name + " não encontrou o Fighter!")
		return
		
	# ==========================================
	# 🌟 A MAGIA ACONTECE AQUI 🌟
	# Agora pedimos os componentes DIRETAMENTE ao Fighter, 
	# não importa em que profundidade (pasta) este estado esteja!
	# ==========================================
	var found_anim = fighter.get_component("AnimatedSpriteComponent")
	if found_anim is AnimatedSpriteComponent: 
		anim = found_anim
		
	input_buffer = fighter.get_component("InputBufferComponent")
	facing = fighter.get_component("FacingComponent")
	hitbox = fighter.get_component("HitboxComponent")
	hurtbox = fighter.get_component("HurtBoxComponent")
	proximity = fighter.get_component("ProximityBoxComponent")
	input = fighter.get_component("InputComponent")
	movement = fighter.get_component("MovementComponent")
	health = fighter.get_component("HealthComponent")
	vfx = fighter.get_component("VfxComponent")
	combo_scaling = fighter.get_component("ScalingComboComponent")

func enter(_payload: Dictionary = {}) -> void: 
	state_time_sec = 0.0
	state_frames = 0

func exit() -> void: 
	state_time_sec = 0.0
	state_frames = 0

func physics_update(delta: float) -> void: 
	state_time_sec += delta
	state_frames += 1

func process_cancel_routes() -> bool:
	if input_buffer == null: return false
	var command = input_buffer.check_special_moves(get_tags())
	if command.is_empty(): return false

	if command.has("query"):
		var query = command["query"]
		var root_fsm = get_component("StateMachine")
		
		if root_fsm and root_fsm is StateMachine:
			var target_node = root_fsm._simulate_leaf_routing(query)
			
			if target_node:
				var next_tier = target_node.cancel_tier_dim
				var current_tier = self.cancel_tier_dim
				
				if next_tier > current_tier or (target_node.name == self.name and can_cancel_self):
					transition_requested.emit(target_node.name, command)
					return true
	return false

func _setup_hitbox() -> void:
	if not hitbox: return
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.damage = damage
	hitbox.hitstun_duration = hitstun
	hitbox.knockback_force = Vector2(knockback.x * f_dir, knockback.y)
	hitbox.attack_level = attack_level
	if hitbox.area_2d:
		hitbox.area_2d.position = Vector2(hitbox_offset.x * f_dir, hitbox_offset.y)
	if hitbox.collision_shape:
		if hitbox.collision_shape.shape is RectangleShape2D:
			hitbox.collision_shape.shape.size = hitbox_size
		hitbox.collision_shape.debug_color = Color(1.0, 0.0, 0.0, 0.4)

func get_tags() -> Array[String]:
	return []
