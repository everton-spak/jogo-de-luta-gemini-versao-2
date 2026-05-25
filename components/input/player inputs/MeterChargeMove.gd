class_name MeterChargeMove
extends MoveComponent

# Carga manual do super meter: LP + HK simultâneos (mantidos segurados).
# Entra no MeterChargeState que incrementa a MeterBar (BarComponent configurado
# como "Super") enquanto os botões estiverem pressionados. Solta um dos dois →
# state termina.
#
# Não confunde com:
#   - hybrid_dash (LP + LK)
#   - special_throw macro (LK + HP durante charge phase de outro special)
#   - dodge (LP + LK)

func _ready() -> void:
	if allowed_tags.is_empty():
		allowed_tags = ["Grounded"]

func check_execution_query(buffer: InputBuffer) -> Dictionary:
	# Anti-spam: já está em meter charge? Não re-entra.
	if buffer.fighter:
		var fsm = buffer.fighter.get_component("StateMachine")
		if fsm and "MeterCharging" in fsm.get_tags():
			return {}

	# Trigger: LP+HK simultâneos.
	if not buffer.simultaneous or not buffer.simultaneous.is_simultaneous_buffered(["punch_light", "kick_heavy"]):
		return {}

	# Consume os dois botões pra não disparar normais (LP e HK) no mesmo frame.
	buffer.simultaneous.consume_simultaneous(["punch_light", "kick_heavy"])

	return {
		"type": "meter_charge",
		"stance": "ground",
		"direction": "any",
	}
