extends "res://scripts/action_can.gd"

# Keep the same lock/charge routine. When the worker is perched directly above,
# search still sweeps the lane instead of waiting like an unused player ability.
func _update_kinetic_ram(delta: float) -> void:
	super._update_kinetic_ram(delta)
	if suspended or state != "idle" or not is_zero_approx(velocity_x):
		return
	var worker := get_tree().get_first_node_in_group("player") as Node2D
	if worker != null and worker.position.y < position.y - 25:
		velocity_x = facing * 72.0
		_travel(delta)

func snapshot() -> Dictionary:
	return {"position": position, "state": state, "time": state_time, "facing": facing, "velocity": velocity_x, "cooldown": cooldown, "contact": contact_cooldown, "squash": squash, "cause": stun_cause, "flash": flash, "clock": clock}

func restore(data: Dictionary) -> void:
	position = data.position
	state = data.state
	state_time = data.time
	facing = data.facing
	velocity_x = data.velocity
	cooldown = data.cooldown
	contact_cooldown = data.contact
	squash = data.squash
	stun_cause = data.cause
	flash = data.flash
	clock = data.clock
	ground_body.collision_layer = 1 if state == "stunned" else 0
	queue_redraw()
