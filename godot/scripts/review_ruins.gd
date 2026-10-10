extends SceneTree
# Native collapse/clear only in the designated city held in scratch memory.
var city: Node3D
var okay := true
var checks := 0

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, text: String) -> void:
	checks += 1
	okay = okay and value
	print("RUINS_REVIEW_CHECK ", "PASS " if value else "FAIL ", text)

func frames(count := 8) -> void:
	for i in count: await process_frame

func capture(label: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/ruins-%s-%s.png" % [city.language,label])

func click(control: Control) -> void:
	DisplayServer.window_move_to_foreground()
	root.warp_mouse(control.get_global_rect().get_center())
	await frames(3)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
		if pressed: await frames(3)
	await frames(20)

func run() -> void:
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.receive_state(city.core.query("pause 1"))
	city.core.simulation.enable_test_commands()
	city.orbit.enabled = false
	city.road_drag.guard = false
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var building := {}
	for asset in ["gymnasium","college","university","warehouse","inventors_workshop"]:
		for item in city.state.buildings:
			if item.asset == asset and int(item.w) == 3 and int(item.h) == 3: building = item; break
		if not building.is_empty(): break
	check(not building.is_empty(), "native 3×3 building found for ruin review: " + str(building.get("asset","")))
	if building.is_empty(): quit(1); return
	var cell := Vector2i(int(building.x),int(building.y))
	var old: Dictionary = city.core.query("inspect %d %d" % [cell.x,cell.y])
	city.core.query("test_collapse %d %d" % [cell.x,cell.y])
	city.receive_state(city.core.simulation.snapshot(true))
	city.orbit.target = city.world_position(cell.x+1,cell.y+1,building.altitude)
	city.orbit.distance = 20
	city.orbit.pitch = 55
	city.orbit.yaw = 135
	city.orbit.refresh()
	city.inspected = cell + Vector2i(2,2)
	city.refresh_inspection()
	await frames()
	var data: Dictionary = city.inspector_controls.value
	check(city.hud.get_node("%InspectorTitle").text == city.tr("Ruins of %s") % str(old.name), "inspector names the former building in " + city.language)
	check(Rect2i(int(data.footprint[0]),int(data.footprint[1]),int(data.footprint[2]),int(data.footprint[3])) == Rect2i(cell,Vector2i(3,3)) and city.selection.mesh.size.x == 3 and city.selection.mesh.size.z == 3, "inspection selects the complete 3×3 ruin")
	check(city.inspector_controls.ruin_demolish_button != null and not city.inspector_controls.ruin_demolish_button.disabled, "panel clearing button is visible and enabled")
	var summary: Node = city.hud.get_node("%InspectionSummary")
	check(summary.status_id == "ruin" and not summary.metrics.maintenance.column.visible, "ruin status replaces fictitious maintenance")
	await capture("inspector")
	city.set_tool("demolish")
	DisplayServer.window_move_to_foreground()
	root.warp_mouse(city.orbit.camera.unproject_position(city.world_position(cell.x+1,cell.y+1,building.altitude)))
	city.placement_key = ""
	await frames(12)
	check(city.picked == cell + Vector2i(1,1) and city.preview.visible and is_equal_approx(city.preview.mesh.size.x,2.98) and is_equal_approx(city.preview.mesh.size.z,2.98) and city.footprint_cells.get_child_count() == 0, "pointer hover displays one complete ruin square without per-tile overlays")
	check(city.hint.text == city.tr("Demolition: %d  •  Click to remove; demolition cannot be undone") % int(data.ruin.cost), "hover explains clearing at the full native cost")
	await capture("hover")
	city.road_drag.begin(city,cell+Vector2i(1,1),"demolish")
	check(city.road_drag.markers.size() == 1 and int(city.road_drag.plan.count) == 9, "held press keeps one full ruin marker")
	city.road_drag.cancel(city)
	city.set_tool("select")
	city.inspected = cell + Vector2i(2,2)
	city.refresh_inspection()
	var money := int(city.state.money)
	var cost := int(city.inspector_controls.value.ruin.cost)
	var paused: bool = city.state.paused
	var time := int(city.state.time)
	await click(city.inspector_controls.ruin_demolish_button)
	check(not city.inspector.visible and not city.core.query("inspect %d %d" % [cell.x,cell.y]).has("footprint"), "ordinary panel mouse press/release clears the entire ruin and closes the inspector")
	check(int(city.state.money) == money-cost and city.state.paused == paused and int(city.state.time) == time, "clearing charges the quoted cost and preserves pause/time")
	await capture("cleared")
	print("RUINS_REVIEW ", "PASS" if okay else "FAIL", " checks=",checks)
	quit(0 if okay else 1)
