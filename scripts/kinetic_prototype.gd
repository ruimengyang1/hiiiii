extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const EnemyScene = preload("res://scripts/enemy.gd")
const PlatformScene = preload("res://scripts/moving_platform.gd")
const SwitchScene = preload("res://scripts/systemic_switch.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")

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
var briefing_active := false
var announcement_time := 0.0
var ui_font: Font
var contact_lesson_seen := false
var contact_hits := 0
var unsafe_pushes := 0
var rewinds_used := 0
var deaths_count := 0
var hint_time := 0.0

var objective_label: Label
var help_label: Label
var hint_label: Label
var hint_back: ColorRect
var announcement_label: Label
var result_label: Label
var briefing_panel: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_font = PixelUI.make_font()
	_setup_inputs()
	_build_level()
	_create_actors()
	_create_ui()
	reset_encounter(true)
	_show_briefing()

func _physics_process(delta: float) -> void:
	if briefing_active:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
			_begin_play()
		_update_ui()
		queue_redraw()
		return
	if Input.is_action_just_pressed("restart"):
		attempts += 1
		if mode == "complete":
			reset_encounter(true)
			_show_briefing()
		else:
			rewinds_used += 1
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
	if Input.is_action_just_pressed("hint"):
		_show_context_hint(5.0)
	_update_camera_shake(delta)
	announcement_time = maxf(0.0, announcement_time - delta)
	hint_time = maxf(0.0, hint_time - delta)
	if announcement_label != null:
		announcement_label.visible = announcement_time > 0.0
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
		contact_hits = 0
		unsafe_pushes = 0
		rewinds_used = 0
		deaths_count = 0
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
	result_label.hide()
	queue_redraw()

func _show_briefing() -> void:
	briefing_active = true
	mode = "briefing"
	player.active = false
	ram.set_charge_enabled(false)
	briefing_panel.show()

func _begin_play() -> void:
	briefing_active = false
	mode = "play"
	player.active = true
	ram.set_charge_enabled(true)
	briefing_panel.hide()
	last_event = "The engineer cannot move the cart. Trick the ram into moving it."
	_show_context_hint(5.5)
	_announce("RESCUE STARTED\nYour position aims the ram.")

func _announce(message: String, duration: float = 1.8) -> void:
	announcement_label.text = message
	announcement_label.visible = true
	announcement_time = duration
	_show_context_hint(maxf(4.5, duration + 1.0))

func _show_context_hint(duration: float = 4.5) -> void:
	hint_time = duration
	if hint_label != null:
		hint_label.show()
	if hint_back != null:
		hint_back.show()

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "dead"
	deaths_count += 1
	attempts += 1
	last_event = "Quick rewind: the last stable cart state is restored."
	effects.burst(player.global_position, Color("e9876c"), 12)
	sfx.play("death")
	var ticket := reset_ticket
	await get_tree().create_timer(0.38).timeout
	if mode == "dead" and ticket == reset_ticket:
		reset_encounter(false)

func _on_ram_touched_player(source: Vector2) -> void:
	if mode == "play":
		contact_hits += 1
		player.take_damage(source)
		if not contact_lesson_seen:
			contact_lesson_seen = true
			ram.receive_stun(0.65)
			last_event = "Body contact hurts. Attack only from above; a successful strike bounces you away."
			_announce("RAM CONTACT HURTS\nJUMP ABOVE IT + PRESS J/X", 2.4)

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
	# Real-time decisions remain readable: every major state transition creates
	# a short planning window without pausing or changing the rules.
	ram.receive_stun(1.0)
	match index:
		1:
			checkpoint_station = maxi(checkpoint_station, 1)
			last_event = "TRANSFER DOCK: the NPC is safe here. Now position the cart as a tool."
			sfx.play("checkpoint")
			_announce("SAFE DOCK REACHED\nR now rewinds here.")
		2:
			circuit_powered = true
			last_event = "CART + PLATE: the live rail is off. The cart is now a platform under CUT-OFF."
			sfx.play("switch")
			_announce("CART PRESSED POWER PLATE\nLIVE RAIL POWERED DOWN")
		3:
			checkpoint_station = 3
			final_switch.set_armed(true)
			last_event = "SAFE BAY: the lock behind you is armed. Bring the ram back into it."
			sfx.play("checkpoint")
			_announce("SAFE BAY REACHED\nRAM LOCK IS NOW ARMED")
		4:
			npc_arrived = true
			last_event = "NPC DELIVERED: the station gate is open."
			sfx.play("win")
			_announce("ENGINEER DELIVERED\nMEET THEM AT THE GREEN STATION", 2.4)
	queue_redraw()

func _on_cart_push_rejected(index: int) -> void:
	unsafe_pushes += 1
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
	if index == 3 and not safety_enabled:
		_announce("UNSAFE MOVE BLOCKED\nCUT-OFF ABOVE CONTROLS THIS BAY", 2.6)
	elif index == 4 and not final_lock_enabled:
		_announce("FINAL TRACK LOCKED\nBAIT RAM INTO THE RED LOCK", 2.4)

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
		_announce("CUT-OFF ACTIVATED\nDANGER BAY CHANGED RED → GREEN", 2.4)
	else:
		final_lock_enabled = true
		carriage.set_final_lock_enabled(true)
		last_event = "RAM LOCK ACTIVE: move right of the cart and drive it home."
		_announce("RAM LOCK ACTIVATED\nRAM RETURNED TO THE USEFUL SIDE", 2.4)

func _complete_level() -> void:
	mode = "complete"
	player.active = false
	player.velocity = Vector2.ZERO
	ram.set_charge_enabled(false)
	announcement_time = 0.0
	announcement_label.hide()
	var score := maxi(0, 100 - unsafe_pushes * 18 - contact_hits * 8 - deaths_count * 12 - rewinds_used * 6)
	var rank := "A" if score >= 90 else "B" if score >= 72 else "C" if score >= 50 else "D"
	result_label.text = "SYSTEM LINK COMPLETE — RANK %s\nENGINEER RESCUED\nPLAN QUALITY %d/100\nUnsafe %d   Hits %d   Rewinds %d\nR  NEW RUN" % [rank, score, unsafe_pushes, contact_hits, rewinds_used]
	result_label.show()
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
	var objective_back := ColorRect.new()
	objective_back.position = Vector2.ZERO
	objective_back.size = Vector2(384, 42)
	objective_back.color = Color(0.035, 0.075, 0.1, 0.94)
	objective_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(objective_back)
	objective_label = _label(Vector2(8, 4), Vector2(368, 35), 9, Color("f5dfa8"))
	canvas.add_child(objective_label)
	hint_back = ColorRect.new()
	hint_back.position = Vector2(7, 158)
	hint_back.size = Vector2(370, 34)
	hint_back.color = Color(0.035, 0.075, 0.1, 0.90)
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_back.visible = false
	canvas.add_child(hint_back)
	hint_label = _label(Vector2(12, 161), Vector2(360, 28), 9, Color("d7e5d5"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.visible = false
	canvas.add_child(hint_label)
	var help_back := ColorRect.new()
	help_back.position = Vector2(0, 195)
	help_back.size = Vector2(384, 21)
	help_back.color = Color(0.025, 0.055, 0.075, 0.96)
	help_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(help_back)
	help_label = _label(Vector2(7, 199), Vector2(370, 14), 8, Color("b6c4bf"))
	help_label.text = "A/D MOVE   SPACE JUMP   J/X STRIKE   H HINT   R REWIND"
	canvas.add_child(help_label)
	announcement_label = _label(Vector2(62, 50), Vector2(260, 38), 10, Color("fff1ac"))
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	announcement_label.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.09, 0.12, 0.96), Color("a9f4dd")))
	announcement_label.visible = false
	canvas.add_child(announcement_label)
	result_label = _label(Vector2(47, 48), Vector2(290, 106), 10, Color("fff1ac"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.06, 0.08, 0.98), Color("fff1ac")))
	result_label.visible = false
	canvas.add_child(result_label)

	briefing_panel = ColorRect.new()
	briefing_panel.position = Vector2.ZERO
	briefing_panel.size = Vector2(384, 216)
	briefing_panel.color = Color(0.025, 0.06, 0.08, 1.0)
	briefing_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(briefing_panel)
	var brief_title := _label(Vector2(24, 21), Vector2(336, 30), 18, Color("fff1ac"))
	brief_title.text = "RESCUE THE ENGINEER"
	brief_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing_panel.add_child(brief_title)
	var brief_goal := _label(Vector2(34, 57), Vector2(316, 42), 10, Color("d7e5d5"))
	brief_goal.text = "Their rail cart is stranded.\nDeliver it to the GREEN STATION on the right."
	brief_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brief_goal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	briefing_panel.add_child(brief_goal)
	var chain := _label(Vector2(26, 108), Vector2(332, 24), 11, Color("a9f4dd"))
	chain.text = "YOU AIM RAM  >  RAM PUSHES CART  >  RESCUE"
	chain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing_panel.add_child(chain)
	var brief_rule := _label(Vector2(35, 132), Vector2(314, 38), 9, Color("efb97b"))
	brief_rule.text = "You cannot push the heavy cart yourself.\nYour POSITION controls where the ram charges.\nStay outside its notice range whenever you need to think."
	brief_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing_panel.add_child(brief_rule)
	var begin := _label(Vector2(75, 181), Vector2(234, 18), 10, Color("fff1ac"))
	begin.text = "SPACE / J / GAMEPAD A  —  BEGIN"
	begin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing_panel.add_child(begin)

func _label(at: Vector2, dimensions: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	PixelUI.style_label(label, ui_font, font_size, color)
	return label

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style

func _update_ui() -> void:
	if objective_label == null:
		return
	objective_label.text = "MISSION: DELIVER ENGINEER TO GREEN STATION   HP %d/3\nCART %d/5  RAM %s  RAIL %s  BAY %s  GATE %s" % [
		player.health,
		carriage.station_index + 1,
		_ram_readout(),
		"OFF" if circuit_powered else "LIVE",
		"SAFE" if safety_enabled else "DANGER",
		"OPEN" if final_lock_enabled else "LOCKED",
	]
	if hint_label != null:
		hint_label.text = _current_hint()
		hint_label.visible = hint_time > 0.0 and mode != "complete"
	if hint_back != null:
		hint_back.visible = hint_time > 0.0 and mode != "complete"

func _current_hint() -> String:
	if npc_arrived:
		return "ENGINEER DELIVERED — WALK TO THE GREEN STATION DOOR"
	match carriage.station_index:
		0:
			if player.global_position.x < 300.0:
				return "RED ARROW = RAM DIRECTION LOCKED\nJUMP ABOVE RAM + J/X = HIGH BOUNCE"
			return "STAND BEYOND THE CART → WAIT FOR RED ARROW → DODGE THE CHARGE"
		1:
			return "SAFE CHECKPOINT — BAIT ANOTHER RIGHT CHARGE ONTO THE GOLD POWER PLATE"
		2:
			if not safety_enabled:
				return "RED BAY UNSAFE — CUT-OFF ABOVE CONTROLS IT\nHOW CAN CART POSITION + RAM BOUNCE CREATE HEIGHT?"
			return "DANGER BAY IS GREEN/SAFE — BAIT ONE RIGHTWARD CART PUSH"
		3:
			if not final_lock_enabled:
				return "GATE LOCKED — RED LOCK ACCEPTS RAM IMPACTS\nPLAN WHERE ITS REBOUND MUST LEAVE THE RAM"
			return "RAM IS LEFT OF CART — WHERE SHOULD YOU STAND TO MAKE IT PUSH RIGHT?"
	return "FOLLOW THE ENGINEER'S CART TO THE GREEN STATION"

func _ram_readout() -> String:
	var arrow := ">" if ram.facing > 0 else "<"
	match ram.state:
		"windup": return "LOCK%s" % arrow
		"coast": return "CHARGE%s" % arrow
		"stunned": return "STUNNED"
	var difference := ram.global_position.x - player.global_position.x
	if difference < -185.0:
		return "LEFT"
	if difference > 185.0:
		return "RIGHT"
	return "NEAR"

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
	var stop_names := ["START", "SAFE", "POWER", "BAY", "STATION"]
	for i in CART_STATIONS.size():
		var color := Color("a9f4dd") if carriage != null and carriage.station_index >= i else Color("657b83")
		draw_rect(Rect2(CART_STATIONS[i] - 3, 174, 6, 8), color)
		draw_string(ui_font, Vector2(CART_STATIONS[i] - 28, 156), "%d %s" % [i + 1, stop_names[i]], HORIZONTAL_ALIGNMENT_CENTER, 56, 7, color)
	# Visible wiring shows why this cart stop changes the live rail.
	var circuit_color := Color("a9f4dd") if circuit_powered else Color("d7b06f")
	draw_rect(Rect2(CART_STATIONS[2] - 38, 177, 76, 5), circuit_color)
	draw_line(Vector2(CART_STATIONS[2], 177), Vector2(ELECTRIC_RECT.get_center().x, 177), circuit_color, 2.0)
	draw_circle(Vector2(CART_STATIONS[2], 177), 4.0, circuit_color)
	if carriage != null and carriage.station_index < 2:
		draw_string(ui_font, Vector2(CART_STATIONS[2] - 37, 145), "CART POWER PLATE", HORIZONTAL_ALIGNMENT_CENTER, 74, 7, circuit_color)
	var electric_color := Color("304551") if circuit_powered else Color("75d6d2")
	draw_rect(ELECTRIC_RECT, Color("20303b"))
	for x in range(int(ELECTRIC_RECT.position.x), int(ELECTRIC_RECT.end.x), 7):
		draw_line(Vector2(x, ELECTRIC_RECT.position.y), Vector2(x + 4, ELECTRIC_RECT.end.y), electric_color, 2.0)
	var bay_color := Color("587b72") if safety_enabled else Color("b84f4f")
	draw_rect(Rect2(1110, 116, 100, 8), bay_color)
	draw_line(Vector2(1120, 124), Vector2(1140, 157), bay_color, 4.0)
	draw_line(Vector2(1200, 124), Vector2(1180, 157), bay_color, 4.0)
	draw_string(ui_font, Vector2(1112, 108), "ENGINEER DANGER BAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, bay_color)
	var gate_color := Color("a9f4dd") if final_lock_enabled else Color("ef9569")
	draw_rect(Rect2(1440, 112, 6, 70), gate_color)
	draw_string(ui_font, Vector2(1028, 76), "HIT WITH RAM", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, gate_color)
	draw_rect(Rect2(GOAL_POSITION.x - 13, GOAL_POSITION.y - 36, 26, 38), Color("a47b55"))
	draw_rect(Rect2(GOAL_POSITION.x - 9, GOAL_POSITION.y - 31, 18, 25), Color("a9f4dd") if npc_arrived else Color("304551"))
	draw_string(ui_font, Vector2(1528, 101), "GREEN STATION — DELIVER ENGINEER", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("a9f4dd"))
	if carriage != null and carriage.npc_mood == "alarm":
		draw_string(ui_font, carriage.position + Vector2(-76, -42), "ENGINEER: STOP! CUT-OFF FIRST!", HORIZONTAL_ALIGNMENT_CENTER, 152, 8, Color("fff1ac"))
	draw_string(ui_font, Vector2(38, 76), "RAM = DANGER + YOUR ONLY TOOL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
	draw_string(ui_font, Vector2(405, 76), "ENGINEER'S CART — RAM IMPACTS ONLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))

func _setup_inputs() -> void:
	_add_action("move_left", 0.2)
	_add_action("move_right", 0.2)
	_add_action("aim_up", 0.2)
	_add_action("aim_down", 0.2)
	_add_action("jump")
	_add_action("attack")
	_add_action("dash")
	_add_action("restart")
	_add_action("hint")
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_key("jump", KEY_SPACE)
	_add_key("attack", KEY_J)
	_add_key("attack", KEY_X)
	_add_key("restart", KEY_R)
	_add_key("hint", KEY_H)
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
