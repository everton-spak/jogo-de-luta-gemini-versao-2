class_name AttackComponent
extends State

# =========================================================
# 🏷️ TAGS E CLASSIFICAÇÃO
# =========================================================
@export_group("Tags & Classification")
## Tags que o InputBuffer lerá (ex: "Cancellable" permite interromper o golpe com um especial)
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
# 💥 PROPRIEDADES DE COMBATE (NOVAS FUNCIONALIDADES)
# =========================================================
@export_group("Combat Properties")
@export var damage: float = 10.0
@export var hitstun_time: float = 0.4
@export var blockstun_time: float = 0.2
@export var pushback_force: float = 200.0
@export var causes_knockdown: bool = false
@export var meter_gain: float = 5.0
@export var base_scaling: float = 1.0 # Usado no ScalingComboComponent

# =========================================================
# ✨ EXTRAS (NOVAS FUNCIONALIDADES)
# =========================================================
@export_group("Extras")
## Toca um som específico no momento do startup
@export var startup_sfx: AudioStream
## Toca um som específico no momento do active (hit)
@export var hit_sfx: AudioStream
## Invencibilidade durante o startup/active
@export_enum("None", "Full", "Strike", "Projectile", "Throw") var invincibility_type: String = "None"
@export var invincibility_duration: float = 0.0

@export var proximity_threshold: float = 80.0

var _timer: float = 0.0
var _phase: int = 0 # 0: Startup, 1: Active, 2: Recovery

func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_phase = 0
	
	# 1. Toca a animação específica definida no Inspector
	if anim and animation_name != "":
		anim.play(animation_name)
		
	# Toca som de startup se existir
	_play_sfx(startup_sfx)
	
	# Aplica invencibilidade se configurada
	_apply_invincibility()
	
	# 2. Configura a Hitbox para este golpe específico
	_setup_hitbox()
	
	# Passa propriedades extras para o hitbox
	_update_hitbox_properties()

func _setup_hitbox() -> void:
	if not hitbox: return
	
	# Garante que começa desligada
	hitbox.disable_box() 
	
	# Inverte a posição horizontal com base no FacingComponent
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.area_2d.position = Vector2(hitbox_pos.x * f_dir, hitbox_pos.y)
	
	# Ajusta o tamanho da colisão (se for um RectangleShape2D)
	if hitbox.collision_shape and hitbox.collision_shape.shape is RectangleShape2D:
		hitbox.collision_shape.shape.size = hitbox_size

func _update_hitbox_properties() -> void:
	if not hitbox: return
	
	# Adiciona dados extras na hitbox para serem lidos pelo Hurtbox do inimigo
	hitbox.set_meta("damage", damage)
	hitbox.set_meta("hitstun", hitstun_time)
	hitbox.set_meta("blockstun", blockstun_time)
	hitbox.set_meta("pushback", pushback_force)
	hitbox.set_meta("knockdown", causes_knockdown)
	hitbox.set_meta("attack_type", attack_type)
	hitbox.set_meta("meter_gain", meter_gain)
	hitbox.set_meta("base_scaling", base_scaling)

func physics_update(_delta: float) -> void:
	_timer += _delta
	
	# =========================================================
	# ⚡ CANCELAMENTOS DO ATAQUE
	# =========================================================
	# O soco/chute continua a mandar: "Só permito cancelar a partir da fase Active!"
	if _phase >= 1:
		# Chama a função do Pai. Se ele retornar true, o combo saiu, então paramos este script com "return"
		if process_cancel_routes():
			return
			
	# =========================================================
	# MÁQUINA DE ESTADOS INTERNA DO GOLPE
	# =========================================================
	match _phase:
		0: # STARTUP (Preparação)
			if _timer >= startup_time:
				_phase = 1
				if hitbox: hitbox.enable_box()
		
		1: # ACTIVE (Dano ativo)
			if _timer >= (startup_time + active_time):
				_phase = 2
				if hitbox: hitbox.disable_box()
		
		2: # RECOVERY (Recuperação / Vulnerável)
			if _timer >= (startup_time + active_time + recovery_time):
				_on_attack_finished()
				
	# Gerencia o fim da invencibilidade
	if invincibility_duration > 0 and _timer >= invincibility_duration:
		_remove_invincibility()

func _on_attack_finished() -> void:
	# Pede à StateMachine pai (NormalAttack ou SpecialAttack) para sair.
	# Como o pai não tem "IdleState", ele passará o pedido para a RootStateMachine.
	if fighter.is_on_floor():
		transition_requested.emit("GroundState", {})
	else:
		transition_requested.emit("AirState", {})

func exit() -> void:
	# Limpeza de segurança
	if hitbox: hitbox.disable_box()
	_remove_invincibility()
	
func get_tags() -> Array:
	return attack_tags
	
# =========================================================
# NOVA FUNÇÃO DE SUPORTE PARA ATAQUES DE PERTO (CLOSE)
# =========================================================
func _is_near_opponent() -> bool:
	# Lê a variável "target_fighter" definida no teu Fighter.gd
	if "target_fighter" in fighter and fighter.target_fighter != null:
		
		# Calcula a distância horizontal entre os dois lutadores
		var distance = abs(fighter.global_position.x - fighter.target_fighter.global_position.x)
		
		# Procura a variável proximity_threshold no script filho (LightPunch, HeavyPunch, etc)
		var threshold = get("proximity_threshold")
		if threshold == null: 
			threshold = 80.0 # Valor padrão de segurança
			
		return distance <= threshold
		
	return false # Se não houver inimigo, ataca sempre de longe

# =========================================================
# FUNÇÕES DE UTILIDADE (NOVAS)
# =========================================================
func _play_sfx(stream: AudioStream) -> void:
	if stream == null or not fighter: return
	
	# Procura um AudioStreamPlayer ou AudioStreamPlayer2D no Fighter
	# Exemplo: se houver um no lutador, toca o som. Se quiser implementar
	# um nó dedicado, adicione aqui!
	pass

func _apply_invincibility() -> void:
	if invincibility_type == "None" or not fighter: return
	
	# Exemplo: chama uma função no lutador para desligar hurtboxes específicas
	if fighter.has_method("set_invincibility"):
		fighter.set_invincibility(true, invincibility_type)

func _remove_invincibility() -> void:
	if invincibility_type == "None" or not fighter: return
	
	if fighter.has_method("set_invincibility"):
		fighter.set_invincibility(false, "None")
