extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const EnemyScene = preload("res://scripts/enemy.gd")
const PressureScene = preload("res://scripts/can_pressure_switch.gd")
const FanScene = preload("res://scripts/can_fan.gd")
const LaserScene = preload("res://scripts/can_laser_rig.gd")
const StrikeSwitchScene = preload("res://scripts/systemic_switch.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")

const LEVEL_COUNT := 7
const FLOOR_Y := 190.0
const LEVEL_TITLES := [
	"1  READ THE CAN",
	"2  HEAVY CURRENT",
	"3  USEFUL JAM",
	"4  BEFORE YOU COMMIT",
	"5  ANGLE OF ATTACK",
	"6  POWER AND AIM",
	"7  SYSTEM MASTERY",
]
const LEVEL_GOALS := [
	"Read the arrow, dodge the charge, then bounce from above.",
	"Trap the Can on HEAVY SWITCH to sustain the fan.",
	"Wedge the Can in the clamp; its final position is the tool.",
	"Use the roaming Can before committing it to the switch.",
	"Drive the Can into the emitter until its beam finds SENSOR.",
	"Use both the held switch/fan and the laser/sensor bridge.",
	"Chain every learned rule. No new mechanic remains.",
]

var world_root: Node2D
var player: CharacterBody2D
var ram: Area2D
var pressure: Node2D
var fan: Node2D
var laser: Node2D
var strike_switch: Area2D
var effects: Node2D
var sfx: Node
var ui_font: Font

var level_index := 0
var mode := "card"
var blocks: Array[Rect2] = []
var spike_rects: Array[Rect2] = []
var bridge_rect := Rect2()
var bridge_body: StaticBody2D
var goal_position := Vector2.ZERO
var goal_enabled := false
var wedge_position := Vector2.ZERO
var has_wedge := false
var upper_latch := false
var power_latch := false
var wedge_release_grace := 0.0
var failure_ticket := 0
var attempts := 0
var level_start_time := 0.0
var total_time := 0.0
var unsafe_commits := 0

var top_label: Label
var hint_label: Label
var hint_back: ColorRect
var announcement_label: Label
var card_panel: ColorRect
var card_title: Label
var card_body: Label
var result_panel: ColorRect
var result_label: Label
var hint_time := 0.0
var announcement_time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_font = PixelUI.make_font()
	_setup_inputs()
	sfx = SfxScene.new()
	add_child(sfx)
	_create_ui()
	_show_level_card(0)

func _physics_process(delta: float) -> void:
	if mode == "card":
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
			_start_level()
		return
	if mode == "campaign_complete":
		if Input.is_action_just_pressed("restart"):
			level_index = 0
			total_time = 0.0
			attempts = 0
			unsafe_commits = 0
			result_panel.hide()
			_show_level_card(0)
		return
	if mode != "play":
		return

	level_start_time += delta
	wedge_release_grace = maxf(0.0, wedge_release_grace - delta)
	hint_time = maxf(0.0, hint_time - delta)
	announcement_time = maxf(0.0, announcement_time - delta)
	_update_transient_ui()

	if Input.is_action_just_pressed("restart"):
		attempts += 1
		_build_level(level_index)
		return
	if Input.is_action_just_pressed("hint"):
		_show_hint(5.0)

	if player.global_position.y > 235.0:
		player.kill()
	if fan != null:
		fan.lift(player, delta)
	_update_pressure_logic()
	_update_mastery_power()
	_update_goal_state()
	_update_hud()
	queue_redraw()

func _show_level_card(index: int) -> void:
	level_index = index
	mode = "card"
	if is_instance_valid(world_root):
		world_root.queue_free()
	card_title.text = LEVEL_TITLES[index]
	card_body.text = "%s\n\nCAN LOOP\nREAD INTENT  >  GUIDE FORCE  >  USE WORLD REACTION\n\nSPACE / J / GAMEPAD A  —  START" % LEVEL_GOALS[index]
	card_panel.show()
	result_panel.hide()

func _start_level() -> void:
	card_panel.hide()
	_build_level(level_index)

func _build_level(index: int) -> void:
	failure_ticket += 1
	level_index = index
	card_panel.hide()
	result_panel.hide()
	if is_instance_valid(world_root):
		world_root.free()
	world_root = Node2D.new()
	world_root.name = "Level%d" % (index + 1)
	add_child(world_root)
	move_child(world_root, 0)
	blocks.clear()
	spike_rects.clear()
	bridge_rect = Rect2()
	bridge_body = null
	pressure = null
	fan = null
	laser = null
	strike_switch = null
	upper_latch = false
	power_latch = false
	has_wedge = false
	wedge_release_grace = 0.0
	goal_enabled = false
	level_start_time = 0.0
	mode = "play"

	match index:
		0: _build_level_1()
		1: _build_level_2()
		2: _build_level_3()
		3: _build_level_4()
		4: _build_level_5()
		5: _build_level_6()
		6: _build_level_7()

	_create_actors(_player_spawn(index), _ram_spawn(index))
	_show_hint(5.5)
	_announce("LEVEL %d\n%s" % [index + 1, LEVEL_TITLES[index].substr(3)], 1.6)
	_update_hud()
	queue_redraw()

func _create_actors(player_at: Vector2, ram_at: Vector2) -> void:
	ram = EnemyScene.new() as Area2D
	ram.name = "Can"
	ram.configure_systemic_ram(ram_at, 28.0, 356.0)
	ram.trigger_range = 145.0
	ram.charge_impulse = 132.0
	ram.touched_player.connect(_on_ram_touched_player)
	ram.kinetic_struck.connect(_on_ram_struck)
	ram.charge_locked.connect(func(direction: int) -> void:
		_announce("CAN LOCKED %s\nDODGE — IT WILL NOT TURN" % ("RIGHT" if direction > 0 else "LEFT"), 1.0)
		sfx.play("telegraph")
	)
	world_root.add_child(ram)

	player = PlayerScene.new()
	player.position = player_at
	player.died.connect(_on_player_died)
	player.rebounded.connect(func(at: Vector2) -> void:
		effects.burst(at, Color("fff1ac"), 9)
		sfx.play("bounce")
	)
	player.jumped.connect(func(_at: Vector2) -> void: sfx.play("jump"))
	world_root.add_child(player)

	effects = EffectsScene.new()
	world_root.add_child(effects)

func _build_level_1() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(278, 120, 106, 70))
	goal_position = Vector2(346, 100)

func _build_level_2() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(298, 88, 86, 12), true)
	_add_pressure(Vector2(126, 184), "PARK CAN HERE")
	_add_fan(Vector2(246, 184), 118.0)
	wedge_position = Vector2(126, 172)
	has_wedge = true
	goal_position = Vector2(344, 68)

func _build_level_3() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(296, 86, 88, 12), true)
	_add_pressure(Vector2(154, 184), "CLAMP + SWITCH")
	_add_fan(Vector2(264, 184), 122.0)
	wedge_position = Vector2(154, 172)
	has_wedge = true
	goal_position = Vector2(342, 66)

func _build_level_4() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(142, 104, 86, 10), true)
	_add_block(Rect2(300, 84, 84, 12), true)
	_add_pressure(Vector2(116, 184), "COMMIT LAST")
	_add_fan(Vector2(260, 184), 124.0)
	strike_switch = StrikeSwitchScene.new() as Area2D
	strike_switch.configure("strike", Vector2(184, 95), "PREP LATCH")
	strike_switch.activated.connect(func(_kind: String, at: Vector2) -> void:
		upper_latch = true
		effects.burst(at, Color("a9f4dd"), 14)
		sfx.play("switch")
		_announce("PREP LATCH SET\nNOW COMMIT THE CAN TO THE SWITCH", 2.0)
	)
	world_root.add_child(strike_switch)
	wedge_position = Vector2(116, 172)
	has_wedge = true
	goal_position = Vector2(342, 64)

func _build_level_5() -> void:
	_add_block(Rect2(0, FLOOR_Y, 252, 26))
	_add_block(Rect2(334, FLOOR_Y, 50, 26))
	_add_spikes(Rect2(252, FLOOR_Y, 82, 26))
	_add_laser(Vector2(188, 172), Vector2(306, 172), 2)
	bridge_rect = Rect2(252, 172, 82, 10)
	goal_position = Vector2(356, 171)

func _build_level_6() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(130, 102, 92, 10), true)
	_add_block(Rect2(316, 88, 68, 10), true)
	_add_pressure(Vector2(84, 184), "FAN SWITCH")
	_add_fan(Vector2(174, 184), 118.0)
	_add_laser(Vector2(276, 172), Vector2(276, 70), 1)
	wedge_position = Vector2(84, 172)
	has_wedge = true
	bridge_rect = Rect2(222, 102, 94, 10)
	goal_position = Vector2(350, 68)

func _build_level_7() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(132, 102, 86, 10), true)
	_add_block(Rect2(314, 82, 70, 10), true)
	_add_pressure(Vector2(82, 184), "SYSTEM POWER")
	_add_fan(Vector2(172, 184), 120.0)
	strike_switch = StrikeSwitchScene.new() as Area2D
	strike_switch.configure("strike", Vector2(176, 93), "POWER LATCH")
	strike_switch.activated.connect(func(_kind: String, at: Vector2) -> void:
		power_latch = true
		laser.armed = true
		effects.burst(at, Color("a9f4dd"), 16)
		sfx.play("sensor")
		_announce("SYSTEM POWER LATCHED\nTHE LASER RIG NOW ACCEPTS FORCE", 2.2)
	)
	world_root.add_child(strike_switch)
	_add_laser(Vector2(276, 172), Vector2(276, 66), 1)
	laser.armed = false
	wedge_position = Vector2(82, 172)
	has_wedge = true
	bridge_rect = Rect2(218, 102, 96, 10)
	goal_position = Vector2(350, 62)

func _add_pressure(at: Vector2, label: String) -> void:
	pressure = PressureScene.new()
	pressure.configure(at, label)
	pressure.changed.connect(func(active: bool) -> void:
		sfx.play("fan" if active else "switch")
		effects.burst(pressure.global_position, Color("a9f4dd") if active else Color("ef9569"), 10)
		_announce("HEAVY SWITCH %s\nFAN %s" % ["HELD" if active else "RELEASED", "ON" if active else "OFF"], 1.5)
	)
	world_root.add_child(pressure)

func _add_fan(at: Vector2, height: float) -> void:
	fan = FanScene.new()
	fan.configure(at, height)
	world_root.add_child(fan)

func _add_laser(at: Vector2, sensor_at: Vector2, start_orientation: int) -> void:
	laser = LaserScene.new()
	laser.configure(at, sensor_at, start_orientation)
	laser.orientation_changed.connect(func(_index: int) -> void:
		sfx.play("laser")
		effects.burst(laser.global_position, Color("ef9569"), 12)
		_announce("CAN FORCE ROTATED THE EMITTER\nWATCH THE BEAM PATH", 1.6)
	)
	laser.sensor_changed.connect(func(active: bool) -> void:
		if active:
			laser.armed = false
			_set_bridge(true)
			sfx.play("sensor")
			_announce("BEAM REACHED SENSOR\nBRIDGE EXTENDED", 2.0)
	)
	laser.impact_rejected.connect(func() -> void:
		unsafe_commits += 1
		_announce("LASER RIG HAS NO POWER\nHOLD THE SWITCH, RIDE THE FAN, LATCH POWER", 2.5)
	)
	world_root.add_child(laser)

func _update_pressure_logic() -> void:
	if pressure == null or not has_wedge:
		return
	var close := ram.global_position.distance_to(wedge_position) <= 25.0
	if close and not ram.wedged and wedge_release_grace <= 0.0:
		if level_index == 3 and not upper_latch:
			unsafe_commits += 1
			_fail_reversal("THE CAN IS COMMITTED TOO EARLY\nYOU NEEDED ITS BOUNCE TO SET PREP LATCH FIRST")
			return
		ram.wedge_at(wedge_position)
	if ram.wedged:
		pressure.set_pressed(true)
	elif not close:
		pressure.set_pressed(false)
	if fan != null:
		fan.set_active(pressure.pressed)

func _update_mastery_power() -> void:
	if level_index == 6 and laser != null:
		laser.armed = power_latch and not laser.sensor_active

func _update_goal_state() -> void:
	match level_index:
		0: goal_enabled = true
		1, 2: goal_enabled = pressure != null and pressure.pressed
		3: goal_enabled = upper_latch and pressure != null and pressure.pressed
		4: goal_enabled = laser != null and laser.sensor_active
		5: goal_enabled = laser != null and laser.sensor_active
		6: goal_enabled = power_latch and laser != null and laser.sensor_active
	if goal_enabled and player.global_position.distance_to(goal_position) <= 28.0:
		_complete_level()

func _complete_level() -> void:
	if mode != "play":
		return
	mode = "transition"
	player.active = false
	ram.set_charge_enabled(false)
	total_time += level_start_time
	sfx.play("win")
	effects.burst(goal_position, Color("fff1ac"), 24)
	_announce("LEVEL %d COMPLETE\nCAN STATE UNDERSTOOD" % (level_index + 1), 1.0)
	var ticket := failure_ticket
	await get_tree().create_timer(0.85).timeout
	if ticket != failure_ticket:
		return
	if level_index + 1 < LEVEL_COUNT:
		_show_level_card(level_index + 1)
	else:
		_finish_campaign()

func _finish_campaign() -> void:
	mode = "campaign_complete"
	var score := maxi(0, 100 - unsafe_commits * 12 - attempts * 5)
	var rank := "A" if score >= 90 else "B" if score >= 72 else "C" if score >= 50 else "D"
	result_label.text = "CAN CAMPAIGN COMPLETE — RANK %s\n7 SHORT SYSTEM LEVELS CLEARED\nPLAN QUALITY %d/100\nRewinds %d   Revealed assumptions %d\nTime %02d:%02d (not scored)\nR  NEW CAMPAIGN" % [rank, score, attempts, unsafe_commits, int(total_time / 60.0), int(total_time) % 60]
	result_panel.show()
	hint_back.hide()
	hint_label.hide()

func _fail_reversal(message: String) -> void:
	if mode != "play":
		return
	mode = "failure"
	player.active = false
	ram.set_charge_enabled(false)
	_announce(message, 2.2)
	var ticket := failure_ticket
	await get_tree().create_timer(1.25).timeout
	if ticket == failure_ticket:
		attempts += 1
		_build_level(level_index)

func _on_ram_struck(_player_speed: float, _ram_speed: float) -> void:
	wedge_release_grace = 0.38
	if pressure != null and ram.wedged == false:
		pressure.set_pressed(false)

func _on_ram_touched_player(source: Vector2) -> void:
	if mode != "play":
		return
	player.take_damage(source)
	if player.health > 0:
		ram.receive_stun(0.55)
		_announce("CAN CONTACT HURTS\nATTACK ONLY FROM ABOVE", 1.4)

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "failure"
	attempts += 1
	sfx.play("death")
	var ticket := failure_ticket
	await get_tree().create_timer(0.38).timeout
	if ticket == failure_ticket:
		_build_level(level_index)

func _set_bridge(active: bool) -> void:
	if not active or bridge_rect.size == Vector2.ZERO or is_instance_valid(bridge_body):
		return
	bridge_body = _add_block(bridge_rect, true)
	goal_enabled = true
	queue_redraw()

func _add_block(rect: Rect2, one_way: bool = false) -> StaticBody2D:
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
	world_root.add_child(body)
	return body

func _add_spikes(rect: Rect2) -> void:
	spike_rects.append(rect)
	var area := Area2D.new()
	area.position = rect.get_center()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and mode == "play":
			player.kill()
	)
	world_root.add_child(area)

func _player_spawn(index: int) -> Vector2:
	return [Vector2(42, 181), Vector2(42, 181), Vector2(42, 181), Vector2(42, 181), Vector2(42, 181), Vector2(42, 181), Vector2(42, 181)][index]

func _ram_spawn(index: int) -> Vector2:
	return [Vector2(118, 180), Vector2(82, 180), Vector2(86, 180), Vector2(88, 180), Vector2(96, 180), Vector2(150, 180), Vector2(150, 180)][index]

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var top_back := ColorRect.new()
	top_back.size = Vector2(384, 36)
	top_back.color = Color(0.025, 0.06, 0.08, 0.96)
	top_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_back)
	top_label = _label(Vector2(7, 3), Vector2(370, 30), 8, Color("f5dfa8"))
	canvas.add_child(top_label)
	hint_back = ColorRect.new()
	hint_back.position = Vector2(7, 160)
	hint_back.size = Vector2(370, 31)
	hint_back.color = Color(0.025, 0.06, 0.08, 0.92)
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hint_back)
	hint_label = _label(Vector2(11, 162), Vector2(362, 27), 8, Color("d7e5d5"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	canvas.add_child(hint_label)
	var controls := _label(Vector2(6, 199), Vector2(372, 12), 7, Color("b6c4bf"))
	controls.text = "A/D MOVE   SPACE JUMP   J/X AIR STRIKE   H HINT   R RESET"
	canvas.add_child(controls)
	announcement_label = _label(Vector2(63, 45), Vector2(258, 38), 9, Color("fff1ac"))
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	announcement_label.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.07, 0.09, 0.97), Color("a9f4dd")))
	canvas.add_child(announcement_label)
	announcement_label.hide()

	card_panel = ColorRect.new()
	card_panel.size = Vector2(384, 216)
	card_panel.color = Color(0.025, 0.06, 0.08, 1.0)
	canvas.add_child(card_panel)
	card_title = _label(Vector2(25, 33), Vector2(334, 28), 16, Color("fff1ac"))
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_panel.add_child(card_title)
	card_body = _label(Vector2(34, 72), Vector2(316, 118), 9, Color("d7e5d5"))
	card_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_panel.add_child(card_body)

	result_panel = ColorRect.new()
	result_panel.position = Vector2(35, 35)
	result_panel.size = Vector2(314, 146)
	result_panel.color = Color(0.025, 0.06, 0.08, 0.99)
	canvas.add_child(result_panel)
	result_label = _label(Vector2(8, 8), Vector2(298, 130), 9, Color("fff1ac"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)
	result_panel.hide()

func _update_hud() -> void:
	if top_label == null or player == null or ram == null:
		return
	var systems := ""
	if pressure != null:
		systems += "  SWITCH %s" % ("HELD" if pressure.pressed else "OPEN")
	if fan != null:
		systems += "  FAN %s" % ("ON" if fan.active else "OFF")
	if laser != null:
		systems += "  LASER %d  SENSOR %s" % [laser.orientation_index + 1, "ON" if laser.sensor_active else "OFF"]
	top_label.text = "%s   HP %d/3\nCAN %s%s" % [LEVEL_TITLES[level_index], player.health, _ram_readout(), systems]

func _ram_readout() -> String:
	if ram.wedged:
		return "WEDGED"
	var arrow := ">" if ram.facing > 0 else "<"
	match ram.state:
		"windup": return "LOCK%s" % arrow
		"coast": return "CHARGE%s" % arrow
		"stunned": return "STUNNED"
	return "READY"

func _current_hint() -> String:
	match level_index:
		0: return "RED ARROW = LOCKED CHARGE. JUMP ABOVE + J/X TO BOUNCE ONTO EXIT LEDGE."
		1: return "STAND BEYOND THE GOLD PLATE. BAIT CAN ONTO IT; HELD WEIGHT KEEPS FAN ON."
		2: return "A MOVING CAN IS DANGER. A WEDGED CAN IS A STABLE WEIGHT AND BOUNCE POINT."
		3:
			return "PREP LATCH FIRST: USE THE ROAMING CAN TO REACH IT. COMMIT TO SWITCH LAST." if not upper_latch else "PREP IS SET. NOW WEDGE CAN ON COMMIT LAST AND RIDE THE FAN."
		4: return "CAN IMPACT ROTATES THE EMITTER. PREDICT WHICH ANGLE REACHES SENSOR."
		5: return "FAN AND LASER ARE BOTH VALID FIRST MOVES. PRESERVE A ROUTE TO THE OTHER."
		6:
			return "SYSTEM POWER MUST BE LATCHED ABOVE BEFORE LASER FORCE MATTERS." if not power_latch else "POWER LATCHED. RELEASE CAN, ROTATE LASER, CROSS SENSOR BRIDGE."
	return "GUIDE CAN → TRIGGER WORLD → USE RESULT"

func _show_hint(duration: float = 4.5) -> void:
	hint_time = duration
	hint_label.text = _current_hint()
	hint_label.show()
	hint_back.show()

func _announce(message: String, duration: float = 1.6) -> void:
	announcement_label.text = message
	announcement_label.show()
	announcement_time = duration

func _update_transient_ui() -> void:
	announcement_label.visible = announcement_time > 0.0
	hint_label.visible = hint_time > 0.0
	hint_back.visible = hint_time > 0.0

func _label(at: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	PixelUI.style_label(label, ui_font, font_size, color)
	return label

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	return style

func _draw() -> void:
	draw_rect(Rect2(0, 0, 384, 216), Color("0d1822"))
	for x in range(24, 384, 72):
		draw_line(Vector2(x, 38), Vector2(x, FLOOR_Y), Color("203541"), 3.0)
		draw_circle(Vector2(x, 58), 12.0, Color("1a303c"))
	for rect in blocks:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("c3935f"))
	for rect in spike_rects:
		for x in range(int(rect.position.x), int(rect.end.x), 8):
			draw_colored_polygon(PackedVector2Array([Vector2(x, rect.position.y + 8), Vector2(x + 4, rect.position.y), Vector2(x + 8, rect.position.y + 8)]), Color("ef9569"))
	if has_wedge:
		draw_line(wedge_position + Vector2(-25, -17), wedge_position + Vector2(-15, 10), Color("a9f4dd"), 4.0)
		draw_line(wedge_position + Vector2(25, -17), wedge_position + Vector2(15, 10), Color("a9f4dd"), 4.0)
	if goal_position != Vector2.ZERO:
		var goal_color := Color("a9f4dd") if goal_enabled else Color("657b83")
		draw_rect(Rect2(goal_position - Vector2(11, 24), Vector2(22, 28)), Color("162230"))
		draw_rect(Rect2(goal_position - Vector2(8, 21), Vector2(16, 22)), goal_color)
		draw_string(ui_font, goal_position + Vector2(-22, -30), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 44, 7, goal_color)
	if mode == "play" and level_index == 3 and not upper_latch:
		draw_string(ui_font, Vector2(130, 70), "USE CAN HERE BEFORE SWITCH", HORIZONTAL_ALIGNMENT_CENTER, 120, 7, Color("fff1ac"))

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
