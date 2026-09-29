extends Node2D

const PlayerScene = preload("res://scripts/player.gd")
const CanScene = preload("res://scripts/enemy.gd")
const BoulderScene = preload("res://scripts/can_boulder.gd")
const PressureScene = preload("res://scripts/can_pressure_switch.gd")
const FanScene = preload("res://scripts/can_fan.gd")
const LaserScene = preload("res://scripts/can_laser_rig.gd")
const PlatformScene = preload("res://scripts/can_moving_platform.gd")
const EffectsScene = preload("res://scripts/effects.gd")
const SfxScene = preload("res://scripts/sfx.gd")
const PixelUI = preload("res://scripts/pixel_ui.gd")

const LEVEL_COUNT := 4
const FLOOR_Y := 190.0
const LEVEL_TITLES := ["1 — REDIRECT", "2 — WEIGHT", "3 — TIMING", "4 — COMBINE"]
const LEVEL_OPENERS := [
	"YOUR POSITION CHOOSES ITS LINE",
	"FORCE CHANGES WHERE WEIGHT ENDS",
	"SENSOR LOCKS BRIEFLY — BAIT THE CAN OUT",
	"PLAN THE STATE YOUR ACTION CREATES",
]

var world_root: Node2D
var player: CharacterBody2D
var can: Area2D
var boulder: AnimatableBody2D
var pressure: Node2D
var fan: Node2D
var laser: Node2D
var primary_platform: AnimatableBody2D
var cargo_platform: AnimatableBody2D
var target_a: AnimatableBody2D
var target_b: AnimatableBody2D
var effects: Node2D
var sfx: Node
var ui_font: Font

var blocks: Array[Rect2] = []
var level_index := 0
var mode := "start"
var goal_position := Vector2.ZERO
var exit_enabled := false
var exit_gate: StaticBody2D
var level_clock := 0.0
var total_clock := 0.0
var attempts := 0
var completion_ticket := 0
var announcement_time := 0.0
var opener_time := 0.0
var shake_time := 0.0
var rotator_has_can := false
var rotator_grace := 0.0
var l4_lift_delay := 0.0
var lift_carrying_can := false
var level_state: Dictionary = {}

var top_label: Label
var opener_label: Label
var announcement_label: Label
var card_panel: ColorRect
var card_title: Label
var card_body: Label
var result_panel: ColorRect
var result_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_font = PixelUI.make_font()
	_setup_inputs()
	sfx = SfxScene.new()
	add_child(sfx)
	_create_ui()
	_show_start()

func _physics_process(delta: float) -> void:
	_update_shake(delta)
	if mode == "start":
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
			_build_level(0)
		return
	if mode == "complete":
		if Input.is_action_just_pressed("restart"):
			total_clock = 0.0
			attempts = 0
			_build_level(0)
		return
	if mode != "play":
		return

	level_clock += delta
	announcement_time = maxf(0.0, announcement_time - delta)
	opener_time = maxf(0.0, opener_time - delta)
	rotator_grace = maxf(0.0, rotator_grace - delta)
	_update_ui_visibility()
	if Input.is_action_just_pressed("restart"):
		attempts += 1
		_build_level(level_index)
		return
	if player.global_position.y > 235.0:
		player.kill()
	if fan != null:
		fan.lift(player, delta)
	if pressure != null:
		pressure.refresh_weight()
	_update_rotator()
	match level_index:
		0: _update_level_1()
		1: _update_level_2()
		2: _update_level_3(delta)
		3: _update_level_4(delta)
	_update_laser_hazard()
	_update_exit()
	_update_hud()
	queue_redraw()

func _show_start() -> void:
	mode = "start"
	card_title.text = "CAN / USEFUL DANGER"
	card_body.text = "IT SEES YOU.\nIT LOCKS A LINE.\nMAKE THAT LINE USEFUL.\n\nSPACE / J / GAMEPAD A  —  BEGIN"
	card_panel.show()
	result_panel.hide()

func _build_level(index: int) -> void:
	completion_ticket += 1
	level_index = index
	if is_instance_valid(world_root):
		world_root.free()
	world_root = Node2D.new()
	world_root.name = "Level%d" % (index + 1)
	add_child(world_root)
	move_child(world_root, 0)
	blocks.clear()
	boulder = null
	pressure = null
	fan = null
	laser = null
	primary_platform = null
	cargo_platform = null
	target_a = null
	target_b = null
	exit_gate = null
	goal_position = Vector2.ZERO
	exit_enabled = false
	level_clock = 0.0
	rotator_has_can = false
	rotator_grace = 0.0
	l4_lift_delay = 0.0
	lift_carrying_can = false
	level_state = {}
	mode = "play"
	card_panel.hide()
	result_panel.hide()
	effects = EffectsScene.new()
	world_root.add_child(effects)

	match index:
		0: _build_level_1()
		1: _build_level_2()
		2: _build_level_3()
		3: _build_level_4()

	_create_actors(_player_spawn(index), _can_spawn(index), 210.0 if index < 2 else 126.0)
	opener_label.text = LEVEL_OPENERS[index]
	opener_time = 2.4
	_update_hud()
	_update_ui_visibility()
	queue_redraw()

func _create_actors(player_at: Vector2, can_at: Vector2, trigger: float) -> void:
	can = CanScene.new() as Area2D
	can.name = "Can"
	can.configure_systemic_ram(can_at, 24.0, 360.0)
	can.trigger_range = trigger
	can.charge_impulse = 150.0
	can.touched_player.connect(_on_can_touched_player)
	can.charge_locked.connect(func(direction: int) -> void:
		sfx.play("lock")
		_announce("LOCK %s" % ("RIGHT" if direction > 0 else "LEFT"), 0.55)
	)
	can.charge_committed.connect(func(_direction: int) -> void:
		sfx.play("charge")
		shake_time = maxf(shake_time, 0.08)
	)
	world_root.add_child(can)

	player = PlayerScene.new()
	player.position = player_at
	player.air_acceleration = 900.0
	player.died.connect(_on_player_died)
	player.rebounded.connect(func(at: Vector2) -> void:
		effects.burst(at, Color("fff1ac"), 12)
		sfx.play("bounce")
		shake_time = 0.09
	)
	player.jumped.connect(func(_at: Vector2) -> void: sfx.play("jump"))
	world_root.add_child(player)

func _build_level_1() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	target_a = _add_platform(Vector2(168, 174), Vector2(216, 174), Vector2(34, 32), "FORCE", true)
	target_b = _add_platform(Vector2(274, 174), Vector2(320, 174), Vector2(34, 32), "AGAIN", true)
	_create_exit(Vector2(362, 166))
	level_state = {"a": false, "b": false}

func _build_level_2() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(315, 82, 69, 108))
	_add_boulder(Vector2(160, 176), 132.0, 238.0)
	_add_pressure(Vector2(222, 184), "WEIGHT")
	_add_fan(Vector2(278, 184), 128.0)
	cargo_platform = _add_platform(Vector2(344, 116), Vector2(206, 116), Vector2(42, 12), "CARGO")
	cargo_platform.speed = 155.0
	_create_exit(Vector2(356, 58))
	level_state = {"cargo_passed": false}

func _build_level_3() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(334, 82, 50, 108))
	_add_laser(Vector2(180, 170), Vector2(300, 72), deg_to_rad(-110.0))
	laser.sensor_lock_duration = 1.0
	primary_platform = _add_platform(Vector2(303, 183), Vector2(303, 112), Vector2(54, 10), "SENSOR LIFT")
	primary_platform.speed = 145.0
	_create_exit(Vector2(360, 58))

func _build_level_4() -> void:
	_add_block(Rect2(0, FLOOR_Y, 384, 26))
	_add_block(Rect2(150, 112, 96, 10), true)
	_add_block(Rect2(145, 80, 105, 10), true)
	_add_block(Rect2(255, 135, 28, 9), true)
	_add_block(Rect2(326, 130, 58, 9), true)
	_add_block(Rect2(330, 70, 54, 10), true)
	_add_boulder(Vector2(160, 176), 105.0, 180.0)
	_add_pressure(Vector2(120, 184), "WEIGHT")
	_add_fan(Vector2(190, 184), 102.0)
	_add_laser(Vector2(294, 170), Vector2(294, 70), PI)
	primary_platform = _add_platform(Vector2(294, 183), Vector2(294, 111), Vector2(52, 10), "FINAL LIFT")
	primary_platform.speed = 155.0
	primary_platform.moved.connect(_on_final_lift_moved)
	primary_platform.arrived.connect(_on_final_lift_arrived)
	_create_exit(Vector2(360, 48))

func _add_boulder(at: Vector2, left: float, right: float) -> void:
	boulder = BoulderScene.new()
	boulder.configure(at, left, right)
	boulder.impacted.connect(func(at_hit: Vector2, speed: float) -> void:
		effects.burst(at_hit, Color("e5b873"), 18)
		sfx.play("boulder")
		shake_time = 0.18
		_impact_pause(speed)
	)
	boulder.settled.connect(func(at_rest: Vector2) -> void:
		effects.burst(at_rest + Vector2(0, 12), Color("9b8060"), 6)
	)
	world_root.add_child(boulder)

func _add_pressure(at: Vector2, label: String) -> void:
	pressure = PressureScene.new()
	pressure.configure(at, label)
	pressure.changed.connect(_on_pressure_changed)
	world_root.add_child(pressure)

func _add_fan(at: Vector2, height: float) -> void:
	fan = FanScene.new()
	fan.configure(at, height)
	world_root.add_child(fan)

func _add_laser(at: Vector2, sensor_at: Vector2, start_angle: float) -> void:
	laser = LaserScene.new()
	laser.configure(at, sensor_at, start_angle)
	laser.sensor_changed.connect(_on_sensor_changed)
	laser.sensor_lock_started.connect(_on_sensor_lock_started)
	laser.sensor_lock_finished.connect(_on_sensor_lock_finished)
	laser.rotator_changed.connect(func(occupied: bool) -> void:
		sfx.play("rotator")
		_announce("ROTATING" if occupied else "ANGLE HELD", 0.65)
	)
	world_root.add_child(laser)

func _add_platform(at: Vector2, target: Vector2, size: Vector2, label: String, impact_driven: bool = false) -> AnimatableBody2D:
	var platform = PlatformScene.new()
	platform.configure(at, target, size, label)
	platform.set_impact_driven(impact_driven)
	world_root.add_child(platform)
	return platform

func _create_exit(at: Vector2) -> void:
	goal_position = at
	exit_gate = StaticBody2D.new()
	exit_gate.position = at
	exit_gate.collision_layer = 1
	exit_gate.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 40)
	collision.shape = shape
	exit_gate.add_child(collision)
	world_root.add_child(exit_gate)

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

func _update_level_1() -> void:
	if target_a.active and not level_state.a:
		level_state.a = true
		_mechanism_impact(target_a.global_position)
	if target_b.active and not level_state.b:
		level_state.b = true
		_mechanism_impact(target_b.global_position)
	_set_exit_enabled(bool(level_state.a) and bool(level_state.b))

func _update_level_2() -> void:
	if cargo_platform.active and not cargo_platform.is_moving():
		level_state.cargo_passed = true
	if cargo_platform.is_moving() and cargo_platform.current_rect().grow(3.0).has_point(player.global_position):
		_fail_current("FAN POWER MOVES THE CARGO TOO")
	_set_exit_enabled(pressure.pressed)

func _update_level_3(_delta: float) -> void:
	_set_exit_enabled(laser.sensor_active and not laser.rotator_occupied and primary_platform.position.distance_to(primary_platform.active_position) < 2.0)

func _update_level_4(delta: float) -> void:
	if l4_lift_delay > 0.0:
		l4_lift_delay = maxf(0.0, l4_lift_delay - delta)
		if l4_lift_delay <= 0.0 and laser.sensor_active:
			lift_carrying_can = can.global_position.distance_to(primary_platform.global_position + Vector2(0, -13)) < 34.0
			if lift_carrying_can:
				can.hold_at(can.global_position, 0.22)
				_announce("THE LIFT MOVES THE CAN TOO", 1.15)
			primary_platform.set_active(true)
	_set_exit_enabled(laser.sensor_active and primary_platform.position.distance_to(primary_platform.active_position) < 2.0)

func _update_rotator() -> void:
	if laser == null or can == null:
		return
	var slot := Vector2(laser.global_position.x, FLOOR_Y - 10.0)
	var close := can.global_position.distance_to(slot) <= 22.0
	if not rotator_has_can and rotator_grace <= 0.0 and close and can.state in ["coast", "recover", "idle", "held"]:
		can.hold_at(slot, 0.62)
		rotator_has_can = true
		close = true
	if rotator_has_can and not close:
		rotator_has_can = false
		rotator_grace = 0.35
	laser.set_rotator_occupied(rotator_has_can and close)

func _update_laser_hazard() -> void:
	if level_index != 3 or laser == null or player.invulnerable_time > 0.0:
		return
	var direction: Vector2 = laser.beam_direction()
	var relative: Vector2 = player.global_position - laser.global_position
	var along: float = relative.dot(direction)
	var perpendicular: float = absf(relative.cross(direction))
	if along > 18.0 and along < laser.beam_end.length() and perpendicular < 4.5:
		player.take_damage(laser.global_position)
		sfx.play("hit")
		effects.burst(player.global_position, Color("ff665b"), 10)

func _on_pressure_changed(active: bool) -> void:
	if fan != null:
		fan.set_active(active)
	if level_index == 1 and cargo_platform != null:
		cargo_platform.set_active(active)
	sfx.play("fan" if active else "switch")
	effects.burst(pressure.global_position, Color("a9f4dd") if active else Color("ef9569"), 12)
	_announce("WEIGHT → FAN + CARGO" if active and level_index == 1 else "WEIGHT → FAN" if active else "WEIGHT RELEASED", 0.9)

func _on_sensor_changed(active: bool) -> void:
	sfx.play("sensor" if active else "laser")
	if active:
		effects.burst(laser.sensor_position, Color("a9f4dd"), 16)
	if level_index == 2 and primary_platform != null:
		primary_platform.set_active(active)
	elif level_index == 3 and primary_platform != null:
		if active:
			l4_lift_delay = 0.22
		else:
			l4_lift_delay = 0.0
			if not lift_carrying_can:
				primary_platform.set_active(false)

func _on_sensor_lock_started(duration: float) -> void:
	if level_index == 2:
		sfx.play("sensor")
		_announce("SENSOR LOCK %.1fs — BAIT CAN NOW" % duration, duration)

func _on_sensor_lock_finished() -> void:
	if level_index == 2 and laser != null and laser.rotator_occupied:
		_announce("LOCK RELEASED — LASER MOVING", 0.75)

func _on_final_lift_moved(delta_position: Vector2) -> void:
	if lift_carrying_can and is_instance_valid(can):
		can.global_position += delta_position

func _on_final_lift_arrived(active: bool) -> void:
	if active:
		lift_carrying_can = false
		sfx.play("platform")

func _mechanism_impact(at: Vector2) -> void:
	effects.burst(at, Color("ef9569"), 15)
	sfx.play("impact")
	shake_time = 0.14
	_impact_pause(130.0)

func _impact_pause(_speed: float) -> void:
	if mode != "play":
		return
	player.set_physics_process(false)
	can.set_physics_process(false)
	var ticket := completion_ticket
	await get_tree().create_timer(0.035, true, false, true).timeout
	if ticket == completion_ticket and mode == "play":
		player.set_physics_process(true)
		can.set_physics_process(true)

func _update_exit() -> void:
	if exit_enabled and player.global_position.distance_to(goal_position) <= 25.0:
		_complete_level()

func _set_exit_enabled(value: bool) -> void:
	if exit_enabled == value:
		return
	exit_enabled = value
	if is_instance_valid(exit_gate):
		exit_gate.collision_layer = 0 if value else 1
	if value:
		sfx.play("checkpoint")
		_announce("ROUTE OPEN", 0.8)

func _complete_level() -> void:
	if mode != "play":
		return
	mode = "transition"
	player.active = false
	can.set_charge_enabled(false)
	total_clock += level_clock
	sfx.play("win")
	effects.burst(goal_position, Color("fff1ac"), 24)
	_announce("%s  CLEAR" % LEVEL_TITLES[level_index], 0.75)
	var ticket := completion_ticket
	await get_tree().create_timer(0.78).timeout
	if ticket != completion_ticket:
		return
	if level_index + 1 < LEVEL_COUNT:
		_build_level(level_index + 1)
	else:
		_finish_demo()

func _finish_demo() -> void:
	mode = "complete"
	result_label.text = "I UNDERSTAND THIS MACHINE NOW.\n\n4 LEVELS COMPLETE\nTime %02d:%02d   Restarts %d\n\nR  PLAY AGAIN" % [int(total_clock / 60.0), int(total_clock) % 60, attempts]
	result_panel.show()

func _fail_current(message: String) -> void:
	if mode != "play":
		return
	mode = "failure"
	player.active = false
	can.set_charge_enabled(false)
	_announce(message, 0.7)
	var ticket := completion_ticket
	await get_tree().create_timer(0.62).timeout
	if ticket == completion_ticket:
		attempts += 1
		_build_level(level_index)

func _on_player_died() -> void:
	if mode != "play":
		return
	mode = "failure"
	attempts += 1
	sfx.play("death")
	var ticket := completion_ticket
	await get_tree().create_timer(0.42).timeout
	if ticket == completion_ticket:
		_build_level(level_index)

func _on_can_touched_player(source: Vector2) -> void:
	if mode != "play":
		return
	player.take_damage(source)
	sfx.play("hit")
	shake_time = 0.12
	if player.health > 0:
		can.receive_stun(0.32)

func _player_spawn(index: int) -> Vector2:
	return [Vector2(42, 181), Vector2(42, 181), Vector2(42, 181), Vector2(42, 181)][index]

func _can_spawn(index: int) -> Vector2:
	return [Vector2(92, 180), Vector2(88, 180), Vector2(88, 180), Vector2(238, 180)][index]

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var top_back := ColorRect.new()
	top_back.size = Vector2(384, 27)
	top_back.color = Color(0.025, 0.06, 0.08, 0.94)
	top_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_back)
	top_label = _label(Vector2(7, 2), Vector2(370, 22), 10, Color("f5dfa8"))
	canvas.add_child(top_label)
	opener_label = _label(Vector2(35, 31), Vector2(314, 20), 9, Color("d7e5d5"))
	opener_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opener_label.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.07, 0.09, 0.88), Color("657b83")))
	canvas.add_child(opener_label)
	announcement_label = _label(Vector2(54, 52), Vector2(276, 24), 10, Color("fff1ac"))
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	announcement_label.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.07, 0.09, 0.95), Color("a9f4dd")))
	canvas.add_child(announcement_label)
	var controls := _label(Vector2(7, 199), Vector2(370, 15), 8, Color("b6c4bf"))
	controls.text = "A/D MOVE   SPACE JUMP   J/X AIR STRIKE   R RESTART"
	canvas.add_child(controls)

	card_panel = ColorRect.new()
	card_panel.size = Vector2(384, 216)
	card_panel.color = Color(0.025, 0.06, 0.08, 1.0)
	canvas.add_child(card_panel)
	card_title = _label(Vector2(24, 42), Vector2(336, 28), 16, Color("fff1ac"))
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_panel.add_child(card_title)
	card_body = _label(Vector2(38, 75), Vector2(308, 104), 10, Color("d7e5d5"))
	card_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_panel.add_child(card_body)

	result_panel = ColorRect.new()
	result_panel.position = Vector2(40, 42)
	result_panel.size = Vector2(304, 132)
	result_panel.color = Color(0.025, 0.06, 0.08, 0.98)
	canvas.add_child(result_panel)
	result_label = _label(Vector2(8, 8), Vector2(288, 116), 11, Color("fff1ac"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)
	result_panel.hide()

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	top_label.text = "%s     HP %d/3" % [LEVEL_TITLES[level_index], player.health]

func _announce(message: String, duration: float = 0.7) -> void:
	announcement_label.text = message
	announcement_time = duration
	_update_ui_visibility()

func _update_ui_visibility() -> void:
	opener_label.visible = mode == "play" and opener_time > 0.0
	announcement_label.visible = announcement_time > 0.0

func _update_shake(delta: float) -> void:
	shake_time = maxf(0.0, shake_time - delta)
	if is_instance_valid(world_root):
		world_root.position = Vector2(sin(shake_time * 310.0), cos(shake_time * 270.0)) * (2.0 if shake_time > 0.0 else 0.0)

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
		draw_line(Vector2(x, 28), Vector2(x, FLOOR_Y), Color("203541"), 3.0)
		draw_circle(Vector2(x, 48), 11.0, Color("1a303c"))
	for rect in blocks:
		draw_rect(rect, Color("283b47"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("c3935f"))
	_draw_connections()
	if goal_position != Vector2.ZERO:
		var goal_color := Color("a9f4dd") if exit_enabled else Color("6b7478")
		draw_rect(Rect2(goal_position - Vector2(11, 22), Vector2(22, 44)), Color("162230"))
		draw_rect(Rect2(goal_position - Vector2(8, 19), Vector2(16, 38)), goal_color)
		draw_circle(goal_position + Vector2(4, 0), 2.0, Color("fff1ac"))
		draw_string(ui_font, goal_position + Vector2(-25, -28), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 50, 8, goal_color)

func _draw_connections() -> void:
	if pressure != null and fan != null:
		var color := Color("a9f4dd") if pressure.pressed else Color("53666b")
		draw_line(pressure.global_position + Vector2(0, 7), Vector2(fan.global_position.x, pressure.global_position.y + 7), color, 2.0)
		draw_line(Vector2(fan.global_position.x, pressure.global_position.y + 7), fan.global_position, color, 2.0)
		if cargo_platform != null:
			draw_line(pressure.global_position + Vector2(0, 9), Vector2(cargo_platform.global_position.x, pressure.global_position.y + 9), color, 1.0)
	if laser != null and primary_platform != null:
		var color := Color("a9f4dd") if laser.sensor_active else Color("53666b")
		draw_line(laser.sensor_position, Vector2(primary_platform.global_position.x, laser.sensor_position.y), color, 2.0)
		draw_line(Vector2(primary_platform.global_position.x, laser.sensor_position.y), primary_platform.global_position, color, 2.0)
	if level_index == 0 and target_a != null and target_b != null:
		var color := Color("a9f4dd") if exit_enabled else Color("53666b")
		draw_line(target_a.global_position, Vector2(target_a.global_position.x, 145), color, 1.0)
		draw_line(Vector2(target_a.global_position.x, 145), Vector2(goal_position.x, 145), color, 1.0)
		draw_line(target_b.global_position, Vector2(target_b.global_position.x, 145), color, 1.0)

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
