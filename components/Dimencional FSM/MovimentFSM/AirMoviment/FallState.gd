class_name FallState
extends State

@export_group("Configuração da Queda")
@export var gravity: float = 1800.0
@export var horizontal_speed: float = 400.0
@export var landing_state: String = "IdleState"

var _locked_dir: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	var query_dict = payload.get("query", {})
	_locked_dir = query_dict.get("dir_x", 0.0)
	
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
