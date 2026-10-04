extends SceneTree
const BuildCatalog = preload("res://scripts/build_catalog.gd")
const UiText = preload("res://scripts/ui_text.gd")
# The build menu's source of truth (headless, in-memory only; the designated save is never written).
#
# `buildable` lists every building the Godot front end may offer, from a static table. This validator checks
# that the list is complete and consistent with the authoritative queries, that asking for it never changes
# the simulation (no probe constructs a building), and that every available building with a converted model
# can be previewed, built for exactly the quoted cost and undone. It also checks the menu built from the list: every
# name has a category, placeholders stay hidden, the HUD offers each building and every label is translated.
# Placed by their own rules (a strip of road, an empty agora space, a trade partner) and checked in agora_checks and validate_trade.gd.
const AGORA_TOOLS := ["common_agora", "grand_agora", "food_vendor", "fleece_vendor", "oil_vendor", "wine_vendor", "arms_vendor", "chariot_vendor", "trade_post", "pier"]
# Placed by the special rules of engine/ebuildplacement (several models, a shore, a street, water or a hippodrome, a path that
# also lays streets) and checked by validate_menu_rest.gd.
const SPECIAL_TOOLS := ["palace", "stadium", "horse_ranch", "fishery", "urchin_quay", "trireme_wharf", "bridge", "roadblock", "hippodrome", "crosswalk", "avenue", "boulevard"]
# Offered although they have no model of their own: roads are terrain, an agora is its road and empty spaces.
const NO_MODEL := ["road", "agora_space"]
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("BUILDINGS_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	return core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)

func spot(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	var tried := 0
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		tried += 1
		var query: Dictionary = core.command("preview %s %d %d 3" % [tool, int(tile[0]), int(tile[1])])
		if query.get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func menu_checks(lang: String, items: Array) -> void:
	check(BuildCatalog.uncategorized(items).is_empty(), lang + " every listed building has a menu category %s" % str(BuildCatalog.uncategorized(items)))
	var unnamed := PackedStringArray()
	var disagree := PackedStringArray()
	for item in items:
		if not BuildCatalog.NAMES.has(item.name):
			unnamed.append(item.name)
		elif lang == "en" and BuildCatalog.NAMES[item.name] != item.label:
			disagree.append("%s: %s / %s" % [item.name, BuildCatalog.NAMES[item.name], item.label])
	check(unnamed.is_empty(), lang + " every listed building has an English menu name %s" % str(unnamed))
	check(disagree.is_empty(), lang + " the menu names equal the core's English labels %s" % str(disagree.slice(0, 4)))
	var shown := BuildCatalog.groups(items, false)
	var everything := BuildCatalog.groups(items, true)
	var shown_count := 0
	var all_count := 0
	var hidden_models := false
	for group in shown:
		shown_count += group.items.size()
		for item in group.items:
			hidden_models = hidden_models or item.asset == "unconverted"
	for group in everything:
		all_count += group.items.size()
	check(shown.size() >= 8 and shown_count >= 40, lang + " the menu offers %d buildings in %d categories" % [shown_count, shown.size()])
	# Once every native building has a model nothing is hidden and both counts agree; a building added later without one is hidden.
	check(not hidden_models and all_count >= shown_count, lang + " buildings without a converted model are hidden unless placeholders are requested (%d vs %d)" % [shown_count, all_count])
	check(not shown.any(func(group): return group.title == BuildCatalog.OTHER), lang + " no building falls into Other")
	var available_models := 0
	for item in items:
		if item.available and item.asset != "unconverted" and not item.name in BuildCatalog.PARTNER_TOOLS:
			available_models += 1
	check(shown_count == available_models, lang + " the menu offers exactly the available buildings that have a model")
	for group in shown:
		for item in group.items:
			if not ResourceLoader.exists("res://assets/models/%s.glb" % item.asset) and not item.asset in NO_MODEL:
				check(false, lang + " " + item.name + " model " + item.asset + " exists")
	# The HUD builds one submenu per category, every item selects its tool, and labels are translated.
	var hud: Control = load("res://ui/hud.tscn").instantiate()
	root.add_child(hud)
	hud.set_tools([["select", "Inspect"], ["road", "Road"], ["house", "Housing"], ["demolish", "Demolish"]])
	hud.set_catalog(shown)
	check(hud.build_menu.get_popup().item_count == shown.size(), lang + " the Build menu has one submenu per category")
	var chosen: Array = []
	hud.tool_selected.connect(func(name): chosen.append(name))
	var activated := true
	for group in shown:
		for item in group.items:
			activated = hud.activate_building(item.name) and activated
	var expected: Array = []
	for group in shown:
		for item in group.items:
			expected.append(item.name)
	check(activated and chosen == expected, lang + " every menu item selects its building tool")
	TranslationServer.set_locale("ru")
	hud.retranslate()
	var untranslated := PackedStringArray()
	var latin_only := RegEx.create_from_string("^[A-Za-z' ]+$")
	for group in shown:
		if latin_only.search(TranslationServer.translate(group.title)) != null:
			untranslated.append(group.title)
		for item in group.items:
			if latin_only.search(TranslationServer.translate(item.label)) != null:
				untranslated.append(item.label)
	for label in ["Inspect", "Road", "Housing", "Demolish", "Build"]:
		if latin_only.search(TranslationServer.translate(label)) != null:
			untranslated.append(label)
	check(untranslated.is_empty(), lang + " category, tool and building labels all have Russian text %s" % str(untranslated.slice(0, 6)))
	check(hud.build_menu.tooltip_text == "Строить", lang + " the menu button re-translates (%s)" % hud.build_menu.tooltip_text)
	TranslationServer.set_locale("en")
	hud.queue_free()

func agora_site(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		var query: Dictionary = core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])])
		if query.get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func pieces(state: Dictionary, asset: String) -> Array:
	return state.buildings.filter(func(b): return b.asset == asset)

# Agoras are laid over roads and vendors replace their empty spaces: one native rule shared with the SDL view.
func agora_checks(core: RefCounted, lang: String, items: Array) -> void:
	var names := {}
	for item in items:
		names[item.name] = item
	# The horse trainer depends on the city's culture (the test city has none), but it is listed with its model.
	check(names.has("horse_vendor") and names.horse_vendor.asset == "horse_vendor", lang + " the horse trainer is listed with its model")
	for required in AGORA_TOOLS:
		check(names.has(required) and names[required].available and names[required].asset != "unconverted", lang + " " + required + " is offered")
	# The grand agora first: the common agora test leaves its agora (and a vendor test) in the city.
	for kind in [["grand_agora", 6, 30], ["common_agora", 3, 18]]:
		var base: Dictionary = core.snapshot(true)
		var site := agora_site(core, base, kind[0])
		check(site != Vector2i(99999, 99999), lang + " a site for the " + kind[0] + " exists in the test city")
		if site == Vector2i(99999, 99999):
			continue
		var args := "%s %d %d 0" % [kind[0], site.x, site.y]
		var query: Dictionary = core.command("preview " + args)
		check(query.valid and query.tiles.size() == kind[2] and int(query.cost) == int(names[kind[0]].cost), lang + " " + kind[0] + " preview covers its road strip and lobe at the quoted cost (%d tiles)" % query.tiles.size())
		check(query.w * query.h >= kind[2], lang + " " + kind[0] + " footprint rectangle %dx%d contains the tiles" % [query.w, query.h])
		var untouched: Dictionary = core.snapshot(true)
		check(untouched.money == base.money and untouched.buildings == base.buildings and untouched.tiles == base.tiles, lang + " " + kind[0] + " preview does not change the city")
		var placed: Dictionary = core.command("build " + args)
		check(not placed.has("error") and placed.money == base.money - int(query.cost) and placed.undo_available, lang + " " + kind[0] + " is built for the quoted cost and can be undone")
		var spaces := pieces(placed, "agora_space")
		check(spaces.size() == kind[1] and spaces.all(func(b): return b.w == 2 and b.h == 2), lang + " " + kind[0] + " opens with %d empty 2x2 vendor spaces" % spaces.size())
		var again: Dictionary = core.command("preview " + args)
		check(not again.valid, lang + " " + kind[0] + " cannot be laid twice on the same road (%s)" % again.get("reason", ""))
		check(core.command("build " + args).has("error"), lang + " a second " + kind[0] + " on the same road is refused without charge")
		var back: Dictionary = core.command("undo")
		var after: Dictionary = core.snapshot(true)
		check(not back.has("error") and after.money == base.money and pieces(after, "agora_space").is_empty() and after.buildings == base.buildings and after.tiles == base.tiles, lang + " undo takes the " + kind[0] + " away and restores money, buildings and roads")
		if kind[0] == "common_agora":
			var again_placed: Dictionary = core.command("build " + args)
			vendor_checks(core, lang, names, again_placed, pieces(again_placed, "agora_space"))

func vendor_checks(core: RefCounted, lang: String, names: Dictionary, placed: Dictionary, spaces: Array) -> void:
	var space: Dictionary = spaces[0]
	# Any tile of a space picks it, like the rectangle of the building it becomes.
	var inside := Vector2i(space.x + 1, space.y + 1)
	var query: Dictionary = core.command("preview food_vendor %d %d 0" % [inside.x, inside.y])
	check(query.valid and query.tiles.size() == 4 and query.x == space.x and query.y == space.y and int(query.cost) == int(names.food_vendor.cost), lang + " food vendor preview covers the space at the quoted cost")
	var elsewhere: Dictionary = core.command("preview food_vendor %d %d 0" % [space.x + 20, space.y + 20])
	check(not elsewhere.get("valid", true) and elsewhere.get("reason", "") in ["needs_agora_space", "not_owned", "out_of_map"] or elsewhere.has("error"), lang + " a vendor needs an agora space (%s)" % elsewhere.get("reason", elsewhere.get("error", "")))
	var before: Dictionary = core.snapshot(true)
	var built: Dictionary = core.command("build food_vendor %d %d 0" % [inside.x, inside.y])
	check(not built.has("error") and built.money == before.money - int(query.cost) and built.undo_available, lang + " a food vendor is built on the space for the quoted cost")
	check(pieces(built, "food_vendor").size() == pieces(before, "food_vendor").size() + 1 and pieces(built, "agora_space").size() == spaces.size() - 1, lang + " the vendor replaces the empty space")
	var duplicate: Dictionary = core.command("preview food_vendor %d %d 0" % [spaces[1].x, spaces[1].y])
	check(not duplicate.valid and duplicate.reason == "vendor_exists", lang + " an agora takes one food vendor (%s)" % duplicate.reason)
	var occupied: Dictionary = core.command("preview fleece_vendor %d %d 0" % [space.x, space.y])
	check(not occupied.valid and occupied.reason == "occupied", lang + " a built stall is not an empty space (%s)" % occupied.reason)
	var other: Dictionary = core.command("preview fleece_vendor %d %d 0" % [spaces[1].x, spaces[1].y])
	check(other.valid, lang + " the next space takes a different vendor")
	var gone: Dictionary = core.command("undo")
	var after: Dictionary = core.snapshot(true)
	check(not gone.has("error") and after.money == before.money and pieces(after, "food_vendor").size() == pieces(before, "food_vendor").size() and pieces(after, "agora_space").size() == spaces.size(), lang + " undo takes the vendor away and the empty space returns")
	var rebuilt: Dictionary = core.command("build food_vendor %d %d 0" % [inside.x, inside.y])
	# The new market lives: the city runs for a while, the stall is still there and the inspector reads it.
	var stall = pieces(rebuilt, "food_vendor").filter(func(b): return not pieces(after, "food_vendor").any(func(o): return o.id == b.id))[0]
	var info: Dictionary = core.command("inspect %d %d" % [stall.x, stall.y])
	check(info.has("name") and int(info.footprint[2]) == 2 and int(info.footprint[3]) == 2, lang + " the inspector reads the new stall (%s)" % info.get("name", "?"))
	var ran: Dictionary = core.replay(300, 7)
	var later: Dictionary = core.snapshot(true)
	check(ran.has("digest") and later.time > rebuilt.time and pieces(later, "food_vendor").size() == pieces(rebuilt, "food_vendor").size(), lang + " the city runs 300 ticks with the new market")
	# Every other good has its stall too: each previews on a free space with its own model and cost, builds and is undone.
	var free: Array = pieces(core.snapshot(true), "agora_space")
	if free.size() >= 1:
		for kind in ["wine_vendor", "arms_vendor", "horse_vendor", "chariot_vendor"]:
			if not names[kind].available:
				continue
			var target: Dictionary = free[0]
			var preview: Dictionary = core.command("preview %s %d %d 0" % [kind, target.x, target.y])
			check(preview.valid and preview.asset == kind and int(preview.cost) == int(names[kind].cost), lang + " the " + kind + " previews on a free space with its own model (%s)" % preview.get("asset", "?"))
			var money: int = core.snapshot(false).money
			var stall_built: Dictionary = core.command("build %s %d %d 0" % [kind, target.x, target.y])
			check(not stall_built.has("error") and stall_built.money == money - int(preview.cost) and pieces(core.snapshot(true), kind).size() >= 1, lang + " the " + kind + " is built on the space for the quoted cost")
			check(int(core.command("undo").money) == money and pieces(core.snapshot(true), "agora_space").size() == free.size(), lang + " and undone, the empty space returns")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var baseline := ""
	for lang in ["en", "ru"]:
		var initial := open(core, lang)
		check(initial.has("protocol"), lang + " designated test city loads")
		if not initial.has("protocol"):
			quit(1)
			return
		var list: Dictionary = core.command("buildable")
		var items: Array = list.get("buildings", [])
		check(list.get("kind", "") == "buildable" and items.size() >= 55, lang + " the build list is complete (%d entries)" % items.size())
		var names := {}
		var well_formed := true
		var costs_positive := true
		for item in items:
			names[item.name] = true
			well_formed = well_formed and item.has_all(["name", "label", "w", "h", "asset", "cost", "available"]) and int(item.w) >= 1 and int(item.h) >= 1 and not String(item.label).is_empty()
			costs_positive = costs_positive and int(item.cost) >= 0
		check(names.size() == items.size(), lang + " every building name is unique")
		check(well_formed, lang + " every entry has a name, label, footprint, model, cost and availability")
		check(costs_positive, lang + " no building has a negative cost")
		for required in ["road", "house", "hospital", "fountain", "warehouse", "granary", "wheat_farm", "olive_press", "winery", "sculpture_studio"]:
			check(names.has(required), lang + " the list contains " + required)
		# Labels follow the interface language.
		if lang == "ru":
			var cyrillic := false
			for item in items:
				if item.name == "hospital":
					cyrillic = String(item.label).unicode_at(0) >= 0x400
			check(cyrillic, "ru labels come from the Russian native dictionary")
		# Asking never changes the simulation.
		var before: Dictionary = core.snapshot(true)
		for i in 5:
			core.command("buildable")
		var after: Dictionary = core.snapshot(true)
		check(after.money == before.money and after.time == before.time and after.buildings == before.buildings and after.tiles == before.tiles, lang + " the build list does not mutate the city")
		# The list shares the key `buildings` with snapshots; a quiet snapshot after it must still carry the city's own.
		var quiet: Dictionary = core.snapshot(false)
		check(quiet.buildings.size() == before.buildings.size() and quiet.buildings.all(func(b): return b.has("asset") and b.has("x")), lang + " a later snapshot still carries the city's buildings, not the build list")
		# Every available building with a converted model: preview, build at the quoted cost, undo.
		var built := 0
		var skipped := PackedStringArray()
		for item in items:
			# Pyramids, monuments and shrines cost no drachmas, are founded through buildPyramid (which the undo does not record) and are checked by validate_pyramids.gd.
			if not item.available or item.asset == "unconverted" or item.name == "road" or item.name in AGORA_TOOLS or item.name in SPECIAL_TOOLS or str(item.name).begins_with("pyramid_") or str(item.name).begins_with("shrine_") or str(item.name).begins_with("god_monument_"):
				continue
			var state: Dictionary = core.snapshot(true)
			var candidate := spot(core, state, item.name)
			if candidate == Vector2i(99999, 99999):
				skipped.append(item.name)
				continue
			var args := "%s %d %d 3" % [item.name, candidate.x, candidate.y]
			var query: Dictionary = core.command("preview " + args)
			var good: bool = query.get("valid", false) and int(query.cost) == int(item.cost) and query.tiles.size() == int(item.w) * int(item.h)
			check(good, lang + " " + item.name + " preview agrees with the list (cost " + str(item.cost) + ", " + str(item.w) + "x" + str(item.h) + ")")
			if not good:
				continue
			var placed: Dictionary = core.command("build " + args)
			var charged: bool = placed.get("money", -1) == state.money - int(item.cost)
			check(charged and placed.get("undo_available", false), lang + " " + item.name + " is built for the quoted cost and can be undone")
			var undone: Dictionary = core.command("undo")
			check(undone.get("money", -1) == state.money, lang + " " + item.name + " undo refunds it")
			built += 1
		check(built >= 20, lang + " at least twenty buildings were exercised (%d; no site in this city: %s)" % [built, ", ".join(skipped)])
		menu_checks(lang, items)
		agora_checks(core, lang, items)
		core.close_city()
	# The list must not move the replay: probing used to change the digest after 200 ticks.
	var plain := open(core, "en")
	var clean: Dictionary = core.replay(200, 7)
	core.close_city()
	open(core, "en")
	for i in 3:
		core.command("buildable")
	var asked: Dictionary = core.replay(200, 7)
	core.close_city()
	check(clean.has("digest") and clean.get("digest", "a") == asked.get("digest", "b"), "asking for the build list leaves the replay digest unchanged (%s)" % clean.get("digest", ""))
	check(plain.has("protocol"), "the clean replay session opened")
	print("BUILDINGS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
