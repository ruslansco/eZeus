extends SceneTree
# Exercise real native previews and installed batches beside widened ordinary roads.
# All construction is confined to the owned in-memory designated test city.
var city: Node3D
var okay := true
var checks := 0

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("PLACEMENT_CLEARANCE_CHECK ", "PASS " if value else "FAIL ", label)

func capture(label: String) -> void:
	for i in 12: await process_frame
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png("res://captures/placement-clearance-%s.png" % label)

func matches(preview: Transform3D, installed: Transform3D) -> bool:
	# The translucent preview is intentionally lifted .02 tile to avoid z-fighting.
	return preview.basis.is_equal_approx(installed.basis) and absf(preview.origin.x - installed.origin.x) < .00001 and absf(preview.origin.z - installed.origin.z) < .00001

func run() -> void:
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 70: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
	city.orbit.enabled = false; city.ui_layer.visible = false
	DisplayServer.window_move_to_foreground()
	var free := {}
	for tile in city.core.simulation.snapshot(true).tiles:
		if int(tile[5]) and not int(tile[4]) and not (int(tile[3]) & (4 | 16 | 2048 | 32768)):
			free[Vector2i(int(tile[0]), int(tile[1]))] = tile
	var base := Vector2i(-1, -1)
	for cell in free:
		var clear := true
		for x in range(-2, 12):
			for y in range(-2, 8):
				var tile: Array = free.get(cell + Vector2i(x, y), [])
				if tile.is_empty() or int(tile[2]) != int(free[cell][2]): clear = false; break
			if not clear: break
		if clear: base = cell; break
	check(base.x >= 0, "clear level native site exists")
	if base.x < 0: city.queue_free(); quit(1); return
	# Roads on all four sides cover both axes and opposing-side cap handling.
	for ends in [[Vector2i(-1, -1), Vector2i(-1, 5)], [Vector2i(-1, -1), Vector2i(5, -1)], [Vector2i(5, -1), Vector2i(5, 5)], [Vector2i(-1, 5), Vector2i(5, 5)]]:
		var a: Vector2i = base + ends[0]; var b: Vector2i = base + ends[1]
		check(not city.core.query("build_road %d %d %d %d" % [a.x, a.y, b.x, b.y]).has("error"), "native ordinary road strip built")
	city.receive_state(city.core.simulation.snapshot(true))
	city.orbit.target = city.world_position(base.x + 2, base.y + 2, free[base][2])
	city.orbit.distance = 13; city.orbit.pitch = 48; city.orbit.yaw = 30; city.orbit.refresh()
	for tool in ["theater", "hospital", "house", "park", "tower"]:
		for facing in 4:
			city.set_tool(tool); city.orientation = facing; city.picked = base
			city.refresh_placement()
			var quote: Dictionary = city.placement_result.duplicate(true)
			check(quote.get("valid", false) and city.ghost.visible and city.footprint_cells.get_child_count() == int(quote.w) * int(quote.h), "%s facing %d: native full footprint remains valid" % [tool, facing])
			if not quote.get("valid", false): continue
			var ghost: Transform3D = city.ghost.transform
			if tool in ["house", "park"]:
				city.road_drag.plan = quote
				var area: Node3D = city.road_drag.area_piece(city, [quote.x, quote.y, quote.altitude])
				check(matches(area.transform, ghost), "%s facing %d: area drag matches the single preview" % [tool, facing])
				area.free()
			if tool == "theater" and facing == 0: await capture("preview")
			var money: int = city.state.money
			var result: Dictionary = city.core.query("build %s %d %d %d" % [tool, base.x, base.y, facing])
			city.receive_state(city.core.simulation.snapshot(true))
			var key := "%d,%d" % [int(quote.x), int(quote.y)]
			check(not result.has("error") and city.building_placements.has(key) and matches(ghost, city.building_placements[key].transform) and int(city.state.money) == money - int(quote.cost), "%s facing %d: installed model matches preview and quoted cost" % [tool, facing])
			city.placement_key = ""; city.refresh_placement()
			check(not city.placement_result.valid and matches(city.ghost.transform, ghost), "%s facing %d: blocked preview retains the same clearance" % [tool, facing])
			if tool == "theater" and facing == 0:
				city.ghost.visible = false; city.footprint_cells.visible = false
				await capture("placed")
			check(not city.core.query("undo").has("error"), "%s: native undo succeeds" % tool)
			city.core.simulation.replay(4)
			city.receive_state(city.core.simulation.snapshot(true))
	# An isolated preview should retain its ordinary fitting, and roads must not shrink.
	city.set_tool("theater"); city.picked = base + Vector2i(7, 0); city.refresh_placement()
	var quote: Dictionary = city.placement_result
	var facing: int = city.StreetFacing.facing(city.tiles, quote.asset, quote.x, quote.y, quote.w, quote.h, city.orientation)
	check(city.ghost.basis.is_equal_approx(city.model_basis(quote.asset, quote.w, quote.h, facing)), "no adjacent roads: preview keeps ordinary fitting")
	city.set_tool("road"); city.picked = base + Vector2i(-1, 1); city.refresh_placement()
	check(city.ghost.basis.get_scale().is_equal_approx(Vector3.ONE), "ordinary road preview keeps full size beside roads")
	print("PLACEMENT_CLEARANCE ", "PASS " if okay else "FAIL ", checks, " checks")
	city.walkers.clear(); city.queue_free()
	await process_frame; await process_frame
	quit(0 if okay else 1)
