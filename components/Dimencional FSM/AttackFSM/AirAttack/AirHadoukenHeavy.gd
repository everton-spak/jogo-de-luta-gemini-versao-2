class_name AirHadoukenHeavy
extends State

@export var animation_name: String = "hadouken_air"
@export var spawn_frame: int = 5
@export var projectile_scene: PackedScene

@export_group("Projétil")
@export var proj_speed: float = 650.0
@export var proj_speed_y: float = 350.0
@export var proj_damage: int = 15
@export var proj_hitstun: float = 0.45
@export var proj_knockback: Vector2 = Vector2(280, -80)

var _spawned: bool = false

func _ready() -> void:
	stance_dim = "air"
	type_dim = "hadouken"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_spawned = false
	if anim: anim.play(animation_name)

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)

	if not _spawned and anim and anim.get_current_frame() >= spawn_frame:
		_spawned = true
		_spawn_projectile()

	if anim and not anim.is_playing():
		transition_requested.emit("FallState", {})

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter: return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0
	var marker = fighter.get_node_or_null("ProjectileSpawnAir")
	if not marker:
		marker = fighter.get_node_or_null("ProjectileSpawn")
	if marker:
		proj.global_position = fighter.global_position + Vector2(marker.position.x * f_dir, marker.position.y)
	else:
		proj.global_position = fighter.global_position + Vector2(50.0 * f_dir, -80.0)
	if proj.has_method("launch"):
		proj.launch(f_dir, proj_speed, fighter, proj_damage, proj_hitstun, proj_knockback, proj_speed_y)

func exit() -> void:
	super.exit()

func get_tags() -> Array[String]:
	return ["Attacking", "Airborne", "Cancellable"]
