extends SceneTree
# Private scenario launcher: all player files live in this prototype's own folder.
func _initialize() -> void:
	var save_root := OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY")
	if save_root.is_empty() or DirAccess.make_dir_recursive_absolute(save_root) != OK:
		push_error("Open this campaign with its workspace Play launcher.")
		quit(1)
		return
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", save_root)
	Engine.set_meta("ezeus_engine_directory", OS.get_environment("EZEUS_SCENARIO_ENGINE"))
	var manifest_path := OS.get_environment("EZEUS_SCENARIO_MANIFEST")
	if manifest_path.is_empty(): manifest_path = ProjectSettings.globalize_path("res://../build-content-research/first-light-harbor/current.json")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	Engine.set_meta("ezeus_new_game_focus", manifest.start_focus)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			Engine.set_meta("ezeus_language", arg.trim_prefix("--lang="))
	call_deferred("start")

func start() -> void:
	change_scene_to_file("res://ui/start_menu.tscn")
