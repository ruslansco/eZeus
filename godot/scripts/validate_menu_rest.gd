extends SceneTree
const BuildCatalog = preload("res://scripts/build_catalog.gd")
# The rest of the SDL build menu (headless, in memory; the designated save is never written): orchards and livestock dragged
# over an area, the shore buildings, the palace with its paving, the stadium, the horse ranch and its paddock, bridges,
# roadblocks, columns and avenues dragged along a path, the hippodrome with a crosswalk, and the commemoratives and gods'
# monuments a scenario grants. Each is previewed, built by the core's shared rules (engine/ebuildplacement, the SDL view's
# own), shown with its model in the snapshot and, where the SDL view allows it, undone.
const NEW_TOOLS := ["vine", "olive_tree", "orange_tree", "goat", "sheep", "cattle", "fishery", "urchin_quay", "trireme_wharf",
	"horse_ranch", "palace", "stadium", "bridge", "roadblock", "doric_column", "ionic_column", "corinthian_column", "avenue",
	"boulevard", "water_park", "hippodrome", "crosswalk"]
const COMMEMORATIVES := ["population", "victory", "colony", "athlete", "conquest", "happiness", "heroic", "diplomacy", "scholar"]
const GODS := ["aphrodite", "apollo", "ares", "artemis", "athena", "atlas", "demeter", "dionysus", "hades", "hephaestus", "hera", "hermes", "poseidon", "zeus"]
const NONE := Vector2i(99999, 99999)
var okay := true
var checks := 0
# The treasury just before the last build_and_undo (the city earns and spends between steps, so undo is checked against it).
var last_money := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("MENU_REST_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	core.enable_test_commands()
	return opened

# The first tile (in snapshot order, optionally only those the snapshot marks buildable) where the tool previews valid.
func spot(core: RefCounted, state: Dictionary, tool: String, orientation := 0, buildable_only := true) -> Vector2i:
	for tile in state.tiles:
		if buildable_only and (not int(tile[5]) or int(tile[4])):
			continue
		if core.command("preview %s %d %d %d" % [tool, int(tile[0]), int(tile[1]), orientation]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return NONE

# Two ends of a straight row of four tiles along x where the path tool plans four new tiles and nothing in the way.
func row_site(core: RefCounted, state: Dictionary, tool: String) -> Array:
	var tried := 0
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var a := Vector2i(int(tile[0]), int(tile[1]))
		var plan: Dictionary = core.command("preview_path %s %d %d %d %d" % [tool, a.x, a.y, a.x + 3, a.y])
		if plan.get("complete", false) and plan.tiles.filter(func(t): return int(t[1]) == a.y and int(t[5]) == 0).size() == 4:
			return [a, a + Vector2i(3, 0)]
		tried += 1
		if tried > 6000:
			break
	return []

func with_asset(state: Dictionary, asset: String) -> Array:
	return state.buildings.filter(func(b): return b.asset == asset)

func tile_map(state: Dictionary) -> Dictionary:
	var out := {}
	for tile in state.tiles:
		out[Vector2i(int(tile[0]), int(tile[1]))] = tile
	return out

# Builds `args`, checks the charge against the preview and that it can be undone (or not), then undoes it.
func build_and_undo(core: RefCounted, label: String, args: String, preview: Dictionary, undoable := true) -> Dictionary:
	var before: Dictionary = core.snapshot(true)
	last_money = int(before.money)
	var placed: Dictionary = core.command("build " + args)
	check(not placed.has("error") and int(placed.money) == int(before.money) - int(preview.cost), label + " is built for the quoted cost (%s)" % placed.get("error", str(int(before.money) - int(placed.get("money", 0)))))
	var full: Dictionary = core.snapshot(true)
	if undoable:
		check(bool(placed.get("undo_available", false)), label + " can be undone")
	return full

# A building taken away is gone from the board only at the next simulation step (its city still counts it until then).
func settle(core: RefCounted) -> void:
	core.replay(4)

func undo(core: RefCounted, label: String, money: int) -> void:
	var back: Dictionary = core.command("undo")
	check(not back.has("error") and int(back.money) == money, label + " undo refunds it")
	settle(core)

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		var opened := open(core, lang)
		check(opened.has("protocol"), lang + " designated test city loads")
		var items: Array = core.command("buildable").buildings
		var by_name := {}
		for item in items:
			by_name[item.name] = item
		var expected: Array = NEW_TOOLS.duplicate()
		for id in COMMEMORATIVES:
			expected.append("monument_" + id)
		for god in GODS:
			expected.append("god_monument_" + god)
		var missing := expected.filter(func(n): return not by_name.has(n))
		check(missing.is_empty(), lang + " the core lists every building of the SDL menu (%s missing)" % str(missing))
		var no_model := expected.filter(func(n): return by_name.has(n) and by_name[n].asset != "road" and not ResourceLoader.exists("res://assets/models/%s.glb" % by_name[n].asset))
		check(no_model.is_empty(), lang + " each has a model %s" % str(no_model))
		check(BuildCatalog.uncategorized(items).is_empty(), lang + " each has a menu category")
		var distinct := {}
		for n in expected:
			if by_name.has(n):
				distinct[str(by_name[n].label)] = true
		check(distinct.size() == expected.size(), lang + " each has its own native name (%d of %d)" % [distinct.size(), expected.size()])
		if lang == "ru":
			check(str(by_name.palace.label).unicode_at(0) >= 0x400 and str(by_name.monument_victory.label).unicode_at(0) >= 0x400, "ru names come from the Russian native dictionary")
		var state: Dictionary = core.snapshot(true)

		# Stadium: 10x5 (5x10 turned); the model runs along y, so a stadium laid along x is turned a quarter.
		for turn in [0, 1]:
			var at := spot(core, state, "stadium", turn)
			check(at != NONE, lang + " a site for the stadium (turn %d)" % turn)
			if at == NONE:
				continue
			var preview: Dictionary = core.command("preview stadium %d %d %d" % [at.x, at.y, turn])
			check(preview.tiles.size() == 50 and int(preview.w) == (5 if turn else 10) and preview.asset == "stadium", lang + " the stadium preview covers its 50 tiles")
			var built := build_and_undo(core, lang + " stadium", "stadium %d %d %d" % [at.x, at.y, turn], preview)
			var stadia := with_asset(built, "stadium")
			check(stadia.size() == 1 and int(stadia[0].w) == int(preview.w) and int(stadia[0].orientation) == int(preview.orientation), lang + " the snapshot shows the stadium as previewed")
			var again: Dictionary = core.command("preview stadium %d %d %d" % [at.x + 20, at.y, turn])
			check(again.get("reason", "") == "stadium_exists" or again.has("error"), lang + " a city has one stadium (%s)" % again.get("reason", ""))
			undo(core, lang + " stadium", last_money)

		# Palace: the test city has one. Demolished, a new one is laid with its paving ring.
		var palaces := with_asset(state, "palace")
		check(palaces.size() == 1, lang + " the test city has its palace")
		if palaces.size() == 1:
			var old: Dictionary = palaces[0]
			var probe: Dictionary = core.command("preview palace %d %d 0" % [int(old.x) + 1, int(old.y) + 2])
			check(not probe.valid and probe.reason in ["palace_exists", "occupied"], lang + " a second palace is refused (%s)" % probe.reason)
			var target: Dictionary = core.command("preview demolish %d %d 0" % [int(old.x), int(old.y)])
			core.command("demolish %d %d 1 %d" % [int(old.x), int(old.y), int(target.target_token)])
			settle(core)
			var cleared: Dictionary = core.snapshot(true)
			check(with_asset(cleared, "palace").is_empty(), lang + " the old palace is demolished")
			var at := spot(core, cleared, "palace", 0)
			check(at != NONE, lang + " a site for a new palace")
			if at != NONE:
				var preview: Dictionary = core.command("preview palace %d %d 0" % [at.x, at.y])
				var ring: Array = preview.pieces.filter(func(p): return str(p.asset).begins_with("palace_tile_"))
				check(preview.pieces.size() == ring.size() + 1 and ring.size() > 10, lang + " the palace preview lists the palace and its %d paving tiles" % ring.size())
				var built := build_and_undo(core, lang + " palace", "palace %d %d 0" % [at.x, at.y], preview)
				var tiles := with_asset(built, "palace_tile_plain").size() + with_asset(built, "palace_tile_lamp").size() - with_asset(cleared, "palace_tile_plain").size() - with_asset(cleared, "palace_tile_lamp").size()
				check(with_asset(built, "palace").size() == 1 and tiles == ring.size(), lang + " the palace stands with its paving (%d tiles)" % tiles)
				undo(core, lang + " palace", last_money)
			core.close_city()
			open(core, lang)
			state = core.snapshot(true)

		# Horse ranch and its paddock, on the side the turn names.
		var ranch_at := spot(core, state, "horse_ranch", 0)
		check(ranch_at != NONE, lang + " a site for a horse ranch")
		if ranch_at != NONE:
			var preview: Dictionary = core.command("preview horse_ranch %d %d 0" % [ranch_at.x, ranch_at.y])
			check(preview.pieces.size() == 2 and preview.tiles.size() == 25, lang + " the ranch preview lists the ranch and the paddock")
			var built := build_and_undo(core, lang + " horse ranch", "horse_ranch %d %d 0" % [ranch_at.x, ranch_at.y], preview)
			var paddock := with_asset(built, "horse_ranch_enclosure")
			var expected_paddock: Dictionary = preview.pieces[1]
			check(with_asset(built, "horse_ranch").size() == with_asset(state, "horse_ranch").size() + 1 and paddock.any(func(b): return int(b.x) == int(expected_paddock.x) and int(b.y) == int(expected_paddock.y) and int(b.w) == 4),
				lang + " the ranch and its paddock stand where previewed")
			undo(core, lang + " horse ranch", last_money)

		# Shore buildings face their water as the pier does; the urchin quay is offered once allowed.
		core.command("test_allow urchin_quay")
		for tool in ["fishery", "trireme_wharf", "urchin_quay"]:
			var at := spot(core, state, tool, 0, false)
			check(at != NONE, lang + " a shore site for the " + tool)
			if at == NONE:
				continue
			var preview: Dictionary = core.command("preview %s %d %d 0" % [tool, at.x, at.y])
			var built := build_and_undo(core, lang + " " + tool, "%s %d %d 0" % [tool, at.x, at.y], preview)
			var placed := with_asset(built, tool).filter(func(b): return int(b.x) == int(preview.x) and int(b.y) == int(preview.y))
			check(placed.size() == 1 and int(placed[0].orientation) == int(preview.orientation), lang + " the " + tool + " stands where previewed, facing its water")
			undo(core, lang + " " + tool, last_money)
		var inland: Dictionary = core.command("preview fishery %d %d 0" % [ranch_at.x, ranch_at.y])
		check(not inland.valid and inland.reason in ["not_on_shore", "occupied"], lang + " a fishery needs the shore (%s)" % inland.reason)

		# A bridge from a shore straight across the water: road over water, charged per tile.
		var bridge_at := spot(core, state, "bridge", 0, false)
		check(bridge_at != NONE, lang + " a bridge site")
		if bridge_at != NONE:
			var preview: Dictionary = core.command("preview bridge %d %d 0" % [bridge_at.x, bridge_at.y])
			check(preview.tiles.size() >= 2 and int(preview.cost) == int(by_name.bridge.cost) * preview.tiles.size(), lang + " the bridge preview lists %d tiles at the cost of each" % preview.tiles.size())
			var built := build_and_undo(core, lang + " bridge", "bridge %d %d 0" % [bridge_at.x, bridge_at.y], preview)
			var cells := tile_map(built)
			check(preview.tiles.all(func(t): return int(cells[Vector2i(int(t[0]), int(t[1]))][4]) == 1), lang + " each tile of the bridge is road")
			undo(core, lang + " bridge", last_money)

		# A roadblock on a street is drawn as its barrier; it cannot be set twice.
		var block_at := NONE
		for tile in state.tiles:
			if int(tile[4]) and core.command("preview roadblock %d %d 0" % [int(tile[0]), int(tile[1])]).get("valid", false):
				block_at = Vector2i(int(tile[0]), int(tile[1]))
				break
		check(block_at != NONE, lang + " a street for a roadblock")
		if block_at != NONE:
			var placed: Dictionary = core.command("build roadblock %d %d 0" % [block_at.x, block_at.y])
			var full: Dictionary = core.snapshot(true)
			check(not placed.has("error") and with_asset(full, "roadblock").any(func(b): return int(b.x) == block_at.x and int(b.y) == block_at.y), lang + " the roadblock stands on the street")
			check(core.command("preview roadblock %d %d 0" % [block_at.x, block_at.y]).reason == "roadblock_exists", lang + " a second roadblock there is refused")
			var off: Dictionary = core.command("preview roadblock %d %d 0" % [ranch_at.x, ranch_at.y])
			check(off.reason == "needs_road", lang + " a roadblock needs a street (%s)" % off.reason)

		# Columns are dragged along a path; avenues lay their median and the street beside it.
		for tool in ["doric_column", "avenue"]:
			var row := row_site(core, state, tool)
			check(row.size() == 2, lang + " a free row of four tiles for the " + tool)
			if row.size() != 2:
				continue
			var plan: Dictionary = core.command("preview_path %s %d %d %d %d" % [tool, row[0].x, row[0].y, row[1].x, row[1].y])
			var money: int = core.snapshot(false).money
			var built: Dictionary = core.command("build_path %s %d %d %d %d" % [tool, row[0].x, row[0].y, row[1].x, row[1].y])
			var after: Dictionary = core.snapshot(true)
			var cells := tile_map(after)
			if tool == "doric_column":
				check(not built.has("error") and int(built.money) == money - int(plan.cost) and with_asset(after, "column_doric").size() == with_asset(state, "column_doric").size() + 4,
					lang + " four columns are raised along the row for the quoted cost")
			else:
				var medians: Array = plan.tiles.filter(func(t): return int(t[0]) >= mini(row[0].x, row[1].x) and int(t[0]) <= maxi(row[0].x, row[1].x) and int(t[1]) == row[0].y)
				check(not built.has("error") and int(built.money) == money - int(plan.cost) and medians.size() == 4 and medians.all(func(t): return int(cells[Vector2i(int(t[0]), int(t[1]))][4]) == 1),
					lang + " the avenue's median and street are laid for the quoted cost (%d tiles)" % plan.tiles.size())
			undo(core, lang + " the " + tool + " row", money)

		# Orchards and livestock drag over an area like parks; sheep need carding sheds (eight a shed).
		var orchard_at := spot(core, state, "olive_tree", 0)
		if orchard_at != NONE:
			var plan: Dictionary = core.command("preview_area olive_tree %d %d %d %d" % [orchard_at.x, orchard_at.y, orchard_at.x + 2, orchard_at.y + 2])
			var money: int = core.snapshot(false).money
			var built: Dictionary = core.command("build_area olive_tree %d %d %d %d 0" % [orchard_at.x, orchard_at.y, orchard_at.x + 2, orchard_at.y + 2])
			check(int(plan.new) >= 1 and not built.has("error") and int(built.money) == money - int(plan.cost), lang + " an olive grove is dragged over an area (%d trees) for the quoted cost" % int(plan.new))
			undo(core, lang + " the olive grove", money)
		# The test city's five carding sheds have their forty sheep: one more shed allows eight more.
		var full_flock: Dictionary = core.command("preview_area sheep %d %d %d %d" % [ranch_at.x, ranch_at.y, ranch_at.x + 2, ranch_at.y + 2])
		check(full_flock.reason == "animal_limit", lang + " the sheds allow no more sheep (%s)" % full_flock.reason)
		var shed_at := spot(core, state, "carding_shed", 0)
		check(shed_at != NONE, lang + " a site for another carding shed")
		if shed_at != NONE:
			core.command("build carding_shed %d %d 0" % [shed_at.x, shed_at.y])
		var sheep_at := spot(core, core.snapshot(true), "sheep", 0)
		if sheep_at != NONE:
			var plan: Dictionary = core.command("preview_area sheep %d %d %d %d" % [sheep_at.x, sheep_at.y, sheep_at.x + 2, sheep_at.y + 3])
			var money: int = core.snapshot(false).money
			var built: Dictionary = core.command("build_area sheep %d %d %d %d 0" % [sheep_at.x, sheep_at.y, sheep_at.x + 2, sheep_at.y + 3])
			check(int(plan.new) >= 1 and not built.has("error") and int(built.money) == money - int(plan.cost), lang + " a flock is dragged over a pasture (%d sheep) for the quoted cost" % int(plan.new))
			undo(core, lang + " the flock", money)
		var goat_reason: String = core.command("preview_area goat %d %d %d %d" % [ranch_at.x, ranch_at.y, ranch_at.x + 1, ranch_at.y + 1]).get("reason", "")
		# Goats come with the dairy (the scenario's grant), and each dairy allows eight.
		core.command("test_allow dairy")
		var limited: Dictionary = core.command("preview_area goat %d %d %d %d" % [ranch_at.x, ranch_at.y, ranch_at.x + 1, ranch_at.y + 1])
		check(goat_reason == "building_not_available" and limited.reason in ["animal_limit", "occupied", "blocked_terrain"], lang + " goats need the scenario and a dairy (%s, %s)" % [goat_reason, limited.reason])

		# The hippodrome: its plates and a crosswalk over a straight one.
		core.command("test_allow hippodrome")
		var hippodrome_at := spot(core, state, "hippodrome", 0)
		check(hippodrome_at != NONE, lang + " a site for the hippodrome")
		if hippodrome_at != NONE:
			var preview: Dictionary = core.command("preview hippodrome %d %d 0" % [hippodrome_at.x, hippodrome_at.y])
			check(preview.asset == "hippodrome_0" and preview.tiles.size() == 16, lang + " the first plate may be any (the turn picks plate 0)")
			var turned: Dictionary = core.command("preview hippodrome %d %d 2" % [hippodrome_at.x, hippodrome_at.y])
			check(turned.asset == "hippodrome_2", lang + " the turn picks another plate")
			var built := build_and_undo(core, lang + " hippodrome plate", "hippodrome %d %d 0" % [hippodrome_at.x, hippodrome_at.y], preview)
			check(with_asset(built, "hippodrome_0").size() == 1, lang + " the plate is drawn as its model")
			var crossing: Dictionary = core.command("preview crosswalk %d %d 0" % [hippodrome_at.x + 1, hippodrome_at.y + 1])
			check(crossing.valid and crossing.tiles.size() == 4, lang + " a crosswalk fits over the straight plate")
			var crossed: Dictionary = core.command("build crosswalk %d %d 0" % [hippodrome_at.x + 1, hippodrome_at.y + 1])
			var cells := tile_map(core.snapshot(true))
			check(not crossed.has("error") and crossing.tiles.all(func(t): return int(cells[Vector2i(int(t[0]), int(t[1]))][4]) == 1), lang + " the crosswalk's tiles are street")
			check(not core.command("preview crosswalk %d %d 0" % [hippodrome_at.x + 1, hippodrome_at.y + 1]).valid, lang + " one crosswalk a plate")

		# Monuments a scenario grants: once allowed, built once, then no longer offered.
		core.command("test_allow monument_victory")
		var arch_at := spot(core, state, "monument_victory", 0)
		check(arch_at != NONE, lang + " a site for the victory monument once granted")
		if arch_at != NONE:
			var built: Dictionary = core.command("build monument_victory %d %d 0" % [arch_at.x, arch_at.y])
			check(not built.has("error") and with_asset(core.snapshot(true), "commemorative_1").size() == with_asset(state, "commemorative_1").size() + 1, lang + " the victory monument stands")
			var listed: Array = core.command("buildable").buildings.filter(func(b): return b.name == "monument_victory")
			check(not listed[0].available and not built.get("undo_available", true), lang + " the grant is used up and the monument is not undone")
		core.command("test_allow god_monument_zeus")
		var statue_at := spot(core, state, "god_monument_zeus", 0)
		check(statue_at != NONE, lang + " a site for Zeus' statue once granted")
		if statue_at != NONE:
			var preview: Dictionary = core.command("preview god_monument_zeus %d %d 0" % [statue_at.x, statue_at.y])
			check(preview.pieces.size() == 13 and preview.tiles.size() == 16, lang + " the statue preview lists the monument and twelve paving tiles")
			var before: Dictionary = core.snapshot(true)
			var built: Dictionary = core.command("build god_monument_zeus %d %d 0" % [statue_at.x, statue_at.y])
			var after: Dictionary = core.snapshot(true)
			check(not built.has("error") and with_asset(after, "sanctuary_monument_zeus").size() == with_asset(before, "sanctuary_monument_zeus").size() + 1, lang + " Zeus' statue stands on its paving")

		# The city lives on with all of it.
		var ran: Dictionary = core.replay(300, 7)
		check(ran.has("digest"), lang + " the city runs 300 ticks after the new buildings")
		core.close_city()
	print("MENU_REST_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
