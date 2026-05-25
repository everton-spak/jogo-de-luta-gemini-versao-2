class_name DodgeState
extends State

# Esquiva: dispara via LP+LK simultâneos (ver DodgeMove).
# - Com direção (dir_x ≠ 0): avança na direção, com cap de distância OU parede.
# - Sem direção (dir_x = 0): esquiva parado, só i-frames.
# Em AMBOS os casos a state dura `duration_sec` antes de voltar pro Idle.

@export var dodge_speed: float = 400.0
# Cap de distância (só pra dodge direcional) — quando atingido, para o movimento
# mas a state CONTINUA até `duration_sec` (tempo de recovery vulnerável).
@export var dodge_distance: float = 120.0
# Duração TOTAL do estado em segundos (i-frames + movimento + recovery).
@export var duration_sec: float = 0.6
# Frames de invencibilidade desde o início do estado. Após isso, o resto é vulnerável.
@export var invincible_frames: int = 18
# JANELA DE SNAP: se o dodge começou parado (dir_x=0) mas a direção for apertada
# nos primeiros `dir_snap_frames`, comita a direção mid-dodge. Resolve o caso de
# "apertou tudo junto" onde a direção chega 1 frame depois dos botões.
@export var dir_snap_frames: int = 5

var _start_x: float = 0.0
var _dir: float = 0.0
var _movement_done: bool = false # true quando bateu distance ou parede

func _ready() -> void:
	type_dim = "dodge"
	stance_dim = "ground"
	direction_dim = "any"
	recovery_state = "IdleState"
	cancel_tier_dim = 0

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query: Dictionary = payload.get("query", {})
	_dir = float(query.get("dir_x", 0.0))
	_movement_done = (abs(_dir) < 0.1) # sem direção = "movimento" já completo (parado)
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

	# SNAP de direção: se começou parado mas direção foi pressionada nos primeiros
	# `dir_snap_frames`, comita pra direção (resolve "tudo junto com lag de 1 frame").
	if _movement_done and abs(_dir) < 0.1 and state_frames <= dir_snap_frames:
		if input:
			var live_x: float = sign(input.get_movement_direction().x)
			if live_x != 0.0:
				_dir = live_x
				_start_x = fighter.global_position.x
				fighter.velocity = Vector2(dodge_speed * _dir, 0.0)
				_movement_done = false

	# Fase de movimento (só pra dodge direcional): para ao bater no cap ou parede.
	if not _movement_done:
		var traveled: float = abs(fighter.global_position.x - _start_x)
		if traveled >= dodge_distance or fighter.is_on_wall():
			fighter.velocity.x = 0.0
			_movement_done = true

	# Duração FIXA — termina quando passou o tempo total, independente de ter chegado
	# à distância. Isso dá uma janela de recovery vulnerável após os i-frames.
	if state_time_sec >= duration_sec:
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	var tags: Array[String] = ["Ground", "Movement"]
	# I-frames só na janela inicial; depois fica vulnerável até a state terminar.
	if state_frames <= invincible_frames:
		tags.append("Invincible")
	return tags
