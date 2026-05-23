class_name ThrowTechState
extends State

# Escape de throw — defensor apertou LP+LK dentro da janela curta após o grab.
# Pushback simétrico (atacante recua via lógica do atacante; aqui só o defensor).
# Estado breve, retorna pra IdleState.

@export_group("Animação")
@export var anim_tech: String = "throw_tech"

@export_group("Tempo & física")
@export var duration_frames: int = 20
@export var pushback_velocity: float = 250.0 # pra trás do atacante
@export var friction: float = 1500.0

var _away_dir: float = 1.0

func _ready() -> void:
	type_dim = "throw_tech"
	stance_dim = "any"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})

	var attacker = hit_data.get("attacker", null)
	if attacker and fighter:
		_away_dir = sign(fighter.global_position.x - attacker.global_position.x)
		if _away_dir == 0.0:
			_away_dir = 1.0
	else:
		_away_dir = 1.0

	if fighter:
		fighter.velocity = Vector2(pushback_velocity * _away_dir, 0.0)

	if anim:
		anim.play(anim_tech)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, friction * delta)
	if not fighter.is_on_floor() and movement:
		movement.apply_gravity(delta)

	if state_frames >= duration_frames:
		transition_requested.emit(_resolve_recovery_state(), {})

func get_tags() -> Array[String]:
	return ["TechRecovery"]
