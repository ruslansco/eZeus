extends RefCounted

func run(city: Node3D) -> bool:
	var okay := true
	city.core.send("pause 1")
	await city.get_tree().create_timer(.2).timeout
	var original_capture: String = city.capture_path
	var review_dir: String = original_capture.get_base_dir()
	if review_dir.is_empty():
		review_dir = ProjectSettings.globalize_path("res://captures")
	for kind in ["warehouse", "granary", "olive_press"]:
		var building := {}
		for item in city.state.buildings:
			if item.asset == kind:
				building = item
				break
		okay = city.check(not building.is_empty(), "inspector fixture " + kind) and okay
		if building.is_empty():
			continue
		city.set_tool("select")
		city.orbit.target = city.world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
		city.orbit.distance = 20
		city.orbit.yaw = 45
		city.orbit.refresh()
		await city.get_tree().physics_frame
		var click := InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = city.orbit.camera.unproject_position(city.orbit.target)
		city._unhandled_input(click)
		var panel: VBoxContainer = city.inspector_controls
		okay = city.check(city.inspector.visible and panel.value.has("target_token"), "click opens live " + kind + " inspector") and okay
		if kind in ["warehouse", "granary"]:
			okay = city.check(panel.rows.size() == panel.value.storage.resources.size() and panel.bay_label.text.contains("8"), kind + " inventory and bay totals are visible") and okay
			var goods: Dictionary = panel.value.storage.resources[0]
			var resource: int = goods.resource
			var row: Dictionary = panel.rows[resource]
			okay = city.check(row.order.get_item_text(2) == city.tr("Get"), kind + " orders use presentation language") and okay
			row.order.select(2)
			row.order.item_selected.emit(2)
			row.limit.value = 0
			panel.settle(resource)
			okay = city.check(row.dirty and panel.commit_at.has("s|%d" % resource), kind + " an edit is a draft that sends itself, with no Apply") and okay
			var stock: int = goods.count
			await city.get_tree().create_timer(.5).timeout
			city.refresh_inspection()
			goods = panel.value.storage.resources[0]
			okay = city.check(int(goods.order) == 2 and int(goods.limit) == 0 and int(goods.count) == stock, kind + " the edit reaches native orders without deleting stock") and okay
			# Refresh must preserve an unfinished edit, and typing must not rotate the camera.
			row = panel.rows[resource]
			row.limit.value = 4
			var input: LineEdit = row.limit.get_line_edit()
			input.grab_focus()
			var yaw: float = city.orbit.yaw
			city.orbit.enabled = true
			Input.action_press("orbit_right")
			await city.get_tree().create_timer(.4).timeout
			Input.action_release("orbit_right")
			city.orbit.enabled = false
			okay = city.check(is_equal_approx(city.orbit.yaw, yaw) and int(row.limit.value) == 4 and int(panel.value.storage.resources[0].limit) == 0, kind + " live refresh preserves drafts and camera stays still while editing") and okay
			input.release_focus()
			# Hold the draft back so the next steps do not race its settle time.
			panel.commit_at["s|%d" % resource] = Time.get_ticks_msec() + 600000
			panel.command_done("storage 0 0 999999 64 0 0", true)
			okay = city.check(row.dirty, kind + " stale completion cannot erase the current draft") and okay
			for queued in range(16):
				city.core.commands.append("snapshot")
			panel.settle(resource)
			await city.get_tree().create_timer(.15).timeout
			okay = city.check(not panel.pending and row.dirty and panel.commit_at.has("s|%d" % resource), kind + " full command queue leaves the draft and sends it again later") and okay
			city.core.commands.clear()
			panel.settle(resource)
			await city.get_tree().create_timer(.6).timeout
			city.refresh_inspection()
			okay = city.check(int(panel.value.storage.resources[0].limit) == 4, kind + " edited stock limit commits by itself") and okay
		else:
			okay = city.check(panel.stock_label.text.contains(city.tr("Input:")) and panel.industry_buttons.has(2048), "production input/output and industry controls are visible") and okay
			var initial_shutdown: bool = panel.value.production.industries[0].shut_down
			if initial_shutdown:
				panel.industry_buttons[2048].pressed.emit()
				await city.get_tree().create_timer(.2).timeout
				city.refresh_inspection()
			panel.industry_buttons[2048].pressed.emit()
			await city.get_tree().create_timer(.3).timeout
			city.refresh_inspection()
			okay = city.check(panel.value.shut_down and int(panel.value.employees) == 0 and panel.production_label.text == city.tr("Industry paused"), "industry button pauses native production and workforce") and okay
			panel.industry_buttons[2048].pressed.emit()
			await city.get_tree().create_timer(.3).timeout
			city.refresh_inspection()
			okay = city.check(not panel.value.shut_down and int(panel.value.employees) > 0, "industry button resumes native production and workforce") and okay
			if initial_shutdown:
				panel.industry_buttons[2048].pressed.emit()
				await city.get_tree().create_timer(.2).timeout
		city.capture_path = review_dir.path_join("inspector-%s-%s.png" % [kind, city.language])
		await city.capture()
	# Exercise the Build menu signals and imported ghost for the storage and production tools.
	okay = city.check(city.hud.build_menu.get_popup().item_count >= 6, "the Build menu groups buildings into categories") and okay
	for entry in [["warehouse", 3], ["granary", 4], ["olive_press", 2], ["winery", 2], ["sculpture_studio", 2]]:
		city.set_tool("road")
		okay = city.check(city.hud.activate_building(entry[0]), "the Build menu lists " + entry[0]) and okay
		okay = city.check(city.mode == entry[0] and not city.tool_buttons.road.button_pressed, "construction menu selects " + entry[0] + " and clears the previous tool") and okay
		var candidate := Vector2i(99999, 99999)
		for point in city.tiles:
			if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
				continue
			var query: Dictionary = city.core.query("preview %s %d %d 3" % [entry[0], point.x, point.y])
			if query.get("valid", false):
				candidate = point
				break
		okay = city.check(candidate != Vector2i(99999, 99999), "native placement available for " + entry[0]) and okay
		if candidate == Vector2i(99999, 99999):
			continue
		city.orbit.target = city.world_position(candidate.x, candidate.y, city.tiles[candidate][2])
		city.orbit.distance = 22
		city.orientation = 3
		for angle in [0.0, 90.0, 180.0, 270.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().physics_frame
			city.pick_tile(city.orbit.camera.unproject_position(city.orbit.target))
			okay = city.check(city.picked == candidate and city.placement_result.get("valid", false) and city.ghost.get_child_count() > 0 and city.footprint_cells.get_child_count() == entry[1] * entry[1], "imported %s ghost and native footprint at %d degrees" % [entry[0], angle]) and okay
	city.set_tool("select")
	for building in city.state.buildings:
		if building.asset == "warehouse":
			city.inspected = Vector2i(int(building.x), int(building.y))
			city.orbit.target = city.world_position(building.x + 1, building.y + 1, building.altitude)
			city.orbit.yaw = 45
			city.orbit.distance = 20
			city.orbit.refresh()
			city.refresh_inspection()
			break
	city.capture_path = original_capture
	return okay
