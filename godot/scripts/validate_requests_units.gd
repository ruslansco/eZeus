extends SceneTree
# The overview's requests and moving several companies at once (headless, in memory; the designated save is never written):
# `city_data` names the requests in the game's words; a request a world city makes is listed with the player's cities that can
# send it and is fulfilled by `world_fulfil`; three companies called out are sent to one tile together with `banners_move`, each
# to its own place around it (as the SDL view places a selection), and malformed or unknown groups are refused.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("REQUESTS_UNITS_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	core.enable_test_commands()
	return opened

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		check(open(core, lang).has("protocol"), lang + " designated test city loads")
		var data: Dictionary = core.command("city_data")
		check(not str(data.get("requests_title", "")).is_empty(), lang + " the overview's requests heading is the game's own: %s" % str(data.get("requests_title", "")))
		if lang == "ru":
			check(str(data.requests_title).unicode_at(0) >= 0x400, "ru the requests heading is in Russian")
		# A request: wheat, which the test city stores.
		var world: Dictionary = core.command("world")
		var partner := -1
		for index in world.cities.size():
			if bool(world.cities[index].get("can_fulfil", false)):
				partner = index
				break
		check(partner >= 0, lang + " a world city that may ask the player for goods")
		if partner >= 0:
			core.command("test_stock 64 40")
			var asked: Dictionary = core.command("test_request %d 64 8" % partner)
			var requests: Array = asked.get("requests", [])
			check(requests.size() >= 1 and int(requests[-1].city) == partner and not requests[-1].from.is_empty(), lang + " the request is listed with the city that can send it")
			if requests.size() >= 1 and not requests[-1].from.is_empty():
				var before := requests.size()
				var sent: Dictionary = core.command("world_fulfil %d %d" % [int(requests[-1].id), int(requests[-1].from[0])])
				check(not sent.has("error") and sent.get("requests", []).size() == before - 1, lang + " sending the goods fulfils it (%s)" % sent.get("error", "ok"))
		# Three companies to one tile together.
		var called: Dictionary = core.command("army_call")
		var army: Dictionary = core.command("army")
		var banners: Array = army.get("banners", []).filter(func(b): return not bool(b.get("abroad", false)))
		check(banners.size() >= 3, lang + " the city has three companies at home (%d)" % banners.size())
		if banners.size() >= 3:
			var ids: Array = banners.slice(0, 3).map(func(b): return int(b.id))
			var state: Dictionary = core.snapshot(true)
			var target := Vector2i(99999, 99999)
			for tile in state.tiles:
				var away := Vector2(float(tile[0]), float(tile[1])).distance_to(Vector2(float(banners[0].x), float(banners[0].y)))
				if int(tile[5]) and not int(tile[4]) and away > 12.0 and away < 25.0:
					target = Vector2i(int(tile[0]), int(tile[1]))
					break
			var moved: Dictionary = core.command("banners_move %d %d %s" % [target.x, target.y, " ".join(ids.map(func(id): return str(id)))])
			var placed: Array = moved.get("banners", []).filter(func(b): return int(b.id) in ids)
			var cells := {}
			for banner in placed:
				cells[Vector2i(int(banner.x), int(banner.y))] = true
			var near: bool = placed.size() == 3 and placed.all(func(b): return Vector2(float(b.x), float(b.y)).distance_to(Vector2(target)) <= 5.0)
			check(not moved.has("error") and near and cells.size() == 3, lang + " the three companies go to the tile together, each to its own place (target %s: %s)" % [str(target), str(placed.map(func(b): return [int(b.x), int(b.y)]))])
			check(core.command("banners_move %d %d" % [target.x, target.y]).has("error") and core.command("banners_move %d %d 999999" % [target.x, target.y]).get("error", "") == "unknown_banner",
				lang + " a group without companies, or of unknown ones, is refused")
		core.close_city()
	print("REQUESTS_UNITS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
