class_name StandLightPunch
extends State

@export_group("Configuração do Ataque")
@export var animation_name: String = "lp_close"
## Estado para onde o lutador volta após o soco terminar
@export var recovery_state: String = "IdleState"

func _ready() -> void:
	# Define as dimensões para o Roteador Heurístico
	type_dim = "punch"
	strength_dim = "light"
	# Nota: stance_dim e direction_dim podem ser "any" ou herdados
	
func enter(_payload: Dictionary = {}) -> void:
	print("🥊 [StandLightPunch] Executando soco leve!")
	if anim:
		anim.play(animation_name)
	
	# Aqui podes emitir um sinal para o seu HitboxComponent ativar 
	# ou o componente de áudio tocar o som do soco.

func physics_update(_delta: float) -> void:
	# Condição de Saída Automática: 
	# Quando a animação do soco termina, ele volta para o repouso.
	if anim and not anim.is_playing():
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	# Adiciona tags específicas para este golpe. 
	# A tag "Attacking" ajuda a prevenir outros movimentos.
	return ["Attacking", "HighPriority"]
