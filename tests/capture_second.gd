extends SceneTree

var level: Node2D
const FOLDER := "res://artifacts/second_redesign/screenshots"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1152, 648)
	DirAccess.make_dir_recursive_absolute(FOLDER)
	level = load("res://scenes/foundry_second.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	for index in 4:
		level.room_index = index
		level._build_room()
		await physics_frame
		await physics_frame
		level._freeze(true)
		level.pause_frames = 0
		level.player.position = Vector2(42, 291)
		level.player.invulnerable_time = 0
		level.player.queue_redraw()
		level.can.position = Vector2(65 if index > 0 else 205, 290)
		level.can.state = "windup"
		level.can.facing = 1
		level.can.state_time = 0.35
		level.can.queue_redraw()
		level.hint_time = 0
		level.queue_redraw()
		await save("%02d_%s" % [index + 1, level.TITLES[index].to_lower()])
	# Additional state comparison shows support and hazard conversion clearly.
	level.cart.force_station(1)
	level.cart.suspended = false
	await physics_frame
	await physics_frame
	level.cart.suspended = true
	level.crusher.suspended = false
	await physics_frame
	await physics_frame
	level.crusher.suspended = true
	level.mechanisms.plate.refresh_weight(0)
	level.mechanisms.bridge.extension = 1
	level.mechanisms.bridge.queue_redraw()
	level.can.state = "idle"
	level.can.queue_redraw()
	await save("05_cart_weight")
	level.cart.force_station(2)
	level.cart.suspended = false
	await physics_frame
	await physics_frame
	level.cart.suspended = true
	level.can.position = Vector2(185, 290)
	level.can.receive_environmental_stun("crusher")
	level.pause_frames = 0
	level.crusher.suspended = false
	await physics_frame
	await physics_frame
	level.crusher.suspended = true
	level.can.queue_redraw()
	level.mechanisms.plate.refresh_weight(0)
	await save("06_can_weight")
	# Captures run faster than real-time audio. Release the last generated
	# grounding voice before exiting the renderer.
	for voice in level.sound.get_children():
		if voice is AudioStreamPlayer:
			voice.stop()
	level.free()
	await process_frame
	await process_frame
	print("SECOND CAPTURE PASS: four rooms and two weight configurations")
	quit(0)

func save(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var status := root.get_texture().get_image().save_png(FOLDER.path_join(filename + ".png"))
	if status != OK:
		printerr("CAPTURE FAIL: ", filename)
		quit(1)
