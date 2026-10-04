extends SceneTree
# City overlays against the embedded core (headless, read-only): all 25 view modes answer, their data is consistent
# with the snapshot (every id is a building the snapshot lists, the filters match the native view-mode rules), asking
# never changes the simulation, the appeal grid covers the map and marks houses, and a new empty city answers too.
const Overlays = preload("res://scripts/overlays.gd")
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("OVERLAY_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	return core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var first := open(core)
	check(first.has("protocol"), "the designated city opens")
	var ids := {}
	var houses := {}
	for building in first.buildings:
		ids[int(building.id)] = building
		if str(building.asset).begins_with("common_house"):
			houses[int(building.id)] = building
	var walker_types := {}
	for walker in first.walkers:
		walker_types[int(walker.type)] = true
	check(Overlays.ids().size() == 25 and Overlays.MODES.has("normal"), "the catalog lists 25 overlays")
	var results := {}
	for id in Overlays.ids():
		var answer: Dictionary = core.command("overlay " + id)
		results[id] = answer
		check(not answer.has("error") and answer.kind == "overlay" and answer.mode == id, "overlay %s answers" % id)
	check(core.command("overlay nonsense").has("error") and core.command("overlay").has("error"), "an unknown or missing overlay is refused")
	# Ids and kinds.
	var stray := 0
	for id in results:
		for entry in results[id].visible:
			stray += 0 if ids.has(int(entry)) else 1
		for row in results[id].columns:
			stray += 0 if ids.has(int(row[0])) and int(row[1]) >= 0 and int(row[2]) >= 1 and int(row[2]) <= 5 else 1
		for row in results[id].supplies:
			stray += 0 if ids.has(int(row[0])) and int(row[2]) in [3, 6] else 1
	check(stray == 0, "every overlay refers only to buildings of the snapshot, with sane columns and supplies")
	check(results.normal.visible.size() == ids.size() and results.normal.columns.is_empty() and results.normal.walker_types.size() == 256, "the normal view shows every building and every walker")
	# Filters follow the native rules: housing overlays keep houses, hide other flat-less buildings.
	for id in ["water", "hygiene", "taxes", "unrest", "supplies"]:
		var shown := {}
		for entry in results[id].visible:
			shown[int(entry)] = true
		var all_houses := true
		for house in houses:
			all_houses = all_houses and shown.has(house)
		check(all_houses and shown.size() < ids.size(), "%s keeps every house and hides unrelated buildings (%d of %d)" % [id, shown.size(), ids.size()])
	check(results.roads.visible.size() < results.normal.visible.size() and results.problems.visible.size() <= results.roads.visible.size(), "roads and problems hide the buildings")
	var lived := 0
	for house in houses.values():
		lived += 1
	for id in ["water", "hygiene", "taxes", "unrest"]:
		var rows: Array = results[id].columns
		var on_houses := true
		for row in rows:
			on_houses = on_houses and houses.has(int(row[0]))
		check(rows.size() > 0 and rows.size() <= lived and on_houses, "%s draws one column per inhabited house (%d)" % [id, rows.size()])
	check(results.supplies.supplies.size() == results.water.columns.size() and results.supplies.supplies.all(func(row): return int(row[2]) == 3 or int(row[2]) == 6), "supplies lists every inhabited house with 3 goods (6 for palaces)")
	check(results.hazards.columns.size() > 0 and results.hazards.columns.all(func(row): return houses.has(int(row[0])) or ids.has(int(row[0]))), "hazards draws columns for buildings that can burn or fall")
	check(results.hygiene.columns.all(func(row): return int(row[2]) in [1, 2, 3, 4]) and results.water.columns.all(func(row): return int(row[2]) == 5), "hygiene uses the green to red tones, water the water tone")
	for id in ["actors", "athletes", "philosophers", "competitors", "all_culture", "astronomers", "scholars", "inventors", "curators", "all_science"]:
		check(results[id].columns.size() == results.water.columns.size(), "%s draws a column for each inhabited house" % id)
	# Walker kinds: the filters name real kinds.
	check(results.problems.walker_types.size() == 2 and results.water.walker_types.size() == 1 and results.hazards.walker_types.size() == 1, "problems, water and hazards keep two, one and one walker kinds")
	check(results.security.walker_types.size() > results.water.walker_types.size() and results.husbandry.walker_types.size() >= 10, "security and husbandry keep more kinds")
	# Appeal.
	var appeal: Dictionary = results.appeal.appeal
	var grid: String = appeal.grid
	var extent: Array = appeal.extent
	var painted := 0
	var house_cells := 0
	for symbol in grid:
		if symbol != ".":
			painted += 1
		if symbol >= "a" and symbol <= "j":
			house_cells += 1
	check(grid.length() == int(extent[0]) * int(extent[1]) and painted > 100 and house_cells >= houses.size(), "the appeal grid covers the map (%d painted, %d house tiles)" % [painted, house_cells])
	var origin: Array = appeal.origin
	var marked := 0
	for building in houses.values():
		var index := (int(building.y) - int(origin[1])) * int(extent[0]) + (int(building.x) - int(origin[0]))
		marked += 1 if grid.unicode_at(index) >= 97 and grid.unicode_at(index) <= 106 else 0
	check(marked == houses.size(), "every house tile of the grid carries a house rating (%d)" % marked)
	# Asking is read-only: the replay digest is the same with or without it.
	core.close_city()
	open(core)
	var plain: Dictionary = core.replay(200, 7)
	core.close_city()
	open(core)
	for id in Overlays.ids():
		core.command("overlay " + id)
	var asked: Dictionary = core.replay(200, 7)
	check(plain.digest == asked.digest, "asking for every overlay leaves the replay digest unchanged (%s)" % plain.digest)
	# A new, empty city answers too.
	core.close_city()
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var adventures: Array = core.adventures(engine, "en").adventures
	var empty := false
	for item in adventures:
		if item.title == "Open Play Sandbox":
			var state: Dictionary = core.open_adventure(engine, item.kind, item.ref, "en")
			var water: Dictionary = core.command("overlay water")
			var appeal_empty: Dictionary = core.command("overlay appeal")
			empty = not state.has("error") and water.visible.is_empty() and water.columns.is_empty() and appeal_empty.appeal.grid.length() == int(state.extent[0]) * int(state.extent[1])
	check(empty, "a new empty city answers every overlay with empty data and a full-size appeal grid")
	print("OVERLAY_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
