extends SceneTree

const RamScript = preload("res://scripts/enemy.gd")
const PressureScript = preload("res://scripts/can_pressure_switch.gd")
const FanScript = preload("res://scripts/can_fan.gd")
const LaserScript = preload("res://scripts/can_laser_rig.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_can_intent_and_wedge()
	await _test_switch_and_fan()
	await _test_laser_sensor()
	await _test_campaign_integration()
	if failures.is_empty():
		print("CAN SYSTEMS PASS: intent, bounce state, wedge, switch, fan, laser, sensor, bridge, and reversal")
		quit(0)
	else:
		for failure in failures:
			printerr("CAN SYSTEMS FAIL: ", failure)
		quit(1)

func _test_can_intent_and_wedge() -> void:
	var ram = RamScript.new()
	ram.configure_systemic_ram(Vector2(100, 100), 20.0, 300.0)
	root.add_child(ram)
	ram.set_physics_process(false)
	ram.facing = 1
	ram.velocity_x = 0.0
	ram.state = "windup"
	ram.state_time = 0.01
	ram._update_kinetic_ram(0.02)
	_check(ram.state == "coast" and ram.velocity_x > 100.0, "Can telegraph commits to its locked direction")
	ram.wedge_at(Vector2(140, 100))
	_check(ram.wedged and ram.state == "wedged" and is_zero_approx(ram.velocity_x), "Can can remain wedged as a persistent heavy resource")
	ram.receive_kinetic_strike(120.0)
	_check(not ram.wedged and ram.state == "coast" and ram.velocity_x > 100.0, "player strike releases and redirects a wedged Can")
	ram.free()
	await process_frame

func _test_switch_and_fan() -> void:
	var pressure = PressureScript.new()
	pressure.configure(Vector2(100, 180), "TEST")
	root.add_child(pressure)
	pressure.set_pressed(true)
	_check(pressure.pressed, "wedged Can state can hold a pressure switch")
	var fan = FanScript.new()
	fan.configure(Vector2(200, 180), 120.0)
	root.add_child(fan)
	fan.set_active(pressure.pressed)
	var body := CharacterBody2D.new()
	body.global_position = Vector2(200, 140)
	body.velocity = Vector2.ZERO
	root.add_child(body)
	fan.lift(body, 0.1)
	_check(fan.active and body.velocity.y < -70.0, "active fan consistently applies readable upward force")
	pressure.set_pressed(false)
	fan.set_active(pressure.pressed)
	var before := body.velocity.y
	fan.lift(body, 0.1)
	_check(not fan.active and is_equal_approx(body.velocity.y, before), "fan turns off when weight leaves the switch")
	body.free()
	fan.free()
	pressure.free()
	await process_frame

func _test_laser_sensor() -> void:
	var laser = LaserScript.new()
	laser.configure(Vector2(100, 100), Vector2(220, 100), 2)
	root.add_child(laser)
	await process_frame
	_check(not laser.sensor_active, "misaligned beam does not activate sensor")
	var returned: float = laser.receive_ram_impact(130.0)
	_check(laser.orientation_index == 0 and laser.sensor_active, "Can force rotates emitter and aligned beam activates sensor")
	_check(returned < 0.0, "laser support returns predictable collision momentum")
	laser.set_orientation(2)
	_check(not laser.sensor_active, "sensor deterministically follows beam orientation")
	laser.free()
	await process_frame

func _test_campaign_integration() -> void:
	var level = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	_check(level.LEVEL_COUNT == 7 and level.mode == "card", "campaign opens with seven short staged levels")

	level._build_level(0)
	level.ram.set_physics_process(false)
	level.ram.monitoring = false
	level.player.global_position = level.ram.global_position + Vector2(0, -27)
	level.player.velocity = Vector2(70, 20)
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	_check(level.player.velocity.y < -180.0, "player consistently rebounds from the Can")

	level._build_level(1)
	level.ram.wedge_at(level.wedge_position)
	level._update_pressure_logic()
	_check(level.pressure.pressed and level.fan.active, "campaign Can-switch-fan loop sustains traversal")
	level.player.global_position = level.fan.global_position + Vector2(0, -30)
	level.player.velocity = Vector2.ZERO
	level.fan.lift(level.player, 0.1)
	_check(level.player.velocity.y < 0.0, "campaign fan lifts the real player controller")

	level._build_level(3)
	level.ram.global_position = level.wedge_position
	level.ram.wedged = false
	level.wedge_release_grace = 0.0
	level._update_pressure_logic()
	_check(level.mode == "failure" and level.unsafe_commits == 1, "early Can commitment creates a fast educational reversal")
	level.failure_ticket += 1

	level._build_level(4)
	level.laser.receive_ram_impact(130.0)
	_check(level.laser.sensor_active and is_instance_valid(level.bridge_body), "laser sensor deterministically builds the world bridge")

	level.mode = "campaign_complete"
	level.player.active = false
	level.ram.set_physics_process(false)
	level.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
