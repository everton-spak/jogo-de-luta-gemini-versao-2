class_name HitboxComponent
extends BoxComponent

# ATUALIZAÇÃO: O sinal agora carrega o alvo atingido e a coordenada do impacto (VFX)
signal attack_connected(target_box: Component, contact_point: Vector2)

@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(300, -150)
@export var hitstun_duration: float = 0.3
@export var hitstop_duration: float = 0.1 # <-- NOVA VARIÁVEL (100ms)
@export var is_throw: bool = false 

func _on_initialized() -> void:
	super._on_initialized() 
	disable_box() 
	area_2d.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	var target_box = area.get_parent()
	var is_valid_hit = false
	
	# 1. Verifica se a colisão é válida (Golpe Normal vs Agarrão)
	if not is_throw and target_box is HurtboxComponent:
		is_valid_hit = true
	elif is_throw and target_box is ThrowHurtboxComponent:
		is_valid_hit = true
		
	# 2. Se for um acerto válido, calcula o Ponto de Impacto e emite o sinal!
	if is_valid_hit:
		# Pega a posição da NOSSA área e da área do ALVO
		var my_pos = area_2d.global_position
		var target_pos = area.global_position
		
		# Calcula o meio exato entre as duas caixas para instanciar a faísca
		var contact_point = (my_pos + target_pos) / 2.0
		
		# 3. Congela quem bateu (O Atacante)
		var my_hitstop = fighter.get_component("HitstopComponent")
		if my_hitstop:
			my_hitstop.start_hitstop(hitstop_duration)
		
		#4. Dispara o sinal enviando os dados vitais para o AttackState
		attack_connected.emit(target_box, contact_point)
