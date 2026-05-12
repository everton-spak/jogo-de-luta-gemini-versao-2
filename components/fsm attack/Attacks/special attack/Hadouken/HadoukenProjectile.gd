class_name HadoukenProjectile
extends Node2D

@export var base_speed: float = 500.0

var _direction: float = 1.0
var _speed: float = 500.0
var _active: bool = false
var _dead: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D

func launch(dir: float, speed: float) -> void:
	_direction = dir
	_speed = speed
	_active = true
	_anim.flip_h = dir < 0.0
	_anim.play("fireball")

func _process(delta: float) -> void:
	if _dead:
		return
	if not _active:
		return

	position.x += _direction * _speed * delta

	# Destrói se sair da tela
	var vp = get_viewport_rect()
	if position.x < vp.position.x - 200 or position.x > vp.end.x + 200:
		queue_free()

func _on_hit() -> void:
	if _dead:
		return
	_dead = true
	_active = false
	_anim.play("fireball_impact")
	_anim.animation_finished.connect(queue_free)
