class_name WalkState
extends State

@export_group("Caminhada: Frente")
@export var forward_speed: float = 250.0
@export var anim_forward: String = "walk"

@export_group("Caminhada: Trás (Defesa)")
@export var backward_speed: float = 180.0
@export var anim_backward: String = "walk_back"

@export_group("Física")
@export var acceleration: float = 2500.0

var _current_anim: String = ""

func enter(_payload: Dictionary = {}) -> void:
	_current_anim = ""

func physics_update(delta: float) -> void:
	if not input or not movement: 
		push_error("❌ [WalkState] Falta Input ou Movement!")
		return

	var dir = input.get_movement_direction().x

	# 1. CONDIÇÃO DE SAÍDA
	if dir == 0.0:
		transition_requested.emit("IdleState", {})
		return

	# 2. ANÁLISE DE DIREÇÃO
	var facing_dir = 1.0
	if facing: facing_dir = facing.current_facing
	
	var is_forward = sign(dir) == sign(facing_dir)
	var target_speed = forward_speed if is_forward else backward_speed
	var target_anim = anim_forward if is_forward else anim_backward

	# 3. ATUALIZA A ANIMAÇÃO (Corrigido!)
	if _current_anim != target_anim:
		_current_anim = target_anim
		if anim:
			anim.play(_current_anim)

	# 4. APLICA O MOVIMENTO
	movement.move_horizontal(dir, target_speed, acceleration, delta)
	movement.commit_movement()

func get_tags() -> Array[String]:
	return ["Ground", "Movement", "Stand"]
