extends AnimatableBody2D

signal impacted(at: Vector2, speed: float)
signal settled(at: Vector2)

const PixelUI = preload("res://scripts/pixel_ui.gd")

var velocity_x := 0.0
var left_bound := 0.0
var right_bound := 384.0
var rolling_angle := 0.0
var was_moving := false
var pixel_font: Font

func configure(at: Vector2, movement_left: float, movement_right: float) -> void:
	position = at
	left_bound = movement_left
	right_bound = movement_right

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	add_to_group("ram_receivers")
	add_to_group("demo_heavy")
	add_to_group("laser_blockers")
	pixel_font = PixelUI.make_font()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	var old_x := position.x
	position.x = clampf(position.x + velocity_x * delta, left_bound, right_bound)
	if not is_equal_approx(position.x, old_x):
		rolling_angle += (position.x - old_x) / 13.0
	if position.x <= left_bound + 0.01 and velocity_x < 0.0:
		velocity_x = 0.0
	elif position.x >= right_bound - 0.01 and velocity_x > 0.0:
		velocity_x = 0.0
	velocity_x = move_toward(velocity_x, 0.0, 118.0 * delta)
	var moving := absf(velocity_x) > 2.0
	if was_moving and not moving:
		settled.emit(global_position)
	was_moving = moving
	queue_redraw()

func receive_ram_impact(ram_velocity: float) -> float:
	velocity_x = clampf(ram_velocity * 0.78, -185.0, 185.0)
	impacted.emit(global_position, absf(ram_velocity))
	return -ram_velocity * 0.10

func plate_mass() -> float:
	return 2.0

func weight_rect() -> Rect2:
	return Rect2(global_position - Vector2(13, 12), Vector2(26, 25))

func beam_block_radius() -> float:
	return 14.0

func _draw() -> void:
	var stone := Color("7f8d8d")
	draw_circle(Vector2.ZERO, 14.0, Color("162230"))
	draw_circle(Vector2.ZERO, 12.0, stone)
	for angle in [0.2, 2.25, 4.25]:
		var start := Vector2(cos(angle + rolling_angle), sin(angle + rolling_angle)) * 4.0
		var finish := Vector2(cos(angle + rolling_angle), sin(angle + rolling_angle)) * 10.0
		draw_line(start, finish, Color("c7d0c8"), 2.0)
	draw_circle(Vector2(-3, -4).rotated(rolling_angle), 2.0, Color("53666b"))
	if absf(velocity_x) > 10.0:
		for x in [-10, 0, 10]:
			draw_circle(Vector2(x - signf(velocity_x) * 13.0, 13), 1.5, Color("c3935f", 0.75))
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-24, -19), "HEAVY", HORIZONTAL_ALIGNMENT_CENTER, 48, 8, Color("d7e5d5"))
