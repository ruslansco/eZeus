extends RefCounted

# Review the real sanctuaries of the designated city: each one from four orbit angles and from straight above, so the facing of
# the statues and the temple can be compared with the footprint's front. Captures go to captures/sanctuary-<phase>-<n>-<view>.png.
func run(city: Node3D, phase: String) -> void:
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.ui_layer.visible = false
	city.orbit.enabled = false
	var pieces: Array = []
	for building in initial.buildings:
		if str(building.asset).begins_with("sanctuary_"):
			pieces.append(building)
	var seeds: Array = []
	for building in pieces:
		if str(building.asset).begins_with("sanctuary_temple_"):
			var known := false
			for seed in seeds:
				known = known or Vector2(seed.x - building.x, seed.y - building.y).length() < 16.0
			if not known:
				seeds.append(building)
	var samples := []
	var number := 0
	for seed in seeds:
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		var altitude := int(seed.altitude)
		for building in pieces:
			if Vector2(seed.x - building.x, seed.y - building.y).length() < 16.0:
				low = Vector2(minf(low.x, building.x), minf(low.y, building.y))
				high = Vector2(maxf(high.x, building.x + building.w), maxf(high.y, building.y + building.h))
		var middle := (low + high) * .5
		print("SANCTUARY_REVIEW ", number, " bounds=", low, high, " middle=", middle)
		city.orbit.target = city.world_position(middle.x - .5, middle.y - .5, altitude) + Vector3.UP * .3
		city.orbit.distance = maxf(high.x - low.x, high.y - low.y) * 1.25
		for view in [[45.0, 49.0], [135.0, 49.0], [225.0, 49.0], [315.0, 49.0], [45.0, 75.0]]:
			city.orbit.yaw = view[0]
			city.orbit.pitch = view[1]
			city.orbit.refresh()
			await city.get_tree().create_timer(.6).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/sanctuary-%s-%d-%d-%d.png" % [phase, number, int(view[0]), int(view[1])])
			await city.capture()
			samples.append({"sanctuary": number, "yaw": view[0], "pitch": view[1]})
		number += 1
	# The placement ghost, as the player sees it before founding: two layouts, unturned and turned (T), from the default camera angle and from above.
	# The real mouse pointer would move the placement (the city picks the tile under it every frame): the ghost is driven from here, so the
	# city takes no input and does no per-frame work meanwhile.
	city.set_process_unhandled_input(false)
	city.set_process(false)
	var site := open_site(initial)
	var site_height := 0
	for tile in initial.tiles:
		if int(tile[0]) == site.x and int(tile[1]) == site.y:
			site_height = int(tile[2])
			break
	for god in ["poseidon", "hermes"]:
		for quarter in [0, 1]:
			city.set_tool("temple_" + god)
			city.orientation = quarter
			city.picked = site
			city.placement_key = ""
			city.refresh_placement()
			city.orbit.target = city.world_position(site.x, site.y, site_height) + Vector3.UP * .3
			city.orbit.distance = 34.0
			for view in [[45.0, 49.0], [225.0, 49.0], [45.0, 75.0]]:
				city.orbit.yaw = view[0]
				city.orbit.pitch = view[1]
				city.orbit.refresh()
				await city.get_tree().create_timer(.6).timeout
				city.capture_path = ProjectSettings.globalize_path("res://captures/sanctuary-%s-ghost-%s-%d-%d-%d.png" % [phase, god, quarter, int(view[0]), int(view[1])])
				await city.capture()
	city.set_tool("select")
	city.set_process(true)
	city.set_process_unhandled_input(true)
	var final: Dictionary = city.core.simulation.snapshot(true)
	var intact: bool = final.tiles == initial.tiles and final.time == initial.time and final.money == initial.money and final.buildings == initial.buildings
	print("SANCTUARY_REVIEW ", "PASS " if intact and number > 0 else "FAIL ", "sanctuaries=", number, " captures=", samples.size())
	city.get_tree().quit(0 if intact and number > 0 else 1)

# The middle of a free 22 by 22 patch of buildable ground (room for the largest layout either way round): no road, building or water on it.
func open_site(state: Dictionary) -> Vector2i:
	var free := {}
	for tile in state.tiles:
		if int(tile[5]) and not int(tile[4]):
			free[Vector2i(int(tile[0]), int(tile[1]))] = int(tile[2])
	for building in state.buildings:
		for dx in int(building.w):
			for dy in int(building.h):
				free.erase(Vector2i(int(building.x) + dx, int(building.y) + dy))
	for tile in state.tiles:
		var middle := Vector2i(int(tile[0]), int(tile[1]))
		if (middle.x + middle.y) % 3 != 0 or not free.has(middle):
			continue
		var open := true
		for dx in range(-11, 11):
			for dy in range(-11, 11):
				var at := middle + Vector2i(dx, dy)
				if not free.has(at) or free[at] != free[middle]:
					open = false
					break
			if not open:
				break
		if open:
			return middle
	return Vector2i(100, -90)
