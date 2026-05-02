class_name StandAttack
extends StateMachine

func _ready() -> void:
	# Forçamos a dimensão de postura via código para evitar esquecimentos no Inspector
	stance_dim = "ground"

func get_machine_tags() -> Array[String]:
	# Injeta automaticamente as tags para qualquer ataque que esteja dentro desta pasta!
	# Assim, o jogo sabe que o lutador está no chão E a atacar.
	return ["Attacking", "Grounded"]

func physics_update(delta: float) -> void:
	# 1. Primeiro, executa a lógica do ataque filho (ex: LightPunch, HeavyKick)
	super.physics_update(delta)
	
	# 2. Física Global para Ataques no Chão:
	# Aplica atrito para que o lutador não deslize como se estivesse no gelo 
	# caso ele ataque logo após um dash ou caminhada.
	if movement:
		movement.apply_friction(3000.0, delta)
		movement.commit_movement()

	# 3. Trava de Segurança:
	# Se por algum motivo o chão desaparecer debaixo dele (ex: o chão foi destruído
	# ou ele foi empurrado para fora da plataforma), aborta o ataque terrestre e cai.
	if movement and not fighter.is_on_floor():
		transition_requested.emit("Fall", {})
