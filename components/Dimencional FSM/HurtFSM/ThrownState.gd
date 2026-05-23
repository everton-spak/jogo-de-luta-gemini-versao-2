class_name ThrownState
extends State

# Sendo arremessado por throw alheio. Diferente de HurtState, NÃO usa hitstun
# nem knockback do payload — a coreografia (trajetória/velocidade/duração) é
# scriptada e fixa neste state. O atacante coordenou que vamos passar por aqui.
#
# Throws "puros" (sem dano variável) usam duração fixa em frames; ao fim,
# transiciona pra IdleState (futuro: KnockdownState pra wakeup options).

@export_group("Animação")
@export var anim_thrown: String = "thrown"

@export_group("Coreografia")
@export var duration_frames: int = 30
# Trajetória simples: arco pra trás+cima do facing do atacante (vem no payload).
@export var launch_velocity_x: float = -200.0
@export var launch_velocity_y: float = -500.0
@export var gravity_scale: float = 1.0

# Direção pra onde fui arremessado (calculada a partir do atacante).
var _away_dir: float = 1.0

func _ready() -> void:
	type_dim = "grabbed" # bate com o que ThrowHurtboxComponent já manda
	stance_dim = "any"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})

	# Direção: pra LONGE do atacante.
	var attacker = hit_data.get("attacker", null)
	if attacker and fighter:
		_away_dir = sign(fighter.global_position.x - attacker.global_position.x)
		if _away_dir == 0.0:
			_away_dir = 1.0
	else:
		_away_dir = 1.0

	if fighter:
		fighter.velocity = Vector2(launch_velocity_x * _away_dir, launch_velocity_y)

	if anim:
		anim.play(anim_thrown)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Gravidade durante o voo do throw.
	if movement:
		movement.apply_gravity(delta, gravity_scale)

	# Duração fixa em frames — independente de hitstun.
	if state_frames >= duration_frames:
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func get_tags() -> Array[String]:
	return ["Thrown"]
