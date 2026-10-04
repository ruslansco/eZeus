extends SceneTree

const Geometry = preload("res://scripts/terrain_geometry.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("ELEVATION_CHECK ","PASS " if value else "FAIL ",message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),"en")
	check(initial.has("tiles") and initial.paused,"designated city loads paused")
	if not okay:
		quit(1)
		return
	var tiles := {}
	var cells: Array[Vector2i] = []
	var schema := true
	var cliffs := 0
	var ramps := 0
	var protected_slopes := 0
	for tile in initial.tiles:
		var cell := Vector2i(int(tile[0]),int(tile[1]))
		tiles[cell] = tile.duplicate()
		cells.append(cell)
		# Column 8 (appended): road kind 0 none, 1 road, 2 avenue, 3 boulevard; it agrees with column 4.
		schema = schema and tile.size() == 9 and int(tile[6]) >= 0 and int(tile[6]) <= 15 and int(tile[8]) in [0,1,2,3] and (int(tile[8]) > 0) == bool(int(tile[4]))
		if int(tile[6]) & 1:
			if int(tile[6]) & 8:
				protected_slopes += 1
			elif int(tile[6]) & 2:
				ramps += 1
			else:
				cliffs += 1
	check(schema,"native snapshot appends valid elevation/walkability/half/foundation flags and character altitude")
	check(cliffs == 203 and ramps == 8 and protected_slopes == 112,"actual city separates blocked cliffs, road ramps and protected building terrain")
	var origin := Vector2i(int(initial.origin[0]),int(initial.origin[1]))
	var extent := Vector2i(int(initial.extent[0]),int(initial.extent[1]))
	var shape := Geometry.new()
	shape.update(tiles,origin,extent,cells)
	var anchors := true
	var finite := true
	var flat_cells := 0
	var continuous := true
	var joined := true
	var sampled := true
	var vertices := 0
	var side_faces := 0
	for cell in cells:
		var p := shape.profile(cell)
		for height in p:
			finite = finite and is_finite(height)
		if not shape.sloped(cell):
			flat_cells += 1
			for height in p:
				anchors = anchors and absf(height-float(tiles[cell][2])*.22) < .00001
		for spec in [[Vector2i.RIGHT,1,2,0,3],[Vector2i.UP,0,1,3,2]]:
			var neighbor: Vector2i = cell+spec[0]
			if tiles.has(neighbor) and shape.sloped(cell) and shape.sloped(neighbor):
				var other := shape.profile(neighbor)
				continuous = continuous and absf(p[spec[1]]-other[spec[3]]) < .00001 and absf(p[spec[2]]-other[spec[4]]) < .00001
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top_count := shape.add_top(surface,cell)
		var faces := shape.add_sides(surface,cell)
		var mesh := surface.commit()
		vertices += mesh.surface_get_array_len(0)
		side_faces += faces
		if shape.sloped(cell):
			var points: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			# Independent triangle centroids must agree with the display-height
			# query used for feet/ghosts, even on saddle/corner ramp geometry.
			for index in range(0,top_count,3):
				var center := (points[index]+points[index+1]+points[index+2])/3.0
				var x := center.x+origin.x+(extent.x-1)*.5
				var y := -center.z+origin.y+(extent.y-1)*.5
				sampled = sampled and absf(center.y-shape.height_at(x,y)) < .00005
		# At least one exterior side must close every exposed map boundary cell.
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if not tiles.has(cell+delta):
				joined = joined and faces > 0
	check(finite,"all height profiles are finite")
	check(anchors and flat_cells > 25000,"flat land, water and every building foundation retain exact native height")
	check(continuous,"neighboring slopes share identical corner heights across section boundaries")
	check(joined and side_faces > 0,"exposed native map edges have closing rock sides")
	check(sampled,"walker/ghost height queries match actual slope triangle centroids")
	check(vertices < 250000,"complete terrain with subdivisions/sides stays within a bounded vertex budget")
	var final: Dictionary = core.snapshot(true)
	check(final.tiles == initial.tiles and final.walkers == initial.walkers and final.buildings == initial.buildings and final.money == initial.money and final.time == initial.time,"full geometry generation leaves the native simulation unchanged")
	check(core.snapshot(false).tile_changes.is_empty(),"read-only geometry observations do not cause repeated terrain updates")
	# The designated city contains no half-height slopes. Exercise their mesh
	# math on a disposable copy of its native tile records, never another save.
	for turn in range(4):
		var fixture := {}
		var center := Vector2i(117,-3)
		var changed: Array[Vector2i] = []
		for y in range(-1,2):
			for x in range(-1,2):
				var delta := Vector2i(x,y)
				for rotation in range(turn):
					delta = Vector2i(-delta.y,delta.x)
				var cell := center+delta
				var tile: Array = tiles[cell].duplicate()
				tile[2] = 1 if x == 1 else 0
				tile[3] = 1
				tile[4] = 1 if x == 0 else 0
				tile[6] = 7 if x == 0 else (5 if x == -1 else 0)
				fixture[cell] = tile
				changed.append(cell)
		var half := Geometry.new()
		half.update(fixture,origin,extent,changed)
		var p := half.profile(center)
		check(absf(half.height_at(center.x,center.y)-.11) < .00001 and absf(float(Array(p).max())-.22) < .00001,"half-height road-ramp mesh retains 0.22 rise at orientation %d" % turn)
		var foundation: Array = fixture[center]
		foundation[6] = 15
		half.update(fixture,origin,extent,[center])
		check(Array(half.profile(center)).max() == 0,"protected half-height foundation remains level at orientation %d" % turn)
	var changed_cell := Vector2i(96,0)
	# Select a real height edge on a section boundary for cache refresh coverage.
	for cell in cells:
		if posmod(cell.x-origin.x,32) != 0 or not shape.sloped(cell):
			continue
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor: Vector2i = cell+delta
			if tiles.has(neighbor) and float(tiles[neighbor][2]) > float(tiles[cell][2]):
				changed_cell = neighbor
				break
		if tiles.has(changed_cell) and float(tiles[changed_cell][2]) > 0:
			break
	var before := shape.profile(changed_cell).duplicate()
	var original: Array = tiles[changed_cell].duplicate()
	tiles[changed_cell][2] = float(original[2])+1
	shape.update(tiles,origin,extent,[changed_cell])
	check(shape.profile(changed_cell) != before,"native height edits invalidate cached profiles at section edges")
	tiles[changed_cell] = original
	shape.update(tiles,origin,extent,[changed_cell])
	check(shape.profile(changed_cell) == before,"reversing a height edit restores the exact surface")
	final = core.snapshot(true)
	check(final.tiles == initial.tiles and final.time == initial.time,"disposable half-slope/cache fixtures do not modify native terrain or clock")
	var report := {"pass":okay,"checks":checks,"cliff_cells":cliffs,"road_ramps":ramps,"protected_slopes":protected_slopes,"terrain_vertices":vertices,"side_faces":side_faces,"half_slope_scope":"presentation-copy math; absent in designated native city"}
	var file := FileAccess.open("res://captures/elevation-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	core.close_city()
	print("ELEVATION_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
