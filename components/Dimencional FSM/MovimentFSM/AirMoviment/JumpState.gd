class_name JumpState
extends State

@export_group("Configuração do Pulo")
@export var jump_force: float = 900.0
@export var horizontal_speed: float = 400.0
@export var gravity: float = 1800.0
@export var fall_state: String = "FallState"

var _locked_dir: float = 0.0

func enter(payload: Dictionary = {}) -> void:
	# 1. Trava a direção no momento da decolagem
	var query_dict = payload.get("query", {})
	_locked_dir = query_dict.get("dir_x", 0.0)
	
	if fighter:
		fighter.velocity.y = -jump_force
		fighter.velocity.x = horizontal_speed * _locked_dir
		if posture: posture.apply("air")
		
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func physics_update(delta: float) -> void:
	if not fighter: return
	
	# 2. Aplica a gravidade e MANTÉM a velocidade horizontal travada
	fighter.velocity.y += gravity * delta
	fighter.velocity.x = horizontal_speed * _locked_dir
	
	# 3. Transição: O ápice do pulo. Começou a cair? Muda pro FallState!
	if fighter.velocity.y > 0:
		# Repassamos o payload para o FallState saber para onde o corpo estava indo
		var fall_payload = {"query": {"dir_x": _locked_dir}}
		transition_requested.emit(fall_state, fall_payload)

func get_tags() -> Array[String]:
	return ["Air", "Movement"]
