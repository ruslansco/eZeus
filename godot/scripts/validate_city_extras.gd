extends SceneTree
# The SDL remaster's extras in the core (headless, in memory; the designated save is never written): the City History record
# (`city_history`), the City Advisor's ranked problems (`city_advisor`), the Trade Summary's lines (`trade_summary`), the house
# card (`house_card`) and walker route editing (`route_begin`, `route_toggle`, `route_both`, `route_clear`, `route_restore`,
# `route_end`), each worded in the game's language by the same engine code as the SDL windows.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("CITY_EXTRAS_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	core.enable_test_commands()
	return opened

func cells(points: Array) -> Array:
	return points.map(func(p): return Vector2i(int(p[0]), int(p[1])))

func russian(text: String) -> bool:
	for index in text.length():
		if text.unicode_at(index) >= 0x400 and text.unicode_at(index) <= 0x4ff:
			return true
	return false

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		var state: Dictionary = open(core, lang)
		check(state.has("protocol"), lang + " designated test city loads")
		# City History
		var history: Dictionary = core.command("city_history")
		check(history.get("kind", "") == "city_history" and history.series.size() == 6 and history.ranges.size() == 3, lang + " the history names six series and three ranges")
		var samples: Array = history.get("samples", [])
		check(samples.all(func(s): return s.values.size() == 6 and not str(s.label).is_empty()), lang + " every month has six values and a name (%d months)" % samples.size())
		var ordered := true
		for index in range(1, samples.size()):
			ordered = ordered and int(samples[index].month) > int(samples[index - 1].month)
		check(ordered, lang + " the months run in order")
		if lang == "ru":
			check(russian(str(history.title)) and russian(str(history.series[0].label)), "ru the history is worded in Russian (%s)" % history.title)
		# City Advisor
		var advisor: Dictionary = core.command("city_advisor")
		var advice: Array = advisor.get("advice", [])
		check(advisor.get("kind", "") == "city_advisor" and advice.size() >= 1 and advice.size() <= 7, lang + " the advisor lists one to seven items (%d)" % advice.size())
		var ranked := true
		for index in range(1, advice.size()):
			ranked = ranked and int(advice[index].severity) <= int(advice[index - 1].severity)
		check(ranked, lang + " the most serious come first: %s" % str(advice.map(func(a): return [a.key, a.severity])))
		check(advice.all(func(a): return not str(a.title).is_empty() and a.places.all(func(p): return p.size() == 2)), lang + " each item has a title and its places are tiles")
		if lang == "ru":
			check(russian(str(advisor.go)) and russian(str(advice[0].title)), "ru the advisor speaks Russian (%s)" % advice[0].title)
		# Trade Summary
		var trade: Dictionary = core.command("trade_summary")
		var lines: Array = trade.get("lines", [])
		var headers: Array = lines.filter(func(l): return bool(l.header))
		check(trade.get("kind", "") == "trade_summary" and headers.size() == 2, lang + " the trade summary has its two sections (%d lines)" % lines.size())
		var tones := ["text", "dim", "green", "red", "amber", "gold", "label"]
		check(lines.all(func(l): return str(l.left_tone) in tones and str(l.right_tone) in tones), lang + " every line has known tones")
		check(lines.any(func(l): return int(l.resource) > 0), lang + " goods in storage are listed with their resource")
		# House card: the first inhabited house.
		var house := {}
		var route_building := {}
		for building in state.get("buildings", []):
			if house.is_empty():
				var card: Dictionary = core.command("house_card %d %d" % [int(building.x), int(building.y)])
				if bool(card.get("valid", false)):
					house = card
			if route_building.is_empty():
				var seen: Dictionary = core.command("inspect %d %d" % [int(building.x), int(building.y)])
				if seen.has("route"):
					route_building = seen
			if not house.is_empty() and not route_building.is_empty():
				break
		check(not house.is_empty() and not str(house.name).is_empty() and int(house.people) > 0 and int(house.levels) >= 5, lang + " a house's card names its level and residents (%s, %s)" % [house.get("name", ""), house.get("residents", "")])
		if not house.is_empty():
			var met_first := true
			var seen_met := false
			for item in house.lines:
				if bool(item.met):
					seen_met = true
				elif seen_met:
					met_first = false
			check(met_first and not str(house.status).is_empty(), lang + " the card says what comes next, missing needs first (%s)" % house.status)
		check(not bool(core.command("house_card 0 0").get("valid", true)), lang + " a tile without a house has no card")
		# Walker routes
		check(not route_building.is_empty(), lang + " an inspected walker building offers route editing (%s)" % route_building.get("name", ""))
		if route_building.is_empty():
			core.close_city()
			continue
		var x := int(route_building.x)
		var y := int(route_building.y)
		check(core.command("route_begin %d %d %d" % [x, y, int(route_building.target_token) + 1]).get("error", "") == "inspection_target_changed", lang + " a stale inspector cannot edit a route")
		var route: Dictionary = core.command("route_begin %d %d %d" % [x, y, int(route_building.target_token)])
		check(bool(route.get("active", false)) and route.get("guides", []).size() == int(route_building.route.guides), lang + " editing begins with the building's own guides (%d)" % route.get("guides", []).size())
		check(bool(core.command("inspect %d %d" % [x, y]).route.editing), lang + " the inspector says the route is being edited")
		# Road tiles near the building, from the snapshot's road column.
		var roads: Array = []
		var centre := Vector2(float(route.centre[0]), float(route.centre[1]))
		for tile in state.tiles:
			var away := Vector2(float(tile[0]), float(tile[1])).distance_to(centre)
			if int(tile[4]) and away >= 3.0 and away <= 9.0:
				roads.append(Vector2i(int(tile[0]), int(tile[1])))
		roads.sort_custom(func(a, b): return Vector2(a).distance_to(centre) > Vector2(b).distance_to(centre))
		check(roads.size() >= 2, lang + " roads near the building (%d)" % roads.size())
		var not_road := Vector2i(-1, -1)
		for tile in state.tiles:
			if int(tile[5]) and not int(tile[4]) and Vector2(float(tile[0]), float(tile[1])).distance_to(centre) < 12.0:
				not_road = Vector2i(int(tile[0]), int(tile[1]))
				break
		core.command("route_clear")
		if roads.size() >= 2:
			var added: Dictionary = core.command("route_toggle %d %d" % [roads[0].x, roads[0].y])
			added = core.command("route_toggle %d %d" % [roads[1].x, roads[1].y])
			check(cells(added.guides) == [roads[0], roads[1]], lang + " two road tiles become the guides, in order (%s)" % str(added.guides))
			# The path finder runs on the board's threads: let the city run until the walk appears.
			var walked: Dictionary = added
			for step in 60:
				core.advance(0.1)
				walked = core.command("route")
				if not walked.path.is_empty():
					break
			check(not walked.path.is_empty() and walked.path.all(func(p): return p.size() == 2), lang + " the walkers' walk follows the guides (%d tiles)" % walked.path.size())
			var both: Dictionary = core.command("route_both")
			check(bool(both.both), lang + " both directions turns on")
			var removed: Dictionary = core.command("route_toggle %d %d" % [roads[0].x, roads[0].y])
			check(cells(removed.guides) == [roads[1]], lang + " a click on a guide takes it away")
		if not_road.x >= 0:
			check(core.command("route_toggle %d %d" % [not_road.x, not_road.y]).get("error", "") == "route_needs_road", lang + " a guide must be on a road")
		var restored: Dictionary = core.command("route_restore")
		check(restored.guides.size() == int(route_building.route.guides), lang + " restore brings back the guides it had")
		core.command("route_both")
		var ended: Dictionary = core.command("route_end")
		check(not bool(ended.active) and core.command("route_clear").get("error", "") == "no_route", lang + " editing ends")
		core.close_city()
	print("CITY_EXTRAS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
