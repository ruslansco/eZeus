extends RefCounted

# Captures the rite on a sanctuary's altar in the designated city (a copy in memory: nothing is saved): the sheep, the bull and the goods, each
# twice a little apart so the priestess's clip and the braziers' flames can be compared, from three sides. Files: captures/rite-<name>-<kind>-<n>.png. `--rite-review=<name>`.
func shot(city: Node3D, name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await city.get_tree().create_timer(.5).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/rite-%s.png" % name)
	await city.capture()

func run(city: Node3D, phase: String) -> void:
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	city.ui_layer.visible = false
	city.orbit.enabled = false
	var simulation: RefCounted = city.core.simulation
	simulation.enable_test_commands()
	var initial: Dictionary = simulation.snapshot(true)
	var altar: Dictionary = {}
	# Any piece called `sanctuary_altar` may be a sanctuary's altar or a pyramid's: the core says which can take a rite.
	for building in initial.buildings:
		if str(building.asset) == "sanctuary_altar" and not simulation.command("test_sacrifice %d %d goods" % [int(building.x), int(building.y)]).has("error"):
			altar = building
			break
	if altar.is_empty():
		print("RITE_REVIEW FAIL no sanctuary altar in the city")
		city.get_tree().quit(1)
		return
	print("RITE_REVIEW altar ", altar)
	var centre := Vector2(float(altar.x) + altar.w * .5 - .5, float(altar.y) + altar.h * .5 - .5)
	city.orbit.target = city.world_position(centre.x, centre.y, int(altar.altitude)) + Vector3.UP * .5
	city.orbit.distance = 4.6
	var shots := 0
	for kind in ["sheep", "bull", "goods"]:
		var started: Dictionary = simulation.command("test_sacrifice %d %d %s" % [int(altar.x), int(altar.y), kind])
		print("RITE_REVIEW start ", kind, " ", started)
		city.receive_state(simulation.snapshot(false))
		await city.get_tree().process_frame
		await city.get_tree().process_frame
		print("RITE_REVIEW scene nodes ", kind, ": goods nodes ", city.world.find_children("SacrificeGoods", "Node3D", true, false).size(), ", rite walkers ", city.walkers.values().filter(func(e): return e.has("roll")).map(func(e): return str(e.asset)))
		for view in [[35.0, 38.0], [125.0, 30.0], [215.0, 38.0]]:
			city.orbit.yaw = view[0]
			city.orbit.pitch = view[1]
			city.orbit.refresh()
			for n in 2:
				city.receive_state(simulation.snapshot(false))
				await shot(city, "%s-%s-%d-%d" % [phase, kind, int(view[0]), n])
				shots += 1
	print("RITE_REVIEW PASS shots=", shots)
	city.get_tree().quit(0)
