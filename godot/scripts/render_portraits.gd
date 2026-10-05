extends SceneTree
# Renders the character window's still portraits: each model in the source folder (build-portraits, outside the project,
# loaded at run time) is posed in the window's own stage, lighting and finish, framed on the head and shoulders and saved
# with a transparent background as <out>/<asset>.png (default build-portraits/renders, outside the game, so the painted
# portraits in res://assets/portraits are never overwritten; copy a render there to use it). Nothing in the city is written; the designated save is only read.
const SCALE := 2               # Rendered at twice the window's portrait size, for sharp high-DPI display.
var city: Node3D
var source := ""
var only := ""
var out := ProjectSettings.globalize_path("res://").path_join("../build-portraits/renders").simplify_path()
var crowd := false             # References: roles without a portrait model are rendered from their crowd model.
var views := "bust"            # bust and/or full (the whole figure), comma-separated; only "bust" names the file plainly.

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func frames(count := 10) -> void:
	for frame in count:
		await process_frame

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source="): source = argument.get_slice("=", 1)
		if argument.begins_with("--only="): only = argument.get_slice("=", 1)
		if argument.begins_with("--out="): out = argument.get_slice("=", 1)
		if argument.begins_with("--views="): views = argument.get_slice("=", 1)
		if argument == "--crowd": crowd = true
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.orbit.enabled = false
	city.character_portrait_source = source
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var done := 0
	var assets: Array = []
	for file in DirAccess.get_files_at(source):
		if file.ends_with(".glb") and (only.is_empty() or file.get_basename() in only.split(",")):
			assets.append(file.get_basename())
	if crowd:
		for asset in only.split(","):
			if not asset.is_empty() and not asset in assets:
				assets.append(asset)
	for asset: String in assets:
		city.open_character_info({"asset": asset, "kind": "person", "name": asset, "occupation": "", "text": "", "voice": "", "others": []})
		var panel: Control = city.character_panel
		panel.posed = true
		panel.stop_voice()
		await frames(4)
		if panel.figure == null or panel.zoom_target != 1.0:
			print("PORTRAIT_RENDER ", asset, " FAIL no figure")
			city.close_character(); continue
		panel.holder.stretch = false
		panel.viewport.size = Vector2i(panel.PORTRAIT_SIZE * SCALE)
		panel.viewport.msaa_3d = Viewport.MSAA_8X
		var ok := true
		for view: String in views.split(","):
			panel.zoom = 1.0 if view == "bust" else 0.0
			panel.zoom_target = panel.zoom
			panel.place_camera()
			await create_timer(.6).timeout
			await RenderingServer.frame_post_draw
			var image: Image = panel.viewport.get_texture().get_image()
			var path: String = out.path_join(asset + ("" if view == "bust" and views == "bust" else "_" + view) + ".png")
			var saved := image.save_png(path) == OK and not image.is_invisible()
			print("PORTRAIT_RENDER ", asset, " ", view, " ", "PASS " if saved else "FAIL ", image.get_size(), " ", path)
			ok = ok and saved
		if ok: done += 1
		city.close_character()
		await frames()
	print("PORTRAIT_RENDERED ", done, "/", assets.size())
	city.character_portrait_source = ""
	city.queue_free()
	await frames(8)
	quit(0 if done == assets.size() else 1)
