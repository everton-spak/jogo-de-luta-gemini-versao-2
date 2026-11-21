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

var _hit_targets: Array = []

func _on_initialized() -> void:
	super._on_initialized() 
	disable_box() 
	if area_2d and not area_2d.area_entered.is_connected(_on_area_entered):
		area_2d.area_entered.connect(_on_area_entered)

func enable_box() -> void:
	_hit_targets.clear()
	super.enable_box()

func _resolve_target_box(area: Area2D) -> Component:
	var p := area.get_parent()
	if p == null:
		return null
	if p is HurtboxComponent or p is ThrowHurtboxComponent:
		return p
	if p is CharacterBody2D and p.has_method("get_component"):
		if not is_throw:
			var hb = p.get_component("HurtboxComponent")
			if hb is HurtboxComponent and hb.area_2d == area:
				return hb
		else:
			var thb = p.get_component("ThrowHurtboxComponent")
			if thb is ThrowHurtboxComponent and thb.area_2d == area:
				return thb
	return null

func _on_area_entered(area: Area2D) -> void:
	var target_box = _resolve_target_box(area)
	if target_box == null:
		return
	# Nunca acerta o próprio lutador nem acerta o mesmo alvo duas vezes na mesma ativação.
	if target_box.fighter == fighter or target_box in _hit_targets:
		return

	var is_valid_hit = false
	# 1. Verifica se a colisão é válida (Golpe Normal vs Agarrão)
	if not is_throw and target_box is HurtboxComponent:
		is_valid_hit = true
	elif is_throw and target_box is ThrowHurtboxComponent:
		is_valid_hit = true
		
	if not is_valid_hit:
		return

	# Ignora alvo invencível ou já em KO (não aplica hitstop nem confirma hit).
	if target_box.fighter:
		var target_fsm = target_box.fighter.get_component("StateMachine")
		if target_fsm:
			var target_tags: Array[String] = target_fsm.get_tags()
			if "Invincible" in target_tags or "KO" in target_tags:
				return

	_hit_targets.append(target_box)

	var my_pos = area_2d.global_position if area_2d else Vector2.ZERO
	var target_pos = area.global_position
	var contact_point = (my_pos + target_pos) / 2.0
	
	# Congela o atacante (quando golpe corpo-a-corpo) e notifica CancelComponent
	var is_melee := (get_parent() is Component)
	if fighter and is_melee:
		var my_hitstop = fighter.get_component("HitstopComponent")
		if my_hitstop:
			my_hitstop.start_hitstop(hitstop_duration)
		var my_cancel = fighter.get_component("CancelComponent")
		if my_cancel and my_cancel.has_method("confirm_hit"):
			my_cancel.confirm_hit()
	
	attack_connected.emit(target_box, contact_point)
