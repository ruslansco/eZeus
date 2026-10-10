extends SceneTree
# Owned native outbreak review. Only the infection is a test fixture; recovery
# comes from ordinary native ticks and real infirmary walkers, including reload.
var city: Node
var language := "en"
var okay := true
var checks := 0

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.trim_prefix("--lang=")
	Engine.set_meta("ezeus_language", language)
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("PLAGUE_REVIEW_CHECK ", "PASS " if value else "FAIL ", label)

func frames(n := 5) -> void:
	for i in n: await process_frame

func infected(state: Dictionary, house: Dictionary) -> bool:
	return state.get("auras", []).any(func(a): return int(a[0]) == int(house.x) and int(a[1]) == int(house.y) and int(a[5]) == 0)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/plague-healing-%s-%s.png" % [language, label])

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	city = load("res://main.tscn").instantiate(); root.add_child(city); current_scene = city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty(): await process_frame
	city.core.set_process(false)
	var core: RefCounted = city.core.simulation
	core.enable_test_commands()
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	core.command("set_priority 3 5")
	core.command("speed 0"); core.command("pause 0")
	for tick in 1000: core.advance(.05)
	core.command("pause 1")
	var state: Dictionary = core.snapshot(true)
	# The designated fixture asks for sculpture during preparation. Use its
	# original Postpone callback only in this disposable review, so patrols and
	# the infected checkpoint can continue; leave unrelated decisions alone.
	for event in state.get("events", []):
		if event.get("kind", "") == "generalRequestAllyInitial" and event.get("actions", []).any(func(a): return int(a.choice) == 1):
			core.command("event %d 1" % int(event.id))
	state = core.snapshot(true); city.receive_state(state)
	check(not state.get("blocked", true), "fixture's known request uses its native Postpone callback before the recovery test")
	var healers: Array = state.walkers.filter(func(w): return str(w.asset) == "physician")
	check(not healers.is_empty(), "existing infirmaries spawn actual native healers")
	var house := {}; var distance := INF
	for building in state.buildings:
		if not str(building.asset).begins_with("common_house_"): continue
		var point := Vector2(float(building.x) + .5, float(building.y) + .5)
		for healer in healers:
			var d := point.distance_to(Vector2(float(healer.x), float(healer.y)))
			if d >= distance: continue
			var info: Dictionary = core.command("house_card %d %d" % [building.x, building.y])
			if int(info.get("people", 0)) > 0: house = building; distance = d
	check(not house.is_empty(), "inhabited house is on an existing healer's route")
	if house.is_empty(): core.close_city(); quit(1); return
	var sick: Dictionary = core.command("test_aura %d %d plague" % [house.x, house.y])
	city.receive_state(sick)
	check(infected(sick, house) and int(sick.plague.houses) > 0, "native outbreak appears in the snapshot with a house marker and plague count")
	var pause_time := int(sick.time)
	core.advance(.5)
	var paused: Dictionary = core.snapshot(true)
	check(int(paused.time) == pause_time and infected(paused, house), "pause holds the infection until an actual treatment visit")
	var saved: Dictionary = core.save_city("infected-healer-review")
	check(saved.has("saved"), "infected city writes only to the disposable save directory")
	if not saved.has("saved"): core.close_city(); quit(1); return
	var saved_path := str(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY")).path_join("infected-healer-review.ez")
	state = core.open_city(ProjectSettings.globalize_path("res://.."), saved_path, language)
	check(infected(state, house) and int(state.plague.houses) == int(sick.plague.houses), "existing saved infections restore their native outbreak membership")
	city.receive_state(state)
	city.orbit.target = city.world_position(float(house.x) + .5, float(house.y) + .5, 0)
	city.orbit.distance = 23.0; city.orbit.yaw = 35.0; city.orbit.pitch = 52.0
	city.orbit.enabled = false; city.orbit.snap_to_ground(); city.orbit.refresh()
	await frames(12)
	var aura_id := "%d,%d,0" % [house.x, house.y]
	check(city.building_auras.auras.has(aura_id) and city.hazard_rail.persistent.has("plague"), "actual city displays the infected house and live hazard count")
	await capture("infected")
	core.command("pause 0")
	var ticks := 0
	while ticks < 4000 and infected(state, house):
		for tick in 5: core.advance(.05); ticks += 1
		state = core.snapshot(true); city.receive_state(state)
		await process_frame
	core.command("pause 1")
	state = core.snapshot(true); city.receive_state(state)
	check(not infected(state, house), "ordinary infirmary patrol clears the loaded infected house")
	await frames(5)
	check(not city.building_auras.auras.has(aura_id), "the green house marker disappears after native recovery")
	check(int(state.plague.houses) < int(sick.plague.houses), "native plague count decreases after treatment")
	check(not city.hazard_rail.persistent.has("plague") if int(state.plague.houses) == 0 else int(city.hazard_rail.persistent.plague.count) == int(state.plague.houses), "hazard rail follows the remaining native outbreak without stale counts")
	await capture("treated")
	print("PLAGUE_REVIEW_RESULT ", JSON.stringify({"ticks": ticks, "house": house, "initial_infected": sick.plague.houses, "remaining": state.plague.houses}))
	core.close_city(); city.queue_free(); await frames(3)
	print("PLAGUE_REVIEW ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
