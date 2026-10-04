extends RefCounted

# Captures the inspection of a finished sanctuary in a city with a rival on the board (The Sands of Betrayal, new game; a copy in memory: nothing
# is saved): the "God Invasion" button and its wait bar as they first show, the answer after asking, and the refusal of a second request.
# The first pass opens the adventure, founds and finishes the sanctuary with the validators' commands and reloads the city scene with it; the
# second pass (the scene sees the marker `ezeus_attack_site`) selects the sanctuary and takes the pictures. Files: captures/attack-<name>-*.png.

func shot(city: Node3D, name: String, to_end := false) -> void:
	DisplayServer.window_move_to_foreground()
	await city.get_tree().create_timer(.7).timeout
	if to_end:
		# The inspection scrolls when a language's longer words fill the panel: show its last lines.
		var scroll: ScrollContainer = city.hud.get_node("%InspectorScroll")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await city.get_tree().process_frame
	city.capture_path = ProjectSettings.globalize_path("res://captures/attack-%s.png" % name)
	await city.capture()

func site_for(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		if core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

# Opens the adventure, founds a finished sanctuary of Dionysus beside a road and hands the opened game to the city scene on its reload.
func prepare(city: Node3D, phase: String) -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	# One city at a time lives in the process: the designated city this scene opened is closed (it is never saved) before another is opened.
	city.core.simulation.close_city()
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(ProjectSettings.globalize_path("res://captures"))
	var listed: Array = core.adventures(engine, "en").adventures.filter(func(item): return str(item.title) == "The Sands of Betrayal")
	var state: Dictionary = core.open_adventure(engine, str(listed[0].kind), str(listed[0].ref), city.language if city.language in ["en", "ru"] else "en")
	core.enable_test_commands()
	core.command("test_allow temple_dionysus")
	var warehouse := site_for(core, state, "warehouse")
	core.command("build warehouse %d %d 0" % [warehouse.x, warehouse.y])
	core.command("test_stock 32768 60")
	state = core.snapshot(true)
	var site := site_for(core, state, "temple_dionysus")
	var plan: Dictionary = core.command("preview temple_dionysus %d %d 0" % [site.x, site.y])
	for dx in [-1, int(plan.w)]:
		var at := Vector2i(int(plan.x) + dx, int(plan.y) + int(plan.h) / 2)
		if core.command("preview road %d %d 0" % [at.x, at.y]).get("valid", false):
			core.command("build road %d %d 0" % [at.x, at.y])
			break
	core.command("build temple_dionysus %d %d 0" % [site.x, site.y])
	core.command("test_complete %d %d" % [site.x, site.y])
	Engine.set_meta("ezeus_simulation", core)
	Engine.set_meta("ezeus_attack_site", site)
	city.get_tree().reload_current_scene.call_deferred()

func run(city: Node3D, phase: String) -> void:
	if not Engine.has_meta("ezeus_attack_site"):
		prepare(city, phase)
		return
	var site: Vector2i = Engine.get_meta("ezeus_attack_site")
	city.core.query("pause 1")
	city.ui_layer.visible = true
	city.orbit.enabled = false
	var first: Dictionary = city.core.query("inspect %d %d" % [site.x, site.y])
	var foot: Array = first.footprint
	city.orbit.target = city.world_position(foot[0] + (foot[2] - 1) * .5, foot[1] + (foot[3] - 1) * .5, int(first.altitude)) + Vector3.UP * .3
	city.orbit.distance = 30.0
	city.orbit.yaw = 35.0
	city.orbit.pitch = 42.0
	city.inspected = site
	city.refresh_inspection()
	await shot(city, phase + "-offer")
	var inspection: Dictionary = city.core.query("inspect %d %d" % [site.x, site.y])
	var targets: Array = inspection.monument.attack.targets
	var asked: Dictionary = city.core.query("sanctuary_attack %d %d %d %d" % [site.x, site.y, int(inspection.target_token), int(targets[0].city)])
	city.refresh_inspection()
	city.inspector_controls.show_attack_answer(asked.attack_answer)
	await shot(city, phase + "-granted", true)
	inspection = city.core.query("inspect %d %d" % [site.x, site.y])
	asked = city.core.query("sanctuary_attack %d %d %d %d" % [site.x, site.y, int(inspection.target_token), int(targets[0].city)])
	city.refresh_inspection()
	city.inspector_controls.show_attack_answer(asked.attack_answer)
	await shot(city, phase + "-refused", true)
	Engine.remove_meta("ezeus_attack_site")
	print("ATTACK_REVIEW PASS site=", site)
	city.get_tree().quit(0)
