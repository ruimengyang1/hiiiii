extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level = load("res://scenes/yard_sandbox.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	level._freeze(true)
	level.player.invulnerable_time = 0
	level.player.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/third_redesign/sandbox_initial.png")
	level.free()
	await process_frame
	print("SANDBOX INITIAL CAPTURE PASS")
	quit(0)
