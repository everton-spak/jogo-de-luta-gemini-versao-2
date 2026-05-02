class_name ThrowHurtboxComponent
extends BoxComponent

func _on_initialized() -> void:
	super._on_initialized()
	area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var hit_node = area.get_parent()
	
	# Só aceita Hitboxes marcadas como agarrão (is_throw = true)
	if hit_node is HitboxComponent and hit_node.is_throw:
		
		# 1. Avisa a StateMachine que fomos agarrados!
		var main_fsm = get_component("MainStateMachine")
		if main_fsm:
			# Passamos o lutador atacante no payload para a nossa animação de ser jogado
			# saber a posição exata de quem nos agarrou!
			var payload = {"attacker": hit_node.fighter}
			main_fsm.change_state("GrabbedState", payload)
			
		# 2. Desliga imediatamente as nossas próprias caixas para não tomarmos golpes duplos
		disable_box()
		var hurtbox = get_component("HurtboxComponent")
		if hurtbox:
			hurtbox.disable_box()
