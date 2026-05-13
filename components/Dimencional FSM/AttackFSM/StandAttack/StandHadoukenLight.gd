class_name StandHadoukenLight
extends State

@export var animation_name: String = "hadouken_stand"
@export var spawn_frame: int = 5
@export var recovery_time: float = 0.25
@export var projectile_scene: PackedScene

@export_group("Projétil")
@export var proj_speed: float = 400.0
@export var proj_damage: int = 8
@export var proj_hitstun: float = 0.30
@export var proj_knockback: Vector2 = Vector2(200, -50)

var _spawned: bool = false
var _in_recovery: bool = false
var _recovery_timer: float = 0.0

func _ready() -> void:
	type_dim = "hadouken"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	fighter.velocity = Vector2.ZERO
	_spawned = false
	_in_recovery = false
	_recovery_timer = 0.0
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if _in_recovery:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0:
			transition_requested.emit("IdleState", {})
		return

	if not _spawned and anim and anim.get_current_frame() >= spawn_frame:
		_spawned = true
		_spawn_projectile()

	if state_frames < 3: return
	if anim and anim.has_method("is_playing") and not anim.is_playing():
		_in_recovery = true
		_recovery_timer = recovery_time

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter: return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0
	var marker = fighter.get_node_or_null("ProjectileSpawn")
	if marker:
		var local = marker.position
		proj.global_position = fighter.global_position + Vector2(local.x * f_dir, local.y)
	else:
		proj.global_position = fighter.global_position + Vector2(50.0 * f_dir, -80.0)
	if proj.has_method("launch"):
		proj.launch(f_dir, proj_speed, fighter, proj_damage, proj_hitstun, proj_knockback)
