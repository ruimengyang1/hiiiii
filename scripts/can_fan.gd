extends Node2D

signal changed(active: bool)

const PixelUI = preload("res://scripts/pixel_ui.gd")

var active := false
var lift_rect := Rect2(-28, -126, 56, 126)
var clock := 0.0
var visual_speed := 0.0
var pixel_font: Font

func configure(at: Vector2, height: float = 126.0) -> void:
	position = at
	lift_rect = Rect2(-28, -height, 56, height)

func _ready() -> void:
	pixel_font = PixelUI.make_font()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	visual_speed = move_toward(visual_speed, 1.0 if active else 0.0, delta * (4.5 if active else 3.0))
	queue_redraw()

func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	changed.emit(active)
	queue_redraw()

func affects(world_point: Vector2) -> bool:
	return active and lift_rect.has_point(to_local(world_point))

func lift(body: CharacterBody2D, delta: float) -> void:
	if not affects(body.global_position):
		return
	body.velocity.y = move_toward(body.velocity.y, -225.0, 760.0 * delta)
	body.velocity.x *= pow(0.93, delta * 60.0)

func _draw() -> void:
	var glow := Color("a9f4dd") if active else Color("657b83")
	draw_rect(Rect2(-30, -8, 60, 12), Color("162230"))
	draw_rect(Rect2(-27, -6, 54, 8), Color("304551"))
	draw_circle(Vector2.ZERO, 15.0, Color("172636"))
	for i in 4:
		var angle := clock * lerpf(1.5, 9.0, visual_speed) + i * PI / 2.0
		draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 13.0, glow, 4.0)
	if visual_speed > 0.05:
		for i in 5:
			var y := -18.0 - fmod(clock * 72.0 + i * 25.0, absf(lift_rect.position.y) - 12.0)
			var sway := sin(clock * 5.0 + i) * 8.0
			draw_line(Vector2(sway - 8.0, y), Vector2(sway + 8.0, y - 7.0), Color(glow, 0.25 + visual_speed * 0.55), 2.0)
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-28, 18), "FAN %s" % ("ON" if active else "OFF"), HORIZONTAL_ALIGNMENT_CENTER, 56, 8, glow)
