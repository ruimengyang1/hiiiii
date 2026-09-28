extends SceneTree

const Can = preload("res://scripts/action_can.gd")
const Cart = preload("res://scripts/action_cart.gd")
const Player = preload("res://scripts/action_player.gd")
var failures: Array[String] = []
var room: Node2D
var can: Area2D
var cart: AnimatableBody2D
var player: CharacterBody2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	room = Node2D.new()
	root.add_child(room)
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(384, 30)
	collision.shape = shape
	floor_body.position = Vector2(192, 315)
	floor_body.add_child(collision)
	room.add_child(floor_body)
	cart = Cart.new()
	cart.configure_systemic(Vector2(190, 284), PackedFloat32Array([110, 190, 270]))
	room.add_child(cart)
	cart.force_station(1)
	can = Can.new()
	can.configure_systemic_ram(Vector2(65, 290), 20, 364)
	room.add_child(can)
	player = Player.new()
	player.position = Vector2(130, 291)
	room.add_child(player)
	player.strike_shape.size = Vector2(22, 14)
	player.set_physics_process(false)
	await frames(4)
	can.cooldown = 0.0
	await frames(1)
	check(can.state == "windup" and can.facing == 1, "bait starts readable rightward windup")
	player.position.x = 25
	await frames(35)
	check(can.state == "charging" and can.facing == 1, "A: moving behind locked Can never redirects charge")
	var before: float = can.position.x
	var remaining: float = can.state_time
	can.receive_kinetic_strike(0.0)
	check(can.state == "charging" and can.state_time == remaining, "C: charging stomp preserves committed duration")
	await frames(10)
	check(can.position.x > before + 25 and can.state == "charging", "charging rebound keeps the robot moving")
	await frames(25)
	check(cart.target_station == 2, "real committed charge impacts Cart during player escape")
	await frames(15)
	check(cart.station_index == 2 and can.state not in ["stunned", "recover"], "B/K: impact and move both reusable within a second")
	can.position = Vector2(110, 290)
	can.state = "idle"
	can.receive_kinetic_strike(0.0)
	check(can.state == "stagger" and can.plate_mass() == 0, "normal stomp is short stagger, never heavy weight")
	await frames(27)
	check(can.state != "stagger" and can.state != "stunned", "ordinary stagger ends within 0.45 seconds")
	can.charge_enabled = false
	can.position = Vector2(110, 290)
	can.state = "idle"
	can.cooldown = 1.0
	player.reset_at(Vector2(110, 252))
	player.velocity.y = 100
	player.set_physics_process(true)
	await frames(7)
	check(player.velocity.y < -240, "forgiving descending contact automatically produces strong rebound")
	check(can.state == "stagger", "automatic rebound uses normal short stagger")
	# Real descending player contact during a committed charge, followed by a
	# real Cart impact. No receive_strike call substitutes for this signature.
	cart.force_station(1)
	can.charge_enabled = true
	can.position = Vector2(65, 290)
	can.state = "windup"
	can.state_time = 0.01
	can.facing = 1
	can.contact_cooldown = 0
	player.reset_at(Vector2(110, 247))
	player.velocity.y = 100
	var contact := {"during_charge": false}
	player.rebounded.connect(func(_at: Vector2) -> void: contact.during_charge = can.state == "charging")
	await frames(16)
	check(contact.during_charge and player.velocity.y < -170 and can.state == "charging", "signature: actual bounce launches player while Can continues charge")
	await frames(20)
	check(cart.target_station == 2, "signature: the same uninterrupted charge impacts Cart")
	can.receive_environmental_stun("hard impact")
	check(can.state == "stunned" and can.plate_mass() == 2 and can.ground_body.collision_layer == 1, "D/H: only environment produces safe solid heavy shell")
	# Independently verify the actual solid-wall collision branch.
	var wall := StaticBody2D.new()
	var wall_collision := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(12, 35)
	wall_collision.shape = wall_shape
	wall.position = Vector2(248, 282.5)
	wall.add_child(wall_collision)
	room.add_child(wall)
	cart.force_station(0)
	player.set_physics_process(false)
	player.position = Vector2(45, 200)
	# AnimatableBody2D applies its pending rail reset on the next physics tick.
	await frames(3)
	can.position = Vector2(205, 290)
	can.state = "charging"
	can.state_time = 1
	can.facing = 1
	await frames(12)
	check(can.state == "stunned" and can.stun_cause == "hard impact" and can.plate_mass() == 2, "actual reinforced solid collision produces heavy grounding: %s %s %s" % [can.state, can.position, can.stun_cause])
	print("CORE TUNING: anticipation=0.55s speed=230 bounce=-305 stagger=0.38s impact recovery=0.20s Cart step=80px/0.40s")
	room.free()
	await process_frame
	for failure in failures:
		printerr("SECOND CORE FAIL: ", failure)
	if failures.is_empty():
		print("SECOND CORE PASS: objective-free bait / commitment / continued rebound / impact / fast reuse / actual hard-wall grounding")
	quit(0 if failures.is_empty() else 1)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
