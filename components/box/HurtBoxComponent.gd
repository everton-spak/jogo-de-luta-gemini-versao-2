class_name HurtboxComponent
extends BoxComponent

# Referências aos novos componentes de economia e combo
var health:  Component
var combo_manager: Component 

func _on_initialized() -> void:
	super._on_initialized()
	
	# 1. Busca as peças vitais do lutador usando a arquitetura de Componentes
	#health = get_component("HealthComponent") as ResourceComponent
	#combo_manager = get_component("ComboComponent") as ComboComponent
	
	# 2. Conecta o sinal de colisão usando a 'area_2d' herdada do BoxComponent
	if area_2d:
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# 1. Apanhamos o "Dono" da área de colisão (o Componente pai)
	var hit_node = area.get_parent()
	
	# 2. Verificamos se esse dono é uma Hitbox e se NÃO é um agarrão (is_throw)
	if hit_node is HitboxComponent and not hit_node.is_throw:
		_process_strike(hit_node)

func _process_strike(hit_node: HitboxComponent) -> void:
	# Busca o Cérebro do lutador para saber exatamente o que ele está a fazer
	var main_fsm = fighter.get_node("RootStateMachine") as StateMachine
	if not main_fsm: return
	
	# Pega a lista COMPLETA de tags (O Somatório do Galho Pai + Folha Filho)
	var tags = main_fsm.get_tags()
	
	# ==========================================
	# PASSO 1: INVENCIBILIDADE (I-FRAMES)
	# ==========================================
	if "Invincible" in tags:
		return # O golpe atravessa o personagem como se fosse um fantasma!
		
	# ==========================================
	# PASSO 2: VERIFICAÇÃO DE DEFESA (BLOCKING)
	# ==========================================
	var input = get_component("Input")
	var facing = get_component("FacingComponent")
	var is_holding_back = false
	
	if input and facing:
		var dir_x = input.get_movement_direction().x
		# Verifica se o jogador está a segurar na direção oposta à sua visão
		if dir_x == -facing.current_facing:
			is_holding_back = true
			
	# Só defende se estiver a segurar para trás, estiver no chão, e NÃO estiver a atacar
	if is_holding_back and "Grounded" in tags and not "Attacking" in tags:
		var block_payload = {
			"hitstun": hit_node.hitstun_duration,
			"knockback": hit_node.knockback_force.x, 
			"damage": hit_node.damage * 0.1 # Chip damage (Sofre apenas 10% do dano)
		}
		
		# A RootFSM atira o lutador para o estado de defesa correto
		if "Crouching" in tags:
			main_fsm.change_state("CrouchBlockState", block_payload)
		else:
			main_fsm.change_state("StandBlockState", block_payload)
			
		return # Interrompe a função aqui. Ele defendeu com sucesso!

	# ==========================================
	# PASSO 3: GOLPE CONECTADO (COMBO E DANO)
	# ==========================================
	var final_damage = hit_node.damage
	
	# Se tivermos o gestor de combo, ele regista o hit e calcula o "Damage Scaling"
	if  combo_manager:
		final_damage = combo_manager.process_hit(hit_node.damage)
		
	# Subtrai a vida usando a nossa nova fábrica genérica de recursos
	if health:
		health.subtract(final_damage)
		
	# ==========================================
	# PASSO 4: FÍSICA DO IMPACTO E ESTADO DE DOR
	# ==========================================
	# Descobre de que lado veio o soco para jogar o lutador para trás
	var hit_dir = sign(fighter.global_position.x - hit_node.global_position.x)
	if hit_dir == 0: hit_dir = 1.0 # Prevenção de vetor nulo
	
	# 1. Congela quem apanhou (O Defensor)
	var my_hitstop = fighter.get_component("HitstopComponent")
	if my_hitstop:
		my_hitstop.start_hitstop(hit_node.hitstop_duration)
	
	# Prepara a "encomenda" (Payload) com as instruções para o Estado de Dor
	var hit_payload = {
		"hitstun": hit_node.hitstun_duration,
		"knockback_x": hit_node.knockback_force.x * hit_dir,
		"knockback_y": hit_node.knockback_force.y,
		"attacker": hit_node.fighter 
	}
	
	# Avalia a força vertical para decidir se é um lançamento ao ar (Juggle) ou impacto normal
	if hit_node.knockback_force.y < -100:
		main_fsm.change_state("AirHitState", hit_payload)
	else:
		main_fsm.change_state("StandHitState", hit_payload)
