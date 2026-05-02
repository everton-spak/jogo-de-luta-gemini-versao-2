class_name HealthComponent
extends Component

signal health_changed(new_health: int, max_health: int)
signal died

@export var max_health: int = 1000
var current_health: int

func _on_initialized() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clampi(current_health, 0, max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_health += amount
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)
