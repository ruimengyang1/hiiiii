extends Node2D

signal changed(pressed: bool)

const PixelUI = preload("res://scripts/pixel_ui.gd")

var pressed := false
var label := "HEAVY SWITCH"
var pixel_font: Font
var required_mass := 2.0
var current_mass := 0.0

func configure(at: Vector2, display_label: String = "HEAVY SWITCH") -> void:
	position = at
	label = display_label

func _ready() -> void:
	pixel_font = PixelUI.make_font()
	queue_redraw()

func set_pressed(value: bool) -> void:
	if pressed == value:
		return
	pressed = value
	changed.emit(pressed)
	queue_redraw()

func refresh_weight() -> void:
	current_mass = 0.0
	var world_rect := Rect2(global_position - Vector2(24, 13), Vector2(48, 22))
	for object in get_tree().get_nodes_in_group("demo_heavy"):
		if not object.has_method("weight_rect") or not object.has_method("plate_mass"):
			continue
		if world_rect.intersects(object.weight_rect()):
			current_mass += float(object.plate_mass())
	set_pressed(current_mass >= required_mass)

func _draw() -> void:
	var glow := Color("a9f4dd") if pressed else Color("e5b873")
	draw_rect(Rect2(-22, -4, 44, 8), Color("162230"))
	draw_rect(Rect2(-19, -3 if pressed else -6, 38, 5), glow)
	for x in [-14, 0, 14]:
		draw_circle(Vector2(x, 2), 2.0, Color("304551"))
	if pixel_font != null:
		draw_string(pixel_font, Vector2(-42, -12), label, HORIZONTAL_ALIGNMENT_CENTER, 84, 8, glow)
