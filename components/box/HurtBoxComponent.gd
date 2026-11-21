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
	var hb := _resolve_hitbox(area)
	if hb == null or hb.is_throw:
		return
	# Nunca apanha do próprio golpe/projétil.
	if hb.fighter == fighter:
		return
	var processed: bool = _process_strike(hb, area)
	# Projéteis somem ao acertar quando o golpe conectou (não se o alvo estava invencível/KO).
	if processed:
		var owner_node := area.get_parent()
		if owner_node and not (owner_node is CharacterBody2D) and owner_node.has_method("_on_hit"):
			owner_node._on_hit()

# Descobre qual HitboxComponent é dono da Area2D que entrou.
# - Hitbox de lutador: a Area2D fica na raiz do Fighter; só vale se for a area_2d
#   da HitboxComponent dele e estiver ativa.
# - Projétil: a Area2D é filha do projétil, que tem um nó "HitboxComponent" ativo.
func _resolve_hitbox(area: Area2D) -> HitboxComponent:
	var p := area.get_parent()
	if p == null:
		return null
	if p is HitboxComponent:
		return p if p.is_active() else null
	if p is CharacterBody2D and p.has_method("get_component"):
		var hb = p.get_component("HitboxComponent")
		if hb is HitboxComponent and hb.area_2d == area and hb.is_active():
			return hb
		return null
	var proj_hb = p.get_node_or_null("HitboxComponent")
	if proj_hb is HitboxComponent and proj_hb.is_active():
		return proj_hb
	return null

# Stance real do lutador. O current_state da raiz é uma pasta (stance "any"),
# então olhamos o chão e o estado folha ativo.
func _current_stance(main_fsm) -> String:
	if not fighter.is_on_floor():
		return "air"
	if main_fsm.has_method("get_active_leaf"):
		var leaf = main_fsm.get_active_leaf()
		if leaf and leaf.stance_dim == "crouch":
			return "crouch"
	return "ground"

func _process_strike(hit_node: HitboxComponent, hit_area: Area2D = null) -> bool:
	if not fighter: return false

	var main_fsm = fighter.get_component("StateMachine")
	var input_buffer = fighter.get_component("InputBufferComponent")
	if not main_fsm or not input_buffer: return false

	var tags = main_fsm.get_tags()
	var current_stance: String = _current_stance(main_fsm)

	# PASSO 1: I-Frames ou já em KO — golpe absorvido sem efeito.
	if "Invincible" in tags or "KO" in tags:
		return false

	# PASSO 2: Detecção de bloqueio (High/Low mixup) — só vale no chão e fora de ataque/hurt.
	var dir_string: String = "N"
	if input_buffer.interpreter and input_buffer.interpreter.has_method("get_direction_string"):
		dir_string = input_buffer.interpreter.get_direction_string()
	var is_blocking := false
	var block_stance: String = current_stance

	# Usa is_on_floor() em vez da tag "Grounded": agachado a tag é "Crouched",
	# o que impedia a defesa baixa (DB) de funcionar.
	var can_block: bool = fighter.is_on_floor() and not ("Attacking" in tags) \
		and not ("Hurt" in tags and not "Blocking" in tags)
	if can_block:
		if dir_string == "B" and hit_node.attack_level != "low":
			is_blocking = true
			block_stance = "ground"
		elif dir_string == "DB" and hit_node.attack_level != "high":
			is_blocking = true
			block_stance = "crouch"

	# PASSO 3: Dano base + combo scaling. Se não estava em hitstun, é um combo novo.
	var final_damage: int = hit_node.damage
	var combo_manager = fighter.get_component("ScalingComboComponent")
	if combo_manager:
		if not ("Hurt" in tags or "Juggling" in tags) and combo_manager.has_method("reset_combo"):
			combo_manager.reset_combo()
		if not is_blocking and combo_manager.has_method("process_hit"):
			final_damage = int(combo_manager.process_hit(hit_node.damage))

	# PASSO 4: Direção do hit (pra espelhar knockback corretamente).
	var src_x: float = hit_area.global_position.x if hit_area else fighter.global_position.x
	var hit_dir: float = sign(fighter.global_position.x - src_x)
	if hit_dir == 0.0:
		hit_dir = 1.0

	var contact_point: Vector2 = fighter.global_position + Vector2(0, -80)
	if hit_area and is_instance_valid(hit_area):
		contact_point = hit_area.global_position

	# Hitstop pra dar peso ao impacto.
	var my_hitstop = fighter.get_component("HitstopComponent")
	if my_hitstop:
		my_hitstop.start_hitstop(hit_node.hitstop_duration)

	# PASSO 5: Decide tipo da reação e aplica dano.
	var health = fighter.get_component("HealthComponent")
	var target_type: String

	if is_blocking:
		target_type = "block"
		# Ataques especiais (>=70 dmg base) dão chip damage; normais dão 0 no block.
		final_damage = maxi(1, int(final_damage * 0.1)) if hit_node.damage >= 70 else 0

		# GUARD METER: consome a barra. Se ZEROU → roteia pra GuardBrokenState.
		var guard_system = fighter.get_component("GuardMeterComponent")
		if guard_system and guard_system.has_method("consume_from_block"):
			if guard_system.consume_from_block(hit_node.attack_level):
				target_type = "guard_broken"
	else:
		# STUN: adiciona à StunBar antes de decidir o tipo. Se encher, vai pra dizzy.
		var stun_system = fighter.get_component("StunSystemComponent")
		var would_dizzy: bool = false
		if stun_system and stun_system.has_method("add_from_hit"):
			would_dizzy = stun_system.add_from_hit(hit_node.attack_level)

		var future_hp: int = (health.current_health - final_damage) if health else 1
		if future_hp <= 0:
			target_type = "ko"          # KO vence tudo (morreu)
		elif would_dizzy:
			target_type = "dizzy"        # Stun bar encheu → dizzy
		elif current_stance == "air" or hit_node.knockback_force.y < -100:
			target_type = "juggle"
		else:
			target_type = "hurt"

	if health and health.has_method("take_damage") and final_damage > 0:
		health.take_damage(final_damage)

	# Ganho de Super Meter estilo KOF (atacante +8 hit / +4 block; defensor +4 hit / +2 block)
	var atk_meter: float = 4.0 if is_blocking else 8.0
	var def_meter: float = 2.0 if is_blocking else 4.0
	if hit_node.fighter and is_instance_valid(hit_node.fighter):
		var atk_bar = hit_node.fighter.get_component("MeterBar")
		if atk_bar and atk_bar.has_method("add"):
			atk_bar.add(atk_meter)
	var def_bar = fighter.get_component("MeterBar")
	if def_bar and def_bar.has_method("add"):
		def_bar.add(def_meter)

	# Camera Shake proporcional ao peso do impacto
	var cam = get_tree().get_first_node_in_group("fight_camera") if get_tree() else null
	if cam and cam.has_method("add_shake"):
		if target_type == "ko":
			cam.add_shake(22.0, 0.35)
		elif not is_blocking and (target_type == "juggle" or hit_node.damage >= 80):
			cam.add_shake(12.0, 0.16)
		elif not is_blocking:
			cam.add_shake(5.0, 0.08)
		else:
			cam.add_shake(3.0, 0.06)

	# PASSO 6: Roteia pra HurtFSM via query. "react": "yes" garante que vence o
	# scoring contra MovementStateMachine/AttackStateMachine.
	var stance_for_query: String = block_stance if is_blocking else current_stance
	var payload := {
		"hit_data": {
			"hitstun": hit_node.hitstun_duration,
			"knockback_x": absf(hit_node.knockback_force.x) * hit_dir,
			"knockback_y": hit_node.knockback_force.y,
			"attacker": hit_node.fighter,
			"damage": final_damage,
			"attack_level": hit_node.attack_level,
			"contact_point": contact_point,
		},
		"query": {
			"type": target_type,
			"stance": stance_for_query,
			"direction": ("backward" if is_blocking else "any"),
			"react": "yes",
		}
	}

	main_fsm.enter(payload)
	return true
