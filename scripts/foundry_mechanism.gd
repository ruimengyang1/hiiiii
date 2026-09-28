extends Node2D

const PixelUI = preload("res://scripts/pixel_ui.gd")
signal changed(mechanism: Node2D)
signal impacted(at: Vector2)

var kind := "gate"
var rect := Rect2()
var label := ""
var active := false
var broken := false
var latched := false
var mass := 0.0
var release_time := 0.0
var release_grace := 0.45
var required_mass := 2.0
var suspended := false
var body: StaticBody2D
var linked_gate: Node2D
var font: Font

func configure(type: String, area: Rect2, title: String) -> void:
	kind = type
	rect = area
	label = title

func _ready() -> void:
	font = PixelUI.make_font()
	z_index = 1
	if kind in ["gate", "breakable"]:
		body = StaticBody2D.new()
		body.position = rect.get_center()
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
		add_to_group("transport_barriers")
		add_to_group("force_receivers")
	if kind == "plate":
		add_to_group("foundry_plates")

func _physics_process(delta: float) -> void:
	if suspended or kind != "plate":
		return
	refresh_weight(delta)

func refresh_weight(delta: float) -> void:
	mass = 0.0
	for object in get_tree().get_nodes_in_group("foundry_heavy"):
		if object.has_method("weight_rect") and rect.intersects(object.weight_rect()):
			mass += float(object.plate_mass())
	var was_active := active
	if mass >= required_mass:
		active = true
		release_time = release_grace
	else:
		release_time = maxf(0.0, release_time - delta)
		active = release_time > 0.0
	if linked_gate != null:
		linked_gate.set_open(active or linked_gate.latched)
	if active != was_active:
		changed.emit(self)
	queue_redraw()

func set_open(value: bool) -> void:
	if active == value:
		return
	if not value and active:
		# A closing gate cannot materialize inside an occupant. It stays open
		# until the body clears its safety strip, then the circuit can close it.
		for object in get_tree().get_nodes_in_group("foundry_heavy"):
			var bounds: Rect2 = object.impact_rect() if object.has_method("impact_rect") else object.weight_rect()
			if rect.intersects(bounds):
				return
		for worker in get_tree().get_nodes_in_group("player"):
			if rect.intersects(Rect2(worker.global_position - Vector2(6, 9), Vector2(12, 18))):
				return
	active = value
	if body != null:
		body.collision_layer = 0 if active else 1
	changed.emit(self)
	queue_redraw()

func latch_open() -> void:
	latched = true
	set_open(true)

func impact_rect() -> Rect2:
	return rect

func impact_enabled() -> bool:
	return not broken and not active

func blocks_transport() -> bool:
	return kind in ["gate", "breakable"] and impact_enabled()

func receive_impact(momentum: float, _source: Node2D = null) -> float:
	if kind == "breakable" and absf(momentum) >= 80.0:
		broken = true
		active = true
		body.collision_layer = 0
		impacted.emit(rect.get_center())
		changed.emit(self)
		queue_redraw()
		return momentum * 0.2
	impacted.emit(rect.get_center())
	return -momentum * 0.22

func snapshot() -> Dictionary:
	return {"active": active, "broken": broken, "latched": latched, "release": release_time, "mass": mass}

func restore(data: Dictionary) -> void:
	active = data.active
	broken = data.broken
	latched = data.latched
	release_time = data.release
	mass = data.mass
	if body != null:
		body.collision_layer = 0 if active or broken else 1
	queue_redraw()

func _draw() -> void:
	var green := Color("a9f4dd")
	var orange := Color("ef9569")
	if kind == "breakable":
		if broken:
			for i in 4:
				draw_rect(Rect2(rect.position.x - 10 + i * 9, rect.end.y - 5, 7, 5), Color("805448"))
		else:
			draw_rect(rect, Color("59484a"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), orange)
			for y in range(int(rect.position.y + 10), int(rect.end.y), 18):
				draw_line(Vector2(rect.position.x + 2, y), Vector2(rect.end.x - 2, y + 9), orange, 2.0)
	elif kind == "gate":
		var color := green if active else orange
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 8)), color)
		if not active:
			draw_rect(rect, Color("273945"))
			for y in range(int(rect.position.y), int(rect.end.y), 12):
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y + 6), color, 2.0)
		else:
			draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color(green, 0.22), 1.0)
	else:
		var color := green if active else Color("d7b06f")
		draw_rect(Rect2(rect.position + Vector2(0, 6), Vector2(rect.size.x, 5)), Color("172636"))
		draw_rect(Rect2(rect.position + Vector2(0, 4 if active else 0), Vector2(rect.size.x, 5)), color)
		if linked_gate != null:
			var wire_y := rect.position.y + 8.0
			draw_line(Vector2(rect.get_center().x, wire_y), Vector2(linked_gate.rect.get_center().x, wire_y), color, 2.0)
			draw_line(Vector2(linked_gate.rect.get_center().x, wire_y), linked_gate.rect.get_center(), color, 1.0)
		if release_time > 0.0 and mass < required_mass:
			draw_rect(Rect2(rect.position + Vector2(0, -4), Vector2(rect.size.x * release_time / release_grace, 2)), orange)
	draw_string(font, Vector2(rect.get_center().x - 50, rect.position.y - 8), label, HORIZONTAL_ALIGNMENT_CENTER, 100, 7, green if active else Color("d7b06f"))
