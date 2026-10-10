extends RefCounted
# The original Zeus keys in the running city (windowed; scratch settings only): this game's own layout gives the ones that clash with nothing
# (the speed, the quarter turns, the bookmarks, the companies, the second pause key, the screenshot, leaving) and opens the build tabs with
# Shift and a digit; the Classic layout gives the Zeus guide's whole list (1-0 the tabs, - the City window, Space switching views, P pausing,
# Tab the map, Home north, M holding a footprint). Every key is pressed as the player presses it, through main.gd's own input.
# Run alone by review_original_keys.gd (tools/review_original_keys.py) and inside the full --validate run.

const KeyBindings = preload("res://scripts/key_bindings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")

var city
var checks := 0
var okay := true

func check(condition: bool, message: String) -> void:
	checks += 1
	okay = okay and condition
	city.check(condition, message)

func key(code: int, modifiers := 0) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = (code & KEY_CODE_MASK) as Key
	event.keycode = event.physical_keycode
	event.pressed = true
	event.ctrl_pressed = bool(modifiers & KEY_MASK_CTRL)
	event.alt_pressed = bool(modifiers & KEY_MASK_ALT)
	event.shift_pressed = bool(modifiers & KEY_MASK_SHIFT)
	return event

func press(code: int, modifiers := 0) -> void:
	city._unhandled_input(key(code, modifiers))
	await city.get_tree().process_frame

func tray_title() -> String:
	return city.hud.active_category if city.hud.get_node("%BuildTray").visible else ""

func run(scene) -> bool:
	city = scene
	var previous_path: Variant = Engine.get_meta("ezeus_settings_path", "")
	var had_path := Engine.has_meta("ezeus_settings_path")
	var scratch := ProjectSettings.globalize_path("res://captures/validation-original-keys-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_settings_path", scratch.path_join("settings.cfg"))
	KeyBindings.reload()
	PlaySettings.reload()
	KeyBindings.apply_input_map()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	city.set_tool("select")
	city.hud.close_build_tray()

	# ---------------------------------------------------------------------------------- this game's own layout
	await press(KEY_1, KEY_MASK_SHIFT)
	check(tray_title() == "Housing and roads" and city.overlay_view.mode == "normal", "Shift+1 opens the Population tab (housing and roads), not an overlay")
	await press(KEY_1, KEY_MASK_SHIFT)
	check(tray_title() == "", "pressing it again closes the tray")
	var distribution: Array = []
	for step in 4:
		await press(KEY_4, KEY_MASK_SHIFT)
		distribution.append(tray_title())
	var expected: Array = ["Storage", "Trade", "Markets"].filter(func(title): return city.hud.category_buttons.has(title) and not city.hud.category_buttons[title].disabled)
	expected.append("")
	check(distribution.slice(0, expected.size()) == expected, "Shift+4 goes through the Distribution tab's categories the city has, then closes %s" % str(distribution))
	city.hud.close_build_tray()
	var speed := int(city.state.get("speed", 0))
	await press(KEY_BRACKETRIGHT)
	for frame in 6: await city.get_tree().process_frame
	check(int(city.state.get("speed", -1)) == mini(speed + 1, 3) and city.hud.speed_buttons[mini(speed + 1, 3) - 1].button_pressed, "] makes the game faster (speed %d)" % int(city.state.get("speed", -1)))
	await press(KEY_BRACKETLEFT)
	for frame in 6: await city.get_tree().process_frame
	check(int(city.state.get("speed", -1)) == speed, "[ makes it slower again")
	var orbit: Node3D = city.orbit
	var yaw_before: float = orbit.yaw
	var target_before: Vector3 = orbit.target
	orbit.yaw = 45.0
	await press(KEY_PAGEDOWN)
	check(is_equal_approx(fposmod(orbit.turn_goal, 360.0), 135.0), "PgDn turns the city a quarter (towards 135 degrees)")
	await press(KEY_PAGEUP)
	await press(KEY_PAGEUP)
	check(is_equal_approx(fposmod(orbit.turn_goal, 360.0), 315.0), "PgUp twice turns it back and a quarter the other way")
	for step in 240: orbit.step_turn(1.0 / 60.0)
	check(is_nan(orbit.turn_goal) and is_equal_approx(orbit.yaw, 315.0), "and the view settles on the quarter (%.1f)" % orbit.yaw)
	# Bookmarks: Ctrl+F1 remembers the view, Alt+F1 (F1 in the Classic layout) comes back to it.
	orbit.target = Vector3(3, 0, -4)
	orbit.distance = 21.0
	orbit.refresh()
	await press(KEY_F1, KEY_MASK_CTRL)
	var marked: Vector3 = orbit.target
	orbit.target = Vector3(-9, 0, 7)
	orbit.distance = 40.0
	orbit.yaw = 100.0
	orbit.refresh()
	await press(KEY_F1, KEY_MASK_ALT)
	check(Vector2(orbit.target.x - marked.x, orbit.target.z - marked.z).length() < .01 and is_equal_approx(orbit.distance, 21.0) and is_equal_approx(orbit.yaw, 315.0), "Ctrl+F1 sets a bookmark and Alt+F1 returns to it")
	await press(KEY_F2, KEY_MASK_ALT)
	check(city.hint.text.contains("2"), "an unset bookmark says how to set it: %s" % city.hint.text)
	# Company keys.
	if not city.banners.is_empty():
		var banner: Dictionary = city.banners[0]
		if not city.army_panel.visible: city.open_army()
		city.army_panel.select(int(banner.id))
		await press(KEY_1, KEY_MASK_CTRL)
		city.army_panel.close()
		city.army_panel.selected_id = -1
		await press(KEY_1, KEY_MASK_ALT)
		check(city.army_panel.visible and city.army_panel.selected_id == int(banner.id), "Ctrl+1 gives the chosen company a key and Alt+1 chooses it again (%s)" % str(banner.get("name", "")))
		city.army_panel.close()
	await press(KEY_3, KEY_MASK_ALT)
	check(not city.army_panel.visible and city.hint.text.contains("3"), "a company key nobody has says so: %s" % city.hint.text)
	# The second pause key.
	await press(KEY_P)
	for frame in 8: await city.get_tree().process_frame
	var resumed: bool = not city.state.get("paused", true)
	await press(KEY_P)
	for frame in 8: await city.get_tree().process_frame
	check(resumed and city.state.get("paused", false), "P pauses and resumes as Space does")
	# A screenshot, into a scratch folder.
	city.hotkeys.screenshot_folder = scratch
	await press(KEY_F12)
	for frame in 4: await city.get_tree().process_frame
	var shots: Array = Array(DirAccess.get_files_at(scratch)).filter(func(name): return name.ends_with(".png"))
	check(shots.size() == 1, "F12 saves a screenshot (%s)" % str(shots))
	city.hotkeys.screenshot_folder = ""
	# Leaving asks first; Cancel goes on playing.
	await press(KEY_X, KEY_MASK_ALT)
	var asked: bool = is_instance_valid(city.hotkeys.quit_dialog) and city.hotkeys.quit_dialog.visible
	if asked:
		city.hotkeys.quit_dialog.canceled.emit()
	await city.get_tree().process_frame
	check(asked and not city.get_tree().paused and city.mode == "select", "Alt+X asks before leaving the game, and Cancel stays")

	# ---------------------------------------------------------------------------------- the Classic Zeus layout
	KeyBindings.set_layout("classic")
	city.hud.retranslate()
	city.set_overlay("normal")
	await press(KEY_1)
	check(tray_title() == "Housing and roads" and city.overlay_view.mode == "normal", "Classic: 1 opens the Population tab")
	await press(KEY_8)
	check(tray_title() in ["Sanctuaries", "Heroes' halls", "Pyramids", "Shrines", ""], "Classic: 8 opens the Mythology tab (%s)" % tray_title())
	city.hud.close_build_tray()
	city.set_overlay("hygiene")
	city.set_overlay("normal")
	await press(KEY_SPACE)
	check(city.overlay_view.mode == "hygiene", "Classic: Space switches to the last overlay")
	await press(KEY_SPACE)
	check(city.overlay_view.mode == "normal", "and back to the normal view")
	var map_open: bool = city.hud.get_node("%MinimapPanel").visible
	await press(KEY_TAB)
	check(city.hud.get_node("%MinimapPanel").visible != map_open, "Classic: Tab shows or hides the city map")
	await press(KEY_TAB)
	orbit.yaw = 200.0
	await press(KEY_HOME)
	check(is_equal_approx(orbit.turn_goal, orbit.NORTH_YAW), "Classic: Home faces north")
	orbit.turn_goal = NAN
	await press(KEY_F1)
	check(city.hint.text.contains("1"), "Classic: F1 goes to bookmark 1 (%s)" % city.hint.text)
	# M holds a footprint in place while the camera looks around.
	var tool := ""
	for group in city.hud.build_groups:
		for item in group.items:
			if tool == "" and int(item.w) >= 2 and str(item.name) not in ["road", "wall", "house", "elite_house", "park"] and not str(item.name).contains(":"):
				tool = str(item.name)
	if tool != "":
		city.set_tool(tool)
		var view: Vector2 = city.get_viewport().get_visible_rect().size
		city.pick_tile(view * .5)
		var held: Vector2i = city.picked
		await press(KEY_M)
		city.pick_tile(view * Vector2(.2, .7))
		check(city.picked == held and city.hotkeys.holds_placement(city), "Classic: M holds the %s placement on its tile while the pointer moves" % tool)
		await press(KEY_M)
		city.pick_tile(view * Vector2(.2, .7))
		check(not city.hotkeys.holds_placement(city) and city.picked != held, "and M lets it follow the pointer again")
		city.set_tool("select")
	await press(KEY_MINUS)
	await city.get_tree().create_timer(.3).timeout
	var windows: Array = city.hud.get_children().filter(func(child): return child is Window and child.visible and child.title == city.tr("City"))
	check(windows.size() == 1, "Classic: - opens the City window (the overview)")
	for window in windows: window.queue_free()
	await city.get_tree().process_frame
	await press(KEY_P)
	for frame in 8: await city.get_tree().process_frame
	var classic_running: bool = not city.state.get("paused", true)
	await press(KEY_P)
	for frame in 8: await city.get_tree().process_frame
	check(classic_running and city.state.get("paused", false), "Classic: P pauses and resumes")

	# ---------------------------------------------------------------------------------- everything back
	KeyBindings.set_layout("ezeus")
	orbit.yaw = yaw_before
	orbit.target = target_before
	orbit.distance = 33.0
	orbit.refresh()
	city.core.send("speed %d" % speed)
	if had_path:
		Engine.set_meta("ezeus_settings_path", previous_path)
	else:
		Engine.remove_meta("ezeus_settings_path")
	for name in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(name))
	DirAccess.remove_absolute(scratch)
	KeyBindings.reload()
	PlaySettings.reload()
	KeyBindings.apply_input_map()
	city.hud.retranslate()
	print("ORIGINAL_KEYS_CHECKS ", "PASS" if okay else "FAIL", " checks=", checks)
	return okay
