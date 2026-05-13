class_name HurtboxComponent
extends BoxComponent

func _on_initialized() -> void:
	super._on_initialized()
	if area_2d and not area_2d.area_entered.is_connected(_on_area_entered):
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hit_node = area.get_parent()
	if hit_node is HitboxComponent and not hit_node.is_throw:
		_process_strike(hit_node)
	elif hit_node is Node2D:
		var sibling = hit_node.get_node_or_null("HitboxComponent")
		if sibling is HitboxComponent and not sibling.is_throw:
			_process_strike(sibling)

func _process_strike(hit_node: HitboxComponent) -> void:
	if not fighter: return
	
	var main_fsm = fighter.get_component("StateMachine")
	var input_buffer = fighter.get_component("InputBufferComponent")
	var facing_comp = fighter.get_component("FacingComponent")
	if not main_fsm or not input_buffer: return
	
	var tags = main_fsm.get_tags()
	var current_stance = main_fsm.current_state.stance_dim
	
	# PASSO 1: I-Frames
	if "Invincible" in tags:
		return 
		
	# PASSO 2: Bloqueio (High/Low Mixup)
	var dir_vec = input_buffer.input.get_movement_direction()
	var dir_string = input_buffer._vector_to_direction_string(dir_vec)
	var is_blocking = false
	var block_stance = current_stance
	
	if "Grounded" in tags and not "Attacking" in tags:
		# Verifica se a direção segurada condiz com o nível do ataque
		if dir_string == "B" and hit_node.attack_level != "low":
			is_blocking = true
			block_stance = "ground"
		elif dir_string == "DB" and hit_node.attack_level != "high":
			is_blocking = true
			block_stance = "crouch"

	# PASSO 3: Cálculo de Dano
	var final_damage = hit_node.damage
	var combo_manager = fighter.get_component("ComboComponent")
	var health = fighter.get_component("HealthComponent")
	
	if combo_manager:
		final_damage = combo_manager.process_hit(hit_node.damage)
		
	# PASSO 4: Impacto e Roteamento para FSM
	var hit_dir = sign(fighter.global_position.x - hit_node.global_position.x)
	if hit_dir == 0: hit_dir = 1.0 
	
	var my_hitstop = fighter.get_component("HitstopComponent")
	if my_hitstop:
		my_hitstop.start_hitstop(hit_node.hitstop_duration)
	
	# Constrói o Payload
	var payload = {
		"hit_data": {
			"hitstun": hit_node.hitstun_duration,
			"knockback_x": hit_node.knockback_force.x * hit_dir,
			"knockback_y": hit_node.knockback_force.y,
			"attacker": hit_node.fighter,
			"damage": final_damage
		},
		"query": {}
	}
	
	# Envia a Query para a Máquina de Estados
	if is_blocking:
		payload["hit_data"]["damage"] *= 0.1 # Chip damage
		payload["query"] = {
			"type": "block", 
			"stance": block_stance, 
			"direction": "backward"
		}
	else:
		if health: health.subtract(payload["hit_data"]["damage"])
		var target_stance = "air" if hit_node.knockback_force.y < -100 else current_stance
		payload["query"] = {
			"type": "hurt", 
			"stance": target_stance, 
			"direction": "any"
		}
		
	main_fsm.enter(payload)
