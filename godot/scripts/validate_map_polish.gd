extends SceneTree
const Geometry = preload("res://scripts/terrain_geometry.gd")
const Forest = preload("res://scripts/terrain_forest.gd")
const Bridges = preload("res://scripts/terrain_bridges.gd")
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("POLISH_CHECK ","PASS " if value else "FAIL ",label)

func entries(props: Node3D) -> Array:
	var result := []
	for section in props.records.values():
		result.append_array(section)
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),"en")
	if not initial.has("tiles"):
		check(false,"designated city loads")
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
	var forest := Forest.new()
	var bridges := Bridges.new()
	get_root().add_child(forest)
	get_root().add_child(bridges)
	forest.update(tiles,origin,extent,geometry,changed)
	bridges.update(tiles,origin,extent,geometry,changed)
	var trees := entries(forest)
	var crossings := entries(bridges)
	var native_trees := 0
	var native_bridges := 0
	for tile in tiles.values():
		if int(tile[3]) & 16 and not int(tile[4]) and not (int(tile[6]) & 8):
			native_trees += 1
		if int(tile[3]) & 4 and int(tile[4]):
			native_bridges += 1
	check(trees.size() == native_trees and native_trees > 3000,"one independently anchored tree per unoccupied native forest cell")
	check(bridges.summary().counts.get("bridge",0) == native_bridges and native_bridges == 57,"all 57 native water-road cells receive real bridge decks")
	check(bridges.summary().counts.get("approach",0) > 0,"native shore roads have continuous bridge approaches")
	var anchor := true
	var bounded := true
	for item in trees:
		var position: Vector3 = item.transform.origin
		var x := position.x+origin.x+(extent.x-1)*.5
		var y := -position.z+origin.y+(extent.y-1)*.5
		anchor = anchor and absf(position.y-geometry.height_at(x,y)) < .00001
		var mesh: ArrayMesh = forest.mesh_for(item.kind,item.variant)
		for point in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var world: Vector3 = item.transform*point
			bounded = bounded and absf(world.x+origin.x+(extent.x-1)*.5-item.cell.x)<.475 and absf(-world.z+origin.y+(extent.y-1)*.5-item.cell.y)<.475
	check(anchor,"all tree roots follow the triangulated native presentation surface")
	check(bounded,"tree geometry stays inside its native cell, including a wind margin")
	var valid_lods := true
	var finite := true
	for mesh in forest.meshes.values():
		var arrays: Array = mesh.surface_get_arrays(0)
		var stored: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(),0)
		var lods: Array = stored.get("lods",[])
		valid_lods = valid_lods and lods.size() == 1 and arrays[Mesh.ARRAY_VERTEX].size() < 6000
		var stride: int = RenderingServer.mesh_surface_get_format_index_stride(stored.format,arrays[Mesh.ARRAY_VERTEX].size())
		for lod in lods:
			var data: PackedByteArray = lod.index_data
			valid_lods = valid_lods and data.size()/stride < arrays[Mesh.ARRAY_INDEX].size()*.4
			for offset in range(0,data.size(),stride):
				var index := data.decode_u16(offset) if stride == 2 else data.decode_u32(offset)
				valid_lods = valid_lods and index < arrays[Mesh.ARRAY_VERTEX].size()
		for normal in arrays[Mesh.ARRAY_NORMAL]:
			finite = finite and is_finite(normal.x) and absf(normal.length()-1)<.001
	check(valid_lods,"both tree species/variants have valid reduced LODs and explicit geometry budgets")
	check(finite,"leaf/crown/branch normals remain finite and normalized")
	check(forest.summary().batches < 260 and bridges.summary().batches < 30,"trees and crossings use bounded spatial MultiMeshes, not individual entity nodes")
	var deck_correct := true
	var bridge_site := Vector2i(99999,99999)
	for item in crossings:
		var cell: Vector2i = item.cell
		var tile: Array = tiles[cell]
		if item.kind == "bridge":
			bridge_site = cell
			deck_correct = deck_correct and int(tile[3]) & 4 and int(tile[4]) and absf(bridges.height_at(cell.x,cell.y)-float(tile[2])*.22-.14)<.00001
		else:
			deck_correct = deck_correct and not (int(tile[3]) & 4) and int(tile[4])
	check(deck_correct,"bridge/approach surfaces match native road identity and visual deck heights")
	var joins := true
	for item in crossings:
		var cell: Vector2i = item.cell
		if item.kind == "approach":
			var delta: Vector2i = bridges.approach(cell)
			joins = joins and absf(bridges.height_at(cell.x+delta.x*.499,cell.y+delta.y*.499)-bridges.height_at(cell.x+delta.x*.501,cell.y+delta.y*.501))<.001
	check(joins,"land approaches and water decks join without a visible vertical step")
	var tree_site: Vector2i = trees[0].cell
	var saved_tree: Array = tiles[tree_site].duplicate()
	var before_rebuilds: int = forest.rebuilds
	tiles[tree_site][5] = 1-int(tiles[tree_site][5])
	forest.update(tiles,origin,extent,geometry,[tree_site])
	check(forest.rebuilds == before_rebuilds,"eligibility-only metadata does not rebuild trees")
	tiles[tree_site] = saved_tree.duplicate()
	tiles[tree_site][3] = 1
	forest.update(tiles,origin,extent,geometry,[tree_site])
	check(entries(forest).size() == trees.size()-1,"native forest-flag clearing removes only the corresponding tree")
	tiles[tree_site] = saved_tree
	forest.update(tiles,origin,extent,geometry,[tree_site])
	check(entries(forest) == trees,"restoring forest observations reproduces the same complete tree layout")
	var saved_bridge: Array = tiles[bridge_site].duplicate()
	tiles[bridge_site][4] = 0
	bridges.update(tiles,origin,extent,geometry,[bridge_site])
	check(bridges.summary().counts.bridge == native_bridges-1 and not bridges.is_bridge(bridge_site),"water-road removal removes the actual bridge and refreshes neighbors")
	tiles[bridge_site] = saved_bridge
	bridges.update(tiles,origin,extent,geometry,[bridge_site])
	check(entries(bridges) == crossings,"restoring roads recreates identical bridge and approach geometry")
	var final: Dictionary = core.snapshot(true)
	check(final.tiles == initial.tiles and final.walkers == initial.walkers and final.buildings == initial.buildings and final.time == initial.time and final.money == initial.money,"map refinements preserve the complete paused C++ simulation")
	var report := {"pass":okay,"checks":checks,"forest":forest.summary(),"bridges":bridges.summary(),"native_state_unchanged":final.tiles == initial.tiles and final.walkers == initial.walkers and final.buildings == initial.buildings and final.time == initial.time and final.money == initial.money}
	FileAccess.open("res://captures/map-polish-validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("POLISH_VALIDATION ","PASS " if okay else "FAIL ","checks=",checks," ",JSON.stringify(report))
	forest.free()
	bridges.free()
	core.close_city()
	quit(0 if okay else 1)
