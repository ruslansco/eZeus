extends SceneTree
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("CONSTRUCTION_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func spot(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var query: Dictionary = core.command("preview %s %d %d 3" % [tool, int(tile[0]), int(tile[1])])
		if query.get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	for lang in ["en", "ru"]:
		var initial: Dictionary = core.open_city(engine, save, lang)
		check(initial.has("protocol"), lang + " designated test city loads paused")
		if not initial.has("protocol"):
			quit(1)
			return
		check(not initial.undo_available, lang + " existing saved buildings cannot be undone")
		check(core.command("preview hospital 2147483647 2147483647 0").has("error"), lang + " extreme invalid coordinates are rejected safely")
		for spec in [["road", 1], ["house", 2], ["hospital", 4], ["fountain", 2], ["warehouse", 3], ["granary", 4], ["olive_press", 2], ["winery", 2], ["sculpture_studio", 2]]:
			var before: Dictionary = core.snapshot(true)
			var candidate := spot(core, before, spec[0])
			check(candidate != Vector2i(99999, 99999), lang + " " + spec[0] + " authoritative footprint found")
			if candidate == Vector2i(99999, 99999):
				continue
			var args := "%s %d %d 3" % [spec[0], candidate.x, candidate.y]
			var query: Dictionary = core.command("preview " + args)
			check(query.valid and query.tiles.size() == spec[1] * spec[1] and query.cost > 0, lang + " " + spec[0] + " complete footprint and native cost")
			var unchanged: Dictionary = core.snapshot(true)
			check(unchanged.money == before.money and unchanged.time == before.time and unchanged.buildings == before.buildings and unchanged.tiles == before.tiles, lang + " " + spec[0] + " queries do not mutate the city")
			var placed: Dictionary = core.command("build " + args)
			check(placed.get("money", -1) == before.money - query.cost and placed.get("undo_available", false), lang + " " + spec[0] + " actual cost matches query and enables undo")
			var blocked: Dictionary = core.command("preview " + args)
			check(not blocked.get("valid", true) and blocked.get("reason") == "occupied", lang + " " + spec[0] + " occupied preview is rejected")
			check(core.command("build " + args).has("error") and core.snapshot(false).money == placed.money, lang + " " + spec[0] + " failed placement does not charge or discard undo")
			var info: Dictionary = core.command("inspect %d %d" % [candidate.x, candidate.y])
			check(info.has("name") and int(info.footprint[2]) == spec[1] and int(info.footprint[3]) == spec[1], lang + " " + spec[0] + " inspector uses actual native footprint")
			if spec[0] == "house":
				check(info.has("residents") and info.has("supported_level") and info.has("missing"), lang + " house needs and population are exposed")
			if spec[0] == "hospital":
				check(info.has("employees") and int(info.max_employees) > 0, lang + " hospital employment is exposed")
			if spec[0] != "road":
				var facing := false
				for b in placed.buildings:
					if b.x == candidate.x and b.y == candidate.y:
						facing = int(b.orientation) == 3
				check(facing, lang + " " + spec[0] + " session model facing survives snapshots")
			var undone: Dictionary = core.command("undo")
			check(undone.get("money", -1) == before.money and not undone.get("undo_available", true), lang + " " + spec[0] + " undo refunds exact cost once")
			check(core.command("preview " + args).get("valid", false) and core.command("undo").has("error"), lang + " " + spec[0] + " undo removes footprint and cannot refund twice")
			core.command("build " + args)
			var money: int = core.snapshot(false).money
			var erase: Dictionary = core.command("preview demolish %d %d 0" % [candidate.x, candidate.y])
			var demolished: Dictionary = core.command("demolish %d %d 0" % [candidate.x, candidate.y])
			check(demolished.get("money", -1) == money - erase.cost and not demolished.get("undo_available", true), lang + " " + spec[0] + " demolition uses native cost and invalidates construction undo")
			check(core.command("preview " + args).get("valid", false), lang + " " + spec[0] + " demolition frees the actual footprint")

		# A native landmark must retain its original confirmation requirement.
		var full: Dictionary = core.snapshot(true)
		var landmark := Vector2i(99999, 99999)
		var protected_query := {}
		for b in full.buildings:
			var query: Dictionary = core.command("preview demolish %d %d 0" % [int(b.x), int(b.y)])
			if query.get("valid", false) and query.get("confirmation_required", false):
				landmark = Vector2i(int(b.x), int(b.y))
				protected_query = query
				break
		check(not protected_query.is_empty(), lang + " protected landmark available in test city")
		if not protected_query.is_empty():
			var money: int = core.snapshot(false).money
			check(core.command("demolish %d %d 0" % [landmark.x, landmark.y]).get("error") == "confirmation_required", lang + " landmark cannot be demolished without confirmation")
			check(core.command("demolish %d %d 1 999999" % [landmark.x, landmark.y]).get("error") == "demolition_target_changed", lang + " stale landmark confirmation is rejected")
			check(core.snapshot(false).money == money, lang + " rejected landmark actions do not charge")
			var result: Dictionary = core.command("demolish %d %d 1 %d" % [landmark.x, landmark.y, int(protected_query.target_token)])
			check(result.get("money", -1) == money - protected_query.cost, lang + " confirmed landmark follows original erase path")
		# Forest clearing also updates the terrain rather than deleting a render node.
		full = core.snapshot(true)
		var forest := Vector2i(99999, 99999)
		for tile in full.tiles:
			if int(tile[3]) != 16 and int(tile[3]) != 32:
				continue
			var query: Dictionary = core.command("preview demolish %d %d 0" % [int(tile[0]), int(tile[1])])
			if query.get("valid", false):
				forest = Vector2i(int(tile[0]), int(tile[1]))
				break
		check(forest != Vector2i(99999, 99999), lang + " owned forest available")
		if forest != Vector2i(99999, 99999):
			var cleared: Dictionary = core.command("demolish %d %d 0" % [forest.x, forest.y])
			var changed := false
			for tile in cleared.get("tile_changes", []):
				changed = changed or (int(tile[0]) == forest.x and int(tile[1]) == forest.y and int(tile[3]) == 1)
			check(changed, lang + " clearing forest changes native terrain to dry land")
		check(core.snapshot(false).time == initial.time, lang + " construction/inspection/undo do not advance paused simulation")
		var reloaded: Dictionary = core.open_city(engine, save, lang)
		check(reloaded.money == initial.money and reloaded.tiles == initial.tiles and reloaded.buildings.size() == initial.buildings.size(), lang + " reload discards all test construction and demolition")
	core.close_city()
	print("CONSTRUCTION_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
