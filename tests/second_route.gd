extends SceneTree

# ONLY input actions after the real launch spawn. The controller observes
# physical state but never teleports actors, writes progression, or calls force.
var level: Node2D
var failures: Array[String] = []
var frame := 0
var jump_hold := 0
var variant := "cart"
var high_route := false
var trace: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--can" in OS.get_cmdline_user_args():
		variant = "can"
	high_route = "--high" in OS.get_cmdline_user_args()
	level = load("res://scenes/foundry.tscn").instantiate()
	root.add_child(level)
	await step()
	await walk(361)
	await next_room(1)
	mark("Sparks: bait, evade, fracture")
	if high_route:
		await bounce_cart(105, 190)
	else:
		await push(1)
		await bounce_cart(330, 246)
	await walk(363)
	await next_room(2)
	mark("Crossroads: preserve A roof" if high_route else "Crossroads: forward C roof after bridge change")
	await push(1)
	await bounce_cart(330, 246)
	await walk(363)
	await next_room(3)
	mark("Press: Cart moves through shield/weight to forward roof")
	if variant == "cart":
		# Stand on the forward roof to bring Can underneath to its far side.
		await roof(291)
		await until_can_right(269)
		await walk(221)
		await wait_station(1)
		mark("Freeform: reverse C to B for lasting support")
		await bounce_cart(220, 192)
		await walk(358)
	else:
		await bounce_cart(218, 192)
		await walk(140)
		await wait_weight()
		mark("Freeform: environment grounds Can as weight")
		await bounce_cart(350, 208)
	await walk(358)
	for i in 60:
		if level.mode == "complete" or not failures.is_empty():
			break
		await step()
	if level.mode != "complete":
		fail("full fresh completion")
	if level.stats.deaths != 0 or level.stats.resets != 0:
		fail("route should execute without deaths or rewinds")
	var route_name := ("high_" if high_route else "") + variant
	print("SECOND ROUTE ", route_name, " METRICS: ", JSON.stringify(level.metrics()))
	if failures.is_empty():
		var file := FileAccess.open("res://artifacts/second_redesign/route_" + route_name + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(level.metrics(), "\t"))
		file.close()
		print("SECOND FRESH ROUTE PASS: ", route_name, " — input-only, all four encounters")
	else:
		for message in failures:
			printerr("SECOND ROUTE FAIL: ", message)
	for action in ["move_left", "move_right", "jump", "attack"]:
		Input.action_release(action)
	level.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func step(direction: float = 0.0, jump: bool = false, attack: bool = false) -> void:
	await process_frame
	hold("move_left", direction < -0.1)
	hold("move_right", direction > 0.1)
	if jump and not Input.is_action_pressed("jump"):
		jump_hold = 23
	hold("jump", jump_hold > 0 and not attack)
	jump_hold = maxi(0, jump_hold - 1)
	hold("attack", attack)
	await physics_frame
	frame += 1
	if frame % 600 == 0:
		print("TRACE ", state())

func hold(action: String, down: bool) -> void:
	if down and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not down and Input.is_action_pressed(action):
		Input.action_release(action)

func dodge(direction: float) -> bool:
	if not level.player.is_on_floor():
		return false
	var dx: float = level.can.position.x - level.player.position.x
	if level.can.state == "stunned" and dx * direction > 15 and dx * direction < 52 and level.player.position.y > 265:
		return true
	if level.can.state in ["windup", "charging", "idle"] and absf(dx) < 53 and absf(dx) > 14 and level.player.position.y > 268:
		return true
	var roof_distance: float = (level.cart.position.x - level.player.position.x) * direction
	return level.cart.visible and roof_distance > 25 and roof_distance < 55 and level.player.position.y > 268

func walk(x: float, limit: int = 800) -> void:
	if not failures.is_empty():
		return
	for i in limit:
		if level.mode in ["transition", "complete"]:
			return
		var dx: float = x - level.player.position.x
		if absf(dx) < 4:
			await step()
			return
		var jump: bool = dodge(signf(dx))
		# Recovery steps are broad; the low floor never requires pixel jumping.
		if level.player.is_on_floor() and level.player.position.x > 287 and level.player.position.y > 270:
			jump = true
		if level.room_index > 0 and level.player.is_on_floor() and dx > 0 and level.player.position.x > 247 and level.player.position.x < 336:
			jump = true
		if level.room_index == 1 and level.player.is_on_floor() and level.player.position.x > 336 and level.player.position.y > 184:
			jump = true
		if high_route and level.player.is_on_floor() and level.player.position.y < 200 and dx > 0 and ((level.player.position.x > 121 and level.player.position.x < 144) or (level.player.position.x > 234 and level.player.position.x < 258)):
			jump = true
		await step(signf(dx), jump)
		if level.stats.deaths > 0:
			fail("walk died")
			return
	fail("walk %.0f timed out" % x)

func push(index: int) -> void:
	await walk(242)
	await wait_station(index)

func wait_station(index: int) -> void:
	if not failures.is_empty():
		return
	for i in 500:
		if level.cart.station_index == index and level.cart.target_station == index:
			return
		await step(0, dodge(1))
	fail("Cart did not reach %d" % index)

func roof(x: float) -> void:
	if not failures.is_empty():
		return
	for i in 700:
		var p: CharacterBody2D = level.player
		if p.is_on_floor() and p.position.y < 261 and absf(p.position.x - x) < 5:
			return
		var dx: float = x - p.position.x
		var jump := p.is_on_floor() and p.position.y > 261 and absf(dx) < 65
		# From below the chassis, first leave its edge so the jump can clear it.
		var direction := signf(dx) if absf(dx) > 3 else 0.0
		if p.is_on_floor() and p.position.y > 268 and absf(level.cart.position.x - p.position.x) < 38:
			direction = -1
			jump = false
		await step(direction, jump or dodge(direction))
	fail("reach roof %.0f timed out" % x)

func bounce_cart(x: float, top: float) -> void:
	if not failures.is_empty():
		return
	var before: int = level.stats.rebounds
	var launched := false
	for i in 750:
		var p: CharacterBody2D = level.player
		if level.stats.rebounds > before:
			launched = true
		if launched:
			if p.is_on_floor() and p.position.y < top - 6:
				return
			await step(signf(x - p.position.x) if absf(x - p.position.x) > 3 else 0)
			if p.is_on_floor() and p.position.y >= top - 6:
				launched = false
				before = level.stats.rebounds
		else:
			var dx: float = level.cart.position.x - p.position.x
			var height: float = level.cart.position.y - p.position.y
			var direction := signf(dx) if absf(dx) > 4 else 0.0
			var jump := p.is_on_floor() and absf(dx) < 58
			var attack := not p.is_on_floor() and absf(dx) < 20 and height > 24 and height < 59
			if p.is_on_floor() and p.position.y > 268 and absf(dx) < 39:
				direction = -1
				jump = false
				attack = false
			await step(direction, jump or dodge(direction), attack)
		if level.mode in ["transition", "complete"]:
			return
	fail("Cart bounce to %.0f/%.0f timed out" % [x, top])

func until_can_right(x: float) -> void:
	if not failures.is_empty():
		return
	for i in 350:
		if level.can.position.x >= x:
			return
		await step()
	fail("Can search right")

func wait_fracture() -> void:
	if not failures.is_empty():
		return
	for i in 400:
		if level.mechanisms.fracture.broken:
			return
		await step(0, dodge(1))
	fail("fracture did not open")

func wait_weight() -> void:
	if not failures.is_empty():
		return
	for i in 400:
		if level.can.state == "stunned" and level.mechanisms.plate.mass >= 2 and level.mechanisms.bridge.active:
			return
		await step(0, dodge(1))
	fail("environment weight did not form")

func next_room(index: int) -> void:
	if not failures.is_empty():
		return
	for i in 100:
		if level.room_index == index and level.mode == "play":
			return
		await step()
	fail("next room %d" % index)

func mark(message: String) -> void:
	if failures.is_empty():
		trace.append(message)
		print("BEAT ", message, " / ", state())

func state() -> String:
	return "room%d P%s Can%s/%s Cart%s/%d>%d mode%s frame%d" % [level.room_index, level.player.position, level.can.position, level.can.state, level.cart.position, level.cart.station_index, level.cart.target_station, level.mode, frame]

func fail(message: String) -> void:
	failures.append(message + " / " + state())
