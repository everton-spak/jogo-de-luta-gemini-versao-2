class_name GroundedState
extends State

# Fase DEITADO: anim em loop até o player escolher (ou ser forçado a) wakeup.
# Lê input direto pra decidir o tipo:
#   - sem input → quick rise   (rápido, pouco invul)
#   - segura back → back rise  (médio, mais invul, recua)
#   - segura down → no tech    (lento, muito invul)
#
# A escolha é feita a cada frame; o que estiver pressionado quando o timer do
# tipo atual estoura é o que sai. Default é quick (timer mais curto).

@export var anim_grounded: String = "knockdown_grounded"

# Frames até cada tipo de wakeup disparar. Quanto MAIOR, mais tempo deitado.
@export var quick_rise_frames: int = 20
@export var back_rise_frames: int = 28
@export var no_tech_frames: int = 45

# Estado escolhido — atualiza a cada frame com base em input atual.
var _chosen_type: String = "quick"
var _chosen_frames: int = 20

func _ready() -> void:
	type_dim = "grounded"
	stance_dim = "any"
	cancel_tier_dim = 5

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	if fighter:
		fighter.velocity = Vector2.ZERO
	if anim:
		anim.play(anim_grounded)
	_chosen_type = "quick"
	_chosen_frames = quick_rise_frames

func physics_update(_delta: float) -> void:
	super.physics_update(_delta)
	if not fighter:
		return

	# Re-avalia escolha a cada frame — o que estiver segurado quando o frame
	# alvo bater é o que sai.
	_update_wakeup_choice()

	if state_frames >= _chosen_frames:
		transition_requested.emit("WakeupState", {"wakeup_type": _chosen_type})

# Lê input direto (não passa pela FSM/gate). Hierarquia: down > back > none.
func _update_wakeup_choice() -> void:
	if not input:
		return
	var dir: Vector2 = input.get_movement_direction()
	var holding_down: bool = dir.y > 0.5

	var f_dir: float = facing.current_facing if facing else 1.0
	var forward: float = dir.x * f_dir
	var holding_back: bool = forward < -0.5

	if holding_down:
		_chosen_type = "no_tech"
		_chosen_frames = no_tech_frames
	elif holding_back:
		_chosen_type = "back"
		_chosen_frames = back_rise_frames
	else:
		_chosen_type = "quick"
		_chosen_frames = quick_rise_frames

func get_tags() -> Array[String]:
	return ["Knockdown", "Grounded"]
