extends SceneTree
# Thrown arrows, spears and rocks (scripts/thrown_shots.gd) and the soot on a burning building (scripts/building_fires.gd), on the
# designated city in memory only (disposable preferences). Missiles are thrown through the validators' `test_shot`, which makes the
# engine's own missile objects, so they reach the front end through the real observer and snapshot; a house is set on fire with
# `test_fire` and the soot is counted, grows darker, and goes with the fire.
var city: Node3D
var checks := 0
var okay := true

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("MISSILE_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count := 8) -> void:
	for frame in count: await process_frame

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func look_at_cell(cell: Vector2, distance: float, yaw := 35.0) -> void:
	var key := Vector2i(roundi(cell.x), roundi(cell.y))
	var altitude := float(city.tiles[key][2]) if city.tiles.has(key) else 0.0
	city.orbit.target = city.world_position(cell.x, cell.y, altitude)
	city.orbit.distance = distance
	city.orbit.yaw = yaw
	city.orbit.refresh()

func shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/missiles-" + name + "-" + city.language + ".png")

func unblock() -> void:
	if not city.state.get("blocked", false):
		return
	for event in city.state.get("events", []):
		var actions: Array = event.get("actions", [])
		if not actions.is_empty() and int(actions[actions.size() - 1].choice) != -2:
			city.core.query("event %d %d" % [int(event.id), int(actions[actions.size() - 1].choice)])
	city.core.query("pause 0")

func wait_running(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		unblock()
		await create_timer(.1).timeout
		left -= .1

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.orbit.enabled = false
	city.core.simulation.enable_test_commands()
	DisplayServer.window_set_size(Vector2i(1600, 1000)); await frames()
	city.core.query("pause 0")
	var houses: Array = city.state.buildings.filter(func(b): return str(b.asset).begins_with("common_house"))
	var origin := Vector2i(int(houses[0].x), int(houses[0].y))
	var open: Vector2i = origin + Vector2i(0, 0)
	look_at_cell(Vector2(origin.x + 4, origin.y + 4), 12)
	# Missiles: a volley of each kind across a few tiles.
	var before: int = city.thrown_shots.launches
	for index in 6:
		city.core.query("test_shot arrow %d %d %d %d" % [origin.x, origin.y + index, origin.x + 8, origin.y + index + 2])
		city.core.query("test_shot spear %d %d %d %d" % [origin.x, origin.y + index, origin.x + 8, origin.y + index])
		city.core.query("test_shot rock %d %d %d %d" % [origin.x, origin.y + index, origin.x + 8, origin.y + index - 2])
	var flying := 0
	var kinds := {}
	for step in 14:
		await wait_running(.04)
		flying = maxi(flying, city.thrown_shots.drawn)
		for shot in city.thrown_shots.shots:
			kinds[shot.kind] = true
		if step == 4:
			await shoot("volley")
	check(city.thrown_shots.launches - before >= 18, "the engine's launches arrive as shots (%d)" % (city.thrown_shots.launches - before))
	check(flying > 0, "arrows, spears and rocks are drawn in flight (%d at once)" % flying)
	check(kinds.has("arrow") and kinds.has("spear") and kinds.has("rock"), "all three kinds arrive: %s" % str(kinds.keys()))
	# Paused, they hang in the air; resumed, they go on.
	city.core.query("test_shot arrow %d %d %d %d" % [origin.x, origin.y, origin.x + 14, origin.y])
	await wait_running(.1)
	city.core.query("pause 1")
	await wait_running(.01)
	var held_at: float = city.thrown_shots.clock
	await create_timer(.5).timeout
	check(is_equal_approx(city.thrown_shots.clock, held_at), "a paused city holds its missiles in the air")
	city.core.query("pause 0")
	var started: float = city.thrown_shots.clock
	for step in 200:
		await wait_running(.1)
		if city.thrown_shots.clock > started + 1500.0:
			break
	var sample: Dictionary = city.thrown_shots.shots[0] if not city.thrown_shots.shots.is_empty() else {}
	print("MISSILE_INFO clock=", city.thrown_shots.clock, " running=", city.thrown_shots.running, " blocked=", city.state.get("blocked"), " first=", sample.get("born", "-"), " duration=", sample.get("duration", "-"), " kind=", sample.get("kind", "-"))
	check(city.thrown_shots.shots.size() < 6, "missiles that have landed are gone (%d left)" % city.thrown_shots.shots.size())

	# Soot.
	var house: Dictionary = houses[1]
	look_at_cell(Vector2(house.x, house.y), 10, 40)
	await frames(20)
	city.core.query("test_fire %d %d" % [house.x, house.y])
	await wait_running(1.5)
	var key := "%d,%d" % [house.x, house.y]
	check(city.building_fires.chars.has(key) and not city.building_fires.chars[key].nodes.is_empty(), "a burning house is covered in soot")
	await shoot("soot-early")
	var early: float = 0.0
	if city.building_fires.chars.has(key):
		early = float(city.building_fires.chars[key].material.get_shader_parameter("amount"))
	# Let the fire burn: the soot thickens.
	city.building_fires.clock += 15.0
	await frames(5)
	var later: float = float(city.building_fires.chars[key].material.get_shader_parameter("amount")) if city.building_fires.chars.has(key) else 0.0
	check(later > early + .1, "the soot darkens as the fire burns (%.2f to %.2f)" % [early, later])
	await shoot("soot-late")
	print("MISSILE_CHECK ", "PASS" if okay else "FAIL", " ", checks, " checks")
	print("MISSILE_REVIEW_DONE")
	quit(0 if okay else 1)
