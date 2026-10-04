extends SceneTree

const Geometry = preload("res://scripts/terrain_geometry.gd")
const Details = preload("res://scripts/terrain_details.gd")
const Presentation = preload("res://scripts/terrain_presentation.gd")
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = value and okay
	print("DETAIL_CHECK ","PASS " if value else "FAIL ",label)

func entries(detail: Node3D) -> Array:
	var result := []
	for section in detail.records.values():
		result.append_array(section)
	return result

func at_cell(detail: Node3D, cell: Vector2i) -> Array:
	return entries(detail).filter(func(item): return item.cell == cell)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),"en")
	if not initial.has("tiles"):
		check(false,"designated native city loads")
		quit(1)
		return
	var tiles := {}
	var changed: Array[Vector2i] = []
	for tile in initial.tiles:
		var cell := Vector2i(int(tile[0]),int(tile[1]))
		tiles[cell] = tile.duplicate()
		changed.append(cell)
	var origin := Vector2i(int(initial.origin[0]),int(initial.origin[1]))
	var extent := Vector2i(int(initial.extent[0]),int(initial.extent[1]))
	var geometry := Geometry.new()
	geometry.update(tiles,origin,extent,changed)
	var style := Presentation.new()
	style.update(tiles,origin,extent,changed)
	var detail := Details.new()
	get_root().add_child(detail)
	detail.update(tiles,origin,extent,geometry,changed)
	var original := entries(detail)
	var stats: Dictionary = detail.summary()
	check(tiles.size() == 25992 and extent == Vector2i(228,227),"only the designated full native map supplies detail")
	for specification in [[64,"stone"],[128,"copper"],[1024,"marble"],[4096,"orichalcum"]]:
		var expected := 0
		for tile in tiles.values():
			if int(tile[3]) & int(specification[0]) and not int(tile[4]) and not (int(tile[6]) & 8) and not (int(tile[3]) & 4):
				if specification[1] == "marble":
					var surrounded := true
					var cell := Vector2i(int(tile[0]),int(tile[1]))
					for delta in cardinal_offsets():
						var other: Array = tiles.get(cell+delta,[])
						surrounded = surrounded and not other.is_empty() and bool(int(other[3]) & 1024)
					if surrounded:
						continue
				expected += 1
		check(expected > 0 and stats.counts.get(specification[1],0) == expected,"%s outcrops match native deposits%s" % [specification[1]," at quarry perimeter cells" if specification[1] == "marble" else ""])
	var mineral_field := true
	for cell in tiles:
		# Only quarries keep a floor; rock outcrops alone mark the other deposits on green land.
		var quarry_floor: bool = bool(int(tiles[cell][3]) & (1024|8192))
		mineral_field = mineral_field and is_equal_approx(style.mineral_image.get_pixelv(cell-origin).a,1.0 if quarry_floor else 0.0)
	var empty_padding := true
	for y in range(extent.y):
		for x in range(extent.x):
			if not tiles.has(origin+Vector2i(x,y)):
				empty_padding = empty_padding and style.mineral_image.get_pixel(x,y).a == 0
	check(mineral_field and empty_padding,"quarry floors cover every marble cell; other deposits and empty-map padding keep the green ground")
	var mineral_texture := style.mineral_texture
	var coast_rebuilds: int = style.coastline_rebuilds
	check(style.ground_material.get_shader_parameter("mineral_data") == mineral_texture,"all ground sections use the shared mineral field")
	check(stats.counts.get("grass",0) > 0 and stats.counts.get("shrub",0) > 0,"forest edges have sparse grass and actual leaf/branch shrubs")
	var habitats := true
	var anchored := true
	var bounded := true
	var grass := Vector2i(99999,99999)
	var deposit := grass
	var boundary := grass
	for item in original:
		var cell: Vector2i = item.cell
		var tile: Array = tiles.get(cell,[])
		habitats = habitats and not tile.is_empty() and not int(tile[4]) and not (int(tile[6]) & 8) and not (int(tile[3]) & 4)
		if item.kind in ["grass","shrub"]:
			for y in range(-1,2):
				for x in range(-1,2):
					var other: Array = tiles.get(cell+Vector2i(x,y),[])
					habitats = habitats and not other.is_empty() and not int(other[4]) and not (int(other[6]) & 8) and int(other[3]) in [1,16,32]
			if item.kind == "grass" and int(tile[3]) == 1:
				grass = cell
				if posmod(cell.x-origin.x,24) in [0,23] or posmod(cell.y-origin.y,24) in [0,23]:
					boundary = cell
		elif item.kind == "copper":
			deposit = cell
		var position: Vector3 = item.transform.origin
		var x: float = position.x+origin.x+(extent.x-1)*.5
		var y: float = -position.z+origin.y+(extent.y-1)*.5
		anchored = anchored and absf(position.y-geometry.height_at(x,y)) < .00001
		var mesh: ArrayMesh = detail.mesh_for(item.kind,item.variant)
		for vertex in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var world: Vector3 = item.transform*vertex
			var dx: float = world.x+origin.x+(extent.x-1)*.5-cell.x
			var dy: float = -world.z+origin.y+(extent.y-1)*.5-cell.y
			bounded = bounded and absf(dx) < .48 and absf(dy) < .48 and is_finite(world.y)
	check(habitats,"no detail in water/holes, roads, foundations, farms or civic buffers; resources retain identity")
	check(anchored,"all detail roots use the actual triangulated visual surface")
	check(bounded,"complete geometry stays in its native cell with a margin for subtle wind")
	var budgets := true
	var batches := true
	for section in detail.sections:
		var counts := {"grass":0,"shrub":0}
		for item in detail.records[section]:
			if item.kind in counts:
				counts[item.kind] += 1
		budgets = budgets and counts.grass <= 96 and counts.shrub <= 48
		for node in detail.sections[section].get_children():
			batches = batches and node is MultiMeshInstance3D and node.get_child_count() == 0
			if node.get_meta("kind") in ["grass","shrub"]:
				batches = batches and node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and node.visibility_range_end > 62
	check(budgets,"each 24-tile section obeys explicit grass/shrub instance budgets")
	check(batches and stats.batches < 350,"bounded spatial MultiMeshes have no per-prop nodes/collision and foliage uses distance culling")
	var finite_meshes := true
	var quarry_centers := true
	var palettes := {}
	for kind in ["stone","copper","silver","tall_stone","marble","orichalcum","black_marble","grass","shrub"]:
		for variant in range(2):
			var mesh: ArrayMesh = detail.mesh_for(kind,variant)
			var arrays := mesh.surface_get_arrays(0)
			finite_meshes = finite_meshes and arrays[Mesh.ARRAY_VERTEX].size() <= 400
			palettes[kind] = Array(arrays[Mesh.ARRAY_COLOR]).hash()
			for normal in arrays[Mesh.ARRAY_NORMAL]:
				finite_meshes = finite_meshes and is_finite(normal.x) and absf(normal.length()-1) < .001
			if kind in ["marble","black_marble"]:
				for vertex in arrays[Mesh.ARRAY_VERTEX]:
					quarry_centers = quarry_centers and absf(vertex.z) > .2
	check(finite_meshes,"all seven resource kinds and two foliage kinds have finite bounded geometry")
	check(quarry_centers,"low native walkable quarry ledges leave cell centers open")
	check(palettes.copper != palettes.orichalcum and palettes.marble != palettes.black_marble and palettes.silver != palettes.stone,"resource palettes and ore veins distinguish native kinds; absent kinds are mesh checks only")
	var second := Details.new()
	get_root().add_child(second)
	second.update(tiles,origin,extent,geometry,changed)
	check(entries(second) == original,"identical native observations reproduce detail without native RNG or iteration drift")
	second.free()
	check(tiles.has(grass) and tiles.has(deposit) and tiles.has(boundary),"actual dry forest edge, deposit and section boundary fixtures exist")
	if tiles.has(grass):
		var saved: Array = tiles[grass].duplicate()
		var rebuilds: int = detail.rebuilds
		tiles[grass][5] = 1-int(tiles[grass][5])
		detail.update(tiles,origin,extent,geometry,[grass])
		check(detail.rebuilds == rebuilds,"placement eligibility alone does not rebuild decorative geometry")
		tiles[grass][4] = 1
		detail.update(tiles,origin,extent,geometry,[grass])
		check(at_cell(detail,grass).is_empty(),"road edits clear the decorated cell and refresh neighbor buffers")
		tiles[grass] = saved.duplicate()
		detail.update(tiles,origin,extent,geometry,[grass])
		check(entries(detail) == original,"reversing a road edit restores the exact deterministic layout")
		tiles[grass][6] = int(saved[6]) | 8
		detail.update(tiles,origin,extent,geometry,[grass])
		check(at_cell(detail,grass).is_empty(),"foundation edits remove understory rather than overlay buildings")
		tiles[grass] = saved.duplicate()
		detail.update(tiles,origin,extent,geometry,[grass])
		tiles[grass][3] = 4
		detail.update(tiles,origin,extent,geometry,[grass])
		check(at_cell(detail,grass).is_empty(),"water edits suppress detail instead of adding shoreline rocks")
		tiles[grass] = saved
		detail.update(tiles,origin,extent,geometry,[grass])
	if tiles.has(boundary):
		var ids := {}
		for section in detail.sections:
			ids[section] = detail.sections[section].get_instance_id()
		var saved: Array = tiles[boundary].duplicate()
		tiles[boundary][4] = 1
		detail.update(tiles,origin,extent,geometry,[boundary])
		var adjacent := {}
		for delta in cardinal_offsets():
			if tiles.has(boundary+delta):
				adjacent[detail.section_key(boundary+delta)] = true
		var correct := adjacent.size() >= 2
		for section in ids:
			if section in adjacent:
				correct = correct and ids[section] != detail.sections[section].get_instance_id()
			elif Vector2(section).distance_to(Vector2(detail.section_key(boundary))) > 2:
				correct = correct and ids[section] == detail.sections[section].get_instance_id()
		check(correct,"edge edits refresh both neighboring detail sections while distant batches are reused")
		tiles[boundary] = saved
		detail.update(tiles,origin,extent,geometry,[boundary])
	if tiles.has(deposit):
		var saved: Array = tiles[deposit].duplicate()
		var height: float = at_cell(detail,deposit)[0].transform.origin.y
		tiles[deposit][2] = float(saved[2])+1.0
		geometry.update(tiles,origin,extent,[deposit])
		detail.update(tiles,origin,extent,geometry,[deposit])
		check(absf(at_cell(detail,deposit)[0].transform.origin.y-height-.22) < .00001,"height edits re-anchor resource detail to the visual surface")
		tiles[deposit] = saved
		geometry.update(tiles,origin,extent,[deposit])
		detail.update(tiles,origin,extent,geometry,[deposit])
		var quarry := Vector2i(99999,99999)
		for cell in tiles:
			if int(tiles[cell][3]) & 1024:
				quarry = cell
				break
		var floor_saved: Array = tiles[quarry].duplicate()
		var color: Color = style.mineral_image.get_pixelv(quarry-origin)
		tiles[quarry] = floor_saved.duplicate()
		tiles[quarry][3] = 1
		style.update(tiles,origin,extent,[quarry])
		check(color.a == 1 and style.mineral_image.get_pixelv(quarry-origin).a == 0 and style.mineral_texture == mineral_texture and style.coastline_rebuilds == coast_rebuilds,"native resource-flag edits refresh the quarry floor without replacing its texture or rebuilding coast")
		tiles[quarry] = floor_saved
		style.update(tiles,origin,extent,[quarry])
		check(style.mineral_image.get_pixelv(quarry-origin) == color,"reversing a resource edit restores the quarry floor")
	check(entries(detail) == original,"all presentation-copy edits restore the full original layout")
	var conservative := true
	for tile in initial.tiles:
		conservative = conservative and not detail.free_ground(tile.slice(0,6))
	check(conservative,"legacy observations without foundation metadata conservatively disable new props")
	var copies_restored := true
	for tile in initial.tiles:
		copies_restored = copies_restored and tiles[Vector2i(int(tile[0]),int(tile[1]))] == tile
	check(copies_restored,"every edited observation copy restores its original native columns")
	var final: Dictionary = core.snapshot(true)
	check(final.tiles == initial.tiles and final.buildings == initial.buildings and final.walkers == initial.walkers and final.money == initial.money and final.time == initial.time,"detail generation and copy tests preserve the full paused native city")
	var report := {"pass":okay,"checks":checks,"statistics":stats,"absent_native_kinds":["silver","tall_stone","black_marble"],"copy_scope":"road/foundation/water/height/cache edits use disposable presentation observations only"}
	FileAccess.open("res://captures/detail-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DETAIL_VALIDATION ","PASS " if okay else "FAIL ","checks=",checks," stats=",JSON.stringify(stats))
	detail.free()
	core.close_city()
	quit(0 if okay else 1)

func cardinal_offsets() -> Array[Vector2i]:
	return [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
