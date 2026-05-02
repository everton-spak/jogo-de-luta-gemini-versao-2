class_name BarComponent
extends Component

# Sinais universais. A Interface (UI) ou a FSM vão ouvir isto!
signal value_changed(current_value: float, max_value: float)
signal depleted() # Dispara quando chega a zero (Ex: Morreu, ou Quebrou a Defesa)
signal filled()   # Dispara quando chega ao máximo (Ex: Barra de Especial cheia)

@export_group("Resource Settings")
# O nome ajuda a debugar e a procurar componentes específicos
@export var resource_name: String = "Resource" 
@export var max_value: float = 100.0
# A barra começa cheia (Vida/Defesa) ou vazia (Especial)?
@export var start_full: bool = true 

var current_value: float = 0.0

func _on_initialized() -> void:
	super._on_initialized()
	
	# Define o valor inicial com base na configuração
	current_value = max_value if start_full else 0.0
	
	# Emite o sinal inicial para a Interface (UI) desenhar a barra corretamente no frame 1
	value_changed.emit(current_value, max_value)

# ==========================================
# ➕ ADICIONAR RECURSO (Curar, Ganhar Magia)
# ==========================================
func add(amount: float) -> void:
	if current_value >= max_value: 
		return # Já está cheio, não faz nada
		
	current_value += amount
	
	# Trava no limite máximo e avisa se encheu
	if current_value >= max_value:
		current_value = max_value
		filled.emit()
		
	value_changed.emit(current_value, max_value)

# ==========================================
# ➖ SUBTRAIR RECURSO (Levar Dano, Gastar Magia)
# ==========================================
func subtract(amount: float) -> void:
	if current_value <= 0.0: 
		return # Já está vazio, não faz nada
		
	current_value -= amount
	
	# Trava no zero e avisa se esgotou
	if current_value <= 0.0:
		current_value = 0.0
		depleted.emit()
		
	value_changed.emit(current_value, max_value)

# ==========================================
# 🔍 VERIFICAÇÕES (Para a Máquina de Estados)
# ==========================================
func has_enough(amount: float) -> bool:
	return current_value >= amount

# Retorna de 0.0 a 1.0 (Ótimo para barras de progresso na UI)
func get_percentage() -> float:
	if max_value == 0: return 0.0
	return current_value / max_value
