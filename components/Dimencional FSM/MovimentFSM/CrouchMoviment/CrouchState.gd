class_name CrouchState
extends State

@export var recovery_state: String = "IdleState"

func _ready() -> void:
	type_dim = "movement"
	stance_dim = "crouch"
	direction_dim = "any"

func enter(_payload: Dictionary = {}) -> void:
	#print("🧎 [Crouch] Personagem agachou!")
	
	if fighter:
		# Agachar freia o personagem imediatamente
		fighter.velocity.x = 0 
		
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		anim.play("crouch_idle")

func physics_update(_delta: float) -> void:
	if not fighter: return
	
	var input_comp = fighter.get_component("InputComponent")
	var is_holding_down = false
	
	# A cada frame, perguntamos ao Input se o direcional ainda aponta para baixo
	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		if current_input.y > 0.5:
			is_holding_down = true

	# Condição de Saída: O jogador soltou o botão de agachar
	if not is_holding_down:
		#print("🧍 [CrouchIdle] Soltou o botão, voltando para guarda.")
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	return ["Ground", "Crouching"]
