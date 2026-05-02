class_name ScalingComboComponent
extends Component

# Sinais para a Interface de Utilizador (UI) mostrar "X HITS!" no ecrã
signal combo_updated(hit_count: int, total_damage: float)
signal combo_dropped()

# Dados do Combo Atual
var current_hits: int = 0
var total_combo_damage: float = 0.0

@export_group("Damage Scaling")
# Cada hit multiplica o dano base por este valor. 
# 0.8 significa que cada hit dá 80% do dano do hit anterior.
@export var scaling_factor: float = 0.8 
# Dano mínimo absoluto (para os golpes não passarem a dar 0 de dano)
@export var minimum_damage: float = 1.0 

# ==========================================
# ➕ REGISTAR UM NOVO GOLPE
# ==========================================
func process_hit(base_damage: float) -> float:
	var final_damage = base_damage
	
	# Se já estamos num combo, aplica o escalonamento (Scaling)
	if current_hits > 0:
		# Fórmula: dano_base * (0.8 elevado ao número de hits)
		var multiplier = pow(scaling_factor, current_hits)
		final_damage = max(base_damage * multiplier, minimum_damage)
	
	# Atualiza a contabilidade
	current_hits += 1
	total_combo_damage += final_damage
	
	# Grita para a UI desenhar o número na tela!
	combo_updated.emit(current_hits, total_combo_damage)
	
	return final_damage

# ==========================================
# 🛑 DEIXAR CAIR O COMBO (Drop)
# ==========================================
func reset_combo() -> void:
	# Só avisa a UI se realmente foi um combo (2 ou mais hits)
	if current_hits > 1:
		combo_dropped.emit()
		
	# Zera tudo
	current_hits = 0
	total_combo_damage = 0.0
