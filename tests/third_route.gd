extends SceneTree

# Discovered routes through the completed sandbox. Only Input actions after
# fresh spawn: observations guide movement; actors and mechanisms are untouched.
var level: Node2D
var failures: Array[String] = []
var frame := 0
var jump_hold := 0
var variant := "support"
var trace: Array[Dictionary] = []
var used_grounded_bridge := false
var capture_run := false
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--ground" in OS.get_cmdline_user_args(): variant = "ground"
	if "--force" in OS.get_cmdline_user_args(): variant = "force"
	capture_run = "--capture" in OS.get_cmdline_user_args()
	level = load("res://scenes/foundry.tscn").instantiate()
	root.add_child(level)
	await step()
	if variant == "ground":
		await bounce_cart(194, 174)
		await walk(198)
		await walk(264, true)
		await wait_ground()
		await walk(356, true)
	elif variant == "force":
		await bounce_cart(194, 174)
		await walk(207)
		await walk(270)
		await wait_fracture()
		await walk(500, true)
		await climb_exit()
	else:
		await walk(225)
		await wait_station(1)
		await bounce_cart(334, 218)
		await walk(356)
	if variant != "force":
		await walk(421, true)
		await walk(506, true)
	await walk(550, true)
	for i in 60:
		if level.mode == "complete" or not failures.is_empty(): break
		await step(signf(548 - level.player.position.x) if absf(548 - level.player.position.x) > 2 else 0)
	if level.mode != "complete": fail("fresh escape")
	if level.stats.deaths != 0 or level.stats.resets != 0: fail("route needed a death or rewind")
	if variant == "support" and level.stats.environmental_stuns != 0: fail("support route must preserve active Can")
	if variant == "ground" and (level.stats.environmental_stuns == 0 or not used_grounded_bridge): fail("lower route must actually use environmental weight")
	if variant == "force" and not level.mechanisms.wall.broken: fail("force route must break weak structure")
	if variant == "force" and (level.signature_count == 0 or level.stats.environmental_stuns != 0): fail("force route must combine a continued-charge rebound and fracture without grounding")
	var metrics: Dictionary = level.metrics()
	metrics["route"] = variant
	metrics["input_only"] = true
	metrics["failures"] = failures
	metrics["trace"] = trace
	metrics["used_grounded_bridge"] = used_grounded_bridge
	if capture_run: await capture_once("13_live_escape")
	var file := FileAccess.open("res://artifacts/third_redesign/route_" + variant + ("_graphics" if capture_run else "") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics, "\t"))
	file.close()
	print("THIRD ROUTE ", variant, " — ", metrics.completion_seconds, "s; charges ", metrics.charges, "; impacts ", metrics.cart_impacts, "; rebounds ", metrics.rebounds, "; grounding ", metrics.environmental_stuns, "; failures ", failures)
	for action in ["move_left", "move_right", "jump", "attack"]: Input.action_release(action)
	for voice in level.sound.get_children():
		if voice is AudioStreamPlayer: voice.stop()
	level.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func step(direction: float = 0, jump: bool = false, attack: bool = false) -> void:
	await process_frame
	hold("move_left", direction < -0.1)
	hold("move_right", direction > 0.1)
	if jump and not Input.is_action_pressed("jump"): jump_hold = 23
	hold("jump", jump_hold > 0 and not attack)
	jump_hold = maxi(0, jump_hold - 1)
	hold("attack", attack)
	await physics_frame
	frame += 1
	if level.can.state == "stunned" and level.mechanisms.catwalk.active and level.player.is_on_floor() and level.player.position.x > 290 and level.player.position.x < 375 and absf(level.player.position.y - 209) < 2:
		used_grounded_bridge = true
	if frame % 30 == 0:
		trace.append({"frame": frame, "player": level.player.position, "can": level.can.position, "state": level.can.state, "cart": level.cart.station_index, "bridge": level.mechanisms.catwalk.active})
	if frame % 600 == 0: print(state())
	if capture_run:
		if level.signature_count > 0: await capture_once("11_live_signature")
		if level.mechanisms.wall.broken: await capture_once("12_live_escape_force")

func hold(action: String, down: bool) -> void:
	if down and not Input.is_action_pressed(action): Input.action_press(action)
	elif not down and Input.is_action_pressed(action): Input.action_release(action)

func dodge(direction: float) -> bool:
	if not level.player.is_on_floor(): return false
	var dx: float = level.can.position.x - level.player.position.x
	var roof_dx: float = (level.cart.position.x - level.player.position.x) * direction
	return level.player.position.y > 268 and ((absf(dx) > 14 and absf(dx) < 53) or (roof_dx > 25 and roof_dx < 55))

func walk(x: float, jump_route: bool = false, limit: int = 500) -> void:
	if not failures.is_empty(): return
	for i in limit:
		if level.mode == "complete": return
		var p: CharacterBody2D = level.player
		var dx: float = x - p.position.x
		if absf(dx) < 4:
			await step()
			return
		var jump := dodge(signf(dx))
		if p.is_on_floor() and p.position.y > 302: jump = true
		if jump_route and p.is_on_floor():
			if (p.position.y < 180 and p.position.x > 190 and p.position.x < 214) or (p.position.y < 275 and p.position.x > 241 and p.position.x < 278) or (p.position.y < 220 and p.position.x > 348 and p.position.x < 376) or (p.position.y < 183 and p.position.x > 413) or (p.position.y > 265 and p.position.x > 471) or (p.position.y > 240 and p.position.x > 513): jump = true
		await step(signf(dx), jump)
	fail("walk %.0f timeout" % x)

func wait_station(index: int) -> void:
	if not failures.is_empty(): return
	for i in 300:
		if level.cart.target_station == index: return
		await step(0, dodge(1))
	fail("station %d" % index)

func roof(x: float) -> void:
	if not failures.is_empty(): return
	for i in 350:
		var p: CharacterBody2D = level.player
		if p.is_on_floor() and p.position.y < 261 and absf(p.position.x - x) < 5: return
		var dx: float = x - p.position.x
		var direction := signf(dx) if absf(dx) > 3 else 0.0
		var jump := p.is_on_floor() and p.position.y > 261 and absf(dx) < 65
		if p.is_on_floor() and p.position.y > 268 and absf(level.cart.position.x - p.position.x) < 38:
			direction = -1
			jump = false
		await step(direction, jump or dodge(direction))
	fail("roof timeout")

func bounce_cart(x: float, top: float) -> void:
	if not failures.is_empty(): return
	var before: int = level.stats.rebounds
	var launched := false
	for i in 550:
		var p: CharacterBody2D = level.player
		if level.stats.rebounds > before: launched = true
		if launched:
			if p.is_on_floor() and p.position.y < top - 6: return
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
	fail("bounce roof timeout")

func wait_ground() -> void:
	if not failures.is_empty(): return
	for i in 280:
		if level.can.state == "stunned" and level.mechanisms.catwalk.active: return
		await step(signf(260 - level.player.position.x) if absf(260 - level.player.position.x) > 3 else 0, dodge(1))
	fail("grounding timeout")

func roof_bounce_from_can() -> void:
	if not failures.is_empty(): return
	# Get back to the preserved A roof and launch onto the temporary catwalk.
	await bounce_cart(302, 218)

func wait_fracture() -> void:
	if not failures.is_empty(): return
	for i in 350:
		if level.mechanisms.wall.broken: return
		await step(0, dodge(1))
	fail("fracture timeout")

func climb_exit() -> void:
	if not failures.is_empty(): return
	for i in 220:
		var p: CharacterBody2D = level.player
		if p.is_on_floor() and p.position.y < 271 and absf(p.position.x - 502) < 8: return
		await step(signf(502 - p.position.x) if absf(502 - p.position.x) > 2 else 0, p.is_on_floor() and p.position.y > 271)
	fail("exit step timeout")

func state() -> String:
	return "f%d P%s Can%s/%s Cart%d>%d bridge%s mode%s" % [frame, level.player.position, level.can.position, level.can.state, level.cart.station_index, level.cart.target_station, level.mechanisms.catwalk.active, level.mode]

func fail(message: String) -> void:
	failures.append(message + " / " + state())

func capture_once(name: String) -> void:
	if name in captures: return
	captures.append(name)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/third_redesign/screenshots/" + name + ".png")
