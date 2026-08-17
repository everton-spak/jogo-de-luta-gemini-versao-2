class_name PhysicsCurves
extends RefCounted

# ==============================================================================
# FÁBRICA DE CURVAS DE FÍSICA (GAME FEEL / FIGHTING GAME CURVES)
# Gera curvas padrão profissionais para Pulo, Knockback, Dash e Rolls.
# Podem ser sobrescritas visualmente via Inspector (@export var curve: Curve).
# ==============================================================================

## Curva de Subida do Pulo: Decolagem explosiva com suave flutuação (Apex Hangtime) no topo
static func create_jump_ascent_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 1.0), 0.0, -0.3)
	c.add_point(Vector2(0.7, 0.45), -0.8, -0.8)
	c.add_point(Vector2(1.0, 0.05), -0.6, 0.0)
	c.bake()
	return c

## Curva de Descida do Pulo: Início suave no ápice com aceleração progressiva na aterrissagem
static func create_jump_descent_curve() -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, 0.1), 0.0, 1.6)
	c.add_point(Vector2(0.5, 0.6), 1.0, 1.0)
	c.add_point(Vector2(1.0, 1.0), 0.6, 0.0)
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
