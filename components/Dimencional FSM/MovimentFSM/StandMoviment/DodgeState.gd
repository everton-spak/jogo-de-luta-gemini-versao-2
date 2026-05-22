class_name DodgeState
extends State

# Esquiva/cambalhota: rola na direção do dir_x (geralmente pra trás) com janela de
# i-frames (tag "Invincible" lida pelo HurtBoxComponent). Volta pro Idle ao fim.

@export var dodge_speed: float = 400.0
@export var dodge_distance: float = 120.0
# Frames de invencibilidade desde o início. Após isso, o resto do roll é vulnerável (recovery).
@export var invincible_frames: int = 18

var _start_x: float = 0.0
var _dir: float = -1.0 # default: pra trás

func _ready() -> void:
	type_dim = "dodge"
	stance_dim = "ground"
	direction_dim = "any"
	recovery_state = "IdleState"
	cancel_tier_dim = 0

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query: Dictionary = payload.get("query", {})
	_dir = query.get("dir_x", -1.0)
	if fighter:
		_start_x = fighter.global_position.x
		fighter.velocity = Vector2(dodge_speed * _dir, 0.0)
	if anim: anim.play("dodge")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return

	# Mantém colado no chão (sem gravidade durante o roll).
	if fighter.is_on_floor():
		fighter.velocity.y = 0.0

	var traveled: float = abs(fighter.global_position.x - _start_x)
	if traveled >= dodge_distance or fighter.is_on_wall():
		fighter.velocity.x = 0.0
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	var tags: Array[String] = ["Ground", "Movement"]
	# I-frames só na janela inicial do roll.
	if state_frames <= invincible_frames:
		tags.append("Invincible")
	return tags
