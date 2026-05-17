class_name AttackStateBase
extends State

# Delegador fino: golpes que seguem o ciclo padrão startup→active→recovery
# herdam disto e ganham toda a delegação pra AttackComponent de graça.
#
# O AttackComponent (componente compartilhado no Fighter) executa o ciclo
# e chama os hooks (_during_startup, _on_launch, etc.) que vivem no State.
# Estados de ataque com fluxo customizado (Shoryuken, ProjectileAttackState)
# continuam `extends State` e gerenciam o ciclo sozinhos.

func enter(_payload: Dictionary = {}) -> void:
	super.enter(_payload)
	if attack: attack.begin(self)

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	if attack: attack.tick(delta)

func exit() -> void:
	super.exit()
	if attack: attack.end()
