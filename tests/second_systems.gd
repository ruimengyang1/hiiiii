extends SceneTree

var failures: Array[String] = []
var count := 0
var level: Node2D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	level = load("res://scenes/foundry_second.tscn").instantiate()
	root.add_child(level)
	await frames(3)
	level.room_index = 3
	level._build_room()
	await frames(3)
	level.player.set_physics_process(false)
	level.player.position = Vector2(330, 273)
	# Sweep-based impact detection really drives all four rail steps.
	level.crusher.set_physics_process(false)
	level.crusher.position = level.crusher.high
	for index in [1, 0]:
		await force_step(-1)
		check(level.cart.station_index == index, "E: left impacts move C→B→A")
	for index in [1, 2]:
		await force_step(1)
		check(level.cart.station_index == index, "E: right impacts move A→B→C")
	check(level.cart.stations.size() == 3, "only three readable local Cart positions")
	level.can.set_physics_process(false)
	level.cart.force_station(0)
	await frames(3)
	level.mechanisms.plate.refresh_weight(1)
	check(not level.mechanisms.bridge.active, "F: A is height, not bridge weight")
	check(level.geometry.has(Rect2(72, 190, 72, 7)) and level.cart.strike_rebound_speed() < level.can.strike_rebound_speed(), "A roof supplies height unavailable to ground Can")
	level.cart.force_station(1)
	await frames(3)
	level.mechanisms.plate.refresh_weight(0)
	check(level.mechanisms.bridge.active and level.mechanisms.bridge.body.collision_layer == 1, "G: arriving B immediately extends nearby solid bridge")
	level.crusher.set_physics_process(true)
	await frames(2)
	check(level.crusher.shielded, "B also physically catches the press above the Can")
	level.cart.force_station(2)
	await frames(3)
	level.mechanisms.plate.refresh_weight(1)
	check(not level.mechanisms.bridge.active and not level.crusher.shielded, "C trades durable weight / shielding for a forward launch")
	# Ordinary stomp never powers the plate, even in the ideal position.
	level.can.position = Vector2(185, 290)
	level.can.state = "idle"
	level.can.receive_kinetic_strike(0)
	level.mechanisms.plate.refresh_weight(1)
	check(level.can.state == "stagger" and not level.mechanisms.bridge.active, "C/H: button stomp cannot manufacture safe heavy weight")
	# Actual press spike geometry, not a direct stun call.
	level.can.state = "idle"
	level.crusher.clock = 0.8
	await frames(5)
	check(level.can.state == "stunned" and level.can.stun_cause == "crusher", "D: real Crusher overlap grounds the robot")
	level.mechanisms.plate.refresh_weight(0)
	check(level.mechanisms.bridge.active and level.mechanisms.plate.mass >= 2, "H: environmentally grounded Can substitutes for Cart weight")
	check(level.can.ground_body.collision_layer == 1, "grounded shell is a safe solid stepping surface")
	# Save a live configuration, then mutate every important local resource.
	level._save_entry()
	var saved_clock: float = level.crusher.clock
	var saved_time: float = level.can.state_time
	level.mechanisms.fracture.receive_impact(230)
	level.cart.force_station(0)
	level.can.position.x = 55
	level.can.state = "charging"
	level.crusher.clock = 1.9
	level._restore_entry()
	level._freeze(true)
	await frames(2)
	check(not level.mechanisms.fracture.broken and level.cart.station_index == 2 and level.can.state == "stunned" and level.can.position.x == 185 and level.can.state_time == saved_time, "complete rewind restores fracture, roof, weight, position and grounding timer")
	check(level.crusher.clock == saved_clock, "pause / rewind preserves hazard phase")
	# Physical force still creates a permanent alternative low passage. This
	# is distinct from the two full routes which legitimately go over it.
	level._freeze(false)
	level.player.set_physics_process(false)
	level.player.position = Vector2(335, 273)
	level.can.set_physics_process(true)
	level.cart.force_station(1)
	await frames(3)
	level.can.position = Vector2(273, 290)
	level.can.state = "windup"
	level.can.facing = 1
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	await frames(18)
	check(level.mechanisms.fracture.broken and level.mechanisms.fracture.body.collision_layer == 0, "real charge beyond Cart breaks mastery partition permanently")
	check(level.mechanisms.bridge.active, "fracture plan preserves Cart's durable weight")
	# Always-right leaves C with no weight and no landing under the final exit.
	level.can.set_physics_process(false)
	level.can.state = "idle"
	level.can.ground_body.collision_layer = 0
	level.cart.force_station(2)
	await frames(3)
	level.mechanisms.plate.refresh_weight(1)
	check(not level.mechanisms.bridge.active and level.mechanisms.bridge.body.collision_layer == 0 and level.mode == "play", "J: rightmost Cart does not provide a valid final landing")
	check(not level.mechanisms.has("gate") and not level.has_method("_activate_switch"), "no gate / lever procedure in launch")
	# Exercise the player's reset input and short death path, not only restore.
	level.player.set_physics_process(true)
	level._save_entry()
	var saved_cart_x: float = level.cart.position.x
	level.cart.force_station(0)
	await process_frame
	Input.action_press("restart")
	await frames(3)
	Input.action_release("restart")
	check(level.mode == "play" and level.cart.position.x == saved_cart_x and level.stats.resets == 1, "R input restores the current bay without replaying solved rooms")
	level.player.position.y = 400
	await frames(2)
	check(level.mode == "dead", "fall starts immediate local recovery")
	await frames(24)
	check(level.mode == "play" and level.player.position.y < 340 and level.cart.position.x == saved_cart_x, "death restores the local configuration within 0.4 seconds")
	level.free()
	await process_frame
	for message in failures:
		printerr("SECOND SYSTEM FAIL: ", message)
	print("SECOND SYSTEM CHECKS: ", count)
	if failures.is_empty():
		print("SECOND SYSTEM PASS: E–J, actual bidirectional impacts, visible multi-role positions, shared hazard, weight, force, complete recovery")
	quit(0 if failures.is_empty() else 1)

func force_step(direction: int) -> void:
	level.can.position = Vector2(level.cart.position.x - direction * 22, 290)
	level.can.facing = direction
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	await frames(40)

func frames(number: int) -> void:
	for i in number:
		await physics_frame

func check(ok: bool, explanation: String) -> void:
	count += 1
	if not ok:
		failures.append(explanation)
