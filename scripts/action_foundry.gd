extends Node2D

const Player = preload("res://scripts/action_player.gd")
const Can = preload("res://scripts/action_can.gd")
const Cart = preload("res://scripts/action_cart.gd")
const Mechanism = preload("res://scripts/action_mechanism.gd")
const Crusher = preload("res://scripts/action_crusher.gd")
const Effects = preload("res://scripts/effects.gd")
const Sound = preload("res://scripts/sfx.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")
const Legacy = preload("res://scripts/foundry.gd")
const TITLES := ["SPARKS", "CROSSROADS", "THE PRESS", "FREEFORM"]
const STOPS := [105.0, 185.0, 265.0]

@export var greybox := false
var room_index := 0
var room_root: Node2D
var player: CharacterBody2D
var can: Area2D
var cart: AnimatableBody2D
var crusher: AnimatableBody2D
var mechanisms: Dictionary = {}
var geometry: Array[Rect2] = []
var camera: Camera2D
var effects: Node2D
var sound: Node
var font: Font
var hud: Label
var hint: Label
var overlay: Label
var mode := "play"
var elapsed := 0.0
var idle_time := 0.0
var pause_frames := 0
var shake := 0.0
var clock := 0.0
var hint_time := 4.0
var entry: Dictionary = {}
var room_results: Array[Dictionary] = []
var stats := {"charges": 0, "cart_impacts": 0, "rebounds": 0, "environmental_stuns": 0, "reversals": 0, "resets": 0, "deaths": 0}
var exit_position := Vector2(362, 291)
var last_cart_direction := 0
var transition_time := 0.0
var reset_serial := 0

func _ready() -> void:
	get_window().title = "Foundry / Future States — Bait. Bounce. Break."
	font = PixelUI.make_font()
	var input_setup := Legacy.new()
	input_setup._setup_inputs()
	input_setup.free()
	effects = Effects.new()
	effects.z_index = 8
	add_child(effects)
	sound = Sound.new()
	add_child(sound)
	sound.samples["commit"] = sound._make_sound(110, 0.10, 0.25, true)
	sound.samples["ground"] = sound._make_sound(75, 0.25, 0.24, true)
	player = Player.new()
	player.position = Vector2(45, 291)
	player.air_acceleration = 1700.0
	player.rebounded.connect(func(at: Vector2) -> void:
		stats.rebounds += 1
		_feedback(at, "bounce", Color("fff1ac"), 8, 2)
	)
	player.jumped.connect(func(_at: Vector2) -> void: sound.play("jump"))
	player.died.connect(_on_death)
	add_child(player)
	player.strike_shape.size = Vector2(22, 14)
	can = Can.new()
	can.configure_systemic_ram(Vector2(115, 290), 20, 364)
	can.charge_locked.connect(func(_direction: int) -> void: sound.play("telegraph"))
	can.committed.connect(func() -> void:
		stats.charges += 1
		sound.play("commit")
	)
	can.touched_player.connect(func(at: Vector2) -> void: player.take_damage(at))
	can.environmental_stun.connect(func(_cause: String) -> void: stats.environmental_stuns += 1)
	can.impact_feedback.connect(func(at: Vector2, hard: bool) -> void:
		_feedback(at, "ground" if hard else "hit", Color("a9f4dd") if hard else Color("ef9569"), 14, 3)
	)
	add_child(can)
	cart = Cart.new()
	cart.configure_systemic(Vector2(STOPS[0], 284), PackedFloat32Array(STOPS))
	cart.ram_impact.connect(_cart_impact)
	add_child(cart)
	camera = Camera2D.new()
	camera.position = Vector2(192, 224)
	add_child(camera)
	camera.make_current()
	_create_ui()
	_build_room()
	_save_entry()

func _build_room() -> void:
	if room_root != null:
		remove_child(room_root)
		room_root.queue_free()
	room_root = Node2D.new()
	room_root.name = "Workshop"
	add_child(room_root)
	geometry.clear()
	mechanisms.clear()
	crusher = null
	_block(Rect2(-20, 105, 20, 255))
	_block(Rect2(384, 105, 20, 255))
	cart.visible = greybox or room_index > 0
	cart.collision_layer = 17 if cart.visible else 0
	cart.remove_from_group("foundry_heavy")
	cart.remove_from_group("force_receivers")
	if cart.visible:
		cart.add_to_group("foundry_heavy")
		cart.add_to_group("force_receivers")
	cart.configure_systemic(Vector2(STOPS[0], 284), PackedFloat32Array(STOPS))
	cart.force_station(2 if room_index == 3 and not greybox else 0)
	last_cart_direction = 0
	can.configure_systemic_ram(Vector2(115 if room_index == 0 else 55, 290), 20, 330 if room_index == 3 else (278 if room_index > 0 and not greybox else 364))
	can.reset_kinetic()
	can.ground_body.collision_layer = 0
	can.squash = 0.0
	player.reset_at(Vector2(45, 291))
	player.invulnerable_time = 0.35
	if greybox:
		_block(Rect2(0, 300, 384, 50))
		exit_position = Vector2.INF
	elif room_index == 0:
		_block(Rect2(0, 300, 384, 50))
		_item("fracture", "breakable", Rect2(278, 186, 16, 114), "")
		# A perch is optional play space, not a switch task.
		_block(Rect2(170, 236, 64, 7), true)
		exit_position = Vector2(361, 291)
	else:
		# A shallow recovery trench costs position, never an unexplained death.
		_block(Rect2(0, 300, 286, 50))
		_block(Rect2(286, 330, 98, 30))
		_block(Rect2(344, 246, 40, 8), true)
		_block(Rect2(300, 282, 44, 7), true)
		var bridge := _item("bridge", "bridge", Rect2(284, 208 if room_index == 3 else 246, 90 if room_index == 3 else 60, 8), "")
		var plate := _item("plate", "plate", Rect2(163, 294, 44, 12), "")
		plate.linked_gate = bridge
		plate.release_grace = 0.6
		# A supplies a high launch, B persistent support, C a forward launch.
		_block(Rect2(72, 190, 72, 7), true)
		_block(Rect2(194, 192, 63, 7), true)
		if room_index == 1:
			_block(Rect2(307, 190, 77, 7), true)
			_block(Rect2(337, 218, 47, 7), true)
			exit_position = Vector2(363, 181)
		else:
			crusher = Crusher.new()
			crusher.foundry_mode = true
			crusher.configure(Vector2(185, 185), 1.55)
			crusher.drop_distance = 86
			crusher.cycle_length = 2.4
			crusher.cycle_warning.connect(func() -> void: sound.play("alarm"))
			room_root.add_child(crusher)
			exit_position = Vector2(363, 237)
		if room_index == 3:
			# Visible weak material closes the rail lane, with an ordinary-height
			# upper opening. Break it OR use the already learned Cart roof.
			_item("fracture", "breakable", Rect2(304, 190, 16, 110), "")
			exit_position = Vector2(358, 199)
	queue_redraw()

func _block(rect: Rect2, one_way: bool = false) -> void:
	geometry.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 3
	body.add_child(collision)
	room_root.add_child(body)

func _item(id: String, kind: String, rect: Rect2, title: String) -> Node2D:
	var item := Mechanism.new()
	item.configure(kind, rect, title)
	item.changed.connect(func(_item: Node2D) -> void: sound.play("switch"))
	mechanisms[id] = item
	room_root.add_child(item)
	return item

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		if Input.is_key_pressed(KEY_SHIFT) or mode == "complete":
			_fresh()
		else:
			stats.resets += 1
			_restore_entry()
	if Input.is_action_just_pressed("pause") and mode in ["play", "paused"]:
		mode = "paused" if mode == "play" else "play"
		_freeze(mode == "paused")
		overlay.text = "PAUSED\n\nESC RESUME   R REWIND BAY"
		overlay.visible = mode == "paused"
	if Input.is_action_just_pressed("hint"):
		hint_time = 4.0
	if mode == "transition":
		elapsed += delta
		transition_time -= delta
		if transition_time <= 0:
			room_index += 1
			_build_room()
			_save_entry()
			mode = "play"
			_freeze(false)
			hint_time = 0
			overlay.hide()
	if mode != "play":
		return
	elapsed += delta
	clock += delta
	hint_time = maxf(0, hint_time - delta)
	shake = maxf(0, shake - delta)
	camera.offset = Vector2(sin(clock * 91), cos(clock * 77)) * shake * 9
	if pause_frames > 0:
		pause_frames -= 1
		_freeze(pause_frames > 0)
	if absf(player.velocity.x) < 8 and absf(player.velocity.y) < 8 and not Input.is_action_pressed("attack"):
		idle_time += delta
	if player.position.y > 365:
		player.kill()
	var at_exit: bool = absf(player.position.x - exit_position.x) < 19 and player.position.y > 224 if room_index == 0 else player.position.distance_to(exit_position) < 19 and player.is_on_floor() and absf(player.position.y - exit_position.y) < 4
	if not greybox and at_exit:
		_finish_room()
	hud.text = "%02d / 04  %s%s" % [room_index + 1, "IMPACT LAB" if greybox else TITLES[room_index], "    " + "●".repeat(player.health)]
	hint.visible = hint_time > 0
	queue_redraw()

func _cart_impact(momentum: float, speed: float) -> void:
	if not is_zero_approx(speed):
		stats.cart_impacts += 1
		var direction := int(signf(momentum))
		# Leftward movement restores a consumed position; count it even when it
		# is the room's first move, as in the final room's starting C state.
		if direction < 0 or (last_cart_direction != 0 and direction != last_cart_direction):
			stats.reversals += 1
		last_cart_direction = direction

func _feedback(at: Vector2, audio: String, color: Color, count: int, stop_frames: int) -> void:
	sound.play(audio)
	effects.burst(at, color, count)
	shake = 0.16 if audio != "bounce" else 0.07
	pause_frames = maxi(pause_frames, stop_frames)

func _freeze(value: bool) -> void:
	player.active = not value
	player.queue_redraw()
	can.suspended = value
	cart.suspended = value
	for item in mechanisms.values():
		item.suspended = value
	if crusher != null:
		crusher.suspended = value

func _save_entry() -> void:
	var objects: Dictionary = {}
	for id in mechanisms:
		objects[id] = mechanisms[id].snapshot()
	entry = {"player": player.position, "can": can.position, "state": can.state, "time": can.state_time, "cooldown": can.cooldown, "contact": can.contact_cooldown, "facing": can.facing, "velocity": can.velocity_x, "squash": can.squash, "cause": can.stun_cause, "cart": cart.snapshot(), "last_direction": last_cart_direction, "objects": objects, "press_clock": crusher.clock if crusher != null else 0.0, "press_position": crusher.position if crusher != null else Vector2.ZERO, "press_warning": crusher.was_warning if crusher != null else false, "press_shield": crusher.shielded if crusher != null else false}

func _restore_entry() -> void:
	reset_serial += 1
	mode = "play"
	pause_frames = 0
	shake = 0
	player.reset_at(entry.player)
	can.position = entry.can
	can.state = entry.state
	can.state_time = entry.time
	can.cooldown = entry.cooldown
	can.facing = entry.facing
	can.velocity_x = entry.velocity
	can.contact_cooldown = entry.contact
	can.squash = entry.squash
	can.stun_cause = entry.cause
	can.ground_body.collision_layer = 1 if can.state == "stunned" else 0
	cart.restore(entry.cart)
	last_cart_direction = entry.last_direction
	for id in mechanisms:
		mechanisms[id].restore(entry.objects[id])
	if crusher != null:
		crusher.clock = entry.press_clock
		crusher.position = entry.press_position
		crusher.was_warning = entry.press_warning
		crusher.shielded = entry.press_shield
	effects.particles.clear()
	_freeze(false)
	overlay.hide()

func _fresh() -> void:
	room_index = 0
	elapsed = 0
	idle_time = 0
	room_results.clear()
	for key in stats:
		stats[key] = 0
	_build_room()
	_save_entry()
	_restore_entry()

func _on_death() -> void:
	if mode != "play":
		return
	stats.deaths += 1
	mode = "dead"
	_freeze(true)
	sound.play("death")
	var serial := reset_serial
	await get_tree().create_timer(0.3).timeout
	if mode == "dead" and reset_serial == serial:
		_restore_entry()

func _finish_room() -> void:
	room_results.append({"room": TITLES[room_index], "time": elapsed, "stats": stats.duplicate(), "cart": cart.station_index, "broken": mechanisms.fracture.broken if mechanisms.has("fracture") else false, "bridge": mechanisms.bridge.active if mechanisms.has("bridge") else false})
	_freeze(true)
	pause_frames = 0
	if room_index < 3:
		mode = "transition"
		transition_time = 0.25
		overlay.text = "NEXT BAY  →"
	else:
		mode = "complete"
		overlay.text = "FUTURE STATES\n\nYOU MADE IT.\n\n%d CHARGES   %d REBOUNDS\nR  PLAY AGAIN" % [stats.charges, stats.rebounds]
		sound.play("win")
	overlay.show()

func metrics() -> Dictionary:
	var result := stats.duplicate()
	result["completion_seconds"] = snappedf(elapsed, 0.01)
	result["idle_seconds"] = snappedf(idle_time, 0.01)
	result["rooms"] = room_results.duplicate(true)
	return result

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(8, 5)
	PixelUI.style_label(hud, font, 8, Color("d7e5d5"))
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(8, 19)
	hint.text = "A/D MOVE   SPACE JUMP   J/X STOMP\nR REWIND BAY   SHIFT+R FRESH   ESC PAUSE"
	PixelUI.style_label(hint, font, 7, Color("9ac6c7"))
	layer.add_child(hint)
	overlay = Label.new()
	overlay.position = Vector2(60, 70)
	overlay.size = Vector2(264, 85)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PixelUI.style_label(overlay, font, 10, Color("fff1ac"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("162230")
	panel.content_margin_top = 12
	overlay.add_theme_stylebox_override("normal", panel)
	overlay.hide()
	layer.add_child(overlay)

func _draw() -> void:
	draw_rect(Rect2(0, 105, 384, 255), Color("101d28"))
	for x in range(0, 384, 96):
		draw_rect(Rect2(x + 12, 110, 5, 225), Color("20333e"))
		draw_circle(Vector2(x + 53, 166), 20, Color("182b35"))
		draw_arc(Vector2(x + 53, 166), 20, 0, TAU, 16, Color("263d48"), 2)
	draw_line(Vector2(0, 149), Vector2(384, 149), Color("304551"), 3)
	for rect in geometry:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("c3935f"))
		for x in range(int(rect.position.x + 8), int(rect.end.x), 20):
			draw_rect(Rect2(x, rect.position.y + 1, 2, 2), Color("edc27a"))
	if cart != null and cart.visible:
		draw_line(Vector2(70, 298), Vector2(296, 298), Color("657b83"), 2)
		for i in 3:
			var at := Vector2(STOPS[i], 310)
			draw_rect(Rect2(at - Vector2(3, 10), Vector2(6, 4)), Color("a9f4dd") if cart.station_index == i else Color("edc27a"))
			var ink := Color("d7b06f")
			if i == 0:
				draw_line(at + Vector2(0, 8), at + Vector2(0, 1), ink, 1)
				draw_line(at + Vector2(-3, 4), at + Vector2(0, 1), ink, 1)
				draw_line(at + Vector2(3, 4), at + Vector2(0, 1), ink, 1)
			elif i == 1:
				draw_rect(Rect2(at + Vector2(-3, 2), Vector2(6, 5)), ink)
			else:
				draw_line(at + Vector2(-4, 4), at + Vector2(4, 4), ink, 1)
				draw_line(at + Vector2(1, 1), at + Vector2(4, 4), ink, 1)
				draw_line(at + Vector2(1, 7), at + Vector2(4, 4), ink, 1)
			# Outlined roof silhouettes show all three positions in one screen.
			if cart.station_index != i:
				draw_line(Vector2(STOPS[i] - 28, 268), Vector2(STOPS[i] + 28, 268), Color("397c82"), 1)
			draw_colored_polygon(PackedVector2Array([Vector2(STOPS[i] + 6, 274), Vector2(STOPS[i] + 2, 278), Vector2(STOPS[i] + 2, 270)]), Color("397c82"))
	if crusher != null:
		var color := Color("a9f4dd") if crusher.shielded else Color("ef9569")
		draw_line(Vector2(185, 150), Vector2(185, 300), Color(color, 0.10), 25)
		draw_line(Vector2(185, 150), crusher.position - Vector2(0, 22), Color("657b83"), 4)
		draw_circle(Vector2(209, 277), 3, color)
	if not greybox:
		draw_rect(Rect2(exit_position - Vector2(12, 26), Vector2(24, 35)), Color("416d83"))
		draw_rect(Rect2(exit_position - Vector2(8, 22), Vector2(16, 28)), Color("a9f4dd"))
		draw_string(font, exit_position + Vector2(-15, -31), "EXIT" if room_index == 3 else "→", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a9f4dd"))
