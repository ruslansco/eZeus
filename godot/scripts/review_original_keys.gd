extends SceneTree
# Opens the designated test city and runs only the original-game suites (validate_original_keys.gd and, as they are added, the
# guide-parity gameplay checks), then exits. Launched by tools/review_original_keys.py, which protects the save and the settings.
func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func run() -> void:
	var city: Node3D = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1")
	city.orbit.enabled = false
	var okay: bool = await load("res://scripts/validate_original_keys.gd").new().run(city)
	if OS.get_cmdline_user_args().has("--parity"):
		okay = await load("res://scripts/validate_guide_parity_ui.gd").new().run(city) and okay
	print("ORIGINAL_KEYS_VALIDATION ", "PASS" if okay else "FAIL")
	quit(0 if okay else 1)
