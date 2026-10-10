extends SceneTree
# Windowed look at the hazard alert buttons in the rail, on the designated city with raised test events (disposable review).
var city: Node3D

func frames(count := 8) -> void:
	for frame in count: await process_frame

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func shoot(name: String) -> void:
	await frames(12); await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var scale: Vector2 = Vector2(image.get_size()) / city.hud.size
	var rail: Rect2 = city.hud.get_node("%EventRail").get_global_rect()
	var region := Rect2i(Vector2(city.hud.size.x - 420, 0) * scale, Vector2(420, 420) * scale)
	image.get_region(region).save_png("res://captures/hazard-alerts-" + name + "-" + city.language + ".png")
	print("HAZARD_CAPTURE ", name, " rail=", rail)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1"); city.orbit.enabled = false
	city.core.simulation.enable_test_commands()
	DisplayServer.window_set_size(Vector2i(1600, 1000)); await frames()
	for command in ["test_raise fire", "test_raise fire", "test_raise collapse", "test_raise earthquake", "test_raise tidalWave", "test_raise plague", "test_raise invasion", "test_raise godInvasion god zeus", "test_raise godVisit god athena", "test_raise heroArrival hero hercules", "test_raise armyReturns", "test_raise sinkLand", "test_raise invasion24", "test_raise monsterInvasion24 monster hydra", "test_raise riskWarning"]:
		var reply: Dictionary = city.core.query(command)
		city.hazard_rail.observe(reply.get("alerts", []))
	city.hazard_rail.set_persistent("plague", 4, Vector2i(10, 10))
	await shoot("all")
	city.hazard_rail._dismiss("quake"); city.hazard_rail._dismiss("flood"); city.hazard_rail._dismiss("plague")
	await shoot("some")
	print("HAZARD_REVIEW_DONE"); quit()
