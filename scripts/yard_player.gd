extends "res://scripts/action_player.gd"

func _draw() -> void:
	# Keep the worker locatable inside a simultaneous chain. Hurt protection
	# pulses an outline instead of intermittently hiding the whole sprite.
	var protection := invulnerable_time
	invulnerable_time = 0
	super._draw()
	invulnerable_time = protection
	if protection > 0 and int(protection * 14) % 2 == 0:
		draw_rect(Rect2(-5, -10, 10, 20), Color("fff1ac"), false, 1)
