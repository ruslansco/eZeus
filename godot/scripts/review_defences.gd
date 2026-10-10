extends SceneTree
const Perch = preload("res://scripts/defence_perch.gd")
var city: Node3D
var okay := true
var checks := 0
var fixtures: Array = []
var actors: Array = []
var guard: Dictionary
var tower: Dictionary

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1; okay = okay and value
	print("DEFENCE_REVIEW_CHECK ", "PASS " if value else "FAIL ", message)

func prop(asset: String, x: float, y: float, altitude: float, facing := 0) -> void:
	var node: Node3D = city.model(asset)
	city.world.add_child(node); fixtures.append(node)
	node.position = city.world_position(x, y, altitude)
	node.rotation.y = facing * PI / 2.0

func capture(name: String, target: Vector3, yaw: float, distance: float) -> void:
	city.orbit.target = target; city.orbit.distance = distance
	city.orbit.pitch = 36; city.orbit.yaw = yaw; city.orbit.refresh()
	for frame in 12: await process_frame
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png("res://captures/defences-%s.png" % name)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 70: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
	city.orbit.enabled = false; city.ui_layer.visible = false
	DisplayServer.window_move_to_foreground()
	var original: Dictionary = city.core.simulation.snapshot(true)
	var free := {}
	for tile in original.tiles:
		if int(tile[5]): free[Vector2i(int(tile[0]), int(tile[1]))] = tile
	var base := Vector2i(-1, -1)
	# Render-only gallery on a clear, level portion of the designated board.
	for cell in free:
		var clear := true
		for dx in range(-8, 9):
			for dy in range(-2, 5):
				var neighbor: Array = free.get(cell + Vector2i(dx, dy), [])
				clear = clear and not neighbor.is_empty()
				if not neighbor.is_empty(): clear = clear and int(neighbor[2]) == int(free[cell][2]) and not (int(neighbor[3]) & 16)
		if clear: base = cell; break
	check(base.x >= 0, "a clear level gallery site exists")
	if base.x < 0: quit(1); return
	var altitude := float(free[base][2])
	prop("gatehouse", base.x, base.y, altitude)
	# Readable paving for the gallery passage; actual cities use native road terrain.
	for dy in range(-2, 3): prop("palace_tile_plain", base.x, base.y + dy, altitude)
	for x in [3, 4, 5, 6, -3, -4, -5, -6]: prop("wall_3", base.x + x, base.y, altitude)
	prop("tower", base.x + 7.5, base.y + .5, altitude)
	prop("tower", base.x - 7.5, base.y + .5, altitude)
	prop("wall_12", base.x + 7, base.y + 2, altitude)
	prop("wall_12", base.x + 7, base.y + 3, altitude)
	# Deliberately extreme native corner position reproduces the user's overflow.
	tower = {"asset": "tower", "x": base.x + 7, "y": base.y, "w": 2, "h": 2, "altitude": altitude}
	var wall := {"asset": "wall_3", "x": base.x - 4, "y": base.y, "w": 1, "h": 1, "altitude": altitude}
	city.defence_perch.refresh([tower, wall])
	guard = {"id": -7001, "asset": "walker_archer", "type": -1, "x": tower.x + .01, "y": tower.y + 1.99, "altitude": altitude, "lift": 2.57, "action": 1, "orientation": 0}
	var live_walkers: Array = city.state.walkers
	var wall_guard := {"id": -7002, "asset": "walker_archer", "type": -1, "x": wall.x + .5, "y": wall.y + .5, "altitude": altitude, "lift": .8, "action": 1, "orientation": 0}
	city.state.walkers = [guard, wall_guard]; city.update_walkers()
	var entry: Dictionary = city.walkers[-7001]; actors.append(entry.node)
	var wall_entry: Dictionary = city.walkers[-7002]; actors.append(wall_entry.node)
	city._process(.1)
	var center: Vector3 = city.world_position(tower.x + .5, tower.y + .5, altitude)
	check(absf(entry.node.position.x - center.x) <= .58001 and absf(entry.node.position.z - center.z) <= .58001, "actual city update keeps extreme guard feet inside the tower")
	check(absf(entry.node.position.y - center.y - 3.05) < .0001 and entry.lane == Vector3.ZERO, "actual guard uses model roof height and no road lane offset")
	var wall_center: Vector3 = city.world_position(wall.x, wall.y, altitude)
	check(absf(wall_entry.node.position.y - wall_center.y - 2.0) < .0001 and wall_entry.lane == Vector3.ZERO, "actual wall guard stands on the raised two-tile walk")
	# Another guard provides scale on the opposite tower.
	for setup in [[-7.5, .5, 3.05]]:
		var actor: Node3D = city.model("walker_archer"); city.world.add_child(actor); actors.append(actor)
		actor.position = city.world_position(base.x + setup[0], base.y + setup[1], altitude) + Vector3.UP * setup[2]
		actor.scale = Vector3.ONE * 1.12
	await capture("ensemble", city.world_position(base.x, base.y, altitude) + Vector3.UP * 1.0, 20, 24)
	await capture("gate", city.world_position(base.x, base.y, altitude) + Vector3.UP * 1.6, 10, 9)
	await capture("gate-back", city.world_position(base.x, base.y, altitude) + Vector3.UP * 1.6, 190, 9)
	await capture("tower-guard", center + Vector3.UP * 2.1, 35, 6)
	var stays_inside := true
	for step in 120:
		var phase := float(step) / 30.0
		var points := [Vector2(.01, .01), Vector2(1.99, .01), Vector2(1.99, 1.99), Vector2(.01, 1.99), Vector2(.01, .01)]
		var point: Vector2 = points[mini(int(phase), 3)].lerp(points[mini(int(phase) + 1, 4)], fmod(phase, 1.0))
		guard.x = tower.x + point.x; guard.y = tower.y + point.y
		city.update_walkers(); city._process(.1)
		stays_inside = stays_inside and absf(entry.node.position.x - center.x) <= .58001 and absf(entry.node.position.z - center.z) <= .58001 and absf(entry.node.position.y - center.y - 3.05) < .0001
		await process_frame
	check(stays_inside, "120 moving guard samples stay on the fighting platform")
	city.state.walkers = live_walkers
	city.walkers.clear()
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(original.tiles == after.tiles and original.buildings == after.buildings and original.walkers == after.walkers and original.money == after.money and original.time == after.time, "render-only review leaves every native city observation unchanged")
	for node in fixtures + actors:
		if is_instance_valid(node): node.queue_free()
	print("DEFENCE_REVIEW ", "PASS " if okay else "FAIL ", checks, " checks")
	city.queue_free(); await process_frame; await process_frame
	quit(0 if okay else 1)
