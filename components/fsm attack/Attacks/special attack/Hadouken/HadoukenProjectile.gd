class_name HadoukenProjectile
extends Node2D

@export var base_speed: float = 500.0

var _direction: float = 1.0
var _speed: float = 500.0
var _speed_y: float = 0.0
var _active: bool = false
var _dead: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: HitboxComponent = $HitboxComponent
@onready var _hit_area: Area2D = $HitArea

func _ready() -> void:
	if _hitbox:
		_hitbox.initialize_once() if _hitbox.has_method("initialize_once") else _hitbox._on_initialized()
	if _hit_area and not _hit_area.area_entered.is_connected(_on_hit_area_entered):
		_hit_area.area_entered.connect(_on_hit_area_entered)

func launch(dir: float, speed: float, attacker: Node, dmg: int, hitstun: float, knockback: Vector2, speed_y: float = 0.0) -> void:
	_direction = dir
	_speed = speed
	_speed_y = speed_y
	_active = true

	if _hitbox:
		_hitbox.fighter = attacker
		_hitbox.damage = dmg
		_hitbox.hitstun_duration = hitstun
		_hitbox.knockback_force = Vector2(absf(knockback.x), knockback.y)
		_hitbox.attack_level = "mid"
		_hitbox.enable_box()

	if _hit_area:
		_hit_area.scale.x = dir  # espelha a hitbox junto com o sprite

	_anim.flip_h = dir < 0.0
	_anim.rotation = atan2(speed_y, _speed * dir)
	_anim.play("fireball")

func _process(delta: float) -> void:
	if _dead or not _active: return
	position.x += _direction * _speed * delta
	position.y += _speed_y * delta
	# Destroi se sair dos limites horizontais da arena ou tocar o chão (Hadouken aéreo)
	if global_position.x < -300.0 or global_position.x > 2220.0 or global_position.y >= 1045.0:
		queue_free()

func _on_hit_area_entered(area: Area2D) -> void:
	if _dead: return
	var node = area.get_parent()
	# Fireball Clash entre projéteis de lutadores diferentes
	if node is HadoukenProjectile and node != self:
		if node._hitbox and _hitbox and node._hitbox.fighter != _hitbox.fighter:
			node._on_hit()
			_on_hit()
		return
	# Acertou Hurtbox direta ou de CharacterBody2D (exceto próprio dono ou alvo invencível/KO)
	if node is HurtboxComponent and node.fighter != (_hitbox.fighter if _hitbox else null):
		if _target_is_hittable(node.fighter):
			_on_hit()
	elif node is CharacterBody2D and _hitbox and node != _hitbox.fighter and node.has_method("get_component"):
		var hb = node.get_component("HurtboxComponent")
		if hb is HurtboxComponent and hb.area_2d == area and _target_is_hittable(node):
			_on_hit()

func _target_is_hittable(target: Node) -> bool:
	if not target or not target.has_method("get_component"):
		return true
	var fsm = target.get_component("StateMachine")
	if fsm:
		var tags: Array[String] = fsm.get_tags()
		if "Invincible" in tags or "KO" in tags:
			return false
	return true

func _on_hit() -> void:
	if _dead: return
	_dead = true
	_active = false
	if _hitbox and _hitbox.collision_shape:
		_hitbox.collision_shape.set_deferred("disabled", true)
	if _hit_area:
		_hit_area.set_deferred("monitoring", false)
		_hit_area.set_deferred("monitorable", false)
	_anim.play("fireball_impact")
	if not _anim.animation_finished.is_connected(queue_free):
		_anim.animation_finished.connect(queue_free)
