class_name FacingComponent
extends Component

@export var sprite: Sprite2D
@export var flip_node: Node2D # Um nó pai que contém todas as Hitboxes/Hurtboxes

var current_facing: float = 1.0 # 1.0 = Direita, -1.0 = Esquerda
var opponent: CharacterBody2D # Referência ao outro lutador

func _on_initialized() -> void:
	# Busca o oponente (em um jogo de luta real, você passaria isso no Manager)
	opponent = owner.get_parent().get_node_or_null("Opponent")

func _physics_process(_delta: float) -> void:
	# 1. SÓ VIRA SE ESTIVER EM ESTADOS QUE PERMITEM (Idle, Walk, Crouch, Jump)
	# Se estiver no meio de um Hadouken ou Dash, ele não vira sozinho!
	var fsm = get_component("StateMachine")
	if fsm and fsm.current_state:
		if not _can_flip(fsm.get_tags()):
			return
			
	_update_facing()

func _can_flip(tags: Array[String]) -> bool:
	# Se estiver atacando ou em hitstun, o personagem fica travado naquela direção
	if "Attack" in tags or "Hitstun" in tags or "Dash" in tags:
		return false
	return true

func _update_facing() -> void:
	if not opponent: return
	
	# Calcula para qual lado o oponente está em relação a nós
	var diff = opponent.global_position.x - fighter.global_position.x
	if abs(diff) < 5: return # Zona morta para evitar "jitter" (tremedeira)
	
	var new_facing = sign(diff)
	
	if new_facing != current_facing and new_facing != 0:
		set_facing(new_facing)

func set_facing(dir: float) -> void:
	current_facing = dir
	
	# Inverte o visual
	if sprite:
		sprite.flip_h = (current_facing == -1.0)
	
	# Inverte TODAS as caixas de colisão de uma vez!
	# (Em vez de flip_h, escalonamos o nó pai no eixo X)
	if flip_node:
		flip_node.scale.x = current_facing
