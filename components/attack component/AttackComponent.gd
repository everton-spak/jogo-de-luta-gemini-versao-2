class_name AttackComponent
extends State

# =========================================================
# 🏷️ TAGS E CLASSIFICAÇÃO
# =========================================================
@export_group("Tags & Classification")
## Tags que o InputBuffer lerá (ex: "Cancellable" permite interromper o golpe)
@export var attack_tags: Array = ["Attacking"]
## Tipo de ataque (High: defende em pé, Mid: defende agachado/em pé, Low: defende agachado)
@export_enum("High", "Mid", "Low", "Throw", "Unblockable") var attack_type: String = "Mid"

# =========================================================
# ⏱️ FRAME DATA
# =========================================================
@export_group("Frame Data")
@export var startup_time: float = 0.05
@export var active_time: float = 0.1
@export var recovery_time: float = 0.15

# =========================================================
# ⚔️ HITBOX & VISUAIS
# =========================================================
@export_group("Visuals & Hitbox")
@export var animation_name: String = ""
@export var hitbox_pos: Vector2 = Vector2(60, -10)
@export var hitbox_size: Vector2 = Vector2(50, 30)

# =========================================================
# 💥 PROPRIEDADES DE COMBATE
# =========================================================
@export_group("Combat Properties")
@export var damage: float = 10.0
@export var hitstun_time: float = 0.4
@export var blockstun_time: float = 0.2
@export var pushback_force: float = 200.0
@export var causes_knockdown: bool = false
@export var meter_gain: float = 5.0
@export var base_scaling: float = 1.0 # Usado no ComboManager

# =========================================================
# ✨ EXTRAS
# =========================================================
@export_group("Extras")
@export var startup_sfx: AudioStream
@export var hit_sfx: AudioStream
@export_enum("None", "Full", "Strike", "Projectile", "Throw") var invincibility_type: String = "None"
@export var invincibility_duration: float = 0.0

var _timer: float = 0.0
var _phase: int = 0 # 0: Startup, 1: Active, 2: Recovery

func _on_enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_phase = 0
	
	# 1. Toca a animação específica usando o Componente Animador
	var anim = fighter.get_component("AnimatedSpriteComponent")
	if anim and animation_name != "":
		anim.play(animation_name)
		
	# 2. Toca som e aplica I-Frames
	_play_sfx(startup_sfx)
	_apply_invincibility()
	
	# 3. Configura a física do golpe usando o novo sistema de Hitbox
	_setup_hitbox()
	_update_hitbox_properties()

func _setup_hitbox() -> void:
	var hitbox = fighter.get_component("HitboxComponent") as HitboxComponent
	if not hitbox: return
	
	# Garante que começa desligada
	hitbox.disable_box() 
	
	# Busca o FacingComponent para saber para qual lado estamos virados
	var facing = fighter.get_component("FacingComponent")
	var f_dir = facing.current_facing if facing else 1.0
	
	# Posiciona o Area2D dinamicamente
	if hitbox.area_2d:
		hitbox.area_2d.position = Vector2(hitbox_pos.x * f_dir, hitbox_pos.y)
	
	# Ajusta o tamanho exato da colisão (Se for retangular)
	if hitbox.collision_shape and hitbox.collision_shape.shape is RectangleShape2D:
		hitbox.collision_shape.shape.size = hitbox_size

func _update_hitbox_properties() -> void:
	var hitbox = fighter.get_component("HitboxComponent") as HitboxComponent
	if not hitbox: return
	
	# [NOVO] Em vez de usar set_meta, injetamos os valores diretamente nas 
	# propriedades do componente fortemente tipado! Isso é mais rápido e seguro.
	hitbox.damage = int(damage)
	hitbox.hitstun_duration = hitstun_time
	hitbox.pushback_force = Vector2(pushback_force, 0) # Assumindo empurrão horizontal base
	
	# Transforma o Enum visual ("Mid") na string exata ("mid") que a Hurtbox espera
	hitbox.attack_level = attack_type.to_lower()

func physics_update(_delta: float) -> void:
	if not fighter: return
	_timer += _delta
	
	# =========================================================
	# ⚡ CANCELAMENTOS DO ATAQUE (Gatling/Cancel Routes)
	# =========================================================
	if _phase >= 1:
		# Verifica se a FSM permite transição (ex: conectou o golpe e digitou especial)
		if _process_cancel_routes():
			return
			
	# =========================================================
	# ⏱️ MÁQUINA DE ESTADOS INTERNA DO GOLPE
	# =========================================================
	var hitbox = fighter.get_component("HitboxComponent") as HitboxComponent
	
	match _phase:
		0: # STARTUP (Preparação do golpe, braço esticando)
			if _timer >= startup_time:
				_phase = 1
				if hitbox: hitbox.enable_box()
		
		1: # ACTIVE (Dano ativo, punho bate)
			if _timer >= (startup_time + active_time):
				_phase = 2
				if hitbox: hitbox.disable_box()
		
		2: # RECOVERY (Recuperação, puxando o braço de volta)
			if _timer >= (startup_time + active_time + recovery_time):
				_on_attack_finished()
				
	# Gerencia o fim da invencibilidade
	if invincibility_duration > 0 and _timer >= invincibility_duration:
		_remove_invincibility()

func _on_attack_finished() -> void:
	# [NOVO] Devolve para a árvore os estados com base na nova nomenclatura.
	# Quando o golpe termina, mandamos o lutador pro Idle ou Fall. 
	# A própria FSM deles se vira com Input depois!
	if fighter.is_on_floor():
		transition_requested.emit("IdleState", {})
	else:
		transition_requested.emit("FallState", {})

func _on_exit() -> void:
	# Limpeza de segurança crucial: se tomarmos dano e o estado for interrompido, 
	# garantimos que o soco seja desativado imediatamente.
	var hitbox = fighter.get_component("HitboxComponent") as HitboxComponent
	if hitbox: hitbox.disable_box()
	_remove_invincibility()
	
func get_tags() -> Array:
	# Mantém a tipagem estrita de Array[String] exigida pela StateMachine
	var typed_tags: Array[String] = []
	for tag in attack_tags:
		typed_tags.append(String(tag))
	return typed_tags
	
# =========================================================
# 📏 FUNÇÃO DE SUPORTE PARA ATAQUES DE PERTO (CLOSE NORMALS)
# =========================================================
func _is_near_opponent() -> bool:
	# [NOVO] Substituímos a matemática manual pesada pelo nosso sistema 
	# inteligente do ProximityBoxComponent que faz o trabalho físico de colisão!
	var proximity_box = fighter.get_component("ProximityBoxComponent") as ProximityBoxComponent
	
	if proximity_box and proximity_box.is_active():
		return proximity_box.is_target_near
		
	return false 

# =========================================================
# 🔄 SIMULAÇÃO DE CANCELAMENTOS (Gatling / Cancels)
# =========================================================
func _process_cancel_routes() -> bool:
	if not fighter: return false
	
	var input_buffer = fighter.get_component("InputBufferComponent")
	var main_fsm = fighter.get_component("StateMachine")
	
	if not input_buffer or not main_fsm: return false
	
	# 1. Pega todas as tags ativas neste exato frame (ex: ["Attacking", "Grounded"])
	# Se quisermos permitir o cancelamento apenas no Active/Recovery, 
	# podemos injetar a tag "Cancellable" dinamicamente aqui!
	var current_tags = main_fsm.get_tags()
	
	# Exemplo: Se o soco conectou (hitbox bateu), nós adicionamos a tag "Cancellable"
	# (Você pode controlar isso com uma variável booleana 'has_hit' que liga no sinal attack_connected)
	current_tags.append("Cancellable") 
	
	# 2. Pergunta ao InputBuffer se tem algum Special Move na agulha
	# que aceita a tag "Cancellable" ou "Attacking"
	var result = input_buffer.check_special_moves(current_tags)
	
	# 3. Se o jogador digitou um Hadouken e o InputBuffer devolveu a Query:
	if result.has("query"):
		print("⚡ [AttackComponent] Cancelamento de Golpe Sucedido!")
		
		# Montamos o Payload com a ordem de execução
		var payload = {
			"query": result["query"]
		}
		
		# Injetamos a ordem direto na FSM Raiz. 
		# Ela vai engolir este soco imediatamente e saltar para o Hadouken!
		main_fsm.enter(payload)
		
		return true # Retorna true para interromper o physics_update do soco
		
	return false

# =========================================================
# 🔊 FUNÇÕES DE UTILIDADE (VFX & SOM)
# =========================================================
func _play_sfx(stream: AudioStream) -> void:
	if stream == null or not fighter: return
	# Futuramente: fighter.get_component("AudioComponent").play(stream)
	pass

func _apply_invincibility() -> void:
	if invincibility_type == "None" or not fighter: return
	# Futuramente: injetar no HitboxComponent ou HurtboxComponent as imunidades
	pass

func _remove_invincibility() -> void:
	if invincibility_type == "None" or not fighter: return
	# Futuramente: limpar as imunidades
	pass
