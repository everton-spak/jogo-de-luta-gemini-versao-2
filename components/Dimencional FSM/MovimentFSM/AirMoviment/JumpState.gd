class_name JumpState
extends State

# ==============================================================================
# FÍSICA AUTÊNTICA DE PULOS THE KING OF FIGHTERS (KOF)
# 4 Tipos de Pulo: Short Hop, Hyper Hop, Normal Jump, Super Jump
# Regra dos 4 Frames de Pre-Jump Squat, Inércia Horizontal Travada e Gravidade Ágil
# ==============================================================================

enum KOFJumpType {
	NORMAL_JUMP,
	SUPER_JUMP,
	SHORT_HOP,
	HYPER_HOP
}

@export_group("Pre-Jump (Startup)")
@export var pre_jump_frames: int = 4

@export_group("Pulo Cheio & Super Jump (Alto)")
@export var normal_jump_force: float = 1500.0
@export var normal_speed_x: float = 420.0
@export var super_speed_x: float = 650.0
@export var normal_gravity: float = 2900.0

@export_group("Hops & Hyper Hops (Curto)")
@export var hop_jump_force: float = 1050.0
@export var hop_speed_x: float = 360.0
@export var hyper_hop_speed_x: float = 600.0
@export var hop_gravity: float = 3600.0

@export_group("Transições")
@export var fall_state: String = "FallState"

var _locked_dir: float = 0.0
var _super_buffered: bool = false
var _up_held: bool = true
var _in_pre_jump: bool = true
var _jump_type: KOFJumpType = KOFJumpType.NORMAL_JUMP

var _current_gravity: float = 2900.0
var _current_speed_x: float = 420.0
var _ghost_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"
	type_dim = "movement"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_locked_dir = float(query_dict.get("dir_x", 0.0))
	_super_buffered = bool(query_dict.get("super_buffered", false))
	_up_held = true
	_in_pre_jump = true
	_ghost_timer = 0.0
	
	if fighter:
		# Durante o pre-jump (squat de 4 frames), o lutador prepara o salto no solo
		fighter.velocity = Vector2.ZERO
		if posture: posture.apply("stand")
		
	if anim:
		# Exibe início do salto / agachamento preparatório
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return
	
	# Checa se o direcional continua segurado ou foi solto rapidamente (Regra KOF dos 4 frames)
	if _in_pre_jump and input:
		var dir = input.get_movement_direction()
		if dir.y >= -0.3:
			_up_held = false
			
	# Fase 1: Pre-Jump Squat no solo (Startup exato de KOF)
	if _in_pre_jump:
		if state_frames >= pre_jump_frames:
			_in_pre_jump = false
			_execute_takeoff()
		return
		
	# Fase 2: Voo Aéreo (Física KOF: inércia horizontal travada + gravidade ágil)
	fighter.velocity.y += _current_gravity * delta
	fighter.velocity.x = _current_speed_x * _locked_dir
	
	# Efeito de Afterimage (Ghost) contínuo em Super Jump e Hyper Hop
	if _jump_type == KOFJumpType.SUPER_JUMP or _jump_type == KOFJumpType.HYPER_HOP:
		_ghost_timer += delta
		if _ghost_timer >= 0.06:
			_ghost_timer = 0.0
			if vfx: vfx.spawn_ghost("cancel", 0.16)
			
	# Transição: Ao atingir o ápice (começou a cair), transiciona para o FallState
	if fighter.velocity.y > 0.0:
		var fall_payload = {
			"query": {
				"dir_x": _locked_dir,
				"horizontal_speed": _current_speed_x,
				"gravity": _current_gravity,
				"is_super": (_jump_type == KOFJumpType.SUPER_JUMP or _jump_type == KOFJumpType.HYPER_HOP)
			}
		}
		transition_requested.emit(fall_state, fall_payload)

func _execute_takeoff() -> void:
	# Determina com precisão qual dos 4 pulos KOF foi disparado:
	if not _up_held:
		# Soltou a tecla antes do 4º frame -> HOP (Pulo Curto)
		if _super_buffered:
			_jump_type = KOFJumpType.HYPER_HOP
			_current_speed_x = hyper_hop_speed_x
			_current_gravity = hop_gravity
			fighter.velocity.y = -hop_jump_force
		else:
			_jump_type = KOFJumpType.SHORT_HOP
			_current_speed_x = hop_speed_x
			_current_gravity = hop_gravity
			fighter.velocity.y = -hop_jump_force
	else:
		# Manteve a tecla segurada no 4º frame -> FULL JUMP (Pulo Alto)
		if _super_buffered:
			_jump_type = KOFJumpType.SUPER_JUMP
			_current_speed_x = super_speed_x
			_current_gravity = normal_gravity
			fighter.velocity.y = -normal_jump_force
		else:
			_jump_type = KOFJumpType.NORMAL_JUMP
			_current_speed_x = normal_speed_x
			_current_gravity = normal_gravity
			fighter.velocity.y = -normal_jump_force
			
	fighter.velocity.x = _current_speed_x * _locked_dir
	if posture: posture.apply("air")
	
	# Flash de decolagem em Super Jump / Hyper Hop
	if _jump_type == KOFJumpType.SUPER_JUMP or _jump_type == KOFJumpType.HYPER_HOP:
		if vfx:
			vfx.play_flash("cancel", 0.08)
			vfx.spawn_ghost("cancel", 0.2)
			
	if anim:
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func get_tags() -> Array[String]:
	if _in_pre_jump:
		# Tag PreJump evita que o InputBuffer reinicie o JumpState durante o startup
		return ["PreJump", "Air", "Movement"]
	return ["Air", "Movement", "Airborne"]
