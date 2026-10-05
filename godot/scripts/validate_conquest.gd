extends SceneTree
# Conquest of a city on the player's own map, with Ares marching along (headless, in memory; a new game of The Sands of Betrayal,
# whose rival Theron shares the map; saves go to a scratch folder, the designated save is never touched).
#   Ares: a finished sanctuary of Ares is not enlisted (the SDL dialog never offers him either); the conquest's enlisting says he can
#   march with it, and asking his sanctuary for help while the army is on the way adds him to it (the engine's eAresHelpAction): the
#   world map's army carries him and the sanctuary says its god is abroad until he comes home with the army.
#   On the map: the army does not fight at a distance as against a foreign city, it lands in Theron as an invasion (the engine's
#   eInvasionEvent with the player's companies), the view is asked to go there, the player's soldiers walk in Theron's district,
#   and the engine decides the end (Theron becomes the player's, or the conquest fails); either way the army and Ares come home.
var okay := true
var checks := 0
var titles: Array = []
var kinds: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	print("CONQUEST_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func site_for(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		if core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

# A sanctuary of Ares founded beside a road and finished at once (as validate_attack.gd founds Dionysus's).
func found_ares(core: RefCounted) -> Vector2i:
	var state: Dictionary = core.snapshot(true)
	core.command("test_allow temple_ares")
	var warehouse := site_for(core, state, "warehouse")
	if warehouse.x == 99999 or core.command("build warehouse %d %d 0" % [warehouse.x, warehouse.y]).has("error"):
		return Vector2i(99999, 99999)
	core.command("test_stock 32768 60")
	state = core.snapshot(true)
	var site := site_for(core, state, "temple_ares")
	if site.x == 99999:
		return site
	var plan: Dictionary = core.command("preview temple_ares %d %d 0" % [site.x, site.y])
	for dx in [-1, int(plan.w)]:
		var at := Vector2i(int(plan.x) + dx, int(plan.y) + int(plan.h) / 2)
		if core.command("preview road %d %d 0" % [at.x, at.y]).get("valid", false):
			core.command("build road %d %d 0" % [at.x, at.y])
			break
	if core.command("build temple_ares %d %d 0" % [site.x, site.y]).has("error"):
		return Vector2i(99999, 99999)
	core.command("test_complete %d %d" % [site.x, site.y])
	return site

func city_named(world: Dictionary, name: String) -> Dictionary:
	for city in world.cities:
		if str(city.name) == name:
			return city
	return {}

func answer_events(core: RefCounted, state: Dictionary) -> void:
	for event in state.get("events", []):
		titles.append(str(event.title))
		kinds.append(str(event.get("event", event.get("kind", ""))))
		print("CONQUEST_EVENT ", str(event.get("event", "")), " | ", str(event.title))
		var choices: Array = event.get("actions", [])
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

# The district a tile lies in, as near as the cities' middles tell (the districts of The Sands of Betrayal lie apart).
func district(cities: Array, x: float, y: float) -> int:
	var best := -1
	var near := INF
	for city in cities:
		var d := Vector2(x, y).distance_to(Vector2(float(city.centre[0]), float(city.centre[1])))
		if d < near:
			near = d
			best = int(city.id)
	return best

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var scratch := ProjectSettings.globalize_path("res://captures/conquest-scratch-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	var sands := {}
	for item in core.adventures(engine, "en").adventures:
		if str(item.title) == "The Sands of Betrayal":
			sands = item
	check(not sands.is_empty(), "The Sands of Betrayal is listed")
	if sands.is_empty():
		finish(scratch)
		return
	core.open_adventure(engine, str(sands.kind), str(sands.ref), "en")
	core.enable_test_commands()
	core.command("test_money 200000")
	var temple := found_ares(core)
	check(temple.x != 99999, "a sanctuary of Ares is founded and finished (%s)" % str(temple))
	var cities: Array = core.command("cities").cities
	var theron_district := -1
	for city in cities:
		if str(city.name) == "Theron":
			theron_district = int(city.id)
	var world: Dictionary = core.command("world")
	var theron := city_named(world, "Theron")
	check(not theron.is_empty() and theron_district != -1 and bool(theron.get("can_conquer", false)), "Theron is on the map and may be conquered (%s)" % str(theron.get("relationship", "-")))
	if theron.is_empty():
		finish(scratch)
		return
	var index := int(theron.index)
	core.command("test_soldiers hoplite 40")
	core.command("test_soldiers horseman 24")
	var enlist: Dictionary = core.command("world_conquer %d" % index)
	check(enlist.get("purpose", "") == "conquer" and enlist.get("ares", {}).get("sanctuary", false) and not enlist.ares.abroad,
		"the conquest's enlisting says Ares can march with it (%s)" % str(enlist.get("ares", {})))
	check(enlist.soldiers.all(func(s): return str(s.type) != "ares"), "Ares himself is not among what may be enlisted")
	var ids := ",".join(enlist.soldiers.filter(func(s): return not bool(s.abroad)).map(func(s): return str(int(s.id))))
	var sent: Dictionary = core.command("enlist_dispatch -1 s:%s" % ids)
	var armies: Array = sent.get("armies", []).filter(func(a): return a.reason == "conquest")
	check(not sent.has("error") and armies.size() >= 1 and armies.all(func(a): return not bool(a.ares)), "the army sets out without Ares (%s)" % str(sent.get("error", "ok")))
	# Ares is asked for help while the army is on the way.
	var inspection: Dictionary = core.command("inspect %d %d" % [temple.x, temple.y])
	var asked: Dictionary = core.command("sanctuary_help %d %d %d" % [temple.x, temple.y, int(inspection.get("target_token", 0))])
	core.advance(.25)
	world = core.command("world")
	var marching: Array = world.armies.filter(func(a): return a.reason == "conquest" and bool(a.ares))
	check(marching.size() == 1, "asked for help, Ares joins the conquest; the map's army carries him (%s)" % str(asked.get("error", "ok")))
	var abroad: Dictionary = core.command("inspect %d %d" % [temple.x, temple.y]).get("monument", {})
	check(bool(abroad.get("god_abroad", false)), "his sanctuary says its god is abroad")
	var again: Dictionary = core.command("world_conquer %d" % index)
	check(bool(again.get("ares", {}).get("abroad", false)), "a second enlisting says Ares is away with another army")
	core.command("enlist_cancel")
	# The army reaches Theron: an invasion on the board, not a battle at a distance.
	core.command("speed 3")
	core.command("pause 0")
	var view := Vector2i(-1, -1)
	var soldiers_in_theron := 0
	var landed := false
	for step in 900:
		core.advance(.25)
		var state: Dictionary = core.snapshot(false)
		answer_events(core, state)
		if state.has("view_tile") and view.x == -1:
			view = Vector2i(int(state.view_tile[0]), int(state.view_tile[1]))
		if view.x != -1 and not landed:
			var full: Dictionary = core.snapshot(true)
			for walker in full.walkers:
				if str(walker.asset).contains("hoplite") or str(walker.asset).contains("horseman"):
					if district(cities, float(walker.x), float(walker.y)) == theron_district:
						soldiers_in_theron += 1
			landed = soldiers_in_theron > 0
		if kinds.has("cityConquered") or kinds.has("cityConquerFailed"):
			break
	check(view.x != -1 and district(cities, view.x, view.y) == theron_district, "the view is asked to go to Theron when the army lands (%s)" % str(view))
	check(landed, "the player's soldiers walk in Theron's district (%d)" % soldiers_in_theron)
	var ended := kinds.has("cityConquered") or kinds.has("cityConquerFailed")
	check(ended, "the engine decides the battle (%s)" % ("conquered" if kinds.has("cityConquered") else ("failed" if kinds.has("cityConquerFailed") else "undecided")))
	if kinds.has("cityConquered"):
		var owners: Array = core.command("cities").cities.filter(func(c): return int(c.id) == theron_district)
		check(not owners.is_empty() and str(owners[0].owner) == "player", "Theron becomes one of the player's cities (%s)" % str(owners))
	# Home again: the army leaves the road and Ares returns to his sanctuary.
	var home := false
	for step in 900:
		core.advance(.25)
		answer_events(core, core.snapshot(false))
		var monument: Dictionary = core.command("inspect %d %d" % [temple.x, temple.y]).get("monument", {})
		if core.command("world").armies.is_empty() and not bool(monument.get("god_abroad", true)):
			home = true
			break
	check(home, "the army comes home and Ares is back at his sanctuary")
	core.close_city()
	finish(scratch)

func finish(scratch: String) -> void:
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	print("CONQUEST_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
