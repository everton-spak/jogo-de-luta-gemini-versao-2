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
	"charge_normal": Color(0.8, 1.0, 2.2), # Azul médio (carga estágio 1)
	"charge_strong": Color(2.0, 2.0, 0.5), # Verde médio (carga estágio 2)
	"charge_super": Color(2.0, 0.5, 0.5),  # Vermelho médio (carga estágio 3)
	"white": Color.WHITE,
}

@export var hit_spark_scene: PackedScene
# Ghost por padrão fica atrás do sprite real (z_index = sprite.z_index + offset)
@export var ghost_z_offset: int = -1

# Cacheado em _on_initialized via fighter.
var sprite: AnimatedSprite2D

# Tween dedicado pro pulse de carga — matado a cada novo pulse pra evitar sobreposição.
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
	var color: Color = COLORS.get(type, COLORS.white)
	fighter.modulate = color
	var tween := create_tween()
	tween.tween_property(fighter, "modulate", Color.WHITE, duration)

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
# 3. HIT SPARK (faísca de impacto)
# ==========================================
# Spawna a `hit_spark_scene` (PackedScene atribuída no Inspector) numa posição global.
# is_heavy = true tinge de vermelho e aumenta a escala.
func spawn_hit_spark(contact_point: Vector2, is_heavy: bool = false) -> void:
	if not hit_spark_scene: return

	var spark = hit_spark_scene.instantiate()
	get_tree().current_scene.add_child(spark)
	spark.global_position = contact_point

	if is_heavy:
		spark.modulate = COLORS["counter"]
		spark.scale = Vector2(1.5, 1.5)

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
