class_name MatchManager
extends Node

signal phase_changed(new_phase: String)
signal round_started(round_number: int)
signal banner_requested(text: String, subtext: String, color: Color, duration: float)
signal timer_changed(seconds_left: int, training_mode: bool)
signal wins_changed(p1_wins: int, p2_wins: int)
signal training_mode_changed(enabled: bool)

enum Phase {
	INTRO,
	FIGHTING,
	ROUND_OVER,
	MATCH_OVER,
}

@export var fighter_p1: Fighter
@export var fighter_p2: Fighter
@export var round_time_sec: int = 99
@export var rounds_to_win: int = 2
@export var p1_spawn_pos: Vector2 = Vector2(550.0, 920.0)
@export var p2_spawn_pos: Vector2 = Vector2(1370.0, 920.0)

var phase: Phase = Phase.INTRO
var current_round: int = 1
var p1_wins: int = 0
var p2_wins: int = 0
var training_mode: bool = false

var _timer_accum: float = 99.0
var _last_displayed_sec: int = 99
var _sequence_token: int = 0
var _ko_pending: bool = false
var _p1_regen_cooldown: float = 0.0
var _p2_regen_cooldown: float = 0.0
var _p1_last_hp: int = 1000
var _p2_last_hp: int = 1000

func _ready() -> void:
	_resolve_fighters()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_connect_fighter_signals()
	start_new_match()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _resolve_fighters() -> void:
	var root := get_parent()
	if not root:
		return
	if not fighter_p1:
		fighter_p1 = root.get_node_or_null("Player1") as Fighter
	if not fighter_p2:
		fighter_p2 = root.get_node_or_null("Opponent") as Fighter
	if fighter_p1 and fighter_p2:
		if fighter_p1.target_fighter == null:
			fighter_p1.target_fighter = fighter_p2
		if fighter_p2.target_fighter == null:
			fighter_p2.target_fighter = fighter_p1

func _connect_fighter_signals() -> void:
	var h1 := _get_health(fighter_p1)
	if h1 and not h1.died.is_connected(_on_fighter_died):
		h1.died.connect(_on_fighter_died.bind(fighter_p1))
	var h2 := _get_health(fighter_p2)
	if h2 and not h2.died.is_connected(_on_fighter_died):
		h2.died.connect(_on_fighter_died.bind(fighter_p2))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key == KEY_R:
		start_new_match()
	elif (key == KEY_ENTER or key == KEY_KP_ENTER) and phase == Phase.MATCH_OVER:
		start_new_match()
	elif key == KEY_F1:
		set_training_mode(not training_mode)

func set_training_mode(enabled: bool) -> void:
	training_mode = enabled
	training_mode_changed.emit(training_mode)
	timer_changed.emit(_last_displayed_sec, training_mode)
	if training_mode:
		banner_requested.emit("MODO TREINO", "Vida Regenera | Tempo Infinito (F1 pra sair)", Color(0.35, 0.9, 1.0), 1.4)
		_heal_and_revive(fighter_p1)
		_heal_and_revive(fighter_p2)
		if phase == Phase.MATCH_OVER or phase == Phase.ROUND_OVER:
			_sequence_token += 1
			Engine.time_scale = 1.0
			phase = Phase.FIGHTING
			phase_changed.emit("FIGHTING")
	else:
		start_new_match()

func start_new_match() -> void:
	_sequence_token += 1
	_ko_pending = false
	Engine.time_scale = 1.0
	p1_wins = 0
	p2_wins = 0
	current_round = 1
	_reset_super_meter(fighter_p1)
	_reset_super_meter(fighter_p2)
	_begin_round()

func _begin_round() -> void:
	_sequence_token += 1
	var my_token := _sequence_token
	_ko_pending = false
	Engine.time_scale = 1.0

	_reset_fighters_for_round()

	_timer_accum = float(round_time_sec)
	_last_displayed_sec = round_time_sec
	phase = Phase.INTRO
	phase_changed.emit("INTRO")
	round_started.emit(current_round)
	wins_changed.emit(p1_wins, p2_wins)
	timer_changed.emit(_last_displayed_sec, training_mode)

	if training_mode:
		banner_requested.emit("MODO TREINO", "PRATIQUE LIVREMENTE", Color(0.35, 0.9, 1.0), 1.0)
		phase = Phase.FIGHTING
		phase_changed.emit("FIGHTING")
		return

	banner_requested.emit("ROUND %d" % current_round, "GET READY!", Color(1.0, 0.85, 0.25), 0.7)
	await get_tree().create_timer(0.7, true, false, true).timeout
	if not is_inside_tree() or _sequence_token != my_token:
		return

	banner_requested.emit("FIGHT!", "", Color(1.0, 0.35, 0.2), 0.55)
	phase = Phase.FIGHTING
	phase_changed.emit("FIGHTING")

func _process(delta: float) -> void:
	if phase != Phase.FIGHTING:
		return

	if training_mode:
		_tick_training_regen(delta)
		return

	_timer_accum = maxf(0.0, _timer_accum - delta)
	var sec: int = ceili(_timer_accum)
	if sec != _last_displayed_sec:
		_last_displayed_sec = sec
		timer_changed.emit(_last_displayed_sec, false)

	if _timer_accum <= 0.0:
		_on_time_over()

func _tick_training_regen(delta: float) -> void:
	_p1_regen_cooldown = _regen_single_fighter(fighter_p1, delta, _p1_regen_cooldown, true)
	_p2_regen_cooldown = _regen_single_fighter(fighter_p2, delta, _p2_regen_cooldown, false)

func _regen_single_fighter(f: Fighter, delta: float, cooldown: float, is_p1: bool) -> float:
	if not f or not is_instance_valid(f):
		return cooldown
	var hp_comp := _get_health(f)
	if not hp_comp:
		return cooldown

	var prev_hp: int = _p1_last_hp if is_p1 else _p2_last_hp
	if hp_comp.current_health < prev_hp:
		cooldown = 1.2
	if is_p1:
		_p1_last_hp = hp_comp.current_health
	else:
		_p2_last_hp = hp_comp.current_health

	if cooldown > 0.0:
		cooldown = maxf(0.0, cooldown - delta)
		return cooldown

	if hp_comp.current_health < hp_comp.max_health:
		var fsm = f.get("root_fsm")
		if fsm:
			var tags: Array[String] = fsm.get_tags()
			if "Hurt" in tags or "Juggling" in tags or "Knockdown" in tags or "Thrown" in tags or "KO" in tags:
				return cooldown
		hp_comp.heal(maxi(1, int(450.0 * delta)))
		if is_p1:
			_p1_last_hp = hp_comp.current_health
		else:
			_p2_last_hp = hp_comp.current_health
	return cooldown

func _on_fighter_died(_loser: Fighter) -> void:
	if training_mode:
		_schedule_training_revive(_loser)
		return
	if phase == Phase.ROUND_OVER or phase == Phase.MATCH_OVER or _ko_pending:
		return
	_ko_pending = true
	call_deferred("_resolve_ko_round_end")

func _schedule_training_revive(f: Fighter) -> void:
	var my_token := _sequence_token
	await get_tree().create_timer(1.2, true, false, true).timeout
	if not is_inside_tree() or _sequence_token != my_token or not training_mode:
		return
	_heal_and_revive(f)

func _heal_and_revive(f: Fighter) -> void:
	if not f or not is_instance_valid(f):
		return
	var hp := _get_health(f)
	if hp:
		hp.heal(hp.max_health)
	var stun_bar = f.get_component("StunBar")
	if stun_bar and stun_bar.has_method("subtract"):
		stun_bar.subtract(stun_bar.max_value)
	var guard_bar = f.get_component("GuardBar")
	if guard_bar and guard_bar.has_method("add"):
		guard_bar.add(guard_bar.max_value)
	var fsm = f.get("root_fsm")
	if fsm and "KO" in fsm.get_tags():
		fsm.change_state("IdleState", {})

func _resolve_ko_round_end() -> void:
	if not is_inside_tree() or phase == Phase.ROUND_OVER or phase == Phase.MATCH_OVER:
		_ko_pending = false
		return

	var h1 := _get_health(fighter_p1)
	var h2 := _get_health(fighter_p2)
	var dead1: bool = (h1 != null and h1.current_health <= 0)
	var dead2: bool = (h2 != null and h2.current_health <= 0)

	var title := "K.O.!"
	var sub := ""
	if dead1 and dead2:
		title = "DOUBLE K.O.!"
		sub = "EMPATE"
	elif dead2:
		p1_wins += 1
		sub = "PLAYER 1 VENCEU O ROUND"
	elif dead1:
		p2_wins += 1
		sub = "PLAYER 2 VENCEU O ROUND"

	_enter_round_over(title, sub, true)

func _on_time_over() -> void:
	if phase != Phase.FIGHTING:
		return
	var h1 := _get_health(fighter_p1)
	var h2 := _get_health(fighter_p2)
	var pct1: float = (float(h1.current_health) / float(h1.max_health)) if h1 else 1.0
	var pct2: float = (float(h2.current_health) / float(h2.max_health)) if h2 else 1.0

	var title := "TIME OVER!"
	var sub := ""
	if pct1 > pct2:
		p1_wins += 1
		sub = "PLAYER 1 VENCEU POR VIDA"
	elif pct2 > pct1:
		p2_wins += 1
		sub = "PLAYER 2 VENCEU POR VIDA"
	else:
		sub = "EMPATE"

	_enter_round_over(title, sub, false)

func _enter_round_over(title: String, sub: String, use_slowmo: bool) -> void:
	_sequence_token += 1
	var my_token := _sequence_token
	_ko_pending = false
	phase = Phase.ROUND_OVER
	phase_changed.emit("ROUND_OVER")
	wins_changed.emit(p1_wins, p2_wins)

	banner_requested.emit(title, sub, Color(1.0, 0.28, 0.22), 1.8)

	if use_slowmo:
		Engine.time_scale = 0.25
		await get_tree().create_timer(0.6, true, false, true).timeout
		if not is_inside_tree() or _sequence_token != my_token:
			Engine.time_scale = 1.0
			return
		Engine.time_scale = 1.0

	await get_tree().create_timer(1.6, true, false, true).timeout
	if not is_inside_tree() or _sequence_token != my_token:
		return

	if p1_wins >= rounds_to_win or p2_wins >= rounds_to_win:
		phase = Phase.MATCH_OVER
		phase_changed.emit("MATCH_OVER")
		var winner := "PLAYER 1 WINS!" if p1_wins >= rounds_to_win else "PLAYER 2 WINS!"
		banner_requested.emit(winner, "ENTER ou R: Revanche", Color(1.0, 0.88, 0.25), 999.0)
	else:
		current_round += 1
		_begin_round()

func _reset_fighters_for_round() -> void:
	_clear_projectiles()
	_reset_single_fighter(fighter_p1, p1_spawn_pos, 1.0)
	_reset_single_fighter(fighter_p2, p2_spawn_pos, -1.0)
	_p1_last_hp = _get_health(fighter_p1).max_health if _get_health(fighter_p1) else 1000
	_p2_last_hp = _get_health(fighter_p2).max_health if _get_health(fighter_p2) else 1000
	_p1_regen_cooldown = 0.0
	_p2_regen_cooldown = 0.0

func _clear_projectiles() -> void:
	var scene_root := get_tree().current_scene if get_tree() else get_parent()
	if not scene_root:
		return
	for child in scene_root.get_children():
		if child is HadoukenProjectile:
			child.queue_free()

func _reset_single_fighter(f: Fighter, spawn_pos: Vector2, initial_dir: float) -> void:
	if not f or not is_instance_valid(f):
		return
	f.global_position = spawn_pos
	f.velocity = Vector2.ZERO
	if "pre_slide_velocity" in f:
		f.pre_slide_velocity = Vector2.ZERO
	f.modulate = Color.WHITE

	var hitstop = f.get_component("HitstopComponent")
	if hitstop:
		hitstop.time_left = 0.0
		if "anim_sprite" in hitstop and hitstop.anim_sprite:
			hitstop.anim_sprite.position.x = hitstop._base_sprite_x
			hitstop.anim_sprite.play()

	var hitbox = f.get_component("HitboxComponent")
	if hitbox and hitbox.has_method("disable_box"):
		hitbox.disable_box()
	var hurtbox = f.get_component("HurtboxComponent")
	if hurtbox:
		if hurtbox.has_method("cancel_invuln"):
			hurtbox.cancel_invuln()
		if hurtbox.has_method("enable_box"):
			hurtbox.enable_box()
	var thb = f.get_component("ThrowHurtboxComponent")
	if thb:
		if thb.has_method("cancel_invuln"):
			thb.cancel_invuln()
		if thb.has_method("enable_box"):
			thb.enable_box()

	var hp := _get_health(f)
	if hp:
		hp.heal(hp.max_health)
	var guard_bar = f.get_component("GuardBar")
	if guard_bar and guard_bar.has_method("add"):
		guard_bar.add(guard_bar.max_value)
	var stun_bar = f.get_component("StunBar")
	if stun_bar and stun_bar.has_method("subtract"):
		stun_bar.subtract(stun_bar.max_value)
	var combo = f.get_component("ScalingComboComponent")
	if combo and combo.has_method("reset_combo"):
		combo.reset_combo()
	var posture = f.get_component("PostureComponent")
	if posture and posture.has_method("apply"):
		posture.apply("stand")

	var fsm = f.get("root_fsm")
	if fsm and fsm.has_method("change_state"):
		fsm.change_state("IdleState", {})

	var fc = f.get_component("FacingComponent")
	if fc and fc.has_method("set_facing"):
		fc.set_facing(initial_dir)

func _reset_super_meter(f: Fighter) -> void:
	if not f or not is_instance_valid(f):
		return
	var meter = f.get_component("MeterBar")
	if meter and meter.has_method("subtract"):
		meter.subtract(meter.max_value)

func _get_health(f: Fighter) -> HealthComponent:
	if not f or not is_instance_valid(f):
		return null
	return f.get_component("HealthComponent") as HealthComponent
