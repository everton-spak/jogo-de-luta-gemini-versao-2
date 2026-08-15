class_name JumpState
extends State

@export_group("Física de Pulo KOF")
@export var normal_jump_force: float = 1150.0
@export var hop_jump_force: float = 850.0
@export var normal_speed_x: float = 400.0
@export var super_speed_x: float = 580.0
@export var normal_gravity: float = 2900.0
@export var hop_gravity: float = 3300.0
@export var fall_state: String = "FallState"

var _locked_dir: float = 0.0
var _is_super: bool = false
var _is_hop: bool = false
var _current_gravity: float = 2900.0
var _current_speed_x: float = 400.0
var _ghost_timer: float = 0.0

func _ready() -> void:
	stance_dim = "air"
	strength_dim = "none"
	type_dim = "movement"

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var query_dict = payload.get("query", {})
	_locked_dir = float(query_dict.get("dir_x", 0.0))
	_is_super = bool(query_dict.get("super_buffered", false))
	_is_hop = false
	_ghost_timer = 0.0
	
	_current_speed_x = super_speed_x if _is_super else normal_speed_x
	_current_gravity = normal_gravity
	
	if fighter:
		# Decolagem imediata
		fighter.velocity.y = -normal_jump_force
		fighter.velocity.x = _current_speed_x * _locked_dir
		if posture: posture.apply("air")
		
	# Efeito visual de Super Jump
	if _is_super and vfx:
		vfx.play_flash("cancel", 0.08)
		vfx.spawn_ghost("cancel", 0.2)
		
	if anim:
		if _locked_dir > 0:
			anim.play("jump_forward")
		elif _locked_dir < 0:
			anim.play_reverse("jump_forward")
		else:
			anim.play("jump_neutral")

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter: return
	
	# Detecção dinâmica de Short Hop: Se o jogador soltar o direcional nos primeiros 6 frames de subida
	if not _is_hop and state_frames <= 6 and input:
		var current_input = input.get_movement_direction()
		if current_input.y >= -0.3:
			_is_hop = true
			_current_gravity = hop_gravity
			if fighter.velocity.y < -hop_jump_force:
				fighter.velocity.y = -hop_jump_force
				
	# Aplica gravidade e velocidade horizontal contínua
	fighter.velocity.y += _current_gravity * delta
	fighter.velocity.x = _current_speed_x * _locked_dir
	
	# Rastro de Ghost em Super Jump / Hyper Hop
	if _is_super:
		_ghost_timer += delta
		if _ghost_timer >= 0.06:
			_ghost_timer = 0.0
			if vfx: vfx.spawn_ghost("cancel", 0.16)
			
	# Ápice atingido: transiciona suavemente para o FallState
	if fighter.velocity.y > 0:
		var fall_payload = {
			"query": {
				"dir_x": _locked_dir,
				"horizontal_speed": _current_speed_x,
				"gravity": _current_gravity,
				"is_super": _is_super
			}
		}
		transition_requested.emit(fall_state, fall_payload)

func get_tags() -> Array[String]:
	return ["Air", "Movement", "Airborne"]
