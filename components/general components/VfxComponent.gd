class_name VfxComponent
extends Component

# Efeitos visuais do lutador: flash de cor, ghost (afterimage), hit spark.
# State.gd cacheia este componente como `vfx`. Qualquer estado pode chamar
# `vfx.play_flash("cancel")` ou `vfx.spawn_ghost()` sem se preocupar com null
# (os métodos são early-return se vfx não foi setado).

# Cores pré-definidas (HDR pra dar brilho com glow ligado no ambiente).
const COLORS := {
	"cancel": Color(0.0, 2.0, 5.0),        # Azul neon
	"counter": Color(5.0, 0.0, 0.0),       # Vermelho intenso
	"buster": Color(5.0, 3.0, 0.0),        # Dourado/laranja
	"charge_normal": Color(0.4, 0.6, 1.5), # Azul suave (carga estágio 1)
	"charge_strong": Color(0.5, 1.0, 0.5), # Verde suave (carga estágio 2)
	"charge_super": Color(1.0, 0.5, 0.5),  # Vermelho suave (carga estágio 3)
	"white": Color.WHITE,
}

@export var hit_spark_scene: PackedScene
# Ghost por padrão fica atrás do sprite real (z_index = sprite.z_index + offset)
@export var ghost_z_offset: int = -1

# Cacheado em _on_initialized via fighter.
var sprite: AnimatedSprite2D

# Tween dedicado pro flash e pro pulse de carga — matados antes de iniciar outro pra evitar sobreposição.
var _flash_tween: Tween
var _charge_tween: Tween

func _on_initialized() -> void:
	if not fighter: return
	sprite = fighter.get_node_or_null("AnimatedSprite2D")

# ==========================================
# 1. FLASH (modulate temporário no fighter)
# ==========================================
# Pinta o fighter com a cor do `type` (cancel/counter/buster/charge/white)
# e faz tween de volta pro branco em `duration` segundos.
func play_flash(type: String, duration: float = 0.15) -> void:
	if not fighter: return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	var color: Color = COLORS.get(type, COLORS.white)
	fighter.modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(fighter, "modulate", Color.WHITE, duration)

# ==========================================
# 2. GHOST (afterimage do frame atual)
# ==========================================
# Spawna uma cópia do AnimatedSprite2D na cena raiz, semi-transparente,
# que esmaece em `lifetime` segundos.
func spawn_ghost(type: String = "cancel", lifetime: float = 0.2) -> void:
	if not sprite or not sprite.sprite_frames: return

	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = sprite.sprite_frames
	ghost.animation = sprite.animation
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.z_index = sprite.z_index + ghost_z_offset

	var base_color: Color = COLORS.get(type, Color.WHITE)
	base_color.a = 0.6
	ghost.modulate = base_color

	get_tree().current_scene.add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.tween_callback(ghost.queue_free)

# ==========================================
# 3. HIT SPARK & BLOCK SPARK (faíscas de impacto)
# ==========================================
# Spawna a `hit_spark_scene` (PackedScene atribuída no Inspector) ou cria efeito
# procedural limpo caso não haja cena atribuída.
func spawn_hit_spark(contact_point: Vector2, is_heavy: bool = false) -> void:
	var scene_root := get_tree().current_scene
	if not scene_root: return

	if hit_spark_scene:
		var spark = hit_spark_scene.instantiate()
		scene_root.add_child(spark)
		spark.global_position = contact_point
		if is_heavy:
			spark.modulate = COLORS["counter"]
			spark.scale = Vector2(1.5, 1.5)
		return

	_spawn_procedural_hit_spark(scene_root, contact_point, is_heavy)

func spawn_block_spark(contact_point: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if not scene_root: return

	var root := Node2D.new()
	root.global_position = contact_point
	root.z_index = 20

	var shield := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(12):
		var ang: float = (TAU / 12.0) * i
		var rx: float = 18.0 if i % 2 == 0 else 28.0
		pts.append(Vector2(cos(ang) * rx, sin(ang) * 44.0))
	shield.polygon = pts
	shield.color = Color(0.35, 0.85, 2.0, 0.9)
	root.add_child(shield)
	root.scale = Vector2(0.45, 0.45)

	scene_root.add_child(root)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2(1.45, 1.45), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(root.queue_free)

func _spawn_procedural_hit_spark(scene_root: Node, contact_point: Vector2, is_heavy: bool) -> void:
	var root := Node2D.new()
	root.global_position = contact_point
	root.rotation = randf_range(0.0, TAU)
	root.z_index = 20

	var star := Polygon2D.new()
	var star_pts := PackedVector2Array()
	var points_count := 16
	for i in range(points_count):
		var ang: float = (TAU / float(points_count)) * i
		var r: float = 48.0 if i % 2 == 0 else 14.0
		star_pts.append(Vector2(cos(ang) * r, sin(ang) * r))
	star.polygon = star_pts
	star.color = Color(2.4, 0.45, 0.25, 1.0) if is_heavy else Color(2.2, 1.4, 0.3, 1.0)

	var core := Polygon2D.new()
	var core_pts := PackedVector2Array()
	for i in range(10):
		var ang: float = (TAU / 10.0) * i
		core_pts.append(Vector2(cos(ang) * 16.0, sin(ang) * 16.0))
	core.polygon = core_pts
	core.color = Color(2.5, 2.5, 2.5, 1.0)

	root.add_child(star)
	root.add_child(core)

	var start_scale: float = 0.45 if is_heavy else 0.30
	var end_scale: float = 2.15 if is_heavy else 1.65
	root.scale = Vector2(start_scale, start_scale)
	scene_root.add_child(root)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "scale", Vector2(end_scale, end_scale), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(root.queue_free)

# ==========================================
# 4. COMBOS PRONTOS
# ==========================================
# Flash + ghost azul: bom pra cancels de tier (LP→HP, etc.)
func play_cancel_fx() -> void:
	play_flash("cancel")
	spawn_ghost("cancel")

# Flash + ghost dourado: bom pra disparo de super/buster.
func play_buster_fx() -> void:
	play_flash("buster")
	spawn_ghost("buster")

# Pulso de carga por tier (vindo do SpecialMechanicComponent.classify_charge):
# - "normal" → azul claro (carga inicial)
# - "strong" → verde   (estágio 2)
# - "super"  → vermelho (estágio 3)
# Pulsa: seta cor + tween de volta pro branco em `duration` segundos.
# Mata o tween anterior pra cada pulse ficar visível na cor correta sem sobreposição.
func play_charge_pulse(tier: String = "normal", duration: float = 0.45) -> void:
	if not fighter: return
	var color_key := "charge_normal"
	if tier == "strong":
		color_key = "charge_strong"
	elif tier == "super":
		color_key = "charge_super"
	var color: Color = COLORS.get(color_key, COLORS.white)

	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
	fighter.modulate = color
	_charge_tween = create_tween()
	_charge_tween.tween_property(fighter, "modulate", Color.WHITE, duration)

# Restaura o modulate do fighter pro branco. Chamar ao soltar o botão de carga.
func clear_charge_pulse() -> void:
	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
	if fighter:
		fighter.modulate = Color.WHITE

# Pulso genérico com cor arbitrária (em vez dos tiers normal/strong/super).
# Útil pra states que querem cor única própria (MeterCharge = roxo, p.ex.).
# Compartilha o _charge_tween — clear_charge_pulse zera tudo igual.
func play_color_pulse(color: Color, duration: float = 0.45) -> void:
	if not fighter:
		return
	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
	fighter.modulate = color
	_charge_tween = create_tween()
	_charge_tween.tween_property(fighter, "modulate", Color.WHITE, duration)
