extends CharacterBody2D

signal health_changed(value: int)
signal died
signal rebounded(at: Vector2)
signal jumped(at: Vector2)
signal dashed(at: Vector2)
signal dash_connected(at: Vector2)

const RUN_SPEED := 155.0
const GROUND_ACCEL := 1050.0
const AIR_ACCEL := 760.0
const GROUND_FRICTION := 1100.0
const AIR_FRICTION := 420.0
const GRAVITY := 650.0
const JUMP_SPEED := -235.0
const REBOUND_SPEED := -285.0
const COYOTE_TIME := 0.11
const JUMP_BUFFER := 0.12
const ATTACK_DURATION := 0.27
const DASH_SPEED := 460.0
const DASH_RANGE := 175.0
const DASH_DURATION := 0.48
const DASH_HIT_DISTANCE := 19.0
const DASH_CONE_ANGLE := deg_to_rad(35.0)

var health := 3
var active := true
var invulnerable_time := 0.0
var attack_time := 0.0
var coyote_time := 0.0
var jump_buffer_time := 0.0
var jump_cut_available := false
var hurt_lock := 0.0
var facing := 1
var run_clock := 0.0
var strike_shape := RectangleShape2D.new()
var dash_enabled := false
var dash_ready := false
var dash_time := 0.0
var dash_target: Area2D
var dash_entry_velocity := Vector2.ZERO
var dash_aim_direction := Vector2.ZERO
var dash_preview_target: Area2D
var air_acceleration := AIR_ACCEL

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 2.0
	platform_floor_layers = 1
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 18)
	body.shape = shape
	add_child(body)
	strike_shape.size = Vector2(12, 12)

func _physics_process(delta: float) -> void:
	if not active:
		return
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_lock = maxf(0.0, hurt_lock - delta)
	attack_time = maxf(0.0, attack_time - delta)
	jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
	if is_on_floor():
		coyote_time = COYOTE_TIME
		attack_time = 0.0
		jump_cut_available = false
		if dash_time <= 0.0:
			dash_ready = dash_enabled
	else:
		coyote_time = maxf(0.0, coyote_time - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER
	dash_aim_direction = Input.get_vector("move_left", "move_right", "aim_up", "aim_down").normalized()
	dash_preview_target = _nearest_dash_target(dash_aim_direction) if dash_enabled and dash_ready else null
	if dash_enabled and dash_ready and hurt_lock <= 0.0 and Input.is_action_just_pressed("dash"):
		var target := dash_preview_target
		if target != null:
			_begin_dash(target)
	if dash_time > 0.0:
		_update_dash(delta)
		move_and_slide()
		_check_dash_hit()
		queue_redraw()
		return
	var direction := Input.get_axis("move_left", "move_right")
	if hurt_lock <= 0.0:
		if absf(direction) > 0.05:
			velocity.x = move_toward(velocity.x, direction * RUN_SPEED, (GROUND_ACCEL if is_on_floor() else air_acceleration) * delta)
			facing = 1 if direction > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, (GROUND_FRICTION if is_on_floor() else AIR_FRICTION) * delta)
	if jump_buffer_time > 0.0 and coyote_time > 0.0 and attack_time <= 0.0:
		velocity.y = JUMP_SPEED
		jump_cut_available = true
		jump_buffer_time = 0.0
		coyote_time = 0.0
		jumped.emit(global_position)
	if Input.is_action_just_released("jump"):
		if jump_cut_available and velocity.y < -80.0 and attack_time <= 0.0:
			velocity.y *= 0.55
		jump_cut_available = false
	if Input.is_action_just_pressed("attack") and not is_on_floor() and attack_time <= 0.0 and hurt_lock <= 0.0:
		attack_time = ATTACK_DURATION
		jump_cut_available = false
		velocity.y = maxf(velocity.y, 170.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 390.0)
	move_and_slide()
	if attack_time > 0.0:
		_check_strike()
	if absf(velocity.x) > 10.0 and is_on_floor():
		run_clock += delta * 18.0
	queue_redraw()

func _nearest_dash_target(direction: Vector2) -> Area2D:
	if direction.is_zero_approx():
		return null
	var aim := direction.normalized()
	var nearest: Area2D
	var nearest_distance := DASH_RANGE * DASH_RANGE
	for node in get_tree().get_nodes_in_group("dash_targets"):
		var enemy := node as Area2D
		if enemy == null or enemy.get("alive") != true:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance >= nearest_distance:
			continue
		var target_direction := global_position.direction_to(enemy.global_position)
		if absf(aim.angle_to(target_direction)) > DASH_CONE_ANGLE:
			continue
		var ray := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1, [get_rid()])
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		nearest = enemy
		nearest_distance = distance
	return nearest

func _begin_dash(target: Area2D) -> void:
	dash_target = target
	dash_preview_target = null
	dash_entry_velocity = velocity
	dash_time = DASH_DURATION
	dash_ready = false
	attack_time = 0.0
	jump_buffer_time = 0.0
	jump_cut_available = false
	coyote_time = 0.0
	velocity = global_position.direction_to(target.global_position) * DASH_SPEED
	facing = 1 if velocity.x >= 0.0 else -1
	dashed.emit(global_position)

func _update_dash(delta: float) -> void:
	dash_time = maxf(0.0, dash_time - delta)
	if not is_instance_valid(dash_target) or dash_target.get("alive") != true:
		dash_time = 0.0
		dash_target = null
		return
	velocity = global_position.direction_to(dash_target.global_position) * DASH_SPEED

func _check_dash_hit() -> void:
	if dash_target == null or not is_instance_valid(dash_target):
		dash_target = null
		return
	if global_position.distance_to(dash_target.global_position) <= DASH_HIT_DISTANCE:
		var hit_position := dash_target.global_position
		if dash_target.receive_dash():
			velocity = (velocity + dash_entry_velocity * 0.35).limit_length(520.0)
			dash_ready = true
			dash_connected.emit(hit_position)
		dash_time = 0.0
		dash_target = null
	elif dash_time <= 0.0:
		dash_target = null

func _check_strike() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = strike_shape
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, 14.0))
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = true
	for result in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var target: Object = result["collider"]
		if target.has_method("accepts_strike_at") and not target.accepts_strike_at(global_position):
			continue
		var connected := false
		if target.has_method("receive_kinetic_strike"):
			connected = target.receive_kinetic_strike(velocity.x)
		if not connected and target.has_method("receive_strike"):
			connected = target.receive_strike()
		if connected:
			attack_time = 0.0
			var launch_speed: float = target.strike_rebound_speed() if target.has_method("strike_rebound_speed") else REBOUND_SPEED
			if launch_speed < 0.0:
				if target.has_method("strike_surface_y"):
					global_position.y = float(target.strike_surface_y()) - 9.0
				velocity.y = launch_speed
			jump_cut_available = false
			coyote_time = 0.0
			if launch_speed < 0.0:
				rebounded.emit(global_position + Vector2(0.0, 10.0))
			return

func take_damage(source: Vector2) -> void:
	if not active or invulnerable_time > 0.0:
		return
	health -= 1
	health_changed.emit(health)
	attack_time = 0.0
	dash_time = 0.0
	dash_target = null
	dash_preview_target = null
	jump_cut_available = false
	if health <= 0:
		kill()
		return
	invulnerable_time = 0.95
	hurt_lock = 0.16
	velocity = Vector2(95.0 if global_position.x >= source.x else -95.0, -145.0)
	queue_redraw()

func kill() -> void:
	if not active:
		return
	active = false
	velocity = Vector2.ZERO
	dash_time = 0.0
	dash_target = null
	dash_preview_target = null
	jump_cut_available = false
	died.emit()

func reset_at(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	health = 3
	active = true
	invulnerable_time = 0.7
	attack_time = 0.0
	dash_time = 0.0
	dash_target = null
	dash_ready = dash_enabled
	dash_aim_direction = Vector2.ZERO
	dash_preview_target = null
	coyote_time = 0.0
	jump_buffer_time = 0.0
	jump_cut_available = false
	hurt_lock = 0.0
	health_changed.emit(health)
	queue_redraw()

func is_striking() -> bool:
	return active and attack_time > 0.0 and velocity.y >= 0.0

func is_dashing() -> bool:
	return active and dash_time > 0.0

func _draw() -> void:
	if not active:
		return
	if invulnerable_time > 0.0 and int(invulnerable_time * 14.0) % 2 == 0:
		return
	var stride := 1 if absf(velocity.x) > 25.0 and is_on_floor() and sin(run_clock) > 0.0 else 0
	var scarf := Color("e45d54")
	var coat := Color("416d83")
	var brass := Color("edc27a")
	var ink := Color("162230")
	draw_rect(Rect2(-3 - facing * 3, -2, 5, 3), scarf)
	draw_rect(Rect2(-4, -1, 8, 7), coat)
	draw_rect(Rect2(-4, -9, 8, 7), brass)
	draw_rect(Rect2(-3, -8, 6, 4), ink)
	draw_rect(Rect2(1 if facing > 0 else -2, -7, 1, 1), Color("fff4d7"))
	draw_rect(Rect2(-4, 6, 3, 3 - stride), ink)
	draw_rect(Rect2(1, 6 + stride, 3, 3 - stride), ink)
	if attack_time > 0.0:
		draw_rect(Rect2(-2, 8, 4, 10), Color("fff1aa"))
		draw_rect(Rect2(-4, 14, 8, 3), Color("f29662"))
	if dash_time > 0.0:
		draw_line(Vector2(-facing * 5, 0), Vector2(-facing * 22, 0), Color("a9f4dd"), 3.0)
		draw_circle(Vector2(-facing * 11, 0), 2.0, Color("fff1ac"))
	elif dash_enabled and dash_ready:
		draw_rect(Rect2(-2, -13, 4, 2), Color("a9f4dd"))
		if not dash_aim_direction.is_zero_approx():
			var guide_color := Color("a9f4dd") if is_instance_valid(dash_preview_target) else Color("657b7d")
			draw_line(Vector2.ZERO, dash_aim_direction * 25.0, guide_color, 1.0)
			draw_line(Vector2.ZERO, dash_aim_direction.rotated(-DASH_CONE_ANGLE) * 18.0, Color(guide_color, 0.55), 1.0)
			draw_line(Vector2.ZERO, dash_aim_direction.rotated(DASH_CONE_ANGLE) * 18.0, Color(guide_color, 0.55), 1.0)
			if is_instance_valid(dash_preview_target):
				draw_arc(to_local(dash_preview_target.global_position), 12.0, 0.0, TAU, 16, Color("a9f4dd"), 1.0)
