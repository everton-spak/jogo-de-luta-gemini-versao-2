class_name HurtboxComponent
extends BoxComponent

# Recebe golpes não-throw (throws caem no ThrowHurtboxComponent). Decide o tipo
# de reação (hurt/block/ko/juggle), calcula dano com combo scaling, aplica
# hitstop, e roteia a FSM pro estado correspondente na HurtFSM via query.
#
# A query SEMPRE inclui "react": "yes" pra rotear pra HurtFSM em vez de
# MovementStateMachine (que ganharia o empate por ordem na cena).

func _on_initialized() -> void:
	super._on_initialized()
	if area_2d and not area_2d.area_entered.is_connected(_on_area_entered):
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hit_node = area.get_parent()
	if hit_node is HitboxComponent and not hit_node.is_throw:
		_process_strike(hit_node)
	elif hit_node is CharacterBody2D and hit_node.has_method("get_component"):
		var hb = hit_node.get_component("HitboxComponent")
		if hb is HitboxComponent and not hb.is_throw:
			_process_strike(hb)

func _process_strike(hit_node: HitboxComponent) -> void:
	if not fighter: return

	var main_fsm = fighter.get_component("StateMachine")
	var input_buffer = fighter.get_component("InputBufferComponent")
	if not main_fsm or not input_buffer: return

	var tags = main_fsm.get_tags()
	var current_stance: String = "ground"
	if main_fsm.current_state:
		current_stance = main_fsm.current_state.stance_dim

	# PASSO 1: I-Frames — golpe absorvido sem efeito.
	if "Invincible" in tags:
		return

	# PASSO 2: Detecção de bloqueio (High/Low mixup) — só vale no chão e fora de ataque.
	var dir_vec = input_buffer.input.get_movement_direction()
	var dir_string = input_buffer._vector_to_direction_string(dir_vec)
	var is_blocking := false
	var block_stance: String = current_stance

	if "Grounded" in tags and not ("Attacking" in tags):
		if dir_string == "B" and hit_node.attack_level != "low":
			is_blocking = true
			block_stance = "ground"
		elif dir_string == "DB" and hit_node.attack_level != "high":
			is_blocking = true
			block_stance = "crouch"

	# PASSO 3: Dano base + combo scaling.
	var final_damage: int = hit_node.damage
	var combo_manager = fighter.get_component("ScalingComboComponent")
	if combo_manager and combo_manager.has_method("process_hit"):
		final_damage = int(combo_manager.process_hit(hit_node.damage))

	# PASSO 4: Direção do hit (pra espelhar knockback corretamente).
	var hit_dir: float = sign(fighter.global_position.x - hit_node.global_position.x)
	if hit_dir == 0.0:
		hit_dir = 1.0

	# Hitstop pra dar peso ao impacto.
	var my_hitstop = fighter.get_component("HitstopComponent")
	if my_hitstop:
		my_hitstop.start_hitstop(hit_node.hitstop_duration)

	# PASSO 5: Decide tipo da reação e aplica dano.
	var health = fighter.get_component("HealthComponent")
	var target_type: String

	if is_blocking:
		target_type = "block"
		final_damage = int(final_damage * 0.1) # chip
	else:
		var future_hp: int = (health.current_health - final_damage) if health else 1
		if future_hp <= 0:
			target_type = "ko"
		elif current_stance == "air" or hit_node.knockback_force.y < -100:
			target_type = "juggle"
		else:
			target_type = "hurt"

	if health and health.has_method("take_damage"):
		health.take_damage(final_damage)

	# PASSO 6: Roteia pra HurtFSM via query. "react": "yes" garante que vence o
	# scoring contra MovementStateMachine/AttackStateMachine.
	var stance_for_query: String = block_stance if is_blocking else current_stance
	var payload := {
		"hit_data": {
			"hitstun": hit_node.hitstun_duration,
			"knockback_x": hit_node.knockback_force.x * hit_dir,
			"knockback_y": hit_node.knockback_force.y,
			"attacker": hit_node.fighter,
			"damage": final_damage,
			"attack_level": hit_node.attack_level,
		},
		"query": {
			"type": target_type,
			"stance": stance_for_query,
			"direction": ("backward" if is_blocking else "any"),
			"react": "yes",
		}
	}

	main_fsm.enter(payload)
