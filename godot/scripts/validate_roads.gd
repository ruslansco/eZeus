extends SceneTree
# Drag-to-place roads against the embedded core (headless, in memory): `preview_road` and `build_road` use the
# SDL view's own path finder and ground rules, charge the native cost per new tile, skip existing roads, and
# are undone as one step.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("ROAD_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func road_cells(state: Dictionary) -> Dictionary:
	var result := {}
	for tile in state.tiles:
		if int(tile[4]) == 1:
			result[Vector2i(int(tile[0]), int(tile[1]))] = true
	return result

# A start with a free, straight corridor to the offset (the shortest orthogonal path, no detour), found with
# the core's own previews.
func corridor(core: RefCounted, state: Dictionary, offset: Vector2i, _unused := 0) -> Array:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var a := Vector2i(int(tile[0]), int(tile[1]))
		var b := a + offset
		var plan: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, b.x, b.y])
		if plan.get("complete", false) and int(plan.new) == absi(offset.x) + absi(offset.y) + 1 and int(plan.existing) == 0:
			return [a, b, plan]
	return []

func contiguous(plan: Dictionary, a: Vector2i, b: Vector2i) -> bool:
	var tiles: Array = plan.tiles
	if tiles.is_empty() or Vector2i(int(tiles[0][0]), int(tiles[0][1])) != a or Vector2i(int(tiles[-1][0]), int(tiles[-1][1])) != b:
		return false
	for index in range(1, tiles.size()):
		var step := absi(int(tiles[index][0]) - int(tiles[index - 1][0])) + absi(int(tiles[index][1]) - int(tiles[index - 1][1]))
		if step != 1:
			return false
	return true

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	var before: Dictionary = core.snapshot(true)
	var found := corridor(core, before, Vector2i(6, 0))
	check(not found.is_empty(), "a free straight corridor for a drag is found with the native preview")
	if found.is_empty():
		quit(1)
		return
	var a: Vector2i = found[0]
	var b: Vector2i = found[1]
	var plan: Dictionary = found[2]
	var unit: Dictionary = core.command("preview road %d %d 0" % [a.x, a.y])
	check(contiguous(plan, a, b) and plan.tiles.size() == 7, "the drag path runs tile by tile from the press to the release (%d tiles)" % plan.tiles.size())
	check(int(plan.unit_cost) == int(unit.cost) and int(plan.cost) == 7 * int(unit.cost) and plan.valid, "the cost is the native road cost per new tile (%d each)" % int(plan.unit_cost))
	var unchanged: Dictionary = core.snapshot(true)
	check(unchanged.money == before.money and unchanged.time == before.time and unchanged.tiles == before.tiles and unchanged.buildings == before.buildings, "previewing a drag does not change the city")
	var diagonal := corridor(core, before, Vector2i(4, 5))
	if not diagonal.is_empty():
		check(contiguous(diagonal[2], diagonal[0], diagonal[1]) and diagonal[2].tiles.size() == 10, "a diagonal drag becomes an orthogonal staircase of tiles")
	var single: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, a.x, a.y])
	check(single.complete and int(single.new) == 1 and int(single.cost) == int(unit.cost), "a drag that ends on its start is one ordinary road tile")

	var built: Dictionary = core.command("build_road %d %d %d %d" % [a.x, a.y, b.x, b.y])
	check(not built.has("error") and int(built.money) == int(before.money) - int(plan.cost), "building the drag charges exactly the previewed cost")
	var after: Dictionary = core.snapshot(true)
	var roads := road_cells(after)
	var every := true
	for tile in plan.tiles:
		every = every and roads.has(Vector2i(int(tile[0]), int(tile[1])))
	check(every and roads.size() == road_cells(before).size() + 7, "every tile of the path is now a road")
	check(built.undo_available, "the drag can be undone")
	# One undo step takes the whole drag back (the native game keeps only the latest construction to undo).
	var restored: Dictionary = core.command("undo")
	var final_roads := road_cells(core.snapshot(true))
	check(not restored.has("error") and int(restored.money) == int(before.money) and final_roads.size() == road_cells(before).size() and not restored.undo_available, "one undo removes the entire drag and refunds its exact cost")
	check(core.command("preview_road %d %d %d %d" % [a.x, a.y, b.x, b.y]).complete, "the removed road can be dragged again")
	core.command("build_road %d %d %d %d" % [a.x, a.y, b.x, b.y])
	var charged: int = core.snapshot(false).money
	var again: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, b.x, b.y])
	check(int(again.existing) == 7 and int(again.new) == 0 and int(again.cost) == 0 and not again.valid and again.reason == "nothing_to_build", "dragging over finished road costs nothing and says so")
	check(core.command("build_road %d %d %d %d" % [a.x, a.y, b.x, b.y]).has("error") and core.snapshot(false).money == charged, "building over finished road is refused without a charge")

	# Extending an existing road pays only for the new tiles.
	var c := Vector2i(b.x + 1, b.y)
	var extension: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, c.x, c.y])
	if extension.get("path_found", false) and extension.complete:
		check(int(extension.existing) == 7 and int(extension.new) == 1, "extending a road counts the old tiles as existing and one new tile")
		var extended: Dictionary = core.command("build_road %d %d %d %d" % [a.x, a.y, c.x, c.y])
		check(int(extended.money) == charged - int(unit.cost), "extending charges only the new tile")
		var undone_extension: Dictionary = core.command("undo")
		check(int(undone_extension.money) == charged and road_cells(core.snapshot(true)).size() == road_cells(before).size() + 7, "undoing the extension removes only the new tile")
	core.command("demolish %d %d 0" % [a.x, a.y])

	# Rejections never charge or change anything.
	var snapshot_before: Dictionary = core.snapshot(true)
	var ruins := Vector2i(99999, 99999)
	for entry in snapshot_before.buildings:
		if int(entry.w) >= 2:
			ruins = Vector2i(int(entry.x), int(entry.y))
			break
	var into_building: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, ruins.x, ruins.y])
	check(not into_building.get("valid", true) or not into_building.get("complete", true), "a drag ending inside a building is not accepted as a complete road")
	var unreachable: Dictionary = core.command("build_road %d %d %d %d" % [a.x, a.y, ruins.x, ruins.y])
	var after_rejection: Dictionary = core.snapshot(true)
	check(after_rejection.money == snapshot_before.money and road_cells(after_rejection).size() == road_cells(snapshot_before).size() or not unreachable.has("error"), "a refused drag leaves the treasury and map as they were")
	check(core.command("preview_road %d %d 2147483647 2147483647" % [a.x, a.y]).has("error") or not core.command("preview_road %d %d 2147483647 2147483647" % [a.x, a.y]).get("path_found", true), "extreme coordinates are rejected safely")
	check(core.command("build_road 1 2 3").has("error"), "a malformed drag command is rejected")
	var far: Dictionary = core.command("preview_road %d %d %d %d" % [a.x, a.y, a.x + 150, a.y])
	check(not far.get("complete", true), "a drag beyond the native search distance (100 tiles) is not a complete path")
	core.close_city()
	print("ROAD_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
