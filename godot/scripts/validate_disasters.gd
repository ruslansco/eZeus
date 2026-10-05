extends SceneTree
# Disasters in the 3D city (headless, in memory; the designated save is never written): a burning building is listed in the
# snapshot's `fires`; brought down it leaves ruins, each tile one of the eight ruins models; an earthquake turns ground into chasm
# tiles as the city runs; lava and marsh tiles carry their terrain bits, and the ground's pattern texture marks all three.
const TerrainPresentation = preload("res://scripts/terrain_presentation.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("DISASTERS_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	core.enable_test_commands()
	return opened

func tiles_of(state: Dictionary) -> Dictionary:
	var out := {}
	for tile in state.get("tiles", []):
		out[Vector2i(int(tile[0]), int(tile[1]))] = tile
	return out

func run() -> void:
	var presentation := TerrainPresentation.new()
	check(presentation.mineral_pattern(2048) == Color(0, 1, 0, 0) and presentation.mineral_pattern(32768) == Color(0, 0, 1, 0)
		and presentation.mineral_pattern(16384) == Color(0, 0, 0, 1) and presentation.mineral_pattern(1024) == Color(1, 0, 0, 0)
		and presentation.mineral_pattern(1) == Color(0, 0, 0, 0), "the ground's pattern marks chasm, lava and marsh apart from quarries")
	for v in 8:
		check(ResourceLoader.exists("res://assets/models/ruins_%d.glb" % v) and FileAccess.file_exists("res://assets/models/ruins_%d.json" % v), "ruins model %d exists" % v)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var state: Dictionary = open(core, "en")
	check(state.has("protocol") and state.get("fires", null) is Array, "the full snapshot lists the fires (%d)" % state.get("fires", []).size())
	# A 2x2 house set burning, then brought down.
	var house := {}
	for building in state.buildings:
		if str(building.asset).begins_with("common_house") and int(building.w) == 2:
			house = building
			break
	check(not house.is_empty(), "a house to set on fire (%s)" % house.get("asset", ""))
	if not house.is_empty():
		var x := int(house.x)
		var y := int(house.y)
		core.command("test_fire %d %d" % [x, y])
		var burning: Dictionary = core.snapshot(false)
		var fires: Array = burning.get("fires", [])
		var listed := fires.filter(func(f): return int(f[0]) == x and int(f[1]) == y and int(f[2]) == 2 and int(f[3]) == 2 and int(f[5]) == 0)
		check(listed.size() == 1, "the burning house is listed with its footprint (%s)" % str(fires))
		check(core.snapshot(false).get("fires", null) == null, "an unchanged fire list is not sent again")
		var down: Dictionary = core.command("test_collapse %d %d" % [x, y])
		var full: Dictionary = core.snapshot(true)
		var ruins: Array = full.buildings.filter(func(b): return str(b.asset).begins_with("ruins_") and int(b.x) >= x and int(b.x) < x + 2 and int(b.y) >= y and int(b.y) < y + 2)
		check(ruins.size() >= 1 and ruins.all(func(b): return int(b.w) == 1 and int(b.h) == 1 and ResourceLoader.exists("res://assets/models/%s.glb" % b.asset)),
			"the house comes down as ruins, each tile a ruins model (%s)" % str(ruins.map(func(b): return b.asset)))
		var rubble_fires: Array = full.fires.filter(func(f): return int(f[5]) == 1)
		check(full.fires.filter(func(f): return int(f[0]) == x and int(f[1]) == y and int(f[5]) == 0).is_empty(), "the house's own fire is gone (%d ruins still smoulder)" % rubble_fires.size())
	# An earthquake on open ground some way off.
	var tiles := tiles_of(state)
	var spot := Vector2i(99999, 99999)
	for cell in tiles:
		var tile: Array = tiles[cell]
		if int(tile[5]) and not int(tile[4]):
			var clear := true
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var near: Array = tiles.get(cell + Vector2i(dx, dy), [])
					clear = clear and not near.is_empty() and int(near[5]) == 1
			if clear:
				spot = cell
				break
	check(spot.x != 99999, "open ground for an earthquake (%s)" % str(spot))
	if spot.x != 99999:
		core.command("test_earthquake %d %d 12" % [spot.x, spot.y])
		core.command("pause 0")
		for step in 80:
			core.advance(0.25)
		core.command("pause 1")
		var after := tiles_of(core.snapshot(true))
		var chasm := after.values().filter(func(t): return int(t[3]) & 2048)
		check(chasm.size() >= 1, "the earthquake opens chasm tiles as the city runs (%d)" % chasm.size())
		check(chasm.all(func(t): return int(t[5]) == 0), "nothing can be built on a chasm")
	# Lava and marsh.
	var lava_at := Vector2i(99999, 99999)
	var marsh_at := Vector2i(99999, 99999)
	var quake_at := Vector2i(99999, 99999)
	for cell in tiles:
		var tile: Array = tiles[cell]
		if int(tile[5]) and not int(tile[4]) and Vector2(cell).distance_to(Vector2(spot)) > 20.0:
			if lava_at.x == 99999:
				lava_at = cell
			elif marsh_at.x == 99999 and Vector2(cell).distance_to(Vector2(lava_at)) > 8.0:
				marsh_at = cell
			elif quake_at.x == 99999 and Vector2(cell).distance_to(Vector2(lava_at)) > 8.0 and Vector2(cell).distance_to(Vector2(marsh_at)) > 8.0:
				quake_at = cell
				break
	var quake: Dictionary = core.command("test_terrain quake %d %d 2" % [quake_at.x, quake_at.y])
	var lava: Dictionary = core.command("test_terrain lava %d %d 2" % [lava_at.x, lava_at.y])
	var marsh: Dictionary = core.command("test_terrain marsh %d %d 2" % [marsh_at.x, marsh_at.y])
	var later := tiles_of(core.snapshot(true))
	check(int(quake.get("changed", 0)) > 0 and int(later[quake_at][3]) & 2048, "chasm tiles carry the quake bit (%d, %s)" % [int(quake.get("changed", 0)), str(later.get(quake_at, []))])
	check(int(lava.get("changed", 0)) > 0 and int(later[lava_at][3]) & 32768, "lava tiles carry the lava bit (%d)" % int(lava.get("changed", 0)))
	check(int(marsh.get("changed", 0)) > 0 and int(later[marsh_at][3]) & 16384, "marsh tiles carry the marsh bit (%d)" % int(marsh.get("changed", 0)))
	check(core.command("test_terrain mud 0 0 1").has("error") and core.command("test_fire 99999 99999").has("error"), "unknown ground and empty tiles are refused")
	core.close_city()
	print("DISASTERS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
