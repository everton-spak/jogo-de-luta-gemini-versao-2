class_name ProjectileAttackState
extends State

# Base para ataques que disparam projétil (Hadouken stand/crouch/air).
# Spawna o projétil quando a animação atinge spawn_frame.
# Suporta recovery_time opcional após o fim da animação.

@export_group("Projétil")
@export var projectile_scene: PackedScene
@export var spawn_frame: int = 5
@export var spawn_marker_name: String = "ProjectileSpawn"
# Marker alternativo (ex: "ProjectileSpawnAir") tentado antes do principal — útil para Air
@export var spawn_marker_alt: String = ""
@export var spawn_offset_fallback: Vector2 = Vector2(50.0, -80.0)

@export var proj_speed: float = 400.0
@export var proj_speed_y: float = 0.0
@export var proj_damage: int = 8
@export var proj_hitstun: float = 0.30
@export var proj_knockback: Vector2 = Vector2(200, -50)

@export_group("Recovery")
# Tempo extra após o fim da animação antes de transicionar (0 = imediato)
@export var recovery_time: float = 0.0

@export_group("Charge (segura o botão pra pausar a anim)")
# Frame da animação onde pausar enquanto o botão estiver segurado.
# -1 = sem fase de charge (Hadouken vai direto até o fim).
@export var charge_pause_frame: int = -1

var _spawned: bool = false
var _in_recovery: bool = false
var _recovery_timer: float = 0.0
var _is_charging: bool = false
# Multiplier capturado no momento da soltura do botão (1.0 = normal, >1.0 = carregado).
var _charge_multiplier: float = 1.0

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_spawned = false
	_in_recovery = false
	_recovery_timer = 0.0
	_is_charging = false
	_charge_multiplier = 1.0
	# Stand/crouch zeram momentum; air mantém
	if fighter and stance_dim != "air":
		fighter.velocity = Vector2.ZERO
	if anim and animation_name != "":
		anim.play(animation_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	var charging_btn := "punch_light" if strength_dim == "light" else "punch_heavy"

	# Macro-cancel: durante o Hadouken (carregando ou não), se o jogador
	# continua segurando o botão e aperta o complemento, cancela em
	# hybrid_dash (light) ou super_throw (heavy).
	if special:
		var result := special.check_macro(charging_btn)
		if not result.is_empty():
			# Limpa o complemento (e o próprio charging_btn) do buffer pra NormalMoves
			# não disparar um golpe normal logo depois.
			if input_buffer and input_buffer.history:
				input_buffer.history.consume_all_action(result.complement)
				input_buffer.history.consume_all_action(charging_btn)
			match result.macro:
				"hybrid_dash":
					transition_requested.emit("HybridDashState", {})
					return
				"special_throw":
					# Super throw só existe na variante de perto. De longe (ou sem
					# inimigo detectado pelo proximity) cancela direto pra recovery.
					var is_near: bool = proximity != null and proximity.is_target_near
					if is_near:
						transition_requested.emit("SuperThrowState", {})
					else:
						transition_requested.emit(_resolve_recovery_state(), {})
					return

	# Fase de carga: enquanto botão segurado, pausa a animação no charge_pause_frame.
	# Solta o botão → captura o multiplier (tier de carga) e resume.
	if charge_pause_frame >= 0 and anim:
		var is_held: bool = input != null and input.is_action_pressed(charging_btn)
		if not _is_charging:
			if anim.get_current_frame() >= charge_pause_frame and is_held:
				_is_charging = true
				anim.pause()
				return
		else:
			if is_held:
				# Pulso visual a cada 6 frames (~100ms a 60fps) com cor por tier.
				if vfx and special and state_frames % 6 == 0:
					var tier_status: String = special.classify_charge(charging_btn).get("status", "normal")
					vfx.play_charge_pulse(tier_status)
				return # mantém pausado
			# Botão soltou: lê o tier de carga ANTES do ChargeTracker zerar o tempo.
			# (ChargeTracker._physics_process roda depois deste, então o tempo ainda está cheio.)
			if special:
				var classification = special.classify_charge(charging_btn)
				_charge_multiplier = classification.get("multiplier", 1.0)
			_is_charging = false
			anim.resume()

	if _in_recovery:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0:
			transition_requested.emit(_resolve_recovery_state(), {})
		return

	if not _spawned and anim and anim.get_current_frame() >= spawn_frame:
		_spawned = true
		_spawn_projectile()

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		if recovery_time > 0.0:
			_in_recovery = true
			_recovery_timer = recovery_time
		else:
			transition_requested.emit(_resolve_recovery_state(), {})

func _resolve_recovery_state() -> String:
	if recovery_state != "":
		return recovery_state
	# Air → FallState; outros → IdleState
	return "FallState" if stance_dim == "air" else "IdleState"

func _spawn_projectile() -> void:
	if not projectile_scene or not fighter: return
	var proj = projectile_scene.instantiate()
	fighter.get_parent().add_child(proj)
	var f_dir = facing.current_facing if facing else 1.0

	var marker: Node = null
	if spawn_marker_alt != "":
		marker = fighter.get_node_or_null(spawn_marker_alt)
	if not marker:
		marker = fighter.get_node_or_null(spawn_marker_name)

	if marker:
		proj.global_position = fighter.global_position + Vector2(marker.position.x * f_dir, marker.position.y)
	else:
		proj.global_position = fighter.global_position + Vector2(spawn_offset_fallback.x * f_dir, spawn_offset_fallback.y)

	# Escala visual + hitbox cresce com o tier de carga (1.0 normal, 1.5 strong, 2.5 super).
	proj.scale = Vector2(_charge_multiplier, _charge_multiplier)

	if proj.has_method("launch"):
		var scaled_damage := int(proj_damage * _charge_multiplier)
		proj.launch(f_dir, proj_speed, fighter, scaled_damage, proj_hitstun, proj_knockback, proj_speed_y)
