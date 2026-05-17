class_name CrouchState
extends State

#@export var recovery_state: String = "IdleState"

func _ready() -> void:
	type_dim = "movement"
	stance_dim = "crouch"
	direction_dim = "any"
	recovery_state = "IdleState"

func enter(_payload: Dictionary = {}) -> void:
	#print("🧎 [Crouch] Personagem agachou!")
	
	if fighter:
		fighter.velocity.x = 0
		fighter.set_posture_collision("crouch")
		
	#var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim:
		anim.play("crouch_idle")

func physics_update(delta: float) -> void:
	if not fighter: return

	if movement:
		movement.apply_gravity(delta)

	var input_comp = fighter.get_component("InputComponent")
	var is_holding_down = false

	if input_comp and input_comp.has_method("get_movement_direction"):
		var current_input = input_comp.get_movement_direction()
		if current_input.y > 0.5:
			is_holding_down = true

	if not is_holding_down:
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	return ["Ground", "Crouching"]
