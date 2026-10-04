extends SceneTree
# The gods' sanctuaries against the embedded core (headless, in memory): the fourteen sanctuaries are in the build list with their sizes,
# marble and names (in the core's language) and every piece of every layout has a model; the scenario's limit and the marble rule are the
# engine's; a sanctuary is previewed (footprint centred on the pointer, turned by a quarter, the pieces it will have) and founded through
# the engine's own `buildSanctuary`; its pieces appear as foundations and rise as the workers build, the inspection words the progress and
# what is still needed (and halting the work works), the carts and workers finish it, the god comes, and the finished sanctuary's god is
# asked for help; the mythology page lists it, a hero's requirement for it is met, and a monster shows up in the page. English and Russian.
var okay := true
var checks := 0

const GODS := ["aphrodite", "apollo", "ares", "artemis", "athena", "atlas", "demeter", "dionysus", "hades", "hephaestus", "hera", "hermes", "poseidon", "zeus"]
const NAMES_EN := {"aphrodite": "Aphrodite's Haven", "apollo": "Oracle of Apollo", "ares": "Ares' Fortress", "artemis": "Artemis' Menagerie", "athena": "Arbor of Athena", "atlas": "Pillar of Atlas", "demeter": "Garden of Demeter", "dionysus": "Grove of Dionysus", "hades": "Gates of Hades", "hephaestus": "Forge of Hephaestus", "hera": "Orchard of Hera", "hermes": "Hermes' Refuge", "poseidon": "Promontory of Poseidon", "zeus": "Zeus' Stronghold"}

func check(value: bool, message: String) -> void:
	checks += 1
	print("SANCT_CHECK ", "PASS " if value else "FAIL ", message)
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

# A free site whose footprint touches a road (the carts must reach the monument), as the engine's rules ask.
func road_site(core: RefCounted, state: Dictionary, tool: String, orientation := 0) -> Vector2i:
	var size := Vector2i(4, 4)
	for item in core.command("buildable").buildings:
		if str(item.name) == tool:
			size = Vector2i(int(item.w), int(item.h))
	if orientation % 2 == 1:
		size = Vector2i(size.y, size.x)
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
		if core.command("preview %s %d %d %d" % [tool, int(tile[0]), int(tile[1]), orientation]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

# Runs the city (answering its decisions) until the monument at `at` is finished or the steps are spent; the step it finished at, else -1.
func build_until_finished(core: RefCounted, at: Vector2i, steps: int) -> int:
	core.command("speed 3")
	core.command("pause 0")
	var started := Time.get_ticks_msec()
	for step in steps:
		if Time.get_ticks_msec() - started > 90000:
			break
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		for event in running.get("events", []):
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		if step % 20 == 0 and bool(core.command("inspect %d %d" % [at.x, at.y]).get("monument", {}).get("finished", false)):
			core.command("pause 1")
			return step
	core.command("pause 1")
	return -1

# Atalanta's hall of the saved city asks for a sanctuary to Artemis (hers is not finished when the city is loaded): that requirement.
func artemis_requirement(core: RefCounted) -> Dictionary:
	var hall: Dictionary = core.command("inspect 92 -7").get("hall", {})
	for requirement in hall.get("requirements", []):
		if str(requirement.text).to_lower().contains("artemis") or str(requirement.text).contains("Артемид"):
			return requirement
	return {}

func pieces_of(state: Dictionary, prefix: String) -> Array:
	return state.buildings.filter(func(b): return str(b.asset).begins_with(prefix))

# ---- the sanctuary faces its front --------------------------------------------------------------------------------------------------
# The temple, the gods' statues and the monument all look to the front of the rectangle, where the temple's entrance is: the end of the long
# axis toward which the yard, the monument and the altar lie. The models are authored looking one way (the temple's pediment toward tile +x for
# pieces 0 and 2 and +y for 1 and 3; statues and monuments toward +y) and the snapshot turns each by quarter turns (`orientation`), which take
# +x to +y. The front is worked out here from the geometry (from the temple toward the monument), not from the core's own rule.
func turn(direction: Vector2i, quarter_turns: int) -> Vector2i:
	for step in posmod(quarter_turns, 4):
		direction = Vector2i(-direction.y, direction.x)
	return direction

func authored_facing(asset: String) -> Vector2i:
	if asset.begins_with("sanctuary_temple_"):
		return Vector2i(1, 0) if int(asset.get_slice("_", 2)) % 2 == 0 else Vector2i(0, 1)
	return Vector2i(0, 1)

func piece_centre(piece: Dictionary) -> Vector2:
	return Vector2(float(piece.x) + float(piece.w) * .5, float(piece.y) + float(piece.h) * .5)

# What is wrong with the facing of the pieces of one sanctuary; empty when nothing is. A temple of two pieces has its complete half (pieces 0 and 1)
# in front and its extension (2 and 3) behind it, so its front is from the extension toward the complete half (this is also where the temple's
# pediment must look). A temple of one piece has the yard, the monuments and the altar in front of it: the front is toward the monuments. (Atlas and
# Hera put their monuments beside the temple, which is why the two-piece rule comes first.)
func facing_problems(pieces: Array) -> Array:
	var temples: Array = pieces.filter(func(p): return str(p.asset).begins_with("sanctuary_temple_"))
	var monuments: Array = pieces.filter(func(p): return str(p.asset).begins_with("sanctuary_monument_"))
	if temples.is_empty() or monuments.is_empty():
		return ["a sanctuary needs a temple and a monument (%d, %d)" % [temples.size(), monuments.size()]]
	var whole: Array = temples.filter(func(p): return int(str(p.asset).get_slice("_", 2)) < 2)
	var behind: Array = temples.filter(func(p): return int(str(p.asset).get_slice("_", 2)) >= 2)
	var toward := Vector2.ZERO
	if not behind.is_empty() and not whole.is_empty():
		toward = piece_centre(whole[0]) - piece_centre(behind[0])
	else:
		var middle := Vector2.ZERO
		for temple in temples:
			middle += piece_centre(temple)
		middle /= float(temples.size())
		var yard := Vector2.ZERO
		for monument in monuments:
			yard += piece_centre(monument)
		yard /= float(monuments.size())
		toward = yard - middle
	var front := Vector2i(1 if toward.x > 0 else -1, 0) if absf(toward.x) > absf(toward.y) else Vector2i(0, 1 if toward.y > 0 else -1)
	var problems: Array = []
	for piece in pieces:
		var asset := str(piece.asset)
		if asset.begins_with("sanctuary_temple_") or asset.begins_with("sanctuary_statue_") or asset.begins_with("sanctuary_monument_"):
			var looks := turn(authored_facing(asset), int(piece.get("orientation", 0)))
			if looks != front:
				problems.append("%s at %d,%d looks %s, not %s" % [asset, int(piece.x), int(piece.y), str(looks), str(front)])
	return problems

# The built sanctuaries of a snapshot: how many were checked and what is wrong with them.
func built_facing(buildings: Array) -> Dictionary:
	var problems: Array = []
	var checked := 0
	for monument in buildings.filter(func(b): return str(b.asset).begins_with("sanctuary_monument_")):
		var near: Array = buildings.filter(func(b): return str(b.asset).begins_with("sanctuary_") and not str(b.asset).begins_with("sanctuary_court_") and piece_centre(b).distance_to(piece_centre(monument)) < 16.0)
		var found := facing_problems(near)
		problems.append_array(found)
		checked += 1
	return {"checked": checked, "problems": problems}

func run_language(lang: String, engine: String) -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	check(initial.has("protocol"), lang + " designated test city loads paused")
	core.replay(0, 11)
	check(core.command("test_allow temple_hermes").get("error", "") == "unsupported_command", lang + " the validators' allowance needs the validators' switch")
	core.enable_test_commands()

	# ---------------------------------------------------------------------------------------- the fourteen sanctuaries
	var catalog: Dictionary = core.command("buildable")
	var items: Array = catalog.buildings
	var temples: Array = items.filter(func(item): return str(item.name).begins_with("temple_"))
	check(temples.size() == 14 and temples.all(func(item): return int(item.w) >= 10 and int(item.h) >= 6 and int(item.marble) >= 8 and int(item.cost) >= 400 and model_ready(str(item.asset))), lang + " fourteen sanctuaries are listed with their footprint, drachmas, marble and a model")
	var named := true
	for god in GODS:
		var item := item_of(items, "temple_" + god)
		named = named and not item.is_empty() and (lang != "en" or str(item.label) == NAMES_EN[god]) and (lang != "ru" or has_cyrillic(str(item.label)))
	check(named, lang + " each has its own name in the core's language")
	check(temples.all(func(item): return not bool(item.available)) and int(catalog.sanctuaries.built) == 2 and int(catalog.sanctuaries.max) == 2, lang + " the test city is offered none and has its two sanctuaries already: %s" % str(catalog.sanctuaries))
	var centre := Vector2i(100, -90)
	var missing: Array = []
	var shapes := true
	for god in GODS:
		var plan: Dictionary = core.command("preview temple_%s %d %d 0" % [god, centre.x, centre.y])
		var turned: Dictionary = core.command("preview temple_%s %d %d 1" % [god, centre.x, centre.y])
		for piece in plan.get("pieces", []):
			if not model_ready(str(piece.asset)) and not missing.has(str(piece.asset)):
				missing.append(str(piece.asset))
		shapes = shapes and not plan.has("error") and plan.pieces.size() >= 8 and int(turned.w) == int(plan.h) and int(turned.h) == int(plan.w) and int(plan.w) * int(plan.h) == plan.tiles.size()
	check(missing.is_empty(), lang + " every piece of every sanctuary has a model %s" % str(missing))
	check(shapes, lang + " a preview lists the pieces and every tile of the footprint, and a quarter turn swaps its sides")
	var unfaced: Array = []
	for god in GODS:
		for quarter in [0, 1]:
			var layout: Dictionary = core.command("preview temple_%s %d %d %d" % [god, centre.x, centre.y, quarter])
			var found := facing_problems(layout.get("pieces", []))
			if not found.is_empty():
				unfaced.append("%s turned %d: %s" % [god, quarter, str(found.slice(0, 2))])
	check(unfaced.is_empty(), lang + " in all 28 layouts (unturned and turned) the temple and every god look to the front, where the monument lies %s" % str(unfaced.slice(0, 2)))
	var altar_plain := true
	for god in GODS:
		for piece in core.command("preview temple_%s %d %d 0" % [god, centre.x, centre.y]).pieces:
			if str(piece.asset) == "sanctuary_altar" or str(piece.asset).begins_with("sanctuary_court_"):
				altar_plain = altar_plain and int(piece.orientation) == 0
	check(altar_plain, lang + " the altar and the paving keep their authored facing")
	var standing := built_facing(initial.buildings)
	check(standing.checked == 2 and standing.problems.is_empty(), lang + " the two sanctuaries of the saved city (built turned) face their front %s" % str(standing.problems.slice(0, 2)))
	check(core.command("preview temple_dionysus %d %d 0" % [centre.x, centre.y]).get("reason", "") == "building_not_available", lang + " a sanctuary the scenario does not offer cannot be placed")

	# ------------------------------------------------------------------------- the scenario's limit and the marble
	core.command("test_allow temple_hermes")
	var allowed: Dictionary = core.command("test_allow temple_dionysus")
	check(bool(item_of(allowed.buildings, "temple_hermes").available) and bool(item_of(allowed.buildings, "temple_dionysus").available) and int(allowed.sanctuaries.max) == 3, lang + " the allowance offers both and lets one more in")
	var state: Dictionary = core.snapshot(true)
	var dionysus_at := road_site(core, state, "temple_dionysus")
	check(dionysus_at.x != 99999, lang + " the Grove of Dionysus has a free site beside a road (%s)" % str(dionysus_at))
	var plan: Dictionary = core.command("preview temple_dionysus %d %d 0" % [dionysus_at.x, dionysus_at.y])
	check(bool(plan.valid) and int(plan.w) == 10 and int(plan.h) == 6 and int(plan.x) == dionysus_at.x - 5 and int(plan.y) == dionysus_at.y - 3 and int(plan.cost) == 400 and int(plan.marble) == 8, lang + " the footprint is centred on the pointer: %s,%s %sx%s for %s drachmas and %s marble" % [str(plan.x), str(plan.y), str(plan.w), str(plan.h), str(plan.cost), str(plan.marble)])
	check(core.command("preview temple_dionysus %d %d 0" % [dionysus_at.x, dionysus_at.y]).tiles.all(func(cell): return bool(cell[3])), lang + " every tile of the site is free")
	var blocked: Dictionary = core.command("preview temple_dionysus 83 -11 0")
	check(not bool(blocked.valid) and str(blocked.reason) != "", lang + " a site over buildings is refused (%s)" % str(blocked.reason))

	# ------------------------------------------------------------------------------------------------- founding it
	var money_before: int = int(core.snapshot(true).money)
	var built: Dictionary = core.command("build temple_dionysus %d %d 0" % [dionysus_at.x, dionysus_at.y])
	check(not built.has("error"), lang + " the sanctuary is founded (%s)" % str(built.get("error", "ok")))
	var founded: Dictionary = core.snapshot(true)
	check(int(founded.money) <= money_before - 400, lang + " its drachmas are paid (%d to %d)" % [money_before, int(founded.money)])
	check(not bool(founded.get("undo_available", false)), lang + " a sanctuary is not undoable (its marble would not come back)")
	var courts: Array = pieces_of(founded, "sanctuary_statue_dionysus").filter(func(b): return int(b.get("grow", 100)) == 0)
	var slabs: Array = founded.buildings.filter(func(b): return bool(b.get("stretch", false)))
	check(courts.size() == 2 and slabs.size() >= 3 and slabs.all(func(b): return str(b.asset) == "sanctuary_court_0" and int(b.w) >= 2), lang + " its two statues are founded and its temple, monument and altar are foundation slabs (%d)" % slabs.size())
	var me := Vector2i(dionysus_at.x, dionysus_at.y)
	var inspection: Dictionary = core.command("inspect %d %d" % [me.x, me.y])
	var monument: Dictionary = inspection.get("monument", {})
	check(not monument.is_empty() and bool(monument.sanctuary) and int(monument.god) == 7 and not bool(monument.finished) and int(monument.progress) == 0 and bool(inspection.can_control), lang + " the inspection of any piece is of the sanctuary: %s" % str(monument.get("title", "-")))
	var lines: Array = monument.get("lines", [])
	check(lines.size() >= 2 and str(monument.god_name) != "" and int(monument.needed.marble) > 0 and int(monument.cost.marble) == 20 and int(monument.cost.wood) == 5 and int(monument.cost.sculpture) == 2, lang + " it says how far it has come and what it still needs: %s" % str(lines.slice(0, 2)))
	if lang == "ru":
		check(has_cyrillic(str(lines[0])) and has_cyrillic(str(monument.title)), "ru its words are in Russian: " + str(lines[0]))

	# ------------------------------------------------------------------------------------------ halting the work
	var token: int = int(inspection.target_token)
	var halted: Dictionary = core.command("monument_halt %d %d %d 1" % [me.x, me.y, token])
	check(bool(halted.monument.halted) and halted.monument.lines.size() > lines.size() - 1, lang + " the work can be halted (the inspection says so)")
	check(core.command("monument_halt %d %d %d 1" % [me.x, me.y, token + 1]).get("error", "") == "inspection_target_changed" and core.command("monument_halt %d %d" % [me.x, me.y]).has("error"), lang + " a stale token or a missing flag is refused")
	check(not bool(core.command("monument_halt %d %d %d 0" % [me.x, me.y, token]).monument.halted), lang + " and resumed")
	check(core.command("sanctuary_help %d %d %d" % [me.x, me.y, token]).get("error", "") == "not_finished", lang + " an unfinished sanctuary cannot be asked for help")

	# ------------------------------------------------------------------------------- the workers and carts build it
	var artemis_before := artemis_requirement(core)
	var finished_at := build_until_finished(core, me, 1500)
	check(finished_at >= 0, lang + " the carts and workers finish the sanctuary (step %d)" % finished_at)
	var done: Dictionary = core.command("inspect %d %d" % [me.x, me.y])
	var finished: Dictionary = done.get("monument", {})
	check(bool(finished.finished) and int(finished.progress) == 100 and finished.lines.is_empty() and str(finished.description).length() > 40 and str(finished.help_label) != "", lang + " it stands: the god's description and the label of its help are there")
	var after: Dictionary = core.snapshot(true)
	check(pieces_of(after, "sanctuary_").filter(func(b): return int(b.get("grow", 100)) < 100 or bool(b.get("stretch", false))).is_empty() or after.buildings.filter(func(b): return bool(b.get("stretch", false))).size() < slabs.size(), lang + " its pieces have risen from their foundations")
	check(pieces_of(after, "sanctuary_temple_").size() >= 3 and pieces_of(after, "sanctuary_monument_dionysus").size() >= 1, lang + " the finished temple, statues and monument are in the city")
	var all_built := built_facing(after.buildings)
	check(all_built.checked == 3 and all_built.problems.is_empty(), lang + " the one founded here (unturned) faces its front like the two turned ones %s" % str(all_built.problems.slice(0, 2)))
	var god_walkers: Array = after.walkers.filter(func(w): return str(w.asset) == "walker_dionysus")
	check(god_walkers.size() >= 1, lang + " the god of the sanctuary walks in the city (%d)" % god_walkers.size())

	# ---------------------------------------------------------------------------------------------------- the god's help
	var asked: Dictionary = core.command("sanctuary_help %d %d %d" % [me.x, me.y, int(done.target_token)])
	check(not asked.has("error") and asked.help != null and str(asked.help.text) != "" and (bool(asked.help.granted) or str(asked.help.reason) != ""), lang + " the god is asked for help and answers in words: %s" % str(asked.get("help", {}).get("text", "-")))
	var again: Dictionary = core.command("sanctuary_help %d %d %d" % [me.x, me.y, int(done.target_token)])
	check(not bool(again.help.granted) and str(again.help.reason) in ["too_soon", "no_target"] and str(again.help.text) != "", lang + " asking again with nothing to help (or too soon) is refused in the god's words: %s" % str(again.help.text))

	# --------------------------------------------------------------------------------------- the mythology page
	var myth: Dictionary = core.command("mythology")
	var listed: Array = myth.sanctuaries.filter(func(s): return int(s.god) == 7)
	check(myth.sanctuaries.size() == 3 and listed.size() == 1 and bool(listed[0].finished) and str(listed[0].state) != "" and str(myth.titles.sanctuaries) != "", lang + " the mythology page lists the three sanctuaries, the new one with its state: %s" % str(listed[0].state if not listed.is_empty() else "-"))
	check(myth.gods_attacking.is_empty() and myth.monsters.is_empty(), lang + " no god attacks and no monster is loose")
	core.command("test_monster cerberus")
	var with_monster: Dictionary = core.command("mythology")
	check(with_monster.monsters.size() == 1 and str(with_monster.monsters[0].name) != "", lang + " a monster at large is on the page: %s" % str(with_monster.monsters[0].name if with_monster.monsters.size() == 1 else "-"))

	# ---------------------------------------------------- the limit, and a hero's requirement for a sanctuary
	check(core.command("preview temple_hermes 108 -90 0").get("reason", "") == "max_sanctuaries" and core.command("build temple_hermes 108 -90 0").get("error", "") == "max_sanctuaries", lang + " the city is at its limit of sanctuaries: another is refused")
	var artemis_after := artemis_requirement(core)
	check(not artemis_before.is_empty() and not bool(artemis_before.met) and bool(artemis_after.get("met", false)), lang + " Atalanta's requirement of a sanctuary to Artemis follows its building: \"%s\" then \"%s\"" % [str(artemis_before.get("status", "-")), str(artemis_after.get("status", "-"))])
	core.close_city()

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var only := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	if only != "ru":
		run_language("en", engine)
	if only != "en":
		run_language("ru", engine)
	print("SANCT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
