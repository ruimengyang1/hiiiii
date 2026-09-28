extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(campaign)
	await process_frame
	for index in campaign.LEVEL_COUNT:
		campaign._build_level(index)
		await process_frame
		_check(campaign.mode == "play" and campaign.player.active, "level %d starts from a fresh playable spawn" % (index + 1))
		_solve_state(campaign, index)
		campaign._update_goal_state()
		_check(campaign.goal_enabled, "level %d has a complete state route" % (index + 1))
		campaign.player.global_position = campaign.goal_position
		campaign._update_goal_state()
		_check(campaign.mode == "transition", "level %d accepts its solved state at the exit" % (index + 1))
		campaign.failure_ticket += 1

	campaign.level_index = 6
	campaign._finish_campaign()
	_check(campaign.mode == "campaign_complete" and campaign.result_panel.visible and "7 SHORT SYSTEM LEVELS CLEARED" in campaign.result_label.text, "seven-level campaign produces a clear mastery finish")
	campaign.mode = "campaign_complete"
	if is_instance_valid(campaign.player):
		campaign.player.active = false
	if is_instance_valid(campaign.ram):
		campaign.ram.set_physics_process(false)
	campaign.free()
	await process_frame
	if failures.is_empty():
		print("CAN CAMPAIGN ROUTE PASS: all seven fresh spawns, two reversals, combination level, and mastery finish")
		quit(0)
	else:
		for failure in failures:
			printerr("CAN CAMPAIGN ROUTE FAIL: ", failure)
		quit(1)

func _solve_state(campaign: Node, index: int) -> void:
	match index:
		0:
			campaign.goal_enabled = true
		1, 2:
			campaign.ram.wedge_at(campaign.wedge_position)
			campaign._update_pressure_logic()
		3:
			campaign.upper_latch = true
			campaign.ram.wedge_at(campaign.wedge_position)
			campaign._update_pressure_logic()
		4:
			campaign.laser.receive_ram_impact(130.0)
		5:
			# Laser-first is one valid order; switch-first is tested separately below.
			campaign.laser.receive_ram_impact(130.0)
			campaign.ram.wedge_at(campaign.wedge_position)
			campaign._update_pressure_logic()
			_check(campaign.fan.active and campaign.laser.sensor_active, "level 6 combines held fan power and laser sensor response")
		6:
			var rejected_before: int = campaign.unsafe_commits
			campaign.laser.receive_ram_impact(130.0)
			_check(campaign.unsafe_commits == rejected_before + 1 and not campaign.laser.sensor_active, "level 7 reveals that an unpowered laser impact is incomplete")
			campaign.ram.wedge_at(campaign.wedge_position)
			campaign._update_pressure_logic()
			campaign.power_latch = true
			campaign._update_mastery_power()
			campaign.laser.receive_ram_impact(130.0)
			_check(campaign.fan.active and campaign.laser.sensor_active, "level 7 chains switch, fan, power latch, laser, and sensor")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
