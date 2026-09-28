extends AnimatableBody2D

signal crushed_player
signal cycle_warning

const SPIKE_X := [-10.0, -3.0, 4.0]

var high := Vector2.ZERO
var drop_distance := 42.0
var clock := 0.0
var foundry_mode := false
var suspended := false
var disabled := false
var spike_area: Area2D
var cycle_length := 2.7
var was_warning := false
var warning_lead := 0.2

func configure(at: Vector2, phase: float = 0.0) -> void:
	position = at
	high = at
	clock = phase

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 36)
	collision.shape = shape
	collision.position.y = -4.0
	add_child(collision)
	var spikes := Area2D.new()
	spike_area = spikes
	spikes.collision_layer = 0
	spikes.collision_mask = 18 if foundry_mode else 2
	spikes.monitoring = true
	add_child(spikes)
	for x in SPIKE_X:
		var spike := CollisionPolygon2D.new()
		spike.polygon = _spike_points(x)
		spikes.add_child(spike)
	spikes.body_entered.connect(_on_body_entered)
	if foundry_mode:
		add_to_group("transport_barriers")

func _spike_points(x: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, 13), Vector2(x + 6, 13), Vector2(x + 3, 21)])

func _physics_process(delta: float) -> void:
	if suspended:
		return
	if disabled:
		position = high
		queue_redraw()
		return
	clock += delta
	var phase := fmod(clock, cycle_length)
	var warning := phase >= maxf(0.0, 0.55 - warning_lead) and phase < 0.75
	if foundry_mode and warning and not was_warning:
		cycle_warning.emit()
	was_warning = warning
	var amount := 0.0
	if phase >= 0.55 and phase < 0.75:
		amount = (phase - 0.55) / 0.2
	elif phase >= 0.75 and phase < 1.45:
		amount = 1.0
	elif phase >= 1.45 and phase < 1.75:
		amount = 1.0 - (phase - 1.45) / 0.3
	position.y = high.y + amount * drop_distance
	if foundry_mode:
		for actor in spike_area.get_overlapping_areas():
			if actor.has_method("receive_stun"):
				actor.receive_stun(6.0)
	queue_redraw()

func impact_rect() -> Rect2:
	return Rect2(global_position + Vector2(-12, -22), Vector2(24, 36))

func blocks_transport() -> bool:
	return foundry_mode

func _on_body_entered(body: Node2D) -> void:
	if foundry_mode and (disabled or suspended):
		return
	if body.is_in_group("player"):
		crushed_player.emit()

func _draw() -> void:
	var warning := fmod(clock, cycle_length) >= maxf(0.0, 0.55 - warning_lead) and fmod(clock, cycle_length) < 0.75
	var stripe := Color("ff775e") if warning else Color("d9b16a")
	draw_rect(Rect2(-12, -22, 24, 5), Color("4b6371"))
	draw_rect(Rect2(-14, -18, 28, 32), Color("172636"))
	draw_rect(Rect2(-11, -16, 22, 25), Color("617b83"))
	draw_rect(Rect2(-9, -14, 18, 4), stripe)
	draw_rect(Rect2(-9, 5, 18, 3), Color("304551"))
	for x in SPIKE_X:
		draw_colored_polygon(_spike_points(x), Color("e8c27f"))
