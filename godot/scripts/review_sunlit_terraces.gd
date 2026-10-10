extends SceneTree
# Structural progression fixtures are separate from the ordinary-economy proof.
var core: RefCounted
var okay := true
var checks := 0
var language := "en"
var report := ""
var chapter_results := []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.trim_prefix("--lang=")
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_engine_directory", OS.get_environment("EZEUS_SCENARIO_ENGINE"))
	Engine.set_meta("ezeus_language", language)
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("SUNLIT_TERRACES_CHECK ", "PASS " if value else "FAIL ", label)

func permissions() -> Dictionary:
	var values := {}
	for row in core.command("buildable").buildings: values[row.name] = row.available
	return values

func footprints() -> Array:
	var values := []
	for row in core.snapshot(true).buildings: values.append([row.asset, row.x, row.y, row.w, row.h])
	values.sort_custom(func(a,b): return JSON.stringify(a) < JSON.stringify(b))
	return values

func run() -> void:
	var engine := OS.get_environment("EZEUS_SCENARIO_ENGINE")
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_PLAN")))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_MANIFEST")))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(manifest.report).path_join("source-terrain.json")))
	core = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	core.set_adventures_directory(engine.path_join("Adventures"))
	var listing: Array = core.adventures(engine, language).adventures
	check(listing.size() == 1 and listing[0].ref == plan.development_name, "isolated catalog contains the new campaign")
	var preview: Dictionary = core.adventure_preview(engine, "folder", plan.development_name, language)
	check(int(preview.get("episode_total",0)) == plan.chapters.size(), "all authored chapters appear in the preview")
	var state: Dictionary = core.open_adventure(engine, "folder", plan.development_name, language)
	check(not state.has("error") and state.tiles.size() == source.tiles.size() and int(state.money) == plan.initial_funds, "source-sized map and opening funds load")
	var geometry := true
	for index in state.tiles.size():
		geometry = geometry and state.tiles[index].slice(0,4) == source.tiles[index].slice(0,4)
	check(geometry, "native coordinates, elevation and terrain are preserved")
	check(state.tiles.any(func(t): return int(t[3]) & 8 and int(t[2]) > 0), "fertile terraces remain raised above the valley")
	var orchard_sites := []
	for tile in state.tiles:
		if not int(tile[3]) & 8: continue
		var query: Dictionary = core.command("preview orange_tree %d %d 0" % [int(tile[0]),int(tile[1])])
		if query.get("valid",false): orchard_sites.append([tile[0],tile[1],tile[2]])
	check(orchard_sites.size() >= 60, "at least sixty native-valid fertile orchard sites exist")
	var carry := []
	var kinds := {0:"population",1:"treasury",7:"housing",8:"set_aside",9:"survive",11:"trade",12:"production",13:"profit"}
	for number in plan.chapters.size():
		var episode: Dictionary = core.command("episode")
		check(int(episode.episode_number) == number+1 and episode.episode_title == plan.text[language]["Parent_Episode_%d_Title" % (number+1)], "localized chapter title %d" % (number+1))
		check(episode.goals.size() == plan.chapters[number].goals.size(), "chapter has its own objective list")
		var authored_goals := true
		for index in episode.goals.size():
			var goal: Dictionary = plan.chapters[number].goals[index]
			authored_goals = authored_goals and episode.goals[index].kind == kinds[int(goal.type)]
			if int(goal.type) != 9: authored_goals = authored_goals and int(episode.goals[index].required) == int(goal.count)
		check(authored_goals, "objective types and required quantities match the recipe")
		check(episode.voice.is_empty() and episode.victory_voice.is_empty(), "source campaign narration is not reused")
		var available := permissions()
		check(available.house and available.orange_tree and available.orange_tenders_lodge and available.warehouse and available.timber_mill and available.trade_post, "settlement, orange orchards and timber trade remain available")
		check(bool(available.growers_lodge) == (number >= 1) and bool(available.olive_tree) == (number >= 1) and bool(available.olive_press) == (number >= 1), "olive production unlocks at chapter two")
		check(bool(available.gymnasium) == (number >= 1) and bool(available.podium) == (number >= 1) and not available.bibliotheke and bool(available.fleece_vendor) == (number >= 1) and not available.carding_shed, "Greek culture and imported clothing unlock without domestic fleece industry")
		check(bool(available.vine) == (number == 2) and bool(available.winery) == (number == 2) and bool(available.palace) == (number == 2), "vineyards, wineries and civic income unlock at chapter three")
		var partners: Array = core.command("trade_partners").partners
		check(partners.size() == 1 and partners[0].name == plan.text.en.partner_name and not partners[0].water and partners[0].buys.size() == 4 and partners[0].sells.size() == 2, "one land partner buys four local products and supplies grain and fleece")
		if number == 0:
			check(core.command("test_win").has("error"), "ordinary play cannot force victory")
			check(not core.command("preview olive_press %d %d 0" % [int(manifest.start_focus[0]),int(manifest.start_focus[1])]).get("valid",false), "locked olive press placement is refused")
			for tile in state.tiles:
				if core.command("preview house %d %d 0" % [int(tile[0]),int(tile[1])]).get("valid",false):
					check(not core.command("build house %d %d 0" % [int(tile[0]),int(tile[1])]).has("error"), "ordinary house built before handoff")
					break
		else: check(footprints() == carry, "existing buildings carry across the chapter")
		if number == 2:
			check(not episode.goals[-1].met and not episode.goals[2].met and not episode.goals[2].set_aside, "future waiting goal and unfunded wine reserve begin unmet")
			check(core.command("set_aside 2").has("error"), "empty city cannot commit the wine reserve")
			core.command("speed 3"); core.command("pause 0")
			for batch in 180:
				for step in 10: core.advance(.05)
				if core.command("episode").goals[-1].met: break
			check(core.command("episode").goals[-1].met, "relative BC waiting goal completes with the calendar")
			core.command("pause 1")
		carry = footprints()
		check(core.save_city("terraces-review-%d" % number).has("saved"), "chapter checkpoint saves")
		core.close_city()
		var loaded: Dictionary = core.open_city(engine, OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("terraces-review-%d.ez" % number), language)
		check(not loaded.has("error") and footprints() == carry and permissions() == available and int(core.command("episode").episode_number) == number+1, "checkpoint reload preserves the chapter, buildings and unlocks")
		chapter_results.append({"chapter":number+1,"permissions":available,"partner":partners[0]})
		core.enable_test_commands(); core.command("test_win")
		var next: Dictionary = core.command("finish_episode")
		if number < plan.chapters.size()-1:
			check(next.get("next") == "episode" and not next.preview.colony, "same-city next chapter is offered")
			core.command("begin_episode")
		else: check(next.get("next") == "complete", "final chapter reaches the campaign ending")
	core.close_city()
	if OS.get_cmdline_user_args().has("--visible") and okay: await visible_menu(plan,manifest)
	var file := FileAccess.open(report.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"okay":okay,"checks":checks,"language":language,"chapters":chapter_results,"orchard_sites":orchard_sites,"progression_victories_are_fixtures":true},"\t"))
	print("FIRST_SCENARIO_TERRACES_REVIEW ", "PASS" if okay else "FAIL", " checks=",checks," lang=",language)
	quit(0 if okay else 1)

func visible_menu(plan: Dictionary, manifest: Dictionary) -> void:
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var leaders = load("res://scripts/leaders.gd")
	if leaders.list().is_empty(): leaders.create("Terraces Review")
	leaders.set_current(leaders.list()[0])
	var menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu); current_scene = menu
	for frame in 30: await process_frame
	menu.open_adventures()
	for frame in 30: await process_frame
	menu.navigation.adventure_pager.select_index(0); menu.start_adventure()
	for frame in 25: await process_frame
	var expected := str(plan.text[language].Parent_Episode_1_Introduction).replace("@P","\n\n   ").replace("@L","\n")
	check("".join(menu.navigation.story_pages).strip_edges() == expected.strip_edges(), "real menu preserves the complete new opening briefing across its pages")
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png(report.path_join("terraces-briefing.png"))
	Engine.set_meta("ezeus_new_game_focus", manifest.start_focus)
	menu.begin()
	for frame in 130: await process_frame
	var city = current_scene
	check(city is Node3D and city.hud.build_entries.has("orange_tree") and city.hud.build_entries.has("orange_tenders_lodge") and not city.hud.build_entries.has("olive_press") and not city.hud.build_entries.has("winery"), "real opening Build menu respects chapter unlocks")
	city.core.send("pause 1")
	for frame in 10: await process_frame
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png(report.path_join("terraces-city.png"))
	city.queue_free()
	for frame in 60: await process_frame
