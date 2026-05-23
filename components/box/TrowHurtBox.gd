class_name ThrowHurtboxComponent
extends BoxComponent

# Recebe agarrões (hitbox.is_throw=true). Antes de virar grab, checa janela de
# THROW TECH: se o defensor apertou LP+LK nos últimos `throw_tech_window_msec`,
# rola pra ThrowTechState em vez de ThrownState.
#
# Query inclui "react": "yes" pra rotear pra HurtFSM corretamente.

@export var throw_tech_window_msec: int = 117 # ~7 frames a 60fps

func _on_initialized() -> void:
	super._on_initialized()
	if area_2d:
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hit_node = area.get_parent()
	if not (hit_node is HitboxComponent and hit_node.is_throw):
		return
	if not fighter:
		return

	var main_fsm = fighter.get_component("StateMachine")
	if not main_fsm:
		return

	# Throw-tech: LP+LK ambos no buffer recente → escape.
	var target_type: String = "throw_tech" if _detect_throw_tech() else "grabbed"

	var payload := {
		"hit_data": {
			"attacker": hit_node.fighter,
		},
		"query": {
			"type": target_type,
			"stance": "any",
			"direction": "any",
			"react": "yes",
		}
	}
	main_fsm.enter(payload)

	# Desliga as duas caixas pra evitar double-hit.
	disable_box()
	var hurtbox = fighter.get_component("HurtboxComponent")
	if hurtbox:
		hurtbox.disable_box()

func _detect_throw_tech() -> bool:
	var input_buffer = fighter.get_component("InputBufferComponent")
	if not input_buffer or not input_buffer.history:
		return false
	var history = input_buffer.history
	# Ambos botões precisam estar buffered dentro da janela curta.
	# Tipo explícito (não :=) porque history vem como Variant da prop do InputBuffer.
	var lp_recent: bool = history.is_action_buffered("punch_light", throw_tech_window_msec)
	var lk_recent: bool = history.is_action_buffered("kick_light", throw_tech_window_msec)
	return lp_recent and lk_recent
