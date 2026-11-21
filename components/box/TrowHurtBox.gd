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
	if area_2d and not area_2d.area_entered.is_connected(_on_area_entered):
		area_2d.area_entered.connect(_on_area_entered)

func _resolve_throw_hitbox(area: Area2D) -> HitboxComponent:
	var p := area.get_parent()
	if p == null:
		return null
	if p is HitboxComponent and p.is_throw and p.is_active():
		return p
	if p is CharacterBody2D and p.has_method("get_component"):
		var hb = p.get_component("HitboxComponent")
		if hb is HitboxComponent and hb.area_2d == area and hb.is_throw and hb.is_active():
			return hb
	return null

func _on_area_entered(area: Area2D) -> void:
	var hit_node := _resolve_throw_hitbox(area)
	if hit_node == null or not fighter or hit_node.fighter == fighter:
		return

	var main_fsm = fighter.get_component("StateMachine")
	if not main_fsm:
		return

	var tags: Array[String] = main_fsm.get_tags()
	if "Invincible" in tags or "KO" in tags or "Knockdown" in tags or "Thrown" in tags or "TechRecovery" in tags:
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

	# Invuln temporária deferred pra evitar erro durante flush de sinais da Area2D.
	call_deferred("start_invuln", 0.55, "thrown")
	var hurtbox = fighter.get_component("HurtboxComponent")
	if hurtbox and hurtbox.has_method("start_invuln"):
		hurtbox.call_deferred("start_invuln", 0.55, "thrown")

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
