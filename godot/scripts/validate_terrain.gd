extends SceneTree

const TerrainStyle = preload("res://scripts/terrain_presentation.gd")
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("TERRAIN_CHECK ", "PASS " if value else "FAIL ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var initial: Dictionary = core.open_city(engine, save, "en")
	check(initial.has("protocol") and initial.paused, "designated native city loads paused")
	if not okay:
		quit(1)
		return
	var tiles := {}
	var cells: Array[Vector2i] = []
	for tile in initial.tiles:
		var cell := Vector2i(int(tile[0]), int(tile[1]))
		tiles[cell] = tile.duplicate()
		cells.append(cell)
	var origin := Vector2i(int(initial.origin[0]), int(initial.origin[1]))
	var extent := Vector2i(int(initial.extent[0]), int(initial.extent[1]))
	var style := TerrainStyle.new()
	style.update(tiles, origin, extent, cells)
	check(tiles.size() == 25992 and extent == Vector2i(228, 227), "actual irregular map and bounding rectangle retained")
	check(style.field_image.get_size() == extent and style.field_image.get_format() == Image.FORMAT_RGBAH, "signed coastal field retains negative land values")
	var native_classes := true
	var finite := true
	var water_levels := true
	var vegetation := true
	var roads := true
	var near_depth := 0.0
	var far_depth := 0.0
	var shoreline := Vector2i.ZERO
	for cell in cells:
		var tile: Array = tiles[cell]
		var flags := int(tile[3])
		var data := style.field_image.get_pixelv(cell - origin)
		native_classes = native_classes and ((data.r > 0) == bool(flags & 4))
		finite = finite and is_finite(data.r) and absf(data.r) >= .5 and absf(data.r) <= 8
		if flags & 4:
			water_levels = water_levels and style.water_height(tiles, cell) == float(tile[2])
			far_depth = maxf(far_depth, data.r)
			if data.r <= .5:
				near_depth = data.r
				shoreline = cell
		if flags & 16:
			vegetation = vegetation and is_equal_approx(data.g, .75)
		elif flags & 8:
			vegetation = vegetation and data.g == 0 and data.b == 1.0
		roads = roads and ((style.road_image.get_pixelv(cell - origin).r > .5) == bool(int(tile[4])))
	check(native_classes, "every native water/land center keeps its original classification")
	check(finite, "all native coastal distances are finite and bounded")
	check(near_depth == .5 and far_depth > 4, "channel shallows and deep open water have distinct distances")
	check(water_levels, "water surfaces use native altitude without rounding")
	check(vegetation, "forest keeps its material weight; fertile meadow has its own channel")
	check(roads, "road material mask matches the entire native road network")
	var empty_cells := 0
	var holes_empty := true
	for y in range(extent.y):
		for x in range(extent.x):
			var cell := origin + Vector2i(x, y)
			if not tiles.has(cell):
				empty_cells += 1
				holes_empty = holes_empty and style.water_height(tiles, cell) == null
	check(empty_cells > 0 and holes_empty, "unused bounding cells produce no water apron geometry")
	var final: Dictionary = core.snapshot(true)
	check(final.tiles == initial.tiles and final.buildings == initial.buildings and final.walkers == initial.walkers and final.time == initial.time and final.money == initial.money, "material creation does not mutate any native city state")
	var field_id := style.field_texture.get_instance_id()
	var road_id := style.road_texture.get_instance_id()
	var old: Array = tiles[shoreline].duplicate()
	var changed: Array[Vector2i] = [shoreline]
	# Alter only the presentation copy to exercise future editor refresh behavior.
	tiles[shoreline][4] = 1 - int(old[4])
	# Current snapshots carry a road-kind column as well as the occupied mask.
	if tiles[shoreline].size() >= 9:
		tiles[shoreline][8] = int(tiles[shoreline][4])
	style.update(tiles, origin, extent, changed)
	check(style.coastline_rebuilds == 1 and style.field_texture.get_instance_id() == field_id and style.road_texture.get_instance_id() == road_id, "road-only updates reuse textures and the coast distance cache")
	check((style.road_image.get_pixelv(shoreline - origin).r > .5) == bool(int(tiles[shoreline][4])), "incremental road edits refresh the material")
	tiles[shoreline][3] = 16
	style.update(tiles, origin, extent, changed)
	check(style.coastline_rebuilds == 2 and style.field_image.get_pixelv(shoreline - origin).r < 0, "a water-mask edit refreshes the coastline immediately")
	check(style.field_image.get_pixelv(shoreline - origin).g == .75, "a changed tile refreshes vegetation with its coastline")
	tiles[shoreline][3] = 1
	style.update(tiles, origin, extent, changed)
	check(style.coastline_rebuilds == 2 and style.field_image.get_pixelv(shoreline - origin).g == 0, "forest clearing removes vegetation without rebuilding an unchanged coastline")
	tiles[shoreline] = old
	style.update(tiles, origin, extent, changed)
	check(style.coastline_rebuilds == 3 and style.field_image.get_pixelv(shoreline - origin).r > 0, "reversing a water-mask edit restores the coast classification")
	final = core.snapshot(true)
	check(final.tiles == initial.tiles and final.time == initial.time and final.money == initial.money, "presentation-copy refresh tests leave native terrain and paused clock intact")
	var report := {"pass":okay,"checks":checks,"tiles":tiles.size(),"unused_cells":empty_cells,"distance_range":[near_depth,far_depth]}
	var file := FileAccess.open("res://captures/terrain-validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	core.close_city()
	print("TERRAIN_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
