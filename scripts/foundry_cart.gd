extends "res://scripts/moving_platform.gd"

const TRAVEL_SPEED := 120.0
var stalled := false
var suspended := false
var pending_position := Vector2.INF

func _ready() -> void:
	super._ready()
	add_to_group("foundry_cart")
	add_to_group("foundry_heavy")
	add_to_group("force_receivers")
	z_index = 2
	# Keep the original moving-platform collision setup, but restrict it to the
	# raised chassis. The little maintenance bot fits below it with forks down.
	var collision := get_child(0) as CollisionShape2D
	(collision.shape as RectangleShape2D).size = Vector2(64, 10)
	collision.position.y = -11.0
	final_lock_enabled = true
	safety_enabled = true

func _physics_process(delta: float) -> void:
	if suspended:
		return
	if pending_position != Vector2.INF:
		position = pending_position
		pending_position = Vector2.INF
		velocity_x = 0.0
		queue_redraw()
		return
	advance_systemic(delta)
	queue_redraw()

func advance_systemic(delta: float) -> void:
	if target_station == station_index and is_equal_approx(position.x, stations[target_station]):
		velocity_x = 0.0
		stalled = false
		return
	var destination := float(stations[target_station])
	var direction := signf(destination - position.x)
	var next_x := move_toward(position.x, destination, TRAVEL_SPEED * delta)
	stalled = false
	for barrier in get_tree().get_nodes_in_group("transport_barriers"):
		if not barrier.blocks_transport():
			continue
		var obstacle: Rect2 = barrier.impact_rect()
		if not obstacle.intersects(Rect2(minf(position.x, next_x) - 32, position.y - 22, absf(next_x - position.x) + 64, 38)):
			continue
		if direction > 0.0 and position.x <= obstacle.position.x - 31.0:
			next_x = minf(next_x, obstacle.position.x - 32.0)
			stalled = true
		elif direction < 0.0 and position.x >= obstacle.end.x + 31.0:
			next_x = maxf(next_x, obstacle.end.x + 32.0)
			stalled = true
	velocity_x = (next_x - position.x) / maxf(delta, 0.0001)
	position.x = next_x
	if is_equal_approx(next_x, destination):
		station_index = target_station
		velocity_x = 0.0
		stalled = false
		npc_mood = "watching"
		station_changed.emit(station_index)
	elif stalled:
		npc_mood = "pointing"

func request_station_push(direction: int, force: float = 1.0) -> bool:
	if absf(force) < 80.0 or direction == 0:
		return false
	if target_station != station_index:
		if not stalled:
			return false
		if direction == signi(target_station - station_index):
			return false
		target_station = station_index
	else:
		var next := clampi(station_index + signi(direction), 0, stations.size() - 1)
		if next == station_index:
			return false
		target_station = next
	stalled = false
	npc_mood = "bracing"
	npc_reacted.emit(npc_mood)
	return true

func receive_impact(momentum: float, _source: Node2D = null) -> float:
	var accepted := request_station_push(int(signf(momentum)), absf(momentum))
	ram_impact.emit(momentum, float(signf(momentum)) * TRAVEL_SPEED if accepted else 0.0)
	return -momentum * 0.18

func impact_rect() -> Rect2:
	return Rect2(global_position - Vector2(32, 16), Vector2(64, 32))

func impact_enabled() -> bool:
	return true

func allows_search_passage() -> bool:
	return true

func accepts_strike_at(from: Vector2) -> bool:
	# A wide enemy stomp query must not hit the underside or an adjacent cart
	# corner while the player's feet are actually over a floor lever.
	return absf(from.x - global_position.x) < kinetic_half_width() + 6.0 and from.y <= global_position.y - 23.0

func strike_surface_y() -> float:
	return global_position.y - 16.0

func plate_mass() -> float:
	return 3.0

func weight_rect() -> Rect2:
	return Rect2(global_position + Vector2(-27, 6), Vector2(54, 10))

func snapshot() -> Dictionary:
	return {"x": position.x, "station": station_index, "target": target_station, "stalled": stalled, "mood": npc_mood}

func restore(data: Dictionary) -> void:
	position.x = data.x
	station_index = data.station
	target_station = data.target
	stalled = data.stalled
	npc_mood = data.mood
	velocity_x = 0.0
	pending_position = Vector2(data.x, position.y)

func force_station(index: int) -> void:
	super.force_station(index)
	pending_position = Vector2(stations[station_index], position.y)

func _draw() -> void:
	# Reuse the passenger and roof art, opening the lower chassis to make the
	# search/charge distinction physically legible.
	super._draw()
	draw_rect(Rect2(-28, -3, 56, 12), Color("172936"))
	draw_line(Vector2(-28, -6), Vector2(28, -6), Color("657b83"), 2.0)
	if stalled and pixel_font != null:
		draw_string(pixel_font, Vector2(-40, -48), "NO GATE POWER", HORIZONTAL_ALIGNMENT_CENTER, 80, 7, Color("ef9569"))
