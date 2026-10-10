extends SceneTree
# The Zeus guide's gameplay that the native engine gained for the Godot game (headless, in memory, the designated test city):
# stockpiling a good (the original Distribution tab): carts stop taking it out of storage and start again when it is released;
# the oracle of Zeus and Apollo (consulted from the finished sanctuary, silent until it is ready again);
# trireme crews (Poseidon's "Crew All": a ship without its wharf's crew takes no orders) and the navy sailing abroad with an army
# to a city the sea reaches, and coming home with it;
# Auto Defend (the original Options menu): the player's own orders wait, and the city calls its companies out against invaders.
# Run: ../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/validate_guide_parity.gd
var okay := true
var checks := 0
var core: RefCounted
var tiles: Dictionary = {}

func check(value: bool, message: String) -> void:
	checks += 1
	print("PARITY_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func page(data: Dictionary, id: String) -> Dictionary:
	for one in data.get("pages", []):
		if str(one.id) == id:
			return one
	return {}

func stockpiled(data: Dictionary, resource: int) -> bool:
	for good in page(data, "storage").get("goods", []):
		if int(good.resource) == resource:
			return bool(good.get("stockpiled", false))
	return false

# Answers the campaign's own decisions with their first choice.
func answer_events(state: Dictionary) -> void:
	for event in state.get("events", []):
		var choices: Array = event.get("actions", [])
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

# Runs the city on (about four game days a step) until the condition holds; false when it never does.
func run_until(condition: Callable, steps := 200) -> bool:
	for step in steps:
		core.advance(.25)
		answer_events(core.snapshot(false))
		if condition.call():
			return true
	return false

# A free site for a building next to a road (a sanctuary's carts and a wharf's must reach it), or Vector2i(99999, 99999).
func site_for(name: String, near_road := true) -> Vector2i:
	var roads := {}
	for point in tiles:
		if int(tiles[point][4]) == 1:
			roads[point] = true
	for point in tiles:
		if not int(tiles[point][5]) or int(tiles[point][4]):
			continue
		if near_road:
			var touches := false
			for dx in range(-6, 6):
				touches = touches or roads.has(Vector2i(point.x + dx, point.y - 4)) or roads.has(Vector2i(point.x + dx, point.y + 3))
			if not touches:
				continue
		if core.command("preview %s %d %d 0" % [name, point.x, point.y]).get("valid", false):
			return point
	return Vector2i(99999, 99999)

func run() -> void:
	core = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "the designated test city loads paused")
	for tile in initial.get("tiles", []):
		tiles[Vector2i(int(tile[0]), int(tile[1]))] = tile
	core.enable_test_commands()
	core.command("speed 3")

	# ------------------------------------------------------------------------------------ stockpiling
	var data: Dictionary = core.command("city_data")
	var goods: Array = page(data, "storage").get("goods", [])
	check(goods.size() == 20 and goods.all(func(g): return g.has("stockpiled") and not bool(g.stockpiled)), "the storage page lists the twenty storable goods, none stockpiled (%d)" % goods.size())
	data = core.command("stockpile 512 1")
	check(data.get("kind", "") == "city_data" and stockpiled(data, 512) and not stockpiled(data, 64), "stockpiling olives marks them, and only them")
	check(core.command("stockpile 576 1").get("error", "") == "invalid_city_setting" and core.command("stockpile 1048576 1").get("error", "") == "invalid_city_setting" and core.command("stockpile 512 2").get("error", "") == "invalid_city_setting", "two goods at once, a horse and a flag that is neither 0 nor 1 are refused")
	data = core.command("stockpile 512 0")
	check(not stockpiled(data, 512), "and releasing them clears the mark")
	# A workshop waiting for its input: while the input is stockpiled no cart brings it; released, the carts bring it again.
	var workshop := {}
	for building in initial.get("buildings", []):
		var inspected: Dictionary = core.command("inspect %d %d" % [int(building.x), int(building.y)])
		var production: Dictionary = inspected.get("production", {})
		if production.has("input") and int(production.input.resource) & ((1 << 20) - 1) and int(production.input.count) < int(production.input.capacity) and str(production.status) in ["operational", "waiting_input"]:
			workshop = {"x": int(building.x), "y": int(building.y), "resource": int(production.input.resource), "count": int(production.input.count)}
			break
	if workshop.is_empty():
		print("PARITY_NOTE no staffed workshop waits for an input in the test city; the cart check is skipped")
	else:
		core.command("test_stock %d 32" % workshop.resource)
		core.command("stockpile %d 1" % workshop.resource)
		core.command("pause 0")
		# A cart already loaded, or already sent to a store, finishes its errand: give those a few days first.
		for step in 12:
			core.advance(.25)
			answer_events(core.snapshot(false))
		workshop.count = int(core.command("inspect %d %d" % [workshop.x, workshop.y]).production.input.count)
		var watch := {"most": int(workshop.count)}
		for step in 60:
			core.advance(.25)
			answer_events(core.snapshot(false))
			var now := int(core.command("inspect %d %d" % [workshop.x, workshop.y]).production.input.count)
			watch.most = maxi(int(watch.most), now)
		check(int(watch.most) <= int(workshop.count), "while %s is stockpiled no cart brings it to the workshop at %d,%d (it held %d, at most %d)" % [str(workshop.resource), workshop.x, workshop.y, workshop.count, int(watch.most)])
		var low := int(core.command("inspect %d %d" % [workshop.x, workshop.y]).production.input.count)
		core.command("stockpile %d 0" % workshop.resource)
		var refilled := run_until(func(): return int(core.command("inspect %d %d" % [workshop.x, workshop.y]).production.input.count) > low, 240)
		check(refilled, "released, the carts bring it again")
		core.command("pause 1")

	# ------------------------------------------------------------------------------------ the oracle
	core.command("test_allow temple_apollo")
	core.command("test_stock 32768 64")    # marble for the sanctuary's base
	var site := site_for("temple_apollo", false)
	check(site.x != 99999, "a site for the Oracle of Apollo")
	if site.x != 99999:
		var founded: Dictionary = core.command("build temple_apollo %d %d 0" % [site.x, site.y])
		check(not founded.has("error"), "the Oracle of Apollo is founded (%s)" % str(founded.get("error", "ok")))
		core.command("test_complete %d %d" % [site.x, site.y])
		var temple: Dictionary = core.command("inspect %d %d" % [site.x, site.y])
		var monument: Dictionary = temple.get("monument", {})
		check(bool(monument.get("finished", false)) and bool(monument.get("oracle", false)) and float(monument.get("oracle_fraction", 0.0)) >= 1.0, "the finished sanctuary keeps an oracle, ready to be consulted")
		var answer: Dictionary = core.command("oracle %d %d %d" % [site.x, site.y, int(temple.get("target_token", 0))])
		var said: Dictionary = answer.get("oracle_answer", {}) if answer.get("oracle_answer") is Dictionary else {}
		check(bool(said.get("granted", false)) and str(said.get("kind", "")) in ["calm", "invasion", "god_attack", "monster", "request", "troops", "gift", "quest", "disaster"], "the oracle answers with a prophecy: %s" % str(said))
		check(str(said.get("kind", "")) == "calm" or (int(said.get("months", 0)) >= 1 and int(said.get("months", 0)) <= 25), "the prophecy says when, within two years")
		temple = core.command("inspect %d %d" % [site.x, site.y])
		answer = core.command("oracle %d %d %d" % [site.x, site.y, int(temple.get("target_token", 0))])
		said = answer.get("oracle_answer", {}) if answer.get("oracle_answer") is Dictionary else {}
		check(not bool(said.get("granted", true)) and int(said.get("ready", 100)) < 100, "asked again at once, it is silent (%d%% ready)" % int(said.get("ready", -1)))
		check(core.command("oracle %d %d 1" % [site.x, site.y]).get("error", "") == "inspection_target_changed", "a stale inspection is refused")

	# ------------------------------------------------------------------------------------ trireme crews and the navy
	var wharf := Vector2i(99999, 99999)
	for point in tiles:
		if core.command("preview trireme_wharf %d %d 0" % [point.x, point.y]).get("valid", false):
			wharf = point
			break
	check(wharf.x != 99999, "a shore site for a trireme wharf")
	if wharf.x != 99999:
		core.command("build trireme_wharf %d %d 0" % [wharf.x, wharf.y])
		core.command("set_priority 7 5")
		core.replay(200, 7)
		core.command("test_trireme %d %d" % [wharf.x + 1, wharf.y + 1])
		var navy: Dictionary = page(core.command("city_data"), "military").get("navy", {})
		check(int(navy.get("wharves", 0)) >= 1 and int(navy.get("crewed", 0)) >= 1 and int(navy.get("triremes", 0)) >= 1, "the military page counts the wharf, its crew and its trireme: %s" % str(navy))
		var ships: Array = core.snapshot(true).walkers.filter(func(w): return w.asset == "trireme" and bool(w.get("own", false)))
		check(not ships.is_empty() and ships.any(func(w): return bool(w.selectable)), "the crewed trireme takes orders")
		navy = page(core.command("crew_all 0"), "military").get("navy", {})
		ships = core.snapshot(true).walkers.filter(func(w): return w.asset == "trireme" and bool(w.get("own", false)))
		check(int(navy.get("crewed", -1)) == 0 and not ships.is_empty() and ships.all(func(w): return not bool(w.selectable)), "sending every crew home leaves the triremes without orders")
		if not ships.is_empty():
			check(core.command("trireme_move %d %d %d" % [wharf.x, wharf.y, int(ships[0].id)]).get("error", "") == "no_trireme", "an order to a ship without a crew is refused")
		core.command("crew_all 1")
		core.command("pause 0")
		var manned := run_until(func(): return int(page(core.command("city_data"), "military").navy.crewed) >= 1, 120)
		check(manned, "Crew All calls the crews back")
		core.command("pause 1")
		# Enlisting: the manned triremes are offered; a city the sea reaches may be sent them.
		core.command("test_soldiers hoplite 24")
		var world: Dictionary = core.command("world")
		var target := -1
		var listed := false
		for candidate in world.cities:
			if bool(candidate.get("current", false)) or not bool(candidate.get("can_raid", false)):
				continue
			var enlist: Dictionary = core.command("world_raid %d" % int(candidate.index))
			if enlist.get("kind", "") != "enlist":
				continue
			listed = listed or not enlist.get("triremes", []).is_empty()
			if enlist.get("triremes", []).any(func(t): return bool(t.reachable)):
				target = int(candidate.index)
				core.command("enlist_cancel")
				break
			if not enlist.get("triremes", []).is_empty():
				check(core.command("enlist_dispatch -1 t:%d" % int(enlist.triremes[0].index)).get("error", "") == "not_by_sea", "a city the sea does not reach cannot be sent ships")
			core.command("enlist_cancel")
		check(listed, "the Enlist Forces session lists the manned trireme")
		if target < 0:
			# The test world reaches nothing by sea: let the first ally that may be raided be a port, as a sea-trade city is.
			for candidate in world.cities:
				if target < 0 and not bool(candidate.get("current", false)) and bool(candidate.get("can_raid", false)):
					target = int(candidate.index)
			if target >= 0:
				core.command("test_sea %d 1" % target)
		if target < 0:
			print("PARITY_NOTE no city of the test world may be raided; the voyage check is skipped")
		else:
			core.command("test_troops %d 5" % target)
			var enlist: Dictionary = core.command("world_raid %d" % target)
			var ids := ",".join(enlist.soldiers.filter(func(s): return not bool(s.abroad)).map(func(s): return str(int(s.id))))
			var ship: Dictionary = enlist.triremes.filter(func(t): return bool(t.reachable))[0]
			var sent: Dictionary = core.command("enlist_dispatch -1 s:%s t:%d" % [ids, int(ship.index)]) if ids != "" else core.command("enlist_dispatch -1 t:%d" % int(ship.index))
			check(not sent.has("error"), "the army sails with its trireme (%s)" % str(sent.get("error", "ok")))
			core.command("pause 0")
			var away := run_until(func(): return int(page(core.command("city_data"), "military").navy.abroad) >= 1, 40)
			check(away, "the trireme is abroad with the army")
			var home := run_until(func(): return core.command("world").armies.is_empty() and int(page(core.command("city_data"), "military").navy.abroad) == 0, 700)
			check(home, "and it comes home with the army (or is lost with its share of the fallen)")
			core.command("pause 1")

	# ------------------------------------------------------------------------------------ Auto Defend
	# Every company home first (an army back from abroad walks in from the edge of the map).
	core.command("test_soldiers hoplite 16")
	core.command("army_home")
	core.command("pause 0")
	var settled := run_until(func(): return core.command("army").banners.all(func(b): return bool(b.home) and not bool(b.abroad)), 300)
	core.command("pause 1")
	check(settled, "the companies are home before the test")
	data = core.command("auto_defend 1")
	check(bool(page(data, "military").get("auto_defend", false)) and bool(core.command("army").get("auto_defend", false)), "Auto Defend is on, in the military page and the army")
	var army: Dictionary = core.command("army")
	check(core.command("army_call").get("error", "") == "auto_defend", "the player's own call to arms waits while it is on")
	if not army.banners.is_empty():
		var first: Dictionary = army.banners[0]
		check(core.command("banner_move %d %d %d" % [int(first.id), int(first.x), int(first.y)]).get("error", "") == "auto_defend", "and so does a banner's move")
	var invaded: Dictionary = core.command("test_invasion greek 6 0 0")
	check(not invaded.has("error"), "invaders land (%s)" % str(invaded.get("error", "ok")))
	core.command("pause 0")
	var called := run_until(func(): return core.command("army").banners.any(func(b): return not bool(b.home) and not bool(b.abroad)), 120)
	check(called, "the city calls its companies out against them by itself")
	core.command("pause 1")
	data = core.command("auto_defend 0")
	check(not bool(page(data, "military").get("auto_defend", true)) and not core.command("army_call").has("error"), "turned off, the companies follow the player's orders again")

	core.close_city()
	print("PARITY_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
