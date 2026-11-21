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
		_register_missing_animations()
		# 🚨 TRAVA DE SEGURANÇA (Godot 4)
		var anim_callable = Callable(self, "_on_sprite_animation_finished")
		
		if not sprite.animation_finished.is_connected(anim_callable):
			sprite.animation_finished.connect(anim_callable)

func _register_missing_animations() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var sf := sprite.sprite_frames
	_add_anim_if_missing(sf, "block_stand", [
		"res://shin ryu sprites/animaçoes/defesa/120-0.png",
		"res://shin ryu sprites/animaçoes/defesa/120-1.png",
		"res://shin ryu sprites/animaçoes/defesa/120-2.png",
		"res://shin ryu sprites/animaçoes/defesa/120-3.png",
	], 12.0, false)
	_add_anim_if_missing(sf, "block_crouch", [
		"res://shin ryu sprites/animaçoes/defesa/121-0.png",
		"res://shin ryu sprites/animaçoes/defesa/121-1.png",
		"res://shin ryu sprites/animaçoes/defesa/121-2.png",
		"res://shin ryu sprites/animaçoes/defesa/121-3.png",
		"res://shin ryu sprites/animaçoes/defesa/121-4.png",
	], 12.0, false)
	_add_anim_if_missing(sf, "guard_broken", [
		"res://shin ryu sprites/animaçoes/defesa/123-0.png",
		"res://shin ryu sprites/animaçoes/defesa/123-1.png",
		"res://shin ryu sprites/animaçoes/defesa/123-2.png",
		"res://shin ryu sprites/animaçoes/defesa/123-3.png",
		"res://shin ryu sprites/animaçoes/defesa/123-4.png",
		"res://shin ryu sprites/animaçoes/defesa/123-5.png",
	], 10.0, false)
	_add_anim_if_missing(sf, "throw_tech", [
		"res://shin ryu sprites/animaçoes/defesa/123-0.png",
		"res://shin ryu sprites/animaçoes/defesa/123-1.png",
		"res://shin ryu sprites/animaçoes/defesa/123-2.png",
		"res://shin ryu sprites/animaçoes/defesa/123-3.png",
	], 14.0, false)
	_add_anim_if_missing(sf, "hit_high", [
		"res://shin ryu sprites/hurt/5000-0.png",
		"res://shin ryu sprites/hurt/5000-10.png",
		"res://shin ryu sprites/hurt/5000-11.png",
		"res://shin ryu sprites/hurt/5000-20.png",
	], 12.0, false)
	_add_anim_if_missing(sf, "hit_mid", [
		"res://shin ryu sprites/hurt/5010-0.png",
		"res://shin ryu sprites/hurt/5010-1.png",
		"res://shin ryu sprites/hurt/5010-2.png",
		"res://shin ryu sprites/hurt/5010-3.png",
		"res://shin ryu sprites/hurt/5010-4.png",
	], 12.0, false)
	_add_anim_if_missing(sf, "hit_low", [
		"res://shin ryu sprites/hurt/5020-0.png",
		"res://shin ryu sprites/hurt/5020-10.png",
		"res://shin ryu sprites/hurt/5020-12.png",
		"res://shin ryu sprites/hurt/5020-13.png",
	], 12.0, false)
	var fall_frames := [
		"res://shin ryu sprites/hurt/5030-0.png",
		"res://shin ryu sprites/hurt/5030-10.png",
		"res://shin ryu sprites/hurt/5030-11.png",
		"res://shin ryu sprites/hurt/5030-20.png",
		"res://shin ryu sprites/hurt/5030-30.png",
		"res://shin ryu sprites/hurt/5030-40.png",
		"res://shin ryu sprites/hurt/5030-41.png",
		"res://shin ryu sprites/hurt/5030-50.png",
	]
	for fall_anim in ["juggle_spin", "ko_fall", "knockdown_fall", "thrown", "wall_splat"]:
		_add_anim_if_missing(sf, fall_anim, fall_frames, 12.0, false)
	var grounded_frames := [
		"res://shin ryu sprites/hurt/5080-0.png",
		"res://shin ryu sprites/hurt/5080-1.png",
		"res://shin ryu sprites/hurt/5080-2.png",
	]
	_add_anim_if_missing(sf, "knockdown_grounded", grounded_frames, 6.0, true)
	_add_anim_if_missing(sf, "ko_grounded", grounded_frames, 6.0, true)
	var wakeup_frames := [
		"res://shin ryu sprites/hurt/5120-0.png",
		"res://shin ryu sprites/hurt/5120-1.png",
		"res://shin ryu sprites/hurt/5120-2.png",
		"res://shin ryu sprites/hurt/5120-3.png",
		"res://shin ryu sprites/hurt/5120-4.png",
		"res://shin ryu sprites/hurt/5120-5.png",
		"res://shin ryu sprites/hurt/5120-6.png",
	]
	for wu_anim in ["wakeup_quick", "wakeup_back", "wakeup_no_tech"]:
		_add_anim_if_missing(sf, wu_anim, wakeup_frames, 12.0, false)
	_add_anim_if_missing(sf, "dizzy", [
		"res://shin ryu sprites/hurt/5300-0.png",
		"res://shin ryu sprites/hurt/5300-1.png",
		"res://shin ryu sprites/hurt/5300-2.png",
		"res://shin ryu sprites/hurt/5300-3.png",
		"res://shin ryu sprites/hurt/5300-4.png",
		"res://shin ryu sprites/hurt/5300-5.png",
		"res://shin ryu sprites/hurt/5300-6.png",
	], 10.0, true)
	_add_anim_if_missing(sf, "super_throw_close", [
		"res://shin ryu sprites/animaçoes/attack/grab/800-0.png",
		"res://shin ryu sprites/animaçoes/attack/grab/800-1.png",
		"res://shin ryu sprites/animaçoes/attack/grab/800-3.png",
		"res://shin ryu sprites/animaçoes/attack/grab/800-4.png",
		"res://shin ryu sprites/animaçoes/attack/grab/800-5.png",
		"res://shin ryu sprites/animaçoes/attack/grab/800-7.png",
	], 12.0, false)

func _add_anim_if_missing(sf: SpriteFrames, anim_name: String, paths: Array, fps: float, loop: bool) -> void:
	if sf.has_animation(anim_name):
		return
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for path in paths:
		var tex = load(path)
		if tex:
			sf.add_frame(anim_name, tex)

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

# Toca a animação (com fallback seguro pra "idle" se não existir)
func play(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	if sprite:
		if sprite.sprite_frames and not sprite.sprite_frames.has_animation(anim_name):
			anim_name = "idle"
		sprite.speed_scale = absf(speed)
		sprite.play(anim_name, 1.0, false)

# Toca a animação de trás para frente a partir do último frame (from_end=true),
# mantendo speed_scale e get_playing_speed() negativos e consistentes.
func play_reverse(anim_name: String, speed: float = 1.0) -> void:
	_is_playing_interval = false
	if sprite:
		if sprite.sprite_frames and not sprite.sprite_frames.has_animation(anim_name):
			anim_name = "idle"
		sprite.speed_scale = -absf(speed)
		sprite.play(anim_name, 1.0, true)

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
		
func is_playing() -> bool:
	if sprite:
		return sprite.is_playing()
	return false

# --- SIGNAL frame_changed (usado por Shoryukens p/ pausar frame específico) ---
# Guarda anti-duplicata embutida.

func connect_frame_changed(cb: Callable) -> void:
	if sprite and not sprite.frame_changed.is_connected(cb):
		sprite.frame_changed.connect(cb)

func disconnect_frame_changed(cb: Callable) -> void:
	if sprite and sprite.frame_changed.is_connected(cb):
		sprite.frame_changed.disconnect(cb)
