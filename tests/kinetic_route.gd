extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame

	# Beat 1: a real downward strike on the central threat returns traversal lift.
	level.ram.state = "stunned"
	level.ram.state_time = 2.0
	level.ram.monitoring = false
	level.player.global_position = level.ram.global_position + Vector2(0, -27)
	level.player.velocity = Vector2(80, 20)
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	_check(level.player.velocity.y < -180.0, "threat becomes a forgiving bounce tool")
	level.ram.monitoring = true

	# Beats 2-3: use general ram momentum to advance to transfer and circuit stops.
	await _push_cart(level, 1)
	_check(level.checkpoint_station == 1, "first passenger dock becomes a nearby rewind point")
	await _push_cart(level, 1)
	_check(level.carriage.station_index == 2 and level.circuit_powered, "cart position disables the shared live rail")

	# Beat 4: blindly repeating push-right reveals the cut-off prerequisite.
	var rejected: bool = not level.carriage.request_station_push(1, 138.0)
	if rejected:
		level._on_cart_push_rejected(3)
	_check(rejected and level.carriage.station_index == 2, "reasonable early heuristic fails without losing the useful state")
	_check("CUT-OFF" in level.last_event, "failure explains the strategic change instead of hiding a trap")
	level.safety_switch.receive_strike()
	await process_frame
	_check(level.safety_enabled, "player interaction changes the cart's future")
	await _push_cart(level, 1)
	_check(level.carriage.station_index == 3 and level.final_switch.armed, "safe bay arms the previously visible ram lock")

	# Beat 5: ram interaction unlocks the route, then the same cart rule pays off.
	_check(level.final_switch.position.x < level.carriage.position.x, "armed lock asks the player to bring the ram back before final progress")
	var ram_return: float = level.final_switch.receive_ram_impact(-138.0)
	await process_frame
	_check(level.final_lock_enabled and ram_return > 0.0, "ram lock returns the barrel on the useful cart-pushing side")
	await _push_cart(level, 1)
	_check(level.carriage.station_index == 4 and level.npc_arrived, "planned final impact delivers the NPC")
	level.player.global_position = level.GOAL_POSITION
	await physics_frame
	_check(level.mode == "complete", "player meets the delivered NPC to finish the complete route")

	level.player.active = false
	level.ram.set_physics_process(false)
	level.carriage.set_physics_process(false)
	level.free()
	await process_frame
	if failures.is_empty():
		print("SYSTEMIC ROUTE PASS: bounce, cart circuit, heuristic break, cut-off, ram lock, NPC delivery")
		quit(0)
	else:
		for failure in failures:
			printerr("SYSTEMIC ROUTE FAIL: ", failure)
		quit(1)

func _push_cart(level: Node, direction: int) -> void:
	var accepted: bool = level.carriage.request_station_push(direction, 138.0)
	_check(accepted, "planned ram impact is accepted at station %d" % level.carriage.station_index)
	for _frame in 40:
		await physics_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
