extends RefCounted

# Review the rest of the SDL build menu in the designated city (a copy in memory: nothing is saved). Captures go to
# captures/menu-rest-<phase>-<name>-<yaw>.png.
#   --menu-rest-review=menu    the Build menu's trays that gained buildings, with every scenario grant allowed
#   --menu-rest-review=city    the City window (F7) on its summary, employment, administration and military pages
#   --menu-rest-review=naval   a trireme launched at a new wharf, a race on a four-plate hippodrome, and the other new models
#                              (Greek chariot, enemy boat, the silver and orichalc miners) standing beside it
#   cities (after --start-review): The Sands of Betrayal's city for sale with its offer, bought through the Buy button, the
#                              menu of the player's two cities, and the pages following the city in view
#   --menu-rest-review=anim    a trireme rowing as it sails, the two rioters, and the newly animated buildings the city has at
#                              work, each at two moments
#   --menu-rest-review=build   builds each new kind of building on a free site (the validators' allowance for those a
#                              scenario grants) and captures it from two sides with its placement ghost shown first
const TOOLS := ["stadium", "horse_ranch", "fishery", "trireme_wharf", "urchin_quay", "hippodrome", "water_park",
	"monument_victory", "god_monument_zeus", "roadblock", "bridge"]
const MENUS := ["Agriculture", "Culture", "Walls and defence", "Gardens and monuments", "Housing and roads", "Administration and security"]

func run(city: Node3D, phase: String) -> void:
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	city.core.simulation.enable_test_commands()
	city.orbit.enabled = false
	if phase == "menu":
		await capture_menus(city)
	elif phase == "city":
		await capture_city_window(city)
	elif phase == "naval":
		await capture_naval(city)
	elif phase == "cities":
		await capture_cities(city)
	elif phase == "anim":
		await capture_animation(city)
	else:
		await build_and_capture(city)

func capture_menus(city: Node3D) -> void:
	for item in city.core.query("buildable").buildings:
		var name := str(item.name)
		if name.begins_with("monument_") or name.begins_with("god_monument_") or name in ["urchin_quay", "hippodrome", "crosswalk", "goat", "cattle"]:
			city.core.query("test_allow " + name)
	city.core.query("test_allow dairy")
	city.core.query("test_allow corral")
	city.refresh_catalog()
	city.ui_layer.visible = true
	var taken := 0
	for title in MENUS:
		city.hud.open_category(title)
		await city.get_tree().create_timer(1.2).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-menu-%s.png" % title.to_lower().replace(" ", "_"))
		await city.capture()
		taken += 1
	print("MENU_REST_REVIEW ", "PASS " if taken == MENUS.size() else "FAIL ", "menus=", taken)
	city.get_tree().quit(0 if taken == MENUS.size() else 1)

# The first tile where the tool previews valid (shore and street tools search every tile, the others free ground).
func site(city: Node3D, tool: String) -> Vector2i:
	var any := tool in ["fishery", "trireme_wharf", "urchin_quay", "bridge", "roadblock"]
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		if not any and (not int(tile[5]) or int(tile[4])):
			continue
		if tool == "roadblock" and not int(tile[4]):
			continue
		if city.core.query("preview %s %d %d 0" % [tool, point.x, point.y]).get("valid", false):
			return point
	return Vector2i(99999, 99999)

func frame(city: Node3D, plan: Dictionary, yaw: float) -> void:
	var size := maxf(float(plan.w), float(plan.h))
	city.orbit.target = city.world_position(float(plan.x) + (float(plan.w) - 1.0) * .5, float(plan.y) + (float(plan.h) - 1.0) * .5, int(plan.altitude)) + Vector3.UP * .2
	city.orbit.distance = size * 1.5 + 5.0
	city.orbit.yaw = yaw
	city.orbit.pitch = 42.0
	city.orbit.refresh()

func build_and_capture(city: Node3D) -> void:
	city.ui_layer.visible = true
	var built_count := 0
	var taken := 0
	for tool in TOOLS:
		city.core.query("test_allow " + tool)
		city.refresh_catalog()
		var at := site(city, tool)
		if at.x == 99999:
			print("MENU_REST_REVIEW no site for ", tool)
			continue
		var plan: Dictionary = city.core.query("preview %s %d %d 0" % [tool, at.x, at.y])
		# The placement ghost first, with the pointer resting on the site.
		frame(city, plan, 45.0)
		city.set_tool(tool)
		city.set_process(false)
		city.orientation = 0
		city.picked = at
		city.placement_key = ""
		city.refresh_placement()
		await city.get_tree().create_timer(.8).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-ghost-%s.png" % tool)
		await city.capture()
		taken += 1
		city.set_process(true)
		city.set_tool("select")
		var built: Dictionary = city.core.query("build %s %d %d 0" % [tool, at.x, at.y])
		if built.has("protocol"):
			city.receive_state(built)
		print("MENU_REST_REVIEW ", tool, " at ", at, " ", plan.w, "x", plan.h, " ", built.get("error", "built"))
		if built.has("error"):
			continue
		built_count += 1
		await city.get_tree().create_timer(1.2).timeout
		for yaw in [45.0, 225.0]:
			frame(city, plan, yaw)
			await city.get_tree().create_timer(.6).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-build-%s-%d.png" % [tool, int(yaw)])
			await city.capture()
			taken += 1
	print("MENU_REST_REVIEW ", "PASS " if built_count == TOOLS.size() else "FAIL ", "built=", built_count, " captures=", taken)
	city.get_tree().quit(0 if built_count == TOOLS.size() else 1)

func capture_city_window(city: Node3D) -> void:
	city.ui_layer.visible = true
	city.game_action("city")
	await city.get_tree().create_timer(.8).timeout
	var dialogs: Array = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.title == city.tr("City"))
	var taken := 0
	if dialogs.size() == 1:
		for page in ["overview", "employment", "administration", "military"]:
			dialogs[0].show_page(page)
			await city.get_tree().create_timer(.6).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-city-%s-%s.png" % [city.language, page])
			await city.capture()
			taken += 1
	print("MENU_REST_REVIEW ", "PASS " if taken == 4 else "FAIL ", "city pages=", taken)
	city.get_tree().quit(0 if taken == 4 else 1)

func shoot(city: Node3D, name: String, at: Vector2, altitude: int, distance: float, yaw: float, pitch := 38.0) -> void:
	city.orbit.target = city.world_position(at.x, at.y, altitude) + Vector3.UP * .2
	city.orbit.distance = distance
	city.orbit.yaw = yaw
	city.orbit.pitch = pitch
	city.orbit.refresh()
	await city.get_tree().create_timer(.8).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-naval-%s.png" % name)
	await city.capture()

func capture_naval(city: Node3D) -> void:
	city.ui_layer.visible = false
	var taken := 0
	city.core.query("test_allow hippodrome")
	# The wharf and its trireme.
	var wharf := site(city, "trireme_wharf")
	if wharf.x != 99999:
		city.receive_state(city.core.query("build trireme_wharf %d %d 0" % [wharf.x, wharf.y]))
		city.core.query("set_priority 7 5")
		city.core.simulation.replay(200, 7)
		var launched: Dictionary = city.core.query("test_trireme %d %d" % [wharf.x + 1, wharf.y + 1])
		if launched.has("protocol"):
			city.receive_state(launched)
		await city.get_tree().create_timer(1.0).timeout
		var ships: Array = launched.get("walkers", []).filter(func(w): return w.asset == "trireme")
		print("MENU_REST_REVIEW trireme ", ships.size())
		if not ships.is_empty():
			await shoot(city, "trireme", Vector2(float(ships[0].x) - .5, float(ships[0].y) - .5), 0, 7.0, 45.0)
			await shoot(city, "trireme-side", Vector2(float(ships[0].x) - .5, float(ships[0].y) - .5), 0, 6.0, 135.0, 25.0)
			taken += 2
	# The race.
	var square := Vector2i(99999, 99999)
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		if not int(tile[5]) or int(tile[4]):
			continue
		var fits := true
		for corner in [Vector2i(0, 0), Vector2i(4, 0), Vector2i(4, 4), Vector2i(0, 4)]:
			fits = fits and city.core.query("preview hippodrome %d %d 0" % [point.x + corner.x, point.y + corner.y]).get("valid", false)
		if fits:
			square = point
			break
	if square.x != 99999:
		for step in [[Vector2i(0, 0), "hippodrome_7"], [Vector2i(4, 0), "hippodrome_1"], [Vector2i(4, 4), "hippodrome_3"], [Vector2i(0, 4), "hippodrome_5"]]:
			for turn in 8:
				var preview: Dictionary = city.core.query("preview hippodrome %d %d %d" % [square.x + step[0].x, square.y + step[0].y, turn])
				if preview.get("valid", false) and preview.asset == step[1]:
					city.receive_state(city.core.query("build hippodrome %d %d %d" % [square.x + step[0].x, square.y + step[0].y, turn]))
					break
		city.core.simulation.replay(4, 7)
		var racing: Dictionary = city.core.query("test_race")
		if racing.has("protocol"):
			city.receive_state(racing)
		# The other new models stand on open ground beside the track.
		var lineup := ["walker_greekchariot", "enemy_boat", "walker_silverminer", "walker_orichalcminer"]
		for index in lineup.size():
			var node: Node3D = city.model(lineup[index])
			if node != null:
				city.world.add_child(node)
				node.position = city.world_position(square.x + 10 + index * 2.5, square.y + 2, 0)
				node.rotation.y = deg_to_rad(-135.0)
		city.core.query("pause 0")
		for step in 16:
			await city.get_tree().create_timer(.25).timeout
			var running: Dictionary = city.core.simulation.snapshot(false)
			city.receive_state(running)
		print("MENU_REST_REVIEW race ", racing.get("walkers", []).filter(func(w): return str(w.asset).begins_with("walker_racechariot")).size())
		await shoot(city, "race", Vector2(square.x + 3.5, square.y + 3.5), 0, 12.0, 45.0)
		await shoot(city, "race-close", Vector2(square.x + 3.5, square.y + 3.5), 0, 7.0, 200.0, 30.0)
		await shoot(city, "race-top", Vector2(square.x + 3.5, square.y + 3.5), 0, 11.0, 45.0, 75.0)
		await shoot(city, "lineup", Vector2(square.x + 13.5, square.y + 2), 0, 9.0, 45.0, 30.0)
		taken += 3
	print("MENU_REST_REVIEW ", "PASS " if taken == 5 else "FAIL ", "naval captures=", taken)
	city.get_tree().quit(0 if taken == 5 else 1)

func capture_cities(city: Node3D) -> void:
	city.ui_layer.visible = true
	city.core.query("pause 1")
	var listing: Dictionary = city.core.query("cities")
	var sale: Array = listing.get("cities", []).filter(func(c): return c.owner == "unowned")
	var mine: Array = listing.get("cities", []).filter(func(c): return c.owner == "player")
	var taken := 0
	if not sale.is_empty() and not mine.is_empty():
		city.jump_to_cell(Vector2(int(sale[0].centre[0]), int(sale[0].centre[1])))
		await city.get_tree().create_timer(1.6).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-cities-offer.png")
		await city.capture()
		taken += 1
		print("MENU_REST_REVIEW offer visible=", city.city_switch.banner.visible, " text=", city.city_switch.banner_text.text)
		city.city_switch.buy_button.pressed.emit()
		await city.get_tree().create_timer(1.2).timeout
		print("MENU_REST_REVIEW bought header=", city.hud.get_node("%CityName").text, " menu=", city.city_switch.menu.visible, " hint=", city.hint.text)
		city.city_switch.menu.show_popup()
		await city.get_tree().create_timer(.6).timeout
		city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-cities-menu.png")
		await city.capture()
		taken += 1
		city.city_switch.menu.get_popup().hide()
		city.city_switch.go_to(int(mine[0].id))
		await city.get_tree().create_timer(1.6).timeout
		print("MENU_REST_REVIEW back header=", city.hud.get_node("%CityName").text)
		city.capture_path = ProjectSettings.globalize_path("res://captures/menu-rest-cities-back.png")
		await city.capture()
		taken += 1
	print("MENU_REST_REVIEW ", "PASS " if taken == 3 else "FAIL ", "cities captures=", taken)
	city.get_tree().quit(0 if taken == 3 else 1)

const ANIMATED := ["armory", "chariot_factory", "college", "corral", "dairy", "drama_school", "mint", "podium", "theater", "stadium", "horse_ranch", "urchin_quay"]

func capture_animation(city: Node3D) -> void:
	city.ui_layer.visible = false
	var taken := 0
	city.core.query("speed 1")
	city.core.query("pause 0")
	# The trireme, sent across the water and caught twice as it rows.
	var wharf := site(city, "trireme_wharf")
	if wharf.x != 99999:
		city.receive_state(city.core.query("build trireme_wharf %d %d 0" % [wharf.x, wharf.y]))
		city.core.query("set_priority 7 5")
		city.core.simulation.replay(200, 7)
		var launched: Dictionary = city.core.query("test_trireme %d %d" % [wharf.x + 1, wharf.y + 1])
		if launched.has("protocol"):
			city.receive_state(launched)
		var ships: Array = launched.get("walkers", []).filter(func(w): return w.asset == "trireme")
		if not ships.is_empty():
			var start := Vector2(float(ships[0].x), float(ships[0].y))
			var target := Vector2i(99999, 99999)
			for point in city.tiles:
				var tile: Array = city.tiles[point]
				var away := Vector2(point).distance_to(start)
				if int(tile[3]) & 4 and not int(tile[4]) and away > 8.0 and away < 16.0:
					target = point
					break
			city.core.query("trireme_move %d %d %d" % [target.x, target.y, int(ships[0].id)])
			for moment in 2:
				for step in 10:
					await city.get_tree().create_timer(.12).timeout
				var entry: Dictionary = city.walkers.get(int(ships[0].id), {})
				if not entry.is_empty():
					var at: Vector2 = city.tile_coordinates(entry.node.position)
					await shoot(city, "anim-trireme-%d" % moment, at, 0, 5.0, 60.0 + moment * 5.0, 30.0)
					taken += 1
	# The rioters, standing on open ground beside the camera's target.
	var ground := site(city, "park")
	if ground.x != 99999:
		for index in 2:
			var node: Node3D = city.model(["walker_disgruntled", "walker_elitecitizen"][index])
			if node != null:
				city.world.add_child(node)
				node.position = city.world_position(ground.x + index * .8, ground.y, 0)
				node.rotation.y = deg_to_rad(-135.0)
		await shoot(city, "anim-rioters", Vector2(ground.x + .4, ground.y), 0, 2.6, 45.0, 18.0)
		taken += 1
	# Three of the newly animated buildings, founded beside a road and run until they are staffed.
	city.core.query("set_priority 5 5")
	city.core.query("set_priority 7 5")
	city.core.query("set_priority 0 5")
	var founded := 0
	for tool in ["college", "armory", "dairy", "podium", "drama_school", "corral", "mint"]:
		if founded >= 3:
			break
		city.core.query("test_allow " + tool)
		var at := road_site(city, tool)
		if at.x == 99999:
			continue
		var built: Dictionary = city.core.query("build %s %d %d 0" % [tool, at.x, at.y])
		if built.has("protocol"):
			city.receive_state(built)
			founded += 1
	city.core.simulation.replay(900, 7)
	city.receive_state(city.core.simulation.snapshot(true))
	await city.get_tree().create_timer(1.0).timeout
	# The newly animated buildings the city has, at work.
	var shown := 0
	for building in city.state.get("buildings", []):
		if not str(building.asset) in ANIMATED or shown >= 4:
			continue
		print("MENU_REST_REVIEW building ", building.asset, " working=", building.get("working", "?"), " workers=", building.get("workers", "?"))
		var middle := Vector2(float(building.x) + float(building.w) * .5 - .5, float(building.y) + float(building.h) * .5 - .5)
		for moment in 2:
			await shoot(city, "anim-%s-%d" % [building.asset, moment], middle, int(building.altitude), maxf(float(building.w), float(building.h)) * 1.4 + 3.0, 45.0, 35.0)
			await city.get_tree().create_timer(.7).timeout
		taken += 1
		shown += 1
	print("MENU_REST_REVIEW ", "PASS " if taken >= 3 else "FAIL ", "anim captures=", taken, " buildings=", shown)
	city.get_tree().quit(0 if taken >= 3 else 1)

# A free site whose footprint touches a road (so that workers come).
func road_site(city: Node3D, tool: String) -> Vector2i:
	var size := Vector2i(2, 2)
	for item in city.core.query("buildable").buildings:
		if str(item.name) == tool:
			size = Vector2i(int(item.w), int(item.h))
	for point in city.tiles:
		var tile: Array = city.tiles[point]
		if not int(tile[5]) or int(tile[4]):
			continue
		var touches := false
		for dx in range(-1, size.x + 1):
			for dy in [-1, size.y]:
				var near: Array = city.tiles.get(point + Vector2i(dx, dy), [])
				touches = touches or (not near.is_empty() and int(near[4]))
		for dy in range(0, size.y):
			for dx in [-1, size.x]:
				var near: Array = city.tiles.get(point + Vector2i(dx, dy), [])
				touches = touches or (not near.is_empty() and int(near[4]))
		if touches and city.core.query("preview %s %d %d 0" % [tool, point.x, point.y]).get("valid", false):
			return point
	return Vector2i(99999, 99999)
