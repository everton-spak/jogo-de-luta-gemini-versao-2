class_name AirHurtState
extends State

# Acertado no ar — vira juggle. Aplica launch (vertical + horizontal) com curva de juggle,
# gravidade reduzida pra dar tempo de combar no ar, e ao tocar o chão transiciona pra Knockdown.

@export_group("Animação")
@export var anim_juggle: String = "juggle_spin"

@export_group("Física")
@export var juggle_gravity_multiplier: float = 0.6
@export var min_air_frames: int = 6

@export_group("Curvas de Física")
@export var juggle_curve: Curve

var _initial_knockback_x: float = 0.0

func _ready() -> void:
	type_dim = "juggle"
	stance_dim = "air"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "FallState"
	if not juggle_curve:
		juggle_curve = PhysicsCurves.create_juggle_decay_curve()

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})
	_initial_knockback_x = float(hit_data.get("knockback_x", 0.0))

	if fighter:
		fighter.velocity.x = _initial_knockback_x
		fighter.velocity.y = float(hit_data.get("knockback_y", -400.0))

	if vfx and fighter:
		var is_heavy: bool = (float(hit_data.get("damage", 0)) >= 15)
		vfx.spawn_hit_spark(fighter.global_position + Vector2(0, -40), is_heavy)

	if anim:
		anim.play(anim_juggle)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Gravidade reduzida pra prolongar o juggle
	if movement:
		movement.apply_gravity(delta, juggle_gravity_multiplier)

	# Decaimento horizontal curvado para manter o oponente no alcance de juggle combos
	var progress = clamp(state_time_sec / 0.6, 0.0, 1.0)
	var decay = juggle_curve.sample_baked(progress) if juggle_curve else (1.0 - progress)
	fighter.velocity.x = _initial_knockback_x * decay

	# Tocou o chão? Sai do juggle
	if state_frames >= min_air_frames and fighter.is_on_floor():
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit("KnockdownState", {
				"hit_data": {
					"knockback_x": fighter.velocity.x,
					"knockback_y": fighter.velocity.y,
				}
			})

func get_tags() -> Array[String]:
	return ["Hurt", "Juggling"]
