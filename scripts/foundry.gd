extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const CanScript = preload("res://scripts/foundry_can.gd")
const CartScript = preload("res://scripts/foundry_cart.gd")
const MechanismScript = preload("res://scripts/foundry_mechanism.gd")
const SwitchScript = preload("res://scripts/foundry_switch.gd")
const CrusherScript = preload("res://scripts/crusher.gd")
const EffectsScript = preload("res://scripts/effects.gd")
const SoundScript = preload("res://scripts/sfx.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")

const WORLD_WIDTH := 3600.0
const START := Vector2(165, 291)
const CAN_START := Vector2(125, 290)
const STATIONS := [720.0, 920.0, 1780.0, 1990.0, 2300.0, 2810.0, 2950.0, 3230.0]
const GOAL := Vector2(3510, 291)

var greybox_mode := false
var player: CharacterBody2D
var can: Area2D
var cart: AnimatableBody2D
var camera: Camera2D
var effects: Node2D
var sound: Node
var mechanisms: Dictionary = {}
var switches: Dictionary = {}
var crushers: Array[AnimatableBody2D] = []
var geometry: Array[Rect2] = []
var checkpoint_data: Dictionary = {}
var checkpoint_id := "entrance"
var checkpoint_name := "INSPECTION"
var mode := "play"
var clock := 0.0
var elapsed := 0.0
var reset_serial := 0
var deaths := 0
var rewinds := 0
var impacts := 0
var stomps := 0
var shake := 0.0
var hint_time := 0.0
var notice_time := 0.0
var last_notice := ""
var font: Font
var hud: Label
var hint: Label
var notice: Label
var overlay: Label
var map_line: Label

func _ready() -> void:
	get_window().title = "Foundry / Future States"
	font = PixelUI.make_font()
	_setup_inputs()
	effects = EffectsScript.new()
	add_child(effects)
	sound = SoundScript.new()
	add_child(sound)
	if greybox_mode:
		_build_mastery()
	else:
		_build_route()
	_create_actors()
	_create_ui()
	save_checkpoint("entrance", "INSPECTION", START if not greybox_mode else Vector2(2750, 291))
	hint_time = 6.0

func _build_route() -> void:
	_block(Rect2(0, 300, WORLD_WIDTH, 60))
	_block(Rect2(-20, 0, 20, 360))
	_block(Rect2(WORLD_WIDTH, 0, 20, 360))
	_mechanism("pump_wall", "breakable", Rect2(100, 96, 16, 204), "SERVICE / SEALED")
	_switch("pump", Vector2(64, 289), "EVAC PUMP")
	_block(Rect2(330, 225, 145, 8), true)
	_switch("inspection", Vector2(395, 216), "TRACK RELEASE")
	_mechanism("inspection_gate", "gate", Rect2(510, 85, 14, 215), "INSPECTION")
	_block(Rect2(630, 224, 85, 8), true)
	_block(Rect2(800, 220, 300, 8), true)
	# Raised freight pin obstructs the transport chassis; a worker or Can with
	# lowered forks fits in the visible 21-pixel service gap below it.
	_mechanism("freight_pin", "gate", Rect2(1000, 250, 14, 29), "TRACK PIN")
	_mechanism("transfer_wall", "breakable", Rect2(1125, 98, 18, 202), "FRACTURED")
	_block(Rect2(1175, 222, 110, 8), true)
	_crusher(Vector2(1500, 229), 0.0)
	_block(Rect2(1530, 228, 100, 8), true)
	_switch("freight", Vector2(1580, 219), "FREIGHT RELEASE")
	_mechanism("freight_gate", "gate", Rect2(1670, 100, 14, 200), "FREIGHT")
	_block(Rect2(1735, 214, 90, 8), true)
	_switch("vent", Vector2(1780, 205), "VENTILATION")
	_block(Rect2(1925, 224, 100, 8), true)
	_mechanism("weight_gate", "gate", Rect2(2170, 226, 16, 74), "WEIGHT CIRCUIT")
	var plate := _mechanism("yard_plate", "plate", Rect2(1940, 294, 100, 12), "HEAVY WEIGHT")
	plate.linked_gate = mechanisms.weight_gate
	_switch("yard_release", Vector2(2220, 289), "HOLD OPEN")
	# The upper service line overlaps prior encounters and makes the return trip
	# a revisit of a working place, rather than a level transition or reset.
	_block(Rect2(2200, 224, 165, 8), true)
	_block(Rect2(2335, 198, 145, 8), true)
	_block(Rect2(2520, 220, 100, 8), true)
	_mechanism("vent_gate", "gate", Rect2(2490, 90, 14, 210), "AIR / VENT")
	_mechanism("pump_gate", "gate", Rect2(2670, 90, 14, 210), "EVAC POWER")
	_build_mastery(false)
	_block(Rect2(3200, 224, 140, 8), true)
	_mechanism("escape_wall", "breakable", Rect2(3400, 100, 18, 200), "EVAC / FRACTURED")

func _build_mastery(add_floor: bool = true) -> void:
	if add_floor:
		_block(Rect2(2700, 300, 900, 60))
		_block(Rect2(2690, 0, 10, 360))
		_block(Rect2(3600, 0, 20, 360))
	_block(Rect2(2765, 214, 90, 8), true)
	_switch("isolation", Vector2(2810, 205), "PRESS ISOLATION")
	_crusher(Vector2(2908, 229), 1.6)
	_mechanism("final_gate", "gate", Rect2(3120, 226, 16, 74), "DELIVERY / WEIGHT")
	var plate := _mechanism("final_plate", "plate", Rect2(2875, 294, 120, 12), "HEAVY WEIGHT")
	plate.linked_gate = mechanisms.final_gate
	_block(Rect2(3010, 214, 150, 8), true)
	_switch("final_release", Vector2(3190, 289), "HOLD OPEN")

func _create_actors() -> void:
	cart = CartScript.new()
	cart.name = "EngineerTransport"
	cart.configure_systemic(Vector2(STATIONS[0], 284), PackedFloat32Array(STATIONS))
	cart.station_changed.connect(_on_cart_arrived)
	cart.ram_impact.connect(_on_impact)
	add_child(cart)
	if greybox_mode:
		cart.force_station(5)
	can = CanScript.new()
	can.name = "MaintenanceCan"
	can.configure_systemic_ram(CAN_START if not greybox_mode else Vector2(2740, 290), 45.0 if not greybox_mode else 2710.0, 3540.0)
	can.charge_locked.connect(func(_direction: int) -> void: sound.play("telegraph"))
	can.kinetic_struck.connect(func(_a: float, _b: float) -> void:
		stomps += 1
		effects.burst(can.position, Color("a9f4dd"), 7)
	)
	can.touched_player.connect(func(at: Vector2) -> void:
		if mode == "play":
			player.take_damage(at)
	)
	can.stunned.connect(func(_duration: float) -> void: sound.play("hit"))
	add_child(can)
	player = PlayerScript.new()
	player.position = START if not greybox_mode else Vector2(2750, 291)
	player.dash_enabled = false
	player.rebounded.connect(func(at: Vector2) -> void:
		sound.play("bounce")
		effects.burst(at, Color("fff1ac"), 8)
	)
	player.jumped.connect(func(_at: Vector2) -> void: sound.play("jump"))
	player.died.connect(_on_death)
	add_child(player)
	player.strike_shape.size = Vector2(20, 12)
	player.air_acceleration = 1600.0
	camera = Camera2D.new()
	camera.position = Vector2(0, -70)
	camera.limit_left = 0 if not greybox_mode else 2700
	camera.limit_right = 3600
	camera.limit_top = 75
	camera.limit_bottom = 325
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	player.add_child(camera)
	camera.make_current()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		set_suspended(mode == "play")
	if Input.is_action_just_pressed("restart"):
		if Input.is_key_pressed(KEY_SHIFT) or mode == "complete":
			get_tree().reload_current_scene()
		else:
			rewinds += 1
			restore_checkpoint()
	if Input.is_action_just_pressed("hint"):
		hint_time = 7.0
	if mode != "play":
		return
	clock += delta
	elapsed += delta
	notice_time = maxf(0.0, notice_time - delta)
	hint_time = maxf(0.0, hint_time - delta)
	shake = maxf(0.0, shake - delta)
	camera.offset = Vector2(sin(clock * 88.0), cos(clock * 75.0)) * (1.5 if shake > 0.0 else 0.0)
	if player.position.y > 365.0:
		player.kill()
	if not greybox_mode:
		_check_checkpoints()
		if cart.station_index == 7 and mechanisms.escape_wall.broken and player.position.distance_to(GOAL) < 22.0:
			_complete()
	_update_ui()
	queue_redraw()

func _switch(id: String, at: Vector2, title: String) -> void:
	var lever := SwitchScript.new()
	lever.configure("strike", at, title)
	lever.activated.connect(func(_type: String, point: Vector2) -> void: _activate_switch(id, point))
	switches[id] = lever
	add_child(lever)

func _activate_switch(id: String, at: Vector2) -> void:
	match id:
		"inspection": mechanisms.inspection_gate.latch_open()
		"freight":
			mechanisms.freight_gate.latch_open()
			mechanisms.freight_pin.latch_open()
		"vent": mechanisms.vent_gate.latch_open()
		"pump": mechanisms.pump_gate.latch_open()
		"yard_release": mechanisms.weight_gate.latch_open()
		"final_release": mechanisms.final_gate.latch_open()
		"isolation": crushers[-1].disabled = true
	sound.play("switch")
	effects.burst(at, Color("a9f4dd"), 12)
	_notify("%s  /  CIRCUIT LATCHED" % switches[id].label)

func _mechanism(id: String, type: String, area: Rect2, title: String) -> Node2D:
	var item := MechanismScript.new()
	item.name = id
	item.configure(type, area, title)
	item.changed.connect(func(_mechanism: Node2D) -> void: sound.play("switch"))
	item.impacted.connect(func(at: Vector2) -> void:
		sound.play("hit")
		effects.burst(at, Color("ef9569"), 16)
		shake = 0.18
	)
	mechanisms[id] = item
	add_child(item)
	return item

func _crusher(at: Vector2, phase: float) -> void:
	var press := CrusherScript.new()
	press.foundry_mode = true
	press.configure(Vector2(at.x, 140), phase)
	press.drop_distance = 131.0
	press.cycle_length = 4.0
	press.warning_lead = 0.55
	press.cycle_warning.connect(func() -> void: sound.play("alarm"))
	press.crushed_player.connect(func() -> void:
		if mode == "play":
			player.kill()
	)
	crushers.append(press)
	add_child(press)

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
	if one_way:
		collision.one_way_collision_margin = 3.0
	body.add_child(collision)
	add_child(body)

func _on_impact(_momentum: float, speed: float) -> void:
	if not is_zero_approx(speed):
		impacts += 1
	sound.play("hit")
	effects.burst(cart.position, Color("d7b06f"), 12)
	shake = 0.17

func _on_cart_arrived(index: int) -> void:
	if index == 7:
		cart.npc_mood = "relieved"
		_notify("ENGINEER DELIVERED  /  EVAC DOOR AHEAD")
		save_checkpoint("delivered", "EVACUATION", Vector2(3280, 291))
	else:
		_notify("TRANSPORT DOCKED  /  %s" % _dock_name(index))

func _check_checkpoints() -> void:
	if checkpoint_id == "entrance" and cart.station_index >= 1 and player.position.x > 960.0:
		save_checkpoint("press", "PRESS HALL", Vector2(980, 291))
	elif checkpoint_id == "press" and switches.freight.active and cart.station_index == 2 and player.position.x > 1690.0:
		save_checkpoint("yard", "TRANSFER YARD", Vector2(1710, 291))
	elif checkpoint_id == "yard" and cart.station_index == 4 and switches.vent.active and switches.yard_release.active:
		save_checkpoint("bay", "SERVICE LOOP", Vector2(2340, 291))
	elif checkpoint_id == "bay" and switches.pump.active and cart.station_index == 5 and player.position.x > 2700.0 and can.position.x > 2680.0:
		save_checkpoint("mastery", "DELIVERY YARD", Vector2(2760, 291))

func save_checkpoint(id: String, title: String, respawn: Vector2) -> void:
	checkpoint_id = id
	checkpoint_name = title
	var object_data: Dictionary = {}
	for key in mechanisms:
		object_data[key] = mechanisms[key].snapshot()
	var lever_data: Dictionary = {}
	for key in switches:
		lever_data[key] = switches[key].active
	var press_data: Array[Dictionary] = []
	for press in crushers:
		press_data.append({"clock": press.clock, "disabled": press.disabled, "position": press.position})
	checkpoint_data = {
		"player": respawn, "can_position": can.position, "can_state": can.state,
		"can_time": can.state_time, "can_facing": can.facing, "can_velocity": can.velocity_x,
		"can_cooldown": can.cooldown, "cart": cart.snapshot(),
		"objects": object_data, "switches": lever_data, "presses": press_data,
	}
	if id != "entrance":
		sound.play("checkpoint")
		_notify("CHECKPOINT  /  %s" % title)

func restore_checkpoint() -> void:
	reset_serial += 1
	mode = "play"
	player.reset_at(checkpoint_data.player)
	can.position = checkpoint_data.can_position
	can.state = checkpoint_data.can_state
	can.state_time = checkpoint_data.can_time
	can.facing = checkpoint_data.can_facing
	can.velocity_x = checkpoint_data.can_velocity
	can.cooldown = checkpoint_data.can_cooldown
	can.contact_cooldown = 0.25
	can.suspended = false
	can.charge_enabled = true
	cart.restore(checkpoint_data.cart)
	cart.suspended = false
	for key in mechanisms:
		mechanisms[key].restore(checkpoint_data.objects[key])
		mechanisms[key].suspended = false
	for key in switches:
		switches[key].active = checkpoint_data.switches[key]
		switches[key].pulse = 0.0
	for i in crushers.size():
		crushers[i].clock = checkpoint_data.presses[i].clock
		crushers[i].disabled = checkpoint_data.presses[i].disabled
		crushers[i].position = checkpoint_data.presses[i].position
		crushers[i].suspended = false
	effects.particles.clear()
	camera.offset = Vector2.ZERO
	camera.reset_smoothing()
	overlay.hide()
	_notify("REWOUND  /  %s" % checkpoint_name)
	_update_ui()

func _on_death() -> void:
	if mode != "play":
		return
	deaths += 1
	mode = "dead"
	_freeze_world(true)
	sound.play("death")
	effects.burst(player.position, Color("ef9569"), 12)
	var serial := reset_serial
	await get_tree().create_timer(0.4).timeout
	if mode == "dead" and serial == reset_serial:
		restore_checkpoint()

func _freeze_world(value: bool) -> void:
	can.suspended = value
	cart.suspended = value
	for object in mechanisms.values():
		object.suspended = value
	for press in crushers:
		press.suspended = value
	player.active = not value

func set_suspended(value: bool) -> void:
	if mode not in ["play", "paused"]:
		return
	mode = "paused" if value else "play"
	_freeze_world(value)
	overlay.text = "PAUSED\n\nESC  RESUME\nR  REWIND ENCOUNTER\nSHIFT + R  NEW RUN"
	overlay.visible = value

func _complete() -> void:
	mode = "complete"
	_freeze_world(true)
	overlay.text = "FUTURE STATES\nENGINEER SAFE / FACILITY EVACUATED\n\n%02d:%02d   %d IMPACTS   %d REWINDS\n\nR  NEW RUN" % [int(elapsed / 60), int(elapsed) % 60, impacts, rewinds]
	overlay.show()
	hint.hide()
	sound.play("win")
	effects.burst(GOAL, Color("fff1ac"), 24)

func _notify(message: String) -> void:
	last_notice = message
	notice_time = 2.0

func _hint_text() -> String:
	if greybox_mode:
		return "Heavy weight powers the door. Switches hold circuits open."
	if not switches.inspection.active:
		return "SPACE jump. J/X above Can or Cart: stomp + rebound."
	if cart.station_index < 2:
		return "The engineer waits on the rail. Watch the Can's locked arrow."
	if not switches.vent.active:
		return "Ventilation is above ROOF dock. Different docks offer different access."
	if not switches.yard_release.active:
		return "Heavy plates need a grounded load. HOLD OPEN latches a circuit."
	if not switches.pump.active:
		return "Evac power: the sealed service pump near inspection."
	if cart.station_index < 7:
		return "Wheels / grounded shell: heavy weight. HOLD OPEN persists."
	return "The engineer is safe. Reach the evacuation terminal."

func _dock_name(index: int) -> String:
	return ["STRANDED", "TRANSFER", "ROOF", "WEIGHT", "SERVICE", "ISOLATION", "WEIGHT", "DELIVERY"][index]

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = _label(Vector2(7, 4), Vector2(370, 26), 8)
	map_line = _label(Vector2(7, 31), Vector2(370, 12), 7)
	hint = _label(Vector2(8, 43), Vector2(368, 20), 8)
	notice = _label(Vector2(25, 65), Vector2(334, 19), 8)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay = _label(Vector2(30, 65), Vector2(324, 92), 10)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay.hide()
	for item in [hud, map_line, hint, notice, overlay]:
		layer.add_child(item)
	var controls := _label(Vector2(7, 199), Vector2(372, 13), 7)
	controls.text = "A/D MOVE  SPACE JUMP  J/X STOMP  H HINT  R REWIND  ESC PAUSE"
	layer.add_child(controls)

func _label(at: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PixelUI.style_label(label, font, font_size, Color("d7e5d5"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.075, 0.1, 0.93)
	panel.content_margin_left = 3
	panel.content_margin_right = 3
	label.add_theme_stylebox_override("normal", panel)
	return label

func _update_ui() -> void:
	var state: String = can.state.to_upper()
	if can.state == "idle":
		state = "SEARCH"
	if can.state in ["windup", "charging"]:
		state += " >" if can.facing > 0 else " <"
	elif can.state == "stunned":
		state += " %.1fs" % can.state_time
	var side := "<" if can.position.x < player.position.x else ">"
	var cart_state := _dock_name(cart.station_index)
	if cart.target_station != cart.station_index:
		cart_state += " > " + _dock_name(cart.target_station)
	if cart.stalled:
		cart_state += " / STALLED"
	hud.text = "DELIVER ENGINEER / RESTORE EVAC  HP %d\nCAN %s %s   CART %s" % [player.health, side, state, cart_state]
	if greybox_mode:
		map_line.text = "DELIVERY YARD  |  WEIGHT %.0f  |  DOOR %s" % [mechanisms.final_plate.mass, "OPEN" if mechanisms.final_gate.active else "CLOSED"]
	else:
		map_line.text = "AIR %s  EVAC %s  |  R: %s" % ["ON" if switches.vent.active else "OFF", "ON" if switches.pump.active else "OFF", checkpoint_name]
	hint.text = _hint_text()
	hint.visible = hint_time > 0.0
	notice.text = last_notice
	notice.visible = notice_time > 0.0

func _draw() -> void:
	draw_rect(Rect2(0, 70, WORLD_WIDTH, 290), Color("101d28"))
	for x in range(0, 3600, 180):
		draw_rect(Rect2(x + 12, 82, 6, 218), Color("263d48"))
		draw_circle(Vector2(x + 95, 160), 24, Color("20333e"))
		draw_arc(Vector2(x + 95, 160), 24, 0, TAU, 20, Color("2a414a"), 3.0)
		draw_line(Vector2(x, 116), Vector2(x + 180, 116), Color("304551"), 4.0)
	for rect in geometry:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color("c3935f"))
		for x in range(int(rect.position.x) + 9, int(rect.end.x), 24):
			draw_rect(Rect2(x, rect.position.y + 1, 2, 2), Color("edc27a"))
	draw_line(Vector2(610, 298), Vector2(3310, 298), Color("657b83"), 2.0)
	for i in STATIONS.size():
		draw_rect(Rect2(STATIONS[i] - 3, 300, 6, 12), Color("d7b06f"))
		draw_string(font, Vector2(STATIONS[i] - 40, 326), _dock_name(i), HORIZONTAL_ALIGNMENT_CENTER, 80, 7, Color("d7b06f"))
	if not greybox_mode:
		var signs := [[160, "01 / INSPECTION"], [685, "02 / TRANSFER"], [1180, "03 / PRESS HALL"], [1740, "04 / SWITCH YARD"], [2320, "SERVICE LOOP  <  EVAC PUMP"], [2780, "05 / DELIVERY"], [3430, "EVACUATION"]]
		for sign in signs:
			draw_string(font, Vector2(sign[0], 174), sign[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("9ac6c7"))
		_draw_wire("inspection", "inspection_gate")
		_draw_wire("freight", "freight_gate")
		_draw_wire("freight", "freight_pin")
		_draw_wire("vent", "vent_gate")
		_draw_wire("pump", "pump_gate")
		_draw_wire("yard_release", "weight_gate")
	_draw_wire("final_release", "final_gate")
	if switches.has("isolation"):
		var color := Color("a9f4dd") if switches.isolation.active else Color("d7b06f")
		draw_line(switches.isolation.position + Vector2(12, 0), crushers[-1].high, color, 1.0)
	for press in crushers:
		var phase: float = fmod(press.clock, press.cycle_length)
		var warning: bool = phase >= maxf(0.0, 0.55 - press.warning_lead) and phase < 1.75 and not press.disabled
		var color := Color("ef9569") if warning else Color("a9f4dd")
		draw_line(Vector2(press.high.x, 182), Vector2(press.high.x, 294), Color(color, 0.15), 24.0)
		draw_circle(Vector2(press.high.x + 22, 257), 4.0, color)
		draw_string(font, Vector2(press.high.x - 30, 318), "PRESS OFF" if press.disabled else "PRESS", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, color)
	if not greybox_mode:
		draw_rect(Rect2(GOAL - Vector2(13, 38), Vector2(26, 47)), Color("657b83"))
		draw_rect(Rect2(GOAL - Vector2(9, 33), Vector2(18, 30)), Color("a9f4dd") if cart.station_index == 7 else Color("304551"))

func _draw_wire(lever_id: String, gate_id: String) -> void:
	if not switches.has(lever_id) or not mechanisms.has(gate_id):
		return
	var color := Color("a9f4dd") if switches[lever_id].active else Color("586976")
	var point: Vector2 = switches[lever_id].position
	var end: Vector2 = mechanisms[gate_id].rect.position
	var lanes := {"inspection": 184.0, "freight": 178.0, "vent": 168.0, "pump": 158.0, "yard_release": 238.0, "final_release": 238.0}
	var wire_y: float = lanes.get(lever_id, 184.0)
	draw_line(point, Vector2(point.x, wire_y), color, 1.0)
	draw_line(Vector2(point.x, wire_y), Vector2(end.x, wire_y), color, 1.0)
	draw_line(Vector2(end.x, wire_y), end, color, 1.0)

func _setup_inputs() -> void:
	# Reuse registration from the preserved prototype, avoiding duplicate events.
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "attack": [KEY_J, KEY_X], "restart": [KEY_R], "pause": [KEY_ESCAPE], "hint": [KEY_H], "aim_up": [], "aim_down": [], "dash": []}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var pads := {"move_left": 13, "move_right": 14, "jump": 0, "attack": 2, "restart": 3, "pause": 6}
	for action in pads:
		var event := InputEventJoypadButton.new()
		event.button_index = pads[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	for action in ["move_left", "move_right"]:
		var event := InputEventJoypadMotion.new()
		event.axis = 0
		event.axis_value = -1.0 if action == "move_left" else 1.0
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
