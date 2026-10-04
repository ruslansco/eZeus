extends SceneTree
# Visible capture of the character window with each portrait model (godot/assets/portraits). Presentation only: the
# window is shown with the role's own words where the city has such a walker, or a caption otherwise; nothing is written.
var city: Node3D
var language := "en"
var only := ""

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func frames(count := 10) -> void:
	for frame in count:
		await process_frame

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=", 1)
		if argument.begins_with("--only="): only = argument.get_slice("=", 1)
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.orbit.enabled = false
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	await frames()
	var assets: Array = []
	for file in DirAccess.get_files_at("res://assets/portraits"):
		if file.ends_with(".glb") and (only.is_empty() or file.get_basename() in only.split(",")):
			assets.append(file.get_basename())
	var count := 0
	for asset in assets:
		var info := {"asset": asset, "kind": "person", "name": asset.trim_prefix("walker_").capitalize(), "occupation": "", "text": "", "voice": "", "others": []}
		for id in city.walkers:
			if city.walkers[id].asset == asset:
				var answer: Dictionary = city.core.query("character_info %d" % id)
				if not answer.has("error"): info = answer
				break
		city.open_character_info(info)
		await create_timer(1.0).timeout
		var panel: Control = city.character_panel
		var ok: bool = panel.figure != null and panel.figure.scene_file_path.begins_with("res://assets/portraits/")
		print("PORTRAIT ", asset, " ", "PASS" if ok else "FAIL")
		if ok: count += 1
		DisplayServer.window_move_to_foreground()
		await frames(10)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://captures/portrait-" + asset + "-" + language + ".png")
		var frame_rect: Rect2 = panel.card.get_global_rect()
		var scale_: Vector2 = Vector2(image.get_size()) / city.hud.size
		image.get_region(Rect2i(frame_rect.position * scale_, Vector2(300, frame_rect.size.y) * scale_)).save_png("res://captures/portrait-" + asset + "-crop.png")
		city.close_character()
		await frames()
	print("PORTRAIT_REVIEW ", count, "/", assets.size())
	city.queue_free()
	await frames(8)
	quit(0 if count == assets.size() else 1)
