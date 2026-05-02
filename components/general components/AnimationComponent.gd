class_name AnimationComponent
extends Component

signal animation_finished(anim_name: String)
signal interval_finished(anim_name: String)

@export var animation_player: AnimationPlayer
@export var base_fps: float = 60.0 # Jogos de luta operam a 60 frames por segundo

# Variáveis internas para o controle de intervalo
var _is_playing_interval: bool = false
var _interval_end_time: float = 0.0
var _interval_loop: bool = false
var _interval_start_time: float = 0.0

func _on_initialized() -> void:
	if not animation_player:
		# Tenta achar o AnimationPlayer no lutador se não foi configurado no Inspector
		animation_player = fighter.get_node("AnimationPlayer")
		
	# Repassa o sinal nativo para quem quiser ouvir este componente
	animation_player.animation_finished.connect(func(anim): animation_finished.emit(anim))

func _physics_process(_delta: float) -> void:
	# Lógica para parar ou em loopar a animação quando atingir o fim do intervalo
	if _is_playing_interval and animation_player.is_playing():
		if animation_player.current_animation_position >= _interval_end_time:
			if _interval_loop:
				# Se for loop de intervalo, volta pro frame inicial do intervalo
				animation_player.seek(_interval_start_time, true)
			else:
				# Se não, para exatamente no frame final
				pause()
				_is_playing_interval = false
				interval_finished.emit(animation_player.current_animation)

# --- CONTROLES BÁSICOS ---

# Toca normal (Velocidade 1.0 = 100%, 2.0 = 200% mais rápido)
func play(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	animation_player.play(anim_name, -1, speed)

# Toca de trás para a frente
func play_reverse(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	animation_player.play_backwards(anim_name, -1)
	animation_player.speed_scale = speed

# Pausa e Retoma (Ideal para Hitstop ou parries)
func pause() -> void:
	animation_player.pause()

func resume() -> void:
	animation_player.play()

# --- CONTROLE AVANÇADO POR FRAMES ---

# Pula para um frame exato e fica parado nele (se estiver pausado) ou continua tocando
func seek_frame(frame: int) -> void:
	var time_in_seconds = float(frame) / base_fps
	animation_player.seek(time_in_seconds, true) # true = atualiza a tela na hora

# Toca apenas um pedaço da animação (Ex: do frame 5 ao frame 15)
func play_interval_frames(anim_name: String, start_frame: int, end_frame: int, loop: bool = false) -> void:
	_interval_start_time = float(start_frame) / base_fps
	_interval_end_time = float(end_frame) / base_fps
	_interval_loop = loop
	_is_playing_interval = true
	
	animation_player.play(anim_name)
	animation_player.seek(_interval_start_time, true)

# Descobre em qual frame a animação está agora
func get_current_frame() -> int:
	return int(animation_player.current_animation_position * base_fps)

# Força o loop de uma animação via código, ignorando a configuração do painel
func set_looping(anim_name: String, loop: bool) -> void:
	var anim = animation_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
