class_name KOState
extends State

# HP zerou. Estado TERMINAL — não há recovery automático (cabe ao gerenciador de
# round resetar a FSM). Trava input via tier 99 (acima de qualquer ataque possível).

@export_group("Animações")
@export var anim_launch: String = "ko_fall"      # caindo após o golpe final
@export var anim_grounded: String = "ko_grounded" # deitado no chão (loop)

@export_group("Física")
@export var launch_velocity_y: float = -600.0
@export var friction: float = 800.0

var _on_ground: bool = false

func _ready() -> void:
	type_dim = "ko"
	stance_dim = "any"
	react_dim = "any"
	cancel_tier_dim = 99 # inquebrável

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	var hit_data: Dictionary = payload.get("hit_data", {})
	_on_ground = false

	# Launch dramatic: knockback_x do payload + launch_velocity_y fixo pra cima.
	if fighter:
		fighter.velocity.x = float(hit_data.get("knockback_x", 0.0))
		fighter.velocity.y = launch_velocity_y

	# Hit spark dramático.
	if vfx and fighter:
		vfx.spawn_hit_spark(fighter.global_position + Vector2(0, -60), true)

	if anim:
		anim.play(anim_launch)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if not fighter:
		return

	# Friction horizontal.
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, friction * delta)

	if not _on_ground:
		# Caindo: aplica gravidade.
		if movement:
			movement.apply_gravity(delta)
		if fighter.is_on_floor():
			_on_ground = true
			fighter.velocity = Vector2.ZERO
			if anim:
				anim.play(anim_grounded)
	# Terminal: nunca emite transition_requested.

func get_tags() -> Array[String]:
	return ["KO"]
