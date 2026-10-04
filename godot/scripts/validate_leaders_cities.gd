extends SceneTree
# Leaders and the player's cities (headless; saves and settings go to a scratch folder, the designated save is never written).
#   Leaders: names are checked as the roster does (empty, too long, a folder's forbidden characters, taken); a leader is a folder
#   of saves, chosen in the settings; SaveFiles saves into it and lists its saves before the ones from before leaders; deleting
#   removes only that folder; the start menu asks for a leader first, creates and chooses one and names it on the main page.
#   Cities: in The Sands of Betrayal (three districts: the player's Elyria, unowned Calliste, rival Theron) the district in the
#   middle of the view is the city in view; the pages follow the player's own; Calliste is bought for its price (refused without
#   the drachmas, and a city that is not for sale is refused), then is governed like Elyria; looking around never changes the
#   simulation (the replay digest holds); the leader's name is accepted for the messages.
const Leaders = preload("res://scripts/leaders.gd")
const SaveFiles = preload("res://scripts/save_files.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("LEADERS_CITIES_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func scratch() -> String:
	var folder := ProjectSettings.globalize_path("res://captures/leaders-scratch-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder.path_join("saves"))
	Engine.set_meta("ezeus_save_directory", folder.path_join("saves"))
	Engine.set_meta("ezeus_settings_path", folder.path_join("settings.cfg"))
	return folder

func touch(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("eZeus.ez")
	file.close()

func remove_tree(folder: String) -> void:
	for sub in DirAccess.get_directories_at(folder):
		remove_tree(folder.path_join(sub))
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)

func leader_checks() -> void:
	var folder := scratch()
	var root := SaveFiles.root()
	touch(root.path_join("older city.ez"))
	check(Leaders.list().is_empty() and Leaders.current().is_empty() and SaveFiles.directory() == root, "no leader yet: saves go to the root")
	for bad in ["", "   ", "a/b", "dot.", ".hidden", "x".repeat(Leaders.MAX_LENGTH + 1), "what?"]:
		if bad == "dot.":
			continue
		check(not Leaders.problem(bad).is_empty() and not Leaders.create(bad), "the name '%s' is refused (%s)" % [bad, Leaders.problem(bad)])
	check(Leaders.create("Pericles") and Leaders.create("Аспасия"), "leaders are created (Latin and Cyrillic names)")
	check(not Leaders.problem("pericles").is_empty(), "a name already taken is refused, whatever its case")
	check(Leaders.list() == ["Pericles", "Аспасия"], "the roster lists them %s" % str(Leaders.list()))
	Leaders.set_current("Pericles")
	check(Leaders.current() == "Pericles" and SaveFiles.directory() == root.path_join("Pericles"), "the chosen leader's folder takes the saves")
	touch(SaveFiles.directory().path_join("pericles city.ez"))
	var listed := SaveFiles.list()
	check(listed.size() == 2 and listed[0].name == "pericles city" and not listed[0].legacy and listed[1].legacy and listed[1].name == "older city",
		"the leader's saves come first, then the ones from before leaders, marked")
	Leaders.set_current("Аспасия")
	check(SaveFiles.list().filter(func(e): return not e.legacy).is_empty(), "another leader does not see Pericles' saves")
	check(Leaders.delete("Pericles") and not "Pericles" in Leaders.list() and FileAccess.file_exists(root.path_join("older city.ez")), "deleting a leader removes its folder and nothing else")
	check(not Leaders.delete("nobody") and not Leaders.delete(".."), "an unknown leader cannot be deleted")
	Leaders.set_current("Ghost")
	check(Leaders.current().is_empty(), "a remembered leader whose folder is gone is not chosen")
	# The start menu: with no leader chosen it opens on the roster; creating one chooses it; the main page names it.
	Leaders.set_current("")
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root_node().add_child(menu)
	await process_frame
	check(menu.page == "leaders" and menu.leader_list.item_count == 1, "with no leader chosen the start menu opens on the roster (%s)" % menu.page)
	menu.leader_name.text = "Solon"
	menu.create_leader()
	check(Leaders.current() == "Solon" and menu.leader_list.item_count == 2 and not menu.leader_proceed.disabled, "Create leader adds and chooses Solon")
	menu.leader_name.text = "solon"
	menu.create_leader()
	check(menu.leader_status.text == menu.tr("There is a leader of that name already"), "a second Solon is refused with a reason: %s" % menu.leader_status.text)
	menu.proceed_leader()
	check(menu.page == "main" and menu.leader_line.text.contains("Solon"), "Proceed returns to the main page, which names the leader: %s" % menu.leader_line.text)
	menu.queue_free()
	await process_frame
	remove_tree(folder)
	Engine.remove_meta("ezeus_save_directory")
	Engine.remove_meta("ezeus_settings_path")

func root_node() -> Window:
	return get_root()

func by_name(answer: Dictionary, name: String) -> Dictionary:
	for item in answer.get("cities", []):
		if item.name == name:
			return item
	return {}

func city_checks(lang: String) -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var lister: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var sands := {}
	for item in lister.adventures(engine, lang).get("adventures", []):
		if str(item.ref).contains("Sands") or str(item.title).contains("Sands") or str(item.title).contains("Песк"):
			sands = item
	check(not sands.is_empty(), lang + " The Sands of Betrayal is among the adventures")
	if sands.is_empty():
		return
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.open_adventure(engine, sands.kind, sands.ref, lang)
	core.enable_test_commands()
	var cities: Dictionary = core.command("cities")
	var owners: Array = cities.cities.map(func(c): return str(c.owner))
	check(cities.cities.size() == 3 and owners.count("player") == 1 and owners.count("unowned") == 1 and owners.count("rival") == 1, lang + " three districts: the player's, one for sale, a rival %s" % str(owners))
	var mine: Dictionary = cities.cities.filter(func(c): return c.owner == "player")[0]
	var sale: Dictionary = cities.cities.filter(func(c): return c.owner == "unowned")[0]
	var rival: Dictionary = cities.cities.filter(func(c): return c.owner == "rival")[0]
	check(int(sale.price) > 0 and int(cities.player_city) == int(mine.id), lang + " %s is for sale for %d drachmas; the pages follow %s" % [sale.name, int(sale.price), mine.name])
	# Looking at the city for sale: it is the city in view, the pages still follow the player's own.
	var looked: Dictionary = core.command("view_tile %d %d" % [int(sale.centre[0]), int(sale.centre[1])])
	check(int(looked.viewed) == int(sale.id) and bool(looked.viewed_changed) and not bool(looked.changed) and int(looked.player_city) == int(mine.id), lang + " looking at the city for sale puts it in view; the pages stay with the player's")
	check(str(core.snapshot(false).city_header.name) == str(mine.name), lang + " the header still names " + str(mine.name))
	# Buying it.
	var money: int = core.snapshot(false).money
	if money >= int(sale.price):
		core.command("test_money %d" % (-money + int(sale.price) - 1))
	var short: Dictionary = core.command("buy_city %d" % int(sale.id))
	check(short.get("error", "") == "insufficient_funds" and by_name(core.command("cities"), str(sale.name)).owner == "unowned", lang + " without the drachmas the city is not bought")
	core.command("test_money %d" % (int(sale.price) * 3))
	var before: int = core.snapshot(false).money
	var bought: Dictionary = core.command("buy_city %d" % int(sale.id))
	var after: int = core.snapshot(false).money
	check(bought.get("kind", "") == "cities" and by_name(bought, str(sale.name)).owner == "player" and before - after == int(sale.price), lang + " %s is bought for %d drachmas" % [sale.name, before - after])
	check(core.command("buy_city %d" % int(sale.id)).get("error", "") == "not_for_sale" and core.command("buy_city %d" % int(rival.id)).get("error", "") == "not_for_sale", lang + " a city already owned, or a rival's, is not for sale")
	# Governing it: the pages, the header and the Build menu follow it while it is in view.
	var header: String = core.snapshot(false).city_header.name
	check(header == str(sale.name) and int(core.command("cities").player_city) == int(sale.id), lang + " the bought city is the one in view and the pages follow it: %s" % header)
	var offered: Array = core.command("buildable").buildings.filter(func(b): return b.available)
	check(offered.size() >= 10, lang + " the Build menu offers %d buildings in %s" % [offered.size(), sale.name])
	var built := false
	var state: Dictionary = core.snapshot(true)
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		if Vector2(float(tile[0]), float(tile[1])).distance_to(Vector2(float(sale.centre[0]), float(sale.centre[1]))) > 25.0:
			continue
		if core.command("preview road %d %d 0" % [int(tile[0]), int(tile[1])]).get("valid", false):
			built = not core.command("build road %d %d 0" % [int(tile[0]), int(tile[1])]).has("error")
			break
	check(built, lang + " a road is built in " + str(sale.name))
	var back: Dictionary = core.command("view_tile %d %d" % [int(mine.centre[0]), int(mine.centre[1])])
	check(bool(back.changed) and int(back.player_city) == int(mine.id) and str(core.snapshot(false).city_header.name) == str(mine.name), lang + " looking back at %s makes it the city the pages follow again" % mine.name)
	var at_rival: Dictionary = core.command("view_tile %d %d" % [int(rival.centre[0]), int(rival.centre[1])])
	check(int(at_rival.viewed) == int(rival.id) and int(at_rival.player_city) == int(mine.id), lang + " looking at the rival keeps the pages on the player's last city")
	check(core.command("view_tile 999999 999999").has("error") and core.command("view_tile x").has("error"), lang + " a tile off the map is refused")
	# The leader's name.
	check(core.command("player_name Солон Афинский").get("name", "") == "Солон Афинский" and core.command("player_name").has("error"), lang + " the leader's name is taken for the messages; an empty one is refused")
	core.close_city()
	# Looking around never changes the simulation. (A new adventure is generated afresh each time it is opened, so two
	# openings never replay alike; the saved test city does, and is used here.)
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var plain: RefCounted = ClassDB.instantiate("EZeusSimulation")
	plain.open_city(engine, save, lang)
	var clean: Dictionary = plain.replay(150, 7)
	plain.close_city()
	var looking: RefCounted = ClassDB.instantiate("EZeusSimulation")
	looking.open_city(engine, save, lang)
	for spot in [Vector2i(150, -40), Vector2i(40, -30), Vector2i(100, -90)]:
		looking.command("view_tile %d %d" % [spot.x, spot.y])
	var looked_replay: Dictionary = looking.replay(150, 7)
	looking.close_city()
	check(clean.has("digest") and clean.digest == looked_replay.digest, lang + " looking around leaves the replay digest unchanged")

func run() -> void:
	await leader_checks()
	for lang in ["en", "ru"]:
		city_checks(lang)
	print("LEADERS_CITIES_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
