extends SceneTree
# The expansion's pyramids, monuments to the sky and shrines against the embedded core (headless, in memory): the 54 buildings of the SDL game's
# pyramids menu are in the build list with the engine's footprints, names and a model for every piece of every layout; a scenario grants each one
# (once, with the dark and light levels it asks for) and the core refuses the others; the layout is previewed centred on the pointer (a pyramid does
# not turn) with each piece lifted by the ground its level raises; founding it through the engine's own `buildPyramid` puts exactly the previewed
# pieces in the city (all 54, each in a fresh city), the ground rises under the pieces as the workers build, the inspection words the progress and what
# the monument still needs, and a finished one stands, describes itself and can be demolished (which gives its grant back). English and Russian.
var okay := true
var checks := 0

const GODS := ["aphrodite", "apollo", "ares", "artemis", "athena", "atlas", "demeter", "dionysus", "hades", "hephaestus", "hera", "hermes", "poseidon", "zeus"]
# name: [footprint width, footprint depth, English name]
const SINGLES := {
	"pyramid_modest": [3, 3, "Modest Pyramid"], "pyramid_standard": [5, 5, "Pyramid"], "pyramid_great": [7, 7, "Great Pyramid"], "pyramid_majestic": [9, 9, "Majestic Pyramid"],
	"pyramid_sky_small": [5, 5, "Small Monument to the Sky"], "pyramid_sky": [6, 6, "Monument to the Sky"], "pyramid_sky_grand": [8, 8, "Grand Monument to the Sky"],
	"pyramid_pantheon": [9, 11, "Pyramid of the Pantheon"], "pyramid_altar": [8, 8, "Altar of Olympus"], "pyramid_temple": [8, 8, "Temple of Olympus"],
	"pyramid_observatory": [9, 9, "Observatory Kosmika"], "pyramid_museum": [8, 8, "Museum Atlantika"]}
const SHRINES := {"shrine_minor_": [3, 3, "%s Minor Shrine"], "shrine_": [6, 6, "%s Shrine"], "shrine_major_": [8, 8, "%s Major Shrine"]}

func check(value: bool, message: String) -> void:
	checks += 1
	print("PYRAMID_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func has_cyrillic(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x0400 and code <= 0x04FF:
			return true
	return false

func model_ready(asset: String) -> bool:
	return FileAccess.file_exists("res://assets/models/%s.glb.import" % asset) or ResourceLoader.exists("res://assets/models/%s.glb" % asset)

func item_of(items: Array, name: String) -> Dictionary:
	for item in items:
		if str(item.name) == name:
			return item
	return {}

# Every building of the menu with its footprint: {name: [w, h, English name]}.
func all_names() -> Dictionary:
	var names := SINGLES.duplicate()
	for prefix in SHRINES:
		for god in GODS:
			names[prefix + god] = [SHRINES[prefix][0], SHRINES[prefix][1], SHRINES[prefix][2] % god.capitalize()]
	return names

# A free site (the tile under the pointer; the footprint is centred on it) beside a road, where a footprint of `size` is valid for `tool`.
func road_site(core: RefCounted, state: Dictionary, tool: String, size: Vector2i) -> Vector2i:
	var roads := {}
	for tile in state.tiles:
		if int(tile[4]) == 1:
			roads[Vector2i(int(tile[0]), int(tile[1]))] = true
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var min_x: int = int(tile[0]) - size.x / 2
		var min_y: int = int(tile[1]) - size.y / 2
		var touches := false
		for dx in range(-1, size.x + 1):
			touches = touches or roads.has(Vector2i(min_x + dx, min_y - 1)) or roads.has(Vector2i(min_x + dx, min_y + size.y))
		for dy in range(-1, size.y + 1):
			touches = touches or roads.has(Vector2i(min_x - 1, min_y + dy)) or roads.has(Vector2i(min_x + size.x, min_y + dy))
		if not touches:
			continue
		if core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

# Runs the city (answering its decisions) until the monument at `at` is finished or the steps are spent; the step it finished at, else -1.
# `seen` collects the titles of the messages that came.
func build_until_finished(core: RefCounted, at: Vector2i, steps: int, seen: Array) -> int:
	core.command("speed 3")
	core.command("pause 0")
	var started := Time.get_ticks_msec()
	for step in steps:
		if Time.get_ticks_msec() - started > 120000:
			break
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		for event in running.get("events", []):
			seen.append(str(event.title))
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		if step % 20 == 0 and bool(core.command("inspect %d %d" % [at.x, at.y]).get("monument", {}).get("finished", false)):
			core.command("pause 1")
			return step
	core.command("pause 1")
	return -1

func rect_of(piece: Dictionary) -> Rect2i:
	return Rect2i(int(piece.x), int(piece.y), int(piece.w), int(piece.h))

# What is wrong with the pieces of a plan: they must lie inside the footprint and not overlap, every one has a model.
func plan_problems(plan: Dictionary) -> Array:
	var problems: Array = []
	var footprint := Rect2i(int(plan.x), int(plan.y), int(plan.w), int(plan.h))
	var covered := {}
	for piece in plan.pieces:
		var rect := rect_of(piece)
		if not footprint.encloses(rect):
			problems.append("%s at %d,%d leaves the footprint" % [piece.asset, rect.position.x, rect.position.y])
		if not model_ready(str(piece.asset)):
			problems.append("no model for " + str(piece.asset))
		for dx in rect.size.x:
			for dy in rect.size.y:
				var tile := Vector2i(rect.position.x + dx, rect.position.y + dy)
				if covered.has(tile):
					problems.append("%s overlaps another piece at %d,%d" % [piece.asset, tile.x, tile.y])
				covered[tile] = true
		if int(piece.lift) % 4 != 0 or int(piece.lift) < 0:
			problems.append("%s is lifted %d, not by whole levels" % [piece.asset, int(piece.lift)])
	return problems

# The pieces of a snapshot inside a rectangle that carry geometry (the filler tiles of larger pieces carry none).
func pieces_in(state: Dictionary, footprint: Rect2i) -> Array:
	return state.buildings.filter(func(b): return str(b.asset) != "native_marker" and footprint.encloses(rect_of(b)))

func run_language(lang: String, engine: String) -> void:
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, save, lang)
	check(initial.has("protocol"), lang + " designated test city loads paused")
	core.replay(0, 11)
	check(core.command("test_allow shrine_minor_zeus").get("error", "") == "unsupported_command", lang + " the validators' allowance needs the validators' switch")
	core.enable_test_commands()
	var names := all_names()

	# --------------------------------------------------------------------------------- the 54 buildings of the menu
	var catalog: Dictionary = core.command("buildable")
	var items: Array = catalog.buildings.filter(func(item): return str(item.name).begins_with("pyramid_") or str(item.name).begins_with("shrine_"))
	check(items.size() == 54 and names.size() == 54, lang + " the build list has the 54 pyramids, monuments and shrines (%d)" % items.size())
	var wrong: Array = []
	for name in names:
		var item := item_of(items, name)
		if item.is_empty() or int(item.w) != int(names[name][0]) or int(item.h) != int(names[name][1]) or int(item.cost) != 0 or int(item.marble) != 0 or not model_ready(str(item.asset)):
			wrong.append(name)
	check(wrong.is_empty(), lang + " each has the engine's footprint, costs no drachmas (its materials come by cart) and has a menu picture %s" % str(wrong.slice(0, 4)))
	var named := true
	for name in names:
		var item := item_of(items, name)
		named = named and not item.is_empty() and (lang != "en" or str(item.label) == str(names[name][2])) and (lang != "ru" or has_cyrillic(str(item.label)))
	check(named, lang + " each has its own name in the core's language")
	var offered_names: Array = items.filter(func(item): return bool(item.available)).map(func(item): return str(item.name))
	check(offered_names == ["pyramid_standard"], lang + " the saved city's scenario grants one pyramid, the standard one, and no other of the 54 is offered %s" % str(offered_names))

	# -------------------------------------------------------------------------------------- every layout is previewed
	var centre := Vector2i(100, -90)
	var problems: Array = []
	var empty_plans: Array = []
	var refused := true
	var sizes := {}
	for name in names:
		var plan: Dictionary = core.command("preview %s %d %d 0" % [name, centre.x, centre.y])
		if plan.has("error") or not plan.has("pieces"):
			empty_plans.append(name)
			continue
		refused = refused and (str(plan.reason) == "building_not_available") != (name == "pyramid_standard")
		problems.append_array(plan_problems(plan).map(func(p): return name + ": " + p))
		if int(plan.w) != int(names[name][0]) or int(plan.h) != int(names[name][1]) or int(plan.x) != centre.x - int(names[name][0]) / 2 or int(plan.y) != centre.y - int(names[name][1]) / 2 or int(plan.w) * int(plan.h) != plan.tiles.size():
			problems.append(name + ": the footprint is not centred on the pointer")
		sizes[name] = plan.pieces.size()
	check(empty_plans.is_empty(), lang + " every building has a preview with its pieces %s" % str(empty_plans))
	check(problems.is_empty(), lang + " in all 54 layouts every piece lies inside the footprint, no two overlap, each has a model and a whole number of levels of lift %s" % str(problems.slice(0, 3)))
	check(refused, lang + " every pyramid the scenario does not grant is refused as not available (the granted one is judged by its site)")
	check(int(sizes.pyramid_modest) == 9 and int(sizes.shrine_minor_zeus) == 9 and int(sizes.pyramid_majestic) > int(sizes.pyramid_great) and int(sizes.pyramid_great) > int(sizes.pyramid_standard) and int(sizes.pyramid_standard) > int(sizes.pyramid_modest), lang + " the pyramids have more pieces as they are larger (%d, %d, %d, %d)" % [sizes.pyramid_modest, sizes.pyramid_standard, sizes.pyramid_great, sizes.pyramid_majestic])
	var temple_plan: Dictionary = core.command("preview pyramid_temple %d %d 0" % [centre.x, centre.y])
	var large_pieces: Dictionary = {}
	for piece in temple_plan.pieces:
		if int(piece.w) > 1:
			large_pieces[str(piece.asset)] = int(piece.w)
	check(large_pieces.get("sanctuary_temple_0", 0) == 4, lang + " the Temple of Olympus has its 4x4 temple among its pieces: %s" % str(large_pieces))
	check(core.command("preview pyramid_observatory %d %d 0" % [centre.x, centre.y]).pieces.any(func(p): return str(p.asset) == "observatory" and int(p.w) == 5) and core.command("preview pyramid_museum %d %d 0" % [centre.x, centre.y]).pieces.any(func(p): return str(p.asset) == "museum" and int(p.w) == 6) and core.command("preview pyramid_altar %d %d 0" % [centre.x, centre.y]).pieces.any(func(p): return str(p.asset) == "sanctuary_altar" and int(p.w) == 2), lang + " the observatory (5x5), the museum (6x6) and the altar (2x2) are pieces of their own monuments")
	var shrine_pieces: Array = core.command("preview shrine_zeus %d %d 0" % [centre.x, centre.y]).pieces
	var monuments: Array = shrine_pieces.filter(func(p): return str(p.asset) == "sanctuary_monument_zeus")
	check(monuments.size() == 1 and int(monuments[0].w) == 2 and int(monuments[0].lift) == 8, lang + " a shrine to Zeus carries his monument, two levels up (%s)" % str(monuments))

	# ----------------------------------------------------------------------------------------- the scenario's grant
	var allowed: Dictionary = core.command("test_allow shrine_minor_zeus")
	check(bool(item_of(allowed.buildings, "shrine_minor_zeus").available) and not bool(item_of(allowed.buildings, "shrine_zeus").available), lang + " the grant offers the one shrine and no other")
	core.command("test_allow pyramid_standard 011")
	var state: Dictionary = core.snapshot(true)
	var dark_walls: Array = core.command("preview pyramid_standard %d %d 0" % [centre.x, centre.y]).pieces.filter(func(p): return str(p.asset).begins_with("pyramid_p1_") and int(str(p.asset).get_slice("_", 2)) >= 17)
	check(dark_walls.size() >= 8, lang + " a grant with dark levels shows black marble pieces (%d on the second level)" % dark_walls.size())

	# ----------------------------------------------------------------------------------------- a shrine is founded
	var shrine_at := road_site(core, state, "shrine_minor_zeus", Vector2i(3, 3))
	check(shrine_at.x != 99999, lang + " the Zeus Minor Shrine has a free site beside a road (%s)" % str(shrine_at))
	var plan: Dictionary = core.command("preview shrine_minor_zeus %d %d 0" % [shrine_at.x, shrine_at.y])
	check(bool(plan.valid) and int(plan.w) == 3 and int(plan.h) == 3 and int(plan.x) == shrine_at.x - 1 and int(plan.cost) == 0 and plan.tiles.all(func(cell): return bool(cell[3])), lang + " the footprint is centred on the pointer and free: %s,%s %sx%s" % [str(plan.x), str(plan.y), str(plan.w), str(plan.h)])
	var statues: Array = plan.pieces.filter(func(p): return str(p.asset).begins_with("sanctuary_statue"))
	check(statues.size() == 1 and int(statues[0].lift) == 4, lang + " it shows its statue on the ground the level raises")
	var blocked: Dictionary = core.command("preview shrine_minor_zeus 83 -11 0")
	check(not bool(blocked.valid) and str(blocked.reason) != "" and str(blocked.reason) != "building_not_available", lang + " a site over buildings is refused (%s)" % str(blocked.reason))
	var money_before: int = int(state.money)
	var footprint := Rect2i(int(plan.x), int(plan.y), 3, 3)
	var built: Dictionary = core.command("build shrine_minor_zeus %d %d 0" % [shrine_at.x, shrine_at.y])
	check(not built.has("error"), lang + " the shrine is founded (%s)" % str(built.get("error", "ok")))
	var founded: Dictionary = core.snapshot(true)
	check(int(founded.money) == money_before and not bool(founded.get("undo_available", false)), lang + " it costs no drachmas and is not undoable")
	var slabs: Array = pieces_in(founded, footprint)
	check(slabs.size() == 9 and slabs.all(func(b): return str(b.asset) == "sanctuary_court_0" and int(b.get("grow", 100)) == 100), lang + " its nine pieces are foundation slabs (%d)" % slabs.size())
	check(not founded.buildings.any(func(b): return str(b.asset) == "unconverted"), lang + " nothing it founded is left without a model")
	var grant: Dictionary = core.command("buildable")
	check(not bool(item_of(grant.buildings, "shrine_minor_zeus").available), lang + " the grant is used up: it cannot be founded again")
	check(core.command("build shrine_minor_zeus %d %d 0" % [shrine_at.x, shrine_at.y]).get("error", "") == "building_not_available", lang + " a second one is refused")
	var inspection: Dictionary = core.command("inspect %d %d" % [shrine_at.x, shrine_at.y])
	var monument: Dictionary = inspection.get("monument", {})
	check(not monument.is_empty() and bool(monument.pyramid) and not bool(monument.sanctuary) and not bool(monument.finished) and int(monument.progress) == 0 and bool(inspection.can_control), lang + " the inspection of any piece is of the monument: %s" % str(monument.get("title", "-")))
	var corner: Dictionary = core.command("inspect %d %d" % [int(plan.x), int(plan.y)])
	check(corner.get("monument", {}).get("name", "") == monument.get("name", "-"), lang + " every piece of it is inspected as the same monument")
	check(int(monument.cost.marble) == 18 and int(monument.cost.orichalc) == 8 and int(monument.cost.sculpture) == 1 and int(monument.needed.marble) == 18, lang + " it says what it needs: 18 marble, 8 orichalc, 1 sculpture (%s)" % str(monument.cost))
	var lines: Array = monument.get("lines", [])
	check(lines.size() >= 2 and str(lines[0]).contains("0%"), lang + " it says how far it has come: %s" % str(lines.slice(0, 1)))
	if lang == "ru":
		check(has_cyrillic(str(lines[0])) and has_cyrillic(str(monument.title)), "ru its words are in Russian: " + str(lines[0]))
	var token: int = int(core.command("inspect %d %d" % [shrine_at.x, shrine_at.y]).target_token)
	var halted: Dictionary = core.command("monument_halt %d %d %d 1" % [shrine_at.x, shrine_at.y, token])
	check(bool(halted.monument.halted), lang + " the work can be halted")
	check(not bool(core.command("monument_halt %d %d %d 0" % [shrine_at.x, shrine_at.y, token]).monument.halted), lang + " and resumed")

	# --------------------------------------------------------------------------- the ground rises, the workers build it
	var ground_before: int = int(core.command("inspect %d %d" % [shrine_at.x, shrine_at.y]).altitude)
	core.command("test_fund %d %d" % [shrine_at.x, shrine_at.y])
	var funded: Dictionary = core.command("inspect %d %d" % [shrine_at.x, shrine_at.y]).monument
	check(int(funded.needed.marble) == 0 and int(funded.needed.orichalc) == 0 and int(funded.needed.sculpture) == 0 and not bool(funded.finished), lang + " the validators' funding brings all its materials at once, the work is still to do")
	var seen: Array = []
	var finished_at := build_until_finished(core, shrine_at, 1500, seen)
	check(finished_at >= 0, lang + " the carts and workers finish the shrine (step %d)" % finished_at)
	var done: Dictionary = core.command("inspect %d %d" % [shrine_at.x, shrine_at.y])
	var finished: Dictionary = done.monument
	check(bool(finished.finished) and int(finished.progress) == 100 and finished.lines.is_empty() and str(finished.description).length() > 30, lang + " it stands and describes itself: %s" % str(finished.description))
	if lang == "en":
		check(str(finished.description).contains("Zeus"), "en the description of a shrine names its god")
	else:
		check(has_cyrillic(str(finished.description)) and not str(finished.description).contains("[god]"), "ru the description is in Russian, with the god's name filled in")
	check(int(done.altitude) == ground_before + 4, lang + " the ground under its statue has risen a level (four steps): %d to %d" % [ground_before, int(done.altitude)])
	var after: Dictionary = core.snapshot(true)
	var standing: Array = pieces_in(after, footprint)
	check(standing.filter(func(b): return str(b.asset) == "sanctuary_statue_zeus" and int(b.get("grow", 100)) == 100 and int(b.altitude) == ground_before + 4).size() == 1 and standing.filter(func(b): return str(b.asset).begins_with("pyramid_p")).size() == 8, lang + " the finished statue and eight faces of the pyramid are in the city, the statue up on the raised ground")
	check(not standing.any(func(b): return bool(b.get("stretch", false)) or str(b.asset) == "sanctuary_court_0"), lang + " no foundation slab is left")
	check(not seen.is_empty(), lang + " the city is told as the work goes on (%s)" % str(seen.slice(0, 3)))

	# ----------------------------------------------------------------------------------------------- demolished
	var erase: Dictionary = core.command("preview demolish %d %d 0" % [shrine_at.x, shrine_at.y])
	var asked: Dictionary = core.command("demolish %d %d 0" % [shrine_at.x, shrine_at.y])
	var removed: Dictionary = asked
	if asked.get("error", "") == "confirmation_required":
		removed = core.command("demolish %d %d 1 %d" % [shrine_at.x, shrine_at.y, int(erase.target_token)])
	check(not removed.has("error"), lang + " the finished shrine can be demolished (%s)" % str(removed.get("error", "ok")))
	# The engine frees a demolished building on the next steps of the game.
	core.command("pause 0")
	for step in 10:
		core.advance(.2)
	core.command("pause 1")
	var cleared: Dictionary = core.snapshot(true)
	check(pieces_in(cleared, footprint).is_empty(), lang + " all its pieces are gone")
	check(int(core.command("inspect %d %d" % [shrine_at.x, shrine_at.y]).get("altitude", -9)) == ground_before, lang + " and the ground is level again")
	check(bool(item_of(core.command("buildable").buildings, "shrine_minor_zeus").available), lang + " its grant is given back: it can be founded again")
	core.close_city()

	# ------------------------------------------- every one of the 54 is founded exactly as previewed (each in a fresh city)
	var probe: RefCounted = ClassDB.instantiate("EZeusSimulation")
	probe.open_city(engine, save, lang)
	probe.enable_test_commands()
	probe.command("test_allow pyramid_pantheon")
	var site := road_site(probe, probe.snapshot(true), "pyramid_pantheon", Vector2i(9, 11))
	probe.close_city()
	check(site.x != 99999, lang + " a site beside a road takes the largest footprint (%s)" % str(site))
	var mismatches: Array = []
	var unfounded: Array = []
	var unmodelled: Array = []
	var founded_count := 0
	for name in names:
		var fresh: RefCounted = ClassDB.instantiate("EZeusSimulation")
		fresh.open_city(engine, save, lang)
		fresh.replay(0, 11)
		fresh.enable_test_commands()
		if name == "pyramid_modest":
			# The saved city's modest pyramid stands (its grant is used up): it is taken down first, which gives the grant back.
			var stand: Dictionary = fresh.command("preview demolish 82 6 0")
			var refusal: Dictionary = fresh.command("demolish 82 6 0")
			if refusal.get("error", "") == "confirmation_required":
				fresh.command("demolish 82 6 1 %d" % int(stand.target_token))
			fresh.command("pause 0")
			for step in 10:
				fresh.advance(.2)
			fresh.command("pause 1")
		fresh.command("test_allow " + name)
		var layout: Dictionary = fresh.command("preview %s %d %d 0" % [name, site.x, site.y])
		var made: Dictionary = fresh.command("build %s %d %d 0" % [name, site.x, site.y]) if bool(layout.get("valid", false)) else {"error": str(layout.get("reason", "?"))}
		if made.has("error"):
			unfounded.append(name + " (" + str(made.error) + ")")
			fresh.close_city()
			continue
		founded_count += 1
		var area := Rect2i(int(layout.x), int(layout.y), int(layout.w), int(layout.h))
		var planned := {}
		for piece in layout.pieces:
			planned[rect_of(piece)] = true
		var founded_rects := {}
		for piece in pieces_in(fresh.snapshot(true), area):
			founded_rects[rect_of(piece)] = true
			if str(piece.asset) == "unconverted" or not model_ready(str(piece.asset)):
				unmodelled.append(name + ": " + str(piece.asset))
		if planned.size() != founded_rects.size() or not planned.keys().all(func(rect): return founded_rects.has(rect)):
			mismatches.append("%s: %d previewed, %d founded" % [name, planned.size(), founded_rects.size()])
		fresh.close_city()
	check(unfounded.is_empty() and founded_count == 54, lang + " all 54 are founded on that site (%d) %s" % [founded_count, str(unfounded.slice(0, 3))])
	check(unmodelled.is_empty(), lang + " nothing any of them founds is without a model %s" % str(unmodelled.slice(0, 3)))
	check(mismatches.is_empty(), lang + " the pieces each one founds are exactly the pieces it previewed, in the same places and sizes %s" % str(mismatches.slice(0, 3)))

# The scenarios grant pyramids themselves (the campaign files list them with their levels): new games of the adventures the start menu lists
# offer some of them, and the offered ones are placed and founded like the validators' grants (scratch saves only).
func run_adventures(engine: String) -> void:
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	var scratch := ProjectSettings.globalize_path("res://captures/validation-pyramids-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	core.enable_test_commands()
	var listed: Array = core.adventures(engine, "en").get("adventures", [])
	var granting: Array = []
	var broken: Array = []
	var founded := ""
	for item in listed:
		var state: Dictionary = core.open_adventure(engine, str(item.kind), str(item.ref), "en")
		if state.has("error"):
			continue
		core.enable_test_commands()
		var offered: Array = core.command("buildable").buildings.filter(func(entry): return (str(entry.name).begins_with("pyramid_") or str(entry.name).begins_with("shrine_")) and bool(entry.available))
		if offered.is_empty():
			core.close_city()
			continue
		granting.append("%s (%d)" % [str(item.title), offered.size()])
		var tool := str(offered[0].name)
		var size := Vector2i(int(offered[0].w), int(offered[0].h))
		var at := road_site(core, core.snapshot(true), tool, size)
		if at.x == 99999:
			# No road yet at the start: any free site will do for the placement.
			for tile in state.tiles:
				if int(tile[5]) and not int(tile[4]) and core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
					at = Vector2i(int(tile[0]), int(tile[1]))
					break
		var made: Dictionary = core.command("build %s %d %d 0" % [tool, at.x, at.y]) if at.x != 99999 else {"error": "no_site"}
		if made.has("error"):
			broken.append("%s: %s %s" % [str(item.title), tool, str(made.error)])
		elif founded.is_empty():
			founded = "%s: %s at %s" % [str(item.title), tool, str(at)]
		core.close_city()
	check(granting.size() >= 1, "new games of the adventures offer pyramids the scenario grants (%d adventures: %s)" % [granting.size(), ", ".join(granting.slice(0, 4))])
	check(broken.is_empty(), "what an adventure grants can be founded at once %s (first: %s)" % [str(broken.slice(0, 3)), founded])
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is untouched")
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)

# A city with a pyramid half built saves and reloads to exactly the same state (scratch saves only). With --keep=<dir> the save is left there and its digest
# printed, so that tools/save_roundtrip.py can open it in the SDL game, which must reach the identical state.
func run_save(engine: String, keep: String) -> void:
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	var scratch := keep if not keep.is_empty() else ProjectSettings.globalize_path("res://captures/validation-pyramids-save-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	core.open_city(engine, designated, "en")
	core.replay(0, 11)
	core.enable_test_commands()
	var site := road_site(core, core.snapshot(true), "pyramid_standard", Vector2i(5, 5))
	var made: Dictionary = core.command("build pyramid_standard %d %d 0" % [site.x, site.y]) if site.x != 99999 else {"error": "no_site"}
	check(not made.has("error"), "save: the standard pyramid the scenario grants is founded (%s)" % str(made.get("error", site)))
	core.command("test_fund %d %d" % [site.x, site.y])
	var progress := 0
	core.command("speed 3")
	core.command("pause 0")
	for step in 600:
		core.advance(.2)
		for event in core.snapshot(false).get("events", []):
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		progress = int(core.command("inspect %d %d" % [site.x, site.y]).get("monument", {}).get("progress", 0))
		if progress >= 20:
			break
	core.command("pause 1")
	var raised: Array = core.snapshot(true).tiles.filter(func(tile): return absi(int(tile[0]) - site.x) <= 2 and absi(int(tile[1]) - site.y) <= 2 and int(tile[2]) > 0)
	check(progress >= 20 and progress < 100 and not raised.is_empty(), "save: the pyramid is partly built (%d%%) and its ground has risen (%d tiles)" % [progress, raised.size()])
	var written: Dictionary = core.save_city("pyramid-city")
	var before: Dictionary = core.replay(0, 7)
	var pieces_before: int = core.snapshot(true).buildings.size()
	core.close_city()
	var file := scratch.path_join("pyramid-city.ez")
	var reopened: Dictionary = core.open_city(engine, file, "en")
	var after: Dictionary = core.replay(0, 7)
	var inspected: Dictionary = core.command("inspect %d %d" % [site.x, site.y]).get("monument", {})
	# (A city that has run holds workers and carts in mid-action, whose state the engine does not restore digit for digit, with or without a pyramid:
	# the terrain, with the ground the pyramid has raised, must be identical, and the monument is checked below.)
	var tiles_before := str(before.sections).get_slice("tiles=", 1).get_slice(" ", 0)
	var tiles_after := str(after.sections).get_slice("tiles=", 1).get_slice(" ", 0)
	check(written.has("saved") and not reopened.has("error") and tiles_before != "" and tiles_before == tiles_after, "save: the city with the half-built pyramid reloads with the identical terrain, the risen ground included (%s)" % tiles_after)
	check(int(inspected.get("progress", -1)) == progress and bool(inspected.get("pyramid", false)) and core.snapshot(true).buildings.size() == pieces_before, "save: the reloaded pyramid is the same monument at the same progress (%d%%)" % int(inspected.get("progress", -1)))
	if not keep.is_empty():
		print("PYRAMID_DIGEST ", after.digest, " file=", file)
	core.close_city()
	check(FileAccess.get_sha256(designated) == designated_hash, "save: the designated test save is untouched")
	if keep.is_empty():
		for name in DirAccess.get_files_at(scratch):
			DirAccess.remove_absolute(scratch.path_join(name))
		DirAccess.remove_absolute(scratch)

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var only := ""
	var keep := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
		if argument.begins_with("--keep="):
			keep = argument.trim_prefix("--keep=")
	if only == "save":
		run_save(engine, keep)
		print("PYRAMID_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
		quit(0 if okay else 1)
		return
	if only != "ru":
		run_language("en", engine)
	if only != "en":
		run_language("ru", engine)
	if only != "ru":
		run_adventures(engine)
		run_save(engine, keep)
	print("PYRAMID_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
