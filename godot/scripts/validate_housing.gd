extends SceneTree
# Elite housing and the area drags against the embedded core (headless, in memory): an elite house is a 4x4 building with
# its own models, common and elite housing are dragged over an area in steps of their size (from the pressed tile toward
# the released one) and parks fill every tile of the rectangle, as in the SDL view; each footprint is built or skipped on
# its own, one undo step covers a drag, previews change nothing.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("HOUSING_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func pieces(state: Dictionary, prefix: String) -> Array:
	return state.buildings.filter(func(b): return String(b.asset).begins_with(prefix))

# The first tile whose drag to `corner` offset is complete and covers `count` footprints.
func find_plot(core: RefCounted, state: Dictionary, name: String, offset: Vector2i, count: int) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]):
			continue
		var a := Vector2i(int(tile[0]), int(tile[1]))
		var plan: Dictionary = core.command("preview_area %s %d %d %d %d" % [name, a.x, a.y, a.x + offset.x, a.y + offset.y])
		if plan.get("complete", false) and int(plan.new) == count:
			return a
	return Vector2i(-1, -1)

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	var listed := {}
	for item in core.command("buildable").buildings:
		listed[item.name] = item
	check(listed.has("elite_house") and listed.elite_house.available and listed.elite_house.asset == "elite_house_0a" and listed.elite_house.w == 4 and listed.elite_house.h == 4, "elite housing is offered as a 4x4 building with its model")
	var before: Dictionary = core.snapshot(true)

	# ----------------------------------------------------------- elite housing
	var origin := find_plot(core, before, "elite_house", Vector2i(8, 4), 6)
	check(origin.x >= 0, "a free plot for six mansions (a 3x2 grid of 4x4 plots) is found")
	if origin.x < 0:
		quit(1)
		return
	var far := origin + Vector2i(8, 4)
	var plan: Dictionary = core.command("preview_area elite_house %d %d %d %d" % [origin.x, origin.y, far.x, far.y])
	var unit: Dictionary = core.command("preview elite_house %d %d 0" % [origin.x, origin.y])
	check(int(plan.count) == 6 and plan.tiles.size() == 6 and int(plan.w) == 4 and int(plan.h) == 4, "a drag of 8 by 4 tiles holds six 4x4 plots, in steps of four")
	var corners: Array = plan.tiles.map(func(t): return Vector2i(int(t[0]), int(t[1])))
	check(corners == [origin, origin + Vector2i(0, 4), origin + Vector2i(4, 0), origin + Vector2i(4, 4), origin + Vector2i(8, 0), origin + Vector2i(8, 4)], "the plots follow the SDL order: columns, then rows")
	check(int(plan.unit_cost) == int(unit.cost) and int(plan.cost) == 6 * int(unit.cost) and plan.valid and plan.complete, "the cost is the native mansion cost per plot (%d each)" % int(plan.unit_cost))
	var unchanged: Dictionary = core.snapshot(true)
	check(unchanged.money == before.money and unchanged.time == before.time and unchanged.tiles == before.tiles and unchanged.buildings == before.buildings, "previewing an area does not change the city")
	var single: Dictionary = core.command("preview_area elite_house %d %d %d %d" % [origin.x, origin.y, origin.x + 1, origin.y + 1])
	check(int(single.new) == 1 and int(single.cost) == int(unit.cost), "a drag shorter than a plot is one mansion")
	var built: Dictionary = core.command("build_area elite_house %d %d %d %d 0" % [origin.x, origin.y, far.x, far.y])
	check(not built.has("error") and int(built.money) == int(before.money) - int(plan.cost), "building the drag charges exactly the previewed cost")
	var after: Dictionary = core.snapshot(true)
	var estates := pieces(after, "elite_house_")
	check(estates.size() == 6 and estates.all(func(b): return int(b.w) == 4 and int(b.h) == 4 and (String(b.asset) == "elite_house_0a" or String(b.asset) == "elite_house_0b")), "six estates stand, each a 4x4 building with a level 0 model (variant a or b)")
	var variants := {}
	for b in estates:
		variants[String(b.asset)] = true
	check(built.undo_available, "the drag can be undone")
	var again: Dictionary = core.command("preview_area elite_house %d %d %d %d" % [origin.x, origin.y, far.x, far.y])
	check(not again.valid and int(again.new) == 0 and again.reason == "occupied", "dragging over finished estates costs nothing and says it is occupied")
	var restored: Dictionary = core.command("undo")
	check(not restored.has("error") and int(restored.money) == int(before.money) and pieces(core.snapshot(true), "elite_house_").is_empty(), "one undo removes all six and refunds the exact cost")
	# Toward the origin: the first plot is the pressed tile, the rest follow in the other direction.
	var backward: Dictionary = core.command("preview_area elite_house %d %d %d %d" % [far.x, far.y, origin.x, origin.y])
	var back_corners: Array = backward.tiles.map(func(t): return Vector2i(int(t[0]), int(t[1])))
	check(int(backward.count) == 6 and back_corners[0] == far and back_corners[-1] == origin, "dragging the other way starts at the pressed tile and steps back")

	# ------------------------------------------------------------ common housing
	var house_origin := find_plot(core, core.snapshot(true), "house", Vector2i(5, 3), 6)
	check(house_origin.x >= 0, "a free plot for six houses (a 3x2 grid of 2x2 plots) is found")
	var house_unit: Dictionary = core.command("preview house %d %d 0" % [house_origin.x, house_origin.y])
	var money: int = core.snapshot(false).money
	var house_plan: Dictionary = core.command("preview_area house %d %d %d %d" % [house_origin.x, house_origin.y, house_origin.x + 5, house_origin.y + 3])
	check(int(house_plan.count) == 6 and int(house_plan.cost) == 6 * int(house_unit.cost), "a 6 by 4 drag holds six 2x2 houses at the native cost")
	var houses_before := pieces(core.snapshot(true), "common_house_").size()
	var house_build: Dictionary = core.command("build_area house %d %d %d %d 0" % [house_origin.x, house_origin.y, house_origin.x + 5, house_origin.y + 3])
	check(not house_build.has("error") and int(house_build.money) == money - int(house_plan.cost) and pieces(core.snapshot(true), "common_house_").size() == houses_before + 6, "six houses are built for the quoted cost")
	check(int(core.command("undo").money) == money and pieces(core.snapshot(true), "common_house_").size() == houses_before, "one undo takes them all back")

	# ------------------------------------------------------------------- parks
	var park_origin := find_plot(core, core.snapshot(true), "park", Vector2i(3, 2), 12)
	check(park_origin.x >= 0, "a free 4 by 3 rectangle for parks is found")
	var park_unit: Dictionary = core.command("preview park %d %d 0" % [park_origin.x, park_origin.y])
	money = core.snapshot(false).money
	var park_plan: Dictionary = core.command("preview_area park %d %d %d %d" % [park_origin.x, park_origin.y, park_origin.x + 3, park_origin.y + 2])
	check(int(park_plan.count) == 12 and int(park_plan.cost) == 12 * int(park_unit.cost) and int(park_plan.w) == 1, "a park drag fills every tile of the rectangle (12) at the native cost")
	var parks_before := pieces(core.snapshot(true), "park").size()
	var park_build: Dictionary = core.command("build_area park %d %d %d %d 0" % [park_origin.x, park_origin.y, park_origin.x + 3, park_origin.y + 2])
	check(not park_build.has("error") and int(park_build.money) == money - int(park_plan.cost) and pieces(core.snapshot(true), "park").size() == parks_before + 12, "twelve parks are built for the quoted cost")
	var park_back: Dictionary = core.command("preview_area park %d %d %d %d" % [park_origin.x + 3, park_origin.y + 2, park_origin.x, park_origin.y])
	check(park_back.tiles.size() == 12 and not park_back.valid, "dragging back over them finds nothing to build")
	check(int(core.command("undo").money) == money and pieces(core.snapshot(true), "park").size() == parks_before, "one undo removes all twelve")

	# --------------------------------------------------------- partial and refused
	# A drag that runs into a building builds only the plots that fit, and says so.
	var ruins := Vector2i(-1, -1)
	for entry in core.snapshot(true).buildings:
		if int(entry.w) >= 3 and not String(entry.asset).begins_with("wall_"):
			var probe: Dictionary = core.command("preview_area house %d %d %d %d" % [int(entry.x) - 4, int(entry.y), int(entry.x) + 3, int(entry.y)])
			if not probe.has("error") and int(probe.new) > 0 and not probe.complete:
				ruins = Vector2i(int(entry.x), int(entry.y))
				break
	check(ruins.x >= 0, "a drag that runs into a building is found")
	if ruins.x >= 0:
		var partial: Dictionary = core.command("preview_area house %d %d %d %d" % [ruins.x - 4, ruins.y, ruins.x + 3, ruins.y])
		var charge: int = core.snapshot(false).money
		var done: Dictionary = core.command("build_area house %d %d %d %d 0" % [ruins.x - 4, ruins.y, ruins.x + 3, ruins.y])
		check(not partial.complete and partial.valid and int(done.money) == charge - int(partial.cost), "only the plots that fit are built, charged as previewed")
		core.command("undo")
	var snapshot_before: Dictionary = core.snapshot(true)
	check(core.command("preview_area castle 1 2 3 4").has("error") and core.command("build_area castle 1 2 3 4 0").has("error"), "a tool that is not dragged is refused")
	check(core.command("preview_area house 1 2").has("error") and core.command("build_area house x").has("error"), "malformed area commands are rejected")
	check(core.command("preview_area house 99999 99999 100000 100000").has("error") and core.command("build_area house 99999 99999 100000 100000 0").has("error"), "a drag that starts off the map is rejected")
	check(core.snapshot(false).money == snapshot_before.money, "refused commands charge nothing")
	var corner := Vector2i(int(before.tiles[0][0]), int(before.tiles[0][1]))
	var huge: Dictionary = core.command("preview_area park %d %d %d %d" % [corner.x, corner.y, corner.x + 300, corner.y + 300])
	check(huge.get("truncated", false) and huge.tiles.size() <= 3000, "an enormous park drag lists a bounded set of footprints")
	core.close_city()
	print("HOUSING_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
