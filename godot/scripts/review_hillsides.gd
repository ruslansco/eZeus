extends SceneTree
var city: Node3D
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")
func frames(count: int) -> void:
	for frame in count: await process_frame
func run() -> void:
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.set_process(false)
	city.orbit.enabled = false
	city.ui_layer.visible = false
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var before: Dictionary = city.core.simulation.snapshot(true)
	var focus := Vector2i(int(before.focus[0]), int(before.focus[1]))
	var subjects := []
	for walkable in [false,true]:
		var nearest := Vector2i.ZERO
		var distance := INF
		for cell in city.tiles:
			var tile: Array = city.tiles[cell]
			if not (int(tile[6]) & 1) or (int(tile[6]) & 8) or bool(int(tile[6]) & 2) != walkable: continue
			var score: float = Vector2(cell).distance_squared_to(Vector2(focus))
			if score < distance: nearest = cell; distance = score
		subjects.append(["ramp" if walkable else "cliff", nearest])
	city.orbit.pitch = 42
	for subject in subjects:
		var cell: Vector2i = subject[1]
		city.orbit.target = city.world_position(cell.x, cell.y, city.tiles[cell][2])
		city.orbit.distance = 14
		for angle in [45,225]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			for finish in [0,1]:
				city.terrain_style.ground_material.set_shader_parameter("hillside_finish",float(finish))
				await frames(24)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://captures/hillside-%s-%s-%d.png" % ["after" if finish else "before", subject[0], angle])
	var scenery: Node3D = city.horizon.surroundings
	var hill := Vector2.ZERO
	var nearest := INF
	for leaf in scenery.leaves:
		var point := Vector2(leaf.x + leaf.size * 0.5, leaf.y + leaf.size * 0.5)
		if scenery.height(point) < scenery.sea_level + 4.0: continue
		var gradient := Vector2(scenery.height(point + Vector2(2,0)) - scenery.height(point - Vector2(2,0)), scenery.height(point + Vector2(0,2)) - scenery.height(point - Vector2(0,2))) / 4.0
		if gradient.length() < 0.7: continue
		var score := point.distance_squared_to(Vector2(focus))
		if score < nearest: nearest = score; hill = point
	city.orbit.target = scenery.world(hill, scenery.height(hill))
	city.orbit.distance = 24
	city.orbit.pitch = 35
	for angle in [45,225]:
		city.orbit.yaw = angle
		city.orbit.refresh()
		for finish in [0,1]:
			scenery.land.material_override.set_shader_parameter("hillside_finish",float(finish))
			await frames(24)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://captures/hillside-%s-countryside-%d.png" % ["after" if finish else "before", angle])
	var after: Dictionary = city.core.simulation.snapshot(true)
	var intact: bool = before.tiles == after.tiles and before.buildings == after.buildings and before.walkers == after.walkers and before.time == after.time and before.money == after.money
	print("HILLSIDE_STATE ", "PASS" if intact else "FAIL", " native terrain/buildings/walkers/time/money unchanged")
	city.queue_free()
	await frames(8)
	city = null
	await frames(4)
	print("HILLSIDE_REVIEW ", "PASS" if intact else "FAIL", " matched views; native terrain/buildings/walkers/time/money unchanged")
	quit(0 if intact else 1)
