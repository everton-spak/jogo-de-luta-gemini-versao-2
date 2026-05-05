class_name BoxComponent
extends Component

@export_group("Nós Físicos")
## Arraste o Area2D que está dentro deste componente para cá no Inspector
@export var area_2d: Area2D 

var collision_shape: CollisionShape2D

func _on_initialized() -> void:
	if area_2d:
		# Busca dinamicamente a forma de colisão (CollisionShape2D) dentro do Area2D
		for child in area_2d.get_children():
			if child is CollisionShape2D:
				collision_shape = child
				break
				
		if not collision_shape:
			push_warning(name + ": CollisionShape2D não encontrado dentro do Area2D!")
	else:
		push_warning(name + ": Area2D não atribuído no Inspector!")

# Funções universais para o AnimationPlayer ou Estados chamarem
func enable_box() -> void:
	if collision_shape:
		collision_shape.disabled = false

func disable_box() -> void:
	if collision_shape:
		collision_shape.disabled = true
	
# Função útil para checar se a caixa está ativa
func is_active() -> bool:
	if collision_shape:
		return not collision_shape.disabled
	return false
