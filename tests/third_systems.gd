extends SceneTree

var level: Node2D
var failures: Array[String] = []
var count := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	level = load("res://scenes/foundry.tscn").instantiate()
	root.add_child(level)
	await frames(3)
	level.player.set_physics_process(false)
	level.player.position = Vector2(410, 291)
	level.crusher.set_physics_process(false)
	level.crusher.position = level.crusher.high
	level.can.position = Vector2(300, 290)
	level.can.state = "idle"
	level.can.cooldown = 0
	await frames(2)
	check(level.can.state == "windup" and level.can.facing == 1, "A: autonomous threat locks toward worker")
	level.player.position.x = 30
	await frames(38)
	check(level.can.state == "charging" and level.can.facing == 1 and level.can.position.x > 300, "A: worker crossing cannot redirect commitment")
	var remaining: float = level.can.state_time
	level.can.receive_kinetic_strike(200)
	check(level.can.state == "charging" and level.can.state_time == remaining, "B: rebound strike preserves charge and duration")
	check(level.can.strike_rebound_speed() == -305, "forgiving predictable Can launch")
	level.can.state = "idle"
	level.can.receive_kinetic_strike(0)
	check(level.can.state == "stagger" and level.can.plate_mass() == 0, "normal stomp cannot create environmental weight")
	await frames(27)
	check(level.can.state != "stagger", "primary mechanic reusable after 0.38-second stagger")
	level.cart.force_station(0)
	await frames(3)
	for index in [1, 2]:
		await force_step(1)
		check(level.cart.station_index == index, "C/D: actual right charge moves one rail position")
	for index in [1, 0]:
		await force_step(-1)
		check(level.cart.station_index == index, "D/M: actual opposite charge recovers prior configuration")
	level.can.set_physics_process(false)
	level.can.state = "idle"
	level.can.ground_body.collision_layer = 0
	level.cart.force_station(0)
	await frames(3)
	level.mechanisms.plate.refresh_weight(1)
	check(not level.mechanisms.catwalk.active, "E: A preserves loft launch, without weight")
	check(level.geometry.has(Rect2(112, 174, 98, 8)), "E: A loft is a real visible landing")
	level.cart.force_station(1)
	await frames(3)
	level.mechanisms.plate.refresh_weight(0)
	level.crusher.set_physics_process(true)
	await frames(2)
	check(level.mechanisms.catwalk.active and level.mechanisms.catwalk.body.collision_layer == 1 and level.crusher.shielded, "E: B immediately supplies bridge and physical press shielding")
	level.cart.force_station(2)
	await frames(3)
	level.mechanisms.plate.refresh_weight(1)
	check(not level.mechanisms.catwalk.active and not level.crusher.shielded, "E: C trades bridge and shielding for exit-side roof")
	level.can.position = Vector2(260, 290)
	level.crusher.clock = 0.8
	await frames(5)
	check(level.can.state == "stunned" and level.can.stun_cause == "crusher", "F: actual Crusher teeth ground Can")
	level.mechanisms.plate.refresh_weight(0)
	check(level.can.plate_mass() == 2 and level.can.velocity_x == 0 and level.can.ground_body.collision_layer == 1 and level.mechanisms.catwalk.active, "G/L: safe stationary heavy Can restores route without Cart")
	var timer: float = level.can.state_time
	level.can.receive_kinetic_strike(200)
	check(level.can.state_time == timer and level.can.state == "stunned", "button cannot extend grounded resource")
	var saved: Dictionary = level.snapshot()
	level.mechanisms.wall.receive_impact(230)
	level.cart.force_station(0)
	level.can.position.x = 45
	level.crusher.clock = 1.9
	level.restore(saved)
	level._freeze(true)
	await frames(3)
	check(level.cart.station_index == 2 and level.can.position.x == 260 and level.can.state_time == timer and not level.mechanisms.wall.broken, "M: explicit rewind restores all physical state, including timers")
	check(level.crusher.clock == saved.press_clock, "rewind preserves machine phase")
	level._freeze(false)
	level.player.set_physics_process(false)
	level.player.position = Vector2(400, 200)
	level.crusher.set_physics_process(false)
	level.crusher.position = level.crusher.high
	level.can.set_physics_process(true)
	level.can.position = Vector2(410, 290)
	level.can.state = "windup"
	level.can.facing = 1
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	await frames(18)
	check(level.mechanisms.wall.broken and level.mechanisms.wall.body.collision_layer == 0, "C/H: active charge permanently breaks weak structure by generic force")
	check(level.can.state == "charging" and level.can.position.x > 460, "H: fracture preserves dangerous momentum, unlike grounding")
	# Generic property works with a source-independent force, not a room ID.
	level.mechanisms.wall.restore({"active": false, "broken": false, "latched": false, "mass": 0, "release": 0})
	level.mechanisms.wall.receive_impact(20)
	check(not level.mechanisms.wall.broken, "weak material rejects insufficient force")
	level.mechanisms.wall.receive_impact(-230)
	check(level.mechanisms.wall.broken, "weak material accepts generic opposite force with no actor flag")
	# Death leaves discoveries, Cart, Can and hazard in place. Reset is separate.
	level.player.set_physics_process(true)
	level.player.kill()
	check(level.mode == "dead", "readable physical failure starts fast respawn")
	await frames(24)
	check(level.mode == "play" and level.player.position.y < 340 and level.cart.station_index == 2 and level.mechanisms.wall.broken, "M: death preserves world discoveries within 0.4 seconds")
	check(level.mechanisms.keys().size() == 3 and not level.mechanisms.has("gate"), "N: no switch checklist or completion prerequisites")
	await process_frame
	Input.action_press("restart")
	await frames(3)
	Input.action_release("restart")
	check(level.stats.resets == 1 and level.cart.station_index == 0 and not level.mechanisms.wall.broken, "R input deliberately restores the entire physical starting yard")
	# Arrival on the real landing works even with every optional resource absent.
	level.can.state = "idle"
	level.player.reset_at(level.EXIT)
	await frames(4)
	check(level.mode == "complete" and level.cart.station_index == 0 and not level.mechanisms.wall.broken and not level.mechanisms.catwalk.active, "N: physical exit arrival needs no invisible Cart / wall / weight flags")
	var file := FileAccess.open("res://artifacts/third_redesign/system_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": count, "failures": failures}, "\t"))
	file.close()
	for message in failures: printerr("THIRD SYSTEM FAIL: ", message)
	print("THIRD SYSTEM CHECKS: ", count, " / failures: ", failures.size())
	level.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func force_step(direction: int) -> void:
	level.can.position = Vector2(level.cart.position.x - direction * 45, 290)
	level.can.facing = direction
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	await frames(45)

func frames(n: int) -> void:
	for i in n: await physics_frame

func check(ok: bool, message: String) -> void:
	count += 1
	if not ok: failures.append(message)
