class_name FightHUD
extends CanvasLayer

@export var match_manager: MatchManager
@export var fighter_p1: Fighter
@export var fighter_p2: Fighter

var _p1_hp_bar: ProgressBar
var _p1_hp_trail: ProgressBar
var _p2_hp_bar: ProgressBar
var _p2_hp_trail: ProgressBar

var _p1_guard_bar: ProgressBar
var _p1_stun_bar: ProgressBar
var _p2_guard_bar: ProgressBar
var _p2_stun_bar: ProgressBar

var _p1_meter_bar: ProgressBar
var _p2_meter_bar: ProgressBar
var _p1_meter_label: Label
var _p2_meter_label: Label

var _timer_label: Label
var _round_label: Label
var _p1_gems: Array[ColorRect] = []
var _p2_gems: Array[ColorRect] = []

var _banner_container: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween

var _p1_combo_box: VBoxContainer
var _p1_combo_hits: Label
var _p1_combo_dmg: Label
var _p1_combo_fade_timer: float = 0.0

var _p2_combo_box: VBoxContainer
var _p2_combo_hits: Label
var _p2_combo_dmg: Label
var _p2_combo_fade_timer: float = 0.0

var _controls_panel: PanelContainer
var _training_badge: Label
var _connected: bool = false

func _ready() -> void:
	layer = 50
	_build_ui()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_resolve_refs()
	_connect_signals()
	_sync_all_bars()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == KEY_F2 and _controls_panel:
			_controls_panel.visible = not _controls_panel.visible

func _resolve_refs() -> void:
	var root := get_parent()
	if not root:
		return
	if not match_manager:
		match_manager = root.get_node_or_null("MatchManager") as MatchManager
	if not fighter_p1:
		fighter_p1 = root.get_node_or_null("Player1") as Fighter
	if not fighter_p2:
		fighter_p2 = root.get_node_or_null("Opponent") as Fighter

func _connect_signals() -> void:
	if _connected:
		return
	_connected = true

	if match_manager:
		match_manager.round_started.connect(_on_round_started)
		match_manager.banner_requested.connect(_on_banner_requested)
		match_manager.timer_changed.connect(_on_timer_changed)
		match_manager.wins_changed.connect(_on_wins_changed)
		match_manager.training_mode_changed.connect(_on_training_mode_changed)

	var h1 := fighter_p1.get_component("HealthComponent") as HealthComponent if fighter_p1 else null
	if h1:
		h1.health_changed.connect(_on_p1_health_changed)
	var h2 := fighter_p2.get_component("HealthComponent") as HealthComponent if fighter_p2 else null
	if h2:
		h2.health_changed.connect(_on_p2_health_changed)

	# Combo contra P2 é exibido no lado do P1 (e vice-versa)
	var c2 := fighter_p2.get_component("ScalingComboComponent") as ScalingComboComponent if fighter_p2 else null
	if c2:
		c2.combo_updated.connect(_on_p1_combo_updated)
		c2.combo_dropped.connect(_on_p1_combo_dropped)
	var c1 := fighter_p1.get_component("ScalingComboComponent") as ScalingComboComponent if fighter_p1 else null
	if c1:
		c1.combo_updated.connect(_on_p2_combo_updated)
		c1.combo_dropped.connect(_on_p2_combo_dropped)

	_connect_bar(fighter_p1, "GuardBar", _p1_guard_bar)
	_connect_bar(fighter_p1, "StunBar", _p1_stun_bar)
	_connect_bar(fighter_p1, "MeterBar", _p1_meter_bar, _p1_meter_label)
	_connect_bar(fighter_p2, "GuardBar", _p2_guard_bar)
	_connect_bar(fighter_p2, "StunBar", _p2_stun_bar)
	_connect_bar(fighter_p2, "MeterBar", _p2_meter_bar, _p2_meter_label)

func _connect_bar(f: Fighter, node_name: String, ui_bar: ProgressBar, meter_lbl: Label = null) -> void:
	if not f:
		return
	var bar_comp := f.get_component(node_name)
	if bar_comp and bar_comp.has_signal("value_changed"):
		bar_comp.value_changed.connect(func(val: float, max_val: float):
			ui_bar.max_value = max_val
			ui_bar.value = val
			if meter_lbl:
				var pct := int((val / maxf(max_val, 1.0)) * 100.0)
				meter_lbl.text = "MAX!" if pct >= 100 else "%d%%" % pct
		)

func _sync_all_bars() -> void:
	if fighter_p1:
		var h1 := fighter_p1.get_component("HealthComponent") as HealthComponent
		if h1:
			_p1_hp_bar.max_value = h1.max_health
			_p1_hp_bar.value = h1.current_health
			_p1_hp_trail.max_value = h1.max_health
			_p1_hp_trail.value = h1.current_health
		_sync_single_bar(fighter_p1, "GuardBar", _p1_guard_bar)
		_sync_single_bar(fighter_p1, "StunBar", _p1_stun_bar)
		_sync_single_bar(fighter_p1, "MeterBar", _p1_meter_bar, _p1_meter_label)
	if fighter_p2:
		var h2 := fighter_p2.get_component("HealthComponent") as HealthComponent
		if h2:
			_p2_hp_bar.max_value = h2.max_health
			_p2_hp_bar.value = h2.current_health
			_p2_hp_trail.max_value = h2.max_health
			_p2_hp_trail.value = h2.current_health
		_sync_single_bar(fighter_p2, "GuardBar", _p2_guard_bar)
		_sync_single_bar(fighter_p2, "StunBar", _p2_stun_bar)
		_sync_single_bar(fighter_p2, "MeterBar", _p2_meter_bar, _p2_meter_label)

func _sync_single_bar(f: Fighter, node_name: String, ui_bar: ProgressBar, meter_lbl: Label = null) -> void:
	var bar_comp := f.get_component(node_name)
	if bar_comp and "current_value" in bar_comp and "max_value" in bar_comp:
		ui_bar.max_value = bar_comp.max_value
		ui_bar.value = bar_comp.current_value
		if meter_lbl:
			var pct := int((bar_comp.current_value / maxf(bar_comp.max_value, 1.0)) * 100.0)
			meter_lbl.text = "MAX!" if pct >= 100 else "%d%%" % pct

func _process(delta: float) -> void:
	if _p1_hp_trail and _p1_hp_bar:
		if _p1_hp_trail.value > _p1_hp_bar.value:
			_p1_hp_trail.value = move_toward(_p1_hp_trail.value, _p1_hp_bar.value, 320.0 * delta)
		else:
			_p1_hp_trail.value = _p1_hp_bar.value
	if _p2_hp_trail and _p2_hp_bar:
		if _p2_hp_trail.value > _p2_hp_bar.value:
			_p2_hp_trail.value = move_toward(_p2_hp_trail.value, _p2_hp_bar.value, 320.0 * delta)
		else:
			_p2_hp_trail.value = _p2_hp_bar.value

	if _p1_combo_fade_timer > 0.0:
		_p1_combo_fade_timer -= delta
		if _p1_combo_fade_timer <= 0.0 and _p1_combo_box:
			_p1_combo_box.visible = false
	if _p2_combo_fade_timer > 0.0:
		_p2_combo_fade_timer -= delta
		if _p2_combo_fade_timer <= 0.0 and _p2_combo_box:
			_p2_combo_box.visible = false

func _on_p1_health_changed(new_hp: int, max_hp: int) -> void:
	_p1_hp_bar.max_value = max_hp
	_p1_hp_bar.value = new_hp
	_p1_hp_trail.max_value = max_hp
	_apply_hp_color(_p1_hp_bar, float(new_hp) / maxf(float(max_hp), 1.0))

func _on_p2_health_changed(new_hp: int, max_hp: int) -> void:
	_p2_hp_bar.max_value = max_hp
	_p2_hp_bar.value = new_hp
	_p2_hp_trail.max_value = max_hp
	_apply_hp_color(_p2_hp_bar, float(new_hp) / maxf(float(max_hp), 1.0))

func _apply_hp_color(bar: ProgressBar, ratio: float) -> void:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill:
		return
	if ratio > 0.5:
		fill.bg_color = Color(0.18, 0.85, 0.42)
	elif ratio > 0.25:
		fill.bg_color = Color(0.95, 0.78, 0.16)
	else:
		fill.bg_color = Color(0.95, 0.22, 0.22)

func _on_round_started(round_number: int) -> void:
	if _round_label:
		_round_label.text = "TREINO" if (match_manager and match_manager.training_mode) else ("ROUND %d" % round_number)

func _on_timer_changed(seconds_left: int, is_training: bool) -> void:
	if not _timer_label:
		return
	if is_training:
		_timer_label.text = "∞"
		_timer_label.modulate = Color(0.45, 0.92, 1.0)
	else:
		_timer_label.text = "%02d" % seconds_left
		_timer_label.modulate = Color(1.0, 0.28, 0.25) if seconds_left <= 15 else Color.WHITE

func _on_wins_changed(p1_w: int, p2_w: int) -> void:
	for i in range(_p1_gems.size()):
		_p1_gems[i].color = Color(1.0, 0.82, 0.15) if i < p1_w else Color(0.22, 0.24, 0.32)
	for i in range(_p2_gems.size()):
		_p2_gems[i].color = Color(1.0, 0.82, 0.15) if i < p2_w else Color(0.22, 0.24, 0.32)

func _on_training_mode_changed(enabled: bool) -> void:
	if _training_badge:
		_training_badge.visible = enabled
	if _round_label:
		_round_label.text = "TREINO" if enabled else ("ROUND %d" % (match_manager.current_round if match_manager else 1))

func _on_banner_requested(text: String, subtext: String, color: Color, duration: float) -> void:
	if not _banner_container:
		return
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()

	_banner_title.text = text
	_banner_title.add_theme_color_override("font_color", color)
	_banner_sub.text = subtext
	_banner_sub.visible = (subtext != "")
	_banner_container.visible = true
	_banner_container.modulate.a = 1.0
	_banner_container.scale = Vector2(1.35, 1.35)

	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_container, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if duration < 100.0:
		_banner_tween.tween_interval(maxf(0.1, duration - 0.35))
		_banner_tween.tween_property(_banner_container, "modulate:a", 0.0, 0.22)
		_banner_tween.tween_callback(func(): _banner_container.visible = false)

func _on_p1_combo_updated(hits: int, total_damage: float) -> void:
	_show_combo(_p1_combo_box, _p1_combo_hits, _p1_combo_dmg, hits, total_damage)
	_p1_combo_fade_timer = 1.6

func _on_p1_combo_dropped() -> void:
	_p1_combo_fade_timer = 0.85

func _on_p2_combo_updated(hits: int, total_damage: float) -> void:
	_show_combo(_p2_combo_box, _p2_combo_hits, _p2_combo_dmg, hits, total_damage)
	_p2_combo_fade_timer = 1.6

func _on_p2_combo_dropped() -> void:
	_p2_combo_fade_timer = 0.85

func _show_combo(box: VBoxContainer, hits_lbl: Label, dmg_lbl: Label, hits: int, dmg: float) -> void:
	if hits < 2:
		return
	box.visible = true
	hits_lbl.text = "%d HITS!" % hits
	dmg_lbl.text = "%d DANO" % int(dmg)
	box.scale = Vector2(1.28, 1.28)
	var t := create_tween()
	t.tween_property(box, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ==============================================================================
# CONSTRUÇÃO DA INTERFACE (1920x1080 ARCADE HUD)
# ==============================================================================
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- P1 NOME ---
	var p1_name := _make_label("P1  SHIN RYU", 20, Color(1.0, 0.9, 0.35), HORIZONTAL_ALIGNMENT_LEFT)
	p1_name.position = Vector2(60, 14)
	p1_name.size = Vector2(400, 28)
	root.add_child(p1_name)

	# --- P2 NOME ---
	var p2_name := _make_label("RYU  P2", 20, Color(0.55, 0.85, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	p2_name.position = Vector2(1460, 14)
	p2_name.size = Vector2(400, 28)
	root.add_child(p2_name)

	# --- BARRA DE VIDA P1 (Drena da esquerda em direção ao centro) ---
	_p1_hp_trail = _make_bar(Vector2(60, 44), Vector2(790, 34), Color(0.07, 0.08, 0.12, 0.92), Color(0.95, 0.72, 0.15), ProgressBar.FILL_END_TO_BEGIN, true)
	root.add_child(_p1_hp_trail)
	_p1_hp_bar = _make_bar(Vector2(60, 44), Vector2(790, 34), Color(0, 0, 0, 0), Color(0.18, 0.85, 0.42), ProgressBar.FILL_END_TO_BEGIN, false)
	root.add_child(_p1_hp_bar)

	# --- BARRA DE VIDA P2 (Drena da direita em direção ao centro) ---
	_p2_hp_trail = _make_bar(Vector2(1070, 44), Vector2(790, 34), Color(0.07, 0.08, 0.12, 0.92), Color(0.95, 0.72, 0.15), ProgressBar.FILL_BEGIN_TO_END, true)
	root.add_child(_p2_hp_trail)
	_p2_hp_bar = _make_bar(Vector2(1070, 44), Vector2(790, 34), Color(0, 0, 0, 0), Color(0.18, 0.85, 0.42), ProgressBar.FILL_BEGIN_TO_END, false)
	root.add_child(_p2_hp_bar)

	# --- GUARD & STUN MINI-BARRAS ---
	var p1_glbl := _make_label("GUARD", 12, Color(0.5, 0.82, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	p1_glbl.position = Vector2(60, 84)
	p1_glbl.size = Vector2(54, 16)
	root.add_child(p1_glbl)
	_p1_guard_bar = _make_bar(Vector2(118, 86), Vector2(220, 10), Color(0.08, 0.1, 0.16, 0.85), Color(0.28, 0.72, 1.0), ProgressBar.FILL_BEGIN_TO_END, false)
	root.add_child(_p1_guard_bar)

	var p1_slbl := _make_label("STUN", 12, Color(1.0, 0.65, 0.25), HORIZONTAL_ALIGNMENT_LEFT)
	p1_slbl.position = Vector2(356, 84)
	p1_slbl.size = Vector2(46, 16)
	root.add_child(p1_slbl)
	_p1_stun_bar = _make_bar(Vector2(404, 86), Vector2(220, 10), Color(0.08, 0.1, 0.16, 0.85), Color(1.0, 0.45, 0.15), ProgressBar.FILL_BEGIN_TO_END, false)
	root.add_child(_p1_stun_bar)

	var p2_glbl := _make_label("GUARD", 12, Color(0.5, 0.82, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	p2_glbl.position = Vector2(1806, 84)
	p2_glbl.size = Vector2(54, 16)
	root.add_child(p2_glbl)
	_p2_guard_bar = _make_bar(Vector2(1582, 86), Vector2(220, 10), Color(0.08, 0.1, 0.16, 0.85), Color(0.28, 0.72, 1.0), ProgressBar.FILL_END_TO_BEGIN, false)
	root.add_child(_p2_guard_bar)

	var p2_slbl := _make_label("STUN", 12, Color(1.0, 0.65, 0.25), HORIZONTAL_ALIGNMENT_RIGHT)
	p2_slbl.position = Vector2(1518, 84)
	p2_slbl.size = Vector2(46, 16)
	root.add_child(p2_slbl)
	_p2_stun_bar = _make_bar(Vector2(1296, 86), Vector2(220, 10), Color(0.08, 0.1, 0.16, 0.85), Color(1.0, 0.45, 0.15), ProgressBar.FILL_END_TO_BEGIN, false)
	root.add_child(_p2_stun_bar)

	# --- GEMAS DE VITÓRIA (P1 e P2) ---
	for i in range(2):
		var g1 := ColorRect.new()
		g1.position = Vector2(828 - i * 26, 86)
		g1.size = Vector2(18, 18)
		g1.color = Color(0.22, 0.24, 0.32)
		root.add_child(g1)
		_p1_gems.append(g1)

		var g2 := ColorRect.new()
		g2.position = Vector2(1074 + i * 26, 86)
		g2.size = Vector2(18, 18)
		g2.color = Color(0.22, 0.24, 0.32)
		root.add_child(g2)
		_p2_gems.append(g2)

	# --- RELÓGIO CENTRAL E ROUND ---
	var timer_panel := PanelContainer.new()
	timer_panel.position = Vector2(880, 14)
	timer_panel.size = Vector2(160, 88)
	var tp_style := StyleBoxFlat.new()
	tp_style.bg_color = Color(0.07, 0.08, 0.14, 0.94)
	tp_style.border_color = Color(0.85, 0.72, 0.28, 0.9)
	tp_style.set_border_width_all(2)
	tp_style.set_corner_radius_all(8)
	timer_panel.add_theme_stylebox_override("panel", tp_style)
	root.add_child(timer_panel)

	var timer_vbox := VBoxContainer.new()
	timer_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(timer_vbox)

	_round_label = _make_label("ROUND 1", 13, Color(0.88, 0.78, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	timer_vbox.add_child(_round_label)

	_timer_label = _make_label("99", 44, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	timer_vbox.add_child(_timer_label)

	_training_badge = _make_label("MODO TREINO (F1)", 14, Color(0.35, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_training_badge.position = Vector2(810, 108)
	_training_badge.size = Vector2(300, 24)
	_training_badge.visible = false
	root.add_child(_training_badge)

	# --- CONTADORES DE COMBO ---
	_p1_combo_box = _make_combo_box(Vector2(65, 220), HORIZONTAL_ALIGNMENT_LEFT)
	_p1_combo_hits = _p1_combo_box.get_child(0) as Label
	_p1_combo_dmg = _p1_combo_box.get_child(1) as Label
	root.add_child(_p1_combo_box)

	_p2_combo_box = _make_combo_box(Vector2(1555, 220), HORIZONTAL_ALIGNMENT_RIGHT)
	_p2_combo_hits = _p2_combo_box.get_child(0) as Label
	_p2_combo_dmg = _p2_combo_box.get_child(1) as Label
	root.add_child(_p2_combo_box)

	# --- BANNER CENTRAL (ROUND / FIGHT / K.O. / WINS) ---
	_banner_container = VBoxContainer.new()
	_banner_container.position = Vector2(460, 340)
	_banner_container.size = Vector2(1000, 180)
	_banner_container.pivot_offset = Vector2(500, 90)
	_banner_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_container.visible = false
	root.add_child(_banner_container)

	_banner_title = _make_label("FIGHT!", 86, Color(1.0, 0.85, 0.25), HORIZONTAL_ALIGNMENT_CENTER)
	_banner_title.add_theme_constant_override("outline_size", 10)
	_banner_title.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
	_banner_container.add_child(_banner_title)

	_banner_sub = _make_label("", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_banner_sub.add_theme_constant_override("outline_size", 6)
	_banner_sub.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
	_banner_container.add_child(_banner_sub)

	# --- SUPER METERS (RODAPÉ) ---
	var p1_mlbl_title := _make_label("SUPER METER", 14, Color(0.75, 0.6, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	p1_mlbl_title.position = Vector2(60, 982)
	p1_mlbl_title.size = Vector2(160, 20)
	root.add_child(p1_mlbl_title)
	_p1_meter_label = _make_label("0%", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_p1_meter_label.position = Vector2(400, 982)
	_p1_meter_label.size = Vector2(80, 20)
	root.add_child(_p1_meter_label)
	_p1_meter_bar = _make_bar(Vector2(60, 1004), Vector2(420, 22), Color(0.07, 0.08, 0.14, 0.92), Color(0.52, 0.35, 1.0), ProgressBar.FILL_BEGIN_TO_END, true)
	root.add_child(_p1_meter_bar)

	var p2_mlbl_title := _make_label("SUPER METER", 14, Color(0.75, 0.6, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	p2_mlbl_title.position = Vector2(1700, 982)
	p2_mlbl_title.size = Vector2(160, 20)
	root.add_child(p2_mlbl_title)
	_p2_meter_label = _make_label("0%", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_p2_meter_label.position = Vector2(1440, 982)
	_p2_meter_label.size = Vector2(80, 20)
	root.add_child(_p2_meter_label)
	_p2_meter_bar = _make_bar(Vector2(1440, 1004), Vector2(420, 22), Color(0.07, 0.08, 0.14, 0.92), Color(0.52, 0.35, 1.0), ProgressBar.FILL_END_TO_BEGIN, true)
	root.add_child(_p2_meter_bar)

	# --- ATALHOS NO RODAPÉ ---
	var hint := _make_label("F1: Modo Treino  |  F2: Comandos  |  F3: Debug  |  R: Reiniciar Partida", 15, Color(0.85, 0.88, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(560, 1044)
	hint.size = Vector2(800, 24)
	root.add_child(hint)

	# --- PAINEL DE COMANDOS (F2) ---
	_controls_panel = _build_controls_panel()
	root.add_child(_controls_panel)

func _make_label(txt: String, font_size: int, col: Color, align: HorizontalAlignment) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _make_bar(pos: Vector2, sz: Vector2, bg_col: Color, fill_col: Color, mode: int, with_border: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = sz
	bar.show_percentage = false
	bar.fill_mode = mode
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_col
	if with_border:
		bg.border_color = Color(0.75, 0.78, 0.88, 0.85)
		bg.set_border_width_all(2)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)

	var fl := StyleBoxFlat.new()
	fl.bg_color = fill_col
	fl.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fl)
	return bar

func _make_combo_box(pos: Vector2, align: HorizontalAlignment) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = pos
	box.size = Vector2(300, 100)
	box.pivot_offset = Vector2(150, 50)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.visible = false

	var hits := _make_label("2 HITS!", 40, Color(1.0, 0.82, 0.18), align)
	hits.add_theme_constant_override("outline_size", 6)
	var dmg := _make_label("120 DANO", 18, Color(1.0, 0.55, 0.25), align)
	box.add_child(hits)
	box.add_child(dmg)
	return box

func _build_controls_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(410, 170)
	panel.size = Vector2(1100, 720)
	panel.visible = false

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.06, 0.11, 0.94)
	st.border_color = Color(0.45, 0.72, 1.0, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", st)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.add_theme_font_size_override("normal_font_size", 18)
	rtl.text = """[center][b][color=#ffd24c]GUIA DE COMANDOS (Pressione F2 para fechar)[/color][/b][/center]

[b][color=#66ccff]CONTROLES P1:[/color][/b]  Setas (Mover / Pular / Agachar)  |  [b]A[/b]: Soco Fraco (LP)  |  [b]D[/b]: Soco Forte (HP)  |  [b]S[/b]: Chute Fraco (LK)  |  [b]Z[/b]: Chute Forte (HK)
[b][color=#88ddff]CONTROLES P2:[/color][/b]  J I K L ou Numpad 4 8 2 6  |  [b]U/Num7[/b]: LP  |  [b]O/Num9[/b]: HP  |  [b]M/Num1[/b]: LK  |  [b]P/Num3[/b]: HK

[b][color=#ffd24c]SISTEMA DE MOVIMENTAÇÃO KOF:[/color][/b]
• [b]Short Hop:[/b] Toque rápido em ↑ (solte em até 4-8 frames)   • [b]Pulo Alto:[/b] Segure ↑
• [b]Hyper Hop / Super Jump:[/b] Toque ↓ antes de ↑, ou pule durante a Corrida
• [b]Dash / Corrida:[/b] → → (mantenha segurado para correr)   • [b]Backdash:[/b] ← ←
• [b]Emergency Roll (Esquiva com i-frames):[/b] LP + LK (com ← ou →; atravessa golpes e projéteis)
• [b]Defesa:[/b] Segure ← (defende High/Mid) ou ↙ (defende Low/Mid)
• [b]Carregar Super Meter:[/b] Segure LP + HK

[b][color=#ff7755]GOLPES ESPECIAIS (Segure o botão para Carregar! Na carga, LP+LK = Hybrid Dash, HP+LK = Super Throw):[/color][/b]
• [b]Hadouken:[/b] ↓ ↘ → + Soco (Chão, Agachado ou Ar)
• [b]Shoryuken (Anti-aéreo invencível):[/b] → ↓ ↘ + Soco
• [b]Tatsumaki:[/b] ↓ ↙ ← + Chute (Chão, Agachado ou Ar)
• [b]Joudan / Divekick:[/b] ↓ ↘ → + Chute (Chão: avanço com Wall Splat no canto | Ar: Divekick)
• [b]Gatling Combos:[/b] LP → LP → HP/HK → Especial"""
	panel.add_child(rtl)
	return panel
