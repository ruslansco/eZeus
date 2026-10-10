extends SceneTree
# Owned render-only house gallery and matched terrain-shader timing. Native roads
# exist in memory only; the house models do not enter the native simulation.
var city: Node3D
var okay := true
var checks := 0
var fixtures: Array[Node3D] = []

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("ROAD_CORNER_REVIEW_CHECK ", "PASS " if value else "FAIL ", label)

func sample(radius: float) -> Dictionary:
	city.terrain_style.ground_material.set_shader_parameter("road_inner_radius", radius)
	for frame in 30: await process_frame
	var viewport: RID = root.get_viewport_rid()
	var gpu := 0.0; var cpu := 0.0
	for frame in 90:
		await RenderingServer.frame_post_draw
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport)
	return {"radius": radius, "gpu_ms": gpu / 90, "cpu_ms": cpu / 90, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}

func capture(label: String, radius: float) -> void:
	city.terrain_style.ground_material.set_shader_parameter("road_inner_radius", radius)
	for frame in 12: await process_frame
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png("res://captures/road-corners-houses-%s.png" % label)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
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
		for x in range(-2, 8):
			for y in range(-2, 8):
				var tile: Array = free.get(cell + Vector2i(x, y), [])
				if tile.is_empty() or int(tile[2]) != int(free[cell][2]): clear = false; break
			if not clear: break
		if clear: base = cell; break
	check(base.x >= 0, "clear level corner gallery site exists")
	if base.x < 0: city.queue_free(); quit(1); return
	for ends in [[Vector2i(-1, -1), Vector2i(-1, 5)], [Vector2i(-1, -1), Vector2i(5, -1)], [Vector2i(5, -1), Vector2i(5, 5)], [Vector2i(-1, 5), Vector2i(5, 5)]]:
		var a: Vector2i = base + ends[0]; var b: Vector2i = base + ends[1]
		check(not city.core.query("build_road %d %d %d %d" % [a.x, a.y, b.x, b.y]).has("error"), "native ordinary road strip built")
	city.receive_state(city.core.simulation.snapshot(true))
	var original: Dictionary = city.core.simulation.snapshot(true)
	for setup in [["common_house_3a", 0, 0], ["common_house_5a", 3, 3]]:
		var building := {"asset": setup[0], "x": base.x + setup[1], "y": base.y + setup[2], "w": 2, "h": 2}
		var facing: int = city.StreetFacing.facing(city.tiles, building.asset, building.x, building.y, 2, 2, 0)
		var house: Node3D = city.model(building.asset); city.world.add_child(house); fixtures.append(house)
		var center: Vector3 = city.world_position(building.x + .5, building.y + .5, free[base][2])
		house.transform = city.StreetSetback.apply(city.tiles, building, Transform3D(city.model_basis(building.asset, 2, 2, facing), center))
	city.orbit.target = city.world_position(base.x + 2, base.y + 2, free[base][2]) + Vector3.UP * .3
	city.orbit.distance = 11; city.orbit.pitch = 55; city.orbit.yaw = -35; city.orbit.refresh()
	await capture("before", 0.0)
	await capture("after", .18)
	# Review the actual kerb join at both house foundations, not just an overview.
	city.orbit.target = city.world_position(base.x - .3, base.y - .3, free[base][2]) + Vector3.UP * .15
	city.orbit.distance = 4.5; city.orbit.pitch = 60; city.orbit.yaw = -35; city.orbit.refresh()
	await capture("near-close", .18)
	city.orbit.target = city.world_position(base.x + 4.3, base.y + 4.3, free[base][2]) + Vector3.UP * .15
	city.orbit.yaw = 145; city.orbit.refresh()
	await capture("far-close", .18)
	city.orbit.target = city.world_position(base.x + 2, base.y + 2, free[base][2]) + Vector3.UP * .3
	city.orbit.distance = 11; city.orbit.pitch = 55; city.orbit.yaw = -35; city.orbit.refresh()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var report := [await sample(0.0), await sample(.18), await sample(0.0), await sample(.18)]
	check(report.all(func(row): return row.draw_calls == report[0].draw_calls and row.primitives == report[0].primitives), "corner shading adds no geometry or draw calls")
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(original.tiles == after.tiles and original.buildings == after.buildings and original.walkers == after.walkers and original.money == after.money and original.time == after.time, "corner rendering and timing leave native city observations unchanged")
	var file := FileAccess.open("res://captures/road-corners-timing.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("ROAD_CORNER_TIMING ", JSON.stringify(report))
	for node in fixtures: node.queue_free()
	print("ROAD_CORNER_REVIEW ", "PASS " if okay else "FAIL ", checks, " checks")
	city.walkers.clear(); city.queue_free(); await process_frame; await process_frame
	quit(0 if okay else 1)
