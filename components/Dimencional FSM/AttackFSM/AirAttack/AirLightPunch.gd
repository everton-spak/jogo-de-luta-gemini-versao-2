class_name AirLightPunch
extends State

@export var animation_name: String = "lp_air"

func _ready() -> void:
	stance_dim = "air"
	type_dim = "punch"
	strength_dim = "light"

func enter(_payload: Dictionary = {}) -> void:
	# No ar, mantemos o momentum — NÃO zeramos a velocidade
	if anim:
		anim.play(animation_name)

func physics_update(_delta: float) -> void:
	# Quando a animação terminar, volta para o FallState
	# (O AirAttack FSM já cuida da gravidade e da aterrissagem)
	if anim and anim.has_method("is_playing"):
		if not anim.is_playing():
			transition_requested.emit("FallState", {})
