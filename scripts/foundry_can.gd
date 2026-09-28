extends "res://scripts/enemy.gd"

# Uses the original ram art, collision area, animations and signals. Its forks
# engage force receivers only during a committed charge; lowered forks fit
# underneath the transport's raised chassis during search.
const WINDUP := 0.78
const CHARGE_SPEED := 170.0
const CHARGE_TIME := 1.65
const STUN_TIME := 6.0
const SEARCH_SPEED := 48.0
const FORCE_THRESHOLD := 80.0

var suspended := false
var last_force_receiver: Node2D

func _ready() -> void:
	super._ready()
	add_to_group("foundry_heavy")
	add_to_group("foundry_can")
	z_index = 3

func _update_kinetic_ram(delta: float) -> void:
	if suspended:
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	state_time = maxf(0.0, state_time - delta)
	match state:
		"idle":
			velocity_x = 0.0
			cooldown = maxf(0.0, cooldown - delta)
			if target != null:
				var distance := target.global_position.x - global_position.x
				if cooldown <= 0.0 and charge_enabled and absf(distance) < 230.0 and absf(distance) > 23.0 and absf(target.global_position.y - global_position.y) < 58.0:
					facing = 1 if distance > 0.0 else -1
					state = "windup"
					state_time = WINDUP
					charge_locked.emit(facing)
				elif absf(distance) > 28.0:
					facing = 1 if distance > 0.0 else -1
					velocity_x = facing * SEARCH_SPEED
		"windup":
			velocity_x = 0.0
			if state_time <= 0.0:
				state = "charging"
				state_time = CHARGE_TIME
				velocity_x = facing * CHARGE_SPEED
		"charging":
			velocity_x = facing * CHARGE_SPEED
			if state_time <= 0.0:
				_begin_recovery()
		"stunned":
			velocity_x = 0.0
			if state_time <= 0.0:
				_begin_recovery()
		"recover":
			velocity_x = move_toward(velocity_x, 0.0, 180.0 * delta)
			if state_time <= 0.0:
				state = "idle"
				cooldown = 0.35
	_travel(delta)
	# An overlapping player must remain vulnerable after a state change, rather
	# than being protected forever because body_entered fired during the stun.
	if state in ["idle", "windup", "charging"]:
		for body in get_overlapping_bodies():
			_on_body_entered(body)

func _travel(delta: float) -> void:
	if is_zero_approx(velocity_x):
		return
	var next_x := clampf(position.x + velocity_x * delta, left_bound, right_bound)
	if state == "charging" and contact_cooldown <= 0.0:
		var nearest: Node2D
		var nearest_x := INF
		for candidate in get_tree().get_nodes_in_group("force_receivers"):
			if not candidate.has_method("receive_impact") or not candidate.has_method("impact_rect"):
				continue
			if candidate.has_method("impact_enabled") and not candidate.impact_enabled():
				continue
			var rect: Rect2 = candidate.impact_rect()
			if position.y + 10.0 < rect.position.y or position.y - 24.0 > rect.end.y:
				continue
			var edge: float = rect.position.x - 10.0 if velocity_x > 0.0 else rect.end.x + 10.0
			var ahead: float = (edge - position.x) * signf(velocity_x)
			if candidate.has_method("allows_search_passage") and candidate.allows_search_passage() and rect.grow(10.0).has_point(position):
				ahead = maxf(0.0, ahead)
			if ahead >= -4.0 and ahead <= absf(next_x - position.x) + 1.0 and ahead < nearest_x:
				nearest = candidate
				nearest_x = ahead
		if nearest != null:
			var hit_rect: Rect2 = nearest.impact_rect()
			if not (nearest.has_method("allows_search_passage") and nearest.allows_search_passage() and hit_rect.grow(10.0).has_point(position)):
				position.x = hit_rect.position.x - 10.0 if velocity_x > 0.0 else hit_rect.end.x + 10.0
			var incoming := velocity_x
			last_force_receiver = nearest
			velocity_x = float(nearest.receive_impact(incoming, self))
			contact_cooldown = 0.25
			state = "recover"
			state_time = 0.9
			carriage_hit.emit(incoming, velocity_x)
			return
	var exclusions: Array[RID] = []
	for cart in get_tree().get_nodes_in_group("foundry_cart"):
		exclusions.append(cart.get_rid())
	var sign_x := signf(velocity_x)
	var ray := PhysicsRayQueryParameters2D.create(position, Vector2(next_x + sign_x * 10.0, position.y), 1, exclusions)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		position.x = float(hit.position.x) - sign_x * 10.5
		if state == "charging":
			velocity_x *= -0.22
			_begin_recovery(false)
		else:
			velocity_x = 0.0
	else:
		position.x = next_x
		if next_x == left_bound or next_x == right_bound:
			_begin_recovery()

func _begin_recovery(stop: bool = true) -> void:
	state = "recover"
	state_time = 0.75
	if stop:
		velocity_x = 0.0

func receive_kinetic_strike(_player_velocity_x: float) -> bool:
	receive_stun(STUN_TIME)
	kinetic_struck.emit(0.0, 0.0)
	return true

func receive_stun(duration: float = STUN_TIME) -> void:
	# Continuous crusher contact must not refresh the timer each frame.
	if state == "stunned":
		return
	super.receive_stun(duration)

func plate_mass() -> float:
	return 2.0 if state == "stunned" else 0.0

func strike_surface_y() -> float:
	return global_position.y - 10.0

func weight_rect() -> Rect2:
	return Rect2(global_position - Vector2(10, 10), Vector2(20, 20))

func _on_body_entered(body: Node2D) -> void:
	if suspended or state in ["stunned", "recover"]:
		return
	super._on_body_entered(body)

func _draw() -> void:
	super._draw()
	if state != "stunned":
		# Active magnetic suspension carries its load; the de-energized shell
		# settles onto heavy plates. This is also the danger/safe state language.
		draw_line(Vector2(-8, 11), Vector2(8, 11), Color("75d6d2"), 1.0)
		draw_rect(Rect2(-6, 12, 3, 2), Color("397c82"))
		draw_rect(Rect2(3, 12, 3, 2), Color("397c82"))
	else:
		draw_rect(Rect2(-10, 8, 20, 3), Color("a9f4dd"))
	if state == "charging":
		draw_line(Vector2(facing * 8, -7), Vector2(facing * 16, -23), Color("ef9569"), 3.0)
		draw_line(Vector2(-facing * 16, 4), Vector2(-facing * 29, 4), Color("d7b06f"), 2.0)
	if state == "stunned":
		var t := clampf(state_time / STUN_TIME, 0.0, 1.0)
		draw_rect(Rect2(-12, -20, 24, 3), Color("172636"))
		draw_rect(Rect2(-12, -20, 24 * t, 3), Color("a9f4dd"))
