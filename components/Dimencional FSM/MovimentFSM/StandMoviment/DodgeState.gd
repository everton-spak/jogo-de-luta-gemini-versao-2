class_name DodgeState
extends State

# Esquiva / Emergency Roll (Padrão KOF):
# Dispara via LP+LK simultâneos (ver DodgeMove).
# - Neutro ou Frente + LP+LK: Forward Roll (Roll para frente)
# - Trás + LP+LK: Back Roll (Roll para trás)
# Frame Data KOF: ~30 frames total, 21 frames de invencibilidade (i-frames), ~9 frames de recovery punível.

@export_group("Configuração do Roll KOF")
@export var dodge_speed: float = 540.0
@export var dodge_distance: float = 270.0
@export var duration_sec: float = 0.50 # ~30 frames a 60fps
@export var invincible_frames: int = 21 # Frames 1 a 21 com i-frames
@export var dir_snap_frames: int = 5

var _start_x: float = 0.0
var _dir: float = 0.0
var _movement_done: bool = false

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
	
	# No KOF: Se neutro, faz Forward Roll na direção do oponente
	if abs(_dir) < 0.1:
		var facing_comp = get_component("FacingComponent")
		var f_dir = facing_comp.current_facing if facing_comp else 1.0
		_dir = f_dir
		
	_movement_done = false
	if fighter:
		_start_x = fighter.global_position.x
		fighter.velocity = Vector2(dodge_speed * _dir, 0.0)
		if posture: posture.apply("stand")
		
	if anim:
		if _dir < 0:
			anim.play_reverse("dodge")
		else:
			anim.play("dodge")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return

	# Mantém colado no chão (sem gravidade durante o roll)
	if fighter.is_on_floor():
		fighter.velocity.y = 0.0

	# Snap de direção rápida nos primeiros frames
	if state_frames <= dir_snap_frames and input:
		var live_x: float = sign(input.get_movement_direction().x)
		if live_x != 0.0 and live_x != _dir:
			_dir = live_x
			_start_x = fighter.global_position.x
			fighter.velocity = Vector2(dodge_speed * _dir, 0.0)
			_movement_done = false

	# Fase de deslocamento: para ao atingir a distância ou bater na parede
	if not _movement_done:
		var traveled: float = abs(fighter.global_position.x - _start_x)
		if traveled >= dodge_distance or fighter.is_on_wall():
			fighter.velocity.x = 0.0
			_movement_done = true

	# Fim do Roll ao atingir a duração total (deixando janela de recovery vulnerável)
	if state_time_sec >= duration_sec:
		transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	var tags: Array[String] = ["Ground", "Movement"]
	# Invencibilidade nos frames iniciais (1-21); vulnerável no recovery (22-30)
	if state_frames <= invincible_frames:
		tags.append("Invincible")
	return tags
