class_name SpecialMechanicComponent
extends Component

@export var max_charge_time: float = 1.5
@export var min_charge_time: float = 0.2

var current_charge: float = 0.0
var input: Component 

# A Tabela de Regras de Combinação (Macros)
# Formato: "botao_sendo_segurado": { "botao_apertado": "resultado" }
const MACRO_CANCELS = {
	# Se segura Soco Fraco e aperta Chute Fraco -> Dash
	"light_punch": {
		"light_kick": "hybrid_dash"
	},
	# Se segura Chute Fraco e aperta Soco Fraco -> Dash | Aperta Soco Forte -> Throw
	"light_kick": {
		"light_punch": "hybrid_dash", 
		"heavy_punch": "special_throw"
	},
	# Se segura Soco Forte e aperta Chute Fraco -> Throw
	"heavy_punch": {
		"light_kick": "special_throw"
	}
}

func _on_initialized() -> void:
	input = get_component("InputComponent")

func reset_charge() -> void:
	current_charge = 0.0

func process_charge(charging_btn: String, delta: float) -> Dictionary:
	
	# =========================================================
	# 1. REGRA DE OURO: CHECAGEM DE CANCELAMENTO (MACROS)
	# =========================================================
	if current_charge > 0.0 or input.is_action_pressed(charging_btn):
		
		# Verifica se o botão que está sendo segurado possui alguma regra de cancelamento
		if MACRO_CANCELS.has(charging_btn):
			var possible_cancels = MACRO_CANCELS[charging_btn]
			
			# Varre todos os botões que combinam com o que está sendo segurado
			for complement_btn in possible_cancels:
				if input.is_action_just_pressed(complement_btn):
					current_charge = 0.0 # Destrói a carga da magia
					# Retorna o status exato da combinação (ex: "hybrid_dash")
					return {"status": possible_cancels[complement_btn]}

	# =========================================================
	# 2. CONTINUA CARREGANDO A MAGIA NORMALMENTE
	# =========================================================
	if input.is_action_pressed(charging_btn):
		current_charge += delta
		return {"status": "charging", "time": current_charge}
		
	# =========================================================
	# 3. SOLTOU O BOTÃO (DISPARA A MAGIA CARREGADA)
	# =========================================================
	elif current_charge > 0.0:
		var final_charge = current_charge
		current_charge = 0.0 
		
		# Avalia o nível da carga baseando-se nas variáveis exportadas
		if final_charge >= max_charge_time:
			return {"status": "super", "multiplier": 2.5}
		elif final_charge >= min_charge_time:
			return {"status": "strong", "multiplier": 1.5}
		else:
			return {"status": "normal", "multiplier": 1.0}
			
	# =========================================================
	# 4. NENHUMA AÇÃO (Inativo)
	# =========================================================
	return {"status": "inactive"}
