extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level = (load("res://scripts/foundry.gd") as GDScript).new()
	level.greybox_mode = true
	root.add_child(level)
	await _frames(3)
	level.player.set_physics_process(false)
	level.player.position = Vector2(3000, 180)
	level.crushers[0].disabled = true
	level.can.position = Vector2(2750, 290)
	level.can.state = "idle"
	level.can.cooldown = 0.0
	level.player.position = Vector2(2825, 291)
	await _frames(2)
	_check(level.can.state == "windup" and level.can.facing == 1, "visible player initiates rightward intent")
	level.player.position = Vector2(2730, 291)
	await _frames(60)
	_check(level.can.facing == 1 and level.cart.target_station == 6, "moving behind after lock does not home; real impact moves Cart")
	await _frames(150)
	_check(level.cart.station_index == 6 and level.mechanisms.final_gate.active, "Cart is heavy weight at a physical plate")
	_check(level.cart.position.x > 2850, "using Cart as progress removes the original high roof")

	# Blind progress removes weight. No scripted station permission prevents it.
	level.player.position = Vector2(3100, 180)
	level.can.position = Vector2(2890, 290)
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.facing = 1
	level.can.contact_cooldown = 0.0
	await _frames(170)
	_check(level.cart.stalled and not level.mechanisms.final_gate.active and level.cart.station_index == 6, "always push right physically stalls after losing plate weight")
	_check(not level.can.plate_mass() > 0.0, "active/recovering Can cannot substitute for a committed weight")

	# Solution B: use the exact same Can as replacement weight through a real
	# downward strike. The stalled Cart resumes without another force/password.
	level.can.position = Vector2(2908, 290)
	level.can.state = "idle"
	level.can.cooldown = 1.0
	level.player.set_physics_process(true)
	level.player.reset_at(Vector2(2908, 251))
	level.player.velocity = Vector2(0, 20)
	await _frames(2)
	await process_frame
	Input.action_press("attack")
	await _frames(1)
	await _frames(7)
	Input.action_release("attack")
	_check(level.can.state == "stunned" and level.player.velocity.y < -180.0, "stomp gives fixed bounce and spends charge availability")
	_check(level.mechanisms.final_plate.mass >= 2.0 and level.mechanisms.final_gate.active, "stunned Can follows the same physical weight rule as Cart")
	level.player.set_physics_process(false)
	await _frames(160)
	_check(level.cart.station_index == 7, "temporary Can weight completes the systemic transport solution")

	# Solution A: persistent far-side release allows the Can to remain a force
	# resource. Set up another fixture, then use strike and contact, not setters.
	level.cart.force_station(6)
	level.can.receive_stun(6.0)
	level.player.reset_at(Vector2(3190, 251))
	level.player.velocity = Vector2(0, 20)
	level.player.set_physics_process(true)
	await _frames(2)
	await process_frame
	Input.action_press("attack")
	await _frames(8)
	Input.action_release("attack")
	_check(level.switches.final_release.active and level.mechanisms.final_gate.latched, "far-side strike creates permanent routing state")
	level.player.set_physics_process(false)
	level.player.position = Vector2(3100, 180)
	level.can.position = Vector2(2890, 290)
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.facing = 1
	level.can.contact_cooldown = 0.0
	await _frames(230)
	_check(level.cart.station_index == 7, "latched-route solution frees Can to supply force instead of weight")

	# Reversal is available, including recovery from an abandoned useful roof.
	level.cart.force_station(6)
	await _frames(2)
	level.can.position = Vector2(3010, 290)
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.facing = -1
	level.can.contact_cooldown = 0.0
	await _frames(140)
	_check(level.cart.station_index == 5, "same force rule reverses Cart to recover high roof access")

	# The hazard must actually detect the same spike polygons, not a Can ID or a
	# hardcoded time at a cart stop.
	level.crushers[0].disabled = false
	level.crushers[0].clock = 0.85
	level.can.position = Vector2(2908, 290)
	level.can.state = "idle"
	level.can.cooldown = 6.0
	level.player.position = Vector2(2908, 180)
	await _frames(4)
	_check(level.can.state == "stunned", "actual crusher spike overlap stuns autonomous Can")

	level.save_checkpoint("fixture", "DEPTH TEST", Vector2(2750, 291))
	var saved_cart: float = level.cart.position.x
	var saved_time: float = level.can.state_time
	level.cart.force_station(7)
	level.mechanisms.final_gate.latched = false
	level.switches.final_release.active = false
	level.can.position.x = 3400
	level.restore_checkpoint()
	level.can.set_physics_process(false)
	await _frames(2)
	_check(is_equal_approx(level.cart.position.x, saved_cart) and is_equal_approx(level.can.state_time, saved_time) and level.mechanisms.final_gate.latched and level.switches.final_release.active, "rewind restores actor positions/timers and persistent circuits together")
	level.set_suspended(true)
	var phase: float = level.crushers[0].clock
	await _frames(10)
	_check(is_equal_approx(level.crushers[0].clock, phase), "pause preserves hazard phase and useful states")
	level.free()
	await process_frame
	if failures.is_empty():
		print("FOUNDRY DEPTH PASS: intent, force, roof cost, weight loss, two solutions, reversal, shared crusher, snapshot, pause")
		quit(0)
	else:
		for failure in failures:
			printerr("FOUNDRY DEPTH FAIL: ", failure)
		quit(1)

func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func _check(condition: bool, explanation: String) -> void:
	if not condition:
		failures.append(explanation)
