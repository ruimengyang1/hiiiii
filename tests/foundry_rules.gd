extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = (load("res://scenes/foundry.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await _frames(3)
	level.can.set_physics_process(false)
	for press in level.crushers:
		press.disabled = true
	_check(get_nodes_in_group("foundry_can").size() == 1 and get_nodes_in_group("foundry_cart").size() == 1, "whole route reuses one persistent Can and one Cart")
	_check(not level.player.dash_enabled, "no late movement upgrade is available to bypass system state")

	# Impact is a force/property contract, not an enemy identity check.
	var source := Node2D.new()
	root.add_child(source)
	level.mechanisms.transfer_wall.receive_impact(30.0, source)
	_check(not level.mechanisms.transfer_wall.broken, "insufficient force cannot fracture a bulkhead")
	level.mechanisms.transfer_wall.receive_impact(100.0, source)
	await _frames(2)
	_check(level.mechanisms.transfer_wall.broken and level.mechanisms.transfer_wall.body.collision_layer == 0, "sufficient force from any compatible source leaves a permanent route")
	_check(not level.mechanisms.transfer_wall.impact_enabled(), "broken material does not repeatedly intercept later charges")
	source.free()

	# Geometry requires the lost roof, not greater jump precision. First try a
	# normal jump; then the largest possible ground-Can rebound and air strike.
	level.cart.force_station(4)
	await _frames(3)
	level.can.position = Vector2(150, 290)
	level.player.reset_at(Vector2(1780, 291))
	await _frames(3)
	await process_frame
	Input.action_press("jump")
	await _frames(18)
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("jump")
	Input.action_release("attack")
	await _frames(35)
	_check(not level.switches.vent.active, "normal jumping cannot consume the high roof objective")
	level.can.position = Vector2(1780, 290)
	level.can.state = "stunned"
	level.can.state_time = 6.0
	level.player.reset_at(Vector2(1780, 256))
	await _frames(2)
	await process_frame
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	var minimum_y: float = level.player.position.y
	for _frame in 20:
		await _frames(1)
		minimum_y = minf(minimum_y, level.player.position.y)
	await process_frame
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	_check(minimum_y + 9.0 > 214.0 and not level.switches.vent.active, "even a Can rebound cannot replace Cart A's high roof")

	# Recover the same roof and repeat the same ability. This time it works.
	level.can.position = Vector2(1600, 290)
	level.cart.force_station(2)
	await _frames(3)
	level.player.reset_at(Vector2(1780, 235))
	await _frames(2)
	await process_frame
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	await _frames(20)
	await process_frame
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	_check(level.switches.vent.active and level.mechanisms.vent_gate.latched, "preserved/recovered Cart roof reaches the lasting high circuit")

	# The early sealed pump may be solved early by knowledge. No stage password
	# or destination index prevents that valid ordering.
	level.mechanisms.pump_wall.receive_impact(100.0, null)
	level.player.reset_at(Vector2(64, 260))
	await _frames(2)
	await process_frame
	Input.action_press("attack")
	await _frames(6)
	Input.action_release("attack")
	_check(level.switches.pump.active and level.mechanisms.pump_gate.latched and level.cart.station_index == 2, "expert knowledge can restore evacuation power before forward cargo progress")

	# Closed machinery cannot crush bodies by reappearing inside them.
	level.player.set_physics_process(false)
	level.mechanisms.final_gate.set_open(true)
	level.player.position = Vector2(3128, 291)
	level.mechanisms.final_gate.set_open(false)
	_check(level.mechanisms.final_gate.active, "gate closing waits until an occupying player clears the safety strip")
	level.player.position = Vector2(3170, 291)
	level.mechanisms.final_gate.set_open(false)
	_check(not level.mechanisms.final_gate.active, "unpowered gate closes after occupancy clears")

	level.save_checkpoint("invariant", "RULES TEST", Vector2(1710, 291))
	level.mechanisms.transfer_wall.broken = false
	level.mechanisms.transfer_wall.active = false
	level.switches.vent.active = false
	level.switches.pump.active = false
	level.cart.force_station(7)
	await process_frame
	Input.action_press("restart")
	await _frames(3)
	Input.action_release("restart")
	_check(level.mechanisms.transfer_wall.broken and level.switches.vent.active and level.switches.pump.active and level.cart.station_index == 2, "deliberate R restores all prior persistent consequences together")
	level.player.set_physics_process(true)
	level.player.position.y = 400.0
	await _frames(2)
	_check(level.mode == "dead", "falling out of bounds begins the quick recovery path")
	await _frames(35)
	_check(level.mode == "play" and level.player.position.y < 310.0 and level.cart.station_index == 2, "death restores the complete local snapshot without replaying earlier work")
	level.free()
	await process_frame
	if failures.is_empty():
		print("FOUNDRY RULES PASS: general force, persistent fracture, dexterity limits, roof prerequisite, early knowledge shortcut, safe gate, R and death recovery")
		quit(0)
	else:
		for failure in failures:
			printerr("FOUNDRY RULES FAIL: ", failure)
		quit(1)

func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func _check(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)
