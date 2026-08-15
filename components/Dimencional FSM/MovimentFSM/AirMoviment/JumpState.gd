class_name JumpState
extends State

enum JumpType {
	NORMAL,
	SUPER,
	SHORT_HOP,
	HYPER_HOP
}

@export_group("Física KOF - Pulo Normal & Super")
@export var normal_jump_force: float = 1150.0
@export var normal_speed_x: float = 380.0
@export var super_speed_x: float = 560.0
@export var normal_gravity: float = 2900.0

@export_group("Física KOF - Hops (Pulos Curtos)")
@export var hop_jump_force: float = 820.0
@export var hop_speed_x: float = 360.0
@export var hyper_hop_speed_x: float = 550.0
@export var hop_gravity: float = 3200.0

@export_group("Pre-Jump & Transição")
@export var pre_jump_frames: int = 4
@export var fall_state: String = "FallState"

var _locked_dir: float = 0.0
var _current_jump_type: JumpType = JumpType.NORMAL
var _super_buffered: bool = false
var _up_held: bool = true
var _in_pre_jump: bool = true
var _current_gravity: float = 2900.0
var _current_horizontal_speed: float = 380.0
var _ghost_spawn_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"
	type_dim = "movement"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_locked_dir = query_dict.get("dir_x", 0.0)
	_super_buffered = query_dict.get("super_buffered", false)
	_up_held = true
	_in_pre_jump = true
	_ghost_spawn_timer = 0.0
	
	if fighter:
		# Durante o pre-jump (squat de 3-4 frames no chão), aguarda a decolagem
		fighter.velocity.x = 0.0
		fighter.velocity.y = 0.0
		if posture: posture.apply("stand")
		
	if anim:
		# Durante o startup, exibe idle ou primeiro frame de agachamento/pulo
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return
	
	# Verifica se o direcional para cima ainda está sendo segurado durante o pre-jump
	if input and _in_pre_jump:
		var dir = input.get_movement_direction()
		if dir.y >= -0.3:
			_up_held = false
			
	# Fase 1: Pre-Jump (Startup de 4 frames no chão)
	if _in_pre_jump:
		if state_frames >= pre_jump_frames:
			_in_pre_jump = false
			_execute_takeoff()
		return
		
	# Fase 2: Voo Aéreo Ativo (Física KOF)
	fighter.velocity.y += _current_gravity * delta
	fighter.velocity.x = _current_horizontal_speed * _locked_dir
	
	# Efeito de Afterimage/Ghost durante Super Jump ou Hyper Hop
	if _current_jump_type == JumpType.SUPER or _current_jump_type == JumpType.HYPER_HOP:
		_ghost_spawn_timer += delta
		if _ghost_spawn_timer >= 0.06:
			_ghost_spawn_timer = 0.0
			if vfx: vfx.spawn_ghost("cancel", 0.18)
			
	# Transição: Ápice do salto. Começou a cair? Muda para FallState
	if fighter.velocity.y > 0:
		var fall_payload = {
			"query": {
				"dir_x": _locked_dir,
				"horizontal_speed": _current_horizontal_speed,
				"gravity": _current_gravity,
				"jump_type": _current_jump_type
			}
		}
		transition_requested.emit(fall_state, fall_payload)

func _execute_takeoff() -> void:
	# Determina qual dos 4 pulos KOF foi disparado:
	if _up_held:
		if _super_buffered:
			_current_jump_type = JumpType.SUPER
			_current_horizontal_speed = super_speed_x
			_current_gravity = normal_gravity
			fighter.velocity.y = -normal_jump_force
		else:
			_current_jump_type = JumpType.NORMAL
			_current_horizontal_speed = normal_speed_x
			_current_gravity = normal_gravity
			fighter.velocity.y = -normal_jump_force
	else:
		if _super_buffered:
			_current_jump_type = JumpType.HYPER_HOP
			_current_horizontal_speed = hyper_hop_speed_x
			_current_gravity = hop_gravity
			fighter.velocity.y = -hop_jump_force
		else:
			_current_jump_type = JumpType.SHORT_HOP
			_current_horizontal_speed = hop_speed_x
			_current_gravity = hop_gravity
			fighter.velocity.y = -hop_jump_force
			
	fighter.velocity.x = _current_horizontal_speed * _locked_dir
	if posture: posture.apply("air")
	
	# Efeito visual para saltos Super / Hyper Hop
	if _current_jump_type == JumpType.SUPER or _current_jump_type == JumpType.HYPER_HOP:
		if vfx:
			vfx.play_flash("cancel", 0.08)
			vfx.spawn_ghost("cancel", 0.22)
			
	if anim:
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func get_tags() -> Array[String]:
	return ["Air", "Movement"]
