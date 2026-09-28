extends SceneTree

const RamScript = preload("res://scripts/enemy.gd")
const CartScript = preload("res://scripts/moving_platform.gd")
const SwitchScript = preload("res://scripts/systemic_switch.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_direction_lock_and_strike()
	_test_cart_rules()
	await _test_switches_and_scene_state()
	if failures.is_empty():
		print("SYSTEMIC PASS: committed ram, deterministic cart, safety gates, switches, NPC, and rewind")
		quit(0)
	else:
		for failure in failures:
			printerr("SYSTEMIC FAIL: ", failure)
		quit(1)

func _test_direction_lock_and_strike() -> void:
	var ram = RamScript.new()
	ram.configure_systemic_ram(Vector2.ZERO, -100.0, 100.0)
	root.add_child(ram)
	ram.set_physics_process(false)
	ram.velocity_x = 150.0
	ram.receive_kinetic_strike(-150.0)
	_check(ram.velocity_x < 0.0, "opposite player momentum redirects the same persistent ram")
	ram.velocity_x = 0.0
	ram.facing = 1
	ram.state = "windup"
	ram.state_time = 0.01
	ram._update_kinetic_ram(0.02)
	_check(ram.state == "coast" and ram.velocity_x > 100.0, "windup commits to its previously locked direction")
	ram.receive_stun(0.8)
	_check(ram.state == "stunned" and is_zero_approx(ram.velocity_x), "shared hazards can stun the ram")
	ram.free()

func _test_cart_rules() -> void:
	var cart = CartScript.new()
	cart.configure_systemic(Vector2(100, 100), PackedFloat32Array([100.0, 200.0, 300.0, 400.0, 500.0]))
	cart.unsafe_station = 3
	_check(cart.request_station_push(1, 120.0), "ram force starts a deterministic one-stop move")
	_advance_cart(cart)
	_check(cart.station_index == 1 and is_equal_approx(cart.position.x, 200.0), "cart snaps to stop one")
	_check(cart.request_station_push(1, 120.0), "second ram impact advances the same cart")
	_advance_cart(cart)
	_check(cart.station_index == 2, "cart reaches the circuit stop")
	_check(not cart.request_station_push(1, 120.0), "danger bay rejects blind push-right strategy")
	_check(cart.station_index == 2 and cart.npc_mood == "alarm", "rejection preserves recoverable state and alarms the NPC")
	cart.set_safety_enabled(true)
	_check(cart.request_station_push(1, 120.0), "cut-off makes danger bay a valid future state")
	_advance_cart(cart)
	_check(not cart.request_station_push(1, 120.0), "final stop remains locked by a separate ram interaction")
	cart.set_final_lock_enabled(true)
	_check(cart.request_station_push(1, 120.0), "ram lock releases the final passenger move")
	_advance_cart(cart)
	_check(cart.station_index == 4, "NPC cart reaches destination stop")
	var first_x: float = cart.position.x
	cart.force_station(2)
	cart.request_station_push(-1, 120.0)
	_advance_cart(cart)
	_check(cart.station_index == 1 and cart.position.x < first_x, "the same general push rule works from either side")
	cart.free()

func _test_switches_and_scene_state() -> void:
	var strike_switch = SwitchScript.new()
	strike_switch.configure("strike", Vector2.ZERO, "TEST")
	_check(strike_switch.receive_strike() and strike_switch.active, "player strike activates a strike-property switch")
	var ram_switch = SwitchScript.new()
	ram_switch.configure("ram", Vector2.ZERO, "TEST")
	ram_switch.set_armed(false)
	ram_switch.receive_ram_impact(100.0)
	_check(not ram_switch.active, "ram switch visibly rejects impact until environment arms it")
	ram_switch.set_armed(true)
	var returned := ram_switch.receive_ram_impact(100.0)
	_check(ram_switch.active and returned < 0.0, "armed switch activates and returns ram momentum as another useful state")
	var passed_through := ram_switch.receive_ram_impact(-100.0)
	_check(is_equal_approx(passed_through, -100.0), "active ram lock becomes pass-through instead of a permanent bumper wall")
	strike_switch.free()
	ram_switch.free()

	var scene := load("res://scenes/kinetic_prototype.tscn") as PackedScene
	var level = scene.instantiate()
	root.add_child(level)
	await physics_frame
	await physics_frame
	_check(level.briefing_active and "RESCUE THE ENGINEER" in level.briefing_panel.get_child(0).text, "opening briefing states the rescue objective before play")
	_check("MISSION: DELIVER ENGINEER" in level.objective_label.text, "persistent HUD names the objective")
	level._begin_play()
	_check(level.ui_font.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "UI font disables smoothing at the pixel-art viewport scale")
	_check(not level.result_label.visible, "empty completion panel never obstructs active play")
	level.hint_time = 0.0
	level._update_ui()
	_check(not level.hint_label.visible and not level.hint_back.visible, "context hint dismisses instead of remaining stuck on screen")
	level._show_context_hint()
	_check(level.hint_label.visible and level.hint_back.visible, "current hint can be recalled on demand")
	level.player.invulnerable_time = 0.0
	level._on_ram_touched_player(level.ram.global_position)
	_check(level.player.active and level.player.health == 2 and level.ram.state == "stunned", "first contact is recoverable and pauses the threat for instruction")
	level.reset_encounter(true)
	_check(level.rams.size() == 1 and level.counter_ram == level.ram, "one central ram replaces redundant opposing enemies")
	level.ram.state = "windup"
	level.ram.facing = 1
	_check(level._ram_readout() == "LOCK>", "HUD exposes the ram's real-time locked direction")
	level.ram.state = "idle"
	level.carriage.force_station(2)
	level._on_cart_station_changed(2)
	_check(level.circuit_powered and not level.safety_enabled and level.ram.state == "stunned", "cart transition changes the circuit and grants a planning window")
	level._on_cart_push_rejected(3)
	_check(level.carriage.station_index == 2 and "DANGER BAY" in level.last_event, "premature push teaches the missing prerequisite")
	level._on_switch_activated("strike", level.safety_switch.position)
	_check(level.safety_enabled and level.carriage.safety_enabled, "upper cut-off changes future cart validity")
	level.carriage.force_station(3)
	level._on_cart_station_changed(3)
	level.final_switch.receive_ram_impact(-100.0)
	_check(level.final_lock_enabled and level.carriage.final_lock_enabled, "ram-only lock feeds the final cart rule")
	level.ram.position = level.final_switch.position
	level.ram.velocity_x = -100.0
	level.ram.state = "coast"
	level.ram.contact_cooldown = 0.0
	level.ram._check_ram_receivers()
	_check(is_equal_approx(level.ram.velocity_x, -100.0) and level.ram.state == "coast", "activated lock no longer intercepts or recovers a passing ram")
	level.carriage.force_station(4)
	level._on_cart_station_changed(4)
	_check(level.npc_arrived, "NPC arrival is explicit progression state")
	level.checkpoint_station = 3
	level.reset_encounter(false)
	_check(level.carriage.station_index == 3 and level.safety_enabled and not level.final_lock_enabled, "rewind restores a coherent nearby puzzle snapshot")
	level.mode = "complete"
	level.player.active = false
	level.ram.set_physics_process(false)
	level.carriage.set_physics_process(false)
	level.free()
	await process_frame

func _advance_cart(cart) -> void:
	for _step in 80:
		cart.advance_systemic(1.0 / 120.0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
