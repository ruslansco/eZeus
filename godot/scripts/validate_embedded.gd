extends SceneTree
var okay := true
var report := {}
func check(value: bool, description: String) -> void:
	print("EMBEDDED_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value
func _initialize() -> void:
	call_deferred("run")
# ---- the engine's own events carry words ------------------------------------------------------------------------
# The monthly summary and the two early warnings (eEvent::monthlySummary, shortageWarning, riskWarning) are raised by
# the engine, not by the game's message catalogue, so the core words them itself (presentation/eenginemessages.h) from
# the SDL view's own language tables (text/language*.txt). The checks read those tables, so the wording cannot drift.
func language_table(engine: String, lang: String) -> Dictionary:
	var table := {}
	var names := ["language.txt"]
	if lang != "en":
		names.append("language_%s.txt" % lang)
	for name in names:
		var file := FileAccess.open(engine.path_join("text").path_join(name), FileAccess.READ)
		if file == null:
			continue
		for line in file.get_as_text().split("\n"):
			var space := line.find(" \"")
			if space > 0 and line.ends_with("\"") and line.length() > space + 2:
				table[line.substr(0, space)] = line.substr(space + 2, line.length() - space - 3)
	return table

func filled(template: String, values: Dictionary) -> String:
	for token in values:
		template = template.replace(token, str(values[token]))
	return template

# The template around one placeholder (a name that is not known here): what must come before and after it.
func fits(text: String, template: String, token: String) -> bool:
	var parts := template.split(token)
	return parts.size() == 2 and text.length() > parts[0].length() + parts[1].length() and text.begins_with(parts[0]) and text.ends_with(parts[1])

func last_event(reply: Dictionary) -> Dictionary:
	var events: Array = reply.get("events", [])
	return events[events.size() - 1] if not events.is_empty() else {}

func engine_event_checks(core: RefCounted, engine: String, lang: String, building: Vector2i) -> void:
	var table := language_table(engine, lang)
	var good: String = {"en": "Olive oil", "ru": "Олив. масло"}[lang]
	core.enable_test_commands()
	var audit: Dictionary = core.command("event_texts")
	var made: Array = audit.get("engine_made", [])
	var without: Array = audit.get("without_text", [])
	var covered := true
	for name in made:
		covered = covered and not without.has(name)
	check(made.size() >= 3 and covered and not without.has("monthlySummary"), lang + " every event the engine raises itself has words in the core " + str(made))
	print("EMBEDDED_INFO ", lang, " event kinds the core sends without title and text: ", without.size(), " of ", int(audit.get("count", 0)))
	check(without.is_empty(), lang + " no event kind reaches the front end without title and text (the god, monster, hero, invasion, monument and request-reply words are in presentation/eeventwords.h; validate_events.gd checks them) " + str(without))

	# Early warnings, through the board's event path with the fields the monthly check fills in.
	var event: Dictionary = last_event(core.command("test_event shortage 2048 18 2"))
	check(event.get("title", "") == filled(table.warn_title, {"%s": good}) and event.get("text", "") == filled(table.warn_text, {"%s": good, "%n": 18, "%m": 2}), lang + " a goods shortage says what runs low and for how long: " + str(event.get("title", "")))
	check(is_informational(event), lang + " a warning only offers to be dismissed")
	event = last_event(core.command("test_event shortage 8388608 4000 1"))
	check(event.get("title", "") == table.warn_treasury_title and event.get("text", "") == filled(table.warn_treasury_text, {"%n": 4000, "%m": 1}), lang + " a falling treasury has its own words: " + str(event.get("title", "")))
	event = last_event(core.command("test_event risk 0 5"))
	check(event.get("title", "") == table.risk_fire_title0 and event.get("text", "") == filled(table.risk_fire_text, {"%n": 5}), lang + " a fire risk without a building: " + str(event.get("title", "")))
	event = last_event(core.command("test_event risk 0 5 %d %d" % [building.x, building.y]))
	check(fits(str(event.get("title", "")), table.risk_fire_title, "%b") and str(event.get("text", "")) == filled(table.risk_fire_text, {"%n": 5}), lang + " a fire risk names the worst building: " + str(event.get("title", "")))
	event = last_event(core.command("test_event risk 1 7"))
	check(event.get("title", "") == table.risk_collapse_title0, lang + " a collapse risk without a building: " + str(event.get("title", "")))
	event = last_event(core.command("test_event risk 1 7 %d %d" % [building.x, building.y]))
	check(event.get("title", "") == filled(table.risk_collapse_title, {"%n": 7}) and fits(str(event.get("text", "")), table.risk_collapse_text, "%b"), lang + " a collapse risk counts the buildings and names the worst: " + str(event.get("title", "")))
	event = last_event(core.command("test_event risk 2 31"))
	check(event.get("title", "") == filled(table.risk_unrest_title, {"%n": 31}) and event.get("text", "") == table.risk_unrest_text, lang + " rising unrest gives its percentage: " + str(event.get("title", "")))
	check(core.command("test_event risk 3 1").has("error") and core.command("test_event shortage 1").has("error") and core.command("test_event nothing").has("error"), lang + " malformed test events are refused")

	# The monthly summary, from a real month of the simulation: replay until the date reaches the next month.
	# Only a card newer than the ones already waiting counts (the earlier steps of this validator run past a month end).
	var before: Dictionary = core.snapshot(false)
	var start: Array = before.date
	var known := 0
	for entry in before.events:
		known = maxi(known, int(entry.id))
	var summary: Dictionary = {}
	var snapshot: Dictionary = {}
	var rounds := 0
	while rounds < 60 and summary.is_empty():
		rounds += 1
		core.replay(100, -1)
		snapshot = core.snapshot(false)
		for entry in snapshot.events:
			if int(entry.id) > known and fits(str(entry.title), table.summary_title, "%m"):
				summary = entry
	check(not summary.is_empty() and snapshot.date[1] != start[1], lang + " a month that ends brings its summary card (%d rounds of 100 ticks, date %s to %s)" % [rounds, str(start), str(snapshot.date)])
	if summary.is_empty():
		return
	var lines: PackedStringArray = str(summary.text).split("\n")
	var tail: String = "  \u00b7  " + table.summary_unrest + " "
	check(lines.size() == 3 and lines[0].begins_with(table.summary_population + " ") and lines[1].begins_with(table.summary_treasury + " ") and lines[2].begins_with(table.summary_food + " ") and lines[2].contains(tail) and lines[2].ends_with("%"), lang + " the summary lists population, treasury, food and unrest: " + str(summary.text).replace("\n", " | "))
	var figure := RegEx.create_from_string("^[^0-9]+ (-?\\d+) \\(([+-]?\\d+)\\)")
	var population: RegExMatch = figure.search(lines[0]) if lines.size() == 3 else null
	var treasury: RegExMatch = figure.search(lines[1]) if lines.size() == 3 else null
	var food: RegExMatch = figure.search(lines[2]) if lines.size() == 3 else null
	check(population != null and treasury != null and food != null, lang + " every figure comes with its change over the month")
	if population != null and treasury != null:
		var pop_gap := absi(int(population.get_string(1)) - int(snapshot.population))
		var money_gap := absi(int(treasury.get_string(1)) - int(snapshot.money))
		check(pop_gap <= maxi(3, int(snapshot.population) / 50) and money_gap <= maxi(1000, absi(int(snapshot.money)) / 50), lang + " the summary's population and treasury are the city's own (gaps %d and %d)" % [pop_gap, money_gap])
		check(int(population.get_string(1)) - int(population.get_string(2)) >= 0, lang + " the population change leaves a real earlier figure")
	check(is_informational(summary) and not str(summary.title).contains("onthlySummary"), lang + " the summary only offers to be dismissed, with no raw event name")

func is_informational(event: Dictionary) -> bool:
	var actions: Array = event.get("actions", [])
	return actions.size() == 1 and int(actions[0].choice) == -1

func run() -> void:
	check(ClassDB.class_exists("EZeusSimulation"), "GDExtension class registered")
	if not okay:
		quit(1)
		return
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	for lang in ["en", "ru"]:
		var state: Dictionary = core.open_city(engine, save, lang)
		var initial_money: int = state.get("money", 0)
		check(state.has("protocol") and state.get("backend") == "embedded_cpp", lang + " original save loads directly")
		if not state.has("protocol"):
			print(state)
			quit(1)
			return
		# Compare the immutable district from the reference SDL process at load time.
		if FileAccess.file_exists("res://data/test_city.json"):
			var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/test_city.json"))
			check(state.time == reference.time and state.money == reference.money and state.population == reference.population, lang + " initial clock/treasury/population match SDL reference")
			var native_tiles := {}
			for tile in state.tiles:
				native_tiles[Vector2i(int(tile[0]),int(tile[1]))] = tile
			var equal := true
			for tile in reference.tiles:
				# The embedded renderer appends native geometry observations after
				# the original six-column SDL contract. Compare that complete prefix.
				equal = equal and native_tiles.get(Vector2i(int(tile[0]),int(tile[1])),[]).slice(0, 6) == tile
			check(equal, lang + " original district terrain/height/road/placement metadata matches SDL reference")
		var diagnostic: Dictionary = core.diagnostics()
		check(not diagnostic.sdl_video_initialized and not diagnostic.sdl_audio_initialized, lang + " SDL video/audio subsystems remain off")
		check(state.tiles.size() > 1024 and state.extent[0] > 32, lang + " full map exceeds the old 32 tile crop")
		check(state.buildings.size() > 51 and state.walkers.size() > 39, lang + " buildings and walkers outside the original crop are included")
		check(state.paused and not state.running, lang + " starts paused")
		var clock: int = state.time
		for index in range(20):
			core.advance(.05)
		state = core.snapshot(false)
		check(state.time == clock and diagnostic.ticks == 0, lang + " paused tick scheduling does not advance the game clock")
		check(not state.has("tiles") and state.tile_changes.is_empty(), lang + " unchanged terrain sends no repeated full map")
		for speed in range(4):
			core.command("speed %d" % speed)
			core.command("pause 0")
			clock = state.time
			for index in range(4):
				core.advance(.05)
			state = core.snapshot(false)
			var expected: int = [24, 60, 120, 1200][speed]
			check(state.time - clock == expected, "%s native speed %d preserves exact tick increments" % [lang, speed])
			core.command("pause 1")
		check(core.command("speed 4").has("error") and core.command("pause 9").has("error"), lang + " invalid controls rejected")
		check(core.command("build road -9999 -9999 0").has("error"), lang + " invalid map placement rejected")
		core.command("speed 0"); core.command("pause 0")
		clock = state.time
		core.advance(20)
		state = core.snapshot(false)
		check(state.time - clock == 30, lang + " frame stall clamps to five ticks")
		core.command("speed 3"); core.command("pause 0")
		for index in range(40):
			core.advance(.05)
		state = core.snapshot(false)
		check(state.blocked and not state.running and not state.events.is_empty(), lang + " pending native decision pauses simulation")
		var decision: Dictionary = {}
		for entry in state.events:
			for action in entry.actions:
				if int(action.choice) == 1:
					decision = {"id":entry.id,"choice":action.choice}
		if not decision.is_empty():
			var resolved: Dictionary = core.command("event %d %d" % [decision.id,decision.choice])
			check(not resolved.has("error") and not resolved.blocked, lang + " native decision callback resumes simulation")
		else:
			check(false, lang + " native request callback is exposed")
		core.command("pause 1")
		var full: Dictionary = core.snapshot(true)
		var before: int = full.money
		for spec in [["road",1,"road"],["house",2,"common_house_0a"],["hospital",4,"hospital"],["fountain",2,"fountain"]]:
			var metadata := {}
			for tile in full.tiles:
				metadata[Vector2i(int(tile[0]),int(tile[1]))] = tile
			var candidate := Vector2i(99999,99999)
			for tile in full.tiles:
				var point := Vector2i(int(tile[0]),int(tile[1]))
				var valid := true
				for y in range(spec[1]):
					for x in range(spec[1]):
						var cell: Array = metadata.get(point+Vector2i(x,y),[])
						if cell.is_empty() or not int(cell[5]) or int(cell[4]) or cell[2] != tile[2]:
							valid = false
				if valid:
					candidate = point
					break
			check(candidate != Vector2i(99999,99999), lang + " " + spec[0] + " buildable footprint available")
			if candidate == Vector2i(99999,99999):
				continue
			var result: Dictionary = core.command("build %s %d %d 2" % [spec[0],candidate.x,candidate.y])
			var placed := not result.has("error")
			if placed:
				placed = result.money < full.money
				if spec[0] == "road":
					placed = placed and result.tile_changes.size() > 0
				else:
					var found := false
					for building in result.buildings:
						found = found or (building.asset == spec[2] and building.x == candidate.x and building.y == candidate.y and building.w == spec[1] and building.h == spec[1])
					placed = placed and found
			check(placed, lang + " " + spec[0] + " original footprint and native treasury charge")
			check(core.command("build %s %d %d 2" % [spec[0],candidate.x,candidate.y]).has("error"), lang + " " + spec[0] + " occupied footprint rejected")
			full = core.snapshot(true)

		var landmark := Vector2i(int(full.buildings[0].x), int(full.buildings[0].y))
		for building in full.buildings:
			if str(building.asset).begins_with("granary"):
				landmark = Vector2i(int(building.x), int(building.y))
		engine_event_checks(core, engine, lang, landmark)
		report[lang] = {"tiles": full.tiles.size(), "extent": full.extent, "buildings": full.buildings.size(), "walkers": full.walkers.size(), "initial_money": before, "save_money": initial_money, "diagnostics": core.diagnostics()}
		var competitor: RefCounted = ClassDB.instantiate("EZeusSimulation")
		check(competitor.open_city(engine, save, lang).get("error") == "simulation_already_owned", lang + " a second native owner is rejected")
		competitor = null
		core.close_city()
		check(core.snapshot(false).has("error"), lang + " close releases the campaign safely")
	var state: Dictionary = core.open_city(engine, save, "en")
	check(state.money == report.en.save_money, "reload discards in-memory construction and restores original treasury")
	check(core.open_city(engine, engine.path_join("Save/invalid.ez"), "en").get("error") == "designated_test_save_required", "save access is limited to designated test city")
	var file := FileAccess.open("res://captures/embedded-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"pass":okay,"results":report}, "\t"))
	core.close_city()
	print("EMBEDDED_VALIDATION ", "PASS" if okay else "FAIL")
	quit(0 if okay else 1)
