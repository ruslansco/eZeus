extends RefCounted

func forest_count(city: Node3D) -> int:
	var count := 0
	for tile in city.tiles.values():
		if (int(tile[3]) & 16) and not int(tile[4]) and not (int(tile[6]) & 8):
			count += 1
	return count

func rendered_trees(city: Node3D) -> int:
	return city.forest_batches.summary().instances

func run(city: Node3D) -> bool:
	var okay := true
	var vertices := 0
	var actual_cells := 0
	var expected_vertices := 0
	var shared := true
	for section in city.chunks.values():
		if section.get_child_count() == 0:
			continue
		var ground: MeshInstance3D = section.get_child(0)
		vertices += ground.mesh.surface_get_array_len(0)
		actual_cells += ground.get_meta("tile_count")
		expected_vertices += int(ground.get_meta("top_vertices"))+int(ground.get_meta("side_faces"))*6
		shared = shared and ground.material_override == city.terrain_style.ground_material
		if section.get_child_count() > 1:
			shared = shared and section.get_child(1).material_override == city.terrain_style.water_material
	okay = city.check(actual_cells == city.tiles.size() and vertices == expected_vertices, "terrain emits exactly the actual map cells with joined slopes/sides, preserving irregular holes") and okay
	okay = city.check(shared, "all terrain sections share the same continuous ground and coast materials") and okay
	okay = city.check(rendered_trees(city) == forest_count(city) and forest_count(city) > 0, "3D trees match native forest cells rather than fertile farmland") and okay
	var coast := Vector2i(99999, 99999)
	var bank := coast
	for point in city.tiles:
		if not (int(city.tiles[point][3]) & 4):
			continue
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Array = city.tiles.get(point + offset, [])
			if not neighbor.is_empty() and not (int(neighbor[3]) & 4) and neighbor[2] == city.tiles[point][2]:
				coast = point
				bank = point + offset
				break
		if coast != Vector2i(99999, 99999):
			break
	okay = city.check(coast != Vector2i(99999, 99999), "native river and bank available for picking checks") and okay
	var saved_target: Vector3 = city.orbit.target
	var saved_yaw: float = city.orbit.yaw
	var saved_distance: float = city.orbit.distance
	city.set_tool("road")
	city.orbit.distance = 22
	for point in [coast, bank]:
		if not city.tiles.has(point):
			continue
		city.orbit.target = city.world_position(point.x, point.y, city.tiles[point][2])
		for angle in [0.0, 90.0, 180.0, 270.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().physics_frame
			city.pick_tile(city.orbit.camera.unproject_position(city.orbit.target))
			var native: Dictionary = city.core.query("preview road %d %d 0" % [point.x, point.y])
			okay = city.check(city.picked == point and city.placement_result.get("valid", false) == native.get("valid", false), "shore/bank picking and native road eligibility at %d degrees for %s" % [angle, point]) and okay
	var candidate := Vector2i(99999, 99999)
	var forest := candidate
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		if candidate == Vector2i(99999, 99999) and int(tile[5]) and not int(tile[4]) and city.core.query("preview road %d %d 0" % [point.x, point.y]).get("valid", false):
			candidate = point
		if forest == Vector2i(99999, 99999) and int(tile[3]) == 16 and city.core.query("preview demolish %d %d 0" % [point.x, point.y]).get("valid", false):
			forest = point
		if candidate != Vector2i(99999, 99999) and forest != Vector2i(99999, 99999):
			break
	okay = city.check(candidate != Vector2i(99999, 99999) and forest != Vector2i(99999, 99999), "native road and forest-clearing sites available") and okay
	var section_ids := {}
	for key in city.chunks:
		section_ids[key] = city.chunks[key].get_instance_id()
	var rebuilds: int = city.terrain_style.coastline_rebuilds
	if candidate != Vector2i(99999, 99999):
		city.core.send("build road %d %d 0" % [candidate.x, candidate.y])
		await city.get_tree().create_timer(.4).timeout
		var same := true
		for key in section_ids:
			same = same and city.chunks[key].get_instance_id() == section_ids[key]
		okay = city.check(same and city.terrain_style.coastline_rebuilds == rebuilds and city.terrain_style.road_image.get_pixelv(candidate - city.origin).r == 1, "road construction refreshes its material without rebuilding coast or collision") and okay
		city.core.send("undo")
		await city.get_tree().create_timer(.3).timeout
		okay = city.check(city.terrain_style.road_image.get_pixelv(candidate - city.origin).r == 0, "road undo removes its material mask") and okay
	if forest != Vector2i(99999, 99999):
		var before := rendered_trees(city)
		city.core.send("demolish %d %d 0" % [forest.x, forest.y])
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(int(city.tiles[forest][3]) == 1 and rendered_trees(city) == before - 1 and rendered_trees(city) == forest_count(city), "native forest clearing removes exactly the affected 3D tree") and okay
		okay = city.check(city.terrain_style.field_image.get_pixelv(forest - city.origin).g == 0 and city.terrain_style.coastline_rebuilds == rebuilds, "forest clearing refreshes soil without changing the river") and okay
	city.set_tool("select")
	city.orbit.target = saved_target
	city.orbit.yaw = saved_yaw
	city.orbit.distance = saved_distance
	city.orbit.refresh()
	return okay
