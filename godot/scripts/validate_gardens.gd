extends SceneTree
const Batches = preload("res://scripts/building_batches.gd")
const COUNTS := {"deco_fish_pond":6,"deco_topiary":3,"deco_hedge_maze":1,"park":164,"deco_shell_garden":1,"deco_sundial":1,"deco_dolphin":1,"deco_orrery":1}
var checks := 0
var okay := true

func check(value: bool, label: String) -> void:
	checks += 1
	okay = okay and value
	print("GARDEN_CHECK ","PASS " if value else "FAIL ",label)

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
	core.command("pause 1")
	initial = core.snapshot(true)
	var batches := Batches.new()
	root.add_child(batches)
	var placements := 0
	for asset in COUNTS:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % asset))
		var width := int(manifest.foliage.native_footprint)
		var count := 0
		var footprint := true
		var inspections := true
		for building in initial.buildings:
			if building.asset != asset:
				continue
			count += 1
			footprint = footprint and int(building.w) == width and int(building.h) == width
			var inspected: Dictionary = core.command("inspect %d %d" % [building.x,building.y])
			inspections = inspections and not inspected.has("error")
		placements += count
		check(count == COUNTS[asset] and footprint and inspections,"%s: every native placement retains its footprint and inspector" % asset)
		var pieces: Array = batches.template(asset)
		var finite := not pieces.is_empty()
		var bounded := true
		var anchored := false
		var height := 0.0
		var materials := true
		for piece in pieces:
			for surface in range(piece.mesh.get_surface_count()):
				var arrays: Array = piece.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				finite = finite and vertices.size() > 0 and normals.size() == vertices.size()
				for index in range(vertices.size()):
					var vertex: Vector3 = piece.transform * vertices[index]
					var normal: Vector3 = normals[index]
					finite = finite and vertex.is_finite() and normal.is_finite() and absf(normal.length()-1) < .01
					bounded = bounded and absf(vertex.x) <= width*.5+.001 and absf(vertex.z) <= width*.5+.001 and vertex.y >= -.01
					anchored = anchored or absf(vertex.y) < .005
					height = maxf(height,vertex.y)
				var material: StandardMaterial3D = piece.mesh.surface_get_material(surface)
				materials = materials and material != null and material.vertex_color_use_as_albedo and material.cull_mode == BaseMaterial3D.CULL_DISABLED
		check(finite and bounded and anchored and (asset != "park" or height > 1.0),"%s: complete finite geometry is anchored inside the native footprint at full height" % asset)
		check(materials and pieces.size() <= 3 and int(manifest.vertices) <= int(manifest.foliage.vertex_budget),"%s: double-sided foliage keeps palette batching and its geometry budget" % asset)
	check(placements == 178,"all 178 native garden objects use updated shared models")
	var final: Dictionary = core.snapshot(true)
	check(final.tiles == initial.tiles and final.buildings == initial.buildings and final.walkers == initial.walkers and final.time == initial.time and final.money == initial.money,"garden import and inspection leave the entire paused native city unchanged")
	var file := FileAccess.open("res://captures/garden-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":okay,"checks":checks,"native_placements":placements,"assets":COUNTS.keys()},"\t"))
	core.close_city()
	batches.free()
	print("GARDEN_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
