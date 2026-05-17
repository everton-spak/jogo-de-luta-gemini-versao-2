extends CanvasLayer

# ==========================================
# 🔍 SISTEMA DE DEBUG - PROPRIEDADES DO PLAYER
# ==========================================
# Pressione F3 para ativar/desativar o painel de debug.
# Ele busca automaticamente todos os Fighters na cena
# e exibe as suas propriedades em tempo real.

var label: RichTextLabel
var panel: PanelContainer
var is_visible: bool = false

# Cache de referências (atualizado a cada 60 frames ou ao ligar)
var _fighters: Array = []
var _refresh_counter: int = 0
const REFRESH_INTERVAL: int = 60  # Atualiza a lista de fighters a cada 60 frames

func _ready() -> void:
	layer = 100  # Fica acima de tudo
	
	# --- PAINEL DE FUNDO ---
	panel = PanelContainer.new()
	panel.name = "DebugPanel"
	
	# Estilo do painel (fundo semi-transparente escuro)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.12, 0.88)
	style.border_color = Color(0.3, 0.6, 1.0, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	
	# Posição e tamanho
	panel.position = Vector2(8, 8)
	panel.size = Vector2(420, 600)
	
	# --- LABEL DE TEXTO RICO ---
	label = RichTextLabel.new()
	label.name = "DebugLabel"
	label.bbcode_enabled = true
	label.scroll_active = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(400, 0)
	
	# Fonte monoespaçada para alinhamento (usa a default do sistema)
	label.add_theme_font_size_override("normal_font_size", 13)
	label.add_theme_font_size_override("bold_font_size", 14)
	label.add_theme_color_override("default_color", Color(0.85, 0.9, 1.0))
	
	panel.add_child(label)
	add_child(panel)
	
	# Começa escondido
	panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			is_visible = !is_visible
			panel.visible = is_visible
			if is_visible:
				_find_fighters()

func _physics_process(_delta: float) -> void:
	if not is_visible:
		return
	
	# Atualiza o cache de fighters periodicamente
	_refresh_counter += 1
	if _refresh_counter >= REFRESH_INTERVAL:
		_refresh_counter = 0
		_find_fighters()
	
	# Monta o texto de debug
	var text = ""
	text += "[b][color=#6aadff]═══ 🔍 DEBUG OVERLAY (F3) ═══[/color][/b]\n"
	text += "[color=#aaaaaa]Tick Global (Física): %d[/color]\n" % Engine.get_physics_frames()
	text += "[color=#555555]────────────────────────────────[/color]\n"
	
	if _fighters.is_empty():
		text += "[color=#ff6666]Nenhum Fighter encontrado na cena![/color]\n"
	else:
		for i in range(_fighters.size()):
			var fighter = _fighters[i]
			if not is_instance_valid(fighter):
				continue
			text += _build_fighter_debug(fighter, i)
			if i < _fighters.size() - 1:
				text += "\n[color=#555555]────────────────────────────────[/color]\n"
	
	label.text = text

# ==========================================
# 🔎 BUSCA TODOS OS FIGHTERS NA CENA
# ==========================================
func _find_fighters() -> void:
	_fighters.clear()
	var root = get_tree().current_scene
	if root:
		_find_fighters_recursive(root)

func _find_fighters_recursive(node: Node) -> void:
	if node is Fighter:
		_fighters.append(node)
	for child in node.get_children():
		_find_fighters_recursive(child)

# ==========================================
# 📊 MONTA O BLOCO DE DEBUG DE UM FIGHTER
# ==========================================
func _build_fighter_debug(fighter: Fighter, index: int) -> String:
	var s = ""
	
	# --- CABEÇALHO ---
	var player_label = fighter.name if fighter.name != "" else ("Player " + str(index + 1))
	s += "[b][color=#ffcc44]▶ %s[/color][/b]\n" % player_label
	
	# --- POSIÇÃO E VELOCIDADE ---
	s += _section("FÍSICA")
	s += _prop("Posição", _vec2_str(fighter.global_position))
	s += _prop("Velocidade", _vec2_str(fighter.velocity))
	s += _prop("No Chão", _bool_str(fighter.is_on_floor()))
	
	# --- STATE MACHINE ---
	s += _section("ESTADO (FSM)")
	var root_fsm = fighter.get_node_or_null("Component/StateMachine") as StateMachine
	if root_fsm:
		s += _build_fsm_state_chain(root_fsm, 0)
		# Tags ativas
		var tags = root_fsm.get_tags()
		if not tags.is_empty():
			s += _prop("Tags", "[color=#88ddff][%s][/color]" % ", ".join(tags))
		else:
			s += _prop("Tags", "[color=#666666]nenhuma[/color]")
	else:
		s += "  [color=#ff6666]FSM não encontrada[/color]\n"
	
	# --- COMPONENTES ---
	s += _section("COMPONENTES")
	
	# Health
	var health = fighter.get_component("HealthComponent")
	if health and health is HealthComponent:
		var pct = (float(health.current_health) / float(health.max_health)) * 100.0
		var health_color = _health_color(pct)
		s += _prop("Vida", "[color=%s]%d / %d (%.0f%%)[/color]" % [health_color, health.current_health, health.max_health, pct])
	
	# Facing
	var facing = fighter.get_component("FacingComponent")
	if facing and facing is FacingComponent:
		var dir_str = "→ Direita" if facing.current_facing > 0 else "← Esquerda"
		s += _prop("Facing", dir_str)
	
	# Combo Scaling
	var combo = fighter.get_component("ScalingComboComponent")
	if combo and combo is ScalingComboComponent:
		if combo.current_hits > 0:
			s += _prop("Combo", "[color=#ffaa33]%d HITS (%.0f DMG)[/color]" % [combo.current_hits, combo.total_combo_damage])
		else:
			s += _prop("Combo", "[color=#666666]—[/color]")
	
	# Hitstop
	var hitstop = fighter.get_component("HitstopComponent")
	if hitstop and hitstop is HitstopComponent:
		if hitstop.is_stopped():
			s += _prop("Hitstop", "[color=#ff4444]CONGELADO (%.2fs)[/color]" % hitstop.time_left)
		else:
			s += _prop("Hitstop", "[color=#666666]—[/color]")
	
	# Input
	var input_comp = fighter.get_component("InputComponent")
	if input_comp and input_comp is InputComponent:
		var dir = input_comp.get_movement_direction()
		s += _prop("Input Dir", _vec2_str(dir))
	
	# ==========================================
	# 🎮 COMANDOS / INPUT BUFFER
	# ==========================================
	s += _section("COMANDOS")
	
	# --- Botões sendo pressionados AGORA ---
	if input_comp and input_comp is InputComponent:
		var held_buttons: Array[String] = []
		for action in ["punch_light", "punch_heavy", "kick_light", "kick_heavy"]:
			if input_comp.is_action_pressed(action):
				held_buttons.append(_input_to_icon(action))
		if not held_buttons.is_empty():
			s += _prop("Botões", "[color=#ff88ff]%s[/color]" % " ".join(held_buttons))
		else:
			s += _prop("Botões", "[color=#666666]—[/color]")
		
		# Direcional atual em notação de luta
		var dir_now = input_comp.get_movement_direction()
		var dir_icon = _direction_to_icon(dir_now)
		s += _prop("Direcional", "[color=#88ffdd]%s[/color]" % dir_icon)
	
	# --- Buffer do InputBuffer (novo sistema) ---
	var input_buffer = fighter.get_component("InputBufferComponent")
	if input_buffer and input_buffer is InputBuffer:
		# Histórico de inputs
		var history = input_buffer.history
		if history and history is InputHistoryComponent:
			s += _build_input_history(history._buffer)
		
		# Charge timers
		var charge = input_buffer.charge
		if charge and "charge_time" in charge:
			s += _build_charge_timers(charge)
		
		# Última Query detectada
		if not input_buffer.last_query.is_empty():
			s += _build_query_display(input_buffer.last_query)
		else:
			s += _prop("Última Query", "[color=#666666]—[/color]")
	
	return s

# ==========================================
# 🌲 DESENHA A CADEIA DE ESTADOS DA FSM
# ==========================================
func _build_fsm_state_chain(fsm: StateMachine, depth: int) -> String:
	var s = ""
	var indent = "  ".repeat(depth + 1)
	
	if fsm.current_state:
		var state_name = fsm.current_state_name
		var color = "#44ff88" if depth == 0 else "#88ffaa"
		s += "%s[color=%s]%s[/color] → " % [indent, "#aaaaaa", fsm.name]
		
		# Adiciona o score se houver
		var score_text = ""
		if "last_winning_score" in fsm and fsm.last_winning_score > 0:
			score_text = " [color=#ffff00](Sc: %d)[/color]" % fsm.last_winning_score
			
		# Adiciona os frames ativos e fases do ataque
		var frames_text = ""
		if "state_frames" in fsm.current_state:
			frames_text = " [color=#44ccff][%d F][/color]" % fsm.current_state.state_frames
			
		# Se for um ataque, mostra a fase (Startup, Active, Recovery)
		# AttackComponent agora é shared (composição) — lê _launched/_active_ended/_recovered
		if fsm.current_state is AttackStateBase:
			var ac = fsm.current_state.attack
			if ac:
				if not ac._launched:
					frames_text += " [color=#ffaa00](STARTUP)[/color]"
				elif not ac._active_ended:
					frames_text += " [color=#ff4444](ACTIVE)[/color]"
				elif not ac._recovered:
					frames_text += " [color=#44bbff](RECOVERY)[/color]"
			
		s += "[b][color=%s]%s[/color][/b]%s%s\n" % [color, state_name, score_text, frames_text]
		
		# Se o estado atual também é uma FSM, mostra os sub-estados recursivamente
		if fsm.current_state is StateMachine:
			s += _build_fsm_state_chain(fsm.current_state as StateMachine, depth + 1)
	else:
		s += "%s[color=#aaaaaa]%s[/color] → [color=#ff9966]SEM ESTADO[/color]\n" % [indent, fsm.name]
	
	return s

# ==========================================
# 🎨 HELPERS DE FORMATAÇÃO
# ==========================================
func _section(title: String) -> String:
	return "\n[color=#6aadff][b]  ── %s ──[/b][/color]\n" % title

func _prop(key: String, value: String) -> String:
	return "  [color=#aaaacc]%s:[/color] %s\n" % [key, value]

func _vec2_str(v: Vector2) -> String:
	return "[color=#dddddd](%.1f, %.1f)[/color]" % [v.x, v.y]

func _bool_str(b: bool) -> String:
	if b:
		return "[color=#44ff88]✓ SIM[/color]"
	else:
		return "[color=#ff6666]✗ NÃO[/color]"

func _health_color(pct: float) -> String:
	if pct > 60:
		return "#44ff88"
	elif pct > 30:
		return "#ffcc44"
	else:
		return "#ff4444"

# ==========================================
# 🎮 HELPERS DE INPUT / COMANDOS
# ==========================================

# Converte nome de ação para ícone visual
func _input_to_icon(action: String) -> String:
	match action:
		"punch_light": return "🤛L"
		"punch_heavy": return "🤜H"
		"kick_light": return "🦶L"
		"kick_heavy": return "🦵H"
		# Notação de setas (vem do buffer)
		"F": return "→"
		"B": return "←"
		"U": return "↑"
		"D": return "↓"
		"DF": return "↘"
		"DB": return "↙"
		"UF": return "↗"
		"UB": return "↖"
		"N": return "●"
		_: return action

# Converte Vector2 direcional para ícone de seta
func _direction_to_icon(v: Vector2) -> String:
	if v == Vector2.ZERO: return "● Neutro"
	
	var x = sign(v.x)
	var y = sign(v.y)
	
	if y < 0 and x > 0: return "↗ Up-Forward"
	if y < 0 and x < 0: return "↖ Up-Back"
	if y > 0 and x > 0: return "↘ Down-Forward"
	if y > 0 and x < 0: return "↙ Down-Back"
	if y < 0: return "↑ Up"
	if y > 0: return "↓ Down"
	if x > 0: return "→ Forward"
	if x < 0: return "← Back"
	return "● Neutro"

# Monta a linha visual do histórico de inputs do buffer
func _build_input_history(buffer: Array) -> String:
	if buffer.is_empty():
		return _prop("Buffer", "[color=#666666]vazio[/color]")
	
	# Mostra os últimos 16 inputs como ícones
	var icons: Array[String] = []
	var start = max(0, buffer.size() - 16)
	for i in range(start, buffer.size()):
		var entry = buffer[i]
		if entry.has("input"):
			icons.append(_input_to_icon(entry["input"]))
	
	var timeline = " ".join(icons)
	var s = _prop("Buffer", "[color=#ffdd88]%s[/color]" % timeline)
	s += _prop("  Tamanho", "[color=#aaaaaa]%d inputs[/color]" % buffer.size())
	return s

# Charge timers para o novo sistema (ChargeTrackerComponent)
func _build_charge_timers(charge_comp) -> String:
	var s = ""
	if "charge_time" in charge_comp:
		var charge_dict = charge_comp.charge_time
		for dir_key in charge_dict.keys():
			var time_ms = charge_dict[dir_key]
			if time_ms > 0:
				var icon = "←" if dir_key == "B" else "↓"
				s += _prop("Carga %s" % icon, "[color=#44ddff]%.0f ms[/color]" % time_ms)
	return s

# Formata a última query detectada
func _build_query_display(payload: Dictionary) -> String:
	var s = ""
	var query = payload.get("query", payload)
	
	# Monta uma linha resumida com todos os campos da query
	var parts: Array[String] = []
	if query.has("type"):
		parts.append("[color=#ff88ff]%s[/color]" % str(query["type"]).to_upper())
	if query.has("strength"):
		var str_color = "#ff4444" if query["strength"] == "heavy" else "#44bbff"
		parts.append("[color=%s]%s[/color]" % [str_color, str(query["strength"])])
	if query.has("stance"):
		parts.append("[color=#88ffaa]%s[/color]" % str(query["stance"]))
	if query.has("direction"):
		parts.append("[color=#ffcc44]dir:%s[/color]" % str(query["direction"]))
	
	if not parts.is_empty():
		s += _prop("Última Query", " | ".join(parts))
	else:
		s += _prop("Última Query", "[color=#aaaaaa]%s[/color]" % str(query))
	
	return s
