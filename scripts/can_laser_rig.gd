extends Node2D

signal orientation_changed(index: int)
signal sensor_changed(active: bool)
signal impact_rejected

const PixelUI = preload("res://scripts/pixel_ui.gd")

var orientation_index := 0
var orientations := [Vector2.RIGHT, Vector2(1, -1).normalized(), Vector2.UP]
var sensor_position := Vector2.ZERO
var sensor_active := false
var armed := true
var pixel_font: Font

func configure(at: Vector2, sensor_at: Vector2, start_orientation: int = 0) -> void:
	position = at
	sensor_position = sensor_at
	orientation_index = clampi(start_orientation, 0, orientations.size() - 1)

func _ready() -> void:
	pixel_font = PixelUI.make_font()
	add_to_group("ram_receivers")
	_evaluate_sensor()
	queue_redraw()

func receive_ram_impact(velocity_x: float) -> float:
	if not armed:
		impact_rejected.emit()
		return velocity_x
	orientation_index = (orientation_index + 1) % orientations.size()
	orientation_changed.emit(orientation_index)
	_evaluate_sensor()
	queue_redraw()
	return -velocity_x * 0.32

func set_orientation(index: int) -> void:
	orientation_index = posmod(index, orientations.size())
	_evaluate_sensor()
	queue_redraw()

func beam_direction() -> Vector2:
	return orientations[orientation_index]

func _evaluate_sensor() -> void:
	var to_sensor := sensor_position - global_position
	var distance_along := to_sensor.dot(beam_direction())
	var perpendicular := absf(to_sensor.cross(beam_direction()))
	var next_active := distance_along > 0.0 and distance_along < 310.0 and perpendicular <= 13.0
	if next_active != sensor_active:
		sensor_active = next_active
		sensor_changed.emit(sensor_active)

func _draw() -> void:
	var direction := beam_direction()
	var beam_length := 300.0
	draw_line(Vector2.ZERO, direction * beam_length, Color(1.0, 0.25, 0.2, 0.28), 5.0)
	draw_line(Vector2.ZERO, direction * beam_length, Color("ff6f5f"), 2.0)
	draw_circle(Vector2.ZERO, 14.0, Color("162230"))
	draw_circle(Vector2.ZERO, 10.0, Color("b95b52"))
	draw_line(Vector2.ZERO, direction * 18.0, Color("fff1ac"), 4.0)
	var local_sensor := to_local(sensor_position)
	draw_rect(Rect2(local_sensor - Vector2(9, 9), Vector2(18, 18)), Color("162230"))
	draw_circle(local_sensor, 6.0, Color("a9f4dd") if sensor_active else Color("657b83"))
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-33, -19), "HIT TO ROTATE", HORIZONTAL_ALIGNMENT_CENTER, 66, 7, Color("efb97b"))
		draw_string(pixel_font, local_sensor + Vector2(-24, -13), "SENSOR", HORIZONTAL_ALIGNMENT_CENTER, 48, 7, Color("a9f4dd") if sensor_active else Color("9aa9a8"))
