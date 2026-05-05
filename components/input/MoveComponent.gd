class_name MoveComponent
extends Component

# O nome do estado que será chamado na StateMachine (ex: "HadoukenState")
@export var target_state_name: String 

# A lista de TAGS permitidas (ex: ["Ground"] permite sair no Idle, Walk e Crouch)
@export var allowed_tags: Array[String] = ["Grounded"]

var attack_component: Component

# Função virtual que será sobrescrita pelos filhos
func check_execution_query(_buffer: InputBuffer) -> Dictionary:
	return {}
