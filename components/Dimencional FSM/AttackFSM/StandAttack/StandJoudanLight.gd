class_name StandJoudanLight
extends State

@export var animation_name: String = "joudan_stand"
@export var travel_speed: float = 500.0
@export var startup_frames: int = 8

@export_group("Hitbox")
@export var hitbox_offset: Vector2 = Vector2(70, -60)
@export var hitbox_size: Vector2 = Vector2(60, 40)
@export var damage: int = 12
@export var hitstun: float = 0.35
@export var knockback: Vector2 = Vector2(250, -100)

var _launched: bool = false

func _ready() -> void:
	type_dim = "joudan"
	strength_dim = "light"
	cancel_tier_dim = 3

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_launched = false
	fighter.velocity.x = 0.0
	_setup_hitbox()
	if hitbox:
		hitbox.disable_box()
	if anim:
		anim.play(animation_name)

func _setup_hitbox() -> void:
	if not hitbox: return
	var f_dir = facing.current_facing if facing else 1.0
	hitbox.damage = damage
	hitbox.hitstun_duration = hitstun
	hitbox.knockback_force = Vector2(knockback.x * f_dir, knockback.y)
	hitbox.attack_level = "high"
	if hitbox.area_2d:
		hitbox.area_2d.position = Vector2(hitbox_offset.x * f_dir, hitbox_offset.y)
	if hitbox.collision_shape and hitbox.collision_shape.shape is RectangleShape2D:
		hitbox.collision_shape.shape.size = hitbox_size

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if not _launched:
		fighter.velocity.x = 0.0
		if state_frames >= startup_frames:
			_launched = true
			var f_dir = facing.current_facing if facing else 1.0
			fighter.velocity.x = travel_speed * f_dir
			if hitbox: hitbox.enable_box()
		return

	if anim and anim.has_method("is_playing") and not anim.is_playing():
		fighter.velocity.x = 0.0
		if hitbox: hitbox.disable_box()
		transition_requested.emit("IdleState", {})

func exit() -> void:
	super.exit()
	if hitbox: hitbox.disable_box()

func get_tags() -> Array[String]:
	return ["Attacking", "Grounded", "Cancellable"]
