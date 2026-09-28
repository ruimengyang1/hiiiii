extends "res://scripts/foundry_can.gd"

signal committed
signal environmental_stun(cause: String)
signal impact_feedback(at: Vector2, hard: bool)

const ANTICIPATION := 0.55
const RAM_SPEED := 230.0
const RAM_DURATION := 1.15
const STAGGER := 0.38
const GROUNDED_TIME := 3.4
const REUSE := 0.20

var squash := 0.0
var ground_body: StaticBody2D
var stun_cause := ""

func _physics_process(delta: float) -> void:
	if suspended:
		return
	super._physics_process(delta)

func _ready() -> void:
	super._ready()
	ground_body = StaticBody2D.new()
	ground_body.collision_layer = 0
	ground_body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 18)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = 1.0
	ground_body.add_child(collision)
	add_child(ground_body)

func _update_kinetic_ram(delta: float) -> void:
	if suspended:
		return
	squash = maxf(0.0, squash - delta)
	state_time = maxf(0.0, state_time - delta)
	var target := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		"idle":
			velocity_x = 0.0
			cooldown = maxf(0.0, cooldown - delta)
			if target != null:
				var dx := target.global_position.x - global_position.x
				if cooldown <= 0.0 and charge_enabled and absf(dx) > 24.0 and absf(dx) < 310.0 and absf(target.global_position.y - global_position.y) < 25.0:
					facing = 1 if dx > 0.0 else -1
					state = "windup"
					state_time = ANTICIPATION
					charge_locked.emit(facing)
				elif absf(dx) > 24.0:
					facing = 1 if dx > 0.0 else -1
					velocity_x = facing * 92.0
		"windup":
			velocity_x = 0.0
			if state_time <= 0.0:
				state = "charging"
				state_time = RAM_DURATION
				velocity_x = facing * RAM_SPEED
				committed.emit()
		"charging":
			velocity_x = facing * RAM_SPEED
			if state_time <= 0.0:
				_begin_recovery()
		"stunned", "stagger", "recover":
			velocity_x = 0.0
			if state_time <= 0.0:
				state = "idle"
				cooldown = 0.08
	ground_body.collision_layer = 1 if state == "stunned" else 0
	_travel(delta)
	if state in ["idle", "windup", "charging"]:
		for worker in get_overlapping_bodies():
			_on_body_entered(worker)

func _travel(delta: float) -> void:
	if is_zero_approx(velocity_x):
		return
	var next_x := clampf(position.x + velocity_x * delta, left_bound, right_bound)
	if state == "charging" and contact_cooldown <= 0.0:
		var nearest: Node2D
		var distance := INF
		for candidate in get_tree().get_nodes_in_group("force_receivers"):
			if not candidate.has_method("impact_rect") or not candidate.impact_enabled():
				continue
			var bounds: Rect2 = candidate.impact_rect()
			if position.y + 10.0 < bounds.position.y or position.y - 24.0 > bounds.end.y:
				continue
			var edge := bounds.position.x - 12.0 if velocity_x > 0.0 else bounds.end.x + 12.0
			var ahead := (edge - position.x) * signf(velocity_x)
			if candidate.has_method("allows_search_passage") and bounds.grow(12.0).has_point(position):
				ahead = maxf(0.0, ahead)
			if ahead >= -4.0 and ahead <= absf(next_x - position.x) + 1.0 and ahead < distance:
				nearest = candidate
				distance = ahead
		if nearest != null:
			var incoming := velocity_x
			last_force_receiver = nearest
			position.x += signf(incoming) * maxf(0.0, distance)
			nearest.receive_impact(incoming, self)
			contact_cooldown = 0.18
			impact_feedback.emit(position, false)
			# Fracture is an output of the same charge; breaking it does not stop
			# the robot. Cart contact has a quick recoil, never a long grounding.
			if nearest.is_in_group("foundry_cart"):
				_begin_recovery()
			carriage_hit.emit(incoming, 0.0)
			return
	var excluded: Array[RID] = [ground_body.get_rid()]
	for object in get_tree().get_nodes_in_group("foundry_cart"):
		excluded.append(object.get_rid())
	var direction := signf(velocity_x)
	var ray := PhysicsRayQueryParameters2D.create(position, Vector2(next_x + direction * 12.0, position.y), 1, excluded)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		position.x = float(hit.position.x) - direction * 12.5
		if state == "charging":
			receive_environmental_stun("hard impact")
		else:
			velocity_x = 0.0
	else:
		position.x = next_x
		if next_x == left_bound or next_x == right_bound:
			_begin_recovery()

func _begin_recovery(_stop: bool = true) -> void:
	state = "recover"
	state_time = REUSE
	velocity_x = 0.0

func receive_kinetic_strike(_player_speed: float) -> bool:
	squash = 0.18
	flash = 0.12
	# A committed charge keeps its direction, speed AND remaining duration.
	if state not in ["charging", "stunned"]:
		state = "stagger"
		state_time = STAGGER
		velocity_x = 0.0
	kinetic_struck.emit(0.0, velocity_x)
	return true

func receive_environmental_stun(cause: String = "crusher") -> void:
	if state == "stunned":
		return
	state = "stunned"
	state_time = GROUNDED_TIME
	velocity_x = 0.0
	flash = 0.16
	squash = 0.3
	stun_cause = cause
	ground_body.collision_layer = 1
	stunned.emit(GROUNDED_TIME)
	environmental_stun.emit(cause)
	impact_feedback.emit(position, true)

func receive_stun(_duration: float = GROUNDED_TIME) -> void:
	receive_environmental_stun("crusher")

func strike_rebound_speed() -> float:
	return -305.0

func accepts_strike_at(from: Vector2) -> bool:
	return from.y <= position.y - 13.0 and absf(from.x - position.x) <= 23.0

func _on_body_entered(worker: Node2D) -> void:
	if suspended or state in ["stunned", "recover", "stagger"]:
		return
	if worker.is_in_group("player") and worker.position.y < position.y - 10.0 and worker.velocity.y >= 0.0:
		return
	super._on_body_entered(worker)

func _draw() -> void:
	var safe := state == "stunned"
	var height := 14.0 if squash > 0.0 else 20.0
	var top := 10.0 - height
	draw_rect(Rect2(-11, top, 22, height), Color("162230"))
	draw_rect(Rect2(-9, top + 2, 18, height - 5), Color("a9f4dd") if safe else Color("658c94"))
	draw_rect(Rect2(-8, top - 2, 16, 3), Color("edc27a"))
	draw_rect(Rect2(-7, 6, 14, 3), Color("a9f4dd") if safe else Color("d4a65e"))
	draw_rect(Rect2(facing * 4 - 2, top + 5, 4, 3), Color("172636") if safe else Color("ff685c"))
	if safe:
		draw_rect(Rect2(-13, 10, 26, 3), Color("a9f4dd"))
		draw_rect(Rect2(-13, -20, 26 * state_time / GROUNDED_TIME, 3), Color("a9f4dd"))
		draw_line(Vector2(-4, -7), Vector2(4, 1), Color("172636"), 2)
		draw_line(Vector2(4, -7), Vector2(-4, 1), Color("172636"), 2)
	else:
		draw_line(Vector2(-8, 12), Vector2(8, 12), Color("75d6d2"), 2)
	if state == "windup":
		var tip := Vector2(facing * 65, -2)
		draw_line(Vector2(facing * 14, -2), tip, Color("ff685c"), 3)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-facing * 9, -6), tip + Vector2(-facing * 9, 6)]), Color("ffad66"))
		draw_rect(Rect2(-12, -22, 24 * (1.0 - state_time / ANTICIPATION), 3), Color("ffad66"))
	if state == "charging":
		draw_line(Vector2(facing * 9, -4), Vector2(facing * 18, -18), Color("ef9569"), 3)
		for i in 3:
			draw_line(Vector2(-facing * (15 + i * 8), -7 + i * 6), Vector2(-facing * (23 + i * 8), -7 + i * 6), Color("edc27a"), 2)
