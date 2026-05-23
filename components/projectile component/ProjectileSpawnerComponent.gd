class_name ProjectileSpawnerComponent
extends Component

# Helper geral pra disparar projéteis a partir do fighter. Resolve a posição
# de spawn via marker (alt → principal → fallback), aplica facing, escala visual
# por multiplier, e (na variante spawn_and_launch) chama launch() no projétil.
#
# Hoje só o ProjectileAttackState consome, mas extraído por ser uma capacidade
# autocontida — quando aparecer um segundo source (super, golpe que cospe N
# projéteis, etc.) já tem um lugar pronto pra reusar.

var facing: Component

func _on_initialized() -> void:
	facing = get_component("FacingComponent")

# Spawna o projétil e retorna a instância (ou null se faltar scene/fighter).
# Não chama launch() — use quando quiser controlar a inicialização manualmente.
func spawn(
	scene: PackedScene,
	marker_main: String = "ProjectileSpawn",
	marker_alt: String = "",
	fallback_offset: Vector2 = Vector2(50.0, -80.0),
	scale_mult: float = 1.0
) -> Node:
	if not scene or not fighter:
		return null

	var proj = scene.instantiate()
	fighter.get_parent().add_child(proj)

	var f_dir: float = facing.current_facing if facing else 1.0

	# Marker alt vence quando setado (ex: "ProjectileSpawnAir" pra Hadouken aéreo).
	var marker: Node = null
	if marker_alt != "":
		marker = fighter.get_node_or_null(marker_alt)
	if not marker:
		marker = fighter.get_node_or_null(marker_main)

	if marker:
		proj.global_position = fighter.global_position + Vector2(marker.position.x * f_dir, marker.position.y)
	else:
		proj.global_position = fighter.global_position + Vector2(fallback_offset.x * f_dir, fallback_offset.y)

	proj.scale = Vector2(scale_mult, scale_mult)
	return proj

# Conveniência: spawna + launch() com os params do Hadouken-like.
# Retorna a instância (ou null) pra ajustes pós-launch se necessário.
func spawn_and_launch(
	scene: PackedScene,
	marker_main: String,
	marker_alt: String,
	fallback_offset: Vector2,
	speed_x: float,
	speed_y: float,
	damage: int,
	hitstun: float,
	knockback: Vector2,
	scale_mult: float = 1.0
) -> Node:
	var proj = spawn(scene, marker_main, marker_alt, fallback_offset, scale_mult)
	if proj == null:
		return null
	if not proj.has_method("launch"):
		push_warning("[ProjectileSpawner] projétil instanciado mas não tem método launch()")
		return proj
	var f_dir: float = facing.current_facing if facing else 1.0
	# call() é duck-typed via Object — evita problema de Node estaticamente não ter "launch".
	proj.call("launch", f_dir, speed_x, fighter, damage, hitstun, knockback, speed_y)
	return proj
