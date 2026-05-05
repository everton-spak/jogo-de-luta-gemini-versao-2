class_name ThrowHurtboxComponent
extends BoxComponent

func _on_initialized() -> void:
	super._on_initialized()
	if area_2d:
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hit_node = area.get_parent()
	
	if hit_node is HitboxComponent and hit_node.is_throw:
		if not fighter: return
		var main_fsm = fighter.get_component("StateMachine")
		
		if main_fsm:
			# Passa a responsabilidade de roteamento para a FSM com uma Query
			var payload = {
				"hit_data": {
					"attacker": hit_node.fighter
				},
				"query": {
					"type": "grabbed",
					"stance": "any",
					"direction": "any"
				}
			}
			main_fsm.enter(payload)
			
		# Desliga imediatamente as caixas para não tomarmos golpes duplos
		disable_box()
		var hurtbox = fighter.get_component("HurtboxComponent")
		if hurtbox:
			hurtbox.disable_box()
