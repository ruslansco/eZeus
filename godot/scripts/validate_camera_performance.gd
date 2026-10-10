extends SceneTree
# Behavioral gates for presentation caches and eased player wheel input.
# No native city is opened and no player settings are written.
const Orbit = preload("res://scripts/orbit_camera.gd")
const Streets = preload("res://scripts/walker_streets.gd")
const Layout = preload("res://scripts/street_layout.gd")
const Geometry = preload("res://scripts/terrain_geometry.gd")
const Combat = preload("res://scripts/walker_combat.gd")
const Vat = preload("res://scripts/walker_vat.gd")
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("CAMERA_PERFORMANCE_CHECK ", "PASS " if value else "FAIL ", label)

func _initialize() -> void: call_deferred("run")

func wheel_checks() -> void:
	var orbit := Orbit.new()
	root.add_child(orbit)
	orbit.set_process(false)
	orbit.bounds = Vector2(100, 100)
	orbit.maximum_distance = 210.0
	var screen := root.get_visible_rect().size * Vector2(.55, .52)
	orbit.ground_height = func(x: float, z: float) -> float: return 2.0 + .02*x + .03*z
	orbit.snap_to_ground()
	var anchor: Vector3 = orbit.terrain_point(screen)
	var start := orbit.distance
	orbit.request_wheel_zoom(screen, .9)
	check(orbit.distance == start and is_equal_approx(orbit.wheel_distance, start*.9), "a wheel notch queues its destination without a camera jump")
	orbit.request_wheel_zoom(screen, .9)
	check(is_equal_approx(orbit.wheel_distance, start*.81), "rapid wheel notches accumulate before the next frame")
	orbit.advance_wheel_zoom(1.0/60)
	check(orbit.distance < start and orbit.distance > start*.81, "the first frame moves partway toward the destination")
	var drift := 0.0
	var previous := orbit.distance
	var monotonic := true
	for i in 60:
		orbit.advance_wheel_zoom(1.0/60)
		monotonic = monotonic and orbit.distance <= previous
		previous = orbit.distance
		var point: Vector3 = orbit.terrain_point(screen)
		drift = maxf(drift, Vector2(point.x-anchor.x, point.z-anchor.z).length())
	check(monotonic and is_equal_approx(orbit.distance, start*.81) and orbit.wheel_distance < 0, "zoom settles exactly without overshoot or residual input")
	check(drift < .01, "the surface under the cursor stays anchored throughout eased zoom (%.5f tiles)" % drift)
	var distances := []
	for fps in [30, 60, 120]:
		orbit.cancel_wheel_zoom()
		orbit.distance = 33.0; orbit.target = Vector3.ZERO; orbit.snap_to_ground()
		orbit.request_wheel_zoom(screen, .8)
		for i in fps/5: orbit.advance_wheel_zoom(1.0/fps)
		distances.append(orbit.distance)
	check(absf(distances[0]-distances[1]) < .00001 and absf(distances[1]-distances[2]) < .00001, "wheel easing is independent of 30/60/120 FPS")
	for property in ["enabled", "modal_input_blocked", "toolbar_input_blocked"]:
		orbit.cancel_wheel_zoom(); orbit.distance = 33; orbit.snap_to_ground()
		orbit.request_wheel_zoom(screen, .9)
		orbit.set(property, property != "enabled")
		orbit._process(.1)
		check(orbit.distance == 33 and orbit.wheel_distance < 0, "%s cancels pending camera motion" % property)
		orbit.set(property, property == "enabled")
	orbit.request_wheel_zoom(screen, .9)
	orbit.distance = 50.0
	orbit.advance_wheel_zoom(.1)
	check(orbit.distance == 50 and orbit.wheel_distance < 0, "a direct camera destination supersedes pending wheel input")
	orbit.request_wheel_zoom(screen, .9)
	orbit.overview(Vector2i(100, 100))
	check(orbit.wheel_distance < 0 and is_equal_approx(orbit.distance, 95), "Home overview cancels pending wheel input")
	orbit.distance = 10; orbit.snap_to_ground()
	orbit.request_wheel_zoom(screen, .5)
	orbit.advance_wheel_zoom(.1)
	check(orbit.distance == 10 and orbit.wheel_distance < 0, "eased zoom respects the closest distance")
	var atlas := {"count": 0}
	orbit.world_zoom_requested.connect(func(): atlas.count += 1; orbit.enabled = false)
	orbit.distance = orbit.maximum_distance
	orbit.request_wheel_zoom(screen, 1.1)
	check(atlas.count == 1 and orbit.wheel_distance < 0 and orbit.distance == orbit.maximum_distance, "outward zoom at the limit opens the atlas once and stops camera motion")
	orbit.overview(Vector2i(100, 100))
	check(atlas.count == 1, "Home never opens the atlas")
	orbit.free()

func cache_checks(city: Node) -> void:
	city.origin = Vector2i(-4, -4); city.extent = Vector2i(9, 9)
	var changed: Array[Vector2i] = []
	for x in range(-4, 5):
		for y in range(-4, 5):
			var cell := Vector2i(x, y)
			city.tiles[cell] = [x,y,0,1,1 if y in [0,1] else 0,1,0,0,2 if y == 0 else (1 if y == 1 else 0)]
			changed.append(cell)
	city.walker_streets.update_tiles(city.tiles, changed, true)
	var equal := true
	for cell in changed:
		equal = equal and Streets.wide_cell(city, cell) == Layout.wide(city.tiles, cell)
	check(equal, "indexed wide roads match the original topology at every fixture cell")
	var initial_tiles: Dictionary = city.tiles.duplicate(true)
	var edit := Vector2i(0, 0)
	var edits: Array[Vector2i] = [edit]
	city.tiles[edit][4] = 0; city.tiles[edit][8] = 0
	city.walker_streets.update_tiles(city.tiles, edits)
	equal = true
	for cell in changed:
		equal = equal and Streets.wide_cell(city, cell) == Layout.wide(city.tiles, cell)
	check(equal, "removing a median updates its own and neighboring lane classifications")
	city.tiles[edit][4] = 1; city.tiles[edit][8] = 3
	city.walker_streets.update_tiles(city.tiles, edits)
	equal = true
	for cell in changed:
		equal = equal and Streets.wide_cell(city, cell) == Layout.wide(city.tiles, cell)
	check(equal, "adding a boulevard invalidates neighboring lane classifications")
	var entry := {"native_position": Vector3.ZERO, "offset": 0.0, "waterborne":false, "action":1, "clips":{}}
	city.walker_streets.lane(entry, Vector3.RIGHT*.01, .016, city)
	check(entry.wide_road, "a stationary position initially recognizes a wide road")
	for cell in changed:
		city.tiles[cell][4] = 0; city.tiles[cell][8] = 0
	city.surface_revision += 1
	city.walker_streets.update_tiles(city.tiles, changed)
	city.walker_streets.lane(entry, Vector3.ZERO, .016, city)
	check(not entry.wide_road, "a held citizen observes a road edit before moving again")
	city.terrain_geometry.update(city.tiles, city.origin, city.extent, changed)
	city.terrain_bridges.geometry = city.terrain_geometry
	city.terrain_bridges.tiles = city.tiles
	var first: Vector3 = city.walker_draw_position(entry, Vector3.ZERO)
	entry.node = Node3D.new()
	entry.node.position = first + Vector3.UP*3
	check(city.walker_draw_position(entry, Vector3.ZERO) == first, "cached ground stays independent of animated node hover/lean")
	var horizontal: Vector3 = city.walker_draw_position(entry, Vector3.RIGHT*.1)
	check(is_equal_approx(horizontal.x, first.x+.1), "an eased lane change resamples the shown position")
	entry.offset = .5
	check(is_equal_approx(city.walker_draw_position(entry, Vector3.ZERO).y, first.y+.5), "changed native roof/deck offset invalidates a held position")
	entry.offset = 0.0
	for cell in changed: city.tiles[cell][2] = 4
	city.terrain_geometry.update(city.tiles, city.origin, city.extent, changed)
	city.surface_revision += 1
	check(city.walker_draw_position(entry, Vector3.ZERO).y > first.y+.8, "terrain changes invalidate stationary citizens' ground height")
	entry.node.free()
	city.tiles = initial_tiles
	var building := {"id":123,"asset":"common_house_2a","x":0,"y":2,"w":2,"h":2,"altitude":0,"orientation":0}
	var transform: Transform3D = city.building_draw_transform(building)
	building.working = true; building.bays = [{"bay":0,"good":"wood"}]
	check(city.building_draw_transform(building) == transform, "inventory and work changes preserve a building's exact placement")
	building.grow = 50
	check(city.building_draw_transform(building).basis.y.length() < transform.basis.y.length()*.6, "sanctuary/building growth invalidates the cached scale")
	building.erase("grow")
	city.tiles[Vector2i(0,1)][4] = 0; city.tiles[Vector2i(1,1)][4] = 0
	city.placement_revision += 1
	check(city.building_draw_transform(building) != transform, "a neighboring road edit invalidates facing and setback")
	building.x = 1
	check(city.building_draw_transform(building).origin.x > transform.origin.x+.8, "a changed footprint invalidates cached placement")
	var before: Dictionary = building.duplicate(true)
	city.building_draw_transform(building)
	check(before == building, "render placement never mutates the native building record")

func pose_checks(city: Node) -> void:
	var vat := Vat.new()
	var model: Node3D = load(vat.runtime_path("walker_archer")).instantiate()
	root.add_child(model)
	var parts: Array = vat.attach(model, "walker_archer")
	var entry: Dictionary = city.new_walker_entry(model, "walker_archer", -1, Vector3.ZERO, 0, parts)
	city.animate_walker(entry, 1.0, 0.0)
	var idle: Vector3 = parts[0].node.get_instance_shader_parameter("vat_idle_pose")
	entry.action = 4
	city.animate_walker(entry, .1, 0.0)
	check(Combat.fighting(entry) and parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 1.0, "combat overrides the cached idle branch")
	entry.action = 1
	city.animate_walker(entry, 1.0, 0.0)
	check(parts[0].node.get_instance_shader_parameter("vat_walk_blend") == 0.0 and parts[0].node.get_instance_shader_parameter("vat_idle_pose").x == idle.x, "returning from combat restores the exact idle branch")
	check(city.pose_pair({"a":2,"b":2}, ["a","b"], .1) == city.pose_pair({"a":2,"b":2}, ["a","b"], .9), "identical pose aliases reuse one shader pose without changing geometry")
	model.free()

func run() -> void:
	wheel_checks()
	var city = load("res://scripts/main.gd").new()
	cache_checks(city)
	pose_checks(city)
	# Take ownership of pre-created nodes without running the city's _ready().
	city.orbit.add_child(city.orbit.camera)
	city.add_child(city.walker_streets.ring)
	city.world_flight.overlay.add_child(city.world_flight.veil)
	city.add_child(city.world_flight.overlay)
	for property in city.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = city.get(property.name)
			if value is Node and value.get_parent() == null: city.add_child(value)
	city.free()
	await process_frame
	print("CAMERA_PERFORMANCE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
