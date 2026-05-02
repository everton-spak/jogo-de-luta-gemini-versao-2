class_name RunMove
extends MoveComponent

@export_group("Comandos de Corrida")
# Deixa vazio ("") se não quiseres usar um botão dedicado
@export var run_button_action: String = "" 
# A clássica sequência de duplo-toque
@export var run_sequence: Array[String] = ["F", "F"] 

@export_group("Estado Alvo")
@export var target_run_state: String = "RunState"

var dynamic_target_state: String = ""

func check_execution(buffer: InputBuffer) -> bool:
	
	# 1. Tenta a Corrida por Botão Dedicado (Ex: Segurar R2/RT)
	if run_button_action != "" and buffer.input and buffer.input.is_action_pressed(run_button_action):
		# Se o jogador também estiver a segurar para a frente, corre!
		var dir = buffer.input.get_movement_direction().x
		var facing_dir = buffer.facing_component.current_facing if buffer.facing_component else 1.0
		
		# Só corre se estiver a apertar na mesma direção que está virado
		if sign(dir) == sign(facing_dir):
			_prepare_transition(target_run_state)
			print("🏃 CORRIDA (BOTÃO) DETETADA!")
			return true

	# 2. Tenta a Corrida por Duplo-Toque (Frente, Frente)
	if not run_sequence.is_empty() and buffer.is_sequence_buffered(run_sequence):
		buffer.consume_sequence()
		_prepare_transition(target_run_state)
		print("🏃 CORRIDA (DUPLO-TOQUE) DETETADA!")
		return true

	return false

func _prepare_transition(target_node_name: String) -> void:
	dynamic_target_state = target_node_name
