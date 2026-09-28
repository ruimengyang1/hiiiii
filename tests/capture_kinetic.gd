extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign = (load("res://scenes/kinetic_prototype.tscn") as PackedScene).instantiate()
	root.add_child(campaign)
	await process_frame
	await create_timer(0.1).timeout
	if not _save("can_campaign_card.png"):
		quit(1)
		return

	campaign._build_level(1)
	campaign.ram.wedge_at(campaign.wedge_position)
	campaign._update_pressure_logic()
	campaign.hint_time = 0.0
	campaign.announcement_time = 0.0
	campaign._update_transient_ui()
	await create_timer(0.1).timeout
	if not _save("can_campaign_fan.png"):
		quit(1)
		return

	campaign._build_level(4)
	campaign.hint_time = 0.0
	campaign.announcement_time = 0.0
	campaign._update_transient_ui()
	await create_timer(0.1).timeout
	if not _save("can_campaign_laser.png"):
		quit(1)
		return
	campaign.laser.receive_ram_impact(130.0)
	await create_timer(0.1).timeout
	if not _save("can_campaign_sensor.png"):
		quit(1)
		return

	campaign._build_level(6)
	campaign.ram.wedge_at(campaign.wedge_position)
	campaign._update_pressure_logic()
	campaign.power_latch = true
	campaign._update_mastery_power()
	campaign.laser.receive_ram_impact(130.0)
	campaign.hint_time = 0.0
	campaign.announcement_time = 0.0
	campaign._update_transient_ui()
	await create_timer(0.1).timeout
	if not _save("can_campaign_mastery.png"):
		quit(1)
		return
	print("CAN CAMPAIGN CAPTURE PASS: card, fan, laser, sensor, and mastery")
	campaign.free()
	await process_frame
	quit(0)

func _save(filename: String) -> bool:
	var image := root.get_texture().get_image()
	return image != null and image.save_png(OS.get_temp_dir().path_join(filename)) == OK
