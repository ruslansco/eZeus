extends SceneTree
const Fixture = preload("res://scripts/monster_effects_fixture.gd")
var city: Node3D
var language := "en"
var kind := "hydra"
var checks := 0
var okay := true
var captures: Array = []

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1; okay = okay and value
	print("MONSTER_FX_REVIEW_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count := 4) -> void:
	for i in count:
		await process_frame

func show_state(core: RefCounted, state: Dictionary) -> void:
	city.receive_state(state)
	city.monster_effects.advance(.1)
	for entry in city.walkers.values():
		var delta: Vector3 = entry.to - entry.native_position
		entry.node.position = city.walker_surface_position(entry.to, entry.to_offset, not entry.waterborne)
		entry.native_position = entry.to
		var dt := .05 if state.get("running", false) else 0.0
		if delta.length_squared() > .00000001:
			entry.node.rotation.y = city.walker_heading(delta)
		elif preload("res://scripts/walker_combat.gd").fighting(entry):
			preload("res://scripts/walker_combat.gd").face(entry,dt)
		city.animate_walker(entry,dt,Vector2(delta.x,delta.z).length())

func capture(core: RefCounted, phase: String) -> void:
	core.command("pause 1")
	var snapshot: Dictionary = core.snapshot(false)
	show_state(core, snapshot)
	var time: float = snapshot.time
	var transform: Transform3D = city.monster_effects.puffs.get_instance_transform(0)
	await frames(10)
	check(core.snapshot(false).time == time, "native time held during " + phase)
	check(city.monster_effects.puffs.get_instance_transform(0) == transform, "effect frozen during " + phase)
	check(city.monster_effects.puff_count > 0, "visible particles during " + phase)
	await RenderingServer.frame_post_draw
	var prefix := "monster-effects-" if kind=="hydra" else "monster-reference-"+kind+"-"
	var path := "res://captures/" + prefix + phase + "-" + language + ".png"
	root.get_texture().get_image().save_png(path)
	captures.append(path)
	core.command("pause 0")

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="):
			language = argument.get_slice("=", 1)
		if argument.begins_with("--monster="):
			kind = argument.get_slice("=", 1)
	Engine.set_meta("ezeus_language", language)
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.set_process(false)
	city.orbit.enabled = false
	city.ui_layer.visible = false
	var core: RefCounted = city.core.simulation
	core.enable_test_commands()
	var fixture: Dictionary = Fixture.prepare(core,kind)
	check(not fixture.has("error"), "real native " + kind + " attack fixture " + str(fixture.get("error", "")))
	if fixture.has("error"):
		quit(1); return
	city.orbit.target = city.world_position((fixture.source.x + fixture.target.x) * .5, (fixture.source.y + fixture.target.y) * .5, 0)
	city.orbit.target.y = city.terrain_height_world(city.orbit.target.x, city.orbit.target.z) + .4
	city.orbit.distance = 12.0
	city.orbit.pitch = 40.0
	city.orbit.yaw = 30.0
	city.orbit.refresh()
	DisplayServer.window_move_to_foreground()
	core.command("speed 1")
	core.command("pause 0")
	var launch := -1.0
	var hit := -1.0
	var collapse := -1.0
	var taken := {}
	var frame_directory := OS.get_environment("EZEUS_FX_FRAME_DIRECTORY")
	var recorded := 0
	for step in 190:
		core.advance(.05)
		var state: Dictionary = core.snapshot(false)
		show_state(core, state)
		for event in state.get("monster_effects", []):
			if event.asset != fixture.asset:
				continue
			if event.phase == "launch" and launch < 0:
				launch = float(event.time)
			if event.phase == "impact" and hit < 0:
				hit = float(event.time)
			if bool(event.destroyed) and collapse < 0:
				collapse = float(event.time)
		if launch >= 0 and float(state.time) >= launch + 30 and not taken.has("breath"):
			taken.breath = true
			await capture(core, "breath")
		if hit >= 0 and float(state.time) >= hit + 45 and not taken.has("impact"):
			taken.impact = true
			await capture(core, "impact")
		if collapse >= 0 and float(state.time) >= collapse + 90 and not taken.has("collapse"):
			taken.collapse = true
			await capture(core, "collapse")
		if not frame_directory.is_empty() and step % 2 == 0:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(frame_directory.path_join("%04d.png" % recorded))
			recorded += 1
		if taken.size() == 3 and (frame_directory.is_empty() or float(state.time) >= collapse + 330):
			break
		if state.get("blocked", false):
			check(false, "fixture stopped at a native decision"); break
	core.command("pause 1")
	check(taken.size() == 3, "breath, hit and real destruction captured")
	check(city.monster_effects.launches >= 3 and city.monster_effects.impacts >= 3, "native three-shot building attack rendered")
	check(city.monster_effects.collapses >= 1, "destruction follows native collapse")
	check(city.monster_effects.get_child_count() == 2, "two draw batches and no added collision")
	var result := {"okay": okay, "checks": checks, "language": language, "captures": captures, "recorded_frames": recorded, "launches": city.monster_effects.launches, "impacts": city.monster_effects.impacts, "collapses": city.monster_effects.collapses}
	var prefix := "monster-effects-" if kind=="hydra" else "monster-reference-"+kind+"-"
	var file := FileAccess.open("res://captures/" + prefix + language + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print("MONSTER_FX_REVIEW ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
