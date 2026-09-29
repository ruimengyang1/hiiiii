extends SceneTree

var game: Node
var output_dir := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://artifacts/final_demo/screenshots")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame

	game._build_level(0)
	game.can.state = "windup"
	game.can.state_time = 0.34
	game.can.facing = 1
	await _capture("01_l1_telegraph.png")
	game.target_a.set_active(true)
	game.target_a.sync_to_physics = false
	game.target_a.position = game.target_a.active_position
	game.can.position = Vector2(145, 180)
	game.can.state = "recover"
	await _capture("02_l1_target_impact.png")

	game._build_level(1)
	game.can.position = Vector2(127, 180)
	game.can.velocity_x = 150.0
	game.can.state = "coast"
	await _capture("03_l2_can_to_boulder.png")
	game.boulder.sync_to_physics = false
	game.boulder.position = game.pressure.position + Vector2(0, -8)
	game.pressure.refresh_weight()
	await _capture("04_l2_boulder_weight.png")
	game.player.position = game.fan.position + Vector2(0, -54)
	game.player.velocity = Vector2(0, -180)
	await _capture("05_l2_fan_lift.png")
	game.cargo_platform.sync_to_physics = false
	game.cargo_platform.position = Vector2(game.fan.position.x, 116)
	game.player.position = Vector2(game.fan.position.x, 138)
	await _capture("06_l2_reversal.png")

	game._build_level(2)
	var slot3 := Vector2(game.laser.position.x, game.FLOOR_Y - 10)
	game.can.hold_at(slot3, 2.0)
	game._update_rotator()
	await _capture("07_l3_can_on_rotator.png")
	var target_angle3: float = game.laser.global_position.direction_to(game.laser.sensor_position).angle()
	game.laser.set_angle(target_angle3 - 0.12)
	await _capture("08_l3_approaching_sensor.png")
	game.laser.set_angle(target_angle3 - 0.035)
	game.can.state = "windup"
	game.can.state_time = 0.28
	game.can.facing = 1
	await _capture("09_l3_bait_away.png")
	game.laser.set_angle(target_angle3)
	game.rotator_has_can = false
	game.rotator_grace = 1.0
	game.can.position = Vector2(250, 180)
	game.laser.set_rotator_occupied(false)
	game.primary_platform.set_active(true)
	game.primary_platform.sync_to_physics = false
	game.primary_platform.position = game.primary_platform.active_position
	game.player.position = game.primary_platform.position + Vector2(0, -14)
	game.exit_enabled = true
	await _capture("10_l3_platform_active.png")

	game._build_level(3)
	await _capture("11_l4_full_layout.png")
	game.laser.set_angle(PI)
	await _capture("12_l4_boulder_blocks_beam.png")
	game.boulder.sync_to_physics = false
	game.boulder.position = game.pressure.position + Vector2(0, -8)
	game.pressure.refresh_weight()
	var slot4 := Vector2(game.laser.position.x, game.FLOOR_Y - 10)
	game.can.hold_at(slot4, 0.0)
	game.can.state = "windup"
	game.can.state_time = 0.32
	game.can.facing = -1
	var target_angle4: float = game.laser.global_position.direction_to(game.laser.sensor_position).angle()
	game.laser.set_angle(target_angle4 - 0.16)
	game.laser.set_rotator_occupied(true)
	await _capture("13_l4_expert_chain.png")
	game.laser.set_angle(target_angle4)
	game.laser.set_rotator_occupied(false)
	game.primary_platform.set_active(true)
	game.primary_platform.sync_to_physics = false
	game.primary_platform.position = game.primary_platform.active_position
	game.can.hold_at(game.primary_platform.position + Vector2(0, -14), 0.0)
	await _capture("14_l4_platform_carries_can.png")
	game._set_exit_enabled(true)
	game.player.position = game.goal_position
	await _capture("15_l4_victory.png")

	print("FINAL DEMO CAPTURE PASS: 15 teaching, consequence, reversal, combination, and victory states")
	game.free()
	await process_frame
	quit(0)

func _capture(filename: String) -> void:
	game.opener_time = 0.0
	game.announcement_time = 0.0
	game._update_ui_visibility()
	game.queue_redraw()
	await process_frame
	await create_timer(0.08).timeout
	var image := root.get_texture().get_image()
	if image == null or image.save_png(output_dir.path_join(filename)) != OK:
		printerr("CAPTURE FAILED: ", filename)
		quit(1)
