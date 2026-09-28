extends "res://scripts/player.gd"

# Falling onto the shell is enough. The existing airborne strike remains a
# faster way to connect, using exactly the same predictable launch surface.
func _physics_process(delta: float) -> void:
	var previous_feet := position.y + 9.0
	super._physics_process(delta)
	if not active or velocity.y < 20.0 or attack_time > 0.0:
		return
	for robot in get_tree().get_nodes_in_group("foundry_can"):
		if not robot.has_method("strike_rebound_speed"):
			continue
		var surface: float = robot.strike_surface_y()
		if absf(position.x - robot.position.x) <= 22.0 and previous_feet <= surface + 3.0 and position.y + 9.0 >= surface - 7.0:
			robot.receive_kinetic_strike(velocity.x)
			position.y = surface - 9.0
			velocity.y = robot.strike_rebound_speed()
			jump_cut_available = false
			coyote_time = 0.0
			rebounded.emit(position + Vector2(0, 10))
			return

func _draw() -> void:
	# Hit pause and deliberate pause freeze execution, but keep the worker
	# visible. The legacy renderer uses active as both movement and visibility.
	var was_active := active
	active = true
	super._draw()
	active = was_active
