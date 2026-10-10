extends SceneTree
# Finds surfaces whose imported mesh LODs lose the shape they stand for: every surface is rasterised (occupancy only) along the
# three axes at full detail and at each LOD level; a LOD that keeps under KEEP of any view's occupancy is "lossy".
# Usage: -- <asset>... (default: every non-character GLB in data/geometry_baseline.json). Prints LODAUDIT lines and a summary and
# exits non-zero while any surface is lossy, so it is also the gate for lod_guard.gd (about ten minutes for the whole set).
# A LOD that keeps under KEEP of a view's occupancy at a switching error of at most NEAR_EDGE (model units; a tile is 1) shows
# as a missing roof or wall at ordinary zoom: those surfaces are what the LOD guard (lod_guard.gd) repairs.
const KEEP := 0.6
const MIN_SURFACE_TRIANGLES := 300
const NEAR_EDGE := 0.6
const SKIP_PREFIXES := ["walker_", "animal_", "hero_", "monster_", "god_", "good_"]
const Coverage = preload("res://scripts/lod_coverage.gd")

func _initialize() -> void:
	call_deferred("run")

func walk(node: Node, out: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		out.append(node)
	for child in node.get_children():
		walk(child, out)

func run() -> void:
	var names: PackedStringArray = OS.get_cmdline_user_args()
	if names.is_empty():
		var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/geometry_baseline.json"))
		for key in baseline.assets:
			var skip := false
			for prefix in SKIP_PREFIXES:
				skip = skip or key.begins_with(prefix)
			if not skip:
				names.append(key)
		names.sort()
	var coverage = Coverage.new()
	var lossy_surfaces := 0
	var lossy_assets := 0
	for asset in names:
		var path := "res://assets/models/%s.glb" % asset
		if not ResourceLoader.exists(path):
			continue
		var scene: Node = load(path).instantiate()
		var meshes: Array = []
		walk(scene, meshes)
		var flagged := false
		for node in meshes:
			var mesh: ArrayMesh = node.mesh
			for s in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(s)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var info := RenderingServer.mesh_get_surface(mesh.get_rid(), s)
				var lods: Array = info.get("lods", [])
				if lods.is_empty() or arrays[Mesh.ARRAY_INDEX].size() / 3 < MIN_SURFACE_TRIANGLES:
					continue
				var low := Vector3(1e9, 1e9, 1e9)
				var high := Vector3(-1e9, -1e9, -1e9)
				for v in vertices:
					low = low.min(v)
					high = high.max(v)
				var full_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var line := ""
				var level := 0
				var bad := false
				for lod in lods:
					level += 1
					var data: PackedByteArray = lod.index_data
					var wide := vertices.size() >= 65536
					var count := data.size() / (4 if wide else 2)
					var idx := PackedInt32Array()
					idx.resize(count)
					for i in count:
						idx[i] = data.decode_u32(i * 4) if wide else data.decode_u16(i * 2)
					var edge: float = lod.get("edge_length", 0.0)
					var worst: float = coverage.kept(vertices, full_indices, idx, low, high - low, edge)
					line += " L%d:%dt/e%.2f/k%.2f" % [level, count / 3, edge, worst]
					if worst < KEEP and edge <= NEAR_EDGE:
						bad = true
				if bad:
					lossy_surfaces += 1
					flagged = true
					print("LODAUDIT ", asset, " ", node.name, " full=", full_indices.size() / 3, "t", line)
		lossy_assets += 1 if flagged else 0
		scene.free()
	print("LODAUDIT_SUMMARY assets=", names.size(), " lossy_assets=", lossy_assets, " lossy_surfaces=", lossy_surfaces)
	print("LOD_ROOF_VALIDATION ", "PASS" if lossy_surfaces == 0 else "FAIL")
	quit(0 if lossy_surfaces == 0 else 1)
