extends SceneTree
# Real native two-episode authoring/export/save/progression fixture on copied terrain.
const Catalog = preload("res://scripts/build_catalog.gd")
var core: RefCounted
var checks := 0
var okay := true
var language := "en"
var report := ""

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("EPISODE_BUILD_CHECK ", "PASS " if value else "FAIL ", label)

func available() -> Dictionary:
	var result := {}
	for item in core.command("buildable").buildings: result[item.name] = bool(item.available)
	return result

func shown() -> Dictionary:
	var result := {}
	for group in Catalog.groups(core.command("buildable").buildings, false, core.command("trade_partners").partners):
		for item in group.items: result[item.name] = true
	return result

func copy_tree(source: String, target: String) -> void:
	DirAccess.make_dir_recursive_absolute(target)
	for name in DirAccess.get_files_at(source): DirAccess.copy_absolute(source.path_join(name), target.path_join(name))

func command(text: String) -> Dictionary:
	var result: Dictionary = core.command(text)
	check(not result.has("error"), text)
	return result

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.trim_prefix("--lang=")
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	var engine := OS.get_environment("EZEUS_SCENARIO_ENGINE")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../content/scenarios/first_light_harbor_chapters.json"))
	var name: String = plan.development_name
	var scratch := report.path_join("Adventures")
	copy_tree(engine.path_join("Adventures").path_join(name), scratch.path_join(name))
	core = ClassDB.instantiate("EZeusSimulation")
	core.set_adventures_directory(scratch)
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	var imported: Dictionary = core.open_editor(engine, "folder", name, language)
	check(imported.get("editor", false), "copied prototype opens in editor")
	if not imported.get("editor", false):
		quit(1)
		return
	# Fresh unique name permits repeat reviews without overwriting an earlier fixture.
	var fixture := "Unlock Fixture %d" % Time.get_ticks_usec()
	command("editor_single_parent " + fixture)
	var first: Dictionary = core.command("editor_episode p 0")
	var cid: int = int(first.cities[0].id)
	var type_ids := {}
	for b in first.cities[0].buildings: type_ids[b.name] = int(b.type)
	# Numeric IDs are derived from the native enum file by the authoring wrapper.
	var build_report := engine.get_base_dir().path_join("report/building-types.json")
	var types: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(build_report))
	check(first.cities[0].buildings.any(func(b): return int(b.type) == int(types.palace)) and first.cities[0].buildings.any(func(b): return int(b.type) == int(types.bibliotheke)), "editor exposes ordinary civic and science permissions")
	for episode in [0, 1]:
		if episode == 1: command("editor_episode_add")
		command("editor_goal_add p %d 0" % episode)
		command("editor_goal_set p %d 0 count 99999" % episode)
		for pair in [["palace", episode], ["bibliotheke", episode], ["tradePost", episode], ["commonAgora", episode], ["grandAgora", 0], ["wheatFarm", 1 - episode], ["timberMill", episode]]:
			command("editor_building p %d %d %d %d" % [episode, cid, int(types[pair[0]]), int(pair[1])])
	command("editor_save")
	core.close_city()
	var initial: Dictionary = core.open_adventure(engine, "folder", fixture, language)
	check(not initial.has("error") and int(core.command("episode").episode_count) == 2, "export reloads as a two-episode native campaign")
	var a := available()
	check(not a.palace and not a.bibliotheke and not a.trade_post and not a.pier and a.wheat_farm and not a.timber_mill, "episode one gates ordinary buildings, trade aliases and industries")
	check(not a.gymnasium and not a.theater, "Atlantean city does not offer Greek culture counterparts")
	check(not a.food_vendor, "market vendors are unavailable when both market layouts are locked")
	var names := shown()
	check(not names.has("palace") and not names.has("bibliotheke") and names.has("wheat_farm"), "Build catalog obeys episode-one native permissions")
	var point := Vector2i()
	for tile in initial.tiles:
		if bool(tile[5]):
			point = Vector2i(int(tile[0]), int(tile[1]))
			break
	for tool in ["palace", "bibliotheke"]:
		check(core.command("preview %s %d %d 0" % [tool, point.x, point.y]).get("reason") == "building_not_available" and core.command("build %s %d %d 0" % [tool, point.x, point.y]).get("error") == "building_not_available", tool + " is blocked by native preview and placement")
	var saved: Dictionary = core.save_city("episode-locks")
	check(saved.has("saved"), "locked first episode saves")
	core.close_city()
	var reopened: Dictionary = core.open_city(engine, OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("episode-locks.ez"), language)
	check(not reopened.has("error") and available() == a, "active and future episode permissions survive save/load")
	core.enable_test_commands()
	core.command("test_win")
	var next: Dictionary = core.command("finish_episode")
	check(next.get("next") == "episode", "validator completion offers the next parent episode")
	var begun: Dictionary = core.command("begin_episode")
	var later := available()
	check(not begun.has("error") and int(core.command("episode").episode_number) == 2 and later.palace and later.bibliotheke and later.trade_post and later.pier and later.timber_mill and not later.wheat_farm, "beginning episode two unlocks its buildings and applies its industry limits")
	check(later.food_vendor and shown().has("bibliotheke") and not shown().has("wheat_farm"), "catalog and derived market tools follow the new episode")
	check(core.save_city("episode-two").has("saved"), "second episode saves")
	core.close_city()
	core.open_city(engine, OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("episode-two.ez"), language)
	check(available() == later and int(core.command("episode").episode_number) == 2, "second-episode unlocks remain after reload")
	core.close_city()
	core.set_adventures_directory("")
	var file := FileAccess.open(report.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"okay": okay, "checks": checks, "language": language, "stage_one": a, "stage_two": later}, "\t"))
	print("EPISODE_BUILD_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks, " lang=", language)
	quit(0 if okay else 1)
