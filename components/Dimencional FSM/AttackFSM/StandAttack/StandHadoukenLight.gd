class_name StandHadoukenLight
extends State

@export var animation_name: String = "hadouken_stand"
# Frame da animação em que o projétil é lançado (ajuste no Inspector)
@export var spawn_frame: int = 5
@export var projectile_scene: PackedScene

var _spawned: bool = false

func _ready() -> void:
	type_dim = "hadouken"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	fighter.velocity = Vector2.ZERO
	_spawned = false
	if anim:
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _spawned and anim and anim.get_current_frame() >= spawn_frame:
		_spawned = true
		_spawn_projectile()

	# Guard: espera ao menos 3 frames antes de checar fim da animação
	if state_frames < 3:
		return
	if anim and anim.has_method("is_playing") and not anim.is_playing():
		transition_requested.emit("IdleState", {})

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter:
		return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0
	var marker = fighter.get_node_or_null("ProjectileSpawn")
	if marker:
		# Usa a posição do marcador mas espelha o X conforme a direção
		var local = marker.position
		proj.global_position = fighter.global_position + Vector2(local.x * f_dir, local.y)
	else:
		proj.global_position = fighter.global_position + Vector2(50.0 * f_dir, -80.0)
	if proj.has_method("launch"):
		proj.launch(f_dir, 400.0)
