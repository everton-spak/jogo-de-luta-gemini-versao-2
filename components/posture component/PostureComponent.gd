class_name PostureComponent
extends Component

# Geometria da postura do fighter (stand/crouch/air): tamanho+posição do
# collider principal e offset do sprite. Antes vivia no Fighter; extraído pra
# ele ficar como orquestrador puro (FSM/input/tick).
#
# Consumidores:
#   - AttackStateBase._ensure_posture() — sincroniza postura no início do golpe.
#   - CrouchHeavyPunch — temporariamente sobe pra "stand" no startup, lê/escreve
#     sprite_y por frame pra prender os pés no chão.

@export_group("Stand")
@export var stand_size: Vector2 = Vector2(60, 120)
@export var stand_pos: Vector2 = Vector2(0, -60)

@export_group("Crouch")
@export var crouch_size: Vector2 = Vector2(60, 70)
@export var crouch_pos: Vector2 = Vector2(0, -35)

@export_group("Air")
@export var air_size: Vector2 = Vector2(60, 100)
@export var air_pos: Vector2 = Vector2(0, -50)

@export_group("Sprite")
# Ajuste fino do Y do sprite aplicado SEMPRE ao trocar de postura (não muda o offset base).
@export var sprite_y_adjustment: float = 0.0

# Refs achadas no _on_initialized; cacheadas pra evitar lookup repetido.
var collider: CollisionShape2D
var sprite: AnimatedSprite2D
# Diferença sprite-collider capturada no início; aplicada como offset constante.
var _sprite_offset: Vector2 = Vector2.ZERO

func _on_initialized() -> void:
	if not fighter:
		return
	collider = fighter.get_node_or_null("CollisionShape2D") as CollisionShape2D
	sprite = fighter.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and collider:
		_sprite_offset = sprite.position - collider.position

# Troca a postura: ajusta o collider e reposiciona o sprite pra manter o offset.
# Aceita "stand", "crouch", "air" — qualquer outro valor cai em "stand".
func apply(posture: String) -> void:
	if not collider or not collider.shape is RectangleShape2D:
		return

	# Garante que a shape é única desta instância (evita compartilhar entre fighters).
	if collider.shape.resource_local_to_scene == false:
		collider.shape = collider.shape.duplicate()
		collider.shape.resource_local_to_scene = true

	match posture:
		"crouch":
			collider.shape.size = crouch_size
			collider.position = crouch_pos
		"air":
			collider.shape.size = air_size
			collider.position = air_pos
		_:
			collider.shape.size = stand_size
			collider.position = stand_pos

	if sprite:
		sprite.position = collider.position + _sprite_offset + Vector2(0, sprite_y_adjustment)

func get_sprite_y() -> float:
	return sprite.position.y if sprite else 0.0

func set_sprite_y(y: float) -> void:
	if sprite:
		sprite.position.y = y
