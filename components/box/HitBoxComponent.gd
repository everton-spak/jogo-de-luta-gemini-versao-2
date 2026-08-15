class_name HitboxComponent
extends BoxComponent

signal attack_connected(target_box: Component, contact_point: Vector2)

@export_group("Dados do Ataque")
@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(300, -150)
@export var hitstun_duration: float = 0.3
@export var hitstop_duration: float = 0.1 
@export var is_throw: bool = false 
## "high" (defende em pé), "low" (defende agachado), "mid" (qualquer defesa)
@export var attack_level: String = "mid" 

func _on_initialized() -> void:
	super._on_initialized() 
	disable_box() 
	if area_2d and not area_2d.area_entered.is_connected(_on_area_entered):
		area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var target_box = area.get_parent()
	var is_valid_hit = false
	
	# 1. Verifica se a colisão é válida (Golpe Normal vs Agarrão)
	if not is_throw and target_box is HurtboxComponent:
		is_valid_hit = true
	elif is_throw and target_box is ThrowHurtboxComponent:
		is_valid_hit = true
		
	# 2. Se for um acerto válido, emite o sinal e aplica Hitstop
	if is_valid_hit:
		var my_pos = area_2d.global_position
		var target_pos = area.global_position
		var contact_point = (my_pos + target_pos) / 2.0
		
		# Congela o atacante e notifica CancelComponent
		if fighter:
			var my_hitstop = fighter.get_component("HitstopComponent")
			if my_hitstop:
				my_hitstop.start_hitstop(hitstop_duration)
			var my_cancel = fighter.get_component("CancelComponent")
			if my_cancel and my_cancel.has_method("confirm_hit"):
				my_cancel.confirm_hit()
		
		attack_connected.emit(target_box, contact_point)
