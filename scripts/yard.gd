extends "res://scripts/action_foundry.gd"

const YardCan = preload("res://scripts/yard_can.gd")
const YardCart = preload("res://scripts/yard_cart.gd")
const YardPlayer = preload("res://scripts/yard_player.gd")
const RAIL_STOPS := [160.0, 260.0, 360.0]
const SPAWN := Vector2(64, 291)
const EXIT := Vector2(548, 237)

@export var sandbox := true
var hit_count := 0
var signature_count := 0
var discoveries: Array[Dictionary] = []
var respawn_at := SPAWN
var control_time := 0.0
var starting_snapshot: Dictionary = {}

func _ready() -> void:
	get_window().title = "Foundry / Future States — Malfunction"
	get_window().content_scale_size = Vector2i(576, 324)
	font = PixelUI.make_font()
	var input_setup := Legacy.new()
	input_setup._setup_inputs()
	input_setup.free()
	room_root = Node2D.new()
	room_root.name = "Factory"
	add_child(room_root)
	_build_factory()
	effects = Effects.new()
	effects.z_index = 8
	add_child(effects)
	sound = Sound.new()
	add_child(sound)
	sound.samples["commit"] = sound._make_sound(110, 0.10, 0.25, true)
	sound.samples["ground"] = sound._make_sound(75, 0.25, 0.24, true)
	player = YardPlayer.new()
	player.position = SPAWN
	player.air_acceleration = 1700
	player.jumped.connect(func(_at: Vector2) -> void: sound.play("jump"))
	player.rebounded.connect(func(at: Vector2) -> void:
		stats.rebounds += 1
		if can.state == "charging" and absf(at.x - can.position.x) < 28:
			signature_count += 1
			_record("charging rebound")
		_feedback(at, "bounce", Color("fff1ac"), 10, 2)
	)
	player.health_changed.connect(func(value: int) -> void:
		if value < 3:
			hit_count += 1
			_feedback(player.position, "hit", Color("ef9569"), 8, 2)
	)
	player.died.connect(_on_death)
	add_child(player)
	player.strike_shape.size = Vector2(22, 14)
	can = YardCan.new()
	can.name = "MaintenanceCan"
	can.configure_systemic_ram(Vector2(110, 290), 24, 550)
	can.charge_locked.connect(func(_side: int) -> void:
		sound.play("telegraph")
		_record("lock")
	)
	can.committed.connect(func() -> void:
		stats.charges += 1
		sound.play("commit")
	)
	can.touched_player.connect(func(at: Vector2) -> void: player.take_damage(at))
	can.environmental_stun.connect(func(_cause: String) -> void:
		stats.environmental_stuns += 1
		_record("grounded")
	)
	can.impact_feedback.connect(func(at: Vector2, hard: bool) -> void:
		_feedback(at, "ground" if hard else "hit", Color("a9f4dd") if hard else Color("ef9569"), 14, 3)
	)
	add_child(can)
	cart = YardCart.new()
	cart.name = "RailPlatform"
	cart.configure_systemic(Vector2(RAIL_STOPS[0], 284), PackedFloat32Array(RAIL_STOPS))
	cart.ram_impact.connect(_cart_impact)
	cart.station_changed.connect(func(_index: int) -> void: _record("Cart settled"))
	add_child(cart)
	crusher.cycle_warning.connect(func() -> void: sound.play("alarm"))
	mechanisms.wall.impacted.connect(func(at: Vector2) -> void:
		_feedback(at, "hit", Color("ef9569"), 22, 3)
		_record("fracture")
	)
	camera = Camera2D.new()
	camera.position = Vector2(288, 232)
	add_child(camera)
	camera.make_current()
	_create_ui()
	starting_snapshot = snapshot()

func _build_factory() -> void:
	_block(Rect2(-20, 68, 20, 340))
	_block(Rect2(576, 68, 20, 340))
	# Broad rail deck with a shallow maintenance well, not a separated room.
	_block(Rect2(0, 300, 200, 80))
	_block(Rect2(240, 300, 45, 80))
	_block(Rect2(335, 300, 241, 80))
	_block(Rect2(200, 336, 135, 44))
	_block(Rect2(200, 316, 40, 7), true)
	_block(Rect2(294, 316, 41, 7), true)
	# The same visible high loop can be reached through different supports.
	_block(Rect2(112, 174, 98, 8), true)
	_block(Rect2(382, 180, 50, 8), true)
	_block(Rect2(486, 180, 44, 8), true)
	_block(Rect2(483, 276, 39, 8), true)
	_block(Rect2(524, 246, 52, 8), true)
	var bridge := _item("catwalk", "bridge", Rect2(230, 218, 145, 8), "")
	var plate := _item("plate", "plate", Rect2(237, 294, 46, 12), "")
	plate.linked_gate = bridge
	plate.release_grace = 0.9
	_item("wall", "breakable", Rect2(444, 144, 16, 156), "")
	crusher = Crusher.new()
	crusher.name = "Press"
	crusher.foundry_mode = true
	crusher.configure(Vector2(260, 185), 1.55)
	crusher.drop_distance = 86
	crusher.cycle_length = 2.4
	room_root.add_child(crusher)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		if Input.is_key_pressed(KEY_SHIFT) or mode == "complete":
			_fresh()
		else:
			stats.resets += 1
			restore(starting_snapshot)
	if Input.is_action_just_pressed("pause") and mode in ["play", "paused"]:
		mode = "paused" if mode == "play" else "play"
		_freeze(mode == "paused")
		overlay.text = "PAUSED\n\nESC RESUME  •  R REWIND YARD"
		overlay.visible = mode == "paused"
	if Input.is_action_just_pressed("hint"):
		control_time = 4.0
	if mode != "play":
		return
	elapsed += delta
	clock += delta
	control_time = maxf(0, control_time - delta)
	shake = maxf(0, shake - delta)
	camera.offset = Vector2(sin(clock * 91), cos(clock * 77)) * shake * 9
	if pause_frames > 0:
		pause_frames -= 1
		_freeze(pause_frames > 0)
	if absf(player.velocity.x) < 8 and absf(player.velocity.y) < 8:
		idle_time += delta
	if player.position.y > 395:
		player.kill()
	# One physical destination, with no Cart-index, plate, wall or other flags.
	if not sandbox and player.is_on_floor() and player.position.distance_to(EXIT) < 18:
		_complete()
	hud.text = "●".repeat(player.health)
	hint.visible = control_time > 0 and not sandbox
	queue_redraw()

func _cart_impact(momentum: float, speed: float) -> void:
	super._cart_impact(momentum, speed)
	if not is_zero_approx(speed):
		_record("Cart impact")

func _record(event: String) -> void:
	if can == null or cart == null:
		return
	discoveries.append({"event": event, "seconds": snappedf(elapsed, 0.01), "player": player.position, "can": can.position, "can_state": can.state, "cart": cart.station_index, "target": cart.target_station, "catwalk": mechanisms.catwalk.active, "grounded": can.plate_mass() > 0, "wall_broken": mechanisms.wall.broken})

func snapshot() -> Dictionary:
	var objects: Dictionary = {}
	for id in mechanisms:
		objects[id] = mechanisms[id].snapshot()
	return {"player": player.position, "can_data": can.snapshot(), "cart": cart.snapshot(), "objects": objects, "press_clock": crusher.clock, "press_position": crusher.position, "press_warning": crusher.was_warning, "press_shield": crusher.shielded, "last_direction": last_cart_direction}

func restore(data: Dictionary) -> void:
	reset_serial += 1
	mode = "play"
	pause_frames = 0
	shake = 0
	player.reset_at(data.player)
	can.restore(data.can_data)
	cart.restore(data.cart)
	for id in mechanisms:
		mechanisms[id].restore(data.objects[id])
	crusher.clock = data.press_clock
	crusher.position = data.press_position
	crusher.was_warning = data.press_warning
	crusher.shielded = data.press_shield
	last_cart_direction = data.last_direction
	effects.particles.clear()
	_freeze(false)
	overlay.hide()
	_record("rewind")

func _fresh() -> void:
	elapsed = 0
	idle_time = 0
	for key in stats:
		stats[key] = 0
	hit_count = 0
	signature_count = 0
	discoveries.clear()
	respawn_at = SPAWN
	restore(starting_snapshot)

func _on_death() -> void:
	if mode != "play":
		return
	stats.deaths += 1
	mode = "dead"
	_freeze(true)
	sound.play("death")
	var serial := reset_serial
	await get_tree().create_timer(0.3).timeout
	if mode == "dead" and serial == reset_serial:
		# Death keeps the discovered world. Only explicit R rewinds objects.
		player.reset_at(respawn_at)
		player.invulnerable_time = 1.0
		pause_frames = 0
		mode = "play"
		_freeze(false)
		_record("respawn preserving world")

func _complete() -> void:
	_record("escape")
	mode = "complete"
	_freeze(true)
	pause_frames = 0
	overlay.text = "OUT OF THE FOUNDRY\n\n%d CHARGES  •  %d REBOUNDS\n\nR PLAY AGAIN" % [stats.charges, stats.rebounds]
	overlay.show()
	sound.play("win")

func metrics() -> Dictionary:
	var result := stats.duplicate()
	result.merge({"completion_seconds": snappedf(elapsed, 0.01), "idle_seconds": snappedf(idle_time, 0.01), "charging_rebounds": signature_count, "hits": hit_count, "cart_final": cart.station_index, "wall_broken": mechanisms.wall.broken, "catwalk": mechanisms.catwalk.active, "discoveries": discoveries.duplicate(true)})
	return result

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(9, 8)
	PixelUI.style_label(hud, font, 10, Color("edc27a"))
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(9, 25)
	hint.text = "A/D MOVE  SPACE JUMP  J/X STOMP\nR REWIND  SHIFT+R FRESH  ESC PAUSE"
	PixelUI.style_label(hint, font, 9, Color("9ac6c7"))
	hint.hide()
	layer.add_child(hint)
	overlay = Label.new()
	overlay.position = Vector2(148, 95)
	overlay.size = Vector2(280, 110)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PixelUI.style_label(overlay, font, 12, Color("fff1ac"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("162230")
	panel.content_margin_top = 16
	overlay.add_theme_stylebox_override("normal", panel)
	overlay.hide()
	layer.add_child(overlay)

func _draw() -> void:
	draw_rect(Rect2(0, 68, 576, 326), Color("101d28"))
	for x in range(0, 576, 96):
		draw_rect(Rect2(x + 12, 74, 5, 300), Color("20333e"))
		draw_circle(Vector2(x + 53, 124), 22, Color("182b35"))
		draw_arc(Vector2(x + 53, 124), 22, 0, TAU, 16, Color("263d48"), 2)
	draw_line(Vector2(0, 96), Vector2(576, 96), Color("304551"), 4)
	for area in geometry:
		draw_rect(area, Color("283b47"))
		draw_rect(Rect2(area.position, Vector2(area.size.x, 3)), Color("c3935f"))
		for x in range(int(area.position.x + 8), int(area.end.x), 20):
			draw_rect(Rect2(x, area.position.y + 1, 2, 2), Color("edc27a"))
	# Rails and etched roof positions show configuration without room captions.
	draw_line(Vector2(115, 299), Vector2(410, 299), Color("657b83"), 2)
	for stop in RAIL_STOPS:
		draw_rect(Rect2(stop - 3, 302, 6, 5), Color("edc27a"))
		if cart != null and absf(cart.position.x - stop) > 3:
			for x in range(int(stop - 28), int(stop + 28), 10):
				draw_line(Vector2(x, 268), Vector2(x + 6, 268), Color("397c82"), 1)
	# Open pit is a readable maintenance passage and a recovery loop.
	draw_line(Vector2(205, 352), Vector2(329, 352), Color("397c82"), 3)
	for x in range(209, 326, 24):
		draw_line(Vector2(x, 350), Vector2(x + 10, 350), Color("a9f4dd"), 1)
	if crusher != null:
		var warning: bool = crusher.was_warning or fmod(crusher.clock, 2.4) >= 0.75 and fmod(crusher.clock, 2.4) < 1.5
		var color := Color("a9f4dd") if crusher.shielded else Color("ffad66") if warning else Color("edc27a")
		draw_line(Vector2(260, 97), crusher.position - Vector2(0, 22), Color("657b83"), 5)
		draw_line(Vector2(260, 163), Vector2(260, 300), Color(color, 0.10), 29)
		draw_circle(Vector2(293, 280), 4, color)
		for x in range(243, 280, 8):
			draw_line(Vector2(x, 298), Vector2(x + 4, 302), Color("ef9569"), 2)
	# Visible committed lane. Red dash marks make a chosen danger tangible.
	if can != null and can.state in ["windup", "charging"]:
		var tip := clampf(can.position.x + can.facing * 230, 24, 550)
		for x in range(int(minf(can.position.x, tip)), int(maxf(can.position.x, tip)), 13):
			draw_line(Vector2(x, 303), Vector2(x + 6, 303), Color("f46e5a"), 1)
	draw_rect(Rect2(EXIT - Vector2(15, 29), Vector2(30, 38)), Color("416d83"))
	draw_rect(Rect2(EXIT - Vector2(10, 24), Vector2(20, 30)), Color("a9f4dd"))
	if not sandbox:
		draw_string(font, EXIT + Vector2(-24, -36), "EXIT →", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9f4dd"))
