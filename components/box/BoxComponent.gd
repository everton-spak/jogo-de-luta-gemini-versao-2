class_name BoxComponent
extends Component

@export_group("Nós Físicos")
## Arraste o Area2D que está dentro deste componente para cá no Inspector
@export var area_2d: Area2D 

var collision_shape: CollisionShape2D

func _on_initialized() -> void:
	if area_2d:
		# Busca dinamicamente a forma de colisão (CollisionShape2D) dentro do Area2D
		for child in area_2d.get_children():
			if child is CollisionShape2D:
				collision_shape = child
				break
				
		if not collision_shape:
			push_warning(name + ": CollisionShape2D não encontrado dentro do Area2D!")
	else:
		push_warning(name + ": Area2D não atribuído no Inspector!")

# Funções universais para o AnimationPlayer ou Estados chamarem
func enable_box() -> void:
	if collision_shape:
		collision_shape.disabled = false

func disable_box() -> void:
	if collision_shape:
		collision_shape.disabled = true
	
# Função útil para checar se a caixa está ativa
func is_active() -> bool:
	if collision_shape:
		return not collision_shape.disabled
	return false

# ==========================================
# INVINCIBILIDADE (i-frames)
# Invuln = box desligado por N segundos e re-ligado automaticamente.
# Reusa o enable_box/disable_box; quem chama é qualquer state (DashState, DodgeState,
# ShoryukenLight/Heavy, KnockdownState futuro, super freeze). Cada caller pode passar
# uma `source` pra debug ("dash"/"wakeup"/"super"/"parry").
#
# Pra "invuln total" (strike+throw) chame em AMBOS os boxes (HurtBox e ThrowHurtBox).
# Estados que ativam invuln devem TAMBÉM retornar "Invincible" em get_tags() pra
# consumidores externos (AI, cancel rules) saberem.
#
# Idempotência: chamar com janela menor durante uma maior NÃO encurta — o max vence.
# Cancelamento: cancel_invuln() restaura o estado do box que existia ANTES do invuln
# (não re-liga box que já estava off por outra razão).
# ==========================================

var _invuln_time_remaining: float = 0.0
var _invuln_source: String = ""
var _box_was_active_before_invuln: bool = true

func start_invuln(duration_sec: float, source: String = "") -> void:
	if duration_sec <= 0.0:
		return
	if _invuln_time_remaining > 0.0:
		# Já em invuln — extende só se a nova janela for maior.
		_invuln_time_remaining = max(_invuln_time_remaining, duration_sec)
	else:
		_invuln_time_remaining = duration_sec
		_box_was_active_before_invuln = is_active()
		disable_box()
	_invuln_source = source

func cancel_invuln() -> void:
	if _invuln_time_remaining <= 0.0:
		return
	_invuln_time_remaining = 0.0
	_invuln_source = ""
	if _box_was_active_before_invuln:
		enable_box()

func is_invuln() -> bool:
	return _invuln_time_remaining > 0.0

func get_invuln_source() -> String:
	return _invuln_source

func _physics_process(delta: float) -> void:
	if _invuln_time_remaining <= 0.0:
		return
	_invuln_time_remaining -= delta
	if _invuln_time_remaining <= 0.0:
		_invuln_time_remaining = 0.0
		_invuln_source = ""
		if _box_was_active_before_invuln:
			enable_box()
