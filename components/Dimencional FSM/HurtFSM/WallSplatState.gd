class_name WallSplatState
extends State

# PIN no muro (estilo Tekken): fighter colado na parede, sem gravidade, parado
# por `pin_duration_frames`. Atacante tem combo grátis garantido durante esse
# tempo. Hits durante TIRAM da WallSplat (transicionam pra Hurt/AirHurt normal),
# então o pin não é "inquebrável" — só dura até o próximo hit OU o timer.
#
# Trigger: WallSplatComponent detecta is_on_wall + velocity + tag e chama
# main_fsm.enter com query type="wall_splat".
#
# Saída (timer):
#   - HP <= 0 → KOState
#   - No chão → KnockdownState (já está colado no muro encostado no chão)
#   - No ar → FallState (cai naturalmente, gravidade volta)

@export var anim_name: String = "wall_splat"
# Duração do pin em frames. 18 = 0.3s @ 60fps — janela de combo curta mas garantida.
# Aumenta pra 24-30 se quiser combo mais longo. Diminui pra 12 se quiser sutil.
@export var pin_duration_frames: int = 18

func _ready() -> void:
	type_dim = "wall_splat"
	stance_dim = "any"
	react_dim = "any"
	cancel_tier_dim = 5
	recovery_state = "FallState" # fallback se nada mais bater

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	# Pin: zera velocity completamente.
	if fighter:
		fighter.velocity = Vector2.ZERO
	if anim:
		anim.play(anim_name)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Mantém velocity zerada cada frame — NÃO aplica gravidade. Fighter fica
	# literalmente preso no ponto de impacto.
	fighter.velocity = Vector2.ZERO

	if state_frames >= pin_duration_frames:
		# Sai do pin. KO > chão > ar.
		if health and health.current_health <= 0:
			transition_requested.emit("KOState", {})
		elif fighter.is_on_floor():
			transition_requested.emit("KnockdownState", {})
		else:
			# Volta pra Fall — gravidade kicka in, juggle pode continuar via novos hits.
			transition_requested.emit(recovery_state, {})

func get_tags() -> Array[String]:
	# "Hurt" pra herdar bloqueios de cancel; "WallSplat" pro WallSplatComponent
	# skipar re-detecção enquanto pinado.
	return ["Hurt", "WallSplat"]
