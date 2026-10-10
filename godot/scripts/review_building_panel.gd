extends SceneTree
# The building panel on the designated city (disposable preferences): the storehouse and granary tables apply their edits by themselves
# and have an "all goods" row, the agora shows its stalls and a house its needs; the panel is wider for those pages. Captures the right half.
var city: Node3D
var checks := 0
var okay := true

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("PANEL_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count := 8) -> void:
	for frame in count: await process_frame

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func shoot(name: String) -> void:
	await frames(14); await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var scale: Vector2 = Vector2(image.get_size()) / city.hud.size
	var region := Rect2i(Vector2(city.hud.size.x * .55, 0) * scale, Vector2(city.hud.size.x * .45, city.hud.size.y) * scale)
	image.get_region(region).save_png("res://captures/building-panel-" + name + "-" + city.language + ".png")

func inspect(asset_part: String) -> Dictionary:
	for building in city.state.buildings:
		if str(building.asset).contains(asset_part):
			city.inspected = Vector2i(int(building.x), int(building.y))
			city.refresh_inspection()
			return building
	return {}

# The designated city has no agora: lay one over a road and put a food vendor on its first space (in memory only).
func build_agora() -> void:
	var site := Vector2i(99999, 99999)
	for cell in city.tiles:
		if city.core.query("preview common_agora %d %d 0" % [cell.x, cell.y]).get("valid", false):
			site = cell
			break
	print("PANEL_AGORA_SITE ", site)
	if site.x == 99999:
		return
	var placed: Dictionary = city.core.query("build common_agora %d %d 0" % [site.x, site.y])
	city.receive_state(placed)
	for piece in placed.buildings:
		if piece.asset == "agora_space":
			var vendor: Dictionary = city.core.query("build food_vendor %d %d 0" % [int(piece.x), int(piece.y)])
			city.receive_state(vendor)
			break
	await frames(10)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1"); city.orbit.enabled = false
	DisplayServer.window_set_size(Vector2i(1600, 1000)); await frames()
	var controls: Node = city.inspector_controls
	var found := {}
	await build_agora()
	for part in ["warehouse", "granary", "common_agora", "food_vendor", "common_house_2a", "common_house_6a", "olive_press"]:
		found[part] = not inspect(part).is_empty()
		print("PANEL_FOUND ", part, " ", found[part])
		if not found[part]:
			continue
		await shoot(part)
		if part == "warehouse" or part == "granary":
			check(city.hud.inspector_wide, part + " panel is the wide one")
			check(controls.rows.size() > 0 and controls.all_order != null, part + " has an all-goods row")
			var resource: int = controls.rows.keys()[0]
			var row: Dictionary = controls.rows[resource]
			# Choose a different order in the first row: it is sent by itself, with no Apply.
			var wanted: int = 0 if row.order.selected != 0 else 1
			row.order.select(wanted); row.order.item_selected.emit(wanted)
			await frames(30)
			var now: Dictionary = city.core.query("inspect %d %d" % [city.inspected.x, city.inspected.y])
			var stored := -1
			for goods in now.storage.resources:
				if int(goods.resource) == resource: stored = int(goods.order)
			check(stored == wanted and not row.dirty, part + " an order change applies by itself")
			# All goods: every row follows.
			var every: int = 1 if wanted != 1 else 0
			controls.all_order.select(every + 1); controls.all_order.item_selected.emit(every + 1)
			await frames(90)
			now = city.core.query("inspect %d %d" % [city.inspected.x, city.inspected.y])
			var same := true
			for goods in now.storage.resources:
				same = same and int(goods.order) == every
			check(same, part + " the all-goods row sets every good")
			check(controls.commit_at.is_empty() and not controls.pending, part + " nothing is left waiting")
			await shoot(part + "-after")
		if part == "common_agora" or part == "food_vendor":
			check(controls.agora_tiles.size() >= 6 and controls.agora_tiles.food.stock.text != "", part + " page lists the agora's stalls")
		if part.begins_with("common_house"):
			check(city.hud.get_node("%InspectionSummary").house_box.visible or city.hud.get_node("%InspectionSummary").needs.visible, "a house shows its needs")
	# The road chip shows only for a building cut off from the roads.
	var summary: Node = city.hud.get_node("%InspectionSummary")
	var sample: Dictionary = city.core.query("inspect %d %d" % [city.inspected.x, city.inspected.y])
	check(sample.has("footprint"), "a building is inspected for the road chip")
	for connected in [true, false]:
		var fake: Dictionary = sample.duplicate(true)
		fake.road_access = connected
		summary.show_data(fake)
		check(summary.metrics.road.column.visible == (not connected), "the road chip is " + ("hidden" if connected else "shown") + " for a " + ("connected" if connected else "cut-off") + " building")
	if found.get("common_house_2a", false):
		inspect("common_house_2a")
		await frames(10)
		var card: Dictionary = summary.value.get("house", {})
		var texts := []
		for child in summary.house_box.get_children():
			if child is Label: texts.append(child.text)
		check(not card.is_empty() and (card.lines as Array).size() > 0, "a lower-level house names the needs of its next level")
		var target := str(card.get("target_name", ""))
		target = target.left(1).to_upper() + target.substr(1)
		check(texts.has(city.tr("To reach %s") % target) or texts.has(city.tr("Needed to keep this level")) or texts.has(city.tr("%s: every need is met") % target), "the house page is headed by the level it is reaching")
	print("PANEL_CHECK ", "PASS" if okay else "FAIL", " ", checks, " checks")
	print("PANEL_REVIEW_DONE")
	quit(0 if okay else 1)
