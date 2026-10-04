extends RefCounted

func entries(city: Node3D) -> Array:
	var result := []
	for section in city.terrain_details.records.values():
		result.append_array(section)
	return result

func at_cell(city: Node3D, cell: Vector2i) -> Array:
	return entries(city).filter(func(item): return item.cell == cell)

func run(city: Node3D) -> bool:
	var okay := true
	var all := entries(city)
	var stats: Dictionary = city.terrain_details.summary()
	okay = city.check(stats.counts.get("grass",0)>0 and stats.counts.get("shrub",0)>0 and stats.batches<350,"native city has bounded spatial outcrops and forest understory batches") and okay
	var saved_target: Vector3 = city.orbit.target
	var saved_distance: float = city.orbit.distance
	var saved_yaw: float = city.orbit.yaw
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.set_tool("road")
	city.orbit.distance = 12
	for specification in [[64,"stone"],[128,"copper"],[1024,"marble"],[4096,"orichalcum"]]:
		var point := Vector2i(99999,99999)
		for item in all:
			if item.kind == specification[1]:
				point = item.cell
				break
		okay = city.check(city.tiles.has(point),"native %s resource has actual 3D detail" % specification[1]) and okay
		if not city.tiles.has(point):
			continue
		city.orbit.target = city.world_position(point.x,point.y,city.tiles[point][2])
		for angle in [0.0,90.0,180.0,270.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().physics_frame
			city.pick_tile(city.orbit.camera.unproject_position(city.orbit.target))
			var native: Dictionary = city.core.query("preview road %d %d 0" % [point.x,point.y])
			okay = city.check(city.picked == point and city.placement_result.get("valid",false) == native.get("valid",false),"%s detail does not intercept picking or change native road eligibility at %d degrees" % [specification[1],angle]) and okay
		city.inspected = point
		city.refresh_inspection()
		okay = city.check(city.inspector.visible and city.inspector_text.text.contains(city.tr("Terrain: %s").trim_suffix(" %s")),"%s ground inspector identifies the native resource in the selected language" % specification[1]) and okay
	var queried: Dictionary = city.core.simulation.snapshot(true)
	okay = city.check(queried.tiles == initial.tiles and queried.buildings == initial.buildings and queried.walkers == initial.walkers and queried.time == initial.time and queried.money == initial.money,"resource picking/inspection leaves native resources, routes, clock and treasury unchanged") and okay
	var site := Vector2i(99999,99999)
	var forest := site
	for item in all:
		var point: Vector2i = item.cell
		if item.kind == "grass" and int(city.tiles[point][3]) == 1 and site == Vector2i(99999,99999):
			var preview: Dictionary = city.core.query("preview house %d %d 0" % [point.x,point.y])
			var dry: bool = preview.get("valid",false)
			for cell in preview.get("tiles",[]):
				var tile: Array = city.tiles.get(Vector2i(int(cell[0]),int(cell[1])),[])
				dry = dry and not tile.is_empty() and int(tile[3]) == 1
			if dry:
				site = point
		if item.kind == "shrub" and forest == Vector2i(99999,99999) and city.core.query("preview demolish %d %d 0" % [point.x,point.y]).get("valid",false):
			forest = point
		if site != Vector2i(99999,99999) and forest != Vector2i(99999,99999):
			break
	okay = city.check(city.tiles.has(site) and city.tiles.has(forest),"actual decorated dry construction and forest clearing sites are available") and okay
	if city.tiles.has(site):
		var original := at_cell(city,site)
		var before: Dictionary = city.core.simulation.snapshot(true)
		var cost: int = city.core.query("preview road %d %d 0" % [site.x,site.y]).get("cost",0)
		city.core.send("build road %d %d 0" % [site.x,site.y])
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(at_cell(city,site).is_empty() and int(city.tiles[site][4]) == 1 and int(city.state.money) == int(before.money)-cost,"native road construction removes understory and retains its exact cost") and okay
		city.core.send("undo")
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(at_cell(city,site) == original and int(city.state.money) == int(before.money),"native road undo restores the same detail layout and refund") and okay
		var preview: Dictionary = city.core.query("preview house %d %d 0" % [site.x,site.y])
		city.core.send("build house %d %d 0" % [site.x,site.y])
		await city.get_tree().create_timer(.4).timeout
		var clear := true
		for cell in preview.tiles:
			clear = clear and at_cell(city,Vector2i(int(cell[0]),int(cell[1]))).is_empty()
		okay = city.check(clear and int(city.state.money) == int(before.money)-int(preview.cost),"native housing clears all decorative footprint cells without altering construction costs") and okay
		city.core.send("undo")
		await city.get_tree().create_timer(.4).timeout
		okay = city.check(at_cell(city,site) == original and int(city.state.money) == int(before.money),"housing undo restores deterministic vegetation and the native refund") and okay
	if city.tiles.has(forest):
		var old_rebuilds: int = city.terrain_style.coastline_rebuilds
		var before: Dictionary = city.core.simulation.snapshot(true)
		var preview: Dictionary = city.core.query("preview demolish %d %d 0" % [forest.x,forest.y])
		city.core.send("demolish %d %d 0" % [forest.x,forest.y])
		await city.get_tree().create_timer(.4).timeout
		var shrubs := at_cell(city,forest).filter(func(item): return item.kind == "shrub")
		okay = city.check(int(city.tiles[forest][3]) == 1 and shrubs.is_empty() and city.terrain_style.coastline_rebuilds == old_rebuilds and int(city.state.money) == int(before.money)-int(preview.cost),"native forest clearing removes its shrubs, refreshes neighbor habitat and preserves native cost/coast") and okay
	okay = city.check(city.core.simulation.snapshot(true).time == initial.time,"detail construction/inspection tests never advance the paused simulation") and okay
	city.set_tool("select")
	city.inspected = Vector2i(99999,99999)
	city.inspector.visible = false
	city.selection.visible = false
	city.orbit.target = saved_target
	city.orbit.distance = saved_distance
	city.orbit.yaw = saved_yaw
	city.orbit.refresh()
	return okay
