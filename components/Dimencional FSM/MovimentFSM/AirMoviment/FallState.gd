class_name FallState
extends State

@export_group("Configuração da Queda")
@export var gravity: float = 1800.0
@export var horizontal_speed: float = 400.0
@export var landing_state: String = "IdleState"

var _locked_dir: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var query_dict = payload.get("query", {})
	
	if query_dict.has("dir_x"):
		_locked_dir = query_dict.get("dir_x", 0.0)
	elif fighter:
		# Se viemos de um ataque aéreo, o payload não tem dir_x.
		# Deduzimos a direção travada pela velocidade atual do personagem!
		if fighter.velocity.x > 10:
			_locked_dir = 1.0
		elif fighter.velocity.x < -10:
			_locked_dir = -1.0
		else:
			_locked_dir = 0.0
	else:
		_locked_dir = 0.0
	
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		# Toca a animação genérica de queda ou a específica por direção
		anim.play("fall") 

func physics_update(delta: float) -> void:
	if not fighter: return
	
	# 1. Continua a trajetória parabólica
	fighter.velocity.y += gravity * delta
	fighter.velocity.x = horizontal_speed * _locked_dir
	
	# 2. O POUSO
	if fighter.is_on_floor():
		fighter.velocity.x = 0
		transition_requested.emit(landing_state, {})

func get_tags() -> Array[String]:
	return ["Air", "Movement"]
