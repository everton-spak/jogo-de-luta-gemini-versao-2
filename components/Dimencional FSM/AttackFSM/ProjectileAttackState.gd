class_name ProjectileAttackState
extends State

# Base para ataques que disparam projétil (Hadouken stand/crouch/air).
# Spawna o projétil quando a animação atinge spawn_frame.
# Suporta recovery_time opcional após o fim da animação.

@export_group("Projétil")
@export var projectile_scene: PackedScene
@export var spawn_frame: int = 5
@export var spawn_marker_name: String = "ProjectileSpawn"
# Marker alternativo (ex: "ProjectileSpawnAir") tentado antes do principal — útil para Air
@export var spawn_marker_alt: String = ""
@export var spawn_offset_fallback: Vector2 = Vector2(50.0, -80.0)

@export var proj_speed: float = 400.0
@export var proj_speed_y: float = 0.0
@export var proj_damage: int = 8
@export var proj_hitstun: float = 0.30
@export var proj_knockback: Vector2 = Vector2(200, -50)

@export_group("Recovery")
# Tempo extra após o fim da animação antes de transicionar (0 = imediato)
@export var recovery_time: float = 0.0

var _spawned: bool = false
var _in_recovery: bool = false
var _recovery_timer: float = 0.0

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_spawned = false
	_in_recovery = false
	_recovery_timer = 0.0
	# Stand/crouch zeram momentum; air mantém
	if fighter and stance_dim != "air":
		fighter.velocity = Vector2.ZERO
	if anim and animation_name != "":
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if _in_recovery:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0:
			transition_requested.emit(_resolve_recovery_state(), {})
		return

	if not _spawned and anim and anim.get_current_frame() >= spawn_frame:
		_spawned = true
		_spawn_projectile()

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		if recovery_time > 0.0:
			_in_recovery = true
			_recovery_timer = recovery_time
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func _resolve_recovery_state() -> String:
	if recovery_state != "":
		return recovery_state
	# Air → FallState; outros → IdleState
	return "FallState" if stance_dim == "air" else "IdleState"

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter: return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0

	var marker: Node = null
	if spawn_marker_alt != "":
		marker = fighter.get_node_or_null(spawn_marker_alt)
	if not marker:
		marker = fighter.get_node_or_null(spawn_marker_name)

	if marker:
		proj.global_position = fighter.global_position + Vector2(marker.position.x * f_dir, marker.position.y)
	else:
		proj.global_position = fighter.global_position + Vector2(spawn_offset_fallback.x * f_dir, spawn_offset_fallback.y)

	if proj.has_method("launch"):
		proj.launch(f_dir, proj_speed, fighter, proj_damage, proj_hitstun, proj_knockback, proj_speed_y)
