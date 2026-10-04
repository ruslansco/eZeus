extends SceneTree
const DisplayOptions = preload("res://scripts/display_settings.gd")
const DisplayDialog = preload("res://ui/display_dialog.gd")
const Settings = preload("res://scripts/user_settings.gd")
var city: Node3D
var okay := true
var checks := 0
var language := "en"

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1; okay = okay and value
	print("DISPLAY_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 12) -> void:
	for frame in count: await process_frame

func file_hash() -> String:
	return FileAccess.get_sha256(Settings.path()) if FileAccess.file_exists(Settings.path()) else ""

func same_window(expected: Dictionary) -> bool:
	return root.mode == expected.actual_mode and root.size == expected.actual_size and root.position == expected.position and root.borderless == expected.borderless and Engine.max_fps == expected.frame_limit and (DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED) == expected.vsync

func click(button: Button, dialog: Window) -> void:
	var point := button.get_global_rect().get_center() + Vector2(dialog.position)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.position = point; event.pressed = pressed
		root.push_input(event, true)
	await frames()

func check_picking(label: String) -> void:
	await physics_frame
	var cell := Vector2i(city.tile_coordinates(city.orbit.target).round())
	var point: Vector3 = city.world_position(cell.x,cell.y,0)
	point.y = city.orbit.height_at(point.x,point.z)
	city.pick_tile(city.orbit.camera.unproject_position(point))
	check(city.picked == cell, "native terrain picking after " + label)

func capture(name: String) -> void:
	# Metal can suspend drawing when another app is foreground; focus only this owned review window.
	DisplayServer.window_move_to_foreground()
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/display-settings-" + name + "-" + language + ".png")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=", 1)
	load("res://scripts/ui_text.gd").set_language(language)
	check(DisplayOptions.load_preferences() == DisplayOptions.DEFAULTS, "new preferences use the existing window size and VSync defaults")
	var damaged := {"mode":"exclusive", "window_size":Vector2i(1,1), "screen":99, "vsync":"yes", "frame_limit":-1}
	check(DisplayOptions.sanitize(damaged) == DisplayOptions.DEFAULTS, "damaged or unsupported choices fall back safely")
	check(DisplayOptions.sanitize({"window_size":Vector2(1920,1080),"frame_limit":60.0}).window_size == DisplayOptions.DEFAULT_SIZE, "wrong preference types are refused")
	check(DisplayOptions.fitted_size(Vector2i(3840,2160),Vector2i(1400,850)) == Vector2i(1400,850), "an oversized window fits the usable desktop")
	Settings.set_value("interface","language","ru")
	Settings.set_value("interface","ui_size",125)
	Settings.set_value("sound","mute",true)
	Settings.set_value("keys","pause",KEY_B)
	Settings.set_value("game","autosave_minutes",10)
	Settings.set_value("game","fullscreen",true)
	check(DisplayOptions.load_preferences().mode == "fullscreen", "the earlier fullscreen preference migrates")
	var saved := {"mode":"windowed", "window_size":Vector2i(1280,720), "screen":0, "vsync":false, "frame_limit":60}
	check(DisplayOptions.commit(saved) == OK and DisplayOptions.load_preferences() == saved, "confirmed display choices persist and reload")
	check(Settings.get_value("interface","language","") == "ru" and Settings.get_value("interface","ui_size",0) == 125 and Settings.get_value("sound","mute",false) and Settings.get_value("keys","pause",0) == KEY_B and Settings.get_value("game","autosave_minutes",0) == 10, "confirmation preserves language, interface, sound, keys and gameplay preferences")
	check(not Settings.get_value("game","fullscreen",true), "the earlier fullscreen flag agrees with the new window mode")
	Settings.set_value("keys","pause",KEY_SPACE)
	TranslationServer.set_locale("ru")
	for text in ["Display settings", "Display settings…", "Window mode", "Windowed", "Display", "Window size", "Frame-rate limit", "Unlimited", "VSync", "Fit to display", "Keep changes", "Revert", "Keep these display settings? Reverting in %d seconds.", "Fullscreen uses your desktop resolution. Window sizes fit the selected display. Apply previews for 15 seconds.", "Could not save display settings. Revert to try again."]:
		check(TranslationServer.translate(text) != text, "Russian display text: " + text)
	TranslationServer.set_locale(language)
	if DisplayServer.get_name() == "headless": finish(); return
	var original := DisplayOptions.capture(root)
	DisplayOptions.apply(root, DisplayOptions.DEFAULTS)
	await frames()
	var choices: Array = DisplayOptions.available_sizes(root.current_screen, root.size)
	var usable := DisplayOptions.usable_size(root.current_screen)
	check(choices.size() >= 2 and choices.all(func(s): return s.x <= usable.x and s.y <= usable.y), "window choices fit the actual monitor: " + str(choices))
	check(DisplayOptions.screen_index(99) == root.current_screen, "a disconnected saved monitor falls back to the current display")
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
	city.orbit.enabled = false
	var native_before: Dictionary = city.core.simulation.snapshot(true)
	var native_digest: String = city.core.simulation.replay(0).digest
	var pose := [city.orbit.target,city.orbit.yaw,city.orbit.pitch,city.orbit.distance]
	var queue_before: Array = city.core.commands.duplicate(true)
	city.game_action("display")
	await frames()
	var dialog: Window
	for child in city.hud.get_children():
		if child is Window and child.get("preview_options") != null: dialog = child
	check(dialog != null and dialog.visible and dialog.choices.size() == 4 and root.get_node("UiAccess").dialog_open, "Game menu opens display settings and shields camera keys")
	await capture("options")
	var before := DisplayOptions.capture(root)
	var hash := file_hash()
	var chosen := Vector2i(1280,720)
	var size_button: OptionButton = dialog.choices.window_size
	for index in size_button.item_count:
		if size_button.get_item_metadata(index) == chosen: size_button.select(index)
	dialog.choices.frame_limit.select(2); dialog.vsync.button_pressed = false
	check(same_window(before) and file_hash() == hash, "editing choices does not alter the window or write preferences")
	await click(dialog.get_ok_button(), dialog)
	check(dialog.pending and root.size == chosen and Engine.max_fps == 60 and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "real Apply click previews window size, frame limit and VSync")
	check(file_hash() == hash and dialog.get_ok_button().text == tr("Keep changes"), "preview is uncommitted and asks to keep it")
	await check_picking("window resizing")
	await capture("preview")
	await click(dialog.get_cancel_button(), dialog)
	check(same_window(before) and file_hash() == hash, "real Revert restores mode, size, position, border, frame limit and VSync without writing")
	if not is_instance_valid(dialog): dialog = DisplayDialog.open(city.hud)
	else: dialog.popup_centered()
	await frames()
	# The same explicit preview, allowed to expire on real wall-clock time.
	dialog.choices.frame_limit.select(1)
	dialog.apply_or_keep()
	await create_timer(DisplayDialog.PREVIEW_SECONDS + .4).timeout
	await frames()
	check(not dialog.pending and same_window(before) and file_hash() == hash, "15-second wall-clock expiry restores the previous window while the city is paused")
	dialog.choices.frame_limit.select(3)
	dialog.apply_or_keep(); await frames()
	await click(dialog.get_ok_button(), dialog)
	check(not is_instance_valid(dialog) and DisplayOptions.load_preferences().frame_limit == 120 and Engine.max_fps == 120 and file_hash() != hash, "real Keep click saves only confirmed settings")
	# Simulate the next startup from the saved settings, after perturbing the runtime.
	Engine.max_fps = 30
	DisplayOptions.startup(root); await frames()
	check(Engine.max_fps == 120 and root.size == DisplayOptions.load_preferences().window_size, "startup reapplies the saved resolution and frame cap")
	before = DisplayOptions.capture(root); hash = file_hash()
	dialog = DisplayDialog.open(city.hud); await frames()
	dialog.choices.mode.select(1); dialog.update_mode()
	check(dialog.choices.window_size.disabled, "fullscreen clearly uses desktop resolution instead of a window size")
	dialog.apply_or_keep()
	await create_timer(2.0).timeout
	await frames()
	check(root.mode == Window.MODE_FULLSCREEN and root.size == DisplayServer.screen_get_size(root.current_screen), "fullscreen preview fills the actual desktop: " + str(root.size))
	await check_picking("fullscreen sizing")
	await capture("fullscreen")
	dialog.revert(); await create_timer(2.0).timeout; await frames()
	check(same_window(before) and not root.borderless and file_hash() == hash, "leaving fullscreen restores the decorated window and its exact geometry")
	dialog.cancel(); await frames()
	dialog = DisplayDialog.open(city.hud); await frames()
	dialog.choices.mode.select(1); dialog.apply_or_keep()
	await create_timer(2.0).timeout; await frames()
	await click(dialog.get_ok_button(), dialog)
	check(DisplayOptions.load_preferences().mode == "fullscreen" and DisplayOptions.load_preferences().window_size == before.window_size, "confirmed fullscreen preserves the chosen window size for the way back")
	var fullscreen_key := InputEventKey.new(); fullscreen_key.physical_keycode = KEY_ENTER; fullscreen_key.keycode = KEY_ENTER; fullscreen_key.alt_pressed = true; fullscreen_key.pressed = true
	root.push_input(fullscreen_key,true)
	await create_timer(2.0).timeout; await frames()
	check(root.mode == Window.MODE_WINDOWED and root.size == before.window_size and not root.borderless and DisplayOptions.load_preferences().mode == "windowed", "the existing fullscreen shortcut restores the chosen decorated window and persists its mode")
	hash = file_hash()
	# Move only this review window to a second display, then restore its original geometry.
	if DisplayServer.get_screen_count() > 1:
		dialog = DisplayDialog.open(city.hud); await frames()
		var second: int = (root.current_screen + 1) % DisplayServer.get_screen_count()
		dialog.choices.screen.select(second)
		dialog.refresh_sizes(dialog.selected_size())
		dialog.apply_or_keep(); await frames()
		check(root.current_screen == second and DisplayServer.screen_get_usable_rect(second).encloses(Rect2i(root.position,root.size)), "preview moves the game window onto the selected monitor")
		dialog.revert(); await frames()
		check(same_window(before) and file_hash() == hash, "monitor preview reverts to the original monitor and geometry")
		dialog.cancel(); await frames()
	dialog = DisplayDialog.open(city.hud); await frames()
	dialog.choices.frame_limit.select(1); dialog.apply_or_keep(); await frames()
	var escape := InputEventKey.new(); escape.physical_keycode = KEY_ESCAPE; escape.keycode = KEY_ESCAPE; escape.pressed = true
	root.push_input(escape, true); await frames()
	check(same_window(before) and file_hash() == hash and not is_instance_valid(dialog), "Escape closes the preview and restores settings without sending a city action")
	dialog = DisplayDialog.open(city.hud); await frames()
	dialog.choices.frame_limit.select(1)
	await click(dialog.get_cancel_button(), dialog)
	check(not is_instance_valid(dialog) and same_window(before) and file_hash() == hash, "Cancel before Apply closes without changing settings")
	for scales in [Vector2i(100,100),Vector2i(125,130)]:
		root.get_node("UiAccess").apply(scales.x,scales.y)
		dialog = DisplayDialog.open(city.hud); await frames()
		check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(Rect2(Vector2(dialog.position),Vector2(dialog.size))), "display dialog fits at interface/text sizes " + str(scales))
		await capture("large" if scales.x == 125 else "windowed")
		dialog.cancel(); await frames()
	root.get_node("UiAccess").apply(100,100)
	dialog = DisplayDialog.open(city.hud); await frames()
	dialog.choices.frame_limit.select(1); dialog.apply_or_keep(); await frames()
	dialog.queue_free(); await frames()
	check(same_window(before) and not root.get_node("UiAccess").dialog_open, "removing a preview dialog restores the runtime and releases input shielding")
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(city.core.simulation.replay(0).digest == native_digest and after.money == native_before.money and after.time == native_before.time and after.walkers == native_before.walkers and after.buildings == native_before.buildings and city.core.commands == queue_before and [city.orbit.target,city.orbit.yaw,city.orbit.pitch,city.orbit.distance] == pose, "display changes preserve native state, pending commands and camera pose")
	DisplayOptions.restore(root, original)
	finish()

func finish() -> void:
	print("DISPLAY_SETTINGS_VALIDATION ", "PASS" if okay else "FAIL", " checks=",checks)
	quit(0 if okay else 1)
