class_name VFXComponent
extends Component

#@onready var fighter: CharacterBody2D = owner
@onready var sprite: Sprite2D = owner.get_node("Sprite2D")

# NOVA VARIÁVEL: Arraste a sua cena de faísca (ex: vfx_spark.tscn) para aqui no Inspetor
@export var hit_spark_scene: PackedScene 

# Cores pré-definidas para consistência visual
const COLORS = {
	"cancel": Color(0.0, 2.0, 5.0),    # Azul Neon (HDR)
	"counter": Color(5.0, 0.0, 0.0),   # Vermelho Intenso
	"buster": Color(5.0, 3.0, 0.0),    # Dourado/Laranja
	"white": Color.WHITE
}

# 1. Efeito de Brilho (Flash)
func play_flash(type: String, duration: float = 0.15):
	var color = COLORS.get(type, COLORS.white)
	fighter.modulate = color
	
	var tween = create_tween()
	tween.tween_property(fighter, "modulate", Color.WHITE, duration)

# 2. Efeito de Rastro (Ghost/Afterimage)
func spawn_ghost(type: String = "cancel", lifetime: float = 0.2):
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = fighter.global_position
	
	# Cor do fantasma baseada no tipo
	var base_color = COLORS.get(type, Color.WHITE)
	base_color.a = 0.6 # Transparência
	ghost.modulate = base_color
	
	# Adiciona à cena (Root) para o fantasma não seguir o player
	get_tree().current_scene.add_child(ghost)
	
	# Animação de sumiço
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, lifetime)
	tween.tween_callback(ghost.queue_free)

# 3. Efeito Combinado de Cancelamento
func play_cancel_fx():
	play_flash("cancel")
	spawn_ghost("cancel")

# ==========================================
# 4. EFEITOS DE IMPACTO (NOVO!)
# ==========================================
func spawn_hit_spark(contact_point: Vector2, is_heavy: bool = false) -> void:
	if not hit_spark_scene: return
	
	var spark = hit_spark_scene.instantiate()
	get_tree().current_scene.add_child(spark)
	
	# Coloca a faísca exatamente no ponto central da colisão
	spark.global_position = contact_point
	
	# Se for um Heavy Hit, reusa a sua cor "counter" e aumenta a escala!
	if is_heavy:
		spark.modulate = COLORS["counter"]
		spark.scale = Vector2(1.5, 1.5)
