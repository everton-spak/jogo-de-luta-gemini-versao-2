class_name ProximityBoxComponent
extends BoxComponent

# Sinais para avisar a StateMachine ou outros componentes instantaneamente
signal target_entered(target_fighter: CharacterBody2D)
signal target_exited(target_fighter: CharacterBody2D)

# Variáveis de estado fáceis de consultar a qualquer momento
var is_target_near: bool = false
var current_target: CharacterBody2D = null

func _on_initialized() -> void:
	super._on_initialized() # Garante que o Area2D foi capturado pelo pai
	
	# A caixa de proximidade geralmente fica ligada o tempo todo
	enable_box() 
	
	# Conecta os sinais de entrada e saída
	area_2d.area_entered.connect(_on_area_entered)
	area_2d.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	var box = area.get_parent()
	
	# Deteta se quem entrou na nossa área foi a Hurtbox de OUTRO lutador
	if box is HurtboxComponent and box.fighter != self.fighter:
		is_target_near = true
		current_target = box.fighter
		target_entered.emit(current_target)

func _on_area_exited(area: Area2D) -> void:
	var box = area.get_parent()
	
	# Confirma se quem saiu foi o lutador que estávamos a rastrear
	if box is HurtboxComponent and box.fighter == current_target:
		is_target_near = false
		current_target = null
		target_exited.emit(box.fighter)
