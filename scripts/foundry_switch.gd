extends "res://scripts/systemic_switch.gd"

func receive_strike() -> bool:
	if active:
		return false
	return super.receive_strike()

func strike_rebound_speed() -> float:
	# A small latched lever supplies no launch energy. Height remains a property
	# of the Can and transport roof, so nearby controls cannot replace them.
	return 0.0
