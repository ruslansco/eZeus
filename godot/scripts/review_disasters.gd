extends SceneTree
# The disasters' effects (scripts/disaster_effects.gd) and the fire's crackle, on the designated city in memory only (disposable
# preferences): starts a tidal wave, a lava flow, an earthquake and a landslide through the validators' `test_disaster` and lets the
# simulation run, counts the effects drawn, captures them; sets a building on fire in view and listens for the fire sound (the core
# plays it only for tiles in the camera box sent by `view_box`).
var city: Node3D
var checks := 0
var okay := true

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("DISASTER_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count := 8) -> void:
	for frame in count: await process_frame

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func look_at_cell(cell: Vector2i, distance: float) -> void:
	var altitude := float(city.tiles[cell][2]) if city.tiles.has(cell) else 0.0
	city.orbit.target = city.world_position(cell.x, cell.y, altitude)
	city.orbit.distance = distance
	city.orbit.yaw = 35
	city.orbit.refresh()

func shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/disaster-" + name + "-" + city.language + ".png")

# A dry, building-free tile with the given number of dry building-free tiles around it (and none near the edge of the map).
func open_land(radius: int, near_water := false) -> Vector2i:
	var buildings := {}
	for building in city.state.buildings:
		buildings[Vector2i(int(building.x), int(building.y))] = true
	for cell in city.tiles:
		var tile: Array = city.tiles[cell]
		if (int(tile[3]) & 1) == 0 or int(tile[4]) == 1 or buildings.has(cell):
			continue
		var wet := false
		var clear := true
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var other: Vector2i = cell + Vector2i(dx, dy)
				if not city.tiles.has(other) or buildings.has(other) or int(city.tiles[other][4]) == 1:
					clear = false
				elif (int(city.tiles[other][3]) & 4) != 0:
					wet = true
		if clear and wet == near_water:
			return cell
	return Vector2i(99999, 99999)

# A decision waiting in the city (a request, an envoy) holds the simulation; this city is only in memory, so it is answered with its last choice.
func unblock() -> void:
	if not city.state.get("blocked", false):
		return
	for event in city.state.get("events", []):
		var actions: Array = event.get("actions", [])
		if not actions.is_empty() and int(actions[actions.size() - 1].choice) != -2:
			city.core.query("event %d %d" % [int(event.id), int(actions[actions.size() - 1].choice)])
	city.core.query("pause 0")

func wait_running(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		unblock()
		await create_timer(.2).timeout
		left -= .2

# Dry ground with a step in the land beside it (a landslide needs a slope), clear of buildings and roads.
func slope_land() -> Vector2i:
	var buildings := {}
	for building in city.state.buildings:
		buildings[Vector2i(int(building.x), int(building.y))] = true
	for cell in city.tiles:
		var tile: Array = city.tiles[cell]
		if (int(tile[3]) & 1) == 0 or int(tile[4]) == 1 or buildings.has(cell):
			continue
		var steps := false
		var clear := true
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				var other: Vector2i = cell + Vector2i(dx, dy)
				if not city.tiles.has(other) or buildings.has(other) or int(city.tiles[other][4]) == 1:
					clear = false
				elif int(city.tiles[other][2]) != int(tile[2]):
					steps = true
		if clear and steps:
			return cell
	return Vector2i(99999, 99999)

# Aims the camera at the newest effect while the disaster runs and captures it.
func live_shot(name: String, tries := 40) -> void:
	for step in tries:
		await wait_running(.1)
		if city.disaster_effects.spawned > 10:
			break
	look_at_cell(city.disaster_effects.last_cell, 7)
	await frames(3)
	await shoot(name)

func disaster(kind: String, cell: Vector2i, seconds: float, shot: String) -> int:
	var before: int = city.disaster_effects.spawned
	var reply: Dictionary = city.core.query("test_disaster %s %d %d" % [kind, cell.x, cell.y])
	print("DISASTER_START ", kind, " ", cell, " reply=", reply)
	look_at_cell(cell, 16)
	await live_shot(shot + "-front")
	await wait_running(seconds * .4)
	await shoot(shot)
	await wait_running(seconds * .6)
	var counts := {"lava": 0, "quake": 0, "water": 0}
	for other in city.tiles:
		if abs(other.x - cell.x) <= 10 and abs(other.y - cell.y) <= 10:
			var terrain := int(city.tiles[other][3])
			counts.lava += 1 if terrain & 32768 else 0
			counts.quake += 1 if terrain & 2048 else 0
			counts.water += 1 if terrain & 4 else 0
	print("DISASTER_STATE ", kind, " running=", city.state.get("running"), " blocked=", city.state.get("blocked"), " tiles=", counts)
	return city.disaster_effects.spawned - before

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.orbit.enabled = false
	city.core.simulation.enable_test_commands()
	DisplayServer.window_set_size(Vector2i(1600, 1000)); await frames()
	city.core.query("speed 3")
	city.core.query("pause 0")
	var land := open_land(4)
	var shore := open_land(3, true)
	print("DISASTER_SITES land=", land, " shore=", shore)
	check(land.x != 99999, "open land for an earthquake, lava and a landslide")
	if land.x != 99999:
		var quake := await disaster("earthquake", land, 4.0, "quake")
		check(quake > 0, "an earthquake draws dust and falling stones (%d effects)" % quake)
		var lava := await disaster("lava", land, 4.0, "lava")
		check(lava > 0, "a lava flow throws blobs and glows where they land (%d effects)" % lava)
		# The real landslide event raises the engine's alert, which opens the landslide effect (altitude changes are otherwise a pyramid rising).
		city.core.query("test_raise landSlide")
		await wait_running(.6)
		var hill := slope_land()
		print("DISASTER_SITES slope=", hill)
		if hill.x != 99999:
			var slide := await disaster("landslide", hill, 4.0, "landslide")
			check(slide > 0, "a landslide draws dust and tumbling stones (%d effects)" % slide)
	if shore.x != 99999:
		var surge := await disaster("tidal", shore, 5.0, "tidal")
		check(surge > 0, "a tidal wave sends surf and spray over the land (%d effects)" % surge)
	else:
		print("DISASTER_INFO no shore site for a tidal wave")
	# The fire's crackle: a building on fire in view.
	city.core.query("pause 1")
	var houses: Array = city.state.buildings.filter(func(b): return str(b.asset).begins_with("common_house"))
	var burning: Dictionary = houses[0]
	look_at_cell(Vector2i(int(burning.x), int(burning.y)), 14)
	await frames(30)
	city.view_box_sent = ""
	city.send_view_box()
	for house in houses.slice(0, 4):
		city.core.query("test_fire %d %d" % [house.x, house.y])
	city.core.query("pause 0")
	# The game's audio runs muted so its log shows what would play.
	var audio: Node = root.get_node("GameAudio")
	audio.enabled = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	audio.log.clear()
	var heard := false
	for step in 200:
		await wait_running(.2)
		for entry in audio.log:
			if str(entry.path).to_lower().contains("fire"):
				heard = true
		if heard:
			break
	check(heard, "a building on fire in view is heard crackling (%d sounds logged)" % audio.log.size())
	print("DISASTER_CHECK ", "PASS" if okay else "FAIL", " ", checks, " checks")
	print("DISASTER_REVIEW_DONE")
	quit(0 if okay else 1)
