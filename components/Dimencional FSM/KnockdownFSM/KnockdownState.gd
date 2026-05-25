class_name KnockdownState
extends State

# Fase de QUEDA: continua caindo (gravidade), preserva velocity de entrada.
# Quando toca o chão, vira GroundedState. Carrega o knockback restante do estado
# anterior (AirHurt ou Thrown) — não zera no enter pra a queda parecer natural.

@export var anim_fall: String = "knockdown_fall"
@export var air_friction: float = 100.0 # mata velocity_x devagar enquanto cai

func _ready() -> void:
	type_dim = "knockdown"
	stance_dim = "any"
	cancel_tier_dim = 5

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	# Velocity preservada do estado anterior — se vier hit_data, sobrescreve.
	var hit_data: Dictionary = payload.get("hit_data", {})
	if hit_data.has("knockback_x") and fighter:
		fighter.velocity.x = float(hit_data.get("knockback_x", 0.0))
	if hit_data.has("knockback_y") and fighter:
		fighter.velocity.y = float(hit_data.get("knockback_y", 0.0))

	if anim:
		anim.play(anim_fall)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Gravidade até tocar o chão.
	if movement:
		movement.apply_gravity(delta)
	# Air friction sutil pra knockback não durar pra sempre.
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, air_friction * delta)

	# Tocou o chão → vira GroundedState (passa o tempo já no chão).
	if fighter.is_on_floor():
		fighter.velocity = Vector2.ZERO
		transition_requested.emit("GroundedState", {})

func get_tags() -> Array[String]:
	return ["Knockdown", "Falling"]
