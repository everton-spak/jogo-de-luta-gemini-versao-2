class_name HitstopComponent
extends Component

var time_left: float = 0.0
var anim_sprite: AnimatedSprite2D
var _base_sprite_x: float = 0.0
var _shake_toggle: bool = false

func _on_initialized() -> void:
	var anim_comp = get_component("AnimatedSpriteComponent") as AnimatedSpriteComponent
	if anim_comp and anim_comp.sprite:
		anim_sprite = anim_comp.sprite
	elif fighter:
		anim_sprite = fighter.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func start_hitstop(duration: float) -> void:
	if duration <= 0.0: return
	if anim_sprite and time_left <= 0.0:
		_base_sprite_x = anim_sprite.position.x
	time_left = maxf(time_left, duration)
	if anim_sprite:
		anim_sprite.pause()

func _physics_process(delta: float) -> void:
	if time_left > 0.0:
		time_left -= delta
		# Micro-vibração clássica de arcade no defensor durante hitstop
		if anim_sprite and fighter:
			var fsm = fighter.get_component("StateMachine")
			if fsm:
				var tags: Array[String] = fsm.get_tags()
				if "Hurt" in tags or "Blocking" in tags:
					_shake_toggle = not _shake_toggle
					anim_sprite.position.x = _base_sprite_x + (4.0 if _shake_toggle else -4.0)
		
		if time_left <= 0.0:
			time_left = 0.0
			if anim_sprite:
				anim_sprite.position.x = _base_sprite_x
				anim_sprite.play()

func is_stopped() -> bool:
	return time_left > 0.0
