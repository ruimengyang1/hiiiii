extends AnimatableBody2D

signal moved(delta_position: Vector2)
signal arrived(active: bool)

const PixelUI = preload("res://scripts/pixel_ui.gd")

var start_position := Vector2.ZERO
var active_position := Vector2.ZERO
var platform_size := Vector2(54, 10)
var active := false
var speed := 150.0
var display_label := "PLATFORM"
var pixel_font: Font
var impact_driven := false

func configure(at: Vector2, target: Vector2, size: Vector2 = Vector2(54, 10), label: String = "PLATFORM") -> void:
	position = at
	start_position = at
	active_position = target
	platform_size = size
	display_label = label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	pixel_font = PixelUI.make_font()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	add_child(collision)
	if impact_driven:
		add_to_group("ram_receivers")
	queue_redraw()

func set_impact_driven(value: bool) -> void:
	impact_driven = value
	if is_inside_tree():
		if value and not is_in_group("ram_receivers"):
			add_to_group("ram_receivers")
		elif not value and is_in_group("ram_receivers"):
			remove_from_group("ram_receivers")

func receive_ram_impact(ram_velocity: float) -> float:
	if not impact_driven or active or absf(ram_velocity) < 80.0:
		return -ram_velocity * 0.32
	set_active(true)
	return -ram_velocity * 0.14

func is_ram_passthrough() -> bool:
	return impact_driven and active

func _physics_process(delta: float) -> void:
	var target := active_position if active else start_position
	var old_position := position
	position = position.move_toward(target, speed * delta)
	var travel := position - old_position
	if not travel.is_zero_approx():
		moved.emit(travel)
		queue_redraw()
	if old_position.distance_to(target) > 0.01 and position.distance_to(target) <= 0.01:
		arrived.emit(active)

func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	queue_redraw()

func current_rect() -> Rect2:
	return Rect2(global_position - platform_size * 0.5, platform_size)

func is_moving() -> bool:
	var target := active_position if active else start_position
	return position.distance_to(target) > 0.5

func _draw() -> void:
	var target_local := to_local(active_position)
	draw_rect(Rect2(target_local - platform_size * 0.5, platform_size), Color("657b83", 0.18), false, 1.0)
	draw_rect(Rect2(-platform_size * 0.5, platform_size), Color("304551"))
	draw_rect(Rect2(-platform_size * 0.5, Vector2(platform_size.x, 3)), Color("a9f4dd") if active else Color("c3935f"))
	for x in range(int(-platform_size.x * 0.5 + 7), int(platform_size.x * 0.5), 12):
		draw_circle(Vector2(x, 2), 2.0, Color("162230"))
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-42, -10), display_label, HORIZONTAL_ALIGNMENT_CENTER, 84, 8, Color("d7e5d5"))
