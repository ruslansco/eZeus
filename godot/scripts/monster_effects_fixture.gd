extends RefCounted
# Disposable designated-city fixture; invokes the native obstacle attack, not a
# presentation-side damage simulation. Never used by ordinary game code.

static func prepare(core: RefCounted, kind := "hydra") -> Dictionary:
	var state: Dictionary = core.snapshot(true)
	var cells := {}
	for row in state.tiles:
		cells[Vector2i(int(row[0]), int(row[1]))] = row
	var chosen := {}
	var source := Vector2i.ZERO
	for building in state.buildings:
		if str(building.asset) != "warehouse":
			continue
		for offset in [Vector2i(-2, 1), Vector2i(int(building.w) + 1, 1), Vector2i(1, -2), Vector2i(1, int(building.h) + 1)]:
			var at: Vector2i = Vector2i(int(building.x), int(building.y)) + offset
			if cells.has(at) and core.command("preview road %d %d 0" % [at.x, at.y]).get("valid", false):
				chosen = building
				source = at
				break
		if not chosen.is_empty():
			break
	if chosen.is_empty():
		return {"error": "no_isolated_warehouse"}
	var spawned: Dictionary = core.command("test_monster " + kind)
	if spawned.has("error"):
		return spawned
	state = core.snapshot(true)
	var asset := "walker_" + kind.replace("_", "")
	var mine: Array = state.walkers.filter(func(w): return str(w.asset) == asset)
	if mine.is_empty():
		return {"error": "no_monster_model"}
	var target := Vector2i(int(chosen.x) + int(chosen.w) / 2, int(chosen.y) + int(chosen.h) / 2)
	var strike: Dictionary = core.command("test_monster_strike %d %d %d %d %d" % [int(mine[0].id), source.x, source.y, target.x, target.y])
	if strike.has("error"):
		return strike
	return {"id": int(mine[0].id), "source": source, "target": target, "building": chosen, "asset": asset}
