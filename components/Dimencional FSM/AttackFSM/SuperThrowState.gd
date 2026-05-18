class_name SuperThrowState
extends AttackStateBase

# Disparado quando o jogador cancela um Heavy Hadouken segurando HP + apertando LK,
# E o oponente está perto o suficiente (ProximityBoxComponent.is_target_near).
# Se estiver longe, ProjectileAttackState cancela direto pra IdleState/FallState.
#
# Só existe a variante de PERTO — não há super_throw_far. O check de proximidade
# já filtra o caso "longe" antes de chegar aqui, então só playamos animation_name.

func _init() -> void:
	# TODO: trocar pelo nome real da animação no SpriteFrames
	animation_name = "super_throw_close"
	hitbox_offset = Vector2(60, -80)
	hitbox_size = Vector2(50, 50)

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "super_throw"
	cancel_tier_dim = 4 # tier máximo (super)
	recovery_state = "IdleState"
