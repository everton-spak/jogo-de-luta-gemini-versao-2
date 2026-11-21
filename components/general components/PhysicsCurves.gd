class_name PhysicsCurves
extends RefCounted

# ==============================================================================
# FÁBRICA DE CURVAS DE FÍSICA (GAME FEEL / FIGHTING GAME CURVES)
# Gera curvas padrão profissionais para Pulo, Knockback, Dash e Rolls.
# Podem ser sobrescritas visualmente via Inspector (@export var curve: Curve).
# ==============================================================================

## Curva de Subida do Pulo: Multiplicador contínuo de gravidade (0.95 -> 1.05), sem hover/pausa no ápice
static func create_jump_ascent_curve() -> Curve:
	var c: Curve = Curve.new()
	c.min_value = 0.0
	c.max_value = 2.0
	c.add_point(Vector2(0.0, 0.95), 0.0, 0.1)
	c.add_point(Vector2(0.5, 1.0), 0.1, 0.1)
	c.add_point(Vector2(1.0, 1.05), 0.1, 0.0)
	c.bake()
	return c

## Curva de Descida do Pulo: Continua C1 do ápice (1.05 -> 1.28) com peso KOF progressivo na aterrissagem
static func create_jump_descent_curve() -> Curve:
	var c: Curve = Curve.new()
	c.min_value = 0.0
	c.max_value = 2.0
	c.add_point(Vector2(0.0, 1.05), 0.0, 0.3)
	c.add_point(Vector2(0.5, 1.18), 0.24, 0.24)
	c.add_point(Vector2(1.0, 1.28), 0.12, 0.0)
	c.bake()
	return c

## Curva de Knockback: Impacto violento no frame 1 dissipando exponencialmente sem patinar
static func create_knockback_decay_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 1.0), 0.0, -3.2)
	c.add_point(Vector2(0.35, 0.25), -0.9, -0.9)
	c.add_point(Vector2(1.0, 0.0), -0.15, 0.0)
	c.bake()
	return c

## Curva de Juggle (Air Hurt): Sustentação controlada para combos aéreos
static func create_juggle_decay_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 1.0), 0.0, -2.0)
	c.add_point(Vector2(0.5, 0.35), -0.6, -0.6)
	c.add_point(Vector2(1.0, 0.0), -0.2, 0.0)
	c.bake()
	return c

## Curva de Dash: Arranque explosivo inicial com desaceleração suave no recovery
static func create_dash_burst_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 1.45), 0.0, -0.8)
	c.add_point(Vector2(0.5, 1.0), -0.5, -0.5)
	c.add_point(Vector2(1.0, 0.35), -0.9, 0.0)
	c.bake()
	return c

## Curva de Roll: Mergulho rápido durante invencibilidade e frenagem no recovery
static func create_roll_velocity_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 0.8), 0.0, 2.0)
	c.add_point(Vector2(0.35, 1.3), 0.0, -1.2)
	c.add_point(Vector2(1.0, 0.2), -0.8, 0.0)
	c.bake()
	return c
