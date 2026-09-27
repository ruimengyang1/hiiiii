extends Area2D

signal touched_player(source: Vector2)
signal defeated(at: Vector2)
signal kinetic_struck(player_speed: float, ram_speed: float)
signal carriage_hit(ram_speed: float, carriage_speed: float)
signal wall_rebounded(side: int, incoming_speed: float, outgoing_speed: float)
signal charge_locked(direction: int)
signal stunned(duration: float)

const KINETIC_STRIKE_RAM_RETENTION := 0.40
const KINETIC_PLAYER_TRANSFER := 1.10
const KINETIC_MAX_SPEED := 260.0
const KINETIC_CHARGE_IMPULSE := 150.0
const KINETIC_COAST_FRICTION := 18.0
const KINETIC_IDLE_FRICTION := 85.0
const KINETIC_WINDUP := 0.52
const KINETIC_TRIGGER_RANGE := 95.0
const KINETIC_WALL_RESTITUTION := 0.48
const KINETIC_CONTACT_DISTANCE := 42.0

var kind := "walker"
var left_bound := 0.0
var right_bound := 0.0
var home := Vector2.ZERO
var facing := 1
var health := 1
var alive := true
var clock := 0.0
var flash := 0.0
var state := "patrol"
var state_time := 0.0
var cooldown := 0.3
var kinetic_mode := false
var velocity_x := 0.0
var spawn_position := Vector2.ZERO
var contact_cooldown := 0.0
var systemic_mode := false
var charge_enabled := true
var trigger_range := KINETIC_TRIGGER_RANGE
var charge_impulse := KINETIC_CHARGE_IMPULSE

func configure(enemy_kind: String, at: Vector2, patrol_left: float, patrol_right: float) -> void:
	kind = enemy_kind
	position = at
	home = at
	left_bound = patrol_left
	right_bound = patrol_right
	health = 2 if kind == "sentry" else 1
	spawn_position = at

func configure_kinetic_ram(at: Vector2, movement_left: float, movement_right: float) -> void:
	kinetic_mode = true
	kind = "kinetic_ram"
	position = at
	home = at
	spawn_position = at
	left_bound = movement_left
	right_bound = movement_right
	facing = 1
	state = "idle"
	state_time = 0.3
	cooldown = 0.3
	velocity_x = 0.0
	health = 1

func configure_systemic_ram(at: Vector2, movement_left: float, movement_right: float) -> void:
	configure_kinetic_ram(at, movement_left, movement_right)
	systemic_mode = true
	trigger_range = 175.0
	charge_impulse = 138.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if not kinetic_mode:
		add_to_group("dash_targets")
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	match kind:
		"drone", "relay": shape.size = Vector2(18, 12)
		"sentry", "kinetic_ram": shape.size = Vector2(20, 20)
		_: shape.size = Vector2(16, 13)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	clock += delta
	flash = maxf(0.0, flash - delta)
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	match kind:
		"walker":
			position.x += facing * 33.0 * delta
			if position.x >= right_bound:
				position.x = right_bound
				facing = -1
			elif position.x <= left_bound:
				position.x = left_bound
				facing = 1
		"drone":
			position.x = home.x + sin(clock * 1.7) * (right_bound - left_bound) * 0.5
			position.y = home.y + sin(clock * 2.4) * 6.0
		"relay":
			position.y = home.y + sin(clock * 2.4) * 4.0
		"sentry":
			_update_sentry(delta)
		"kinetic_ram":
			_update_kinetic_ram(delta)
	queue_redraw()

func _update_kinetic_ram(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		"idle":
			velocity_x = move_toward(velocity_x, 0.0, KINETIC_IDLE_FRICTION * delta)
			cooldown = maxf(0.0, cooldown - delta)
			if charge_enabled and player != null and cooldown <= 0.0 and absf(player.global_position.x - global_position.x) <= trigger_range:
				facing = 1 if player.global_position.x > global_position.x else -1
				state = "windup"
				state_time = KINETIC_WINDUP
				charge_locked.emit(facing)
		"windup":
			velocity_x = move_toward(velocity_x, 0.0, KINETIC_IDLE_FRICTION * delta)
			state_time = maxf(0.0, state_time - delta)
			if state_time <= 0.0:
				velocity_x = clampf(velocity_x + facing * charge_impulse, -KINETIC_MAX_SPEED, KINETIC_MAX_SPEED)
				state = "coast"
		"coast":
			velocity_x = move_toward(velocity_x, 0.0, KINETIC_COAST_FRICTION * delta)
			if absf(velocity_x) < 8.0:
				state = "recover"
				state_time = 0.35
		"recover":
			velocity_x = move_toward(velocity_x, 0.0, KINETIC_IDLE_FRICTION * delta)
			state_time = maxf(0.0, state_time - delta)
			if state_time <= 0.0:
				state = "idle"
				cooldown = 0.2
		"stunned":
			velocity_x = 0.0
			state_time = maxf(0.0, state_time - delta)
			if state_time <= 0.0:
				state = "recover"
				state_time = 0.28
	position.x += velocity_x * delta
	if position.x < left_bound:
		var incoming_left := velocity_x
		position.x = left_bound
		velocity_x = absf(velocity_x) * KINETIC_WALL_RESTITUTION
		state = "recover"
		state_time = 0.3
		wall_rebounded.emit(-1, incoming_left, velocity_x)
	elif position.x > right_bound:
		var incoming_right := velocity_x
		position.x = right_bound
		velocity_x = -absf(velocity_x) * KINETIC_WALL_RESTITUTION
		state = "recover"
		state_time = 0.3
		wall_rebounded.emit(1, incoming_right, velocity_x)
	_check_kinetic_carriage_contact()
	_check_ram_receivers()

func _check_ram_receivers() -> void:
	if not systemic_mode or contact_cooldown > 0.0 or absf(velocity_x) < 25.0:
		return
	for node in get_tree().get_nodes_in_group("ram_receivers"):
		var receiver := node as Node2D
		if receiver == null or not receiver.has_method("receive_ram_impact"):
			continue
		if global_position.distance_to(receiver.global_position) > 27.0:
			continue
		var incoming := velocity_x
		var result = receiver.call("receive_ram_impact", incoming)
		velocity_x = float(result) if result != null else -incoming * 0.35
		state = "recover"
		state_time = 0.42
		contact_cooldown = 0.16
		return

func _check_kinetic_carriage_contact() -> void:
	if contact_cooldown > 0.0:
		return
	var carriage := get_tree().get_first_node_in_group("kinetic_carriage") as Node2D
	if carriage == null or not carriage.has_method("receive_ram_impact"):
		return
	if absf(carriage.global_position.y - global_position.y) > 22.0:
		return
	var offset := carriage.global_position.x - global_position.x
	var direction := signf(offset)
	var carriage_velocity := float(carriage.get("velocity_x"))
	if is_zero_approx(direction):
		direction = 1.0 if velocity_x >= carriage_velocity else -1.0
	var relative_speed: float = velocity_x - carriage_velocity
	if absf(offset) > KINETIC_CONTACT_DISTANCE or relative_speed * direction <= 8.0:
		return
	var incoming := velocity_x
	global_position.x = carriage.global_position.x - direction * KINETIC_CONTACT_DISTANCE
	velocity_x = float(carriage.call("receive_ram_impact", incoming))
	contact_cooldown = 0.12
	state = "recover"
	state_time = 0.3
	carriage_hit.emit(incoming, float(carriage.get("velocity_x")))

func _update_sentry(delta: float) -> void:
	state_time = maxf(0.0, state_time - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		"patrol":
			position.x += facing * 22.0 * delta
			if position.x >= right_bound or position.x <= left_bound:
				position.x = clampf(position.x, left_bound, right_bound)
				facing *= -1
			cooldown = maxf(0.0, cooldown - delta)
			if player != null and cooldown <= 0.0 and absf(player.global_position.x - global_position.x) < 120.0 and absf(player.global_position.y - global_position.y) < 40.0:
				facing = 1 if player.global_position.x > global_position.x else -1
				state = "windup"
				state_time = 0.55
		"windup":
			if state_time <= 0.0:
				state = "charge"
				state_time = 0.5
		"charge":
			position.x += facing * 155.0 * delta
			if position.x <= left_bound or position.x >= right_bound or state_time <= 0.0:
				position.x = clampf(position.x, left_bound, right_bound)
				state = "recover"
				state_time = 0.75
		"recover":
			if state_time <= 0.0:
				state = "patrol"
				cooldown = 0.55

func receive_strike() -> bool:
	if not alive:
		return false
	health -= 1
	flash = 0.14
	if health <= 0:
		alive = false
		collision_layer = 0
		monitoring = false
		defeated.emit(global_position)
		queue_free()
	elif kind == "sentry":
		state = "recover"
		state_time = 0.8
	return true

func receive_dash() -> bool:
	return receive_strike()

func receive_kinetic_strike(player_velocity_x: float) -> bool:
	if not kinetic_mode:
		return false
	velocity_x = clampf(
		velocity_x * KINETIC_STRIKE_RAM_RETENTION + player_velocity_x * KINETIC_PLAYER_TRANSFER,
		-KINETIC_MAX_SPEED,
		KINETIC_MAX_SPEED
	)
	flash = 0.14
	state = "coast"
	state_time = 0.0
	contact_cooldown = 0.08
	kinetic_struck.emit(player_velocity_x, velocity_x)
	return true

func receive_stun(duration: float = 0.9) -> void:
	velocity_x = 0.0
	state = "stunned"
	state_time = duration
	cooldown = duration
	flash = duration
	stunned.emit(duration)

func set_charge_enabled(enabled: bool) -> void:
	charge_enabled = enabled
	if not enabled and state == "windup":
		state = "recover"
		state_time = 0.25

func reset_kinetic() -> void:
	position = spawn_position
	home = spawn_position
	velocity_x = 0.0
	facing = 1
	state = "idle"
	state_time = 0.3
	cooldown = 0.3
	contact_cooldown = 0.0
	alive = true
	monitoring = true
	charge_enabled = true
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not alive or not body.is_in_group("player"):
		return
	var reach := Vector2(16, 19) if kind in ["sentry", "kinetic_ram"] else Vector2(15, 16)
	if absf(body.global_position.x - global_position.x) > reach.x or absf(body.global_position.y - global_position.y) > reach.y:
		return
	if body.has_method("is_dashing") and body.is_dashing():
		return
	if body.has_method("is_striking") and body.is_striking() and body.global_position.y < global_position.y:
		return
	touched_player.emit(global_position)

func _draw() -> void:
	var ink := Color("162230")
	var steel := Color("658c94")
	var brass := Color("d4a65e")
	var eye := Color("f4dd8d")
	if flash > 0.0:
		steel = Color("fff1b8")
		brass = Color("fff1b8")
	match kind:
		"walker":
			draw_rect(Rect2(-8, -5, 16, 9), ink)
			draw_rect(Rect2(-6, -6, 12, 8), brass)
			draw_rect(Rect2(-4, -8, 8, 3), steel)
			draw_rect(Rect2(2 * facing, -3, 2, 2), eye)
			draw_rect(Rect2(-6, 4, 3, 3), ink)
			draw_rect(Rect2(3, 4, 3, 3), ink)
		"drone", "relay":
			draw_rect(Rect2(-9, -4, 18, 8), ink)
			draw_rect(Rect2(-7, -3, 14, 6), Color("397c82") if kind == "relay" else steel)
			draw_rect(Rect2(-3, -2, 6, 4), Color("a9f4dd") if kind == "relay" else eye)
			draw_rect(Rect2(-11, -6, 5, 2), brass)
			draw_rect(Rect2(6, -6, 5, 2), brass)
			draw_rect(Rect2(-12, -8 + int(sin(clock * 18.0)), 7, 1), Color("9ac6c7"))
			draw_rect(Rect2(5, -8 - int(sin(clock * 18.0)), 7, 1), Color("9ac6c7"))
		"sentry", "kinetic_ram":
			draw_rect(Rect2(-10, -10, 20, 20), ink)
			draw_rect(Rect2(-8, -9, 16, 16), steel)
			draw_rect(Rect2(-7, 5, 14, 3), brass)
			draw_rect(Rect2(-2 + facing * 3, -5, 3, 3), Color("f46e5a") if state == "windup" else eye)
			draw_rect(Rect2(-7, -12, 14, 3), brass)
			if state == "windup":
				draw_rect(Rect2(-12 if facing < 0 else 8, -3, 4, 6), Color("f46e5a"))
			if kinetic_mode and absf(velocity_x) > 10.0:
				draw_line(Vector2.ZERO, Vector2(clampf(velocity_x * 0.12, -28.0, 28.0), 0), Color("a9f4dd"), 2.0)
