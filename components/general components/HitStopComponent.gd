class_name HitstopComponent
extends Component

var time_left: float = 0.0
var anim_player: AnimationPlayer

func _on_initialized() -> void:
	# Tenta encontrar o AnimationPlayer do lutador
	var anim_comp = get_component("AnimatedSpriteComponent")
	if anim_comp and anim_comp.has_node("AnimatedSprite2D"):
		anim_player = anim_comp.get_node("AnimatedSprite2D")

func start_hitstop(duration: float) -> void:
	if duration <= 0.0: return
	
	time_left = duration
	
	# Pausa a animação imediatamente
	if anim_player:
		anim_player.pause()

func _physics_process(delta: float) -> void:
	# Conta o tempo de congelamento
	if time_left > 0.0:
		time_left -= delta
		
		# Quando o tempo acabar, descongela a animação
		if time_left <= 0.0:
			time_left = 0.0
			if anim_player:
				anim_player.play()

# Função utilitária para o Fighter saber se está congelado
func is_stopped() -> bool:
	return time_left > 0.0
