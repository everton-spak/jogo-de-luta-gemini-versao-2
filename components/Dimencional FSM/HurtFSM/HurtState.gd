class_name HurtState
extends State

# Acertado no chão. Aplica knockback com curva exponencial, toca anim por attack_level,
# conta hitstun, e ao fim transiciona pra Idle (ou KO se health zerou durante o hit).

@export_group("Animações por nível")
@export var anim_high: String = "hit_high"
@export var anim_mid: String = "hit_mid"
@export var anim_low: String = "hit_low"

@export_group("Curvas de Física")
@export var knockback_curve: Curve

var _hitstun: float = 0.0
var _total_hitstun: float = 0.3
var _initial_knockback_x: float = 0.0
var _attack_level: String = "mid"

func _ready() -> void:
	type_dim = "hurt"
	stance_dim = "ground"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "IdleState"
	if not knockback_curve:
		knockback_curve = PhysicsCurves.create_knockback_decay_curve()

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})
	_hitstun = float(hit_data.get("hitstun", 0.3))
	_total_hitstun = max(0.01, _hitstun)
	_attack_level = str(hit_data.get("attack_level", "mid"))

	_initial_knockback_x = float(hit_data.get("knockback_x", 0.0))
	var initial_knockback_y = float(hit_data.get("knockback_y", 0.0))

	if fighter:
		fighter.velocity.x = _initial_knockback_x
		fighter.velocity.y = initial_knockback_y

	# Hit spark com feedback proporcional
	if vfx and fighter:
		var is_heavy: bool = (float(hit_data.get("damage", 0)) >= 15)
		vfx.spawn_hit_spark(fighter.global_position + Vector2(0, -60), is_heavy)

	# Anim por nível do golpe (high/mid/low)
	if anim:
		match _attack_level:
			"high": anim.play(anim_high)
			"low": anim.play(anim_low)
			_: anim.play(anim_mid)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if fighter:
		# Desaceleração de knockback modelada pela curva (impacto inicial violento + parada suave)
		var progress = clamp(state_time_sec / _total_hitstun, 0.0, 1.0)
		var decay = knockback_curve.sample_baked(progress) if knockback_curve else (1.0 - progress)
		fighter.velocity.x = _initial_knockback_x * decay
		
		# Gravidade se foi lançado levemente para o ar
		if not fighter.is_on_floor() and movement:
			movement.apply_gravity(delta)

	_hitstun -= delta
	if _hitstun <= 0.0:
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func get_tags() -> Array[String]:
	return ["Hurt"]
