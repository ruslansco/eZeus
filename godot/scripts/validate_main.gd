extends RefCounted
const UiText = preload("res://scripts/ui_text.gd")
var UiTextLanguages: Array = UiText.languages()
# Windowed integration checks (--validate), moved out of main.gd: camera controls and picking, construction,
# demolition and undo against the embedded core, then the inspector, terrain, elevation, detail and map-polish
# suites. `city` is the running main.gd scene; checks drive it exactly as a player would and read its state.
# main.gd calls run(self) from _process once the first snapshot has arrived.

var city

func run(scene: Node3D) -> void:
	city = scene
	await run_checks()

func run_construction_checks() -> bool:
	var okay := true
	var candidate := Vector2i(99999, 99999)
	var nearest := INF
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		var distance: float = city.world_position(point.x, point.y, 0).distance_squared_to(city.orbit.target)
		if distance >= nearest:
			continue
		var query: Dictionary = city.core.query("preview hospital %d %d 3" % [point.x, point.y])
		if query.get("valid", false):
			candidate = point
			nearest = distance
	okay = city.check(candidate != Vector2i(99999, 99999), "native hospital query finds a free footprint near the city") and okay
	if candidate == Vector2i(99999, 99999):
		return false
	var original_target: Vector3 = city.orbit.target
	var original_yaw: float = city.orbit.yaw
	var original_distance: float = city.orbit.distance
	var original_facing = city.orientation
	city.orbit.target = city.world_position(candidate.x + 1.5, candidate.y + 1.5, city.tiles[candidate][2])
	city.orbit.distance = 26
	city.set_tool("hospital")
	city.orientation = 3
	for angle in [0.0, 90.0, 180.0, 270.0]:
		city.orbit.yaw = angle
		city.orbit.refresh()
		await city.get_tree().physics_frame
		var screen: Vector2 = city.orbit.camera.unproject_position(city.world_position(candidate.x, candidate.y, city.tiles[candidate][2]))
		city.pick_tile(screen)
		okay = city.check(city.picked == candidate and city.placement_result.get("valid", false) and city.ghost.get_child_count() > 0 and city.footprint_cells.get_child_count() == 16, "real hospital ghost and native footprint at %d degrees" % angle) and okay
	var quoted_cost: int = city.placement_result.cost
	var money_before: int = city.state.money
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = city.orbit.camera.unproject_position(city.world_position(candidate.x, candidate.y, city.tiles[candidate][2]))
	city._unhandled_input(click)
	await city.get_tree().create_timer(.5).timeout
	var placed := false
	for building in city.state.buildings:
		placed = placed or (building.x == candidate.x and building.y == candidate.y and building.asset == "hospital" and int(building.orientation) == 3)
	okay = city.check(placed and int(city.state.money) == money_before - quoted_cost, "click builds the queried model with matching cost and facing") and okay
	city.set_tool("select")
	city._unhandled_input(click)
	okay = city.check(city.inspector.visible and city.inspector_text.text.contains(city.tr("Workers:")), "click inspection shows live native hospital employment") and okay
	var undo := InputEventKey.new()
	undo.physical_keycode = KEY_Z
	undo.ctrl_pressed = true
	undo.pressed = true
	city._unhandled_input(undo)
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(int(city.state.money) == money_before and city.undo_button.disabled, "Ctrl Z refunds construction and updates the undo button") and okay
	# Put a 2x2 house within the 4x4 footprint, then check individual blocked cells.
	city.core.send("build house %d %d 0" % [candidate.x, candidate.y])
	await city.get_tree().create_timer(.4).timeout
	city.set_tool("hospital")
	city.picked = candidate
	city.refresh_placement()
	var blocked := 0
	for cell in city.placement_result.tiles:
		if not cell[3]:
			blocked += 1
	okay = city.check(not city.placement_result.valid and blocked == 4 and city.footprint_cells.get_child_count() == 16, "native query highlights only the four obstructed tiles") and okay
	var before_rejection: int = city.state.money
	city._unhandled_input(click)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(int(city.state.money) == before_rejection, "blocked click cannot charge the treasury") and okay
	city.set_tool("demolish")
	city._unhandled_input(click)
	await city.get_tree().create_timer(.4).timeout
	var free: Dictionary = city.core.query("preview hospital %d %d 0" % [candidate.x, candidate.y])
	okay = city.check(free.get("valid", false) and not city.state.get("undo_available", true), "demolition click frees native tiles and disables construction undo") and okay
	var landmark := Vector2i(99999, 99999)
	for building in city.state.buildings:
		var protected_query: Dictionary = city.core.query("preview demolish %d %d 0" % [int(building.x), int(building.y)])
		if protected_query.get("valid", false) and protected_query.get("confirmation_required", false):
			landmark = Vector2i(int(building.x), int(building.y))
			break
	okay = city.check(landmark != Vector2i(99999, 99999), "native protected landmark is available for the dialog") and okay
	if landmark != Vector2i(99999, 99999):
		city.orbit.target = city.world_position(landmark.x, landmark.y, city.tiles[landmark][2])
		city.orbit.distance = 26
		city.orbit.refresh()
		await city.get_tree().physics_frame
		click.position = city.orbit.camera.unproject_position(city.world_position(landmark.x, landmark.y, city.tiles[landmark][2]))
		city.set_tool("demolish")
		var before_cancel: int = city.state.money
		city._unhandled_input(click)
		okay = city.check(city.demolition_dialog.visible and not city.demolition_request.is_empty(), "landmark click opens the localized confirmation dialog") and okay
		city.demolition_dialog.get_cancel_button().pressed.emit()
		await city.get_tree().create_timer(.2).timeout
		okay = city.check(not city.demolition_dialog.visible and city.state.paused and int(city.state.money) == before_cancel, "cancel keeps the landmark and preserves an already-paused game") and okay
		city.core.send("pause 0")
		await city.get_tree().create_timer(.25).timeout
		city._unhandled_input(click)
		await city.get_tree().create_timer(.3).timeout
		var modal_clock: int = city.state.time
		await city.get_tree().create_timer(.2).timeout
		okay = city.check(city.demolition_dialog.visible and city.state.paused and int(city.state.time) == modal_clock, "landmark dialog pauses a running native simulation") and okay
		city.demolition_dialog.get_cancel_button().pressed.emit()
		await city.get_tree().create_timer(.25).timeout
		okay = city.check(not city.demolition_dialog.visible and not city.state.paused, "dialog cancellation restores the prior running state") and okay
		city.core.send("pause 1")
		await city.get_tree().create_timer(.2).timeout
	city.orbit.yaw = original_yaw
	city.orbit.target = original_target
	city.orbit.distance = original_distance
	city.orbit.refresh()
	# Leave a visible ghost beside an inspector in the validation capture.
	city.set_tool("hospital")
	city.orientation = 1
	city.picked = candidate
	city.refresh_placement()
	city.inspected = Vector2i(int(city.state.focus[0]), int(city.state.focus[1]))
	city.refresh_inspection()
	okay = city.check(city.ghost.get_child_count() > 0 and city.inspector.visible, "localized inspector and imported model preview are visible") and okay
	city.orbit.yaw = original_yaw
	city.orbit.target = original_target
	city.orbit.distance = original_distance
	city.orbit.refresh()
	city.orientation = original_facing
	return okay

func world_to_tile_x(point: Vector3) -> float:
	return point.x + city.origin.x + (city.extent.x - 1) * .5

func world_to_tile_y(point: Vector3) -> float:
	return -point.z + city.origin.y + (city.extent.y - 1) * .5

func mouse_event(position: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	return event

func tile_screen(cell: Vector2i) -> Vector2:
	return city.orbit.camera.unproject_position(city.world_position(cell.x, cell.y, city.tiles[cell][2]))

# The minimap draws the city (terrain, roads, buildings), follows incremental changes, shows the camera footprint and
# moves the camera where it is clicked.
# Image colours are stored in 8 bits, so compare within a quantization step.
func same_colour(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < .01 and absf(a.g - b.g) < .01 and absf(a.b - b.b) < .01

func run_minimap_checks() -> bool:
	var okay := true
	var map: Control = city.hud.minimap
	okay = city.check(map.texture != null and map.terrain.get_size() == Vector2i(city.extent), "the minimap covers the whole map (%d x %d)" % [city.extent.x, city.extent.y]) and okay
	var water := Vector2i(99999, 99999)
	var road := Vector2i(99999, 99999)
	for cell in city.tiles:
		var tile: Array = city.tiles[cell]
		if water == Vector2i(99999, 99999) and int(tile[3]) & 4 and not int(tile[4]):
			water = cell
		if road == Vector2i(99999, 99999) and int(tile[4]) and not (int(tile[3]) & 4):
			road = cell
	var pixel := func(cell: Vector2i) -> Color: return map.composed.get_pixelv(Vector2i(cell.x - city.origin.x, city.extent.y - 1 - (cell.y - city.origin.y)))
	okay = city.check(same_colour(pixel.call(water), map.WATER_COLOUR) and same_colour(pixel.call(road), map.ROAD_COLOUR), "water and roads are drawn in their own colours") and okay
	var building: Dictionary = {}
	for entry in city.state.buildings:
		if not str(entry.asset) in ["native_marker", "terrain_road"] and int(entry.w) >= 2:
			building = entry
			break
	var building_pixel: Color = pixel.call(Vector2i(int(building.x), int(building.y)))
	okay = city.check(same_colour(building_pixel, map.HOUSE_COLOUR) or same_colour(building_pixel, map.BUILDING_COLOUR), "buildings are drawn over the ground") and okay
	# A new road appears and disappears with no rebuild of the whole map.
	var site := Vector2i(99999, 99999)
	for cell in city.tiles:
		if int(city.tiles[cell][5]) and not int(city.tiles[cell][4]) and not (int(city.tiles[cell][3]) & 4) and city.core.query("preview road %d %d 0" % [cell.x, cell.y]).get("valid", false):
			site = cell
			break
	var before_colour: Color = pixel.call(site)
	city.core.send("build road %d %d 0" % [site.x, site.y])
	await city.get_tree().create_timer(.5).timeout
	okay = city.check(same_colour(pixel.call(site), map.ROAD_COLOUR), "a newly built road appears on the minimap") and okay
	city.core.send("undo")
	await city.get_tree().create_timer(.5).timeout
	okay = city.check(same_colour(pixel.call(site), before_colour), "undoing it restores the ground") and okay
	# Clicking moves the camera; the point and cell conversions agree.
	var sample := Vector2(city.origin.x + city.extent.x * .3, city.origin.y + city.extent.y * .7)
	okay = city.check(map.point_to_cell(map.cell_to_point(sample)).distance_to(sample) < .02, "minimap points and tile coordinates convert both ways") and okay
	map.size = Vector2(220, 220)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map.cell_to_point(sample)
	map._gui_input(click)
	click.pressed = false
	map._gui_input(click)
	var target_cell: Vector2 = city.tile_coordinates(city.orbit.target)
	okay = city.check(target_cell.distance_to(sample) < .6 and absf(city.orbit.target.y - city.orbit.height_at(city.orbit.target.x, city.orbit.target.z)) < .01, "clicking the minimap moves the camera there, onto the ground") and okay
	city.orbit.refresh()
	city.hud.minimap.set_view(city.view_footprint())
	okay = city.check(map.view.size() >= 3 and Geometry2D.is_point_in_polygon(city.tile_coordinates(city.orbit.target), map.view), "the camera footprint outline contains the point the camera looks at") and okay
	return okay

# Saving and loading through the interface: the Game menu, a saved file in the per-user directory, the load dialog's list,
# quick save and the rotating autosave. (The restart that a load performs is covered by validate_load.gd.)
func run_save_checks() -> bool:
	var okay := true
	var directory: String = city.save_directory()
	var created: Array = []
	var stamp := "harness %d" % Time.get_ticks_usec()
	okay = city.check(city.hud.GAME_ACTIONS.all(func(action): return action.is_empty() or not city.hud.menu_action_text(action).is_empty()), "the Game menu offers save, load, the quick actions, the world map, the army, mythology, trade, sound and the main menu") and okay
	okay = city.check(city.sanitize_save_name("../a:b*c") == "..-a-b-c".trim_prefix("..") .trim_prefix("-") or city.sanitize_save_name("../a:b*c") != "", "unsafe characters are replaced in a typed save name") and okay
	okay = city.check(city.sanitize_save_name(".hidden") == "hidden" and city.sanitize_save_name("Сохранение 1") == "Сохранение 1" and city.sanitize_save_name("x".repeat(90)).length() == 64, "a save name loses leading dots, keeps other alphabets and stops at 64 letters") and okay
	city.hud.open_save_dialog(city.default_save_name())
	okay = city.check(city.hud.save_dialog.visible and city.hud.save_name.text != "", "the save dialog opens with a name drawn from the game date (%s)" % city.hud.save_name.text) and okay
	city.hud.save_dialog.hide()
	var money_before: int = city.state.money
	okay = city.check(city.save_game(stamp), "saving through the interface succeeds") and okay
	created.append(directory.path_join(stamp + ".ez"))
	okay = city.check(FileAccess.file_exists(created[0]) and FileAccess.open(created[0], FileAccess.READ).get_length() > 100000 and int(city.state.money) == money_before, "the save is a real file and saving does not change the city") and okay
	okay = city.check(city.hint.text.contains(stamp), "the hint confirms the save by name") and okay
	var entries: Array = city.list_saves()
	var found := false
	for entry in entries:
		found = found or entry.name == stamp
	okay = city.check(found and entries[0].name == stamp, "the load list shows it first (newest)") and okay
	var requested: Array = []
	var listener := func(path): requested.append(path)
	# Inspect the emitted load request here; the real callback replaces this city
	# and would destroy the rest of the running validation suite.
	city.hud.load_requested.disconnect(city.load_game)
	city.hud.load_requested.connect(listener)
	city.hud.open_load_dialog(entries)
	okay = city.check(city.hud.load_dialog.visible and city.hud.save_list.item_count == entries.size() and city.hud.save_list.get_selected_items() == PackedInt32Array([0]), "the load dialog lists the saves with the newest selected") and okay
	city.hud._confirm_load()
	okay = city.check(requested == [created[0]], "confirming the dialog asks to load that file") and okay
	city.hud.load_requested.disconnect(listener)
	city.hud.load_requested.connect(city.load_game)
	city.hud.load_dialog.hide()
	city.hud.open_load_dialog([])
	okay = city.check(city.hud.load_dialog.get_ok_button().disabled and city.hud.save_info.text == city.tr("No saved games yet"), "an empty list says so and cannot load") and okay
	city.hud.load_dialog.hide()
	okay = city.check(not city.save_game("   ..  ") and not FileAccess.file_exists(directory.path_join(".ez")), "an empty name is refused without writing anything") and okay
	# Autosave keeps three rotating slots.
	for slot in range(1, 4):
		DirAccess.remove_absolute(directory.path_join("autosave %d.ez" % slot))
	okay = city.check(city.autosave() and FileAccess.file_exists(directory.path_join("autosave 1.ez")) and not FileAccess.file_exists(directory.path_join("autosave 2.ez")), "the first autosave fills slot 1") and okay
	var first_size := FileAccess.open(directory.path_join("autosave 1.ez"), FileAccess.READ).get_length()
	city.autosave()
	city.autosave()
	city.autosave()
	okay = city.check(FileAccess.file_exists(directory.path_join("autosave 1.ez")) and FileAccess.file_exists(directory.path_join("autosave 2.ez")) and FileAccess.file_exists(directory.path_join("autosave 3.ez")) and not FileAccess.file_exists(directory.path_join("autosave 4.ez")) and FileAccess.open(directory.path_join("autosave 3.ez"), FileAccess.READ).get_length() == first_size, "older autosaves move down and only three are kept") and okay
	# The timer: only a running city counts down.
	city.autosave_age = 0.0
	var original_state: Dictionary = city.state
	okay = city.check(city.autosave_interval == city.AUTOSAVE_SECONDS and city.AUTOSAVE_SECONDS >= 120.0, "autosave runs every few minutes (%d s)" % int(city.AUTOSAVE_SECONDS)) and okay
	city.save_game("quicksave")
	created.append(directory.path_join("quicksave.ez"))
	for slot in range(1, 4):
		created.append(directory.path_join("autosave %d.ez" % slot))
	okay = city.check(FileAccess.file_exists(directory.path_join("quicksave.ez")), "quick save writes the quicksave slot") and okay
	for path in created:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	okay = city.check(Array(DirAccess.get_files_at(directory)).filter(func(file): return file.begins_with("harness") or file.begins_with("autosave") or file == "quicksave.ez").is_empty(), "the harness leaves no saves behind") and okay
	return okay

# Messages: minor news is a toast that fades by itself and is dismissed in the core, decisions wait in a box,
# and every message is kept in a log with an unread count. Synthetic events stand in for the core's.
func run_message_checks() -> bool:
	var okay := true
	var real_events: Array = city.state.get("events", []).duplicate(true)
	var known_entries: int = city.message_log.entries.size()
	var dismissed: Array = []
	var listener := func(id): dismissed.append(id)
	city.hud.message_dismissed.connect(listener)
	var info := {"id": 900001, "title": "fire at the granary", "text": "A fire has started.", "actions": [{"choice": -1, "label": "Dismiss"}]}
	var decision := {"id": 900002, "title": "an envoy arrives", "text": "Receive the envoy?", "actions": [{"choice": 0, "label": "Yes"}, {"choice": 1, "label": "No"}]}
	city.state.events = real_events + [info]
	city.event_signature = ""
	city.update_events()
	okay = city.check(city.hud.toasts.get_child_count() == 1 and city.message_log.entries.size() == known_entries + 1, "minor news appears as a toast and is recorded in the log") and okay
	okay = city.check(city.message_log.entries[-1].title == "Fire at the granary" and city.hud.messages_button.tooltip_text.contains(city.tr("Inbox (%d)") % city.message_log.unread), "the log keeps the title and the messages button shows an unread count") and okay
	city.update_events()
	okay = city.check(city.hud.toasts.get_child_count() == 1 and city.message_log.entries.size() == known_entries + 1, "the same message is never toasted or logged twice") and okay
	city.state.events = real_events + [info, decision]
	city.event_signature = ""
	city.update_events()
	okay = city.check(city.hud.events_box.visible and city.hud.get_node("%EventActions").get_child_count() == 2, "a decision keeps its original choices below its message") and okay
	var card: Node = city.hud.toasts.get_child(0)
	city.hud._close_toast(card)
	okay = city.check(dismissed == [900001] and city.hud.toasts.get_child_count() == 0, "closing a toast dismisses that message in the core") and okay
	for index in 6:
		var more := {"id": 900010 + index, "title": "news %d" % index, "text": "x", "actions": [{"choice": -1, "label": "Dismiss"}]}
		city.state.events = real_events + [more]
		city.event_signature = ""
		city.update_events()
	okay = city.check(city.hud.toasts.get_child_count() == 1 and city.hud.alert_queue.size() == 5 and dismissed == [900001], "one urgent alert shows while further news waits without losing history") and okay
	city.hud.set_messages_open(true)
	await city.get_tree().process_frame
	okay = city.check(city.message_log.unread == 0 and not city.hud.messages_button.tooltip_text.contains(city.tr("Inbox (%d)") % city.message_log.unread) and city.hud.message_list.get_child_count() == city.message_log.entries.size(), "opening the log lists every message newest first and clears the unread count") and okay
	var first_card: Node = city.hud.message_list.get_child(0)
	okay = city.check(first_card.title_text == city.message_log.entries[-1].title, "the newest message is at the top") and okay
	var language = city.language
	if UiTextLanguages.size() > 1:
		var original_title: String = city.hud.message_title.text
		city.language = UiText.set_language(UiText.next_language(language))
		city.hud.retranslate()
		okay = city.check(city.hud.message_title.text != original_title, "the log title follows the interface language") and okay
		city.language = UiText.set_language(language)
		city.hud.retranslate()
	city.hud.set_messages_open(false)
	for child in city.hud.toasts.get_children():
		child.queue_free()
	city.hud.alert_queue.clear()
	city.hud.message_dismissed.disconnect(listener)
	city.state.events = real_events
	city.event_signature = ""
	city.update_events()
	return okay

# Drag-to-place roads through the real input path: press starts a drag that previews the core's path, release builds
# it as one step, a click is one tile, and Escape or a right click cancels without touching the city.
func run_road_drag_checks() -> bool:
	var okay := true
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var start := Vector2i(99999, 99999)
	var finish := Vector2i(99999, 99999)
	var nearest := INF
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		var distance: float = city.world_position(point.x, point.y, 0).distance_squared_to(saved_target)
		if distance >= nearest:
			continue
		var plan: Dictionary = city.core.query("preview_road %d %d %d %d" % [point.x, point.y, point.x + 5, point.y])
		if plan.get("complete", false) and int(plan.new) == 6 and int(plan.existing) == 0:
			start = point
			finish = point + Vector2i(5, 0)
			nearest = distance
	okay = city.check(start != Vector2i(99999, 99999), "a free six-tile corridor is available for the drag regression") and okay
	if start == Vector2i(99999, 99999):
		return false
	city.orbit.target = city.world_position(start.x + 2.5, start.y, city.tiles[start][2])
	city.orbit.distance = 18
	city.orbit.yaw = 0
	city.orbit.snap_to_ground()
	city.set_tool("road")
	city.road_drag.guard = false
	await city.get_tree().physics_frame
	var money_before: int = city.state.money
	var roads_before := 0
	for point in city.tiles:
		roads_before += int(city.tiles[point][4])
	# Press, drag to the far end: the plan is drawn tile by tile with its cost, and nothing is built yet.
	city._unhandled_input(mouse_event(tile_screen(start), true))
	okay = city.check(city.road_drag.active and city.footprint_cells.get_child_count() == 1, "pressing the road tool starts a drag and nothing is built yet") and okay
	city.pick_tile(tile_screen(finish))
	var quoted: Dictionary = city.core.query("preview_road %d %d %d %d" % [start.x, start.y, finish.x, finish.y])
	okay = city.check(city.footprint_cells.get_child_count() == 6 and city.footprint_cells.visible and city.hint.text.contains("%d" % int(quoted.cost)), "dragging draws the six-tile path with its cost (%d)" % int(quoted.cost)) and okay
	okay = city.check(int(city.state.money) == money_before, "previewing a drag does not spend anything") and okay
	await city.get_tree().physics_frame
	city._unhandled_input(mouse_event(tile_screen(finish), false))
	await city.get_tree().create_timer(.5).timeout
	var roads_after := 0
	for point in city.tiles:
		roads_after += int(city.tiles[point][4])
	okay = city.check(not city.road_drag.active and roads_after == roads_before + 6 and int(city.state.money) == money_before - int(quoted.cost), "releasing builds all six tiles for the quoted cost in one step") and okay
	okay = city.check(city.state.undo_available and city.road_drag.plan.is_empty() and not city.road_drag.active, "the drag is undoable and its plan is cleared") and okay
	var undo := InputEventKey.new()
	undo.physical_keycode = KEY_Z
	undo.ctrl_pressed = true
	undo.pressed = true
	city._unhandled_input(undo)
	await city.get_tree().create_timer(.4).timeout
	var roads_undone := 0
	for point in city.tiles:
		roads_undone += int(city.tiles[point][4])
	okay = city.check(roads_undone == roads_before and int(city.state.money) == money_before, "one Ctrl Z removes the whole drag and refunds it") and okay
	# Escape and right click cancel without building.
	city._unhandled_input(mouse_event(tile_screen(start), true))
	city.pick_tile(tile_screen(finish))
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	city._input(escape)
	okay = city.check(not city.road_drag.active and city.footprint_cells.get_child_count() == 0 and city.mode == "road" and int(city.state.money) == money_before, "Escape cancels the drag but keeps the road tool") and okay
	city._unhandled_input(mouse_event(tile_screen(start), true))
	city.pick_tile(tile_screen(finish))
	city._unhandled_input(mouse_event(tile_screen(finish), true, MOUSE_BUTTON_RIGHT))
	await city.get_tree().create_timer(.2).timeout
	okay = city.check(not city.road_drag.active and int(city.state.money) == money_before, "right click cancels the drag") and okay
	# A press and release on one tile is the ordinary single road.
	var unit: Dictionary = city.core.query("preview road %d %d 0" % [start.x, start.y])
	city._unhandled_input(mouse_event(tile_screen(start), true))
	city._unhandled_input(mouse_event(tile_screen(start), false))
	await city.get_tree().create_timer(.5).timeout
	okay = city.check(int(city.tiles[start][4]) == 1 and int(city.state.money) == money_before - int(unit.cost), "a click without dragging builds one road tile") and okay
	city._unhandled_input(undo)
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(int(city.tiles[start][4]) == 0 and int(city.state.money) == money_before, "the single road is undone and refunded") and okay
	city.road_drag.guard = true
	city.set_tool("select")
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay

# Walls, towers and gatehouses through the real interface: the Build menu lists them under their own heading, a wall drag
# draws the pieces it will build (as models, joined to each other) with the cost, a release builds the outline in one
# step, the gatehouse follows T and a click lays it over its passage, and everything is undone as the native game does.
func run_wall_checks() -> bool:
	var okay := true
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var group: Array = city.hud.build_groups.filter(func(g): return g.title == "Walls and defence")
	okay = city.check(group.size() == 1 and group[0].items.map(func(i): return i.name).slice(0, 3) == ["wall", "tower", "gatehouse"], "the Build menu lists the wall, tower and gatehouse first under their own heading (the horse ranch and trireme wharf follow)") and okay
	var site := Vector2i(99999, 99999)
	var nearest := INF
	for point in city.tiles:
		if not int(city.tiles[point][5]):
			continue
		var distance: float = city.world_position(point.x, point.y, 0).distance_squared_to(saved_target)
		if distance >= nearest:
			continue
		var plan: Dictionary = city.core.query("preview_wall %d %d %d %d 1" % [point.x, point.y, point.x + 11, point.y + 8])
		# Tiles off the map are skipped silently, so the plot must be walled in full (12 x 9 = 108 pieces).
		if plan.get("complete", false) and int(plan.new) == 108:
			site = point
			nearest = distance
	okay = city.check(site != Vector2i(99999, 99999), "a free 12x9 plot is available for the wall regression") and okay
	if site == Vector2i(99999, 99999):
		return false
	var far := site + Vector2i(5, 4)
	city.orbit.target = city.world_position(site.x + 3, site.y + 2, city.tiles[site][2])
	city.orbit.distance = 18
	city.orbit.yaw = 20
	city.orbit.snap_to_ground()
	city.set_tool("wall")
	city.road_drag.guard = false
	await city.get_tree().physics_frame
	city.update_hint()
	okay = city.check(city.hint.text == city.tr("Drag to wall a rectangle's outline  •  hold Shift to fill it"), "choosing the wall tool tells how to drag (and Shift)") and okay
	var money_before: int = city.state.money
	var walls_before: int = city.state.buildings.filter(func(b): return String(b.asset).begins_with("wall_")).size()
	var quoted: Dictionary = city.core.query("preview_wall %d %d %d %d 0" % [site.x, site.y, far.x, far.y])
	city._unhandled_input(mouse_event(tile_screen(site), true))
	okay = city.check(city.road_drag.active and city.road_drag.tool == "wall", "pressing the wall tool starts a wall drag") and okay
	city.pick_tile(tile_screen(far))
	await city.get_tree().physics_frame
	okay = city.check(int(quoted.new) == 18 and city.footprint_cells.get_child_count() == 36 and city.hint.text.contains("%d" % int(quoted.cost)), "dragging outlines the 18 pieces, each a footprint and its model, with the cost (%d)" % int(quoted.cost)) and okay
	okay = city.check(int(city.state.money) == money_before, "previewing a wall does not spend anything") and okay
	city._unhandled_input(mouse_event(tile_screen(far), false))
	await city.get_tree().create_timer(.6).timeout
	var walls_after: int = city.state.buildings.filter(func(b): return String(b.asset).begins_with("wall_")).size()
	okay = city.check(not city.road_drag.active and walls_after == walls_before + 18 and int(city.state.money) == money_before - int(quoted.cost), "releasing builds the outline for the quoted cost in one step") and okay
	var undo := InputEventKey.new()
	undo.physical_keycode = KEY_Z
	undo.ctrl_pressed = true
	undo.pressed = true
	city._unhandled_input(undo)
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(city.state.buildings.filter(func(b): return String(b.asset).begins_with("wall_")).size() == walls_before and int(city.state.money) == money_before, "one Ctrl Z removes the whole outline and refunds it") and okay
	# The gatehouse: T turns it, the ghost shows its native footprint and the click lays it.
	var gate := Vector2i(99999, 99999)
	for turned in [0, 1]:
		var found := Vector2i(99999, 99999)
		for point in city.tiles:
			if city.core.query("preview gatehouse %d %d %d" % [point.x, point.y, turned]).get("valid", false) and (found == Vector2i(99999, 99999) or city.world_position(point.x, point.y, 0).distance_squared_to(saved_target) < city.world_position(found.x, found.y, 0).distance_squared_to(saved_target)):
				found = point
		okay = city.check(found != Vector2i(99999, 99999), "a site for a gatehouse turned %d is available" % turned) and okay
		if turned == 0:
			gate = found
	if gate != Vector2i(99999, 99999):
		city.orbit.target = city.world_position(gate.x + 2, gate.y + 1, city.tiles[gate][2])
		city.orbit.distance = 14
		city.orbit.snap_to_ground()
		await city.get_tree().physics_frame
		okay = city.check(city.hud.activate_building("gatehouse") and city.mode == "gatehouse", "the Build menu selects the gatehouse") and okay
		city.orientation = 0
		city.pick_tile(tile_screen(gate))
		city.refresh_placement()
		var quote: Dictionary = city.placement_result
		okay = city.check(quote.valid and int(quote.w) == 5 and int(quote.h) == 2 and city.footprint_cells.get_child_count() == 10 and city.ghost.visible and city.hint.text.contains("%d" % int(quote.cost)), "the pointer shows the gatehouse's ten tiles and its model with the cost (%d)" % int(quote.cost))  and okay
		var turn := InputEventKey.new()
		turn.physical_keycode = KEY_T
		turn.pressed = true
		city._unhandled_input(turn)
		city.refresh_placement()
		okay = city.check(city.orientation == 1 and int(city.placement_result.w) == 2 and int(city.placement_result.h) == 5 and int(city.placement_result.orientation) == 1, "T turns the gatehouse to its 2x5 form") and okay
		city._unhandled_input(turn)
		city._unhandled_input(turn)
		city._unhandled_input(turn)
		city.refresh_placement()
		money_before = city.state.money
		city._unhandled_input(mouse_event(tile_screen(gate), true))
		city._unhandled_input(mouse_event(tile_screen(gate), false))
		await city.get_tree().create_timer(.6).timeout
		okay = city.check(city.state.buildings.any(func(b): return b.asset == "gatehouse" and b.x == gate.x and b.y == gate.y and b.w == 5) and int(city.state.money) == money_before - int(quote.cost) and city.state.undo_available, "a click lays the gatehouse for the quoted cost") and okay
		okay = city.check(city.model_file_exists("gatehouse") and city.model_file_exists("tower") and city.model_file_exists("walker_archer"), "the gatehouse, the tower and the archer have models") and okay
		city._unhandled_input(undo)
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(not city.state.buildings.any(func(b): return b.asset == "gatehouse") and int(city.state.money) == money_before, "Ctrl Z takes the gatehouse back and refunds it") and okay
	city.road_drag.guard = true
	city.set_tool("select")
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay

# Elite housing and the area drags through the real interface: the Build menu lists elite housing with the common one, a
# drag over an area shows each plot (and a few as models) with the cost, a release builds all that fit in one step, a park
# drag fills every tile, and Ctrl Z takes each drag back.
func run_housing_checks() -> bool:
	var okay := true
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var group: Array = city.hud.build_groups.filter(func(g): return g.title == "Housing and roads")
	okay = city.check(group.size() == 1 and group[0].items.map(func(i): return i.name).slice(0, 3) == ["house", "elite_house", "road"], "the Build menu lists elite housing beside common housing (roadblocks and bridges follow the road)") and okay
	var undo := InputEventKey.new()
	undo.physical_keycode = KEY_Z
	undo.ctrl_pressed = true
	undo.pressed = true
	for case in [["elite_house", Vector2i(8, 4), 6, 12], ["park", Vector2i(3, 2), 12, 24]]:
		var tool: String = case[0]
		var offset: Vector2i = case[1]
		var count: int = case[2]
		var site := Vector2i(99999, 99999)
		var nearest := INF
		for point in city.tiles:
			if not int(city.tiles[point][5]):
				continue
			var distance: float = city.world_position(point.x, point.y, 0).distance_squared_to(saved_target)
			if distance >= nearest:
				continue
			var plan: Dictionary = city.core.query("preview_area %s %d %d %d %d" % [tool, point.x, point.y, point.x + offset.x, point.y + offset.y])
			if plan.get("complete", false) and int(plan.new) == count:
				site = point
				nearest = distance
		okay = city.check(site != Vector2i(99999, 99999), "a free plot for the %s drag (%d plots) is available" % [tool, count]) and okay
		if site == Vector2i(99999, 99999):
			continue
		var far := site + offset
		city.orbit.target = city.world_position(site.x + offset.x * .5, site.y + offset.y * .5, city.tiles[site][2])
		city.orbit.distance = 22
		city.orbit.yaw = 20
		city.orbit.snap_to_ground()
		okay = city.check(city.hud.activate_building(tool) and city.mode == tool, "the Build menu selects the %s tool" % tool) and okay
		city.road_drag.guard = false
		await city.get_tree().physics_frame
		city.update_hint()   # a pointer resting on the map would otherwise replace it with the placement hint
		okay = city.check(city.hint.text == city.tr("Drag to fill an area  •  each plot is built where it fits"), "the tool says how to drag") and okay
		var money_before: int = city.state.money
		var quoted: Dictionary = city.core.query("preview_area %s %d %d %d %d" % [tool, site.x, site.y, far.x, far.y])
		city._unhandled_input(mouse_event(tile_screen(site), true))
		okay = city.check(city.road_drag.active and city.road_drag.tool == tool, "pressing starts an area drag") and okay
		city.pick_tile(tile_screen(far))
		await city.get_tree().physics_frame
		okay = city.check(city.footprint_cells.get_child_count() == int(case[3]) and city.hint.text.contains("%d" % int(quoted.cost)), "dragging shows %d plots, the first few as models, with the cost (%d)" % [count, int(quoted.cost)]) and okay
		okay = city.check(int(city.state.money) == money_before, "previewing an area does not spend anything") and okay
		city._unhandled_input(mouse_event(tile_screen(far), false))
		await city.get_tree().create_timer(.6).timeout
		var prefix := "elite_house_" if tool == "elite_house" else "park"
		var built: int = city.state.buildings.filter(func(b): return String(b.asset).begins_with(prefix)).size()
		okay = city.check(not city.road_drag.active and built >= count and int(city.state.money) == money_before - int(quoted.cost), "releasing builds all %d for the quoted cost in one step" % count) and okay
		city._unhandled_input(undo)
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(city.state.buildings.filter(func(b): return String(b.asset).begins_with(prefix)).size() == built - count and int(city.state.money) == money_before, "one Ctrl Z removes the whole drag and refunds it") and okay
	okay = city.check(city.model_file_exists("elite_house_0a") and city.model_file_exists("elite_house_4b"), "the elite house models are present") and okay
	city.road_drag.guard = true
	city.set_tool("select")
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay

# Every building the Build menu offers has its model, and the culture and garden pieces that long stayed hidden are among them.
func run_menu_model_checks() -> bool:
	var okay := true
	var missing: Array = []
	for group in city.hud.build_groups:
		for item in group.items:
			# A road and an agora space are drawn by the presentation itself, not from a model file.
			if not String(item.asset) in ["road", "agora_space"] and not city.model_file_exists(String(item.asset)):
				missing.append(item.name)
	okay = city.check(missing.is_empty(), "every building in the Build menu has its model file %s" % str(missing)) and okay
	var unconverted: Array = city.core.query("buildable").buildings.filter(func(b): return b.asset == "unconverted").map(func(b): return b.name)
	okay = city.check(unconverted.is_empty(), "no native building is left without a model %s" % str(unconverted)) and okay
	return okay

# The world map through the real interface: the Game menu's action opens it over the held city, its markers stand on the map picture,
# selecting a city fills the panel, the dealings go to the core (a request lowers regard, a gift leaves the treasury), the military
# buttons say they are not available, and Escape (or F2) closes it and lets a running city run on.
func run_world_checks() -> bool:
	var okay := true
	var wm = city.world_map
	var money_start: int = city.state.money
	city.core.send("pause 0")
	await city.get_tree().create_timer(.4).timeout
	var was_running: bool = not city.state.paused
	city.game_action("world")
	while city.world_flight.busy(): await city.get_tree().process_frame
	okay = city.check(wm.visible and wm.world.get("cities", []).size() >= 4 and wm.marker_nodes.size() == wm.world.cities.size(), "the Game menu action opens the world map with a marker for each city (%d)" % wm.marker_nodes.size()) and okay
	okay = city.check(city.state.paused or not was_running, "the city is held while the map is open") and okay
	var rect: Rect2 = wm.image_rect()
	var inside := true
	for index in wm.marker_nodes:
		var marker: Control = wm.marker_nodes[index]
		var point: Vector2 = marker.position + marker.anchor()
		inside = inside and rect.grow(1.0).has_point(point)
	okay = city.check(wm.map.texture != null and wm.atlas.built and wm.atlas.active and inside, "the live 3D atlas is shown and every native marker projects inside the overview") and okay
	okay = city.check(wm.city_name.text == String(wm.find_city(wm.selected).name) and wm.find_city(wm.selected).current and wm.request_button.disabled and wm.gift_button.disabled, "the city being played is selected first, and nothing can be asked of it") and okay
	okay = city.check(["Raid", "Conquer", "Aid"].all(func(n): var b: Button = wm.get_node("%" + n); return b.disabled and b.tooltip_text != ""), "the military dealings are disabled for the city being played and say why") and okay
	var friend := -1
	var stranger := -1
	for entry in wm.world.cities:
		if entry.current:
			continue
		if entry.regarded and entry.can_request and friend < 0:
			friend = int(entry.index)
		if not entry.regarded and entry.can_request and stranger < 0:
			stranger = int(entry.index)
	okay = city.check(friend >= 0 and stranger >= 0, "the test world has a regarding city and one that is cold") and okay
	if friend < 0 or stranger < 0:
		wm.close()
		return false
	wm.step(1)
	okay = city.check(wm.selected != wm.default_city(), "the arrows step through the cities") and okay
	# A cold city grants nothing and says so.
	wm.select_city(stranger)
	wm.open_request()
	await city.get_tree().process_frame
	var cold_buttons: Array = wm.dialog.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with(city.tr("Request").substr(0, 3)) and b != wm.dialog.get_ok_button())
	okay = city.check(wm.dialog != null and cold_buttons.is_empty(), "a city that does not regard the player offers nothing to ask for") and okay
	wm.close_dialog()
	# A friend: asking lowers its regard by 20 (every city by 10 and this one by 10 more).
	wm.select_city(friend)
	var regard_before: int = int(wm.find_city(friend).attitude)
	wm.open_request()
	await city.get_tree().process_frame
	var asks: Array = wm.dialog.find_children("*", "Button", true, false).filter(func(b): return b != wm.dialog.get_ok_button())
	okay = city.check(asks.size() == wm.find_city(friend).sells.size() + 1, "a friendly city can be asked for each good it sells, and for drachmas (%d)" % asks.size()) and okay
	asks[0].pressed.emit()
	await city.get_tree().process_frame
	okay = city.check(int(wm.find_city(friend).attitude) == regard_before - 20 and wm.status.text != "" and wm.dialog == null, "asking is made through the core: regard %d to %d, the dialog closes and the panel says so" % [regard_before, int(wm.find_city(friend).attitude)]) and okay
	# A gift: 500 drachmas leave the treasury at once.
	var treasury: int = int(wm.world.treasury)
	wm.open_gift()
	await city.get_tree().process_frame
	var buttons: Array = wm.dialog.find_children("*", "Button", true, false).filter(func(b): return b.text == "500")
	okay = city.check(buttons.size() == 1, "the gift dialog offers drachmas in a size of 500") and okay
	if buttons.size() == 1:
		buttons[0].pressed.emit()
		await city.get_tree().process_frame
		okay = city.check(int(wm.world.treasury) == treasury - 500 and wm.status.text != "", "the gift leaves the treasury at once (%d to %d)" % [treasury, int(wm.world.treasury)]) and okay
	wm.open_fulfil()
	await city.get_tree().process_frame
	okay = city.check(wm.dialog != null and wm.dialog.find_children("*", "Label", true, false).size() >= 1, "the requests dialog opens (nothing, or the city's own requests)") and okay
	wm.close_dialog()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await city.get_tree().process_frame # parse_input_event dispatches on the next frame.
	while city.world_flight.busy(): await city.get_tree().process_frame
	okay = city.check(not wm.visible, "Escape closes the map") and okay
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(not city.state.paused or not was_running, "a city that was running runs on again") and okay
	var f2 := InputEventKey.new()
	f2.physical_keycode = KEY_F2
	f2.pressed = true
	city._unhandled_input(f2)
	while city.world_flight.busy(): await city.get_tree().process_frame
	okay = city.check(wm.visible, "F2 opens the map") and okay
	wm.close()
	while city.world_flight.busy(): await city.get_tree().process_frame
	city.core.send("pause 1")
	await city.get_tree().create_timer(.4).timeout
	return okay

# The army through the real interface: the Game menu's action opens the panel with a row for each company, the banners stand on the
# map as flags, choosing a company rings its flag, the orders go to the core (call out, send home), the banner is placed by the
# Place button and by the right button, a click on a flag chooses it, and Escape and F4 close the panel.
func run_army_checks() -> bool:
	var okay := true
	var panel = city.army_panel
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	var listed: Array = city.banners
	okay = city.check(listed.size() >= 1 and city.army_view.flags.size() == listed.filter(func(b): return bool(b.placed)).size(), "the city has companies and a flag stands for each (%d)" % listed.size()) and okay
	city.game_action("army")
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(panel.visible and panel.rows.size() == listed.size() and panel.list.get_child_count() == listed.size(), "the Game menu action opens the army panel with a row for each company") and okay
	okay = city.check(not city.inspector.visible and panel.title.text == city.tr("Army") and panel.summary.text.contains("%d" % listed.size()), "it takes the inspector's place and gives the count") and okay
	okay = city.check(panel.rows.values().all(func(r): return r.text.contains("\n") and r.icon != null), "each row names the company, its kind, its size and where it is") and okay
	var first: Dictionary = listed[0]
	panel.rows[int(first.id)].pressed.emit()
	await city.get_tree().process_frame
	okay = city.check(panel.selected_id == int(first.id) and city.army_view.selected == int(first.id) and city.army_view.flags[int(first.id)].ring.visible and panel.detail.visible, "choosing a company rings its flag and shows its card") and okay
	okay = city.check(city.army_view.flags.values().filter(func(f): return f.ring.visible).size() == 1, "only the chosen company is ringed") and okay
	# The flag stands on the tile the core gave, on the terrain.
	var flag: Node3D = city.army_view.flags[int(first.id)].node
	var expected: Vector3 = city.walker_surface_position(city.world_position(int(first.x), int(first.y), 0), 0.0, true)
	okay = city.check(flag.position.distance_to(expected) < .01, "the flag stands on its banner's tile") and okay
	# Orders.
	panel.call_all.pressed.emit()
	await city.get_tree().create_timer(.5).timeout
	okay = city.check(city.banners.all(func(b): return not bool(b.home)) and city.hint.text == city.tr("The companies are called out to their banners."), "Call all out calls every company and says so") and okay
	okay = city.check(panel.rows[int(first.id)].text.contains(city.tr("called out")) and panel.toggle_button.text == city.tr("Send home"), "the rows and the card show the companies as called out") and okay
	panel.toggle_button.pressed.emit()
	await city.get_tree().create_timer(.5).timeout
	var one: Dictionary = city.banners.filter(func(b): return int(b.id) == int(first.id))[0]
	var out: int = city.banners.filter(func(b): return not bool(b.home)).size()
	okay = city.check(bool(one.home) and out == city.banners.size() - 1 and panel.toggle_button.text == city.tr("Call out"), "the card sends that one company home and offers to call it out again") and okay
	panel.home_all.pressed.emit()
	await city.get_tree().create_timer(.5).timeout
	okay = city.check(city.banners.all(func(b): return bool(b.home)) and city.hint.text == city.tr("The companies return to the palace."), "Send all home brings every company back") and okay
	# Placing: the Place button, then a click on a free tile near the banner.
	city.jump_to_cell(Vector2(int(first.x), int(first.y)))
	city.orbit.distance = 16
	city.orbit.refresh()
	await city.get_tree().create_timer(.3).timeout
	var target := Vector2i(99999, 99999)
	for point in city.tiles:
		var offset := Vector2(point.x - int(first.x), point.y - int(first.y))
		if int(city.tiles[point][5]) and offset.length() > 6.0 and offset.length() < 9.0 and not city.terrain_geometry.sloped(point):
			var screen: Vector2 = tile_screen(point)
			if city.get_viewport().get_visible_rect().grow(-120).has_point(screen):
				target = point
				break
	okay = city.check(target != Vector2i(99999, 99999), "a free tile in view away from the banner is found") and okay
	if target == Vector2i(99999, 99999):
		panel.close()
		return false
	panel.place_button.pressed.emit()
	okay = city.check(city.placing_banner == int(first.id) and city.hint.text.contains(city.tr("Escape cancels").substr(0, 4)) and panel.place_button.text == city.tr("Click the ground…"), "Place banner waits for a click and says so") and okay
	city._unhandled_input(mouse_event(tile_screen(target), true))
	await city.get_tree().create_timer(.5).timeout
	var placed: Dictionary = city.banners.filter(func(b): return int(b.id) == int(first.id))[0]
	okay = city.check(city.placing_banner == -1 and Vector2(int(placed.x), int(placed.y)).distance_to(Vector2(target)) <= 4.5 and panel.place_button.text == city.tr("Place banner"), "the click places the banner there (%d, %d)" % [int(placed.x), int(placed.y)]) and okay
	okay = city.check(city.army_view.flags[int(first.id)].cell == Vector2i(int(placed.x), int(placed.y)), "and its flag moves with it") and okay
	# Escape cancels a placement that was begun.
	panel.place_button.pressed.emit()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	city._input(escape)
	okay = city.check(city.placing_banner == -1 and panel.visible, "Escape cancels a placement and keeps the panel") and okay
	# The right button sends the chosen banner to the tile under the pointer, as in the SDL view.
	var back := Vector2i(int(first.x), int(first.y))
	if city.tiles.has(back) and city.get_viewport().get_visible_rect().grow(-60).has_point(tile_screen(back)):
		city._unhandled_input(mouse_event(tile_screen(back), true, MOUSE_BUTTON_RIGHT))
		await city.get_tree().create_timer(.5).timeout
		var returned: Dictionary = city.banners.filter(func(b): return int(b.id) == int(first.id))[0]
		okay = city.check(Vector2(int(returned.x), int(returned.y)).distance_to(Vector2(back)) <= 4.5, "the right button moves the chosen banner to the tile (%d, %d)" % [int(returned.x), int(returned.y)]) and okay
	# A left click on a flag chooses its company (and opens the panel when it is closed).
	panel.close()
	okay = city.check(not panel.visible and city.army_view.selected == -1 and not city.army_view.flags.values().any(func(f): return f.ring.visible), "closing the panel drops the choice") and okay
	var second: Dictionary = city.banners[city.banners.size() - 1]
	city.jump_to_cell(Vector2(int(second.x), int(second.y)))
	city.orbit.distance = 12
	city.orbit.refresh()
	await city.get_tree().create_timer(.4).timeout
	var flag_cell := Vector2i(int(second.x), int(second.y))
	city._unhandled_input(mouse_event(tile_screen(flag_cell), true))
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(panel.visible and panel.selected_id == int(second.id), "a click on a flag opens the panel with that company chosen") and okay
	# Clicking elsewhere inspects as before and the panel steps aside for the inspector.
	var elsewhere := Vector2i(99999, 99999)
	for building in city.state.buildings:
		var cell := Vector2i(int(building.x), int(building.y))
		if city.tiles.has(cell) and city.army_view.banner_at(cell) < 0 and city.get_viewport().get_visible_rect().grow(-100).has_point(tile_screen(cell)) and not String(building.asset).begins_with("native_marker"):
			elsewhere = cell
			break
	if elsewhere != Vector2i(99999, 99999):
		city._unhandled_input(mouse_event(tile_screen(elsewhere), true))
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(not panel.visible and city.inspector.visible, "choosing another place closes the panel and inspects it") and okay
	# The keys: F4 opens and closes the panel; Escape closes it.
	var f4 := InputEventKey.new()
	f4.physical_keycode = KEY_F4
	f4.pressed = true
	city._unhandled_input(f4)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(panel.visible, "F4 opens the panel") and okay
	city._unhandled_input(f4)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(not panel.visible, "and closes it again") and okay
	city.game_action("army")
	await city.get_tree().create_timer(.3).timeout
	city._input(escape)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(not panel.visible, "Escape closes the panel") and okay
	# The language: the panel's texts follow it.
	city.game_action("army")
	await city.get_tree().create_timer(.3).timeout
	var english: String = panel.title.text
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(panel.title.text != english and panel.call_all.text == city.tr("Call all out") and panel.summary.text != "", "the panel's texts follow the interface language") and okay
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(panel.title.text == english, "and follow it back") and okay
	panel.close()
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.refresh()
	return okay

# Fighting through the real interface: an enemy force lands (a validators-only core command), the red notice counts the invaders,
# the soldiers' models play their baked fight clip while the core says they fight and their die clip when they fall (the shader's pose
# indices are the clip's frames), fighters face the direction the core gives them, and the notice goes when the battle is won.
func run_fight_checks() -> bool:
	var okay := true
	var WalkerCombat = preload("res://scripts/walker_combat.gd")
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(not city.invasion_banner.visible, "in peace the invasion notice is hidden") and okay
	var landed: Dictionary = city.core.query("test_invasion persian 8 0 0")
	okay = city.check(landed.get("invaders", 0) == 8, "eight Persian hoplites land (%s)" % str(landed.get("error", "ok"))) and okay
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(city.invasion_banner.visible and city.invasion_banner.label.text == city.tr("Under attack: %d invaders") % 8, "the red notice counts the invaders: %s" % city.invasion_banner.label.text) and okay
	var at: Vector2i = city.invasion_banner.at
	var home_target: Vector3 = city.orbit.target
	city.orbit.target = Vector3(home_target.x + 40.0, home_target.y, home_target.z)
	city.invasion_banner.show_button.pressed.emit()
	await city.get_tree().create_timer(.3).timeout
	var seen: Vector2 = city.tile_coordinates(city.orbit.target)
	okay = city.check(city.invasion_banner.show_button.text == city.tr("Go to the invaders") and seen.distance_to(Vector2(at)) < 2.0, "its button takes the camera to the invaders (%s, the camera at %s)" % [str(at), str(seen)]) and okay
	city.orbit.target = home_target
	city.orbit.refresh()
	var persians: Array = city.walkers.values().filter(func(e): return e.asset == "walker_persianhoplite")
	okay = city.check(persians.size() == 8 and persians.all(func(e): return e.clips.has("fight") and e.clips.has("die") and not e.morphs.is_empty()), "their models carry fight and die clips (%d walkers)" % persians.size()) and okay
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	var other_language: String = city.invasion_banner.label.text
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(other_language != city.invasion_banner.label.text, "the notice follows the interface language") and okay
	city.core.send("speed 3")
	city.core.send("pause 0")
	var fight_ok := false
	var die_ok := false
	var die_seen := false
	var facing_ok := false
	var fight_note := "no fighter seen"
	var die_note := "no fall seen"
	var elapsed := 0.0
	while elapsed < 100.0 and not (fight_ok and die_ok and facing_ok):
		await city.get_tree().process_frame
		elapsed += city.get_process_delta_time()
		for event in city.state.get("events", []):
			var choices: Array = event.get("actions", [])
			city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		for entry in city.walkers.values():
			if entry.asset != "walker_persianhoplite":
				continue
			var clip: String = str(entry.get("clip", ""))
			if clip == "":
				continue
			var morph = entry.morphs[0]
			var pose: Vector3 = morph.node.get_instance_shader_parameter("vat_pose")
			var frames: Array = entry.clips[clip]
			var indices: Array = frames.map(func(n): return int(morph.table[n]))
			if clip == "fight" and not fight_ok:
				fight_ok = int(pose.x) in indices and int(pose.y) in indices and morph.node.get_instance_shader_parameter("vat_walk_blend") == 1.0
				fight_note = "pose %s of %s" % [str(pose), str(indices)]
			if clip == "fight" and not facing_ok and entry.clip_time > .4:
				facing_ok = absf(angle_difference(entry.node.rotation.y, WalkerCombat.facing_angle(int(entry.facing)))) < .4
			if clip == "die" and not die_ok:
				# A corpse is removed by the core within a couple of game seconds (less than a second at the top speed), so the clip's
				# end is checked on this walker's own state: after its time is spent the pose must be the clip's last frame.
				die_seen = int(pose.x) in indices and int(pose.y) in indices
				entry.clip_time = 5.0
				WalkerCombat.animate(entry, 0.0)
				var held: Vector3 = morph.node.get_instance_shader_parameter("vat_pose")
				die_ok = die_seen and int(held.x) == indices[-1] and int(held.y) == indices[-1]
				die_note = "pose %s while falling, %s held" % [str(pose), str(held)]
	okay = city.check(fight_ok, "a fighting soldier plays its fight clip through the pose shader (%s)" % fight_note) and okay
	okay = city.check(facing_ok, "and faces the direction the core gives it") and okay
	okay = city.check(die_ok, "a fallen soldier plays its die clip and then holds its last frame (%s)" % die_note) and okay
	elapsed = 0.0
	while elapsed < 90.0 and city.invasion_banner.visible:
		await city.get_tree().process_frame
		elapsed += city.get_process_delta_time()
		for event in city.state.get("events", []):
			var choices: Array = event.get("actions", [])
			city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
	okay = city.check(not city.invasion_banner.visible, "the notice goes when the battle is over") and okay
	# The victory message may ask for an answer: leave nothing pending for whatever runs next.
	for round in 20:
		var pending: Array = city.state.get("events", [])
		if pending.is_empty():
			break
		for event in pending:
			var choices: Array = event.get("actions", [])
			city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		await city.get_tree().create_timer(.3).timeout
	city.core.send("pause 1")
	await city.get_tree().create_timer(.4).timeout
	return okay

# The words of events that the SDL view writes in its own handlers (presentation/eeventwords.h) through the real interface: a god's
# visit, a monster slain, a city's thanks for help and a quest reach the toasts and the message log with their title and text, the
# player's own invasion (an alert tile in the SDL view) says nothing, and the answer is in the core's language (validate_events.gd
# checks all 103 kinds).
func run_event_word_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	var known: int = city.message_log.entries.size()
	city.core.query("test_raise godVisit god zeus")
	await city.get_tree().create_timer(.6).timeout
	var entry: Dictionary = city.message_log.entries[-1] if city.message_log.entries.size() > known else {}
	okay = city.check(not entry.is_empty() and str(entry.title).length() > 3 and str(entry.text).length() > 40 and not str(entry.text).contains("["), "a god's visit reaches the message log with title and text: %s" % str(entry.get("title", "-"))) and okay
	okay = city.check(entry.get("kind", "") == "godVisit", "a peaceful god visit carries its native kind for quiet journal delivery") and okay
	known = city.message_log.entries.size()
	city.core.query("test_raise godQuest god hades quest 1 hero hercules")
	await city.get_tree().create_timer(.6).timeout
	var quest: Dictionary = city.message_log.entries[-1] if city.message_log.entries.size() > known else {}
	okay = city.check(not quest.is_empty() and str(quest.text).length() > 60 and not str(quest.text).contains("[hero_needed]"), "a god's quest names the hero it needs: %s" % str(quest.get("title", "-"))) and okay
	known = city.message_log.entries.size()
	city.core.query("test_raise monsterSlain monster hydra")
	await city.get_tree().create_timer(.6).timeout
	var slain: Dictionary = city.message_log.entries[-1] if city.message_log.entries.size() > known else {}
	okay = city.check(not slain.is_empty() and str(slain.title) != "MonsterSlain" and str(slain.text).length() > 20, "a monster slain is worded: %s" % str(slain.get("title", "-"))) and okay
	known = city.message_log.entries.size()
	city.core.query("test_raise famineAllyComply city 1")
	await city.get_tree().create_timer(.6).timeout
	var thanks: Dictionary = city.message_log.entries[-1] if city.message_log.entries.size() > known else {}
	okay = city.check(not thanks.is_empty() and str(thanks.text).length() > 60 and not str(thanks.text).contains("[city_name]"), "a city's thanks for the food it asked for names the city: %s" % str(thanks.get("title", "-"))) and okay
	known = city.message_log.entries.size()
	city.core.query("test_raise playerInvasion")
	city.core.query("test_raise playerGodAttack")
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(city.message_log.entries.size() == known, "the player's own invasion and god attack bring no message box (alerts only)") and okay
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	return okay

# Answers the decisions the city is waiting for (they pause it and refuse every building command) with their first choice, until none is left.
func answer_pending() -> void:
	for round in 20:
		var pending: Array = city.state.get("events", [])
		var asking := false
		for event in pending:
			var choices: Array = event.get("actions", [])
			if choices.size() > 1 or (choices.size() == 1 and int(choices[0].choice) != -1):
				asking = true
			city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		if not asking:
			break
		await city.get_tree().create_timer(.3).timeout

# A sanctuary through the real interface (run last, after the heroes: it founds one and shows the mythology page): a scenario's
# allowance puts the sanctuary in the Build menu with its drachmas and marble; the pointer shows its pieces as a translucent ghost over
# the footprint (turned by T, centred on the pointer) with the cost; founding it puts the foundations in the city; its inspector words the
# progress and halts or resumes the work; the Game menu's Mythology page lists the sanctuaries and a monster at large, and its Show
# button takes the camera there.
func run_sanctuary_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	await answer_pending()
	var before := int(city.core.query("buildable").sanctuaries.built)
	okay = city.check(city.hud.build_groups.all(func(g): return g.title != "Sanctuaries"), "before the scenario allows one the Build menu offers no sanctuary") and okay
	city.core.query("test_allow temple_dionysus")
	city.refresh_catalog()
	var group: Array = city.hud.build_groups.filter(func(g): return g.title == "Sanctuaries")
	var offered: Array = group[0].items.filter(func(item): return item.name == "temple_dionysus") if group.size() == 1 else []
	okay = city.check(offered.size() == 1 and offered[0].label == "Grove of Dionysus" and int(offered[0].marble) == 8 and city.hud.cost_text(offered[0]).contains("8"), "the allowed sanctuary is in the Build menu with its marble: %s" % (city.hud.cost_text(offered[0]) if offered.size() == 1 else "-")) and okay
	# A site beside a road (the carts must reach it).
	var site := Vector2i(99999, 99999)
	var roads := {}
	for point in city.tiles:
		if int(city.tiles[point][4]) == 1:
			roads[point] = true
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		var touches := false
		for dx in range(-6, 6):
			touches = touches or roads.has(Vector2i(point.x + dx, point.y - 4)) or roads.has(Vector2i(point.x + dx, point.y + 3))
		if touches and city.core.query("preview temple_dionysus %d %d 0" % [point.x, point.y]).get("valid", false):
			site = point
			break
	okay = city.check(site != Vector2i(99999, 99999), "a site for the sanctuary is free") and okay
	city.set_tool("temple_dionysus")
	city.orientation = 0
	city.picked = site
	city.placement_key = ""
	city.refresh_placement()
	var pieces: Array = city.placement_result.get("pieces", [])
	okay = city.check(city.placement_result.valid and pieces.size() >= 8 and city.sanctuary_ghost.visible and city.sanctuary_ghost.get_child_count() == pieces.size() and not city.ghost.visible, "the pointer shows the sanctuary's %d pieces as a ghost" % pieces.size()) and okay
	okay = city.check(city.footprint_cells.get_child_count() == int(city.placement_result.w) * int(city.placement_result.h) and city.hint.text.contains("8") and city.hint.text.contains(city.tr("Ready to place")), "over its %dx%d footprint, with the cost in the hint: %s" % [int(city.placement_result.w), int(city.placement_result.h), city.hint.text]) and okay
	var wide: int = int(city.placement_result.w)
	city.orientation = 1
	city.placement_key = ""
	city.refresh_placement()
	okay = city.check(int(city.placement_result.h) == wide and int(city.placement_result.w) < wide, "T turns it a quarter (the footprint's sides swap)") and okay
	city.orientation = 0
	city.set_tool("select")
	await city.get_tree().process_frame
	okay = city.check(not city.sanctuary_ghost.visible, "the ghost goes with the tool") and okay
	var built: Dictionary = city.core.query("build temple_dionysus %d %d 0" % [site.x, site.y])
	okay = city.check(not built.has("error"), "the sanctuary is founded (%s)" % str(built.get("error", "ok"))) and okay
	await city.get_tree().create_timer(.8).timeout
	var slabs := 0
	var statues := 0
	for building in city.state.buildings:
		slabs += 1 if building.get("stretch", false) else 0
		statues += 1 if building.asset == "sanctuary_statue_dionysus" and int(building.get("grow", 100)) == 0 else 0
	okay = city.check(slabs >= 3 and statues == 2, "its foundations are in the city: %d slabs and %d founded statues" % [slabs, statues]) and okay
	city.inspected = site
	city.refresh_inspection()
	await city.get_tree().process_frame
	var controls: VBoxContainer = city.inspector_controls
	okay = city.check(controls.monument_lines != null and controls.monument_lines.text.contains("%") and controls.monument_halt_button != null and controls.monument_halt_button.text == city.tr("Halt the work") and not controls.monument_halt_button.disabled, "the inspector words the progress and offers to halt the work: %s" % str(controls.monument_lines.text if controls.monument_lines != null else "-").replace("\n", " / ")) and okay
	if controls.monument_halt_button != null:
		controls.monument_halt_button.pressed.emit()
		await city.get_tree().create_timer(.5).timeout
		okay = city.check(controls.monument_halt_button.text == city.tr("Resume the work") and bool(controls.value.monument.halted), "halting shows 'Resume the work' and the core's state") and okay
		controls.monument_halt_button.pressed.emit()
		await city.get_tree().create_timer(.5).timeout
		okay = city.check(controls.monument_halt_button.text == city.tr("Halt the work"), "and resuming restores it") and okay
	city.core.query("test_monster cerberus")
	city.game_action("mythology")
	await city.get_tree().create_timer(.5).timeout
	var dialogs: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.title == city.tr("Mythology"))
	okay = city.check(dialogs.size() == 1, "the Game menu's Mythology page opens") and okay
	if dialogs.size() == 1:
		var shows: Array = dialogs[0].find_children("*", "Button", true, false).filter(func(b): return b.text == city.tr("Show"))
		okay = city.check(shows.size() >= before + 2, "it lists the sanctuaries (%d, the new one among them) and the monster at large, each with a Show button" % (before + 1)) and okay
		var home: Vector3 = city.orbit.target
		city.orbit.target = Vector3(home.x + 60.0, home.y, home.z)
		if not shows.is_empty():
			shows[shows.size() - 1].pressed.emit()
			await city.get_tree().create_timer(.4).timeout
		okay = city.check(city.orbit.target.distance_to(Vector3(home.x + 60.0, home.y, home.z)) > 5.0, "Show takes the camera to it") and okay
		if is_instance_valid(dialogs[0]):
			dialogs[0].queue_free()
	return okay

# A pyramid and a shrine through the real interface (run last: they are founded in the city): the saved city's scenario grants the standard pyramid,
# so the Build menu has "Pyramids" at once, and a granted shrine adds "Shrines", their materials coming by cart rather than drachmas; the pointer shows the pieces of the
# pyramid as a ghost centred on it, each on the ground its level will raise; founding it through the command queue (as a click does) puts the
# foundations in the city; the inspector words the progress, what is still needed and offers to halt the work; the saved city's
# finished pyramid is inspected as a monument with the game's description and no god's help to ask for.
# The rite on a sanctuary's altar, shown in the running city: a priestess in the walkers' list standing on the altar's stairs with her stab clip, the animal lying
# on its side on the table (or the goods in place of it), and the braziers burning high; a rite of goods raises her arms instead.
func run_rite_checks() -> bool:
	var okay := true
	var WalkerCombat = preload("res://scripts/walker_combat.gd")
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	await answer_pending()
	var simulation: RefCounted = city.core.simulation
	simulation.enable_test_commands()
	var altar := {}
	for building in city.state.buildings:
		if str(building.asset) == "sanctuary_altar" and not simulation.command("test_sacrifice %d %d sheep" % [int(building.x), int(building.y)]).has("error"):
			altar = building
			break
	okay = city.check(not altar.is_empty(), "a sanctuary's altar takes a rite in the running city") and okay
	if altar.is_empty():
		return false
	city.receive_state(simulation.snapshot(false))
	await city.get_tree().process_frame
	await city.get_tree().process_frame
	var centre: Vector3 = city.world_position(float(altar.x) + altar.w * .5 - .5, float(altar.y) + altar.h * .5 - .5, int(altar.altitude))
	var priestess := {}
	var victim := {}
	# The engine may have a rite of its own on the city's other altar: only the parts at this altar count.
	for entry in city.walkers.values():
		if Vector2(entry.node.position.x - centre.x, entry.node.position.z - centre.z).length() > 1.6:
			continue
		if entry.asset == "walker_priestess":
			priestess = entry
		elif entry.get("roll", 0.0) != 0.0:
			victim = entry
	okay = city.check(not priestess.is_empty() and not victim.is_empty() and victim.asset == "animal_sheep_fleeced", "the priestess and the sheep are among the city's walkers") and okay
	if priestess.is_empty() or victim.is_empty():
		return false
	okay = city.check(absf(priestess.node.position.x - centre.x) < .05 and absf(priestess.node.position.z - (centre.z - 1.12)) < .05, "the priestess stands one tile out from the altar's centre, on its +y side") and okay
	okay = city.check(priestess.node.position.y > centre.y + .25 and victim.node.position.y > centre.y + .7, "she stands on the stairs and the sheep on the table (%.2f, %.2f above the altar's ground)" % [priestess.node.position.y - centre.y, victim.node.position.y - centre.y]) and okay
	okay = city.check(absf(victim.node.position.x - centre.x) < .1 and absf(victim.node.position.z - centre.z) < .3 and absf(victim.node.rotation.z - deg_to_rad(90.0)) < .01, "the sheep lies on its side over the table's middle") and okay
	okay = city.check(priestess.clips.has("fight") and priestess.clips.fight.size() == 24 and priestess.clips.has("fight2") and WalkerCombat.clip_for(priestess) == "fight", "the priestess plays her stab clip") and okay
	var key: Vector2i = city.rite_key(float(altar.x) + altar.w * .5, float(altar.y) + altar.h * .5)
	var burning := false
	for id in city.altar_fires.keys:
		if city.altar_fires.keys[id] == key:
			burning = city.altar_fires.burning.has(key) and float(city.altar_fires.tufts[id][0].get_instance_shader_parameter("burn")) == 1.0
	okay = city.check(burning, "the braziers of that altar burn high (key %s, burning %s)" % [str(key), str(city.altar_fires.burning.keys())]) and okay
	# An offering of goods: her arms rise, the animal is replaced by the goods.
	simulation.command("test_sacrifice %d %d goods" % [int(altar.x), int(altar.y)])
	city.receive_state(simulation.snapshot(false))
	await city.get_tree().process_frame
	await city.get_tree().process_frame
	okay = city.check(WalkerCombat.clip_for(priestess) == "fight2", "for goods she raises her arms (the offering clip)") and okay
	# The core link may still deliver a snapshot taken before the command: wait (a second or so) until the scene is the goods'.
	var props: Array = []
	for frame in 60:
		props = city.world.find_children("SacrificeGoods", "Node3D", true, false)
		props = props.filter(func(n): return Vector2(n.global_position.x - centre.x, n.global_position.z - centre.z).length() < 1.6)
		if props.size() == 1 and not city.walkers.values().any(func(e): return e.asset == "animal_sheep_fleeced" and e.has("roll") and Vector2(e.node.position.x - centre.x, e.node.position.z - centre.z).length() < 1.6):
			break
		await city.get_tree().process_frame
	okay = city.check(props.size() == 1 and not city.walkers.values().any(func(e): return e.asset == "animal_sheep_fleeced" and e.has("roll") and Vector2(e.node.position.x - centre.x, e.node.position.z - centre.z).length() < 1.6), "the goods stand on the table where the animal was (%d goods nodes; rite walkers %s)" % [props.size(), str(city.walkers.values().filter(func(e): return e.has("roll")).map(func(e): return str(e.asset)))]) and okay
	return okay

func run_pyramid_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	await answer_pending()
	var granted: Array = city.hud.build_groups.filter(func(g): return g.title == "Pyramids")
	okay = city.check(granted.size() == 1 and granted[0].items.size() == 1 and granted[0].items[0].name == "pyramid_standard" and city.hud.build_groups.all(func(g): return g.title != "Shrines"), "the saved city's scenario grants the standard pyramid: the Build menu lists it under Pyramids and has no Shrines yet") and okay
	city.core.query("test_allow shrine_minor_zeus")
	city.refresh_catalog()
	var pyramids: Array = city.hud.build_groups.filter(func(g): return g.title == "Pyramids")
	var shrines: Array = city.hud.build_groups.filter(func(g): return g.title == "Shrines")
	var offered: Array = pyramids[0].items if pyramids.size() == 1 else []
	var shrine_items: Array = shrines[0].items if shrines.size() == 1 else []
	okay = city.check(offered.size() == 1 and offered[0].name == "pyramid_standard" and offered[0].label == "Pyramid" and shrine_items.size() == 1 and shrine_items[0].name == "shrine_minor_zeus" and shrine_items[0].label == "Zeus Minor Shrine", "a granted shrine joins it in the Build menu under Shrines") and okay
	okay = city.check(offered.size() == 1 and city.hud.cost_text(offered[0]) == city.tr("Materials by cart"), "their cost says the materials come by cart: %s" % (city.hud.cost_text(offered[0]) if offered.size() == 1 else "-")) and okay
	# A site beside a road (the carts must reach it) where a 5x5 footprint centred on the tile is free.
	var site := Vector2i(99999, 99999)
	var roads := {}
	for point in city.tiles:
		if int(city.tiles[point][4]) == 1:
			roads[point] = true
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		var touches := false
		for dx in range(-3, 4):
			touches = touches or roads.has(Vector2i(point.x + dx, point.y - 3)) or roads.has(Vector2i(point.x + dx, point.y + 3))
		if touches and city.core.query("preview pyramid_standard %d %d 0" % [point.x, point.y]).get("valid", false):
			site = point
			break
	okay = city.check(site != Vector2i(99999, 99999), "a site for the pyramid is free") and okay
	city.set_tool("pyramid_standard")
	city.orientation = 0
	city.picked = site
	city.placement_key = ""
	city.refresh_placement()
	var pieces: Array = city.placement_result.get("pieces", [])
	okay = city.check(city.placement_result.valid and pieces.size() == 25 and city.sanctuary_ghost.visible and city.sanctuary_ghost.get_child_count() == 25 and not city.ghost.visible, "the pointer shows the pyramid's %d pieces as a ghost" % pieces.size()) and okay
	okay = city.check(city.footprint_cells.get_child_count() == 25 and city.hint.text.contains(city.tr("Ready to place")) and not city.hint.text.contains("marble"), "over its 5x5 footprint, with no drachmas or marble asked: %s" % city.hint.text) and okay
	var lowest := INF
	var highest := -INF
	for holder in city.sanctuary_ghost.get_children():
		lowest = minf(lowest, holder.position.y)
		highest = maxf(highest, holder.position.y)
	okay = city.check(is_equal_approx(snappedf(highest - lowest, .01), snappedf(8 * .22, .01)), "its capstone stands two levels (eight steps) above the ring of the base: %.2f" % (highest - lowest)) and okay
	city.set_tool("select")
	await city.get_tree().process_frame
	okay = city.check(not city.sanctuary_ghost.visible, "the ghost goes with the tool") and okay
	city.core.send("build pyramid_standard %d %d 0" % [site.x, site.y])
	await city.get_tree().create_timer(1.2).timeout
	var near: Array = city.state.buildings.filter(func(b): return int(b.x) >= site.x - 2 and int(b.x) <= site.x + 2 and int(b.y) >= site.y - 2 and int(b.y) <= site.y + 2)
	var slabs: Array = near.filter(func(b): return str(b.asset) == "sanctuary_court_0")
	okay = city.check(slabs.size() == 25 and not near.any(func(b): return str(b.asset) == "unconverted"), "founding it puts its foundations in the city: %d slabs" % slabs.size()) and okay
	city.inspected = site
	city.refresh_inspection()
	await city.get_tree().process_frame
	var controls: VBoxContainer = city.inspector_controls
	okay = city.check(controls.monument_lines != null and controls.monument_lines.text.contains("0%") and controls.monument_halt_button != null and controls.monument_halt_button.text == city.tr("Halt the work"), "the inspector words the progress and offers to halt the work: %s" % str(controls.monument_lines.text if controls.monument_lines != null else "-").replace("\n", " / ")) and okay
	# The materials come at once (the validators' funding): the inspector's list of what is still needed empties when it is refreshed. (The workers
	# are not waited for here: the battles of the earlier checks may have destroyed the artisans' guilds; validate_pyramids.gd runs the work.)
	var needed_before: int = int(controls.value.monument.needed.marble)
	city.core.query("test_fund %d %d" % [site.x, site.y])
	city.refresh_inspection()
	await city.get_tree().process_frame
	okay = city.check(needed_before > 0 and int(controls.value.monument.needed.marble) == 0 and int(controls.value.monument.needed.orichalc) == 0, "funded, the inspector no longer lists materials still needed (marble %d to %d)" % [needed_before, int(controls.value.monument.needed.marble)]) and okay
	# The saved city's finished modest pyramid.
	city.inspected = Vector2i(82, 6)
	city.refresh_inspection()
	await city.get_tree().process_frame
	var standing: Dictionary = city.inspector_controls.value.get("monument", {})
	okay = city.check(not standing.is_empty() and bool(standing.finished) and bool(standing.pyramid) and str(standing.description).length() > 30 and city.inspector_controls.monument_help_button == null, "the finished pyramid of the saved city is a monument with the game's description and no god's help: %s" % str(standing.get("title", "-"))) and okay
	city.close_inspection()
	return okay

# Waits until the world map's flight (to the atlas or back) is over, at most eight seconds.
func wait_world_flight() -> void:
	await city.get_tree().create_timer(.2).timeout
	for step in 80:
		if not city.world_flight.busy():
			break
		await city.get_tree().create_timer(.1).timeout
	await city.get_tree().create_timer(.2).timeout

# The controls and game settings through the real interface (scratch settings, restored at the end): the Game menu lists Controls and Game settings;
# the Controls dialog rebinds a key and the city answers to the new one and not the old (placement turn, overlay, quick save, the world map's own key),
# the menu entries and tooltips name the new keys, a held camera key follows in the InputMap, a swap is said in words, Restore defaults puts it all
# back; the Game settings dialog changes the autosave rhythm of the running city at once.
# The City window (F7, or Game, City…) through the real interface: the SDL side panel's twelve pages as tabs, the overview's six
# verdicts tinted, the wage list and a priority list for each of the eight sectors (a choice goes through the command queue and
# the page shows the core's new data), the taxes in the order of their percentage with the finances table, and a See button that
# opens its overlay. The settings are put back afterwards.
func run_city_data_checks() -> bool:
	var okay := true
	var KeyBindings = preload("res://scripts/key_bindings.gd")
	var start: Dictionary = city.core.query("city_data")
	# The controls checks give F7 to the world map for a while, and the City window takes the map's F2 meanwhile: their F2 press
	# opens a City window, which is closed here.
	for child in city.hud.get_children():
		if child is AcceptDialog and child.title == city.tr("City"):
			child.free()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F7
	key.pressed = true
	city._unhandled_input(key)
	await city.get_tree().create_timer(.6).timeout
	var dialogs: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.title == city.tr("City"))
	okay = city.check(dialogs.size() == 1 and city.hud.GAME_ACTIONS.has("city") and KeyBindings.label("city") == "F7", "F7 opens the City window, which the Game menu offers too") and okay
	if dialogs.size() != 1:
		city.game_action("city")
		await city.get_tree().create_timer(.6).timeout
		dialogs = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.title == city.tr("City"))
		if dialogs.size() != 1:
			return okay
	var dialog = dialogs[0]
	okay = city.check(dialog.tabs.get_tab_count() == 12 and dialog.tabs.get_tab_title(0) == city.tr("Summary") and dialog.tabs.get_tab_title(11) == city.tr("Mythology"), "it has the SDL panel's twelve pages as tabs") and okay
	var values: Array = dialog.bodies.overview.find_children("Value", "Label", true, false)
	okay = city.check(values.size() >= 5 and values.all(func(v): return v.has_theme_color_override("font_color")), "the summary shows the core's verdicts, each tinted by how serious it is (%d)" % values.size()) and okay
	dialog.show_page("employment")
	await city.get_tree().process_frame
	var options: Array = dialog.bodies.employment.find_children("*", "OptionButton", true, false)
	okay = city.check(options.size() == 9 and options[0].item_count == 6 and options[1].item_count == 6, "the employment page has the wage list and a priority list for each of the eight sectors (%d lists)" % options.size()) and okay
	if options.size() == 9:
		options[1].select(0)
		options[1].item_selected.emit(0)
		await city.get_tree().create_timer(.6).timeout
		var husbandry: Dictionary = city.core.query("city_data").workforce.sectors[0]
		okay = city.check(int(husbandry.priority) == 0 and int(husbandry.have) == 0, "choosing no priority for husbandry goes through the command queue and its workers are shared out elsewhere") and okay
		var shown: Array = dialog.bodies.employment.find_children("*", "OptionButton", true, false)
		okay = city.check(shown.size() == 9 and shown[1].selected == 0, "the page shows the core's new priority") and okay
		var wages: Array = dialog.bodies.employment.find_children("*", "OptionButton", true, false)
		wages[0].item_selected.emit(5)
		await city.get_tree().create_timer(.6).timeout
		okay = city.check(int(city.core.query("city_data").wage.rate) == 5, "the wage list sets the city's wage rate") and okay
	dialog.show_page("administration")
	await city.get_tree().process_frame
	var tax_lists: Array = dialog.bodies.administration.find_children("*", "OptionButton", true, false)
	okay = city.check(tax_lists.size() == 1 and tax_lists[0].item_count == 7 and tax_lists[0].get_item_text(1).contains("3%") and tax_lists[0].get_item_text(2).contains("7%"), "the tax list goes up by percentage: %s" % (tax_lists[0].get_item_text(1) if tax_lists.size() == 1 else "-")) and okay
	okay = city.check(dialog.bodies.administration.find_child("Finances", true, false) != null, "the administration page has the finances table") and okay
	if tax_lists.size() == 1:
		tax_lists[0].item_selected.emit(5)
		await city.get_tree().create_timer(.6).timeout
		okay = city.check(int(city.core.query("city_data").tax.rate) == 5, "the tax list sets the city's tax rate (very high)") and okay
	dialog.show_page("hygiene")
	await city.get_tree().process_frame
	var sees: Array = dialog.bodies.hygiene.find_children("*", "Button", true, false).filter(func(b): return not b is OptionButton)
	okay = city.check(sees.size() == 4, "the hygiene page has its four See buttons") and okay
	if sees.size() == 4:
		sees[0].pressed.emit()
		await city.get_tree().create_timer(.5).timeout
		okay = city.check(city.overlay_view.mode == "water" and not is_instance_valid(dialog), "See water opens the water overlay and closes the window") and okay
		city.set_overlay("normal")
	city.core.send("set_tax %d" % int(start.tax.rate))
	city.core.send("set_wage %d" % int(start.wage.rate))
	city.core.send("set_priority 0 %d" % int(start.workforce.sectors[0].priority))
	await city.get_tree().create_timer(.6).timeout
	if is_instance_valid(dialog):
		dialog.queue_free()
	return okay

# The trireme wharf and its trireme through the real interface: the inspector shows the SDL page's lines and its switch, which shuts
# the wharf down through the command queue and sets it working again; a launched trireme is picked by a click near it, wears the
# gold ring, sails toward the water a right click names, and Escape lets it go.
func run_naval_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	var site := Vector2i(99999, 99999)
	for point in city.tiles:
		if city.core.query("preview trireme_wharf %d %d 0" % [point.x, point.y]).get("valid", false):
			site = point
			break
	okay = city.check(site.x != 99999, "a shore site for a trireme wharf") and okay
	if site.x == 99999:
		return okay
	city.core.send("build trireme_wharf %d %d 0" % [site.x, site.y])
	await city.get_tree().create_timer(.6).timeout
	city.inspected = site + Vector2i(1, 1)
	city.refresh_inspection()
	await city.get_tree().process_frame
	var controls = city.inspector_controls
	okay = city.check(controls.notes_label != null and not controls.notes_label.text.is_empty() and controls.switch_button != null, "the wharf's inspector shows the SDL page's lines and its switch: %s" % (controls.notes_label.text.replace("\n", " / ") if controls.notes_label != null else "-")) and okay
	if controls.switch_button != null:
		var working: String = controls.switch_button.text
		controls.switch_button.pressed.emit()
		await city.get_tree().create_timer(.6).timeout
		city.refresh_inspection()
		okay = city.check(bool(city.core.query("inspect %d %d" % [site.x + 1, site.y + 1]).shut_down) and controls.switch_button.text != working, "the switch shuts the wharf down and names its new state: %s" % controls.switch_button.text) and okay
		controls.switch_button.pressed.emit()
		await city.get_tree().create_timer(.6).timeout
		city.refresh_inspection()
		okay = city.check(not bool(city.core.query("inspect %d %d" % [site.x + 1, site.y + 1]).shut_down) and controls.switch_button.text == working, "and sets it working again") and okay
	city.close_inspection()
	city.core.query("set_priority 7 5")
	city.core.simulation.replay(200, 7)
	var launched: Dictionary = city.core.query("test_trireme %d %d" % [site.x + 1, site.y + 1])
	if launched.has("protocol"):
		city.receive_state(launched)
	await city.get_tree().create_timer(.5).timeout
	var ships: Array = launched.get("walkers", []).filter(func(w): return w.asset == "trireme")
	okay = city.check(ships.size() == 1 and city.walkers.has(int(ships[0].id)) and city.walkers[int(ships[0].id)].waterborne, "the launched trireme sails on the water in the city (%d)" % ships.size()) and okay
	if ships.size() != 1:
		return okay
	var ship: Dictionary = ships[0]
	var cell := Vector2i(roundi(float(ship.x) - .5), roundi(float(ship.y) - .5))
	city.set_tool("select")
	var id: int = city.trireme_orders.trireme_at(city, cell)
	okay = city.check(id == int(ship.id), "a click by the trireme picks it") and okay
	city.trireme_orders.select(city, id)
	okay = city.check(city.trireme_orders.ring != null and city.trireme_orders.ring.get_parent() == city.walkers[id].node, "the selected trireme wears the gold ring") and okay
	var target := Vector2i(99999, 99999)
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		var distance := Vector2(point).distance_to(Vector2(cell))
		if int(tile[3]) & 4 and not int(tile[4]) and distance > 6.0 and distance < 14.0:
			target = point
			break
	if target.x != 99999:
		var start := Vector2(float(ship.x), float(ship.y))
		okay = city.check(city.trireme_orders.order(city, target), "a right click's order goes through the command queue") and okay
		await city.get_tree().create_timer(.4).timeout
		city.core.simulation.replay(120, 7)
		var after: Array = city.core.simulation.snapshot(false).walkers.filter(func(w): return int(w.id) == id)
		okay = city.check(after.size() == 1 and Vector2(float(after[0].x), float(after[0].y)).distance_to(Vector2(target)) < start.distance_to(Vector2(target)), "the trireme sails toward the water it was sent to") and okay
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	city._input(escape)
	okay = city.check(city.trireme_orders.selected == -1, "Escape lets the trireme go") and okay
	return okay

# The overview's requests and choosing several companies through the real interface: a world city's request shows on the
# City window's summary with a Send button that fulfils it; a box drawn around company banners chooses them (their rings show)
# and a right click's order sends them all; Escape lets them go.
func run_requests_units_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	var world: Dictionary = city.core.query("world")
	var partner := -1
	for index in world.cities.size():
		if bool(world.cities[index].get("can_fulfil", false)):
			partner = index
			break
	if partner >= 0:
		city.core.query("test_stock 64 40")
		var asked: Dictionary = city.core.query("test_request %d 64 8" % partner)
		var before: int = asked.get("requests", []).size()
		city.game_action("city")
		await city.get_tree().create_timer(.6).timeout
		var dialogs: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.title == city.tr("City"))
		var rows: Array = dialogs[0].bodies.overview.find_children("Request", "HBoxContainer", true, false) if dialogs.size() == 1 else []
		okay = city.check(rows.size() >= 1, "the City window's summary lists the request (%d)" % rows.size()) and okay
		var buttons: Array = rows[-1].find_children("*", "Button", true, false) if not rows.is_empty() else []
		if not buttons.is_empty():
			buttons[0].pressed.emit()
			await city.get_tree().create_timer(.6).timeout
			okay = city.check(city.core.query("world").get("requests", []).size() == before - 1, "its Send button fulfils it") and okay
		for dialog in dialogs:
			if is_instance_valid(dialog):
				dialog.queue_free()
		await city.get_tree().process_frame
	# Companies chosen by a box. Earlier checks send the city's own companies abroad, so fresh ones are raised at home first, and
	# three of them have their banners placed near one another (a flag is drawn for a placed banner).
	city.core.query("test_soldiers hoplite 48")
	var home_companies: Array = city.core.query("army").get("banners", []).filter(func(b): return not bool(b.get("abroad", false)))
	var spot := Vector2i(99999, 99999)
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		if int(tile[5]) and not int(tile[4]) and city.core.query("preview park %d %d 0" % [point.x, point.y]).get("valid", false) and city.core.query("preview park %d %d 0" % [point.x + 6, point.y]).get("valid", false):
			spot = point
			break
	for index in mini(3, home_companies.size()):
		city.core.query("banner_move %d %d %d" % [int(home_companies[index].id), spot.x + index * 3, spot.y])
	city.receive_state(city.core.simulation.snapshot(true))
	await city.get_tree().create_timer(1.2).timeout
	var flags: Array = city.army_view.flags.keys()
	okay = city.check(flags.size() >= 2, "company banners stand in the city (%d)" % flags.size()) and okay
	if flags.size() < 2:
		return okay
	var first: Node3D = city.army_view.flags[flags[0]].node
	city.orbit.target = first.global_position
	city.orbit.distance = 30.0
	city.orbit.refresh()
	await city.get_tree().create_timer(.5).timeout
	var camera: Camera3D = city.orbit.camera
	var rect := Rect2()
	var inside := []
	for id in flags:
		var node: Node3D = city.army_view.flags[id].node
		if camera.is_position_behind(node.global_position):
			continue
		var at := camera.unproject_position(node.global_position)
		if city.get_viewport().get_visible_rect().has_point(at):
			rect = Rect2(at, Vector2.ZERO) if inside.is_empty() else rect.expand(at)
			inside.append(int(id))
	rect = rect.grow(12.0)
	city.set_tool("select")
	city.unit_selection.press(city, rect.position)
	city.unit_selection.drag(city, rect.position + rect.size * .5)
	city.unit_selection.drag(city, rect.end)
	var boxed: bool = city.unit_selection.release(city, rect.end)
	okay = city.check(boxed and city.unit_selection.banners.size() == inside.size() and inside.size() >= 2 and city.unit_selection.banners.all(func(id): return city.army_view.flags[id].ring.visible),
		"a box around %d banners chooses them all, each with its ring (%d)" % [inside.size(), city.unit_selection.banners.size()]) and okay
	var target := Vector2i(99999, 99999)
	var home: Vector3 = first.global_position
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		var away := Vector2(point).distance_to(city.tile_coordinates(home))
		if int(tile[5]) and not int(tile[4]) and away > 12.0 and away < 25.0:
			target = point
			break
	if target.x != 99999 and boxed:
		okay = city.check(city.unit_selection.order(city, target), "a right click's order for the group goes through the command queue") and okay
		await city.get_tree().create_timer(.8).timeout
		# The engine spaces a group three tiles apart around the tile and avoids blocked ground, so the farthest may stand a little off.
		var group: Array = city.core.query("army").banners.filter(func(b): return int(b.id) in inside)
		var moved: Array = group.filter(func(b): return Vector2(float(b.x), float(b.y)).distance_to(Vector2(target)) <= 9.0)
		okay = city.check(moved.size() == inside.size(), "every chosen company goes there (%d of %d near %s: %s)" % [moved.size(), inside.size(), str(target), str(group.map(func(b): return [int(b.x), int(b.y)]))]) and okay
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	city._input(escape)
	okay = city.check(not city.unit_selection.has_group(city) and city.army_view.group.is_empty(), "Escape lets the group go") and okay
	city.core.send("army_home")
	await city.get_tree().create_timer(.4).timeout
	return okay

func run_controls_checks() -> bool:
	var okay := true
	var KeyBindings = preload("res://scripts/key_bindings.gd")
	var PlaySettings = preload("res://scripts/play_settings.gd")
	var previous_path: Variant = Engine.get_meta("ezeus_settings_path", "")
	var had_path := Engine.has_meta("ezeus_settings_path")
	var scratch := ProjectSettings.globalize_path("res://captures/validation-controls-ui-%d.cfg" % Time.get_ticks_usec())
	Engine.set_meta("ezeus_settings_path", scratch)
	KeyBindings.reload()
	PlaySettings.reload()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	await answer_pending()
	city.set_tool("select")
	var entries: Array = []
	for action in city.hud.GAME_ACTIONS:
		entries.append(city.hud.menu_action_text(action))
	okay = city.check(entries.has(city.tr("Controls…")) and entries.has(city.tr("Game settings…")), "the Game menu lists Controls and Game settings") and okay
	okay = city.check(city.hud.menu_action_text("quick_save").ends_with("(F5)") and city.hud.undo_button.tooltip_text.contains(KeyBindings.label("undo")), "the menu names the keys as they are now: %s" % city.hud.menu_action_text("quick_save")) and okay
	city.game_action("controls")
	await city.get_tree().create_timer(.4).timeout
	var dialogs: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.has_method("assign_from_event"))
	okay = city.check(dialogs.size() == 1 and dialogs[0].title == city.tr("Controls") and dialogs[0].key_buttons.size() == KeyBindings.actions().size(), "the Controls dialog opens with a row for each control (%d)" % (dialogs[0].key_buttons.size() if dialogs.size() == 1 else 0)) and okay
	if dialogs.size() != 1:
		return false
	var dialog = dialogs[0]
	# The placement's turn key.
	city.orientation = 0
	dialog.begin_capture("turn_placement")
	dialog.assign_from_event(key_event(KEY_U))
	await city.get_tree().process_frame
	city._unhandled_input(key_event(KEY_T))
	var after_old: int = city.orientation
	city._unhandled_input(key_event(KEY_U))
	okay = city.check(after_old == 0 and city.orientation == 1, "the placement turns with the new key (U) and no longer with T") and okay
	okay = city.check(city.hud.get_node("%RotateRight").tooltip_text.ends_with("(U)"), "and the turn button's tooltip says so: %s" % city.hud.get_node("%RotateRight").tooltip_text) and okay
	# An overlay key.
	dialog.begin_capture("overlay_water")
	dialog.assign_from_event(key_event(KEY_Y))
	await city.get_tree().process_frame
	city._unhandled_input(key_event(KEY_1))
	var after_digit: String = city.overlay_view.mode
	city._unhandled_input(key_event(KEY_Y))
	okay = city.check(after_digit == "normal" and city.overlay_view.mode == "water", "the water overlay answers to Y and no longer to 1") and okay
	city._unhandled_input(key_event(KEY_Y))
	okay = city.check(city.overlay_view.mode == "normal" and city.hud.overlay_text("water").contains("[Y]"), "pressing it again goes back to normal; the overlay menu names the key") and okay
	# Quick save, named in the Game menu.
	dialog.begin_capture("quick_save")
	dialog.assign_from_event(key_event(KEY_F8))
	await city.get_tree().process_frame
	okay = city.check(city.hud.menu_action_text("quick_save").ends_with("(F8)"), "the Game menu entry for the quick save names F8") and okay
	# A held camera key, and a swap in words.
	dialog.begin_capture("orbit_left")
	dialog.assign_from_event(key_event(KEY_E))
	var held := InputMap.action_get_events("orbit_left")
	okay = city.check(held.size() == 1 and int(held[0].physical_keycode) == KEY_E and InputMap.action_get_events("orbit_right")[0].physical_keycode == KEY_Q and dialog.message.text.contains("Q"), "Orbit left takes E from Orbit right, which takes Q (the held keys follow): %s" % dialog.message.text) and okay
	city.update_hint()
	okay = city.check(city.hint.text.contains("E / Q"), "the hint names the camera keys now: %s" % city.hint.text) and okay
	# The world map's own key.
	dialog.begin_capture("world_map")
	dialog.assign_from_event(key_event(KEY_F7))
	var map = city.world_map
	city._unhandled_input(key_event(KEY_F2))
	await wait_world_flight()
	var shown_by_old: bool = map != null and map.visible
	city._unhandled_input(key_event(KEY_F7))
	await wait_world_flight()
	okay = city.check(not shown_by_old and map != null and map.visible, "the world map opens with F7 and not with F2") and okay
	map._input(key_event(KEY_F7))
	await wait_world_flight()
	okay = city.check(not map.visible, "and the same key closes it") and okay
	# Everything back.
	dialog.restore_defaults()
	await city.get_tree().process_frame
	okay = city.check(not KeyBindings.any_custom() and KeyBindings.label("turn_placement") == "T" and city.hud.get_node("%RotateRight").tooltip_text.ends_with("(T)") and city.hud.menu_action_text("quick_save").ends_with("(F5)"), "Restore defaults gives every control its key again, and the menus say so") and okay
	city.orientation = 0
	city._unhandled_input(key_event(KEY_T))
	okay = city.check(city.orientation == 1, "T turns the placement again") and okay
	city.orientation = 0
	dialog.close()
	await city.get_tree().process_frame
	# The Game settings.
	city.game_action("settings")
	await city.get_tree().create_timer(.4).timeout
	var settings: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.has_method("option_row"))
	okay = city.check(settings.size() == 1 and settings[0].title == city.tr("Game settings") and city.autosave_interval == city.AUTOSAVE_SECONDS, "the Game settings dialog opens; the city autosaves every %d seconds" % int(city.autosave_interval)) and okay
	if settings.size() == 1:
		settings[0].choices.autosave_minutes.item_selected.emit(PlaySettings.OPTIONS.autosave_minutes[2].find(15))
		settings[0].choices.autosave_slots.item_selected.emit(PlaySettings.OPTIONS.autosave_slots[2].find(5))
		okay = city.check(is_equal_approx(city.autosave_interval, 900.0) and city.autosave_slots == 5, "choosing fifteen minutes and five slots changes the running city's autosave at once") and okay
		settings[0].choices.autosave_minutes.item_selected.emit(0)
		okay = city.check(city.autosave_interval == 0.0, "'Off' stops it") and okay
		settings[0].queue_free()
	await city.get_tree().process_frame
	# Restore the city's own settings.
	PlaySettings.reload()
	KeyBindings.reload()
	KeyBindings.apply_input_map()
	if had_path:
		Engine.set_meta("ezeus_settings_path", previous_path)
	else:
		Engine.remove_meta("ezeus_settings_path")
	DirAccess.remove_absolute(scratch)
	city.autosave_interval = city.AUTOSAVE_SECONDS
	city.autosave_slots = city.AUTOSAVE_SLOTS
	KeyBindings.reload()
	PlaySettings.reload()
	city.hud.retranslate()
	return okay

# A hero's hall through the real interface (run last: the hero joins the city's defence and hunts monsters): a god's quest lets the
# city build the hero's hall, so the Build menu lists "Heroes' halls"; the hall's inspector lists the requirements with how far the
# city is from them and a Summon button that stays off while one is unmet; once the hero has arrived the inspector says so, he slays the
# monster he is the slayer of (the monster notice counts one less) and the world map's quests list lets the player send him on the quest.
func run_hero_checks() -> bool:
	var okay := true
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	await answer_pending()
	okay = city.check(city.hud.build_groups.all(func(g): return g.items.all(func(item): return item.name != "hero_hall_perseus")), "before the god asks for Perseus the Build menu does not offer his hall") and okay
	city.core.query("test_quest hades 1")
	city.refresh_catalog()
	var group: Array = city.hud.build_groups.filter(func(g): return g.title == "Heroes' halls")
	var offered: Array = group[0].items.filter(func(item): return item.name == "hero_hall_perseus") if group.size() == 1 else []
	okay = city.check(offered.size() == 1 and offered[0].label == "Hero's Hall for Perseus", "the god's quest puts the hero's hall in the Build menu %s" % str(group.map(func(g): return g.items.map(func(i): return i.name)))) and okay
	var site := Vector2i(99999, 99999)
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		if city.core.query("preview hero_hall_perseus %d %d 0" % [point.x, point.y]).get("valid", false):
			site = point
			break
	okay = city.check(site != Vector2i(99999, 99999), "the hall has a free site") and okay
	var built: Dictionary = city.core.query("build hero_hall_perseus %d %d 0" % [site.x, site.y])
	okay = city.check(not built.has("error"), "the hall is built (%s)" % str(built.get("error", "ok"))) and okay
	city.refresh_catalog()
	okay = city.check(city.hud.build_groups.all(func(g): return g.items.all(func(item): return item.name != "hero_hall_perseus")), "and, being built, is no longer offered") and okay
	city.inspected = site
	city.refresh_inspection()
	await city.get_tree().process_frame
	var controls: VBoxContainer = city.inspector_controls
	okay = city.check(controls.hall_rows.size() >= 4 and controls.summon_button != null and controls.summon_button.visible and controls.summon_button.disabled, "the hall's inspector lists %d requirements and its Summon button is off" % controls.hall_rows.size()) and okay
	okay = city.check(controls.hall_stage_label.text == city.tr("The hero has not been summoned yet.") and controls.summon_button.text.begins_with(city.tr("Summon %s").split("%s")[0]), "it says the hero has not been summoned and offers to summon him: %s" % controls.summon_button.text) and okay
	okay = city.check(controls.hall_rows.all(func(row): return row.text.contains("  ·  ")), "each requirement shows what the city has: %s" % controls.hall_rows[0].text) and okay
	city.core.query("test_hero perseus")
	city.refresh_inspection()
	await city.get_tree().process_frame
	okay = city.check(controls.hall_stage_label.text == city.tr("The hero is in the city and defends it.") and not controls.summon_button.visible, "once he has come the inspector says so: %s" % controls.hall_stage_label.text) and okay
	# The monsters left loose by the monster checks: Perseus slays the kraken, the minotaur stays (Theseus has not come).
	var before: int = int(city.state.get("monsters", 0))
	city.core.send("speed 3")
	city.core.send("pause 0")
	var elapsed := 0.0
	while elapsed < 60.0 and int(city.state.get("monsters", 0)) >= before and before > 0:
		await city.get_tree().process_frame
		elapsed += city.get_process_delta_time()
		for event in city.state.get("events", []):
			var choices: Array = event.get("actions", [])
			city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
	city.core.send("pause 1")
	okay = city.check(before >= 1 and int(city.state.get("monsters", 0)) < before, "the hero slays the monster he is the slayer of: the notice counts %d monster(s), was %d" % [int(city.state.get("monsters", 0)), before]) and okay
	await city.get_tree().create_timer(.4).timeout
	# The quest: the world map lists it with its hero ready, and sending him takes it off the list.
	var wm = city.world_map
	city.game_action("world")
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(not wm.quests_button.disabled and wm.quests_button.text.contains("("), "the world map offers the gods' quests: %s" % wm.quests_button.text) and okay
	var asked: int = wm.world.quests.size()
	wm.quests_button.pressed.emit()
	await city.get_tree().process_frame
	var send_prefix: String = city.tr("Send %s").split("%s")[0]
	var sends: Array = wm.dialog.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with(send_prefix))
	var ready: Array = sends.filter(func(b): return not b.disabled)
	okay = city.check(sends.size() == asked and ready.size() == 1, "the quest dialog lists %d quests and the arrived hero can be sent (%d)" % [sends.size(), ready.size()]) and okay
	if ready.size() == 1:
		ready[0].pressed.emit()
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(wm.world.quests.size() == asked - 1, "sending him takes the quest off the list") and okay
	wm.close()
	await city.get_tree().create_timer(.3).timeout
	return okay

# A monster loose in the city through the real interface (run after the fights, as it leaves the monster at large): the red notice
# names it and takes the camera to it, its model carries walk, fight and die clips that play through the pose shader, and the
# notice follows the interface language. A land monster and a sea monster (which stands in the water, not on the shore).
func run_monster_checks() -> bool:
	var okay := true
	var WalkerCombat = preload("res://scripts/walker_combat.gd")
	city.core.simulation.enable_test_commands()
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(not city.invasion_banner.visible, "before a monster comes the notice is hidden") and okay
	var landed: Dictionary = city.core.query("test_monster minotaur")
	okay = city.check(int(landed.get("monsters", 0)) == 1, "a minotaur is let loose (%s)" % str(landed.get("error", "ok"))) and okay
	await city.get_tree().create_timer(.6).timeout
	var notice: String = city.invasion_banner.label.text
	okay = city.check(city.invasion_banner.visible and notice.begins_with(city.tr("A monster stalks the city: %s").split("%s")[0]) and notice.length() > 22, "the notice names the monster: %s" % notice) and okay
	var at: Vector2i = city.invasion_banner.at
	var home_target: Vector3 = city.orbit.target
	city.orbit.target = Vector3(home_target.x + 40.0, home_target.y, home_target.z)
	city.invasion_banner.show_button.pressed.emit()
	await city.get_tree().create_timer(.3).timeout
	var seen: Vector2 = city.tile_coordinates(city.orbit.target)
	okay = city.check(city.invasion_banner.show_button.text == city.tr("Go to the monster") and seen.distance_to(Vector2(at)) < 2.0, "its button takes the camera to the monster (%s, the camera at %s)" % [str(at), str(seen)]) and okay
	city.orbit.target = home_target
	city.orbit.refresh()
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	var other_language: String = city.invasion_banner.label.text
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(other_language != city.invasion_banner.label.text, "the notice follows the interface language") and okay
	var minotaurs: Array = city.walkers.values().filter(func(e): return e.asset == "walker_minotaur")
	okay = city.check(minotaurs.size() == 1 and minotaurs[0].clips.has("fight") and minotaurs[0].clips.has("fight2") and minotaurs[0].clips.has("die") and not minotaurs[0].morphs.is_empty(), "the minotaur's model carries its fight and die clips (%d walkers)" % minotaurs.size()) and okay
	if minotaurs.size() == 1:
		var entry: Dictionary = minotaurs[0]
		var morph = entry.morphs[0]
		var checked := {}
		for action in [[4, "fight"], [5, "fight2"], [6, "die"]]:
			entry.action = action[0]
			for round in 3:
				WalkerCombat.animate(entry, .25)
			var pose: Vector3 = morph.node.get_instance_shader_parameter("vat_pose")
			var indices: Array = entry.clips[action[1]].map(func(n): return int(morph.table[n]))
			checked[action[1]] = int(pose.x) in indices and int(pose.y) in indices and morph.node.get_instance_shader_parameter("vat_walk_blend") == 1.0
		okay = city.check(checked.values().all(func(v): return v), "the monster plays its fight, fight2 and die clips through the pose shader %s" % str(checked)) and okay
		entry.action = 3
		WalkerCombat.animate(entry, .1)
	var sea: Dictionary = city.core.query("test_monster kraken")
	okay = city.check(int(sea.get("monsters", 0)) == 2, "a kraken is let loose as well (%s)" % str(sea.get("error", "ok"))) and okay
	await city.get_tree().create_timer(.6).timeout
	var krakens: Array = city.walkers.values().filter(func(e): return e.asset == "walker_kraken")
	okay = city.check(krakens.size() == 1, "the kraken has its own model (%d walkers)" % krakens.size()) and okay
	okay = city.check(city.invasion_banner.label.text.contains("2") or city.invasion_banner.label.text.length() > 10, "two monsters are announced together: %s" % city.invasion_banner.label.text) and okay
	city.core.send("pause 1")
	await city.get_tree().create_timer(.4).timeout
	return okay

# The military dealings through the real interface (run last: they let the game run and answer its decisions): the world map's Raid
# opens the enlist dialog with what the core offers, "Enlist all" and Send put an army on the road (the map draws it, the companies
# are abroad), a second look shows them abroad and unselectable, Aid asks a regarding city for troops, and a troop request's
# "send troops" decision opens the same dialog over the city and is answered when the troops are sent.
func run_military_checks() -> bool:
	var okay := true
	var wm = city.world_map
	city.core.simulation.enable_test_commands()
	city.core.query("test_soldiers hoplite 24")
	city.core.query("test_troops 3 5")
	# The allies' regard falls as the run goes on (requests are refused as they fall due); only allies that regard the player (over 50) can be enlisted.
	for index in [4, 5, 6]:
		city.core.query("test_attitude %d 80" % index)
	city.core.send("pause 1")
	await city.get_tree().create_timer(.3).timeout
	city.game_action("world")
	await city.get_tree().create_timer(.6).timeout
	wm.select_city(3)
	await city.get_tree().process_frame
	okay = city.check(not wm.raid_button.disabled and not wm.conquer_button.disabled and wm.raid_button.tooltip_text != "", "an ally can be raided or conquered: the buttons are on (%s)" % wm.raid_button.tooltip_text) and okay
	wm.raid_button.pressed.emit()
	await city.get_tree().process_frame
	var dialog = wm.enlisting
	okay = city.check(dialog != null and wm.dialog == dialog.window and dialog.window.title == city.tr("Raid on %s") % wm.find_city(3).name, "Raid opens the enlist dialog for that city (%s)" % (dialog.window.title if dialog != null else "none")) and okay
	var rows: Array = dialog.buttons if dialog != null else []
	var soldier_rows: Array = rows.filter(func(r): return r.kind == "s")
	okay = city.check(soldier_rows.size() >= 3 and rows.any(func(r): return r.kind == "a") and dialog.plunder != null and dialog.plunder.item_count >= 3, "it lists the companies and the allies' troops the core offers (and a hero when one is in the city), with a plunder to choose (%d rows)" % rows.size()) and okay
	dialog.send()
	okay = city.check(dialog.status.text == city.tr("Choose at least one company or hero first."), "sending nothing is refused with the reason") and okay
	dialog.enlist_all()
	await city.get_tree().process_frame
	okay = city.check(dialog.chosen_soldiers.size() >= 3 and dialog.chosen_ally >= 0 and dialog.summary.text.contains("%d" % dialog.chosen_soldiers.size()), "Enlist all chooses every company and one allied city (%s)" % dialog.summary.text) and okay
	var second_ally: Array = rows.filter(func(r): return r.kind == "a")
	if second_ally.size() >= 2:
		second_ally[1].button.button_pressed = true
		okay = city.check(second_ally[0].button.button_pressed == false and dialog.chosen_ally == int(second_ally[1].key), "choosing a second allied city replaces the first") and okay
	dialog.send()
	await city.get_tree().create_timer(.4).timeout
	# The troops of the allied city go along as an army of their own.
	var raid_armies: Array = wm.world.armies.filter(func(a): return a.reason == "raid")
	okay = city.check(wm.enlisting == null and wm.dialog == null and raid_armies.any(func(a): return int(a.from) == 0 and int(a.to) == 3) and wm.status.text == city.tr("The army sets out for %s.") % wm.find_city(3).name, "Send puts the army on the road and the map says so (%d armies, status: %s)" % [raid_armies.size(), wm.status.text]) and okay
	okay = city.check(wm.armies_layer.armies.size() == raid_armies.size() and wm.armies_layer.positions.has(3), "the map draws the armies on their road") and okay
	var abroad: Array = city.core.query("army").banners.filter(func(b): return b.abroad)
	okay = city.check(abroad.size() >= 3, "the enlisted companies are abroad (%d)" % abroad.size()) and okay
	wm.raid_button.pressed.emit()
	await city.get_tree().process_frame
	dialog = wm.enlisting
	var abroad_rows: Array = dialog.buttons.filter(func(r): return r.kind == "s" and r.button.disabled and r.button.text.contains(city.tr("(abroad)")))
	okay = city.check(abroad_rows.size() >= 3, "a second look shows those companies abroad and unselectable") and okay
	dialog.cancel()
	await city.get_tree().process_frame
	okay = city.check(wm.enlisting == null and wm.dialog == null and city.core.query("enlist").get("error", "") == "no_enlistment", "Cancel closes the dialog and drops the enlisting in the core") and okay
	# Aid: a city that regards the player enough is asked for troops.
	city.core.query("test_attitude 5 90")
	wm.close()
	city.game_action("world")
	await city.get_tree().create_timer(.5).timeout
	wm.select_city(5)
	await city.get_tree().process_frame
	okay = city.check(not wm.aid_button.disabled, "Aid is on for a city that regards the player") and okay
	var regard_before: int = int(wm.find_city(5).attitude)
	wm.aid_button.pressed.emit()
	await city.get_tree().process_frame
	var request_aid: Array = wm.dialog.find_children("*", "Button", true, false).filter(func(b): return b.text == city.tr("Request defensive aid"))
	okay = city.check(request_aid.size() == 1, "the aid dialog offers the request") and okay
	if request_aid.size() == 1:
		request_aid[0].pressed.emit()
		await city.get_tree().process_frame
		okay = city.check(int(wm.find_city(5).attitude) == regard_before - 20 and wm.status.text.contains(wm.find_city(5).name), "asking for aid costs regard as the engine says (%d to %d)" % [regard_before, int(wm.find_city(5).attitude)]) and okay
	wm.close()
	# A troop request: its decision has a working "send troops" choice.
	city.core.query("test_relationship 3 rival")
	city.core.query("test_attitude 4 90")
	city.core.query("test_troops_request 4 3")
	city.core.send("speed 3")
	city.core.send("pause 0")
	var request_button: Button
	var waited := 0.0
	while waited < 60.0 and request_button == null:
		await city.get_tree().process_frame
		waited += city.get_process_delta_time()
		for event in city.state.get("events", []):
			var choices: Array = event.get("actions", [])
			if choices.any(func(c): return int(c.choice) == -2):
				var wanted := str(choices.filter(func(c): return int(c.choice) == -2)[0].label)
				for child in city.hud.get_node("%EventActions").get_children():
					if child is Button and child.text == wanted:
						request_button = child
			else:
				city.core.send("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
	okay = city.check(request_button != null and not request_button.disabled, "a city's request for troops shows a \"send troops\" button that is enabled") and okay
	if request_button != null:
		# The decision holds the clock; companies added now stay (housing would take the test's hoplites away once time runs).
		city.core.query("test_soldiers hoplite 16")
		request_button.pressed.emit()
		await city.get_tree().process_frame
		var troop_dialog = city.enlist_dialog
		okay = city.check(troop_dialog != null and troop_dialog.window.title == city.tr("Troops to send"), "it opens the same dialog over the city") and okay
		if troop_dialog != null:
			troop_dialog.enlist_all()
			troop_dialog.send()
			await city.get_tree().create_timer(.6).timeout
			var still_asking: bool = city.core.query("world").troop_requests > 0 or city.state.get("events", []).any(func(e): return e.actions.any(func(c): return int(c.choice) == -2))
			okay = city.check(city.enlist_dialog == null and city.core.query("world").armies.any(func(a): return a.reason == "help") and not still_asking, "sending the troops answers the request and puts the help on the road (%s)" % city.hint.text) and okay
	city.core.send("pause 1")
	await city.get_tree().create_timer(.4).timeout
	return okay

# Markets through the real interface: the Build menu picks the agora, the pointer shows the footprint over the road
# and the free ground beside it, a click lays it, and the vendor tools fill its empty spaces.
func run_market_checks() -> bool:
	var okay := true
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var site := Vector2i(99999, 99999)
	var nearest := INF
	for point in city.tiles:
		var distance: float = city.world_position(point.x, point.y, 0).distance_squared_to(saved_target)
		if distance >= nearest:
			continue
		if city.core.query("preview common_agora %d %d 0" % [point.x, point.y]).get("valid", false):
			site = point
			nearest = distance
	okay = city.check(site != Vector2i(99999, 99999), "a site for an agora is available for the market regression") and okay
	if site == Vector2i(99999, 99999):
		return false
	var quoted: Dictionary = city.core.query("preview common_agora %d %d 0" % [site.x, site.y])
	city.orbit.target = city.world_position(site.x + 1, site.y - 1, city.tiles[site][2])
	city.orbit.distance = 16
	city.orbit.yaw = 45
	city.orbit.snap_to_ground()
	await city.get_tree().physics_frame
	okay = city.check(city.hud.activate_building("common_agora") and city.mode == "common_agora", "the Build menu offers the common agora and selects it") and okay
	city.pick_tile(tile_screen(site))
	city.refresh_placement()
	okay = city.check(city.footprint_cells.get_child_count() == 18 and city.hint.text.contains("%d" % int(quoted.cost)), "the pointer shows the 18 tiles of the agora with its cost (%d)" % int(quoted.cost)) and okay
	var money_before: int = city.state.money
	city._unhandled_input(mouse_event(tile_screen(site), true))
	city._unhandled_input(mouse_event(tile_screen(site), false))
	await city.get_tree().create_timer(.6).timeout
	var spaces: Array = city.state.buildings.filter(func(b): return b.asset == "agora_space")
	okay = city.check(spaces.size() == 3 and int(city.state.money) == money_before - int(quoted.cost) and city.state.undo_available, "a click lays the agora with three empty spaces for the quoted cost") and okay
	await city.get_tree().create_timer(.4).timeout
	var space: Dictionary = spaces[0]
	okay = city.check(city.hud.activate_building("food_vendor") and city.mode == "food_vendor", "the Build menu selects the food vendor") and okay
	var cell := Vector2i(space.x, space.y)
	city.pick_tile(tile_screen(cell))
	city.refresh_placement()
	okay = city.check(city.footprint_cells.get_child_count() == 4 and city.placement_result.valid, "the vendor tool outlines the empty space under the pointer") and okay
	var vendor_cost: int = int(city.placement_result.cost)
	money_before = city.state.money
	city._unhandled_input(mouse_event(tile_screen(cell), true))
	city._unhandled_input(mouse_event(tile_screen(cell), false))
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(city.state.buildings.any(func(b): return b.asset == "food_vendor" and b.x == space.x and b.y == space.y) and int(city.state.money) == money_before - vendor_cost, "a click puts a food vendor on the space for its cost (%d)" % vendor_cost) and okay
	city.set_tool("oil_vendor")
	var next: Dictionary = spaces[1]
	city.pick_tile(tile_screen(Vector2i(next.x, next.y)))
	city.refresh_placement()
	city._unhandled_input(mouse_event(tile_screen(Vector2i(next.x, next.y)), true))
	city._unhandled_input(mouse_event(tile_screen(Vector2i(next.x, next.y)), false))
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(city.state.buildings.any(func(b): return b.asset == "oil_vendor"), "the next space takes an oil vendor") and okay
	var markets: Array = city.hud.build_groups.filter(func(g): return g.title == "Markets")
	var market_names: Array = markets[0].items.map(func(i): return i.name) if not markets.is_empty() else []
	okay = city.check(["wine_vendor", "arms_vendor", "chariot_vendor"].all(func(n): return n in market_names), "the Markets menu offers the wine, arms and chariot vendors too") and okay
	city.set_tool("wine_vendor")
	var last: Dictionary = spaces[2]
	city.pick_tile(tile_screen(Vector2i(last.x, last.y)))
	city.refresh_placement()
	city._unhandled_input(mouse_event(tile_screen(Vector2i(last.x, last.y)), true))
	city._unhandled_input(mouse_event(tile_screen(Vector2i(last.x, last.y)), false))
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(city.state.buildings.any(func(b): return b.asset == "wine_vendor") and city.model_file_exists("wine_vendor") and city.model_file_exists("arms_vendor") and city.model_file_exists("horse_vendor") and city.model_file_exists("chariot_vendor"), "the last space takes a wine vendor and all four new stalls have models") and okay
	city.set_tool("select")
	city.orbit.distance = 12
	city.orbit.refresh()
	await city.get_tree().create_timer(.4).timeout
	var original_capture: String = city.capture_path
	var review_dir: String = original_capture.get_base_dir()
	if review_dir.is_empty():
		review_dir = ProjectSettings.globalize_path("res://captures")
	city.capture_path = review_dir.path_join("market-%s.png" % city.language)
	await city.capture()
	city.capture_path = original_capture
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay

# Objectives and the way back to the menu: the test city carries a real episode, so its objectives panel must list
# them with live status, follow the language, and the Game menu must offer the main menu behind a confirmation.
func run_objective_checks() -> bool:
	var okay := true
	await city.get_tree().create_timer(2.6).timeout
	var episode: Dictionary = city.core.query("episode")
	var goals: Array = episode.get("goals", [])
	okay = city.check(goals.size() == 4 and city.hud.goals_panel.visible and city.hud.goals_list.get_child_count() == 4, "the objectives panel lists the episode's four objectives") and okay
	var summary: Label = city.hud.get_node("%GoalsSummary")
	okay = city.check(city.hud.goals_title.text == city.tr("Objectives") and summary.text == city.tr("%d of %d achieved") % [int(episode.met), int(episode.total)], "its header counts the objectives met (%s)" % summary.text) and okay
	var met := 0
	for goal in goals:
		met += 1 if goal.met else 0
	okay = city.check(met == int(episode.met) and goals.any(func(goal): return not str(goal.status).is_empty()), "each objective carries its status text") and okay
	city.hud.set_goals_expanded(true)
	city.hud.goals_toggle.pressed.emit()
	okay = city.check(not city.hud.goals_list.visible, "the objectives can be folded away") and okay
	city.hud.goals_toggle.pressed.emit()
	okay = city.check(city.hud.goals_list.visible, "and shown again") and okay
	var labels: Array = []
	for action in city.hud.GAME_ACTIONS:
		labels.append(city.hud.menu_action_text(action))
	okay = city.check(city.tr("Main menu") in labels, "the Game menu offers the main menu") and okay
	city.game_action("main_menu")
	okay = city.check(city.hud.menu_dialog.visible and city.hud.menu_dialog.dialog_text == city.tr("Return to the main menu? Progress since your last save is lost."), "the main menu asks before leaving") and okay
	city.hud.menu_dialog.hide()
	okay = city.check(city.current_scene_is_city(), "declining stays in the city") and okay
	return okay

func key_event(code: Key, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	return event

# City overlays through the real interface: hotkeys, the menu, building and walker filters, the value columns and the
# appeal decal, the legend, the language, and Escape.
func run_overlay_checks() -> bool:
	var okay := true
	var view = city.overlay_view
	okay = city.check(view.mode == "normal" and not view.columns.visible and city.hud.overlay_menu.tooltip_text == city.tr("Overlays") + " ▾", "the city starts in the normal view") and okay
	var hospital := {}
	for building in city.state.buildings:
		if building.asset == "hospital":
			hospital = building
			break
	var walkers_before: int = city.walkers.size()
	city._unhandled_input(key_event(KEY_1))
	await city.get_tree().create_timer(.5).timeout
	var water: Dictionary = city.core.query("overlay water")
	okay = city.check(view.mode == "water" and view.column_count == water.columns.size() and view.column_count > 0 and view.columns.visible, "the 1 key shows the water overlay with its columns (%d)" % view.column_count) and okay
	okay = city.check(city.hud.overlay_legend.visible and city.hud.overlay_legend.text == city.tr(city.Overlays.MODES.water[1]) and city.hud.overlay_menu.tooltip_text == city.tr("Water and fountains") + " ▾", "the menu button and legend name it") and okay
	okay = city.check(not hospital.is_empty() and not view.building_visible(hospital), "a hospital lies flat under the water overlay") and okay
	var shown := 0
	for entry in city.walkers.values():
		shown += 1 if entry.node.visible else 0
	var distributors := 0
	for entry in city.walkers.values():
		distributors += 1 if view.walker_kinds.has(entry.type) else 0
	okay = city.check(city.walkers.size() == walkers_before and shown == distributors, "only the water carriers stay visible (%d of %d)" % [shown, walkers_before]) and okay
	city._unhandled_input(key_event(KEY_1))
	await city.get_tree().create_timer(.5).timeout
	var all_back := true
	for entry in city.walkers.values():
		all_back = all_back and entry.node.visible
	okay = city.check(view.mode == "normal" and not view.columns.visible and all_back and not city.hud.overlay_legend.visible, "pressing 1 again goes back to the normal view") and okay
	# Number keys and Tab, delivered through the real input pipeline.
	Input.parse_input_event(key_event(KEY_4))
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(view.mode == "hazards" and view.column_count > 0, "the 4 key shows fire and collapse risk (%d columns)" % view.column_count) and okay
	Input.parse_input_event(key_event(KEY_TAB))
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(view.mode == "problems", "Tab shows the city problems") and okay
	city._unhandled_input(key_event(KEY_0))
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(view.mode == "normal", "0 returns to the normal view") and okay
	# Taxes: unpaid houses get a short red stub.
	city._unhandled_input(key_event(KEY_6))
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(view.mode == "taxes" and view.column_count > 0, "the 6 key shows tax collection") and okay
	# Supplies draw markers, three per house.
	city._unhandled_input(key_event(KEY_2))
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(view.mode == "supplies" and view.marker_count >= 3 and view.markers.visible and not view.columns.visible, "the 2 key shows supply markers instead of columns (%d)" % view.marker_count) and okay
	# Appeal paints the ground through a decal.
	city._unhandled_input(key_event(KEY_5))
	await city.get_tree().create_timer(.6).timeout
	okay = city.check(view.mode == "appeal" and view.decal != null and view.decal.visible and view.decal.texture_albedo != null and view.decal.texture_albedo.get_width() >= city.extent.x, "the 5 key paints the ground with the appeal decal") and okay
	await city.get_tree().create_timer(.8).timeout
	var original_capture: String = city.capture_path
	var review_dir: String = original_capture.get_base_dir()
	if review_dir.is_empty():
		review_dir = ProjectSettings.globalize_path("res://captures")
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var sum := Vector2.ZERO
	var count := 0
	for building in city.state.buildings:
		if str(building.asset).begins_with("common_house"):
			sum += Vector2(building.x, building.y)
			count += 1
	if count > 0:
		var middle := sum / count
		city.orbit.target = city.world_position(middle.x, middle.y, 0)
		city.orbit.distance = 26
		city.orbit.yaw = 35
		city.orbit.snap_to_ground()
	for id in ["hazards", "appeal", "water"]:
		city.set_overlay(id)
		await city.get_tree().create_timer(1.2).timeout
		city.capture_path = review_dir.path_join("overlay-%s-%s.png" % [id, city.language])
		await city.capture()
	city.capture_path = original_capture
	# The menu, including a submenu entry; the language follows.
	okay = city.check(city.hud.activate_overlay("all_science") and view.mode == "all_science", "the Science submenu selects all-science") and okay
	okay = city.check(city.hud.overlay_popups.has("actors") and city.hud.overlay_popups.actors[0] != city.hud.overlay_menu.get_popup(), "Culture and Science are submenus") and okay
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(city.hud.overlay_menu.tooltip_text == city.tr("All science") + " ▾" and city.hud.overlay_legend.text == city.tr(city.Overlays.MODES.all_science[1]), "changing language re-translates the overlay button and legend") and okay
	city.change_language()
	await city.get_tree().create_timer(.3).timeout
	# Selecting the active overlay again, and Escape, return to normal.
	city.hud.activate_overlay("all_science")
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(view.mode == "normal", "choosing the active overlay again switches it off") and okay
	city.hud.activate_overlay("unrest")
	await city.get_tree().create_timer(.3).timeout
	city.set_tool("select")
	city._input(key_event(KEY_ESCAPE))
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(view.mode == "normal" and not view.columns.visible and not view.markers.visible and (view.decal == null or not view.decal.visible), "Escape returns to the normal view and clears every overlay drawing") and okay
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay

# Sound through the real interface. Validation runs are silent, so the manager is switched on here with the master bus
# muted and a scratch settings file: the checks read what was asked to play and which players are running.
func run_audio_checks() -> bool:
	var okay := true
	var scratch := ProjectSettings.globalize_path("res://captures/validation-sound-%d.cfg" % Time.get_ticks_usec())
	Engine.set_meta("ezeus_settings_path", scratch)
	var was_enabled: bool = GameAudio.enabled
	GameAudio.enabled = true
	GameAudio.set_muted(true)
	GameAudio.log.clear()
	GameAudio.last_played.clear()
	# The live core keeps sending snapshots (with `music: city`); hold them back so the test chooses what arrives.
	city.core.set_process(false)
	# The city's music starts from the first snapshot and a battle request switches it.
	GameAudio.music_kind = ""
	city.receive_state(city.state.duplicate())
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(GameAudio.music_kind == "city" and GameAudio.music.playing and GameAudio.music.bus == "Music", "the city plays peaceful music on the Music bus") and okay
	var battle: Dictionary = city.state.duplicate()
	battle.music = "battle"
	city.receive_state(battle)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(GameAudio.music_kind == "battle" and GameAudio.music_track.contains("Battle"), "the core's battle request switches to battle music") and okay
	var peaceful: Dictionary = city.state.duplicate()
	peaceful.music = "city"
	city.receive_state(peaceful)
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(GameAudio.music_kind == "city", "and back to peaceful music when it ends") and okay
	# Sounds from a snapshot play on their buses.
	var with_sounds: Dictionary = city.state.duplicate()
	with_sounds.sounds = ["Audio/Wavs/fire.wav", "Audio/Ambient/Layer2/maintenance1.wav"]
	GameAudio.log.clear()
	city.receive_state(with_sounds)
	var asked_paths: Array = GameAudio.log.map(func(entry): return entry.path)
	okay = city.check(GameAudio.busy_effects() >= 2 and asked_paths.has("Audio/Wavs/fire.wav") and asked_paths.has("Audio/Ambient/Layer2/maintenance1.wav"), "the sounds the simulation asked for play at once (%d voices)" % GameAudio.busy_effects()) and okay
	# A click on a building plays that kind of building's sound.
	var granary := {}
	for building in city.state.buildings:
		if building.asset == "granary":
			granary = building
			break
	GameAudio.log.clear()
	GameAudio.last_played.clear()
	city.orbit.target = city.world_position(granary.x + 1, granary.y + 1, granary.altitude)
	city.orbit.distance = 16
	city.orbit.snap_to_ground()
	await city.get_tree().physics_frame
	city.set_tool("select")
	city._unhandled_input(mouse_event(tile_screen(Vector2i(granary.x, granary.y)), true))
	await city.get_tree().create_timer(.3).timeout
	okay = city.check(GameAudio.log.any(func(entry): return entry.path.begins_with("Audio/Ambient/Layer2/")), "clicking a building plays its sound") and okay
	# Ambient sound from the middle of the view.
	GameAudio.log.clear()
	GameAudio.last_played.clear()
	var heard: Array = []
	for i in 12:
		heard.append_array(GameAudio.request_ambient(city.core, city.ambient_tile()))
	okay = city.check(heard.size() > 0 and GameAudio.log.size() > 0 and GameAudio.log.all(func(entry): return entry.path.begins_with("Audio/Ambient/") or entry.path.begins_with("Audio/Wavs/")), "the view's surroundings answer with ambient sounds (%d)" % heard.size()) and okay
	# The M key and the Sound dialog.
	var before_muted: bool = GameAudio.muted()
	city._unhandled_input(key_event(KEY_M))
	okay = city.check(GameAudio.muted() != before_muted and city.hint.text == city.tr("Sound on" if before_muted else "Sound off"), "the M key switches the sound off and on") and okay
	city._unhandled_input(key_event(KEY_M))
	city.game_action("sound")
	await city.get_tree().create_timer(.4).timeout
	var dialog: Window = null
	for child in city.hud.get_children():
		if child is AcceptDialog and child.has_method("_ready") and child.get("sliders") != null and not child.sliders.is_empty():
			dialog = child
	okay = city.check(dialog != null and dialog.visible and dialog.sliders.size() == 5, "Game, Sound opens the sound settings with five sliders") and okay
	if dialog != null:
		dialog.sliders["Music"].value = .35
		okay = city.check(absf(GameAudio.volume("Music") - .35) < .001 and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(.35)) < .02, "moving a slider changes that bus and is remembered") and okay
		dialog.hide()
		dialog.queue_free()
	GameAudio.set_volume("Music", .7)
	GameAudio.stop_music(.1)
	await city.get_tree().create_timer(.3).timeout
	GameAudio.music.stop()
	GameAudio.music_fading.stop()
	for item in GameAudio.pool:
		item.stop()
	GameAudio.set_muted(false)
	city.core.set_process(true)
	GameAudio.enabled = was_enabled
	Engine.remove_meta("ezeus_settings_path")
	DirAccess.remove_absolute(scratch)
	return okay

# The campaign screens' host: the city carries the overlay (hidden while playing), the episode query names the episode, and
# a result card shows over the city and goes away again. (The whole flow is in validate_campaign_ui.gd.)
func run_campaign_checks() -> bool:
	var okay := true
	var overlay = city.episode_overlay
	var episode: Dictionary = city.core.query("episode")
	okay = city.check(overlay != null and not overlay.visible and not episode.victory and not episode.defeat and episode.episode_count >= 1 and episode.episode_number >= 1, "the city hosts the campaign screens, hidden while the episode is played (episode %d of %d)" % [episode.episode_number, episode.episode_count]) and okay
	var aside := 0
	for line in city.hud.goals_list.get_children():
		for node in line.get_children():
			aside += 1 if node is Button else 0
	okay = city.check(aside == 0 and episode.goals.all(func(goal): return goal.has("index") and not goal.set_aside), "no objective offers to set goods aside in the test city") and okay
	overlay.show_result({"victory": false})
	okay = city.check(overlay.visible and overlay.card.mode == "defeat" and overlay.card.primary.text == city.tr("Main menu") and overlay.card.heading.text == city.tr("Defeat"), "a result card covers the city and speaks the interface language") and okay
	overlay.visible = false
	return okay

# Trade through the real interface in the test city (four partners, each with a post): the partners dialog, and an existing
# trade post's panel with its partner's goods instead of the raw store orders. Placing a post is in validate_trade_ui.gd.
func run_trade_checks() -> bool:
	var okay := true
	var partners: Array = city.core.query("trade_partners").partners
	okay = city.check(partners.size() == 4 and partners.all(func(p): return p.has_post) and city.hud.build_groups.all(func(group): return group.title != "Trade"), "the test city has a post for each of its four partners, so the Build menu offers no new trade post") and okay
	city.game_action("trade")
	await city.get_tree().create_timer(.4).timeout
	var dialog: Window = null
	for child in city.hud.get_children():
		if child is AcceptDialog and child.get("partner_count") != null:
			dialog = child
	okay = city.check(dialog != null and dialog.visible and dialog.partner_count == 4, "Game, Trade partners opens the dialog with the four partners") and okay
	if dialog != null:
		dialog.hide()
		dialog.queue_free()
	var post := {}
	for building in city.state.buildings:
		if building.asset == "trade_post":
			post = building
			break
	city.set_tool("select")
	city.inspected = Vector2i(int(post.x), int(post.y))
	city.refresh_inspection()
	await city.get_tree().create_timer(.5).timeout
	var panel = city.inspector_controls
	okay = city.check(panel.value.has("trade") and panel.trade_rows.size() > 0 and panel.bay_label == null, "a trade post's panel shows its partner's goods, not the raw store orders (%d rows)" % panel.trade_rows.size()) and okay
	city.inspector.visible = false
	city.inspected = Vector2i(99999, 99999)
	return okay

# Raised terrain: the orbit centre must follow the ground (a centre left at y = 0 sits below a plateau, so
# orbiting swings the view around a point under the surface) while zoom keeps the surface point under the
# cursor, and trackpad gestures must drive the same camera.
func run_camera_checks(screen: Vector2) -> bool:
	var okay := true
	var raised := Vector2i(99999, 99999)
	var top := 0
	for cell in city.tiles:
		var altitude := int(city.tiles[cell][2])
		if altitude > top and not city.terrain_geometry.sloped(cell):
			top = altitude
			raised = cell
	if top > 0:
		var saved_target: Vector3 = city.orbit.target
		var saved_distance: float = city.orbit.distance
		city.orbit.target = city.world_position(raised.x, raised.y, top)
		city.orbit.distance = 20.0
		city.orbit.snap_to_ground()
		var anchor = city.orbit.terrain_point(screen)
		city.orbit.zoom_at(screen, .8)
		var anchor_after = city.orbit.terrain_point(screen)
		var drift := Vector2(anchor.x - anchor_after.x, anchor.z - anchor_after.z).length() if anchor != null and anchor_after != null else 99.0
		var ground = city.terrain_geometry.height_at(raised.x, raised.y)
		print("CAMERA_RAISED level ", top, " surface anchor drift ", snappedf(drift, .0001), " orbit centre y ", snappedf(city.orbit.target.y, .01), " ground ", snappedf(ground, .01))
		okay = city.check(drift < .01, "zoom stays anchored on a raised plateau (level %d)" % top) and okay
		okay = city.check(ground > .5 and absf(city.orbit.target.y - city.terrain_geometry.height_at(world_to_tile_x(city.orbit.target), world_to_tile_y(city.orbit.target))) < .01, "the orbit centre stands on the plateau, not below it (%.2f)" % city.orbit.target.y) and okay
		city.orbit.target = saved_target
		city.orbit.distance = saved_distance
		city.orbit.refresh()
	city.orbit.enabled = true
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(3, 0)
	var target_before: Vector3 = city.orbit.target
	city.orbit._unhandled_input(pan)
	okay = city.check(city.orbit.target.distance_to(target_before) > .05, "trackpad two-finger scroll pans the camera") and okay
	var pinch := InputEventMagnifyGesture.new()
	pinch.position = screen
	pinch.factor = 1.25
	var distance_before: float = city.orbit.distance
	city.orbit._unhandled_input(pinch)
	okay = city.check(city.orbit.distance < distance_before, "trackpad pinch zooms in") and okay
	# Zooming in stops at the minimum distance, by wheel and by pinch, and zooming out still works from it.
	for step in 40:
		city.orbit.zoom_at(screen, .9)
	var closest: float = city.orbit.distance
	pinch.factor = 2.0
	city.orbit._unhandled_input(pinch)
	okay = city.check(is_equal_approx(closest, city.orbit.MINIMUM_DISTANCE) and is_equal_approx(city.orbit.distance, closest), "zooming in stops at the minimum distance (%.1f)" % closest) and okay
	city.orbit.zoom_at(screen, 1.1)
	okay = city.check(city.orbit.distance > closest, "zooming out works from the closest view") and okay
	city.orbit.distance = distance_before
	city.orbit.refresh()
	city.orbit.enabled = false
	return okay

func run_checks() -> void:
	city.orbit.enabled = false
	# Let macOS activation and the first Metal frames settle before timing held keys.
	# A first-frame stall can expire the timer before the camera receives its interval.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_move_to_foreground()
		await city.get_tree().create_timer(.8).timeout
	var okay = city.check(city.state.get("paused", false), "native city starts paused")
	if city.core.simulation != null:
		var diagnostics: Dictionary = city.core.simulation.diagnostics()
		okay = city.check(diagnostics.backend == "embedded_cpp" and not diagnostics.sdl_video_initialized and not diagnostics.sdl_audio_initialized, "embedded C++ runs without SDL video or audio") and okay
		okay = city.check(city.tiles.size() > 1024 and city.chunks.size() > 1, "full native map is streamed into terrain chunks") and okay
	var original_yaw: float = city.orbit.yaw
	var original_target: Vector3 = city.orbit.target
	hold_camera("orbit_right", .5)
	var held_orbit = fposmod(city.orbit.yaw - original_yaw, 360.0)
	okay = city.check(held_orbit > 25 and held_orbit < 40, "held E drives the continuous camera (%.2f degrees)" % held_orbit) and okay
	city.orbit.yaw = original_yaw; city.orbit.refresh()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T; key.pressed = true
	var old_orientation = city.orientation
	city._unhandled_input(key)
	okay = city.check(city.orientation == (old_orientation + 1) % 4 and city.orbit.yaw == original_yaw, "T placement orientation is independent of camera yaw") and okay
	var saved_pitch: float = city.orbit.pitch
	hold_camera("tilt_up", .4)
	okay = city.check(city.orbit.pitch > saved_pitch + 10 and city.orbit.yaw == original_yaw, "held R raises the camera tilt without turning the map") and okay
	hold_camera("tilt_down", .4)
	okay = city.check(absf(city.orbit.pitch - saved_pitch) < 2, "held F lowers the camera tilt") and okay
	city.orbit.step_tilt(1, 10); okay = city.check(city.orbit.pitch == 75, "upper tilt limit") and okay
	city.orbit.step_tilt(-1, 10); okay = city.check(city.orbit.pitch == 25, "lower tilt limit") and okay
	city.orbit.pitch = saved_pitch; city.orbit.refresh()
	for angle in [0.0, 90.0, 180.0]:
		city.orbit.yaw = angle; city.orbit.refresh()
		var right: Vector3 = city.orbit.pan_vector(Vector2(1, 0))
		okay = city.check(right.dot(city.orbit.camera.global_basis.x) > .999, "camera relative pan at %d degrees" % angle) and okay
	for heading in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var facing = Basis(Vector3.UP, city.walker_heading(heading)) * Vector3.FORWARD
		okay = city.check(facing.dot(heading) > .999, "GLB forward axis follows walker travel %s" % heading) and okay
	city.orbit.yaw = original_yaw; city.orbit.refresh()
	city.orbit.step_orbit(1, 360.0 / 65.0)
	okay = city.check(absf(city.orbit.yaw - original_yaw) < .001, "continuous full 360-degree orbit") and okay
	for fps in [30, 60, 120]:
		city.orbit.yaw = 17.0
		for index in range(fps):
			city.orbit.step_orbit(1, 1.0 / fps)
		okay = city.check(absf(city.orbit.yaw - 82.0) < .002, "%d FPS orbit timing" % fps) and okay
	city.orbit.yaw = 67.0; city.orbit.refresh()
	var screen := Vector2(city.get_viewport().get_visible_rect().size) * Vector2(.59, .43)
	city.orbit.snap_to_ground()
	var before = city.orbit.terrain_point(screen)
	city.orbit.zoom_at(screen, .9)
	var after_zoom = city.orbit.terrain_point(screen)
	okay = city.check(before != null and after_zoom != null and Vector2(before.x - after_zoom.x, before.z - after_zoom.z).length() < .01, "cursor anchored zoom holds on the terrain surface") and okay
	okay = city.check(absf(city.orbit.target.y - city.orbit.height_at(city.orbit.target.x, city.orbit.target.z)) < .01, "the orbit centre sits on the ground") and okay
	okay = await run_camera_checks(screen) and okay
	var focus: Array = city.state.get("focus", [city.origin.x + 16, city.origin.y + 16])
	var test_key := Vector2i(int(focus[0]), int(focus[1]))
	for angle in [0.0, 45.0, 135.0, 270.0]:
		city.orbit.yaw = angle; city.orbit.refresh()
		var position = city.world_position(test_key.x, test_key.y, city.tiles[test_key][2])
		await city.get_tree().physics_frame
		city.pick_tile(city.orbit.camera.unproject_position(position))
		if city.picked != test_key:
			print("PICK_DIAGNOSTIC expected=", test_key, " actual=", city.picked, " position=", position, " yaw=", angle, " tiles=", city.tiles.size(), " chunks=", city.chunks.size())
		okay = city.check(city.picked == test_key, "terrain picking at %d degrees" % angle) and okay
	var clock: int = city.state.time
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(int(city.state.time) == clock, "orbit and picking do not advance paused simulation") and okay
	city.core.send("pause 0")
	await city.get_tree().create_timer(1.6).timeout
	okay = city.check(int(city.state.time) > clock and not city.state.paused, "Godot resumes the original C++ simulation") and okay
	city.core.send("pause 1")
	await city.get_tree().create_timer(.5).timeout
	clock = city.state.time
	await city.get_tree().create_timer(.4).timeout
	okay = city.check(city.state.paused and int(city.state.time) == clock, "pause reaches native core") and okay
	city.orbit.yaw = original_yaw; city.orbit.target = original_target; city.orbit.distance = 33; city.orbit.refresh()
	if city.core.simulation != null:
		okay = await run_hud_checks() and okay
		okay = await preload("res://scripts/validate_context_ui.gd").new().run(city) and okay
		okay = await preload("res://scripts/validate_status_ui.gd").new().run(city) and okay
		okay = await run_construction_checks() and okay
		okay = await run_road_drag_checks() and okay
		okay = await run_wall_checks() and okay
		okay = await run_housing_checks() and okay
		okay = await run_menu_model_checks() and okay
		okay = await run_world_checks() and okay
		okay = await run_army_checks() and okay
		okay = await run_market_checks() and okay
		okay = await run_objective_checks() and okay
		okay = await run_overlay_checks() and okay
		okay = await run_audio_checks() and okay
		okay = await run_campaign_checks() and okay
		okay = await run_trade_checks() and okay
		okay = await run_message_checks() and okay
		okay = await run_event_word_checks() and okay
		okay = await run_minimap_checks() and okay
		okay = await run_save_checks() and okay
		okay = await preload("res://scripts/validate_inspector_ui.gd").new().run(city) and okay
		okay = await preload("res://scripts/validate_terrain_ui.gd").new().run(city) and okay
		okay = await preload("res://scripts/validate_elevation_ui.gd").new().run(city) and okay
		okay = await preload("res://scripts/validate_details_ui.gd").new().run(city) and okay
		okay = await preload("res://scripts/validate_map_polish_ui.gd").new().run(city) and okay
		# Last: it lets the game run for a battle and answers its decisions, which moves the clock for everything after it.
		okay = await run_fight_checks() and okay
		okay = await run_military_checks() and okay
		okay = await run_monster_checks() and okay
		okay = await run_hero_checks() and okay
		okay = await run_sanctuary_checks() and okay
		okay = await run_rite_checks() and okay
		okay = await run_pyramid_checks() and okay
		okay = await run_controls_checks() and okay
		okay = await run_city_data_checks() and okay
		okay = await run_naval_checks() and okay
		okay = await run_requests_units_checks() and okay
	city.update_hint()
	city.update_details()
	if not city.capture_path.is_empty():
		await city.capture()
	# The scratch folder of the save checks goes with the run.
	if not city.validation_save_directory.is_empty():
		for file in DirAccess.get_files_at(city.validation_save_directory):
			DirAccess.remove_absolute(city.validation_save_directory.path_join(file))
		DirAccess.remove_absolute(city.validation_save_directory)
	print("GODOT_VALIDATION ", "PASS" if okay else "FAIL")
	city.get_tree().quit(0 if okay else 1)

# Visible HUD controls, the native catalog, text focus and responsive panel bounds.
func hud_click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	city.get_viewport().push_input(mouse_event(point, true), true)
	city.get_viewport().push_input(mouse_event(point, false), true)
	await city.get_tree().process_frame

# Exercise the full camera input path with exact elapsed time. Wall-clock timers can include a
# long render frame before the action was pressed, making R/F intervals unequal on a loaded GPU.
func hold_camera(action: String, seconds: float) -> void:
	var processing: bool = city.orbit.is_processing()
	city.orbit.set_process(false)
	Input.action_press(action)
	city.orbit.enabled = true
	for frame in 30:
		city.orbit._process(seconds / 30.0)
	Input.action_release(action)
	city.orbit.enabled = false
	city.orbit.set_process(processing)

func run_hud_checks() -> bool:
	var okay := true
	var hud: Control = city.hud
	var initial: Dictionary = city.core.simulation.snapshot(true)
	var lang: String = city.language
	var prior_window := DisplayServer.window_get_size()
	city.set_tool("select")
	hud.set_goals_expanded(false)
	okay = city.check(hud.category_buttons.size() == hud.build_groups.size(), "the dock exposes every available native category") and okay
	await hud_click(hud.category_buttons["Industry"])
	okay = city.check(hud.get_node("%BuildTray").visible and hud.active_category == "Industry", "clicking a category opens its tray without reaching the map") and okay
	var expected: Array = hud.build_groups.filter(func(group): return group.title == "Industry")[0].items
	okay = city.check(hud.building_cards.size() == expected.size() and expected.all(func(item): return hud.building_cards.has(item.name)), "cards contain exactly the native category's buildings") and okay
	if hud.building_cards.has("olive_press"):
		await hud_click(hud.building_cards.olive_press)
		okay = city.check(city.mode == "olive_press" and hud.building_cards.olive_press.button_pressed, "clicking a card selects and highlights the real construction tool") and okay
	var search: LineEdit = hud.get_node("%BuildSearch")
	okay = city.check(not search.visible and not search.has_focus(), "building choices omit the search field") and okay
	okay = city.check(hud.building_cards.values().all(func(card): return card.get_child(0).get_child_count() == 2), "building cards show only model and name without a cost row") and okay
	await hud_click(hud.get_node("%TrayClose"))
	okay = city.check(not hud.get_node("%BuildTray").visible and not search.has_focus() and city.mode == "olive_press", "closing the tray releases focus and keeps the selected tool") and okay
	hud.set_minimap_open(true)
	await hud_click(hud.get_node("%MapToggle"))
	okay = city.check(not hud.get_node("%MinimapPanel").visible, "the map button collapses the minimap") and okay
	await hud_click(hud.get_node("%MapToggle"))
	okay = city.check(hud.get_node("%MinimapPanel").visible, "the map button restores the live minimap") and okay
	var hospital: Dictionary = city.state.buildings.filter(func(b): return b.asset == "hospital")[0]
	city.inspected = Vector2i(hospital.x, hospital.y)
	city.refresh_inspection()
	await city.get_tree().process_frame
	okay = city.check(hud.get_node("%InspectorTitle").text != "" and hud.get_node("%Workforce").value == hud.inspector_controls.value.employees, "the heading and workforce bar use live native values") and okay
	await hud_click(hud.get_node("%InspectorClose"))
	city.refresh_inspection()
	okay = city.check(not hud.inspector.visible and not city.selection.visible, "closing inspection clears selection and refresh cannot reopen it") and okay
	for locale in ["en", "ru"]:
		city.language = UiText.set_language(locale)
		hud.retranslate()
		for resolution in [Vector2i(1440,900), Vector2i(1280,720), Vector2i(1920,1080)]:
			DisplayServer.window_set_size(resolution)
			city.inspected = Vector2i(hospital.x, hospital.y)
			city.refresh_inspection()
			hud.open_category("Gardens and monuments")
			if not hud.get_node("%BuildTray").visible: hud.open_category("Gardens and monuments")
			for frame in 5: await city.get_tree().process_frame
			var screen := Rect2(Vector2.ZERO, hud.size)
			var contained := true
			for panel in ["BottomBar", "StatusBar", "BuildTray", "Inspector", "MinimapPanel", "StatsGroup"]:
				contained = contained and screen.grow(1).encloses(hud.get_node("%" + panel).get_global_rect())
			okay = city.check(contained and not hud.inspector.get_global_rect().intersects(hud.get_node("%BuildTray").get_global_rect()), "%s %s panels fit and inspector clears the tray" % [locale, resolution]) and okay
	city.language = UiText.set_language(lang)
	hud.retranslate()
	DisplayServer.window_set_size(prior_window)
	hud.close_build_tray()
	city.close_inspection()
	city.set_tool("select")
	var after: Dictionary = city.core.simulation.snapshot(true)
	okay = city.check(initial.money == after.money and initial.time == after.time and initial.buildings == after.buildings and initial.walkers == after.walkers, "HUD browsing, search, language and layout leave the native city unchanged") and okay
	if DisplayServer.get_name() != "headless":
		for frame in 50:
			if not hud.thumbnails.busy and hud.thumbnails.pending.is_empty(): break
			await city.get_tree().process_frame
		okay = city.check(not hud.thumbnails.cache.is_empty() and hud.thumbnails.get_child_count() == 1, "building previews use one shared viewport and cached textures") and okay
	return okay
