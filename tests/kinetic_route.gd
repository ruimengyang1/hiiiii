extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	for index in game.LEVEL_COUNT:
		game._build_level(index)
		await process_frame
		_check(game.mode == "play" and game.level_index == index and game.player.active, "%s fresh spawn is playable" % game.LEVEL_TITLES[index])
		game.player.global_position = game.goal_position
		game._update_exit()
		_check(game.mode == "play", "T/U: %s exit cannot trigger before its visible mechanism route is active" % game.LEVEL_TITLES[index])
		if index > 0:
			var required_rise: float = [0.0, 108.0, 108.0, 60.0][index]
			var normal_jump_rise: float = game.player.JUMP_SPEED * game.player.JUMP_SPEED / (2.0 * game.player.GRAVITY)
			_check(normal_jump_rise < required_rise, "T: %s critical ledge exceeds ordinary jump height" % game.LEVEL_TITLES[index])
		_solve_visible_state(game, index)
		if index == 3:
			_check(game.pressure.pressed and game.fan.active and game.laser.sensor_active and game.primary_platform.active, "S: Level 4 combines Boulder/Button/Fan with Laser/Sensor/Platform using known rules")
		game.player.global_position = game.goal_position
		game._update_exit()
		_check(game.mode == "transition", "%s accepts physical arrival after its world relationship is solved" % game.LEVEL_TITLES[index])
		game.completion_ticket += 1

	game._build_level(3)
	var preserved_index: int = game.level_index
	var before_restart: int = game.completion_ticket
	Input.action_press("restart")
	await physics_frame
	Input.action_release("restart")
	await process_frame
	_check(game.level_index == preserved_index and game.mode == "play" and game.completion_ticket > before_restart, "V: R reconstructs only the active room")
	game.player.kill()
	await create_timer(0.5).timeout
	_check(game.level_index == 3 and game.mode == "play", "W: death restarts the current room without erasing progression")

	game._finish_demo()
	_check(game.mode == "complete" and game.result_panel.visible and "4 LEVELS COMPLETE" in game.result_label.text, "four-level demo ends with a clear mastery result")
	game.player.active = false
	game.can.set_physics_process(false)
	game.free()
	await process_frame
	if failures.is_empty():
		print("FINAL DEMO ROUTE PASS: P–W — four fresh solved states, anti-skip exits, restart, and progression retention")
		quit(0)
	else:
		for failure in failures:
			printerr("FINAL DEMO ROUTE FAIL: ", failure)
		quit(1)

func _solve_visible_state(game: Node, index: int) -> void:
	match index:
		0:
			game.target_a.set_active(true)
			game.target_b.set_active(true)
			game._update_level_1()
		1:
			game.pressure.set_pressed(true)
			game.cargo_platform.position = game.cargo_platform.active_position
			game._update_level_2()
		2:
			game.laser.sensor_active = true
			game.primary_platform.set_active(true)
			game.primary_platform.sync_to_physics = false
			game.primary_platform.position = game.primary_platform.active_position
			game._update_level_3(0.0)
		3:
			game.pressure.set_pressed(true)
			game.laser.sensor_active = true
			game.l4_lift_delay = 0.0
			game.primary_platform.set_active(true)
			game.primary_platform.sync_to_physics = false
			game.primary_platform.position = game.primary_platform.active_position
			game._update_level_4(0.0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
