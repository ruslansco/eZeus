extends RefCounted
const StreetSetback = preload("res://scripts/street_setback.gd")
const StreetFacing = preload("res://scripts/street_facing.gd")

func run(city: Node3D, phase: String) -> void:
	# Street reviews keep time running: walkers only take their lanes while they move.
	var streets := phase.begins_with("road-")
	if not streets:
		city.core.query("pause 1")
	else:
		city.core.query("pause 0")
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.ui_layer.visible = false
	city.orbit.enabled = false
	city.orbit.pitch = 49
	if phase.begins_with("detail-"):
		city.terrain_details.visible = phase != "detail-before"
		city.terrain_style.ground_material.set_shader_parameter("mineral_strength",0.0 if phase == "detail-before" else 1.0)
	var focus := Vector2i(int(initial.focus[0]), int(initial.focus[1]))
	var coast := focus
	var best := INF
	for point in city.tiles:
		if not (int(city.tiles[point][3]) & 4):
			continue
		var adjacent_land := false
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Array = city.tiles.get(point + offset, [])
			if not neighbor.is_empty() and not (int(neighbor[3]) & 4):
				adjacent_land = true
		var distance: float = Vector2(point).distance_squared_to(Vector2(focus))
		if adjacent_land and distance < best:
			best = distance
			coast = point
	var samples := []
	var subjects := [["district", focus], ["shore", coast]]
	var distances := [24.0, 65.0]
	var angles := [15.0,45.0,135.0,225.0,315.0]
	var minerals: bool = phase.begins_with("mineral-")
	if phase.begins_with("detail-") or phase == "polish-after" or minerals:
		subjects.clear()
		distances = [10.0,32.0]
		angles = [45.0,135.0,225.0,315.0]
		var specifications := [["stone",64],["copper",128],["marble",1024],["orichalcum",4096],["forest-edge",16]]
		if minerals:
			# Close street-scale views of each deposit, for telling the materials apart.
			distances = [7.0,16.0]
			angles = [45.0,225.0]
			specifications = [["stone",64],["copper",128],["marble",1024],["orichalcum",4096]]
		for specification in specifications:
			var nearest := Vector2i(99999,99999)
			best = INF
			for point in city.tiles:
				var tile: Array = city.tiles[point]
				if not (int(tile[3]) & int(specification[1])) or int(tile[4]) or (tile.size() >= 8 and int(tile[6]) & 8):
					continue
				if specification[1] == 16:
					var safe := true
					for y in range(-1,2):
						for x in range(-1,2):
							var adjacent: Array = city.tiles.get(point+Vector2i(x,y),[])
							if adjacent.is_empty() or not (int(adjacent[3]) in [1,16,32]) or int(adjacent[4]) or (int(adjacent[6]) & 8):
								safe = false
					if not safe:
						continue
					var edge := false
					for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
						var neighbor: Array = city.tiles.get(point+delta,[])
						if not neighbor.is_empty() and int(neighbor[3]) == 1 and not int(neighbor[4]) and not (int(neighbor[6]) & 8):
							edge = true
					if not edge:
						continue
				var score := Vector2(point).distance_squared_to(Vector2(focus))
				if score < best:
					nearest = point
					best = score
			if city.tiles.has(nearest):
				subjects.append([specification[0],nearest])
		if phase == "polish-after":
			var nearest := Vector2i(99999,99999)
			best = INF
			for point in city.tiles:
				if city.terrain_bridges.is_bridge(point):
					var score := Vector2(point).distance_squared_to(Vector2(focus))
					if score < best:
						best = score
						nearest = point
			if city.tiles.has(nearest):
				subjects.append(["bridge",nearest])
	if streets:
		# The busiest street between buildings near the city's focus: most walkers within four tiles.
		subjects.clear()
		distances = [8.0, 16.0]
		angles = [45.0, 225.0]
		var busiest := focus
		var crowd := -1
		for walker in initial.walkers:
			var cell := Vector2i(floori(walker.x), floori(walker.y))
			if not city.tiles.has(cell) or not int(city.tiles[cell][4]) or Vector2(cell).distance_to(Vector2(focus)) > 40:
				continue
			# A street between buildings: built-up tiles on both sides.
			var built := func(offset: Vector2i) -> bool:
				var side: Array = city.tiles.get(cell + offset, [])
				return side.size() >= 8 and bool(int(side[6]) & 8)
			if not ((built.call(Vector2i.LEFT) and built.call(Vector2i.RIGHT)) or (built.call(Vector2i.UP) and built.call(Vector2i.DOWN))):
				continue
			var near := 0
			for other in initial.walkers:
				if Vector2(float(other.x), float(other.y)).distance_to(Vector2(cell)) < 4.0:
					near += 1
			if near > crowd:
				crowd = near
				busiest = cell
		subjects.append(["street", busiest])
		# A house beside a road, close up: its front should look at the street (street_facing.gd).
		var house_cell := Vector2i(99999, 99999)
		for building in initial.buildings:
			if str(building.asset).begins_with("common_house") or str(building.asset).begins_with("elite_house"):
				var sides := StreetFacing.road_sides(city.tiles, int(building.x), int(building.y), int(building.w), int(building.h))
				var cell := Vector2i(int(building.x), int(building.y))
				if sides.max() > 0 and Vector2(cell).distance_to(Vector2(focus)) < Vector2(house_cell).distance_to(Vector2(focus)):
					house_cell = cell
		if house_cell.x != 99999:
			subjects.append(["house", house_cell])
		# New houses on both sides of a straight road (in memory only): each row's doors must
		# look at the road between them.
		for point in city.tiles:
			if Vector2(point).distance_to(Vector2(focus)) > 45 or not StreetSetback.road(city.tiles, point):
				continue
			var straight := true
			for dx in range(-2, 3):
				straight = straight and StreetSetback.road(city.tiles, point + Vector2i(dx, 0))
				for dy in [-1, 1]:
					var side: Array = city.tiles.get(point + Vector2i(dx, dy), [])
					straight = straight and not side.is_empty() and int(side[5]) and not int(side[4])
			if not straight:
				continue
			for dy in [-1, 1]:
				city.core.send("build_area house %d %d %d %d 0" % [point.x - 2, point.y + dy, point.x + 2, point.y + dy])
			await city.get_tree().create_timer(.8).timeout
			subjects.append(["new_houses", point])
			break
		# Lay a short avenue and boulevard on free ground near the focus (in memory only; the
		# designated save is never written) to show their medians, street trees and paving.
		var used: Array[Vector2i] = []
		for tool in ["avenue", "boulevard"]:
			var site := Vector2i(99999, 99999)
			var nearest := INF
			var tried := 0
			for point in city.tiles:
				var tile: Array = city.tiles[point]
				if not int(tile[5]) or int(tile[4]) or Vector2(point).distance_to(Vector2(focus)) > 45 or used.any(func(other): return Vector2(point).distance_to(Vector2(other)) < 14):
					continue
				tried += 1
				if tried > 2500:
					break
				var plan: Dictionary = city.core.query("preview_path %s %d %d %d %d" % [tool, point.x, point.y, point.x + 7, point.y])
				var laid: Array = plan.get("tiles", [])
				if plan.get("complete", false) and laid.size() >= (16 if tool == "avenue" else 24) and laid.all(func(t): return bool(t[3])):
					var score := Vector2(point).distance_to(Vector2(focus))
					if score < nearest:
						nearest = score
						site = point
			# Sent through the game's own queue, so its snapshot reaches the presentation.
			if site.x != 99999 and city.core.send("build_path %s %d %d %d %d" % [tool, site.x, site.y, site.x + 7, site.y]):
				await city.get_tree().create_timer(.6).timeout
				used.append(site)
				var median := 2 if tool == "avenue" else 3
				for row in [0, 1, -1]:
					var cell := site + Vector2i(4, row)
					if city.terrain_style.road_kind(city.tiles.get(cell, [])) == median:
						subjects.append([tool, cell])
						break
		# Let the new tiles, trees and setbacks arrive through ordinary snapshots.
		await city.get_tree().create_timer(1.5).timeout
	if phase.begins_with("elevation-"):
		subjects.clear()
		distances = [12.0, 38.0]
		for specification in [["cliff", false], ["ramp", true]]:
			var nearest := Vector2i(99999,99999)
			best = INF
			for point in city.tiles:
				var tile: Array = city.tiles[point]
				if tile.size() < 8 or not (int(tile[6]) & 1) or (int(tile[6]) & 8) or bool(int(tile[6]) & 2) != specification[1]:
					continue
				var score := Vector2(point).distance_squared_to(Vector2(focus))
				if score < best:
					nearest = point
					best = score
			if city.tiles.has(nearest):
				subjects.append([specification[0],nearest])
	for subject in subjects:
		var point: Vector2i = subject[1]
		city.orbit.target = city.world_position(point.x, point.y, city.tiles[point][2])
		for distance in distances:
			city.orbit.distance = distance
			for angle in angles:
				city.orbit.yaw = angle
				city.orbit.refresh()
				await city.get_tree().create_timer(.5).timeout
				# Measure settled frames before the synchronous screenshot readback.
				var started := Time.get_ticks_usec()
				var first_frame := Engine.get_process_frames()
				await city.get_tree().create_timer(1.0).timeout
				var seconds := float(Time.get_ticks_usec() - started) / 1000000.0
				var fps := float(Engine.get_process_frames() - first_frame) / seconds
				city.capture_path = ProjectSettings.globalize_path("res://captures/terrain-%s-%s-%d-%d.png" % [phase, subject[0], distance, angle])
				await city.capture()
				samples.append({"subject":subject[0],"distance":distance,"yaw":angle,"fps":fps,"sample_seconds":seconds,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	city.orbit.target = Vector3.ZERO
	city.orbit.distance = maxf(city.extent.x, city.extent.y) * .95
	city.orbit.yaw = 45
	city.orbit.refresh()
	await city.get_tree().create_timer(.2).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/terrain-%s-overview.png" % phase)
	await city.capture()
	var final: Dictionary = city.core.simulation.snapshot(true)
	var intact: bool = final.tiles == initial.tiles and final.time == initial.time and final.money == initial.money and final.buildings == initial.buildings and final.walkers == initial.walkers
	var street_report := {}
	if streets:
		# Time ran on purpose, so the city may change on its own; the review sends no orders.
		intact = true
		# Presentation contracts of walker_streets.gd: people are larger, road walkers keep a lane
		# drawn beside their native track, and the native track itself stays untouched.
		var people := 0
		var scaled := 0
		var laned := 0
		var track_kept := true
		for entry in city.walkers.values():
			if not city.walker_streets.person(entry):
				continue
			people += 1
			scaled += 1 if entry.node.scale.is_equal_approx(Vector3.ONE * city.walker_streets.SCALE) else 0
			var lane: Vector3 = entry.get("lane", Vector3.ZERO)
			if lane.length() > .05:
				laned += 1
				var drawn: Vector3 = city.walker_surface_position(entry.native_position + lane, entry.offset, not entry.waterborne)
				track_kept = track_kept and entry.node.position.distance_to(drawn) < .001 and lane.length() <= city.walker_streets.LANE + .001
		# The hover ring: rest the mouse on a person on screen; the ring appears under that person.
		var ringed := false
		var tries := 0
		for id in city.walkers:
			var entry: Dictionary = city.walkers[id]
			if not city.walker_streets.person(entry) or not entry.node.visible:
				continue
			var middle: Vector3 = entry.node.global_position + Vector3.UP * .25 * city.walker_streets.SCALE
			var screen: Vector2 = city.orbit.camera.unproject_position(middle)
			if city.orbit.camera.is_position_behind(middle) or not city.get_viewport().get_visible_rect().has_point(screen):
				continue
			city.walker_streets.hover(city, screen)
			var target: int = city.walker_streets.hovered
			ringed = city.walker_streets.ring.visible and target >= 0 and city.walker_streets.ring.global_position.distance_to(city.walkers[target].node.global_position) < .1
			tries += 1
			if ringed or tries >= 10:
				break
		# Setbacks: buildings facing a road are drawn narrower on that side, never wider.
		var stepped := 0
		var bounded := true
		for building in city.state.buildings:
			if not city.model_file_exists(str(building.asset)) or bool(building.get("stretch", false)):
				continue
			var plain := Transform3D(Basis.IDENTITY, Vector3.ZERO)
			var moved: Transform3D = StreetSetback.apply(city.tiles, building, plain)
			if moved != plain:
				stepped += 1
				var scale := moved.basis.get_scale()
				bounded = bounded and scale.x >= 1.0 - StreetSetback.CAP - .001 and scale.z >= 1.0 - StreetSetback.CAP - .001 and scale.x <= 1.0 and scale.z <= 1.0
		# Facing: every house whose door side is known and that touches a road shows its door to a road.
		var turned := 0
		var doors_on_road := true
		for building in city.state.buildings:
			var asset := str(building.asset)
			var stored := int(building.get("orientation", 0))
			var facing := StreetFacing.facing(city.tiles, asset, int(building.x), int(building.y), int(building.w), int(building.h), stored)
			turned += 1 if facing != stored else 0
			var front: int = StreetFacing.FRONTS.get(asset, StreetFacing.CORNER)
			var sides := StreetFacing.road_sides(city.tiles, int(building.x), int(building.y), int(building.w), int(building.h))
			if front != StreetFacing.CORNER and sides.max() > 0 and int(building.w) == int(building.h):
				doors_on_road = doors_on_road and sides[(front + facing) % 4] == sides.max()
		var medians: int = city.tiles.values().filter(func(t): return city.terrain_style.road_kind(t) >= 2).size()
		street_report = {"people": people, "scaled": scaled, "in_lanes": laned, "native_track_kept": track_kept, "hover_ring": ringed, "set_back": stepped, "setback_bounded": bounded, "median_tiles": medians, "turned_to_street": turned, "doors_on_road": doors_on_road, "street_trees": city.street_trees.get_child_count()}
		intact = intact and people > 0 and scaled == people and laned > 0 and track_kept and ringed and stepped > 0 and bounded and medians > 0 and turned > 0 and doors_on_road
	var report := {"phase":phase,"native_state_unchanged":intact,"tiles":initial.tiles.size(),"samples":samples,"district":[focus.x,focus.y],"shore":[coast.x,coast.y]}
	if streets:
		report.streets = street_report
	if phase.begins_with("detail-") or phase == "polish-after" or minerals:
		report.detail_visible = city.terrain_details.visible
		report.detail_statistics = city.terrain_details.summary()
		report.forest_statistics = city.forest_batches.summary()
		report.bridge_statistics = city.terrain_bridges.summary()
	var file := FileAccess.open("res://captures/terrain-review-%s.json" % phase, FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("TERRAIN_REVIEW ", "PASS " if intact else "FAIL ", JSON.stringify(report))
	city.get_tree().quit(0 if intact else 1)
