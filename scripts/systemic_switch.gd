extends Area2D

signal activated(kind: String, at: Vector2)

var kind := "strike"
var active := false
var label := "CUT-OFF"
var pulse := 0.0
var armed := true

func configure(switch_kind: String, at: Vector2, display_label: String) -> void:
	kind = switch_kind
	position = at
	label = display_label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 16
	collision_mask = 0
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 18)
	collision.shape = shape
	add_child(collision)
	if kind == "ram":
		add_to_group("ram_receivers")

func _process(delta: float) -> void:
	pulse = maxf(0.0, pulse - delta)
	queue_redraw()

func receive_strike() -> bool:
	if kind != "strike":
		return false
	_activate()
	return true

func receive_ram_impact(velocity_x: float) -> float:
	if kind != "ram":
		return velocity_x
	if armed:
		_activate()
	else:
		pulse = 0.2
	return -velocity_x * 0.42

func set_armed(enabled: bool) -> void:
	armed = enabled
	queue_redraw()

func reset_switch() -> void:
	active = false
	pulse = 0.0
	queue_redraw()

func _activate() -> void:
	pulse = 0.3
	if active:
		return
	active = true
	activated.emit(kind, global_position)
	queue_redraw()

func _draw() -> void:
	var glow := Color("a9f4dd") if active else Color("ef9569") if kind == "ram" and armed else Color("657b83") if kind == "ram" else Color("e9b96f")
	if pulse > 0.0:
		glow = Color("fff1ac")
	draw_rect(Rect2(-12, -10, 24, 20), Color("162230"))
	draw_rect(Rect2(-9, -7, 18, 14), Color("304551"))
	draw_circle(Vector2.ZERO, 5.0, glow)
	if kind == "ram":
		draw_rect(Rect2(-15, -3, 4, 6), glow)
		draw_rect(Rect2(11, -3, 4, 6), glow)
	else:
		draw_rect(Rect2(-5, -13, 10, 3), glow)
	draw_string(ThemeDB.fallback_font, Vector2(-18, -16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, glow)
