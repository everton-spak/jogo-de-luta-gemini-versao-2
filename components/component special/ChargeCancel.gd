class_name SpecialMechanicComponent
extends Component

# Detém só o que é EXCLUSIVO desta mecânica:
#   1. Tabela MACRO_CANCELS — regras de "botão segurado + botão complementar"
#   2. Classificação de tiers (normal/strong/super) por tempo de carga
#
# O tracking de tempo de botão segurado fica no ChargeTrackerComponent.
# Detecção genérica de botões simultâneos fica no SimultaneousInterpreterComponent.

# Regras de macro-cancel: "botão segurado" → {"complementar apertado": "resultado"}.
# Disparado quando charging_btn está sendo segurado AGORA e complement_btn foi
# pressionado NESTE frame (just_pressed). Não é a mesma coisa que "simultâneo
# dentro de uma janela" — esse caso usa SimultaneousInterpreterComponent.
const MACRO_CANCELS := {
	"light_punch": {
		"light_kick": "hybrid_dash"
	},
	"light_kick": {
		"light_punch": "hybrid_dash",
		"heavy_punch": "special_throw"
	},
	"heavy_punch": {
		"light_kick": "special_throw"
	}
}

@export_group("Tiers da Carga")
# Limiares em ms (alinhado com a unidade do ChargeTrackerComponent).
@export var min_charge_msec: float = 200.0
@export var max_charge_msec: float = 1500.0
@export var normal_multiplier: float = 1.0
@export var strong_multiplier: float = 1.5
@export var super_multiplier: float = 2.5

var input: Component
var charge_tracker: ChargeTrackerComponent

func _on_initialized() -> void:
	input = get_component("InputComponent")
	charge_tracker = get_component("ChargeTrackerComponent")

# Retorna o nome do macro disparado (ex: "hybrid_dash", "special_throw") ou ""
# se nada. Caller só chama isto enquanto charging_btn estiver pressionado.
func check_macro(charging_btn: String) -> String:
	if not input: return ""
	if not MACRO_CANCELS.has(charging_btn): return ""

	var possible_cancels = MACRO_CANCELS[charging_btn]
	for complement_btn in possible_cancels:
		if input.is_action_just_pressed(complement_btn):
			return possible_cancels[complement_btn]
	return ""

# Classifica a carga acumulada de um botão em tiers normal/strong/super.
# Lê o tempo direto do ChargeTrackerComponent. Caller normalmente chama isto
# após is_action_just_released(btn) pra avaliar o que sai no release.
func classify_charge(btn: String) -> Dictionary:
	var t := 0.0
	if charge_tracker:
		t = charge_tracker.get_button_charge_time(btn)

	if t >= max_charge_msec:
		return {"status": "super", "multiplier": super_multiplier, "time_msec": t}
	if t >= min_charge_msec:
		return {"status": "strong", "multiplier": strong_multiplier, "time_msec": t}
	return {"status": "normal", "multiplier": normal_multiplier, "time_msec": t}
