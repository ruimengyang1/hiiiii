extends SceneTree

var level: Node2D
var folder := "res://artifacts/screenshots"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	level = (load("res://scenes/foundry_legacy.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level._freeze_world(true)
	await _stage(0, Vector2(210, 291), Vector2(125, 290), "windup")
	level.hint_time = 6.0
	level._update_ui()
	await _save("01_inspection")
	await _stage(0, Vector2(765, 251), Vector2(665, 290), "windup")
	await _save("02_discovery")
	await _stage(1, Vector2(1090, 211), Vector2(1070, 290), "windup")
	await _save("03_force_transfer")
	await _stage(2, Vector2(1810, 291), Vector2(1710, 290), "windup")
	await _save("04_roof_or_progress")
	await _stage(3, Vector2(2050, 291), Vector2(1948, 290), "stunned")
	level.mechanisms.yard_plate.refresh_weight(0.0)
	await _save("05_weight_circuit")
	await _stage(6, Vector2(3070, 259), Vector2(2908, 290), "idle")
	level.cart.restore({"x": 3088.0, "station": 6, "target": 7, "stalled": true, "mood": "pointing"})
	level.cart.suspended = false
	await physics_frame
	await physics_frame
	level.cart.suspended = true
	await _save("06_stalled_roof_recovery")
	await _stage(7, Vector2(3510, 291), Vector2(3440, 290), "stunned")
	level.mechanisms.escape_wall.broken = true
	level.mechanisms.escape_wall.active = true
	level.mechanisms.escape_wall.body.collision_layer = 0
	level._complete()
	await _save("07_complete")
	print("FOUNDRY CAPTURE PASS: ", ProjectSettings.globalize_path(folder))
	level.free()
	await process_frame
	quit(0)

func _stage(index: int, player_at: Vector2, can_at: Vector2, state: String) -> void:
	if index >= 1:
		level.switches.inspection.active = true
		level.mechanisms.inspection_gate.latch_open()
	if index >= 2:
		level.switches.freight.active = true
		level.mechanisms.freight_gate.latch_open()
		level.mechanisms.freight_pin.latch_open()
		level.mechanisms.transfer_wall.broken = true
		level.mechanisms.transfer_wall.active = true
		level.mechanisms.transfer_wall.body.collision_layer = 0
	if index >= 4:
		level.switches.vent.active = true
		level.switches.yard_release.active = true
		level.mechanisms.vent_gate.latch_open()
		level.mechanisms.weight_gate.latch_open()
	if index >= 5:
		level.switches.pump.active = true
		level.mechanisms.pump_gate.latch_open()
		level.switches.isolation.active = true
		level.crushers[-1].disabled = true
	level.cart.force_station(index)
	level.cart.suspended = false
	await physics_frame
	await physics_frame
	await physics_frame
	level.cart.suspended = true
	level.player.position = player_at
	level.can.position = can_at
	level.can.state = state
	level.can.facing = 1
	level.can.state_time = 5.0 if state == "stunned" else 0.55
	level.can.suspended = true
	level.hint_time = 0.0
	level.notice_time = 0.0
	level._update_ui()
	level.camera.reset_smoothing()
	level.queue_redraw()
	await process_frame
	await process_frame

func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
	if result != OK:
		printerr("FOUNDRY CAPTURE FAIL: ", name)
		quit(1)
