class_name HybridDashState
extends AttackStateBase

# Disparado quando o jogador cancela um Light Hadouken segurando LP + apertando LK.
# Transição vinda de ProjectileAttackState.physics_update via SpecialMechanicComponent.check_macro().

@export var dash_speed: float = 500.0

func _init() -> void:
	# TODO: trocar pelo nome real da animação no SpriteFrames
	animation_name = "hybrid_dash"

func _ready() -> void:
	stance_dim = "ground"
	type_dim = "hybrid_dash"
	cancel_tier_dim = 3
	recovery_state = "IdleState"

# Sobrescreve o _ensure_posture do AttackStateBase pra usar collider de crouch
# (em vez do default "stand" que viria do stance_dim="ground").
func _ensure_posture() -> void:
	if posture: posture.apply("crouch")

# Sobrescreve o default do State (que zeraria a velocity por estar no chão).
# Dispara o avanço pra frente com base no facing.
func _apply_enter_velocity() -> void:
	var f_dir = facing.current_facing if facing else 1.0
	fighter.velocity = Vector2(dash_speed * f_dir, 0.0)
	# Pulse azul rápido (fade 0.15s) marcando o início do dash.
	if vfx: vfx.play_charge_pulse("normal", 0.15)

# Pulse rápido a cada 5 frames (~166ms) durante o dash.
func _during_active(_delta: float) -> void:
	if vfx and state_frames % 5 == 0:
		vfx.play_charge_pulse("normal", 0.1)
