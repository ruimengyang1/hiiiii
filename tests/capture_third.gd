extends SceneTree

# Staged visual inspections, deliberately separate from input-only route proof.
var level: Node2D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/third_redesign/screenshots")
	level = load("res://scenes/foundry.tscn").instantiate()
	root.add_child(level)
	await frames(3)
	level.set_physics_process(false)
	level._freeze(true)
	await capture("01_initial_space")
	level.can.state = "windup"
	level.can.state_time = 0.28
	level.can.facing = 1
	level.player.position = Vector2(222, 291)
	await capture("02_locked_intent")
	await station(0)
	level.can.position = Vector2(110, 290)
	level.can.state = "idle"
	level.player.position = Vector2(165, 165)
	await capture("04_cart_A_loft")
	await station(1)
	level.player.position = Vector2(325, 209)
	level.crusher.position.y = 246
	level.crusher.shielded = true
	await capture("05_cart_B_support_shield")
	await station(2)
	level.mechanisms.plate.refresh_weight(1)
	level.mechanisms.catwalk.extension = 0
	level.crusher.shielded = false
	level.crusher.position.y = 255
	level.crusher.was_warning = true
	level.can.position = Vector2(252, 290)
	level.player.position = Vector2(278, 281)
	await capture("06_shared_crusher_threat")
	level.can.receive_environmental_stun("crusher")
	level.can.position.x = 260
	level.mechanisms.plate.refresh_weight(0)
	level.mechanisms.catwalk.extension = 1
	level.player.position = Vector2(330, 209)
	await capture("07_grounded_weight_route")
	# Same position, opposite utility: no heavy object, charge aimed at material.
	level.can.position = Vector2(390, 290)
	level.can.state = "windup"
	level.can.state_time = 0.22
	level.can.ground_body.collision_layer = 0
	level.player.position = Vector2(433, 268)
	level.mechanisms.plate.refresh_weight(1)
	level.mechanisms.catwalk.extension = 0
	await capture("08_active_force_retained")
	level.can.state = "idle"
	level.can.position = Vector2(215, 290)
	level.player.position = Vector2(316, 240)
	level.crusher.position.y = 185
	level.crusher.was_warning = false
	await capture("09_forward_cost_missing_bridge")
	# Actual simultaneous rebound/Cart chain, not a drawn pose.
	await station(1)
	level.can.position = Vector2(145, 290)
	level.can.state = "windup"
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	level.player.reset_at(Vector2(190, 247))
	level.player.velocity.y = 100
	level.crusher.clock = 1.55
	level.pause_frames = 0
	level.set_physics_process(true)
	level._freeze(false)
	for i in 25:
		await physics_frame
		if i == 15:
			level.set_physics_process(false)
			level._freeze(true)
			await capture("03_rebound_continuing_charge")
			level.set_physics_process(true)
			level._freeze(false)
	level.set_physics_process(false)
	level._freeze(true)
	await capture("10_bounce_cart_chain")
	for voice in level.sound.get_children():
		if voice is AudioStreamPlayer: voice.stop()
	level.free()
	await process_frame
	print("THIRD CAPTURES PASS: ten native relationship inspections")
	quit(0)

func station(index: int) -> void:
	level.cart.force_station(index)
	level.cart.suspended = false
	await frames(3)
	level.cart.suspended = true
	level.mechanisms.plate.refresh_weight(1)
	level.mechanisms.catwalk.extension = 1 if level.mechanisms.catwalk.active else 0

func capture(name: String) -> void:
	level.camera.offset = Vector2.ZERO
	level.player.invulnerable_time = 0
	for actor in [level, level.player, level.can, level.cart, level.crusher]: actor.queue_redraw()
	for item in level.mechanisms.values(): item.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/third_redesign/screenshots/" + name + ".png")

func frames(n: int) -> void:
	for i in n: await physics_frame
