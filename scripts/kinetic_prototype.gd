extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const EnemyScene = preload("res://scripts/enemy.gd")
const PlatformScene = preload("res://scripts/moving_platform.gd")
const SwitchScene = preload("res://scripts/systemic_switch.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")

const WORLD_WIDTH := 1760.0
const START_POSITION := Vector2(48, 173)
const RAM_START := Vector2(108, 172)
const CARRIAGE_START := Vector2(455, 166)
const CART_STATIONS := [455.0, 680.0, 900.0, 1160.0, 1480.0]
const ELECTRIC_RECT := Rect2(1010, 166, 42, 16)
const GOAL_POSITION := Vector2(1605, 151)

var player: CharacterBody2D
var ram: Area2D
var counter_ram: Area2D # Alias retained for older diagnostic scripts.
var rams: Array[Area2D] = []
var carriage: AnimatableBody2D
var safety_switch: Area2D
var final_switch: Area2D
var camera: Camera2D
var effects: Node2D
var sfx: Node
var blocks: Array[Rect2] = []
var spike_rects: Array[Rect2] = []
var mode := "play"
var attempts := 1
var last_event := "The ram is dangerous. Its path is also your route."
var reset_ticket := 0
var checkpoint_station := 0
var circuit_powered := false
var safety_enabled := false
var final_lock_enabled := false
var npc_arrived := false
var shake_time := 0.0

var objective_label: Label
var help_label: Label
var result_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	_build_level()
	_create_actors()
	_create_ui()
	reset_encounter(true)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		attempts += 1
		reset_encounter(false)
	if mode == "play" and player.global_position.y > 230.0:
		player.kill()
	if mode == "play" and not circuit_powered and ELECTRIC_RECT.grow(5.0).has_point(ram.global_position) and ram.state == "coast":
		ram.receive_stun(0.9)
		last_event = "LIVE RAIL: it stops every actor. The cart's brass plate can cut power."
		effects.burst(ram.global_position, Color("a9f4dd"), 12)
		sfx.play("hit")
	if mode == "play" and npc_arrived and player.global_position.distance_to(GOAL_POSITION) < 28.0:
		_complete_level()
	_update_camera_shake(delta)
	_update_ui()
	queue_redraw()

func _build_level() -> void:
	# Beat 1: a broad-topped ledge is too high for a normal jump but comfortably
	# reachable from the ram's stronger rebound.
	_add_block(Rect2(0, 182, 245, 34))
	_add_block(Rect2(245, 130, 53, 86))
	_add_block(Rect2(298, 182, 1462, 34))
	# Beat 4: the cart stages the player below this cut-off balcony.
	_add_block(Rect2(885, 104, 145, 10), true)
	_add_block(Rect2(1060, 132, 90, 10), true)
	_add_block(Rect2(-16, 0, 16, 216))
	_add_block(Rect2(WORLD_WIDTH, 0, 16, 216))
	_add_electric_hazard()

func _create_actors() -> void:
	carriage = PlatformScene.new()
	carriage.name = "PassengerCart"
	carriage.configure_systemic(CARRIAGE_START, PackedFloat32Array(CART_STATIONS))
	carriage.unsafe_station = 3
	carriage.ram_impact.connect(_on_ram_hit_carriage)
	carriage.directly_struck.connect(_on_carriage_struck)
	carriage.station_changed.connect(_on_cart_station_changed)
	carriage.push_rejected.connect(_on_cart_push_rejected)
	carriage.npc_reacted.connect(_on_npc_reacted)
	add_child(carriage)

	ram = EnemyScene.new() as Area2D
	ram.name = "ClockworkRam"
	ram.configure_systemic_ram(RAM_START, 70.0, 1530.0)
	ram.touched_player.connect(_on_ram_touched_player)
	ram.kinetic_struck.connect(_on_ram_struck)
	ram.carriage_hit.connect(func(_ram_speed: float, _cart_speed: float) -> void: sfx.play("hit"))
	ram.charge_locked.connect(_on_ram_charge_locked)
	ram.stunned.connect(func(_duration: float) -> void: last_event = "The live rail stunned the ram; its inert shell is a safe bounce target.")
	add_child(ram)
	rams.append(ram)
	counter_ram = ram

	safety_switch = SwitchScene.new() as Area2D
	safety_switch.configure("strike", Vector2(952, 95), "CUT-OFF")
	safety_switch.activated.connect(_on_switch_activated)
	add_child(safety_switch)

	final_switch = SwitchScene.new() as Area2D
	final_switch.configure("ram", Vector2(1068, 161), "RAM LOCK")
	final_switch.set_armed(false)
	final_switch.activated.connect(_on_switch_activated)
	add_child(final_switch)

	player = PlayerScene.new()
	player.position = START_POSITION
	player.died.connect(_on_player_died)
	player.rebounded.connect(_on_player_rebounded)
	player.jumped.connect(func(_point: Vector2) -> void: sfx.play("jump"))
	add_child(player)

	camera = Camera2D.new()
	camera.position = Vector2(0, -65)
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 216
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	effects = EffectsScene.new()
	add_child(effects)
	sfx = SfxScene.new()
	add_child(sfx)

func reset_encounter(full_reset: bool = false) -> void:
	reset_ticket += 1
	mode = "play"
	if full_reset:
		checkpoint_station = 0
	var restore_station := checkpoint_station
	circuit_powered = restore_station >= 2
	safety_enabled = restore_station >= 3
	final_lock_enabled = false
	npc_arrived = false
	carriage.force_station(restore_station)
	carriage.set_safety_enabled(safety_enabled)
	carriage.set_final_lock_enabled(false)
	safety_switch.reset_switch()
	if safety_enabled:
		safety_switch.active = true
	final_switch.reset_switch()
	final_switch.set_armed(restore_station >= 3)
	ram.reset_kinetic()
	var ram_at := RAM_START
	var player_at := START_POSITION
	if restore_station == 1:
		ram_at = Vector2(555, 172)
		player_at = Vector2(620, 173)
	elif restore_station >= 3:
		ram_at = Vector2(1030, 172)
		player_at = Vector2(1090, 123)
	ram.position = ram_at
	ram.spawn_position = ram_at
	ram.home = ram_at
	player.reset_at(player_at)
	camera.reset_smoothing()
	last_event = "Use the threat. Watch what each position changes next."
	result_label.text = ""
	queue_redraw()

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "dead"
	attempts += 1
	last_event = "Quick rewind: the last stable cart state is restored."
	effects.burst(player.global_position, Color("e9876c"), 12)
	sfx.play("death")
	var ticket := reset_ticket
	await get_tree().create_timer(0.38).timeout
	if mode == "dead" and ticket == reset_ticket:
		reset_encounter(false)

func _on_ram_touched_player(_source: Vector2) -> void:
	if mode == "play":
		player.kill()

func _on_player_rebounded(at: Vector2) -> void:
	effects.burst(at, Color("f6d68c"), 9)
	sfx.play("bounce")
	last_event = "RAM + STRIKE: the threat becomes lift."

func _on_ram_charge_locked(direction: int) -> void:
	last_event = "RAM LOCKED %s — it will not correct its aim." % ("RIGHT" if direction > 0 else "LEFT")
	sfx.play("telegraph")

func _on_ram_struck(player_speed: float, ram_speed: float) -> void:
	last_event = "STRIKE REDIRECT  player %+.0f -> ram %+.0f" % [player_speed, ram_speed]
	effects.burst(ram.global_position, Color("fff1ac"), 8)

func _on_ram_hit_carriage(ram_speed: float, _cart_speed: float) -> void:
	last_event = "RAM + CART: committed force advances one readable stop."
	effects.burst(carriage.global_position, Color("a9f4dd"), 14)
	sfx.play("hit")
	shake_time = 0.16

func _on_carriage_struck(_player_speed: float, _cart_speed: float) -> void:
	last_event = "The cart is too heavy to steer directly—but its roof still returns your bounce."

func _on_cart_station_changed(index: int) -> void:
	effects.burst(carriage.global_position + Vector2(0, 10), Color("d8b47b"), 10)
	shake_time = 0.1
	match index:
		1:
			checkpoint_station = maxi(checkpoint_station, 1)
			last_event = "TRANSFER DOCK: the NPC is safe here. Now position the cart as a tool."
			sfx.play("checkpoint")
		2:
			circuit_powered = true
			last_event = "CART + PLATE: the live rail is off. The cart is now a platform under CUT-OFF."
			sfx.play("switch")
		3:
			checkpoint_station = 3
			final_switch.set_armed(true)
			last_event = "SAFE BAY: the lock behind you is armed. Bring the ram back into it."
			sfx.play("checkpoint")
		4:
			npc_arrived = true
			last_event = "NPC DELIVERED: the station gate is open."
			sfx.play("win")
	queue_redraw()

func _on_cart_push_rejected(index: int) -> void:
	ram.receive_stun(0.45)
	shake_time = 0.2
	if index == 3 and not safety_enabled:
		last_event = "DANGER BAY LIVE: pushing right now endangers the NPC. Reach CUT-OFF first."
	elif index == 4 and not final_lock_enabled:
		last_event = "FINAL TRACK LOCKED: use your position to drive the ram into RAM LOCK."
	else:
		last_event = "The cart is already at the rail stop."
	sfx.play("alarm")
	effects.burst(carriage.global_position, Color("ef9569"), 16)

func _on_npc_reacted(mood: String) -> void:
	if mood == "ready":
		last_event = "The passenger is ready. The ram is now on the useful left side."

func _on_switch_activated(kind: String, at: Vector2) -> void:
	effects.burst(at, Color("a9f4dd"), 16)
	sfx.play("switch")
	shake_time = 0.12
	if kind == "strike":
		safety_enabled = true
		carriage.set_safety_enabled(true)
		last_event = "CUT-OFF ACTIVE: the danger bay is safe. Future cart movement is now useful."
	else:
		final_lock_enabled = true
		carriage.set_final_lock_enabled(true)
		last_event = "RAM LOCK ACTIVE: move right of the cart and drive it home."

func _complete_level() -> void:
	mode = "complete"
	player.active = false
	player.velocity = Vector2.ZERO
	ram.set_charge_enabled(false)
	result_label.text = "SYSTEM LINK COMPLETE\nTHE PASSENGER IS HOME\nR  REPLAY FROM LAST DOCK"
	effects.burst(GOAL_POSITION, Color("fff1ac"), 28)
	sfx.play("win")

func _add_block(rect: Rect2, one_way: bool = false) -> void:
	blocks.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	if one_way:
		collision.one_way_collision_margin = 3.0
	body.add_child(collision)
	add_child(body)

func _add_spikes(rect: Rect2) -> void:
	spike_rects.append(rect)
	var area := Area2D.new()
	area.position = rect.get_center() + Vector2(0, -4)
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size + Vector2(0, 8)
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and mode == "play":
			player.kill()
	)
	add_child(area)

func _add_electric_hazard() -> void:
	var area := Area2D.new()
	area.position = ELECTRIC_RECT.get_center()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = ELECTRIC_RECT.size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(func(body: Node2D) -> void:
		if not circuit_powered and body.is_in_group("player") and mode == "play":
			player.kill()
	)
	add_child(area)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	objective_label = _label(Vector2(7, 5), Vector2(370, 34), 8, Color("f5dfa8"))
	canvas.add_child(objective_label)
	help_label = _label(Vector2(7, 198), Vector2(370, 14), 8, Color("b6c4bf"))
	help_label.text = "A/D MOVE   SPACE JUMP   J/X DOWN STRIKE   R REWIND"
	canvas.add_child(help_label)
	result_label = _label(Vector2(55, 62), Vector2(274, 76), 13, Color("fff1ac"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	canvas.add_child(result_label)

func _label(at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("162230"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _update_ui() -> void:
	if objective_label == null:
		return
	var step := "REACH THE CART"
	if carriage.station_index == 1:
		step = "STAGE CART ON THE BRASS PLATE"
	elif carriage.station_index == 2 and not safety_enabled:
		step = "USE RAM LIFT -> STRIKE CUT-OFF"
	elif carriage.station_index == 2:
		step = "DANGER BAY SAFE -> ADVANCE CART"
	elif carriage.station_index == 3 and not final_lock_enabled:
		step = "BAIT RAM INTO THE RED RAM LOCK"
	elif carriage.station_index == 3:
		step = "GET RAM LEFT -> DRIVE CART HOME"
	elif npc_arrived:
		step = "MEET THE NPC AT THE STATION"
	objective_label.text = "%s\n%s" % [step, last_event]

func _update_camera_shake(delta: float) -> void:
	shake_time = maxf(0.0, shake_time - delta)
	if shake_time > 0.0:
		camera.offset = Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
	else:
		camera.offset = Vector2.ZERO

func _draw() -> void:
	draw_rect(Rect2(0, 0, WORLD_WIDTH, 216), Color("0d1822"))
	for section in [Rect2(0, 42, 370, 174), Rect2(370, 42, 460, 174), Rect2(830, 42, 420, 174), Rect2(1250, 42, 510, 174)]:
		draw_rect(section, Color("172936") if int(section.position.x / 400.0) % 2 == 0 else Color("142431"))
	for x in range(40, int(WORLD_WIDTH), 180):
		draw_line(Vector2(x, 50), Vector2(x, 182), Color("263d48"), 4.0)
		draw_circle(Vector2(x, 72), 18.0, Color("203541"))
	for rect in blocks:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("c3935f"))
	for rect in spike_rects:
		for x in range(int(rect.position.x), int(rect.end.x), 8):
			draw_colored_polygon(PackedVector2Array([Vector2(x, rect.position.y + 8), Vector2(x + 4, rect.position.y), Vector2(x + 8, rect.position.y + 8)]), Color("ef9569"))
	draw_line(Vector2(CART_STATIONS[0] - 45, 180), Vector2(CART_STATIONS[-1] + 45, 180), Color("657b83"), 2.0)
	for i in CART_STATIONS.size():
		var color := Color("a9f4dd") if carriage != null and carriage.station_index >= i else Color("657b83")
		draw_rect(Rect2(CART_STATIONS[i] - 3, 174, 6, 8), color)
		draw_string(ThemeDB.fallback_font, Vector2(CART_STATIONS[i] - 18, 158), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 36, 8, color)
	var electric_color := Color("304551") if circuit_powered else Color("75d6d2")
	draw_rect(ELECTRIC_RECT, Color("20303b"))
	for x in range(int(ELECTRIC_RECT.position.x), int(ELECTRIC_RECT.end.x), 7):
		draw_line(Vector2(x, ELECTRIC_RECT.position.y), Vector2(x + 4, ELECTRIC_RECT.end.y), electric_color, 2.0)
	var bay_color := Color("587b72") if safety_enabled else Color("b84f4f")
	draw_rect(Rect2(1110, 116, 100, 8), bay_color)
	draw_line(Vector2(1120, 124), Vector2(1140, 157), bay_color, 4.0)
	draw_line(Vector2(1200, 124), Vector2(1180, 157), bay_color, 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(1124, 108), "DANGER BAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, bay_color)
	var gate_color := Color("a9f4dd") if final_lock_enabled else Color("ef9569")
	draw_rect(Rect2(1440, 112, 6, 70), gate_color)
	draw_string(ThemeDB.fallback_font, Vector2(1028, 76), "RAM-ONLY LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, gate_color)
	draw_rect(Rect2(GOAL_POSITION.x - 13, GOAL_POSITION.y - 36, 26, 38), Color("a47b55"))
	draw_rect(Rect2(GOAL_POSITION.x - 9, GOAL_POSITION.y - 31, 18, 25), Color("a9f4dd") if npc_arrived else Color("304551"))
	draw_string(ThemeDB.fallback_font, Vector2(1540, 101), "PASSENGER STATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f5dfa8"))
	draw_string(ThemeDB.fallback_font, Vector2(44, 76), "I  THREAT -> LIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_string(ThemeDB.fallback_font, Vector2(420, 76), "II  RAM -> CART", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_string(ThemeDB.fallback_font, Vector2(840, 76), "III  POSITION IS STATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))

func _setup_inputs() -> void:
	_add_action("move_left", 0.2)
	_add_action("move_right", 0.2)
	_add_action("aim_up", 0.2)
	_add_action("aim_down", 0.2)
	_add_action("jump")
	_add_action("attack")
	_add_action("dash")
	_add_action("restart")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("jump", KEY_SPACE)
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_X)
	_add_key("restart", KEY_R)
	_add_pad_button("move_left", 13)
	_add_pad_button("move_right", 14)
	_add_pad_axis("move_left", 0, -1.0)
	_add_pad_axis("move_right", 0, 1.0)
	_add_pad_button("jump", 0)
	_add_pad_button("attack", 2)
	_add_pad_button("restart", 3)

func _add_action(action: String, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)

func _add_key(action: String, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)

func _add_pad_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_pad_axis(action: String, axis: int, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
