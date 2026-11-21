class_name FacingComponent
extends Component

@export var sprite: Sprite2D
@export var flip_node: Node2D # Um nó pai que contém todas as Hitboxes/Hurtboxes
@export var initial_facing: float = 1.0

var current_facing: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var opponent: CharacterBody2D # Referência ao outro lutador

func _on_initialized() -> void:
	if initial_facing != 1.0:
		set_facing(initial_facing)
	_resolve_opponent()
	_update_facing()

const LOCKED_TAGS: Array[String] = [
	"Attacking", "Hurt", "Dashing", "Blocking", "Knockdown",
	"WallSplat", "Thrown", "KO", "Invincible", "Dodge", "Airborne", "MeterCharging"
]

func _resolve_opponent() -> void:
	if fighter and fighter.target_fighter and fighter.target_fighter != fighter:
		opponent = fighter.target_fighter
		return
		
	if owner and owner.get_parent():
		var opp = owner.get_parent().get_node_or_null("Opponent")
		if opp is CharacterBody2D and opp != fighter:
			opponent = opp
			if fighter and fighter.target_fighter == null:
				fighter.target_fighter = opp
			return
			
	# Busca outro Fighter na cena automaticamente
	if fighter and fighter.get_parent():
		for child in fighter.get_parent().get_children():
			if child is CharacterBody2D and child != fighter:
				opponent = child
				if fighter.target_fighter == null:
					fighter.target_fighter = child
				break

func _physics_process(_delta: float) -> void:
	var fsm = get_component("StateMachine")
	if fsm:
		if not _can_flip(fsm.get_tags()):
			return
			
	_update_facing()

func _can_flip(tags: Array[String]) -> bool:
	for locked in LOCKED_TAGS:
		if locked in tags:
			return false
	return true

func _update_facing() -> void:
	if not opponent or not is_instance_valid(opponent):
		_resolve_opponent()
		if not opponent: return
	
	# Calcula para qual lado o oponente está em relação a nós
	var diff = opponent.global_position.x - fighter.global_position.x
	if abs(diff) < 5: return # Zona morta para evitar "jitter" (tremedeira)
	
	var new_facing = sign(diff)
	
	if new_facing != current_facing and new_facing != 0:
		set_facing(new_facing)

func set_facing(dir: float) -> void:
	current_facing = dir
	
	# Inverte o visual (seja Sprite2D ou AnimatedSprite2D)
	if sprite:
		sprite.flip_h = (current_facing == -1.0)
	elif fighter:
		var anim_sprite = fighter.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.flip_h = (current_facing == -1.0)
		var anim_comp = fighter.get_component("AnimatedSpriteComponent")
		if anim_comp and "sprite" in anim_comp and anim_comp.sprite:
			anim_comp.sprite.flip_h = (current_facing == -1.0)
		var prox_area = fighter.get_node_or_null("ProximityArea")
		if prox_area:
			prox_area.scale.x = current_facing
	
	# Inverte TODAS as caixas de colisão de uma vez!
	if flip_node:
		flip_node.scale.x = current_facing
