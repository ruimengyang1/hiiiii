extends SceneTree

var level: Node2D
var failures: Array[String] = []
var samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	level = load("res://scenes/yard_sandbox.tscn").instantiate()
	root.add_child(level)
	await frames(3)
	check(level.sandbox and level.mode == "play", "objective-free sandbox has no completion")
	check(get_nodes_in_group("foundry_can").size() == 1 and get_nodes_in_group("foundry_cart").size() == 1, "one persistent pair")
	var can_id: int = level.can.get_instance_id()
	var cart_id: int = level.cart.get_instance_id()
	# Observe one dense interaction, not an escape recipe: bounce off an actual
	# committed charge while it removes Cart's support and press shielding.
	level._freeze(true)
	level.cart.force_station(1)
	level.cart.suspended = false
	await frames(3)
	level.can.position = Vector2(145, 290)
	level.can.state = "windup"
	level.can.facing = 1
	level.can.state_time = 0.01
	level.can.contact_cooldown = 0
	level.player.reset_at(Vector2(190, 247))
	level.player.velocity.y = 100
	level.pause_frames = 0
	level._freeze(false)
	for i in 105:
		await process_frame
		if i > 12:
			Input.action_press("move_right")
		await physics_frame
		if i % 6 == 0:
			samples.append({"frame": i, "player": level.player.position, "can": level.can.position, "can_state": level.can.state, "cart": level.cart.position, "station": level.cart.station_index, "target": level.cart.target_station, "catwalk": level.mechanisms.catwalk.active, "shield": level.crusher.shielded})
	Input.action_release("move_right")
	check(level.signature_count > 0, "real player rebound during continued charge")
	check(level.cart.station_index == 2 and not level.crusher.shielded, "same charge relocates roof and exposes the press")
	check(samples.any(func(s: Dictionary) -> bool: return not s.catwalk), "forward push removes old catwalk support")
	check(samples.any(func(s: Dictionary) -> bool: return s.can_state == "stunned" and s.catwalk), "exposed press restores support with the grounded Can")
	check(level.stats.deaths == 0, "lost route gives recoverable geometry, not mandatory death")
	check(level.can.get_instance_id() == can_id and level.cart.get_instance_id() == cart_id, "chain never replaces or rehomes actors")
	var phase: float = level.crusher.clock
	await frames(100)
	check(level.crusher.clock > phase + 1.0, "factory keeps cycling without an objective")
	# Another property combination in the same geometry: exposed machine turns
	# the force source into weight, restoring the catwalk while Cart stays C.
	level.player.set_physics_process(false)
	level.player.position = Vector2(310, 209)
	level.can.position = Vector2(260, 290)
	level.can.state = "idle"
	level.can.cooldown = 1
	level.crusher.clock = 0.8
	await frames(5)
	check(level.can.state == "stunned" and level.mechanisms.catwalk.active, "actual press grounding restores route without moving Cart")
	var file := FileAccess.open("res://artifacts/third_redesign/sandbox_probe.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples": samples, "discoveries": level.discoveries, "failures": failures}, "\t"))
	file.close()
	for message in failures:
		printerr("THIRD SANDBOX FAIL: ", message)
	if failures.is_empty():
		print("THIRD SANDBOX PASS: objective-free simultaneous rebound / impact / roof relocation / shielding loss / catwalk loss / environmental restoration")
	level.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
