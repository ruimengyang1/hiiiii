extends SceneTree

# Fresh-spawn route: only MOVE/JUMP/STOMP inputs. No actor teleport, force call,
# switch activation, cart station setter or progression-state mutation.
var level: Node2D
var failures: Array[String] = []
var frame_count := 0
var jump_hold := 0
var rebound_count := 0
var trace: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	level = (load("res://scenes/foundry.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await _step()
	level.player.rebounded.connect(func(_at: Vector2) -> void: rebound_count += 1)
	await _walk(395)
	await _bounce(level.can, 395, 225)
	await _lever("inspection")
	_mark("react")
	await _transport(1)
	await _bounce(level.cart, 1040, 220)
	await _walk(1080)
	await _wait_can_right(970)
	await _walk(1110)
	await _wait_wall("transfer_wall")
	_mark("knowledge transfer")
	await _walk(1560)
	await _bounce(level.can, 1580, 228)
	await _lever("freight")
	_mark("world affects Can")
	await _transport(2)
	await _bounce(level.can, 1690, 300, true)
	await _walk(1780)
	await _bounce(level.cart, 1780, 214)
	await _lever("vent")
	_mark("preserve roof before transport")
	await _transport(3)
	await _walk(2220)
	await _lever("yard_release")
	await _transport(4)
	_mark("preserve weight then latch route")
	await _walk(132)
	await _wait_wall("pump_wall")
	await _walk(64)
	await _lever("pump")
	_mark("return with knowledge")
	await _transport(5)
	await _walk(2810)
	await _bounce(level.cart, 2810, 214)
	await _lever("isolation")
	await _transport(6)
	if "--weight" in OS.get_cmdline_user_args():
		# Real alternate order: spend Can as replacement weight before crossing
		# to the permanent release, rather than latch before sending cargo.
		await _bounce(level.can, 3010, 300, true)
	else:
		# A premature charge relocates the roof to the closed gate. That cost also
		# creates recovery access to the previously taught upper service route.
		await _bounce(level.cart, 3150, 214)
	await _walk(3190)
	await _lever("final_release")
	await _transport(7)
	_mark("mastery: temporary weight" if "--weight" in OS.get_cmdline_user_args() else "mastery: durable route")
	await _bounce(level.cart, 3310, 224)
	await _walk(3320)
	await _wait_can_right(3265)
	await _walk(3380)
	await _wait_wall("escape_wall")
	await _walk(3510)
	await _step()
	_check(level.mode == "complete", "fresh input-only run reaches evacuation completion")
	_check(level.deaths == 0 and level.rewinds == 0, "correct ordering is executable without deaths or resets")
	print("ROUTE STATES: ", " | ".join(trace))
	print("ROUTE TIME: %.1f simulated seconds; %d impacts; %d stomps" % [level.elapsed, level.impacts, level.stomps])
	_release()
	level.free()
	await process_frame
	if failures.is_empty():
		print("FOUNDRY FRESH ROUTE PASS: real player inputs, every beat, one persistent Can/Cart, full completion")
		quit(0)
	else:
		for failure in failures:
			printerr("FOUNDRY ROUTE FAIL: ", failure)
		quit(1)

func _step(direction: float = 0.0, jump: bool = false, attack: bool = false) -> void:
	await process_frame
	_hold_action("move_left", direction < -0.1)
	_hold_action("move_right", direction > 0.1)
	if jump and not Input.is_action_pressed("jump"):
		jump_hold = 19
	_hold_action("jump", jump_hold > 0 and not attack)
	jump_hold = maxi(0, jump_hold - 1)
	_hold_action("attack", attack)
	await physics_frame
	frame_count += 1
	if frame_count % 1800 == 0:
		print("ROUTE PROGRESS ", _state())

func _hold_action(action: String, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)

func _release() -> void:
	for action in ["move_left", "move_right", "jump", "attack"]:
		Input.action_release(action)

func _walk(x: float, limit: int = 2200) -> void:
	if not failures.is_empty():
		return
	for i in limit:
		if level.mode == "complete":
			return
		var dx: float = x - level.player.position.x
		if absf(dx) < 5.0:
			await _step()
			return
		var direction := signf(dx)
		var jump := _dodge(direction)
		var halt := false
		for press in level.crushers:
			var distance: float = (press.high.x - level.player.position.x) * direction
			var phase: float = fmod(press.clock, press.cycle_length)
			if not press.disabled and distance > 12.0 and distance < 56.0 and level.player.position.y > 250.0 and phase > 0.25 and phase < 1.85:
				halt = true
		if not halt:
			await _step(direction, jump)
		else:
			await _step()
		if level.deaths > 0:
			_fail("walk to %.0f died" % x)
			return
	_fail("walk to %.0f timed out" % x)

func _dodge(direction: float = 1.0) -> bool:
	if not level.player.is_on_floor():
		return false
	var dx: float = level.can.position.x - level.player.position.x
	if level.can.state not in ["stunned", "recover"] and absf(dx) < 57.0 and absf(dx) > 12.0:
		return true
	var cart_distance: float = (level.cart.position.x - level.player.position.x) * direction
	return cart_distance > 24.0 and cart_distance < 58.0 and level.player.position.y > 267.0

func _bounce(target: Node2D, landing_x: float, landing_top: float, require_rebound: bool = false) -> void:
	if not failures.is_empty():
		return
	var before := rebound_count
	var launched := false
	for i in 1300:
		var player: CharacterBody2D = level.player
		if not require_rebound and player.is_on_floor() and player.position.y < landing_top - 7.0:
			await _walk(landing_x)
			return
		if rebound_count > before:
			launched = true
		if launched:
			var dx := landing_x - player.position.x
			if player.is_on_floor() and player.position.y < landing_top - 7.0 and absf(dx) < 22.0:
				await _step()
				return
			await _step(signf(dx) if absf(dx) > 3.0 else 0.0)
			if player.is_on_floor() and player.position.y > landing_top - 7.0:
				launched = false
				before = rebound_count
		else:
			var dx := target.position.x - player.position.x
			var height := target.position.y - player.position.y
			var useful: bool = target != level.can or (target.position.x > landing_x - 115.0 and target.position.x < landing_x + 95.0)
			var jump: bool = player.is_on_floor() and absf(dx) < 52.0 and useful
			var strike: bool = not player.is_on_floor() and absf(dx) < 19.0 and height >= 24.0 and height < 56.0 and useful
			var direction: float = signf(dx) if absf(dx) > 5.0 else 0.0
			if target == level.cart and player.is_on_floor() and player.position.y > 260.0 and absf(dx) < 40.0:
				direction = -1.0
				jump = false
				strike = false
			if target == level.can and not useful:
				direction = signf(landing_x - player.position.x) if absf(landing_x - player.position.x) > 8.0 else 0.0
			var halt := false
			for press in level.crushers:
				var phase: float = fmod(press.clock, press.cycle_length)
				var nearby: bool = absf(press.high.x - player.position.x) < 65.0 or absf(press.high.x - target.position.x) < 55.0
				if not press.disabled and nearby and phase > 0.1 and phase < 1.85:
					halt = true
			if halt:
				await _step()
			else:
				await _step(direction, jump or _dodge(direction), strike)
		if level.deaths > 0:
			_fail("bounce to %.0f/%.0f died" % [landing_x, landing_top])
			return
	_fail("bounce to %.0f/%.0f timed out" % [landing_x, landing_top])

func _lever(id: String) -> void:
	if not failures.is_empty():
		return
	var lever: Area2D = level.switches[id]
	for i in 700:
		if lever.active:
			await _step()
			return
		var dx: float = lever.position.x - level.player.position.x
		var height: float = lever.position.y - level.player.position.y
		await _step(signf(dx) if absf(dx) > 4.0 else 0.0, level.player.is_on_floor() and absf(dx) < 20.0, not level.player.is_on_floor() and absf(dx) < 16.0 and height > 21.0 and height < 52.0)
		if level.deaths > 0:
			_fail("lever %s died" % id)
			return
	_fail("lever %s timed out" % id)

func _transport(index: int) -> void:
	if not failures.is_empty():
		return
	# The bait remains beyond the Cart. If the Can is in search, it must catch up
	# through the connected facility; nothing moves it or the transport by code.
	var bait: float = level.cart.position.x + 100.0
	if level.cart.station_index >= index:
		return
	if level.cart.target_station < index:
		await _walk(bait)
	for i in 4000:
		if level.cart.station_index >= index:
			await _step()
			return
		await _step(0.0, _dodge())
		if level.deaths > 0 or level.cart.stalled:
			_fail("transport to dock %d died/stalled" % index)
			return
	_fail("transport to dock %d timed out" % index)

func _wait_can_right(x: float) -> void:
	if not failures.is_empty():
		return
	for i in 2200:
		if level.can.position.x > x:
			return
		await _step()
	_fail("Can search right %.0f timed out" % x)

func _wait_can_left(x: float) -> void:
	if not failures.is_empty():
		return
	for i in 2400:
		if level.can.position.x < x:
			return
		await _step()
	_fail("Can search left %.0f timed out" % x)

func _wait_wall(id: String) -> void:
	if not failures.is_empty():
		return
	for i in 2800:
		if level.mechanisms[id].broken:
			return
		await _step(0.0, _dodge())
		if level.deaths > 0:
			_fail("wall %s died" % id)
			return
	_fail("wall %s timed out" % id)

func _mark(beat: String) -> void:
	if failures.is_empty():
		trace.append(beat)
		print("ROUTE BEAT ", beat, " ", _state())

func _state() -> String:
	return "P %s / Can %s %s / Cart %s %d->%d / mode %s / frame %d" % [level.player.position, level.can.position, level.can.state, level.cart.position, level.cart.station_index, level.cart.target_station, level.mode, frame_count]

func _fail(message: String) -> void:
	failures.append(message + " / " + _state())
	_release()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)
