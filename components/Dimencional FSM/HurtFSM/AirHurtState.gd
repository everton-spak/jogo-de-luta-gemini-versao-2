class_name AirHurtState
extends State

# Acertado no ar — vira juggle. Aplica launch (vertical + horizontal), gravidade
# reduzida pra dar tempo de combar no ar, e ao tocar o chão volta pra Idle
# (ou KO se health zerou; no futuro, KnockdownState pra wakeup options).

@export_group("Animação")
@export var anim_juggle: String = "juggle_spin"

@export_group("Física")
@export var juggle_gravity_multiplier: float = 0.6 # menor que gravidade normal pra prolongar o air time
@export var air_friction: float = 200.0
# Mínimo de hitstun a respeitar mesmo se ainda no ar — evita sair do juggle
# antes do tempo se o jogador atinge o chão muito rápido.
@export var min_air_frames: int = 6

func _ready() -> void:
	type_dim = "juggle"
	stance_dim = "air"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "FallState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})

	if fighter:
		fighter.velocity.x = float(hit_data.get("knockback_x", 0.0))
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

	# Gravidade reduzida pra prolongar o juggle.
	if movement:
		movement.apply_gravity(delta, juggle_gravity_multiplier)

	# Air friction horizontal — knockback vai morrendo aos poucos.
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, air_friction * delta)

	# Tocou o chão? Sai do juggle.
	if state_frames >= min_air_frames and fighter.is_on_floor():
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			# TODO Tier 3: trocar pra KnockdownState quando existir.
			transition_requested.emit("IdleState", {})

func get_tags() -> Array[String]:
	return ["Hurt", "Juggling"]
