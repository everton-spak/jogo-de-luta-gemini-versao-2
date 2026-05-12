class_name CrouchHadoukenHeavy
extends State

@export var animation_name: String = "hadouken_crouch_heavy"
@export var startup_time: float = 0.17
@export var projectile_scene: PackedScene

var _spawned: bool = false

func _ready() -> void:
	type_dim = "hadouken"
	strength_dim = "heavy"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	fighter.velocity = Vector2.ZERO
	_spawned = false
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _spawned and state_time_sec >= startup_time:
		_spawned = true
		_spawn_projectile()

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		transition_requested.emit("IdleState", {})

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter:
		return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0
	proj.global_position = fighter.global_position + Vector2(50.0 * f_dir, -20.0)
	if proj.has_method("launch"):
		proj.launch(f_dir, 650.0)
