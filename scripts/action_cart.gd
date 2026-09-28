extends "res://scripts/foundry_cart.gd"

func advance_systemic(delta: float) -> void:
	# A single 80-pixel move takes 0.4 seconds. No escort travel or hidden locks.
	if target_station == station_index:
		velocity_x = 0.0
		return
	var next_x := move_toward(position.x, stations[target_station], 200.0 * delta)
	velocity_x = (next_x - position.x) / delta
	position.x = next_x
	if is_equal_approx(position.x, stations[target_station]):
		station_index = target_station
		velocity_x = 0.0
		npc_mood = "watching"
		station_changed.emit(station_index)

func strike_rebound_speed() -> float:
	return -335.0

func _draw() -> void:
	# The transport carries a flywheel, not an escort objective. Reuse chassis,
	# wheel and roof language; impact recoil communicates its physical change.
	draw_rect(Rect2(-32, -16, 64, 14), Color("172636"))
	draw_rect(Rect2(-30, -14, 60, 7), Color("a67853"))
	draw_rect(Rect2(-28, -16, 56, 3), Color("e5b873"))
	draw_line(Vector2(-26, -4), Vector2(26, -4), Color("657b83"), 2)
	for x in [-24, 24]:
		draw_circle(Vector2(x, 11), 4, Color("162230"))
		draw_circle(Vector2(x, 11), 2, Color("d8b47b"))
	draw_circle(Vector2(5, -25), 9, Color("416d83"))
	draw_arc(Vector2(5, -25), 8, 0, TAU, 12, Color("9ac6c7"), 2)
	var angle := position.x * 0.08
	draw_line(Vector2(5, -25) - Vector2(cos(angle), sin(angle)) * 6, Vector2(5, -25) + Vector2(cos(angle), sin(angle)) * 6, Color("edc27a"), 2)
	if npc_mood == "bracing":
		draw_line(Vector2(-36, -12), Vector2(-42, -12), Color("fff1ac"), 2)
		draw_line(Vector2(36, -12), Vector2(42, -12), Color("fff1ac"), 2)
