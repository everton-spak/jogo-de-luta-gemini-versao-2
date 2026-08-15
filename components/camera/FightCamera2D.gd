class_name FightCamera2D
extends Camera2D

@export var target_p1: CharacterBody2D
@export var target_p2: CharacterBody2D

@export_group("Movimento e Suavização")
@export var smooth_speed: float = 12.0
@export var center_offset: Vector2 = Vector2(0, -60)
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)

@export_group("Limites de Arena")
@export var enable_arena_limits: bool = true
@export var arena_min_x: float = 650.0
@export var arena_max_x: float = 1270.0
@export var arena_max_y: float = 540.0

func _ready() -> void:
	# Ativa a câmera no viewport
	make_current()
	zoom = camera_zoom
	_find_targets_if_needed()

func _find_targets_if_needed() -> void:
	if target_p1 and target_p2:
		return
		
	var fighters: Array[CharacterBody2D] = []
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is CharacterBody2D:
				fighters.append(child)
				
	if fighters.size() >= 1 and not target_p1:
		target_p1 = fighters[0]
	if fighters.size() >= 2 and not target_p2:
		target_p2 = fighters[1]

func _physics_process(delta: float) -> void:
	if not target_p1 or not is_instance_valid(target_p1):
		_find_targets_if_needed()
		if not target_p1:
			return
			
	var target_pos: Vector2
	
	if target_p2 and is_instance_valid(target_p2):
		# Rastreia o ponto médio exato entre os dois lutadores
		target_pos = (target_p1.global_position + target_p2.global_position) * 0.5 + center_offset
	else:
		# Modo treino / 1 jogador: segue o P1
		target_pos = target_p1.global_position + center_offset
		
	# Respeita os limites da arena
	if enable_arena_limits:
		target_pos.x = clamp(target_pos.x, arena_min_x, arena_max_x)
		if target_pos.y > arena_max_y:
			target_pos.y = arena_max_y
		
	# Movimento suave
	global_position = global_position.lerp(target_pos, clamp(smooth_speed * delta, 0.0, 1.0))
