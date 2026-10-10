extends SceneTree
# Static views rendered from copied normal-play checkpoints. No HUD or ticks.
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func run() -> void:
	var report := OS.get_environment("EZEUS_SCENARIO_REPORT")
	var subjects: Array = JSON.parse_string(FileAccess.get_file_as_string(report.path_join("subjects.json")))
	DisplayServer.window_set_size(Vector2i(1600,600))
	for subject in subjects:
		if subject.has("engine"):Engine.set_meta("ezeus_engine_directory",subject.engine)
		# Each input is an owned copied checkpoint, potentially outside the review's
		# output-save folder. Preserve the native read-directory guard.
		Engine.set_meta("ezeus_save_directory",str(subject.save).get_base_dir())
		Engine.set_meta("ezeus_load",subject.save)
		var city = load("res://main.tscn").instantiate()
		root.add_child(city); current_scene = city
		for frame in 160: await process_frame
		if city.state.is_empty(): push_error("Art checkpoint did not load: " + city.hint.text); quit(1); return
		city.core.query("pause 1")
		city.hud.hide(); city.hint.hide(); city.details.hide()
		for child in city.get_children():
			if child is CanvasLayer: child.hide()
		city.orbit.target = city.world_position(subject.focus[0],subject.focus[1],0)
		city.orbit.distance = subject.distance
		city.orbit.pitch = subject.get("pitch",55)
		city.orbit.yaw = subject.get("yaw",135)
		city.orbit.snap_to_ground()
		city.building_auras.hide()
		for frame in 30: await process_frame
		RenderingServer.force_draw(true,.016)
		var image := root.get_texture().get_image()
		image.resize(960,360,Image.INTERPOLATE_LANCZOS)
		image.save_png(subject.output)
		city.queue_free()
		for frame in 60: await process_frame
	print("CAMPAIGN_ART_CAPTURE PASS")
	quit()
