extends Node2D

signal angle_changed(angle: float)
signal sensor_changed(active: bool)
signal rotator_changed(occupied: bool)
signal sensor_lock_started(duration: float)
signal sensor_lock_finished

const PixelUI = preload("res://scripts/pixel_ui.gd")

var beam_angle := -PI * 0.5
var rotation_speed := deg_to_rad(34.0)
var sensor_position := Vector2.ZERO
var sensor_active := false
var rotator_occupied := false
var sensor_lock_duration := 0.0
var sensor_lock_time := 0.0
var sensor_lock_consumed := false
var beam_length := 330.0
var beam_end := Vector2.ZERO
var contact_blocker: Node2D
var pixel_font: Font

func configure(at: Vector2, sensor_at: Vector2, start_angle: float = -PI * 0.5) -> void:
	position = at
	sensor_position = sensor_at
	beam_angle = start_angle

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	pixel_font = PixelUI.make_font()
	_evaluate_beam()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if sensor_lock_time > 0.0:
		sensor_lock_time = maxf(0.0, sensor_lock_time - delta)
		if sensor_lock_time <= 0.0:
			sensor_lock_finished.emit()
	elif rotator_occupied:
		beam_angle = wrapf(beam_angle + rotation_speed * delta, -PI, PI)
		angle_changed.emit(beam_angle)
	_evaluate_beam()
	queue_redraw()

func set_rotator_occupied(value: bool) -> void:
	if rotator_occupied == value:
		return
	rotator_occupied = value
	if not value and sensor_lock_time > 0.0:
		sensor_lock_time = 0.0
		sensor_lock_finished.emit()
	rotator_changed.emit(value)
	queue_redraw()

func set_angle(value: float) -> void:
	beam_angle = wrapf(value, -PI, PI)
	_evaluate_beam()
	queue_redraw()

func beam_direction() -> Vector2:
	return Vector2.from_angle(beam_angle)

func _evaluate_beam() -> void:
	var direction := beam_direction()
	var maximum := beam_length
	contact_blocker = null
	for object in get_tree().get_nodes_in_group("laser_blockers"):
		var blocker := object as Node2D
		if blocker == null or not blocker.has_method("beam_block_radius"):
			continue
		var relative := blocker.global_position - global_position
		var along := relative.dot(direction)
		var perpendicular := absf(relative.cross(direction))
		var radius := float(blocker.beam_block_radius())
		if along <= 8.0 or along >= maximum or perpendicular > radius:
			continue
		maximum = maxf(8.0, along - sqrt(maxf(0.0, radius * radius - perpendicular * perpendicular)))
		contact_blocker = blocker
	beam_end = direction * maximum
	var to_sensor := sensor_position - global_position
	var sensor_along := to_sensor.dot(direction)
	var sensor_perpendicular := absf(to_sensor.cross(direction))
	var next_active := sensor_along > 8.0 and sensor_along <= maximum + 5.0 and sensor_perpendicular <= 9.0
	if next_active and not sensor_active and rotator_occupied and sensor_lock_duration > 0.0 and not sensor_lock_consumed:
		sensor_lock_time = sensor_lock_duration
		sensor_lock_consumed = true
		sensor_lock_started.emit(sensor_lock_duration)
	elif not next_active:
		sensor_lock_consumed = false
	if next_active != sensor_active:
		sensor_active = next_active
		sensor_changed.emit(sensor_active)

func _draw() -> void:
	var direction := beam_direction()
	draw_circle(Vector2.ZERO, 17.0, Color("162230"))
	draw_arc(Vector2.ZERO, 14.0, -PI, PI, 18, Color("c3935f"), 3.0)
	for angle in [-PI * 0.75, -PI * 0.25, PI * 0.25, PI * 0.75]:
		draw_line(Vector2.from_angle(angle) * 12.0, Vector2.from_angle(angle) * 17.0, Color("657b83"), 2.0)
	draw_line(Vector2.ZERO, direction * 19.0, Color("fff1ac"), 4.0)
	draw_line(direction * 17.0, beam_end, Color(1.0, 0.18, 0.12, 0.25), 6.0)
	draw_line(direction * 17.0, beam_end, Color("ff665b"), 2.0)
	draw_circle(beam_end, 4.0, Color("fff1ac"))
	var local_sensor := to_local(sensor_position)
	draw_rect(Rect2(local_sensor - Vector2(10, 10), Vector2(20, 20)), Color("162230"))
	var sensor_color := Color("fff1ac") if sensor_lock_time > 0.0 else Color("a9f4dd") if sensor_active else Color("657b83")
	draw_circle(local_sensor, 7.0, sensor_color)
	draw_arc(local_sensor, 9.0, 0.0, TAU, 16, Color("fff1ac") if sensor_active else Color("304551"), 2.0)
	if sensor_lock_time > 0.0:
		var lock_ratio := sensor_lock_time / maxf(sensor_lock_duration, 0.001)
		draw_rect(Rect2(local_sensor + Vector2(-16, 12), Vector2(32, 4)), Color("162230"))
		draw_rect(Rect2(local_sensor + Vector2(-15, 13), Vector2(30.0 * lock_ratio, 2)), Color("fff1ac"))
	if rotator_occupied:
		for i in 3:
			var arc_start := fmod(Time.get_ticks_msec() * 0.004 + i * TAU / 3.0, TAU)
			draw_arc(Vector2.ZERO, 21.0, arc_start, arc_start + 0.7, 7, Color("a9f4dd"), 2.0)
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-40, 28), "ROTATOR", HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color("a9f4dd") if rotator_occupied else Color("d7b06f"))
		draw_string(pixel_font, local_sensor + Vector2(-28, -14), "SENSOR", HORIZONTAL_ALIGNMENT_CENTER, 56, 8, sensor_color)
		if sensor_lock_time > 0.0:
			draw_string(pixel_font, local_sensor + Vector2(-45, 27), "LOCK %.1fs" % sensor_lock_time, HORIZONTAL_ALIGNMENT_CENTER, 90, 8, Color("fff1ac"))
