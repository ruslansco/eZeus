extends SceneTree
# Walls, towers and gatehouses against the embedded core (headless, in memory): the wall drag follows the SDL rule
# (the outline of the dragged rectangle, all of it with fill), the pieces join their neighbours, a tower is a plain 2x2
# building, and a gatehouse lays two towers around a road passage in either direction. Costs, undo and demolition are
# the native ones; previews change nothing.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("WALL_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func free_cells(state: Dictionary) -> Dictionary:
	var result := {}
	for tile in state.tiles:
		if int(tile[5]):
			result[Vector2i(int(tile[0]), int(tile[1]))] = true
	return result

func has_area(free: Dictionary, origin: Vector2i, w: int, h: int) -> bool:
	for dx in w:
		for dy in h:
			if not free.has(origin + Vector2i(dx, dy)):
				return false
	return true

# The first origin, scanning the tiles in order, whose w x h block is free and that the core's own preview accepts.
func find_site(core: RefCounted, state: Dictionary, name: String, w: int, h: int, orientation := 0, skip := []) -> Vector2i:
	var free := free_cells(state)
	for tile in state.tiles:
		var origin := Vector2i(int(tile[0]), int(tile[1]))
		if not has_area(free, origin, w, h) or origin in skip:
			continue
		if core.command("preview %s %d %d %d" % [name, origin.x, origin.y, orientation]).get("valid", false):
			return origin
	return Vector2i(-1, -1)

func settle(core: RefCounted) -> void:
	core.command("pause 0")
	for i in 30:
		core.advance(.05)
	core.command("pause 1")

func pieces(state: Dictionary, prefix: String) -> Array:
	return state.buildings.filter(func(b): return String(b.asset).begins_with(prefix))

func wall_masks(state: Dictionary) -> Dictionary:
	var result := {}
	for b in pieces(state, "wall_"):
		result[Vector2i(int(b.x), int(b.y))] = int(String(b.asset).trim_prefix("wall_"))
	return result

func plan_mask(plan: Dictionary, cell: Vector2i) -> int:
	for tile in plan.tiles:
		if int(tile[0]) == cell.x and int(tile[1]) == cell.y:
			return int(tile[5])
	return -1

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	var listed: Dictionary = {}
	for item in core.command("buildable").buildings:
		listed[item.name] = item
	for name in ["wall", "tower", "gatehouse"]:
		check(listed.has(name) and listed[name].available and listed[name].asset != "unconverted", name + " is offered with a model")
	check(listed.wall.w == 1 and listed.tower.w == 2 and listed.gatehouse.w == 5 and listed.gatehouse.h == 2, "footprints are the native ones (1x1, 2x2, 5x2)")
	var before: Dictionary = core.snapshot(true)
	var free := free_cells(before)

	# ------------------------------------------------------------------ walls
	var origin := Vector2i(-1, -1)
	for tile in before.tiles:
		var a := Vector2i(int(tile[0]), int(tile[1]))
		if has_area(free, a, 6, 5) and core.command("preview_wall %d %d %d %d 0" % [a.x, a.y, a.x + 5, a.y + 4]).get("complete", false):
			origin = a
			break
	check(origin.x >= 0, "a free 6x5 plot for a wall rectangle is found")
	if origin.x < 0:
		quit(1)
		return
	var far := origin + Vector2i(5, 4)
	var plan: Dictionary = core.command("preview_wall %d %d %d %d 0" % [origin.x, origin.y, far.x, far.y])
	var unit: Dictionary = core.command("preview wall %d %d 0" % [origin.x, origin.y])
	check(int(plan.new) == 2 * (6 + 5) - 4 and plan.tiles.size() == 18, "a dragged rectangle is walled along its outline (18 tiles)")
	check(int(plan.unit_cost) == int(unit.cost) and int(plan.cost) == 18 * int(unit.cost) and plan.valid and plan.complete, "the cost is the native wall cost per tile (%d each)" % int(plan.unit_cost))
	check(plan_mask(plan, origin) == 10 and plan_mask(plan, origin + Vector2i(2, 0)) == 3 and plan_mask(plan, origin + Vector2i(0, 2)) == 12 and plan_mask(plan, far) == 5, "the preview joins pieces: a corner meets two neighbours, a run meets two")
	var filled: Dictionary = core.command("preview_wall %d %d %d %d 1" % [origin.x, origin.y, far.x, far.y])
	check(int(filled.new) == 30 and filled.tiles.size() == 30 and plan_mask(filled, origin + Vector2i(2, 2)) == 15, "with fill the whole rectangle is walled and the inside pieces join on all four sides")
	var unchanged: Dictionary = core.snapshot(true)
	check(unchanged.money == before.money and unchanged.time == before.time and unchanged.tiles == before.tiles and unchanged.buildings == before.buildings, "previewing walls does not change the city")
	var single: Dictionary = core.command("preview_wall %d %d %d %d 0" % [origin.x, origin.y, origin.x, origin.y])
	check(int(single.new) == 1 and int(single.cost) == int(unit.cost) and plan_mask(single, origin) == 0, "a drag that ends on its start is one lone wall")

	var built: Dictionary = core.command("build_wall %d %d %d %d 0" % [origin.x, origin.y, far.x, far.y])
	check(not built.has("error") and int(built.money) == int(before.money) - int(plan.cost), "building the drag charges exactly the previewed cost")
	var after: Dictionary = core.snapshot(true)
	var masks := wall_masks(after)
	check(masks.size() == wall_masks(before).size() + 18, "eighteen walls were built")
	var matches := true
	for tile in plan.tiles:
		matches = matches and masks.get(Vector2i(int(tile[0]), int(tile[1])), -1) == int(tile[5])
	check(matches, "every built wall shows the connections the preview promised")
	check(built.undo_available, "the drag can be undone")
	var again: Dictionary = core.command("preview_wall %d %d %d %d 0" % [origin.x, origin.y, far.x, far.y])
	check(not again.valid and int(again.new) == 0 and int(again.cost) == 0 and again.reason == "occupied", "dragging over finished wall costs nothing and says it is occupied")
	var restored: Dictionary = core.command("undo")
	check(not restored.has("error") and int(restored.money) == int(before.money) and wall_masks(core.snapshot(true)).size() == wall_masks(before).size() and not restored.undo_available, "one undo removes the whole drag and refunds its exact cost")

	# A new piece changes how its neighbours look; removing it changes them back.
	core.command("build_wall %d %d %d %d 0" % [origin.x, origin.y, origin.x + 2, origin.y])
	var line := wall_masks(core.snapshot(true))
	check(line.get(origin) == 2 and line.get(origin + Vector2i(1, 0)) == 3 and line.get(origin + Vector2i(2, 0)) == 1, "a line of three walls: ends meet one neighbour, the middle meets two")
	core.command("build_wall %d %d %d %d 0" % [origin.x + 2, origin.y + 1, origin.x + 2, origin.y + 1])
	check(wall_masks(core.snapshot(true)).get(origin + Vector2i(2, 0)) == 9, "a wall built beside the end of the line changes the end's connections")
	core.command("undo")
	check(wall_masks(core.snapshot(true)).get(origin + Vector2i(2, 0)) == 1, "and undoing that wall changes them back")
	core.command("undo")

	# ------------------------------------------------------------------ tower
	var tower_site := find_site(core, core.snapshot(true), "tower", 2, 2)
	check(tower_site.x >= 0, "a free 2x2 site for a tower is found")
	var money_before: int = core.snapshot(false).money
	var tower_plan: Dictionary = core.command("preview tower %d %d 0" % [tower_site.x, tower_site.y])
	check(tower_plan.valid and tower_plan.w == 2 and tower_plan.h == 2 and tower_plan.asset == "tower", "the tower previews as a 2x2 building with its model")
	var tower_built: Dictionary = core.command("build tower %d %d 0" % [tower_site.x, tower_site.y])
	check(not tower_built.has("error") and int(tower_built.money) == money_before - int(tower_plan.cost), "building the tower charges its native cost (%d)" % int(tower_plan.cost))
	var towers := pieces(core.snapshot(true), "tower")
	check(towers.size() >= 1 and towers.any(func(b): return int(b.x) == tower_site.x and int(b.y) == tower_site.y and int(b.w) == 2 and int(b.orientation) == 0), "the tower is in the snapshot with its footprint")
	var undone_tower: Dictionary = core.command("undo")
	check(not undone_tower.has("error") and int(undone_tower.money) == money_before and pieces(core.snapshot(true), "tower").is_empty(), "undoing the tower refunds its cost and removes it")
	# A wall beside a tower joins it (the native rule counts towers and gatehouses as wall).
	core.command("build tower %d %d 0" % [tower_site.x, tower_site.y])
	var beside := tower_site + Vector2i(2, 0)
	if core.command("preview wall %d %d 0" % [beside.x, beside.y]).get("valid", false):
		core.command("build_wall %d %d %d %d 0" % [beside.x, beside.y, beside.x, beside.y])
		check(wall_masks(core.snapshot(true)).get(beside) == 1, "a wall beside a tower joins it")
		core.command("demolish %d %d 0" % [beside.x, beside.y])
	core.command("demolish %d %d 0" % [tower_site.x, tower_site.y])
	settle(core)
	check(pieces(core.snapshot(true), "tower").is_empty(), "a tower can be demolished")

	# --------------------------------------------------------------- gatehouse
	for turned in [0, 1]:
		var w := 2 if turned else 5
		var h := 5 if turned else 2
		var site := find_site(core, core.snapshot(true), "gatehouse", w, h, turned)
		check(site.x >= 0, "a free %dx%d site for a gatehouse is found" % [w, h])
		if site.x < 0:
			continue
		var money: int = core.snapshot(false).money
		var gate_plan: Dictionary = core.command("preview gatehouse %d %d %d" % [site.x, site.y, turned])
		check(gate_plan.valid and gate_plan.w == w and gate_plan.h == h and gate_plan.orientation == turned and gate_plan.tiles.size() == 10 and gate_plan.asset == "gatehouse", "the gatehouse previews as %dx%d, turned %d, over ten tiles" % [w, h, turned])
		var cost_before: int = core.snapshot(false).money
		var gate: Dictionary = core.command("build gatehouse %d %d %d" % [site.x, site.y, turned])
		check(not gate.has("error") and int(gate.money) == money - int(gate_plan.cost), "building the gatehouse charges its native cost once (%d)" % int(gate_plan.cost))
		var state: Dictionary = core.snapshot(true)
		var gates := pieces(state, "gatehouse")
		check(gates.size() == 1 and int(gates[0].x) == site.x and int(gates[0].y) == site.y and int(gates[0].w) == w and int(gates[0].h) == h and int(gates[0].orientation) == turned, "one gatehouse stands on the footprint, facing as asked")
		# The passage is road: the middle strip between the two 2x2 blocks.
		var roads := {}
		for tile in state.tiles:
			if int(tile[4]) == 1:
				roads[Vector2i(int(tile[0]), int(tile[1]))] = true
		var passage := [site + Vector2i(0, 2), site + Vector2i(1, 2)] if turned else [site + Vector2i(2, 0), site + Vector2i(2, 1)]
		check(roads.has(passage[0]) and roads.has(passage[1]), "the two passage tiles are road")
		# Building over the gatehouse is refused tile by tile.
		var over: Dictionary = core.command("preview gatehouse %d %d %d" % [site.x, site.y, turned])
		check(not over.valid and over.reason == "occupied", "a second gatehouse cannot take the same ground")
		var crossing: Dictionary = core.command("preview gatehouse %d %d %d" % [passage[0].x - (1 - turned) * 2, passage[0].y - turned * 2, 1 - turned])
		check(not crossing.valid, "nor can one cross the first one's passage")
		# Demolition from a passage tile removes the gatehouse, not just the street, and leaves the road.
		var demolition: Dictionary = core.command("preview demolish %d %d 0" % [passage[0].x, passage[0].y])
		check(demolition.valid and demolition.w == w and demolition.h == h, "demolishing a passage tile targets the whole gatehouse")
		core.command("demolish %d %d 0" % [passage[0].x, passage[0].y])
		settle(core)
		var removed: Dictionary = core.snapshot(true)
		var free_now := free_cells(removed)
		var road_now := {}
		for tile in removed.tiles:
			if int(tile[4]) == 1:
				road_now[Vector2i(int(tile[0]), int(tile[1]))] = true
		# The native rule: the gatehouse's ten tiles are emptied, the passage with them.
		check(pieces(removed, "gatehouse").is_empty() and free_now.has(passage[0]) and free_now.has(passage[1]) and not road_now.has(passage[0]), "the gatehouse is gone and its passage with it, leaving free ground")
		core.command("undo")
		# Undo of a fresh build removes the gatehouse and the road it laid.
		var fresh: Dictionary = core.command("build gatehouse %d %d %d" % [site.x, site.y, turned])
		var undone: Dictionary = core.command("undo")
		var gone: Dictionary = core.snapshot(true)
		var gone_roads := {}
		for tile in gone.tiles:
			if int(tile[4]) == 1:
				gone_roads[Vector2i(int(tile[0]), int(tile[1]))] = true
		check(not fresh.has("error") and pieces(gone, "gatehouse").is_empty() and int(undone.money) == int(core.snapshot(false).money) and not gone_roads.has(passage[0]), "undo removes the new gatehouse and the passage road it laid")

	# An existing street may carry the passage (the gatehouse takes it over).
	var site := find_site(core, core.snapshot(true), "gatehouse", 5, 2)
	if site.x >= 0:
		var street_a := site + Vector2i(2, 0)
		var street_b := site + Vector2i(2, 1)
		core.command("build_road %d %d %d %d" % [street_a.x, street_a.y, street_b.x, street_b.y])
		var on_street: Dictionary = core.command("preview gatehouse %d %d 0" % [site.x, site.y])
		check(on_street.valid, "a gatehouse may be laid across an existing street")
		var money: int = core.snapshot(false).money
		var crossed: Dictionary = core.command("build gatehouse %d %d 0" % [site.x, site.y])
		check(not crossed.has("error") and int(crossed.money) == money - int(on_street.cost), "it charges only the gatehouse, not the street again")
		var undone_gate: Dictionary = core.command("undo")
		var street_state: Dictionary = core.snapshot(true)
		var street_free := free_cells(street_state)
		check(not undone_gate.has("error") and int(undone_gate.money) == money and pieces(street_state, "gatehouse").is_empty() and street_free.has(street_a) and street_free.has(street_b), "undoing it refunds the gatehouse and, as demolishing does, empties the passage")

	# Saved and reloaded: standing defences come back as they were, and the passage of a demolished gatehouse does not.
	var scratch := ProjectSettings.globalize_path("user://validation_walls_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	core.set_save_directory(scratch)
	var standing := find_site(core, core.snapshot(true), "gatehouse", 5, 2)
	core.command("build gatehouse %d %d 0" % [standing.x, standing.y])
	var lost := find_site(core, core.snapshot(true), "gatehouse", 5, 2)
	core.command("build gatehouse %d %d 0" % [lost.x, lost.y])
	core.command("demolish %d %d 0" % [lost.x + 2, lost.y])
	settle(core)
	var tower_spot := find_site(core, core.snapshot(true), "tower", 2, 2)
	core.command("build tower %d %d 0" % [tower_spot.x, tower_spot.y])
	var wall_spot := Vector2i(-1, -1)
	for tile in core.snapshot(true).tiles:
		if int(tile[5]) and core.command("preview_wall %d %d %d %d 0" % [tile[0], tile[1], int(tile[0]) + 5, tile[1]]).get("new", 0) == 6:
			wall_spot = Vector2i(int(tile[0]), int(tile[1]))
			break
	core.command("build_wall %d %d %d %d 0" % [wall_spot.x, wall_spot.y, wall_spot.x + 5, wall_spot.y])
	var before_save: Dictionary = core.snapshot(true)
	var wanted: Array = before_save.buildings.filter(func(b): return b.asset == "gatehouse" or b.asset == "tower" or String(b.asset).begins_with("wall_")).map(func(b): return "%s@%d,%d %dx%d o%d" % [b.asset, b.x, b.y, b.w, b.h, b.orientation])
	check(core.save_city("defences").has("saved"), "a city with walls, a tower and gatehouses can be saved")
	core.close_city()
	var reopened: Dictionary = core.open_city(engine, scratch.path_join("defences.ez"), "en")
	var after_load: Dictionary = core.snapshot(true)
	var found: Array = after_load.buildings.filter(func(b): return b.asset == "gatehouse" or b.asset == "tower" or String(b.asset).begins_with("wall_")).map(func(b): return "%s@%d,%d %dx%d o%d" % [b.asset, b.x, b.y, b.w, b.h, b.orientation])
	wanted.sort()
	found.sort()
	check(reopened.has("protocol") and found == wanted, "the reopened city has the same walls (with their connections), tower and gatehouse")
	var gate_free := free_cells(after_load)
	var passage_road := false
	for tile in after_load.tiles:
		if int(tile[0]) == lost.x + 2 and int(tile[1]) == lost.y and int(tile[4]) == 1:
			passage_road = true
	check(not passage_road and gate_free.has(Vector2i(lost.x + 2, lost.y)), "the passage of the demolished gatehouse did not come back as a road")
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)

	# ---------------------------------------------------------------- rejection
	var snapshot_before: Dictionary = core.snapshot(true)
	var blocked_gate := Vector2i(-1, -1)
	for entry in snapshot_before.buildings:
		if int(entry.w) >= 2 and not String(entry.asset).begins_with("wall_") and not core.command("preview gatehouse %d %d 0" % [entry.x, entry.y]).has("error"):
			blocked_gate = Vector2i(int(entry.x), int(entry.y))
			break
	if blocked_gate.x >= 0:
		var over_building: Dictionary = core.command("preview gatehouse %d %d 0" % [blocked_gate.x, blocked_gate.y])
		check(not over_building.valid, "a gatehouse overlapping a building is refused")
		var refused: Dictionary = core.command("build gatehouse %d %d 0" % [blocked_gate.x, blocked_gate.y])
		check(refused.has("error") and core.snapshot(false).money == snapshot_before.money, "refusing it charges nothing")
		var wall_over: Dictionary = core.command("preview_wall %d %d %d %d 0" % [blocked_gate.x, blocked_gate.y, blocked_gate.x, blocked_gate.y])
		check(not wall_over.get("valid", true) and wall_over.get("reason", "") == "occupied", "a wall cannot be put on a building")
	check(core.command("build_wall 1 2 3").has("error") and core.command("preview_wall x y").has("error"), "malformed wall commands are rejected")
	check(core.command("preview_wall 99999 99999 100000 100000 0").has("error"), "a drag off the map is rejected")
	var corner := Vector2i(int(before.tiles[0][0]), int(before.tiles[0][1]))
	var huge: Dictionary = core.command("preview_wall %d %d %d %d 1" % [corner.x, corner.y, corner.x + 300, corner.y + 300])
	print("WALL_INFO huge drag: ", huge.get("new"), " new, ", huge.get("tiles", []).size(), " listed")
	check(huge.get("truncated", false) and huge.tiles.size() <= 3000, "an enormous filled drag lists a bounded set of tiles")
	# Last, because running the city brings the campaign's own events, which hold further commands until answered.
	# A staffed tower puts an archer on its platform; the presentation lifts the figure onto the roof.
	var late_site := find_site(core, core.snapshot(true), "tower", 2, 2)
	var late_tower: Dictionary = core.command("build tower %d %d 0" % [late_site.x, late_site.y])
	check(not late_tower.has("error"), "a tower can be built again at the end")
	core.command("speed 3")
	core.command("pause 0")
	var archers: Array = []
	for step in 400:
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		# The campaign's own requests pause the city until answered: put each one off.
		for event in running.get("events", []):
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		archers = running.walkers.filter(func(w): return str(w.asset) in ["walker_archer", "walker_archerposeidon"])
		if not archers.is_empty():
			break
	core.command("pause 1")
	check(not archers.is_empty() and absf(float(archers[0].get("lift", 0.0)) - 2.57) < .001, "the tower's archer is shown with an archer model (Greek or Atlantean), standing on the platform (lift 2.57)")
	check(core.snapshot(false).walkers.all(func(w): return str(w.asset) != "unconverted"), "no walker is left without a model")

	core.close_city()
	print("WALL_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
