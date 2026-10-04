extends RefCounted

# Review pyramids from four orbit angles and from straight above. Captures go to captures/pyramid-<phase>-<n>-<yaw>-<pitch>.png.
#   --pyramid-review=<name>                  the pyramids the designated city already has
#   --pyramid-review=menu                    the Build menu with all 54 granted: the Pyramids and Shrines trays
#   --pyramid-review=ghost:<tool>[,<tool>]  the placement ghost of each (granted by the validators' allowance), pointer on a free site beside a road
#   --pyramid-review=build:<tool>[,<tool>]   founds each pyramid (a build tool of the core) beside a road, with the scenario's allowance and
#                                            the validators' funding, captures it a little way into its building and again when it stands
#                                            (the city is a copy in memory: nothing is saved)
const GROUP_RADIUS := 14.0

func run(city: Node3D, phase: String) -> void:
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	city.ui_layer.visible = false
	city.orbit.enabled = false
	if phase == "menu":
		await capture_menu(city)
		return
	if phase.begins_with("ghost:"):
		await capture_ghost(city, phase.trim_prefix("ghost:").split(","))
		return
	if phase.begins_with("build:"):
		await build_and_capture(city, phase.trim_prefix("build:").split(","))
		return
	var initial: Dictionary = city.core.simulation.snapshot(true)
	var pieces: Array = []
	for building in initial.buildings:
		if str(building.asset).begins_with("pyramid_"):
			pieces.append(building)
	var groups: Array = []
	for building in pieces:
		var known := false
		for group in groups:
			known = known or Vector2(group.x - building.x, group.y - building.y).length() < GROUP_RADIUS
		if not known:
			groups.append(building)
	var number := 0
	var captures := 0
	for first in groups:
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for building in pieces:
			if Vector2(first.x - building.x, first.y - building.y).length() < GROUP_RADIUS:
				low = Vector2(minf(low.x, building.x), minf(low.y, building.y))
				high = Vector2(maxf(high.x, building.x + building.w), maxf(high.y, building.y + building.h))
		captures += await capture_around(city, phase, number, low, high, int(first.altitude))
		number += 1
	print("PYRAMID_REVIEW ", "PASS " if number > 0 else "FAIL ", "pyramids=", number, " captures=", captures)
	city.get_tree().quit(0 if number > 0 else 1)

func capture_around(city: Node3D, phase: String, number: int, low: Vector2, high: Vector2, altitude: int) -> int:
	var middle := (low + high) * .5
	print("PYRAMID_REVIEW ", number, " bounds=", low, high, " middle=", middle)
	city.orbit.target = city.world_position(middle.x - .5, middle.y - .5, altitude) + Vector3.UP * .3
	city.orbit.distance = maxf(high.x - low.x, high.y - low.y) * 1.6 + 4.0
	var taken := 0
	DisplayServer.window_move_to_foreground()
	for view in [[45.0, 40.0], [135.0, 40.0], [225.0, 40.0], [315.0, 40.0], [45.0, 75.0]]:
		city.orbit.yaw = view[0]
		city.orbit.pitch = view[1]
		city.orbit.refresh()
		await city.get_tree().create_timer(.6).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/pyramid-%s-%d-%d-%d.png" % [phase, number, int(view[0]), int(view[1])])
		await city.capture()
		taken += 1
	return taken

# A free site beside a road, so that the carts can reach the pyramid (the footprint is centred on the tile).
func road_site(city: Node3D, tool: String) -> Vector2i:
	var size := Vector2i(3, 3)
	for item in city.core.query("buildable").buildings:
		if str(item.name) == tool:
			size = Vector2i(int(item.w), int(item.h))
	var roads := {}
	for point in city.tiles:
		if int(city.tiles[point][4]) == 1:
			roads[point] = true
	for point in city.tiles:
		if not int(city.tiles[point][5]) or int(city.tiles[point][4]):
			continue
		var min_x: int = point.x - size.x / 2
		var min_y: int = point.y - size.y / 2
		var touches := false
		for dx in range(-1, size.x + 1):
			touches = touches or roads.has(Vector2i(min_x + dx, min_y - 1)) or roads.has(Vector2i(min_x + dx, min_y + size.y))
		for dy in range(-1, size.y + 1):
			touches = touches or roads.has(Vector2i(min_x - 1, min_y + dy)) or roads.has(Vector2i(min_x + size.x, min_y + dy))
		if touches and city.core.query("preview %s %d %d 0" % [tool, point.x, point.y]).get("valid", false):
			return point
	return Vector2i(99999, 99999)

func progress_of(city: Node3D, at: Vector2i) -> int:
	return int(city.core.query("inspect %d %d" % [at.x, at.y]).get("monument", {}).get("progress", -1))

# Runs the city (answering its decisions) a few seconds at a time until the pyramid at `at` has come `percent` far or the time is spent.
func run_until(city: Node3D, at: Vector2i, percent: int, seconds: float) -> int:
	city.core.query("speed 3")
	city.core.query("pause 0")
	var started := Time.get_ticks_msec()
	var progress := progress_of(city, at)
	while progress < percent and float(Time.get_ticks_msec() - started) < seconds * 1000.0:
		for step in 40:
			city.core.simulation.advance(.2)
		var running: Dictionary = city.core.simulation.snapshot(false)
		city.receive_state(running)
		for event in running.get("events", []):
			var choices: Array = event.get("actions", [])
			city.core.query("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		await city.get_tree().process_frame
		progress = progress_of(city, at)
	city.core.query("pause 1")
	await city.get_tree().create_timer(.5).timeout
	return progress

func build_and_capture(city: Node3D, tools: PackedStringArray) -> void:
	city.core.simulation.enable_test_commands()
	var number := 0
	var captures := 0
	for tool in tools:
		city.core.query("test_allow " + tool)
		var site := road_site(city, tool)
		if site.x == 99999:
			print("PYRAMID_REVIEW no site for ", tool)
			continue
		var plan: Dictionary = city.core.query("preview %s %d %d 0" % [tool, site.x, site.y])
		var built: Dictionary = city.core.query("build %s %d %d 0" % [tool, site.x, site.y])
		# A command's answer is the snapshot of what it changed; the city never sees one that is only queried.
		if built.has("protocol"):
			city.receive_state(built)
		print("PYRAMID_REVIEW ", tool, " at ", site, " ", plan.w, "x", plan.h, " pieces=", plan.pieces.size(), " ", built.get("error", "founded"))
		if built.has("error"):
			continue
		var low := Vector2(float(plan.x), float(plan.y))
		var high := low + Vector2(float(plan.w), float(plan.h))
		city.core.query("test_fund %d %d" % [site.x, site.y])
		await city.get_tree().create_timer(.4).timeout
		await city.get_tree().create_timer(1.0).timeout
		# The foundations, then partway, then done.
		captures += await capture_around(city, "%s-%s-founded" % [tools[0].get_slice("_", 0), tool], number, low, high, int(plan.altitude))
		var midway := await run_until(city, site, 40, 90.0)
		print("PYRAMID_REVIEW ", tool, " is ", midway, "% built")
		captures += await capture_around(city, "%s-building" % tool, number, low, high, int(plan.altitude))
		var done := await run_until(city, site, 100, 150.0)
		print("PYRAMID_REVIEW ", tool, " is ", done, "% built")
		captures += await capture_around(city, "%s-done" % tool, number, low, high, int(plan.altitude))
		number += 1
	print("PYRAMID_REVIEW ", "PASS " if number > 0 else "FAIL ", "pyramids=", number, " captures=", captures)
	city.get_tree().quit(0 if number > 0 else 1)

# The Build menu once the scenario grants everything: the trays of the two categories, captured with the interface on.
func capture_menu(city: Node3D) -> void:
	city.core.simulation.enable_test_commands()
	for item in city.core.query("buildable").buildings:
		if str(item.name).begins_with("pyramid_") or str(item.name).begins_with("shrine_"):
			city.core.query("test_allow " + str(item.name))
	city.refresh_catalog()
	city.ui_layer.visible = true
	var taken := 0
	for title in ["Pyramids", "Shrines"]:
		city.hud.open_category(title)
		await city.get_tree().create_timer(1.2).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/pyramid-menu-%s.png" % title.to_lower())
		await city.capture()
		taken += 1
	print("PYRAMID_REVIEW ", "PASS " if taken == 2 else "FAIL ", "menus=", taken)
	city.get_tree().quit(0 if taken == 2 else 1)

# The placement ghost of each tool over a free site beside a road: the camera centres on the site and the pointer rests in the middle of the
# view; captured with the interface on.
func capture_ghost(city: Node3D, tools: PackedStringArray) -> void:
	city.core.simulation.enable_test_commands()
	city.ui_layer.visible = true
	var taken := 0
	for tool in tools:
		city.core.query("test_allow " + tool)
		city.refresh_catalog()
		var site := road_site(city, tool)
		if site.x == 99999:
			print("PYRAMID_REVIEW no site for ", tool)
			continue
		var plan: Dictionary = city.core.query("preview %s %d %d 0" % [tool, site.x, site.y])
		city.orbit.target = city.world_position(site.x, site.y, int(plan.altitude))
		city.orbit.distance = maxf(float(plan.w), float(plan.h)) * 1.7 + 6.0
		city.orbit.yaw = 45.0
		city.orbit.pitch = 42.0
		city.orbit.refresh()
		city.set_tool(tool)
		DisplayServer.window_move_to_foreground()
		await city.get_tree().create_timer(.5).timeout
		# The pointer is the review's own: the game's per-frame picking is switched off and the placement is refreshed by hand.
		city.set_process(false)
		city.orientation = 0
		city.picked = site
		city.placement_key = ""
		city.refresh_placement()
		await city.get_tree().create_timer(.6).timeout
		print("PYRAMID_REVIEW ghost ", tool, " picked=", city.picked, " site=", site, " visible=", city.sanctuary_ghost.visible, " hint=", city.hint.text)
		city.capture_path = ProjectSettings.globalize_path("res://captures/pyramid-ghost-%s.png" % tool)
		await city.capture()
		city.set_process(true)
		taken += 1
	print("PYRAMID_REVIEW ", "PASS " if taken == tools.size() else "FAIL ", "ghosts=", taken)
	city.get_tree().quit(0 if taken == tools.size() else 1)
