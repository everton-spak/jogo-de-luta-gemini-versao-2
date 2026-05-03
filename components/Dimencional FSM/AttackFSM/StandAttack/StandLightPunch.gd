class_name StandLightPunch
extends State

@export var animation_name: String = "lp_close"
@export var recovery_state: String = "IdleState"

func _ready() -> void:
	type_dim = "punch"
	strength_dim = "light"

# 1. Mudamos para _on_enter (padrão da sua StateMachine)
func enter(_payload: Dictionary = {}) -> void:
	# 2. TRAVA O DESLIZE: Para o boneco imediatamente
	if fighter:
		fighter.velocity = Vector2.ZERO
	
	if anim:
		anim.play(animation_name)

func physics_update(_delta: float) -> void:
	if anim and anim.has_method("is_playing"):
		if not anim.is_playing():
			# Isto vai mostrar no console qual é o valor real da variável
			#print("🛑 [Debug] Valor exato de recovery_state: '", recovery_state, "'")
			
			# Trava absoluta: Se estiver vazio, força o texto manualmente
			var estado_alvo = recovery_state
			if estado_alvo == "" or estado_alvo == " ":
				estado_alvo = "IdleState"
				
			transition_requested.emit(estado_alvo, {})
