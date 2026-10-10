extends RefCounted
# The original Zeus: Master of Olympus keys in the city (the Zeus guide's hotkey list), as rebindable controls of `KeyBindings`:
# the build tabs (1-0 in the Classic layout; Shift and a digit in this game's own, as in the SDL view), switching views, the city map,
# a second pause key, the game speed, quarter turns and facing north, map bookmarks, company keys, holding a footprint in place, a
# screenshot, the old window sizes and leaving the game. Presentation only: the city is reached through the commands it always had.
# `main.gd` asks `handle(city, event)` once per key press, before its own keys; the city (main.gd) is passed in, never kept.

const KeyBindings = preload("res://scripts/key_bindings.gd")
const RoadDrag = preload("res://scripts/road_drag.gd")
const DisplayOptions = preload("res://scripts/display_settings.gd")

# The original game's tabs (1-9, 0) and the categories of this game's Build menu each one opens; a second press goes on to the next
# category of the tab that the city can build, and past the last one the tray closes. "-" (the Overview tab) opens the City window.
const TABS := [
	["Housing and roads"],
	["Agriculture"],
	["Industry"],
	["Storage", "Trade", "Markets"],
	["Health and water", "Administration and security"],
	["Administration and security"],
	["Culture", "Science"],
	["Sanctuaries", "Heroes' halls", "Pyramids", "Shrines"],
	["Walls and defence"],
	["Gardens and monuments"],
]
const DIGITS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
const WINDOWS := {"window_800": Vector2i(800, 600), "window_1024": Vector2i(1024, 768)}
const NOWHERE := Vector2i(99999, 99999)

var last_overlay := "water"
# Bookmarks by city name: {name: {slot: {target, yaw, pitch, distance}}}; they last for the session, like the company keys.
var bookmarks: Dictionary = {}
# Company keys: {slot: banner id}. Banner ids are the session's, so the keys are forgotten when another city opens.
var companies: Dictionary = {}
var company_city := ""
var frozen_cell := NOWHERE
var frozen_mode := ""
var quit_dialog: ConfirmationDialog
var screenshot_folder := ""    # tests point this at a scratch folder

# True when the key was one of these controls (the city then does nothing more with it).
func handle(city: Node, event: InputEventKey) -> bool:
	for slot in range(1, 11):
		if KeyBindings.matches(event, "category_%d" % slot):
			open_tab(city, slot)
			return true
	for slot in range(1, 5):
		if KeyBindings.matches(event, "bookmark_set_%d" % slot):
			set_bookmark(city, slot)
			return true
		if KeyBindings.matches(event, "bookmark_go_%d" % slot):
			go_to_bookmark(city, slot)
			return true
	for slot in range(1, 6):
		if KeyBindings.matches(event, "company_set_%d" % slot):
			set_company(city, slot)
			return true
		if KeyBindings.matches(event, "company_select_%d" % slot):
			choose_company(city, slot)
			return true
	if KeyBindings.matches(event, "pause_alt"):
		city.core.send("pause %d" % (0 if city.state.get("paused", true) else 1))
		return true
	if KeyBindings.matches(event, "speed_up") or KeyBindings.matches(event, "speed_down"):
		change_speed(city, 1 if KeyBindings.matches(event, "speed_up") else -1)
		return true
	if KeyBindings.matches(event, "rotate_left") or KeyBindings.matches(event, "rotate_right"):
		city.orbit.turn_quarter(-1 if KeyBindings.matches(event, "rotate_left") else 1)
		return true
	if KeyBindings.matches(event, "face_north"):
		city.orbit.face_north()
		return true
	if KeyBindings.matches(event, "switch_view"):
		switch_view(city)
		return true
	if KeyBindings.matches(event, "overview_map"):
		city.hud.set_minimap_open(not city.hud.get_node("%MinimapPanel").visible, true)
		return true
	if KeyBindings.matches(event, "freeze_footprint"):
		toggle_freeze(city)
		return true
	if KeyBindings.matches(event, "screenshot"):
		take_screenshot(city)
		return true
	if KeyBindings.matches(event, "quit_game"):
		ask_quit(city)
		return true
	for id in WINDOWS:
		if KeyBindings.matches(event, id):
			set_window(city, WINDOWS[id])
			return true
	# This game's own layout keeps the digits for the overlays; Shift and a digit (or -) opens a tab, as in the SDL view.
	if event.shift_pressed and not (event.ctrl_pressed or event.meta_pressed or event.alt_pressed):
		var key := int(event.physical_keycode) if int(event.physical_keycode) != 0 else int(event.keycode)
		if key in DIGITS:
			open_tab(city, DIGITS.find(key) + 1)
			return true
		if key == KEY_MINUS:
			city.game_action("city")
			return true
	return false

# ---- the build tabs -----------------------------------------------------------------------------------------------------
func open_tab(city: Node, slot: int) -> void:
	var hud: Control = city.hud
	var titles: Array = TABS[slot - 1].filter(func(title): return hud.category_buttons.has(title) and not hud.category_buttons[title].disabled)
	if titles.is_empty():
		city.hint.text = tr("Nothing in this tab can be built in this city now.")
		return
	var at: int = titles.find(hud.active_category) if hud.get_node("%BuildTray").visible else -1
	if at < 0:
		hud.open_category(titles[0])
	elif at + 1 < titles.size():
		hud.open_category(titles[at + 1])
	else:
		hud.close_build_tray()

# ---- views, the map and the clock -----------------------------------------------------------------------------------------
func switch_view(city: Node) -> void:
	if city.overlay_view.mode != "normal":
		city.set_overlay("normal")
	else:
		city.set_overlay(last_overlay)

func change_speed(city: Node, step: int) -> void:
	var speed := clampi(maxi(1,int(city.state.get("speed", 1))) + step, 1, 3)
	city.core.send("speed %d" % speed)
	city.state["speed"] = speed
	city.hud.set_speed(speed)
	city.hint.text = tr(city.hud.SPEEDS[speed - 1])

# ---- bookmarks --------------------------------------------------------------------------------------------------------------
func city_name(city: Node) -> String:
	return str(city.hud.city_header.get("name", ""))

func set_bookmark(city: Node, slot: int) -> void:
	var marks: Dictionary = bookmarks.get(city_name(city), {})
	marks[slot] = {"target": city.orbit.target, "yaw": city.orbit.yaw, "pitch": city.orbit.pitch, "distance": city.orbit.distance}
	bookmarks[city_name(city)] = marks
	city.hint.text = tr("Bookmark %d set. %s comes back here.") % [slot, KeyBindings.label("bookmark_go_%d" % slot)]

func go_to_bookmark(city: Node, slot: int) -> void:
	var marks: Dictionary = bookmarks.get(city_name(city), {})
	if not marks.has(slot):
		city.hint.text = tr("Bookmark %d is not set yet: %s sets it.") % [slot, KeyBindings.label("bookmark_set_%d" % slot)]
		return
	var mark: Dictionary = marks[slot]
	var orbit: Node3D = city.orbit
	orbit.cancel_wheel_zoom()
	orbit.turn_goal = NAN
	orbit.target = mark.target
	orbit.yaw = mark.yaw
	orbit.pitch = mark.pitch
	orbit.distance = clampf(mark.distance, orbit.MINIMUM_DISTANCE, orbit.maximum_distance)
	orbit.clamp_target()
	orbit.snap_to_ground()
	orbit.refresh()
	city.hint.text = tr("Bookmark %d") % slot

# ---- company keys -----------------------------------------------------------------------------------------------------------
func _company_scope(city: Node) -> void:
	if company_city != city_name(city):
		company_city = city_name(city)
		companies.clear()

func set_company(city: Node, slot: int) -> void:
	_company_scope(city)
	var panel = city.army_panel
	if panel == null or not panel.visible or panel.selected_id < 0:
		city.hint.text = tr("Choose a company first: click its banner or pick it in the Army panel.")
		return
	companies[slot] = int(panel.selected_id)
	city.hint.text = tr("%s chooses this company now.") % KeyBindings.label("company_select_%d" % slot)

func choose_company(city: Node, slot: int) -> void:
	_company_scope(city)
	var banner := {}
	for candidate in city.banners:
		if int(candidate.id) == int(companies.get(slot, -1)):
			banner = candidate
	if banner.is_empty():
		companies.erase(slot)
		city.hint.text = tr("No company has key %d: choose one and press %s.") % [slot, KeyBindings.label("company_set_%d" % slot)]
		return
	if not city.army_panel.visible:
		city.open_army()
	city.army_panel.select(int(banner.id))
	if not bool(banner.get("abroad", false)):
		city.jump_to_cell(Vector2(int(banner.x), int(banner.y)))

# ---- holding a footprint in place (the original game's M for sanctuaries too large to see whole) -------------------------------
func placing(city: Node) -> bool:
	var tool: String = city.mode
	return tool not in ["select", "demolish", "road", "wall"] and tool not in RoadDrag.AREA_TOOLS and tool not in RoadDrag.PATH_TOOLS

# While held, the placement stays on its tile whatever the pointer does, so the camera can look around it; a click builds there.
func holds_placement(city: Node) -> bool:
	if frozen_mode == "":
		return false
	if frozen_mode != city.mode or not city.tiles.has(frozen_cell):
		release_placement()
		return false
	return true

func release_placement() -> void:
	frozen_mode = ""
	frozen_cell = NOWHERE

func toggle_freeze(city: Node) -> void:
	if holds_placement(city):
		release_placement()
		city.hint.text = tr("The placement follows the pointer again.")
		return
	if not placing(city) or not city.tiles.has(city.picked):
		city.hint.text = tr("Choose a building and point at its place first.")
		return
	frozen_mode = city.mode
	frozen_cell = city.picked
	city.hint.text = tr("The placement holds its place: look around, click to build there, %s lets it go.") % KeyBindings.label("freeze_footprint")

# ---- the screen, the window and leaving -------------------------------------------------------------------------------------
func take_screenshot(city: Node) -> void:
	await RenderingServer.frame_post_draw
	var folder := screenshot_folder
	if folder == "":
		folder = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join("eZeus") if KeyBindings.uses_player_settings() else ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("eZeus %s.png" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", " "))
	var error := city.get_viewport().get_texture().get_image().save_png(path)
	city.hint.text = (tr("Screenshot saved: %s") % path) if error == OK else tr("The screenshot could not be saved.")

func set_window(city: Node, size: Vector2i) -> void:
	var window: Window = city.get_tree().root
	var options := DisplayOptions.capture(window)
	options.mode = "windowed"
	options.window_size = size
	DisplayOptions.commit(DisplayOptions.apply(window, options))
	city.hint.text = tr("Window %d × %d") % [size.x, size.y]

func ask_quit(city: Node) -> void:
	if is_instance_valid(quit_dialog):
		return
	var was_running: bool = not city.state.get("paused", true)
	if was_running:
		city.core.send("pause 1")
	quit_dialog = ConfirmationDialog.new()
	quit_dialog.title = tr("Exit the game")
	quit_dialog.dialog_text = tr("Leave the game now? Anything not saved is lost.")
	quit_dialog.ok_button_text = tr("Exit")
	quit_dialog.cancel_button_text = tr("Cancel")
	city.hud.add_child(quit_dialog)
	quit_dialog.confirmed.connect(func(): city.get_tree().quit())
	var stay := func():
		if was_running and is_instance_valid(city):
			city.core.send("pause 0")
		if is_instance_valid(quit_dialog):
			quit_dialog.queue_free()
	quit_dialog.canceled.connect(stay)
	quit_dialog.close_requested.connect(stay)
	quit_dialog.popup_centered(Vector2i(420, 160))
