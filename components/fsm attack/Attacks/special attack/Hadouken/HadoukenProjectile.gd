class_name HadoukenProjectile
extends Node2D

@export var base_speed: float = 500.0

var _direction: float = 1.0
var _speed: float = 500.0
var _active: bool = false
var _dead: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: HitboxComponent = $HitboxComponent
@onready var _hit_area: Area2D = $HitArea

func _ready() -> void:
	if _hitbox:
		_hitbox._on_initialized()
	if _hit_area:
		_hit_area.area_entered.connect(_on_hit_area_entered)

func launch(dir: float, speed: float, attacker: Node, dmg: int, hitstun: float, knockback: Vector2) -> void:
	_direction = dir
	_speed = speed
	_active = true

	if _hitbox:
		_hitbox.fighter = attacker
		_hitbox.damage = dmg
		_hitbox.hitstun_duration = hitstun
		_hitbox.knockback_force = Vector2(knockback.x * dir, knockback.y)
		_hitbox.attack_level = "mid"

	if _hit_area:
		_hit_area.scale.x = dir  # espelha a hitbox junto com o sprite

	_anim.flip_h = dir < 0.0
	_anim.play("fireball")

func _process(delta: float) -> void:
	if _dead or not _active: return
	position.x += _direction * _speed * delta
	var vp = get_viewport_rect()
	if position.x < vp.position.x - 200 or position.x > vp.end.x + 200:
		queue_free()

func _on_hit_area_entered(area: Area2D) -> void:
	if _dead: return
	var node = area.get_parent()
	if node is HurtboxComponent:
		_on_hit()

func _on_hit() -> void:
	if _dead: return
	_dead = true
	_active = false
	_anim.play("fireball_impact")
	_anim.animation_finished.connect(queue_free)
