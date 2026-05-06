class_name ChargeTrackerComponent
extends Component

# Tempo que a carga ainda vale após soltar o botão (ms)
@export var charge_grace_msec: int = 250

# Acumuladores de tempo para Trás (Back) e Baixo (Down)
var _charge_time: Dictionary = {"B": 0.0, "D": 0.0}
var _charge_drop_time: Dictionary = {"B": 0, "D": 0}

var interpreter: DirectionalInterpreterComponent

func _on_initialized() -> void:
	interpreter = get_component("DirectionalInterpreterComponent")

func _physics_process(delta: float) -> void:
	if not interpreter: return
	
	var dir_string = interpreter.get_direction_string()
	var current_time = Time.get_ticks_msec()
	
	# Verifica Carga para Trás ("B") e Baixo ("D")
	for key in ["B", "D"]:
		# Nota: Se estiver em diagonal (ex: DB), conta para ambos!
		if key in dir_string:
			_charge_time[key] += delta * 1000.0
			_charge_drop_time[key] = current_time
		else:
			# Se soltou, espera a janela de graça antes de zerar
			if current_time - _charge_drop_time[key] > charge_grace_msec:
				_charge_time[key] = 0.0

# API para os golpes consultarem se a carga está pronta
func is_charge_ready(charge_dir: String, required_msec: float) -> bool:
	return _charge_time.get(charge_dir, 0.0) >= required_msec
