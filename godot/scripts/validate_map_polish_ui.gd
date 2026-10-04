extends RefCounted

func run(city: Node3D) -> bool:
	var okay := true
	var initial: Dictionary = city.core.simulation.snapshot(true)
	var aligned := true
	var crossing_walkers := 0
	var on_deck := true
	for walker in initial.walkers:
		var expected: Vector3 = city.world_position(float(walker.x)-.5,float(walker.y)-.5,walker.altitude)
		var observed: Vector3 = city.walker_world_position(walker)
		aligned = aligned and observed == expected
		var cell := Vector2i(floori(walker.x),floori(walker.y))
		if city.terrain_bridges.is_bridge(cell) and not (walker.asset in ["fishing_boat","trade_ship"]):
			crossing_walkers += 1
			var foot: Vector3 = city.walker_surface_position(observed,0)
			on_deck = on_deck and absf(foot.y-float(city.tiles[cell][2])*.22-.14)<.00001
	okay = city.check(aligned,"native 0..1 walker coordinates convert once to centered Godot tiles, including negative map coordinates") and okay
	okay = city.check(crossing_walkers > 0 and on_deck,"actual native pedestrians over water stand on existing bridge decks") and okay
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	city.set_tool("road")
	city.orbit.distance = 10
	for direction in [0,1]:
		var point := Vector2i(99999,99999)
		for cell in city.tiles:
			if city.terrain_bridges.is_bridge(cell) and city.terrain_bridges.axis(cell) == direction:
				point = cell
				break
		if not city.tiles.has(point):
			okay = city.check(false,"native bridge axis fixture exists") and okay
			continue
		city.orbit.target = city.world_position(point.x,point.y,city.tiles[point][2])+Vector3.UP*.14
		for angle in [0.0,90.0,180.0,270.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().physics_frame
			var screen: Vector2 = city.orbit.camera.unproject_position(city.orbit.target)
			city.pick_tile(screen)
			var native: Dictionary = city.core.query("preview road %d %d 0" % [point.x,point.y])
			okay = city.check(city.picked == point and city.placement_result.get("valid",false) == native.get("valid",false),"native bridge axis %d picking/eligibility stays correct at %d degrees" % [direction,angle]) and okay
		var native_position: Vector3 = city.world_position(point.x,point.y,city.tiles[point][2])
		var boat: Vector3 = city.walker_surface_position(native_position,0,false)
		okay = city.check(boat.y == native_position.y,"waterborne models retain their native water height under bridge axis %d" % direction) and okay
	var final: Dictionary = city.core.simulation.snapshot(true)
	okay = city.check(final.tiles == initial.tiles and final.walkers == initial.walkers and final.buildings == initial.buildings and final.money == initial.money and final.time == initial.time,"bridge review and alignment queries preserve all native state") and okay
	city.set_tool("select")
	city.inspected = Vector2i(99999,99999)
	city.inspector.visible = false
	city.selection.visible = false
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay
