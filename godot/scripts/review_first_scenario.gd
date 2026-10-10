extends SceneTree
# Scoped prototype checks. End-screen exercise is explicitly a validator fixture.
var core: RefCounted
var okay := true
var checks := 0
var report := ""
var language := "en"
var engine := ""
var visible := false

func _initialize() -> void:
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	engine = OS.get_environment("EZEUS_SCENARIO_ENGINE")
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_engine_directory", engine)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.trim_prefix("--lang=")
	visible = OS.get_cmdline_user_args().has("--visible")
	Engine.set_meta("ezeus_language", language)
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("FIRST_SCENARIO_CHECK ", "PASS " if value else "FAIL ", message)

func frames(count: int) -> void:
	for i in count: await process_frame

func find_site(state: Dictionary, tool: String, partner := -1) -> Vector2i:
	for tile in state.tiles:
		if int(tile[5]) and int(tile[2]) == 0:
			var result: Dictionary = core.command("preview %s %d %d 0 %d" % [tool, int(tile[0]), int(tile[1]), partner])
			if result.get("valid", false): return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(-999, -999)

func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(report.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))

func run() -> void:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../content/scenarios/first_light_harbor.json"))
	core = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	core.set_adventures_directory(engine.path_join("Adventures"))
	var listing: Dictionary = core.adventures(engine, language)
	var list: Array = listing.get("adventures", [])
	check(list.size() == 1 and list[0].kind == "folder" and list[0].ref == plan.development_name, "isolated catalog contains only the new development scenario")
	if list.size() != 1:
		quit(1)
		return
	var preview: Dictionary = core.adventure_preview(engine, "folder", plan.development_name, language)
	check(not preview.has("error") and int(preview.get("episode_total", 0)) == 1 and not preview.get("sandbox", true), "one playable episode with native objectives")
	var state: Dictionary = core.open_adventure(engine, "folder", plan.development_name, language)
	check(not state.has("error") and state.get("paused", false) and int(state.get("population", -1)) == 0 and int(state.get("money", 0)) == int(plan.initial_funds), "empty settlement opens paused with its starting treasury")
	if state.has("error"):
		quit(1)
		return
	var ep: Dictionary = core.command("episode")
	check(ep.get("episode_title") == plan.text[language].Parent_Episode_1_Title and ep.get("introduction") == plan.text[language].Parent_Episode_1_Introduction, "new briefing loads in " + language)
	check(ep.get("goals", []).size() == 7 and ep.get("episode_count") == 1 and not ep.get("victory", true), "seven unmet objectives and a single final episode")
	check(not bool(ep.goals[4].met), "an available neighbor alone does not fulfill the export-route objective")
	check(int(core.command("difficulty").value) == int(plan.difficulty), "Mortal difficulty saved in the campaign")
	var stats := {"tiles": state.tiles.size(), "water": 0, "fertile": 0, "forest": 0, "buildable": 0, "extent": state.extent, "focus": state.focus}
	for tile in state.tiles:
		for pair in [["water", 4], ["fertile", 8], ["forest", 16]]:
			if int(tile[3]) & int(pair[1]): stats[pair[0]] += 1
		stats.buildable += int(bool(tile[5]))
	check(stats.tiles == 25992 and stats.fertile > 1000 and stats.forest > 1000 and stats.buildable > 5000, "full parent map has settlement ground, meadow and timber")
	var permissions := {}
	for item in core.command("buildable").buildings: permissions[item.name] = bool(item.available)
	check(permissions.house and permissions.fountain and permissions.common_agora and permissions.bibliotheke and permissions.wheat_farm and permissions.timber_mill and permissions.carding_shed, "opening episode offers its housing, food, science, fleece and timber prerequisites")
	check(not permissions.palace and not permissions.university and not permissions.armory and not permissions.gymnasium and not permissions.grand_agora and not permissions.wall, "unneeded advanced, military and other-culture buildings stay locked")
	check(core.command("test_win").has("error") and core.command("editor_single_parent Another").get("error") == "not_editing", "play sessions cannot invoke authoring or test completion")
	var partners: Array = core.command("trade_partners").partners
	check(partners.size() == 1 and partners[0].name == plan.text.en.partner_name and partners[0].available, "one available partner with the new identity")
	var partner: Dictionary = partners[0]
	check(partner.buys.any(func(g): return int(g.resource) == 8192) and partner.sells.any(func(g): return int(g.resource) == 4096), "wood exports and fallback fleece imports are offered")
	var sites := {}
	for tool in ["house", "fountain", "maintenance_office", "warehouse", "granary", "wheat_farm", "carding_shed", "timber_mill", "bibliotheke"]:
		var at := find_site(state, tool)
		sites[tool] = [at.x, at.y]
		check(at != Vector2i(-999, -999), tool + " has a native-valid site")
	var trade_tool := "pier" if partner.water else "trade_post"
	var trade_at := find_site(state, trade_tool, int(partner.index))
	sites[trade_tool] = [trade_at.x, trade_at.y]
	check(trade_at != Vector2i(-999, -999), "native-valid site for the required trading route")
	if trade_at != Vector2i(-999, -999):
		var post: Dictionary = core.command("build %s %d %d 0 %d" % [trade_tool, trade_at.x, trade_at.y, int(partner.index)])
		check(not post.has("error") and not bool(core.command("episode").goals[4].met), "an unstaffed post without export orders does not fulfill the route objective")
		core.command("undo")
		core.replay(4, -1)
	var house: Array = sites.house
	var built: Dictionary = core.command("build house %d %d 0" % [int(house[0]), int(house[1])])
	check(not built.has("error") and core.snapshot(true).buildings.any(func(b): return str(b.asset).begins_with("common_house")), "normal housing construction works on the imported terrain")
	var before: Dictionary = core.replay(0, 517)
	var saved: Dictionary = core.save_city("first-scenario-review")
	check(saved.has("saved"), "prototype saves to the scratch directory")
	var holder := Control.new()
	root.add_child(holder)
	var loader: RefCounted = load("res://scripts/save_loader.gd").new()
	var probed: Dictionary = await loader.probe(holder, OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("first-scenario-review.ez"), language)
	check(probed.get("ok", false), "load preflight uses the isolated scenario resource root")
	load("res://scripts/save_loader.gd").clean(probed)
	holder.queue_free()
	core.close_city()
	var opened: Dictionary = core.open_city(engine, OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("first-scenario-review.ez"), language)
	var after: Dictionary = core.replay(0, 517)
	check(not opened.has("error") and before.digest == after.digest and core.command("episode").goals.size() == 7 and not bool(core.command("episode").goals[4].met), "save/reload preserves native state and the export-route requirement")
	core.close_city()
	# Advance the empty scenario through the authored trade interruption using
	# ordinary native ticks; no resources, population, dates or outcomes are injected.
	core.open_adventure(engine, "folder", plan.development_name, language)
	core.command("speed 3")
	core.command("pause 0")
	var interrupted := false
	var resumed := false
	var native_ticks := 0
	while native_ticks < 4000 and not resumed:
		for i in 10: core.advance(.05)
		native_ticks += 10
		var current: Dictionary = core.snapshot(false)
		var trading: Array = core.command("trade_partners").partners
		var open := trading.size() == 1 and bool(trading[0].trading)
		if not open: interrupted = true
		if interrupted and open: resumed = true
		if current.get("blocked", false): break
	check(interrupted and resumed, "Poseidon closes and automatically restores the route through native event timing")
	check(not core.snapshot(false).get("blocked", true), "the challenge does not require an invented decision or payment")
	core.command("pause 1")
	core.enable_test_commands()
	core.command("test_win")
	var ending: Dictionary = core.command("finish_episode")
	check(ending.get("next") == "complete", "validator victory fixture reaches the end without a colony handoff")
	core.close_city()
	if visible and okay:
		await show_city(plan)
	write_json("result.json", {"okay": okay, "checks": checks, "language": language, "terrain": stats, "sites": sites, "native_event_ticks": native_ticks, "visible": visible, "full_playthrough_verified": false, "pacing_verified": false, "ending_test_is_fixture": true})
	print("FIRST_SCENARIO_REVIEW ", "PASS" if okay else "FAIL", " checks=", checks, " lang=", language)
	quit(0 if okay else 1)

func show_city(plan: Dictionary) -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../build-content-research/first-light-harbor/current.json"))
	Engine.set_meta("ezeus_new_game_focus", manifest.start_focus)
	var leaders = load("res://scripts/leaders.gd")
	if leaders.list().is_empty(): leaders.create("Harbor Review")
	leaders.set_current(leaders.list()[0])
	var menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(20)
	menu.open_adventures()
	await frames(30)
	check(menu.engine == engine and menu.listing.size() == 1, "prototype launcher uses its isolated catalog in the real menu")
	menu.navigation.adventure_pager.select_index(0)
	menu.start_adventure()
	await frames(20)
	check(menu.intro_card.mode == "intro" and menu.intro_card.heading.text == plan.text[language].Adventure_Title and menu.intro_card.body.text == plan.text[language].Parent_Episode_1_Introduction, "real Start displays the authored briefing")
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png(report.path_join("briefing.png"))
	menu.begin()
	var deadline := Time.get_ticks_msec() + 15000
	while not current_scene is Node3D and Time.get_ticks_msec() < deadline:
		await process_frame
	check(current_scene is Node3D, "real Begin enters the 3D settlement")
	if not current_scene is Node3D: return
	var city = current_scene
	await frames(100)
	city.core.send("pause 1")
	city.orbit.distance = 105
	city.orbit.snap_to_ground()
	await frames(20)
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png(report.path_join("terrain.png"))
	city.queue_free()
	await frames(4)
