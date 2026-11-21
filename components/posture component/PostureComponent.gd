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
var hurtbox_collider: CollisionShape2D
var throw_collider: CollisionShape2D
# Diferença sprite-collider capturada no início; aplicada como offset constante.
var _sprite_offset: Vector2 = Vector2.ZERO

func _on_initialized() -> void:
	if not fighter:
		return
	collider = fighter.get_node_or_null("CollisionShape2D") as CollisionShape2D
	sprite = fighter.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	hurtbox_collider = fighter.get_node_or_null("HurtboxArea/CollisionShape2D") as CollisionShape2D
	throw_collider = fighter.get_node_or_null("ThrowHurtboxArea/CollisionShape2D") as CollisionShape2D
	if sprite and collider:
		_sprite_offset = sprite.position - collider.position

# Troca a postura: ajusta o collider, hurtboxes e reposiciona o sprite pra manter o offset.
# Aceita "stand", "crouch", "air" — qualquer outro valor cai em "stand".
func apply(posture: String) -> void:
	if not collider or not collider.shape is RectangleShape2D:
		return

	var target_size: Vector2
	var target_pos: Vector2
	match posture:
		"crouch":
			target_size = crouch_size
			target_pos = crouch_pos
		"air":
			target_size = air_size
			target_pos = air_pos
		_:
			target_size = stand_size
			target_pos = stand_pos

	_apply_shape(collider, target_size, target_pos)
	_apply_shape(hurtbox_collider, target_size, target_pos)
	_apply_shape(throw_collider, Vector2(maxf(target_size.x - 10.0, 20.0), maxf(target_size.y - 15.0, 20.0)), target_pos)

	if sprite:
		sprite.position = collider.position + _sprite_offset + Vector2(0, sprite_y_adjustment)

func _apply_shape(col: CollisionShape2D, size: Vector2, pos: Vector2) -> void:
	if not col or not col.shape is RectangleShape2D:
		return
	if col.shape.resource_local_to_scene == false:
		col.shape = col.shape.duplicate()
		col.shape.resource_local_to_scene = true
	col.shape.size = size
	col.position = pos

func get_sprite_y() -> float:
	return sprite.position.y if sprite else 0.0

func set_sprite_y(y: float) -> void:
	if sprite:
		sprite.position.y = y
