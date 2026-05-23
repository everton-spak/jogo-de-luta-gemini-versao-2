class_name HurtState
extends State

# Acertado no chão. Aplica knockback, toca anim por attack_level, conta hitstun,
# e ao fim transiciona pra Idle (ou KO se health zerou durante o hit).

@export_group("Animações por nível")
@export var anim_high: String = "hit_high"
@export var anim_mid: String = "hit_mid"
@export var anim_low: String = "hit_low"

@export_group("Física")
@export var friction: float = 1500.0 # desaceleração horizontal do knockback

# Capturados no enter() do payload.
var _hitstun: float = 0.0
var _attack_level: String = "mid"

func _ready() -> void:
	type_dim = "hurt"
	stance_dim = "ground"
	react_dim = "any" # default — não interfere no scoring interno por nada além de "react"
	cancel_tier_dim = 5
	recovery_state = "IdleState"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})
	_hitstun = float(hit_data.get("hitstun", 0.3))
	_attack_level = str(hit_data.get("attack_level", "mid"))

	# Knockback do payload (já vem com sign correto pelo HurtboxComponent).
	if fighter:
		fighter.velocity.x = float(hit_data.get("knockback_x", 0.0))
		fighter.velocity.y = float(hit_data.get("knockback_y", 0.0))

	# Hit spark — VfxComponent já tem spawn_hit_spark; passa is_heavy=true pra
	# golpes pesados (escala+cor diferente).
	if vfx and fighter:
		var is_heavy: bool = (float(hit_data.get("damage", 0)) >= 15)
		vfx.spawn_hit_spark(fighter.global_position + Vector2(0, -60), is_heavy)

	# Anim por nível do golpe (high/mid/low).
	if anim:
		match _attack_level:
			"high": anim.play(anim_high)
			"low": anim.play(anim_low)
			_: anim.play(anim_mid)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if fighter:
		# Friction horizontal pra desacelerar o knockback gradualmente.
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, friction * delta)
		# Gravidade se foi parar no ar pelo knockback vertical.
		if not fighter.is_on_floor() and movement:
			movement.apply_gravity(delta)

	_hitstun -= delta
	if _hitstun <= 0.0:
		# Health zerou durante o hit? Vai pra KO em vez de Idle.
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func get_tags() -> Array[String]:
	return ["Hurt"]
