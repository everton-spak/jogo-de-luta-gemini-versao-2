class_name AnimatedSpriteComponent
extends Component

signal animation_finished(anim_name: String)
signal interval_finished(anim_name: String)

@export var sprite: AnimatedSprite2D
@export var base_fps: float = 60.0 # Mantido para cálculos de tempo se necessário

# Variáveis internas para o controle de intervalo
var _is_playing_interval: bool = false
var _interval_start_frame: int = 0
var _interval_end_frame: int = 0
var _interval_loop: bool = false

func _on_initialized() -> void:
	if not sprite:
		# Tenta achar o AnimatedSprite2D no lutador se não foi configurado 
		sprite = fighter.get_node_or_null("AnimatedSprite2D")
	
	if sprite:
		# 🚨 TRAVA DE SEGURANÇA (Godot 4)
		var anim_callable = Callable(self, "_on_sprite_animation_finished")
		
		if not sprite.animation_finished.is_connected(anim_callable):
			sprite.animation_finished.connect(anim_callable)

func _physics_process(_delta: float) -> void:
	# Lógica para controlar o intervalo de frames 
	if _is_playing_interval and sprite.is_playing():
		if sprite.frame >= _interval_end_frame:
			if _interval_loop:
				sprite.frame = _interval_start_frame
			else:
				pause()
				_is_playing_interval = false
				interval_finished.emit(sprite.animation)

func _on_sprite_animation_finished() -> void:
	animation_finished.emit(sprite.animation)

# --- CONTROLES BÁSICOS ---

# Toca a animação 
func play(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	if sprite:
		sprite.speed_scale = speed
		sprite.play(anim_name)

# Nota: AnimatedSprite2D não tem play_backwards nativo da mesma forma, 
# mas podemos simular invertendo a escala de velocidade.
func play_reverse(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	if sprite:
		sprite.speed_scale = -speed
		sprite.play(anim_name)

func pause() -> void:
	if sprite:
		sprite.pause()

func resume() -> void:
	if sprite:
		sprite.play()

# --- CONTROLE POR FRAMES ---

# Pula para um frame exato (índice do sprite) 
func seek_frame(frame: int) -> void:
	if sprite:
		sprite.frame = frame

# Toca apenas um pedaço da animação (Ex: do frame 5 ao 15) 
func play_interval_frames(anim_name: String, start_frame: int, end_frame: int, loop: bool = false) -> void:
	_interval_start_frame = start_frame
	_interval_end_frame = end_frame
	_interval_loop = loop
	_is_playing_interval = true
	
	play(anim_name)
	seek_frame(start_frame)

# Descobre o frame atual
func get_current_frame() -> int:
	return sprite.frame if sprite else 0

# No AnimatedSprite2D, o loop é definido no SpriteFrames, 
# mas podemos tentar forçar via código se necessário.
func set_looping(anim_name: String, loop: bool) -> void:
	if sprite and sprite.sprite_frames:
		sprite.sprite_frames.set_animation_loop(anim_name, loop)
