extends SceneTree

const CanScript = preload("res://scripts/enemy.gd")
const PlayerScript = preload("res://scripts/player.gd")
const BoulderScript = preload("res://scripts/can_boulder.gd")
const PressureScript = preload("res://scripts/can_pressure_switch.gd")
const FanScript = preload("res://scripts/can_fan.gd")
const LaserScript = preload("res://scripts/can_laser_rig.gd")
const PlatformScript = preload("res://scripts/can_moving_platform.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_inputs()
	await _test_intent_lock_and_impact()
	await _test_rebound()
	await _test_boulder_weight_fan()
	await _test_continuous_laser_and_platform()
	await _test_campaign_integration()
	if failures.is_empty():
		print("FINAL DEMO SYSTEMS PASS: A–O — Can intent/lock/impact/rebound, Boulder weight, fan, continuous laser, sensor, platform")
		quit(0)
	else:
		for failure in failures:
			printerr("FINAL DEMO SYSTEMS FAIL: ", failure)
		quit(1)

func _test_intent_lock_and_impact() -> void:
	var target = PlayerScript.new()
	target.position = Vector2(220, 100)
	root.add_child(target)
	target.set_physics_process(false)
	var can = CanScript.new()
	can.configure_systemic_ram(Vector2(100, 100), 20.0, 300.0)
	can.trigger_range = 180.0
	root.add_child(can)
	can.set_physics_process(false)
	can.cooldown = 0.0
	can.state = "idle"
	can._update_kinetic_ram(0.01)
	_check(can.state == "windup" and can.facing == 1, "A/B: Can telegraphs and locks toward the player's initial side")
	target.position.x = 20.0
	can._update_kinetic_ram(0.56)
	_check(can.state == "coast" and can.velocity_x > 100.0 and can.facing == 1, "C: Can does not track a player who crosses sides after lock")

	var boulder = BoulderScript.new()
	boulder.configure(Vector2(126, 100), 110.0, 240.0)
	root.add_child(boulder)
	boulder.set_physics_process(false)
	can.global_position = Vector2(101, 100)
	can.velocity_x = 150.0
	can.contact_cooldown = 0.0
	can._check_ram_receivers()
	_check(boulder.velocity_x > 100.0 and can.velocity_x < 0.0, "D/F: a committed Can impact transfers reliable force into a Boulder")
	var before_x: float = boulder.position.x
	boulder._physics_process(0.2)
	_check(boulder.position.x > before_x or boulder.velocity_x > 0.0, "G: Boulder travel direction follows impact direction deterministically")
	boulder.free()
	can.free()
	target.free()
	await process_frame

func _test_rebound() -> void:
	var can = CanScript.new()
	can.configure_systemic_ram(Vector2(120, 180), 20.0, 300.0)
	root.add_child(can)
	can.set_physics_process(false)
	can.monitoring = false
	var player = PlayerScript.new()
	player.position = can.position + Vector2(0, -27)
	player.velocity = Vector2(70, 35)
	root.add_child(player)
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	_check(player.velocity.y < -180.0, "E: downward contact gives a consistent generous Can rebound")
	player.free()
	can.free()
	await process_frame

func _test_boulder_weight_fan() -> void:
	var boulder = BoulderScript.new()
	boulder.configure(Vector2(120, 176), 80.0, 220.0)
	root.add_child(boulder)
	var pressure = PressureScript.new()
	pressure.configure(Vector2(120, 184), "TEST WEIGHT")
	root.add_child(pressure)
	var fan = FanScript.new()
	fan.configure(Vector2(200, 184), 120.0)
	root.add_child(fan)
	pressure.changed.connect(func(active: bool) -> void: fan.set_active(active))
	pressure.refresh_weight()
	_check(pressure.pressed, "H: generic Boulder mass holds a Weight Button")
	_check(fan.active, "I: held Button state immediately activates Fan")
	var body := CharacterBody2D.new()
	body.position = Vector2(200, 140)
	root.add_child(body)
	fan.lift(body, 0.1)
	_check(body.velocity.y < -70.0, "J: active Fan applies readable upward force")
	boulder.sync_to_physics = false
	boulder.global_position = Vector2(200, 176)
	pressure.refresh_weight()
	var before := body.velocity.y
	fan.lift(body, 0.1)
	_check(not pressure.pressed and not fan.active and is_equal_approx(body.velocity.y, before), "K: Button and Fan deactivate when heavy weight leaves")
	body.free()
	fan.free()
	pressure.free()
	boulder.free()
	await process_frame

func _test_continuous_laser_and_platform() -> void:
	var laser = LaserScript.new()
	laser.configure(Vector2(100, 150), Vector2(220, 100), -PI * 0.5)
	root.add_child(laser)
	laser.set_physics_process(false)
	var start_angle: float = laser.beam_angle
	laser.set_rotator_occupied(true)
	laser._physics_process(0.5)
	_check(laser.beam_angle > start_angle + 0.2, "L: Can occupancy changes Laser angle continuously over time")
	laser.set_rotator_occupied(false)
	var frozen_angle: float = laser.beam_angle
	laser._physics_process(0.5)
	_check(is_equal_approx(laser.beam_angle, frozen_angle), "M: leaving the Rotator freezes the current angle")

	var lock_laser = LaserScript.new()
	lock_laser.configure(Vector2(100, 150), Vector2(220, 150), -0.2)
	lock_laser.sensor_lock_duration = 1.0
	root.add_child(lock_laser)
	lock_laser.set_physics_process(false)
	lock_laser.set_rotator_occupied(true)
	lock_laser._physics_process(0.4)
	var dwell_angle: float = lock_laser.beam_angle
	_check(lock_laser.sensor_active and lock_laser.sensor_lock_time > 0.9, "L/N: Stage 3-style sensor alignment starts a visible one-second rotation lock")
	lock_laser._physics_process(0.4)
	_check(is_equal_approx(lock_laser.beam_angle, dwell_angle) and lock_laser.sensor_lock_time < 0.7, "L: Laser angle remains fixed while the sensor-lock countdown is active")
	lock_laser.set_rotator_occupied(false)
	lock_laser._physics_process(0.2)
	_check(is_equal_approx(lock_laser.beam_angle, dwell_angle), "M: baiting Can away during sensor lock preserves the aligned angle")
	lock_laser.free()

	var platform = PlatformScript.new()
	platform.configure(Vector2(250, 180), Vector2(250, 100), Vector2(50, 10), "TEST")
	root.add_child(platform)
	laser.sensor_changed.connect(func(active: bool) -> void: platform.set_active(active))
	var sensor_angle: float = laser.global_position.direction_to(laser.sensor_position).angle()
	laser.set_angle(sensor_angle)
	_check(laser.sensor_active, "N: geometric beam overlap activates Sensor")
	platform.set_active(laser.sensor_active)
	var platform_start: Vector2 = platform.position
	await create_timer(0.2).timeout
	_check(platform.active and platform.position.y < platform_start.y, "O: active Sensor moves its linked Platform")
	platform.free()
	laser.free()
	await process_frame

func _test_campaign_integration() -> void:
	var game = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	_check(game.LEVEL_COUNT == 4 and game.mode == "start", "main demo contains exactly four focused levels")
	game._build_level(0)
	game.target_a.receive_ram_impact(150.0)
	_check(game.target_a.active and game.target_a.is_ram_passthrough(), "Level 1's first moved force target no longer blocks the reproduced charge")
	game._build_level(1)
	game.can.set_physics_process(false)
	game.boulder.receive_ram_impact(150.0)
	await create_timer(0.85).timeout
	game.pressure.refresh_weight()
	_check(game.boulder.position.x > 195.0 and game.pressure.pressed and game.fan.active and game.cargo_platform.active, "Level 2 realizes the physical Can → Boulder → Weight → Fan + Cargo chain")
	game._build_level(2)
	game.can.hold_at(Vector2(game.laser.position.x, game.FLOOR_Y - 10), 2.0)
	game._update_rotator()
	_check(game.rotator_has_can and game.laser.rotator_occupied and is_equal_approx(game.laser.sensor_lock_duration, 1.0), "Level 3 physically holds Can on a continuous Rotator with an actionable sensor-lock window")
	game.mode = "complete"
	game.player.active = false
	game.can.set_physics_process(false)
	game.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ensure_inputs() -> void:
	for action in ["move_left", "move_right", "aim_up", "aim_down", "jump", "attack", "dash", "restart"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
