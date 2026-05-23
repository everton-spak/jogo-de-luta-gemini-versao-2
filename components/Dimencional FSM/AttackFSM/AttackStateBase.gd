class_name AttackStateBase
extends State

# Delegador fino: golpes que seguem o ciclo padrão startup→active→recovery
# herdam disto e ganham toda a delegação pra AttackComponent de graça.
#
# O AttackComponent (componente compartilhado no Fighter) executa o ciclo
# e chama os hooks (_during_startup, _on_launch, etc.) que vivem no State.
# Estados de ataque com fluxo customizado (Shoryuken, ProjectileAttackState)
# continuam `extends State` e gerenciam o ciclo sozinhos.
#
# Motion moves (charge_pause_frame >= 0) automaticamente ganham:
# - Charge phase: pausa anim enquanto botão segurado, multiplier no release
# - Macro-cancel: cancel em hybrid_dash/super_throw via complemento

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	_reset_charge()
	_ensure_posture()
	if attack: attack.begin(self)

# Garante que o collider+sprite estão na postura correta pra esse golpe.
# Sem isso, ao cancelar de um golpe agachado pra um golpe em pé (ou vice-versa)
# o collider fica na postura do golpe anterior e o sprite do novo golpe é
# desenhado deslocado (parece que o personagem afunda).
func _ensure_posture() -> void:
	if not posture: return
	match stance_dim:
		"ground": posture.apply("stand")
		"crouch": posture.apply("crouch")
		"air": posture.apply("air")

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	# Motion moves: macro-cancel e charge phase. Skip se charge_pause_frame < 0
	# (golpes normais não passam por esses checks porque _get_charging_button
	# retorna "" via inferência por type_dim).
	var charging_btn := _get_charging_button()
	if charging_btn != "":
		if _check_macro(charging_btn):
			return
		if _tick_charge(charging_btn):
			return # paused — não avança o tick do AttackComponent

	if attack: attack.tick(delta)

func exit() -> void:
	super.exit()
	if attack: attack.end()
