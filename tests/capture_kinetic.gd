extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/kinetic_prototype.tscn") as PackedScene
	var prototype = scene.instantiate()
	root.add_child(prototype)
	await process_frame
	prototype.player.invulnerable_time = 0.0
	await create_timer(0.2).timeout
	if not _save(OS.get_temp_dir().path_join("system_link_start.png")):
		printerr("KINETIC CAPTURE FAIL")
		quit(1)
		return
	prototype.carriage.force_station(2)
	prototype._on_cart_station_changed(2)
	prototype.ram.position = Vector2(850, 172)
	prototype.ram.state = "windup"
	prototype.ram.state_time = 0.3
	prototype.player.global_position = Vector2(900, 140)
	prototype.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save(OS.get_temp_dir().path_join("system_link_cutoff.png")):
		quit(1)
		return
	prototype._on_switch_activated("strike", prototype.safety_switch.position)
	prototype.carriage.force_station(3)
	prototype._on_cart_station_changed(3)
	prototype.ram.position = Vector2(1115, 172)
	prototype.ram.state = "windup"
	prototype.ram.state_time = 0.3
	prototype.player.global_position = Vector2(1000, 145)
	prototype.camera.reset_smoothing()
	await create_timer(0.12).timeout
	if not _save(OS.get_temp_dir().path_join("system_link_ram_lock.png")):
		quit(1)
		return
	print("SYSTEM LINK CAPTURE PASS: start, cut-off, and ram lock")
	prototype.free()
	await process_frame
	quit(0)

func _save(path: String) -> bool:
	var image := root.get_texture().get_image()
	return image != null and image.save_png(path) == OK
