extends "res://scripts/crusher.gd"

var shielded := false

func _physics_process(delta: float) -> void:
	if suspended:
		return
	clock += delta
	var phase := fmod(clock, 2.4)
	var warning := phase >= 0.25 and phase < 0.75
	if warning and not was_warning:
		cycle_warning.emit()
	was_warning = warning
	var amount := 0.0
	if phase >= 0.55 and phase < 0.75:
		amount = (phase - 0.55) / 0.2
	elif phase >= 0.75 and phase < 1.20:
		amount = 1.0
	elif phase >= 1.20 and phase < 1.50:
		amount = 1.0 - (phase - 1.20) / 0.30
	position.y = high.y + amount * drop_distance
	shielded = false
	for transport in get_tree().get_nodes_in_group("foundry_cart"):
		if absf(transport.position.x - position.x) < 40.0 and transport.visible:
			# The solid chassis catches the press before its teeth reach the bot.
			position.y = minf(position.y, transport.position.y - 38.0)
			shielded = true
	for actor in spike_area.get_overlapping_areas():
		if not shielded and actor.has_method("receive_environmental_stun"):
			actor.receive_environmental_stun("crusher")
	queue_redraw()

func _on_body_entered(worker: Node2D) -> void:
	if suspended:
		return
	if worker.is_in_group("player"):
		# Contact is recoverable; only falling out of the room costs a rewind.
		worker.take_damage(position)

func _draw() -> void:
	super._draw()
	if shielded:
		draw_line(Vector2(-18, 24), Vector2(18, 24), Color("a9f4dd"), 2)
