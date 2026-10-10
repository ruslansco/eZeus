extends SceneTree
# The plague over a sick house, a blessed and a cursed building (scripts/building_auras.gd), on the designated city in memory only
# (disposable preferences): marks three buildings through the validators' `test_aura`, counts the auras, captures them, clears them.
var city: Node3D
var checks := 0
var okay := true

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("AURA_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count := 8) -> void:
	for frame in count: await process_frame

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func look_at_building(building: Dictionary, name: String) -> void:
	city.orbit.target = city.world_position(building.x + (building.w - 1) * .5, building.y + (building.h - 1) * .5, building.altitude)
	city.orbit.distance = float(OS.get_environment("AURA_DISTANCE")) if OS.has_environment("AURA_DISTANCE") else 13.0
	city.orbit.yaw = 35
	city.orbit.refresh()
	await frames(20); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/auras-" + name + "-" + city.language + ".png")

# Through the live pipeline (the command queue and the delta snapshots the game runs on), as a god's blessing would arrive.
func mark(building: Dictionary, what: String) -> void:
	city.core.send("test_aura %d %d %s" % [building.x, building.y, what])
	await frames(30)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1"); city.orbit.enabled = false
	city.core.simulation.enable_test_commands()
	DisplayServer.window_set_size(Vector2i(1600, 1000)); await frames()
	var houses: Array = city.state.buildings.filter(func(b): return str(b.asset).begins_with("common_house"))
	var others: Array = city.state.buildings.filter(func(b): return b.asset == "warehouse" or b.asset == "olive_press")
	check(houses.size() >= 2 and others.size() >= 2, "the city has houses and other buildings to mark")
	var sick: Dictionary = houses[0]
	var blessed: Dictionary = others[0]
	var cursed: Dictionary = others[1]
	var baseline: int = city.building_auras.count()
	await mark(sick, "plague")
	await frames(10)
	check(city.building_auras.count() >= 1 and city.building_auras.auras.has("%d,%d,0" % [sick.x, sick.y]), "a sick house gets the plague effect")
	var plague_snapshot: Dictionary = city.core.simulation.snapshot(true)
	check(int(plague_snapshot.plague.houses) >= 1, "the snapshot counts the sick houses")
	await look_at_building(sick, "plague")
	await mark(blessed, "blessed")
	await look_at_building(blessed, "blessed")
	check(city.building_auras.auras.has("%d,%d,1" % [blessed.x, blessed.y]), "a blessed building glows gold")
	await mark(cursed, "cursed")
	await look_at_building(cursed, "cursed")
	check(city.building_auras.auras.has("%d,%d,2" % [cursed.x, cursed.y]), "a cursed building is dark")
	await mark(sick, "clear")
	await mark(blessed, "clear")
	await mark(cursed, "clear")
	await frames(10)
	check(city.building_auras.count() == baseline, "clearing the marks takes every effect we added away")
	print("AURA_CHECK ", "PASS" if okay else "FAIL", " ", checks, " checks")
	print("AURA_REVIEW_DONE")
	quit(0 if okay else 1)
