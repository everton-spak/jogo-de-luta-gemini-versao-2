class_name BlockState
extends State

# Defendeu o golpe. Aplica chip damage (já calculado pelo HurtboxComponent),
# pushback pequeno, toca anim de block_stand ou block_crouch baseado no stance
# que veio no payload, e ao fim do blockstun volta pro IdleState/CrouchState.

@export_group("Animações por postura")
@export var anim_stand: String = "block_stand"
@export var anim_crouch: String = "block_crouch"

@export_group("Física")
@export var pushback_scale: float = 0.3 # multiplica o knockback_x pra pushback mais sutil
@export var friction: float = 2000.0

var _blockstun: float = 0.0
var _block_stance: String = "ground" # "ground" ou "crouch" — vem no payload.query.stance

func _ready() -> void:
	type_dim = "block"
	stance_dim = "any" # roteamento bate via type_dim; stance vem como dado no payload
	react_dim = "any"
	cancel_tier_dim = 5

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})
	var query: Dictionary = payload.get("query", {})

	_blockstun = float(hit_data.get("hitstun", 0.2))
	_block_stance = str(query.get("stance", "ground"))

	# Pushback escalado (block empurra menos que hit).
	if fighter:
		fighter.velocity.x = float(hit_data.get("knockback_x", 0.0)) * pushback_scale
		fighter.velocity.y = 0.0 # block no chão não levanta

	# Anim por stance — stand vs crouch.
	if anim:
		if _block_stance == "crouch":
			anim.play(anim_crouch)
		else:
			anim.play(anim_stand)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if fighter:
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, friction * delta)
		if not fighter.is_on_floor() and movement:
			movement.apply_gravity(delta)

	_blockstun -= delta
	if _blockstun <= 0.0:
		# Health pode ter zerado por chip damage acumulado — verifica KO.
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		else:
			# Volta pra postura correta.
			var next := "CrouchState" if _block_stance == "crouch" else "IdleState"
			transition_requested.emit(next, {})

func get_tags() -> Array[String]:
	return ["Blocking"]
