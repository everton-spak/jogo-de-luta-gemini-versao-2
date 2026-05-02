class_name BoxComponent
extends Component

@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _on_initialized() -> void:
	# Por padrão, vamos garantir que a configuração do editor seja respeitada,
	# mas você pode forçar disable_box() aqui se quiser que todas comecem desligadas.
	pass

# Funções universais para o AnimationPlayer ou Estados chamarem
func enable_box() -> void:
	collision_shape.disabled = false

func disable_box() -> void:
	collision_shape.disabled = true
	
# Função útil para checar se a caixa está ativa
func is_active() -> bool:
	return not collision_shape.disabled
