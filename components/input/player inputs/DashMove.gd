class_name DashMove
extends MoveComponent

# Configuração da Macro: Soco Fraco + Chute Fraco
# (O InputBuffer deve ter um alias ou verificamos os dois botões)
@export var macro_buttons: Array[String] = ["punch_light", "kick_light"]

#@export var target_state_name: String = "DashState"

var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

func check_execution(buffer: InputBuffer) -> bool:
	# 1. Verifica se os dois botões da macro foram apertados no mesmo intervalo (plinking)
	var pressed_macro = true
	for btn in macro_buttons:
		if not buffer.is_action_buffered(btn):
			pressed_macro = false
			break
	
	if pressed_macro:
		# Consome os inputs para não disparar outros golpes acidentalmente
		for btn in macro_buttons:
			buffer.consume_action(btn)
			
		# =========================================================
		# 2. DETEÇÃO DE DIREÇÃO (Frente ou Trás)
		# =========================================================
		var input_comp = buffer.input_provider
		var facing_comp = buffer.fighter.get_component("FacingComponent")
		
		var move_dir = 0.0
		if input_comp:
			move_dir = input_comp.get_movement_direction().x
		
		# Se não houver direção na alavanca, assume Dash para frente por padrão
		if move_dir == 0.0 and facing_comp:
			move_dir = facing_comp.current_facing
			
		# Injeta a direção no Payload
		payload_to_inject.clear()
		dynamic_target_state = target_state_name
		payload_to_inject["direction"] = move_dir
		
		return true
		
	return false
