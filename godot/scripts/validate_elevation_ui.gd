extends RefCounted

func run(city: Node3D) -> bool:
	var okay := true
	var cliff := Vector2i(99999,99999)
	var ramp := cliff
	var available := cliff
	for cell in city.tiles:
		var tile: Array = city.tiles[cell]
		if tile.size() < 8 or not city.terrain_geometry.sloped(cell):
			continue
		if not (int(tile[6]) & 2):
			cliff = cell
		else:
			ramp = cell
			var occupied := false
			for walker in city.state.walkers:
				occupied = occupied or Vector2i(floori(walker.x),floori(walker.y)) == cell
			if not occupied and city.core.query("preview demolish %d %d 0" % [cell.x,cell.y]).get("valid",false):
				available = cell
		if city.tiles.has(cliff) and city.tiles.has(ramp) and city.tiles.has(available):
			break
	okay = city.check(city.tiles.has(cliff) and city.tiles.has(ramp),"native blocked cliff and walkable road ramp are available") and okay
	var target: Vector3 = city.orbit.target
	var yaw: float = city.orbit.yaw
	var distance: float = city.orbit.distance
	var before: Dictionary = city.core.simulation.snapshot(true)
	city.set_tool("road")
	city.orbit.distance = 12
	for cell in [cliff,ramp]:
		if not city.tiles.has(cell):
			continue
		var center: Vector3 = city.world_position(cell.x,cell.y,city.tiles[cell][2])
		center.y = city.terrain_geometry.height_at(cell.x,cell.y)
		city.orbit.target = center
		for angle in [0.0,90.0,180.0,270.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().physics_frame
			city.pick_tile(city.orbit.camera.unproject_position(center))
			var oracle: Dictionary = city.core.query("preview road %d %d %d" % [cell.x,cell.y,city.orientation])
			okay = city.check(city.picked == cell and city.placement_result.get("valid",false) == oracle.get("valid",false) and absf(city.ghost.position.y-center.y-.02) < .001,"3D slope picking, native eligibility and road ghost height at %d degrees for %s" % [angle,cell]) and okay
		if cell == cliff:
			okay = city.check(not city.placement_result.get("valid",true),"blocked native cliff remains unavailable for road construction") and okay
		else:
			var normal: Vector3 = city.terrain_geometry.normal_at(city.terrain_geometry.profile(cell),.5,.5)
			okay = city.check(city.ghost.basis.y.normalized().dot(normal) > .999,"road ghost tilts along the native ramp independently of camera yaw") and okay
		var native_point: Vector3 = city.world_position(cell.x+.13,cell.y+.17,city.tiles[cell][2])
		var projected: Vector3 = city.walker_surface_position(native_point,0.0)
		okay = city.check(projected.x == native_point.x and projected.z == native_point.z and absf(projected.y-city.terrain_geometry.height_at(cell.x+.13,cell.y+.17)) < .00001,"walker presentation follows the slope without changing native horizontal coordinates") and okay
	var after: Dictionary = city.core.simulation.snapshot(true)
	okay = city.check(after.tiles == before.tiles and after.money == before.money and after.time == before.time and after.walkers == before.walkers,"slope picking/ghost/foot projection does not change native terrain, time, money or walkers") and okay
	okay = city.check(city.tiles.has(available),"an unoccupied native road ramp is available for construction regression") and okay
	if city.tiles.has(available):
		var cell: Vector2i = available
		var profile: PackedFloat32Array = city.terrain_geometry.profile(cell).duplicate()
		city.core.send("demolish %d %d 0" % [cell.x,cell.y])
		await city.get_tree().create_timer(.4).timeout
		var preview: Dictionary = city.core.query("preview road %d %d 0" % [cell.x,cell.y])
		okay = city.check(preview.get("valid",false) and city.terrain_geometry.profile(cell) == profile,"native ramp keeps its slope and allows road reconstruction after demolition") and okay
		if preview.get("valid",false):
			var money: int = city.state.money
			city.core.send("build road %d %d 0" % [cell.x,cell.y])
			await city.get_tree().create_timer(.4).timeout
			okay = city.check(int(city.tiles[cell][4]) == 1 and int(city.state.money) == money-int(preview.cost) and city.terrain_geometry.profile(cell) == profile,"ramp road construction preserves native cost/terrain and the continuous surface") and okay
			city.inspected = cell
			city.refresh_inspection()
			okay = city.check(city.inspector.visible,"native ramp road inspector still opens") and okay
			city.core.send("undo")
			await city.get_tree().create_timer(.3).timeout
			okay = city.check(int(city.tiles[cell][4]) == 0 and int(city.state.money) == money and city.terrain_geometry.profile(cell) == profile,"ramp road undo refunds the native cost without changing elevation") and okay
			city.core.send("build road %d %d 0" % [cell.x,cell.y])
			await city.get_tree().create_timer(.3).timeout
	# Footprint markers outside an irregular map remain temporary red UI meshes.
	var outside := Vector2i(-9999,-9999)
	var marker: ArrayMesh = city.terrain_geometry.footprint_mesh(outside,0)
	okay = city.check(marker.surface_get_array_len(0) == 6 and not city.tiles.has(outside),"invalid out-of-map footprint feedback does not fabricate native terrain") and okay
	city.set_tool("select")
	city.orbit.target = target
	city.orbit.yaw = yaw
	city.orbit.distance = distance
	city.orbit.refresh()
	return okay
