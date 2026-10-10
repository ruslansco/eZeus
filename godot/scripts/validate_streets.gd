extends SceneTree
const Layout = preload("res://scripts/street_layout.gd")
const Avenues = preload("res://scripts/terrain_avenues.gd")
const Furniture = preload("res://scripts/street_furniture.gd")
const Walkers = preload("res://scripts/walker_streets.gd")
const Geometry = preload("res://scripts/terrain_geometry.gd")
const Presentation = preload("res://scripts/terrain_presentation.gd")
const Preview = preload("res://scripts/building_preview.gd")
var checks := 0
var okay := true

class City extends Node:
	var tiles: Dictionary = {}
	var origin := Vector2i(-12,-12)
	var extent := Vector2i(25,25)

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("STREET_CHECK ","PASS " if value else "FAIL ",label)

func _initialize() -> void: call_deferred("run")

func fixture(kind: int, rotated: bool) -> Dictionary:
	var tiles := {}
	for x in range(-12,13):
		for y in range(-12,13):
			var along: int = y if rotated else x
			var across: int = x if rotated else y
			var k := kind if across == 0 else (1 if across == 1 or (kind == 3 and across == -1) else 0)
			if abs(along) > 9: k = 0
			tiles[Vector2i(x,y)] = [x,y,0,1,1 if k else 0,1,0,0,k]
	return tiles

func run() -> void:
	var walkers := Walkers.new()
	for kind in [2,3]:
		for rotated in [false,true]:
			var label := "%s %s"%["avenue" if kind == 2 else "boulevard","north/south" if rotated else "east/west"]
			var city := City.new(); root.add_child(city); city.tiles = fixture(kind,rotated)
			var before: Dictionary = city.tiles.duplicate(true)
			var along := Vector2i.DOWN if rotated else Vector2i.RIGHT
			var geo := Geometry.new(); var changed: Array[Vector2i] = []
			changed.assign(city.tiles.keys()); geo.update(city.tiles,city.origin,city.extent,changed)
			var avenues := Avenues.new(); root.add_child(avenues)
			avenues.update(city.tiles,city.origin,city.extent,geo,changed)
			var records: Array = []
			for entries in avenues.records.values(): records.append_array(entries)
			check(records.any(func(p): return p.kind == "street_statue") and records.any(func(p): return p.kind == "street_bench") and records.any(func(p): return p.kind == "street_planter"),label+": statues, benches and planted pockets are batched")
			var edges_clear := true
			for p in records:
				var point: Vector3 = p.transform.origin
				var across: float = point.x if rotated else -point.z
				edges_clear = edges_clear and (absf(across - 1.4) < .001 or absf(across - (-1.4 if kind == 3 else -.4)) < .001)
			check(edges_clear,label+": every decoration sits on an outside edge, away from native tracks")
			check(avenues.layout(along*9).is_empty(),label+": end tiles stay clear")
			var travel_clear := true; var bounded := true; var track_kept := true
			# Straight lanes, transverse crossings and diagonal corner crossings use
			# the same native points while rendering within the paved road footprint.
			for path in [[Vector2(-7,0),Vector2(7,0)],[Vector2(0,0),Vector2(0,1)],[Vector2(-2,0),Vector2(-1,1)],[Vector2(-7,1),Vector2(7,1)]]:
				var entry := {"waterborne":false,"native_position":Vector3.ZERO,"lane":Vector3.ZERO,"action":1,"clips":{}}
				var previous := Vector3.ZERO
				for i in 301:
					var native: Vector2 = path[0].lerp(path[1],float(i)/300.0)
					if rotated: native = Vector2(native.y,native.x)
					var position := Vector3(native.x,0,-native.y)
					entry.native_position = position
					var lane: Vector3 = walkers.lane(entry,position-previous,1.0/60.0,city)
					var shown := position+lane
					track_kept = track_kept and entry.native_position == position
					bounded = bounded and Layout.kind(city.tiles,Walkers.cell_at(city,shown)) > 0
					for p in records:
						var d: Vector3 = shown-p.transform.origin
						var across: float = d.x if rotated else d.z
						var length: float = d.z if rotated else d.x
						if absf(length) < .42: travel_clear = travel_clear and absf(across) > .19
					previous = position
				var held: Vector3 = entry.lane
				for i in 60: walkers.lane(entry,Vector3.ZERO,1.0/60.0,city)
				check(entry.lane.is_equal_approx(held),label+": a stopped native track does not drift")
			check(bounded and travel_clear and track_kept,label+": straight, transverse and diagonal walker samples keep native tracks, paving and decoration clearance")
			var regular := {"waterborne":false,"native_position":Vector3(-5,0,-1) if not rotated else Vector3(1,0,5),"action":1,"clips":{}}
			for i in 120: walkers.lane(regular,Vector3.FORWARD if rotated else Vector3.RIGHT,1.0/60.0,city)
			check(absf(regular.lane.length()-Walkers.LANE)<.0001,label+": ordinary right-hand lane width is retained")
			var style := Presentation.new()
			check(style.road_pattern(city.tiles,Vector2i.ZERO).r == 1 and style.road_pattern(city.tiles,Vector2i.ZERO).g == 1,label+": every native median remains a dressed road")
			style = null
			var bend := city.tiles.duplicate(true)
			bend[along] = [along.x,along.y,0,1,0,1,0,0,0]
			check(Layout.axis(bend,Vector2i.ZERO)==Vector2i.ZERO,label+": a bend has no guessed decorative axis")
			var cross := Vector2i.RIGHT if rotated else Vector2i.DOWN
			var intersection: Dictionary = city.tiles.duplicate(true)
			for sign in [-1,1]:
				var point: Vector2i = cross*sign
				intersection[point]=[point.x,point.y,0,1,1,1,0,0,kind]
			check(Layout.edges(intersection,Vector2i.ZERO).is_empty(),label+": intersections stay open")
			check(city.tiles == before,label+": rendering, decoration and lane calculations do not alter tile observations")
			avenues.free(); city.free()
	for kind in ["street_statue","street_planter","street_bench"]:
		var mesh: ArrayMesh = Furniture.mesh(kind)
		var aabb := mesh.get_aabb()
		check(aabb.size.x <= .1801 and mesh.surface_get_array_len(0) < 10000,kind+": narrow ornament geometry and bounded mesh size")
		var arrays: Array = mesh.surface_get_arrays(0)
		check(Array(arrays[Mesh.ARRAY_VERTEX]).all(func(v):return v.is_finite()) and Array(arrays[Mesh.ARRAY_NORMAL]).all(func(v):return v.is_finite()),kind+": finite vertices and normals")
		check(not RenderingServer.mesh_get_surface(mesh.get_rid(),0).get("lods",[]).is_empty(),kind+": reduced index LOD is present")
	check(not Layout.wide(fixture(2,false),Vector2i(0,-1)),"adjacent grass never receives road lane clamping")
	var plain:=City.new(); root.add_child(plain)
	plain.tiles=fixture(2,false); plain.tiles[Vector2i(8,8)]=[8,8,0,1,1,1,0,0,1]
	check(not Walkers.wide_road(plain,Vector3(8,0,-8)),"a standalone single-tile road retains its original movement path")
	plain.free()
	var bend_city:=City.new(); root.add_child(bend_city); bend_city.tiles=fixture(2,false)
	for cell in bend_city.tiles: bend_city.tiles[cell][4]=0; bend_city.tiles[cell][8]=0
	for x in range(-5,1):
		for y in [0,1]: bend_city.tiles[Vector2i(x,y)][4]=1; bend_city.tiles[Vector2i(x,y)][8]=2 if y==0 else 1
	for y in range(0,6):
		for x in [0,1]: bend_city.tiles[Vector2i(x,y)][4]=1; bend_city.tiles[Vector2i(x,y)][8]=2 if x==0 else 1
	for reverse in [false,true]:
		var entry: Dictionary={"waterborne":false,"native_position":Vector3.ZERO,"action":1,"clips":{}}
		var previous:=Vector3.ZERO; var prior_shown:=Vector3.ZERO; var continuous:=true
		for i in 301:
			var t:=float(i)/300.0
			if reverse: t=1.0-t
			var p:=Vector3(-1+t,0,-1-t); entry.native_position=p
			var shown: Vector3=p+walkers.lane(entry,p-previous,1.0/60.0,bend_city)
			if i: continuous=continuous and shown.distance_to(prior_shown)<.04
			previous=p; prior_shown=shown
		check(continuous,"diagonal bend crossing is continuous in both directions, without tile-box snapping")
		var held: Vector3=walkers.lane(entry,Vector3.ZERO,1.0/60.0,bend_city)
		var settled := Vector3.ZERO
		for i in 60: settled=walkers.lane(entry,Vector3.ZERO,1.0/60.0,bend_city)
		check(held.is_equal_approx(settled),"stopped bend retains a fixed visual offset")
	bend_city.free()
	# A change TWO cells beyond a median must invalidate its decorations across
	# a 24-cell batch boundary (median 23, flank 24, outside 25).
	var tiles := {}; var cells: Array[Vector2i] = []
	for x in 25:
		for y in 49:
			var k:=2 if y==23 else (1 if y==24 else 0)
			var cell:=Vector2i(x,y); cells.append(cell)
			tiles[cell]=[x,y,0,1,1 if k else 0,1,0,0,k]
	var geo:=Geometry.new(); geo.update(tiles,Vector2i.ZERO,Vector2i(25,49),cells)
	var avenues:=Avenues.new(); root.add_child(avenues)
	avenues.update(tiles,Vector2i.ZERO,Vector2i(25,49),geo,cells)
	var old: Array=avenues.records[Vector2i(0,0)].filter(func(p):return p.cell==Vector2i(4,23))
	tiles[Vector2i(4,25)][6]=8
	var edit: Array[Vector2i]=[Vector2i(4,25)]
	avenues.update(tiles,Vector2i.ZERO,Vector2i(25,49),geo,edit)
	var fresh: Array=avenues.records[Vector2i(0,0)].filter(func(p):return p.cell==Vector2i(4,23))
	check(old.size()==2 and fresh.size()==1,"nearby construction clears an entrance pocket across the batch boundary")
	avenues.free()
	for width in [false,true]:
		var miniature: Node3D=Preview.street(width)
		check(miniature.get_child_count()>1 and miniature.get_children().all(func(n):return not n is Viewport and not n is CollisionObject3D),"street catalog miniature has static paving/decoration and no live viewport or physics")
		miniature.free()
	walkers.ring.free()
	print("STREET_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
