extends SceneTree
const Options = preload("res://scripts/graphics_settings.gd")
const Dialog = preload("res://ui/graphics_dialog.gd")
const Settings = preload("res://scripts/user_settings.gd")
var city: Node
var checks := 0
var okay := true
var language := "en"

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("GRAPHICS_CHECK ", "PASS " if value else "FAIL ", label)

func frames(count := 8) -> void:
	for i in count: await process_frame

func pref_hash() -> String:
	return FileAccess.get_sha256(Settings.path()) if FileAccess.file_exists(Settings.path()) else ""

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.get_slice("=", 1)
	load("res://scripts/ui_text.gd").set_language(language)
	root.size = Vector2i(1280,720)
	check(Options.load_preference() == "balanced", "new players retain the established appearance")
	check(not ProjectSettings.get_setting("rendering/rendering_device/fallback_to_opengl3",true), "modern rendering does not silently select the legacy renderer")
	for value in [null, 2, "ultra", {}, false]:
		check(Options.sanitize(value) == "balanced", "unsupported preference falls back: " + str(value))
	Settings.set_value("display", "frame_limit", 60)
	Settings.set_value("interface", "text_size", 115)
	Settings.set_value("game", "autosave_minutes", 0)
	city = load("res://main.tscn").instantiate(); root.add_child(city); current_scene = city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	await frames(16)
	check(not city.state.is_empty() and city.tiles.size() == 25992, "the full designated city loaded")
	city.core.set_process(false); city.set_process(false); city.orbit.set_process(false)
	city.core.simulation.command("pause 1")
	var digest: String = city.core.simulation.replay(0).digest
	var queues: Array = city.core.commands.duplicate()
	var build_count: int = city.building_render_updates
	var detail_rebuilds: int = city.terrain_details.rebuilds
	var instances: Dictionary = city.static_batches.group_nodes.duplicate()
	var counts: Dictionary = city.terrain_details.summary().counts.duplicate()
	var ui_scale: float = root.content_scale_factor
	for preset in Options.ORDER:
		var hash := pref_hash()
		var dialog: Window = Dialog.open(city.hud)
		await frames()
		check(Dialog.open(city.hud) == null, "one options window at a time")
		dialog.choice.select(Options.ORDER.find(preset)); dialog.preview()
		await frames()
		check(Options.current == preset and is_equal_approx(root.scaling_3d_scale, Options.PRESETS[preset].scale) and root.msaa_3d == Options.PRESETS[preset].msaa and is_equal_approx(root.mesh_lod_threshold, Options.PRESETS[preset].lod), preset + ": live viewport settings")
		check(city.graphics_sun.shadow_enabled == Options.PRESETS[preset].shadows and is_equal_approx(city.graphics_sun.directional_shadow_max_distance, Options.PRESETS[preset].shadow_distance), preset + ": sun settings")
		check(city.terrain_details.rebuilds == detail_rebuilds and city.terrain_details.summary().counts == counts and city.building_render_updates == build_count and city.static_batches.group_nodes == instances, preset + ": no world/model rebuild or missing resource outcrops")
		check(root.content_scale_factor == ui_scale and pref_hash() == hash, preset + ": sharp UI and no preview writes")
		check(root.scaling_3d_scale == 1.0 and city.graphics_sun.shadow_enabled, preset + ": full-resolution city and sun shadows retained")
		for distance in [25.0, 80.0]:
			city.orbit.distance = distance; city.orbit.snap_to_ground()
			await frames(2); await physics_frame
			var cell := Vector2i(city.tile_coordinates(city.orbit.target).round())
			var point: Vector3 = city.world_position(cell.x,cell.y,0)
			point.y = city.orbit.height_at(point.x,point.z)
			city.pick_tile(city.orbit.camera.unproject_position(point))
			check(city.picked == cell, preset + ": native picking at distance " + str(distance))
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_move_to_foreground()
			await frames(); await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://captures/graphics-"+preset+"-"+language+".png")
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(Rect2(Vector2(dialog.position),Vector2(dialog.size))), preset + ": dialog fits")
		dialog.canceled.emit(); await frames()
		check(Options.current == "balanced" and pref_hash() == hash and not root.get_node("UiAccess").dialog_open, preset + ": Cancel restores and releases input")
	var dialog: Window = Dialog.open(city.hud); await frames()
	dialog.choice.select(1); dialog.preview(); dialog.confirmed.emit(); await frames()
	check(Options.current == "high" and Options.load_preference() == "high", "Apply persists only the selected preset")
	check(Settings.get_value("display","frame_limit",0) == 60 and Settings.get_value("interface","text_size",0) == 115 and Settings.get_value("game","autosave_minutes",-1) == 0, "other preference sections survive Apply")
	Options.apply(self,"balanced"); Options.startup(self)
	check(Options.current == "high" and city.graphics_sun.shadow_enabled, "next startup restores the committed preset")
	dialog = Dialog.open(city.hud); await frames(); dialog.choice.select(0); dialog.preview()
	var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.physical_keycode = KEY_ESCAPE; event.pressed = true
	event.set_meta("review_input",true)
	root.push_input(event,true); await frames()
	check(not is_instance_valid(dialog) and Options.current == "high", "Escape cancels the live preview")
	dialog = Dialog.open(city.hud); await frames(); dialog.choice.select(0); dialog.preview(); dialog.queue_free(); await frames()
	check(Options.current == "high" and not root.get_node("UiAccess").dialog_open, "scene removal restores previous settings")
	for scale in [Vector2i(100,100),Vector2i(125,130)]:
		root.get_node("UiAccess").apply(scale.x,scale.y)
		dialog = Dialog.open(city.hud); await frames()
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(Rect2(Vector2(dialog.position),Vector2(dialog.size))), "fits independent interface/text sizes " + str(scale))
		dialog.canceled.emit(); await frames()
	root.get_node("UiAccess").apply(100,100)
	# A failed settings write must leave Cancel available and preserve the old preset.
	var previous_path: String = Engine.get_meta("ezeus_settings_path")
	Engine.set_meta("ezeus_settings_path", previous_path.path_join("missing/settings.cfg"))
	dialog = Dialog.open(city.hud); await frames(); dialog.choice.select(0); dialog.preview(); dialog.confirmed.emit()
	check(not dialog.committed and dialog.write_error.visible, "failed persistence is visible and does not close")
	dialog.canceled.emit(); await frames(); Engine.set_meta("ezeus_settings_path",previous_path)
	check(Options.current == "high" and city.core.simulation.replay(0).digest == digest and city.core.commands == queues, "all previews preserve native city state, RNG and command queue")
	Options.apply(self,"balanced")
	print("GRAPHICS_VALIDATION ", "PASS" if okay else "FAIL", " checks=",checks)
	quit(0 if okay else 1)
