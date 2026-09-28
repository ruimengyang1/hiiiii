extends "res://scripts/foundry_mechanism.gd"

var extension := 0.0

func _ready() -> void:
	super._ready()
	if kind == "bridge":
		body = StaticBody2D.new()
		body.position = rect.get_center()
		body.collision_layer = 0
		body.collision_mask = 0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.one_way_collision = true
		body.add_child(collision)
		add_child(body)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not suspended and kind == "bridge":
		extension = move_toward(extension, 1.0 if active else 0.0, delta * 7.0)
		queue_redraw()

func set_open(value: bool) -> void:
	if kind != "bridge":
		super.set_open(value)
		return
	if active == value:
		return
	active = value
	# Change collision with the signal, so the consequence is immediate. The
	# 0.14-second telescoping art explains the mechanical relationship.
	body.collision_layer = 1 if value else 0
	changed.emit(self)
	queue_redraw()

func restore(data: Dictionary) -> void:
	super.restore(data)
	if kind == "bridge":
		body.collision_layer = 1 if active else 0
		extension = 1.0 if active else 0.0

func _draw() -> void:
	if kind != "bridge":
		super._draw()
		return
	draw_rect(Rect2(rect.position + Vector2(-8, -4), Vector2(8, 16)), Color("416d83"))
	draw_line(rect.position + Vector2(0, 14), rect.end + Vector2(0, 14), Color("263d48"), 2)
	var visible_rect := Rect2(rect.position, Vector2(rect.size.x * extension, rect.size.y))
	draw_rect(visible_rect, Color("416d83"))
	draw_rect(Rect2(visible_rect.position, Vector2(visible_rect.size.x, 3)), Color("a9f4dd"))
	for x in range(int(rect.position.x), int(rect.position.x + visible_rect.size.x), 12):
		draw_line(Vector2(x, rect.position.y + 4), Vector2(x + 5, rect.end.y), Color("edc27a"), 1)
	if not active:
		for x in range(int(rect.position.x + 10), int(rect.end.x), 14):
			draw_rect(Rect2(x, rect.position.y, 6, 2), Color("397c82"))
