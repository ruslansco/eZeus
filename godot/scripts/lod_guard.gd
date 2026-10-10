@tool
extends EditorScenePostImport
# Import script for building models whose automatic mesh LODs lose their roofs.
#
# Godot builds each surface's LOD ladder with a quadric simplifier that removes whatever is cheapest, and fine, dense detail
# such as a shingled roof is cheap: the first LOD (a switching error of only about a quarter of a tile, reached at ordinary
# zoom-out) can have no roof left at all (maintenance office, hospital). This script measures each surface's LODs
# (`lod_coverage.gd`, the silhouette they keep along the three axes) and, for a surface whose near LODs lose the shape, replaces
# its whole ladder with vertex-clustering LODs: vertices falling in the same grid cell (and facing the same way) are merged into
# the one nearest the cell's centre. Clustering reuses existing vertices, so colours, UVs and morph targets stay valid, and it
# cannot delete a region, only coarsen it. Surfaces whose Godot ladder is sound are left exactly as imported.
#
# By the time an import script runs, Godot has already turned the meshes into ArrayMeshes holding their LODs, so a guarded
# mesh is rebuilt as a whole (ArrayMesh cannot change one surface's LODs). `tools/apply_lod_guard.py` lists the models to guard
# and sets `import_script/path` in their .import files; `tools/reimport_models.sh` re-imports them; audit with
# `scripts/audit_lod_coverage.gd` (it is also the pass/fail gate for the result).

const Coverage = preload("res://scripts/lod_coverage.gd")
# A LOD that keeps less than KEEP of the cells the full mesh touches (on a grid as coarse as its own switching error), at an
# error up to NEAR_EDGE (model units, a tile is 1), is lossy.
const KEEP := 0.6
const NEAR_EDGE := 0.6
# Cell sizes of the clustering ladder; each level's switching error is its cell size.
const CELLS := [0.1, 0.2, 0.4, 0.8, 1.6]
# Levels are kept while they remove at least this share of the previous level's triangles and leave this many.
const MIN_GAIN := 0.15
const MIN_TRIANGLES := 24
const MIN_SURFACE_TRIANGLES := 300
const KEPT_FORMAT_FLAGS := Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES | Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS

func _post_import(scene: Node) -> Object:
	var coverage = Coverage.new()
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh as ArrayMesh
		if mesh == null:
			continue
		var guarded := guard(mesh, coverage)
		if guarded != null:
			node.mesh = guarded
			print("LOD_GUARD ", get_source_file(), " ", node.name, ": ladder replaced")
	return scene

# The LOD levels Godot generated for a surface: edge length -> triangle indices, as the rendering server holds them.
func lods_of(mesh: ArrayMesh, surface: int, vertex_count: int) -> Dictionary:
	var result := {}
	var info := RenderingServer.mesh_get_surface(mesh.get_rid(), surface)
	var wide := vertex_count >= 65536
	for lod in info.get("lods", []):
		var data: PackedByteArray = lod.index_data
		var count := data.size() / (4 if wide else 2)
		var indices := PackedInt32Array()
		indices.resize(count)
		for i in count:
			indices[i] = data.decode_u32(i * 4) if wide else data.decode_u16(i * 2)
		result[float(lod.edge_length)] = indices
	return result

# A copy of the mesh whose lossy surfaces have a clustering ladder in place of Godot's LODs; null when none needed it.
func guard(mesh: ArrayMesh, coverage) -> ArrayMesh:
	var existing: Array[Dictionary] = []
	var fixed := {}
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var lods := lods_of(mesh, surface, (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		existing.append(lods)
		if mesh.surface_get_primitive_type(surface) == Mesh.PRIMITIVE_TRIANGLES and is_lossy(arrays, lods, coverage):
			var ladder := cluster_ladder(arrays, coverage)
			if ladder.is_empty():
				# Nothing clusters better (thin parts finer than any cell): keep only Godot's sound levels, so the part stays at
				# its last good LOD instead of losing its shape.
				ladder = sound_levels(arrays, lods, coverage)
			fixed[surface] = ladder
	if fixed.is_empty():
		return null
	var copy := ArrayMesh.new()
	copy.resource_name = mesh.resource_name
	copy.blend_shape_mode = mesh.blend_shape_mode
	for shape in mesh.get_blend_shape_count():
		copy.add_blend_shape(mesh.get_blend_shape_name(shape))
	for surface in mesh.get_surface_count():
		var info := RenderingServer.mesh_get_surface(mesh.get_rid(), surface)
		var shapes: Array[Array] = []
		for shape in mesh.surface_get_blend_shape_arrays(surface):
			shapes.append(shape)
		copy.add_surface_from_arrays(mesh.surface_get_primitive_type(surface), mesh.surface_get_arrays(surface), shapes,
				fixed.get(surface, existing[surface]), int(info.get("format", 0)) & KEPT_FORMAT_FLAGS)
		copy.surface_set_material(surface, mesh.surface_get_material(surface))
		copy.surface_set_name(surface, mesh.surface_get_name(surface))
	return copy

# Whether a surface's near LODs lose a view's silhouette (the shape of a roof or wall), as `audit_lod_coverage.gd` judges.
func is_lossy(arrays: Array, lods: Dictionary, coverage) -> bool:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if lods.is_empty() or indices.size() / 3 < MIN_SURFACE_TRIANGLES:
		return false
	var low := Vector3(1e9, 1e9, 1e9)
	var high := Vector3(-1e9, -1e9, -1e9)
	for vertex in vertices:
		low = low.min(vertex)
		high = high.max(vertex)
	for edge in lods:
		if edge <= NEAR_EDGE and coverage.kept(vertices, indices, lods[edge], low, high - low, edge) < KEEP:
			return true
	return false

# Godot's own levels up to (not including) the first one that loses the shape at a near error.
func sound_levels(arrays: Array, lods: Dictionary, coverage) -> Dictionary:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var low := Vector3(1e9, 1e9, 1e9)
	var high := Vector3(-1e9, -1e9, -1e9)
	for vertex in vertices:
		low = low.min(vertex)
		high = high.max(vertex)
	var edges := lods.keys()
	edges.sort()
	var kept_levels := {}
	for edge in edges:
		if edge <= NEAR_EDGE and coverage.kept(vertices, indices, lods[edge], low, high - low, edge) < KEEP:
			break
		kept_levels[edge] = lods[edge]
	return kept_levels

# The clustering LODs of a surface. A near level (error up to NEAR_EDGE) that itself loses the shape is left out, so the guard
# never offers a worse LOD than the full mesh; levels beyond that only apply when the model is a few pixels wide.
func cluster_ladder(arrays: Array, coverage) -> Dictionary:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var low := Vector3(1e9, 1e9, 1e9)
	var high := Vector3(-1e9, -1e9, -1e9)
	for vertex in vertices:
		low = low.min(vertex)
		high = high.max(vertex)
	var ladder := {}
	var previous := indices.size() / 3
	for cell in CELLS:
		var level := cluster(vertices, normals, indices, cell)
		var count := level.size() / 3
		if count < MIN_TRIANGLES:
			break
		if count > previous * (1.0 - MIN_GAIN):
			continue
		if cell <= NEAR_EDGE and coverage.kept(vertices, indices, level, low, high - low, cell) < KEEP:
			continue
		ladder[cell] = level
		previous = count
	return ladder

# Triangles of `indices` with their vertices replaced by their cluster's representative; collapsed and repeated ones dropped.
func cluster(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, cell: float) -> PackedInt32Array:
	var sums := {}
	var keys: Array = []
	keys.resize(vertices.size())
	for i in vertices.size():
		# Faces looking different ways stay apart, so the two sides of a thin shell do not fuse.
		var facing := 0
		if i < normals.size():
			var n := normals[i]
			var axis := n.abs().max_axis_index()
			facing = axis * 2 + (1 if n[axis] < 0.0 else 0)
		var key := Vector4i(floori(vertices[i].x / cell), floori(vertices[i].y / cell), floori(vertices[i].z / cell), facing)
		keys[i] = key
		if not sums.has(key):
			sums[key] = [0.0, 0.0, 0.0, 0.0]
		var sum: Array = sums[key]
		sum[0] += vertices[i].x
		sum[1] += vertices[i].y
		sum[2] += vertices[i].z
		sum[3] += 1.0
	# The representative: the member nearest the cluster's centroid.
	var best := {}
	for i in vertices.size():
		var sum: Array = sums[keys[i]]
		var centre: Vector3 = Vector3(sum[0], sum[1], sum[2]) / sum[3]
		var distance: float = vertices[i].distance_squared_to(centre)
		if not best.has(keys[i]) or distance < best[keys[i]][0]:
			best[keys[i]] = [distance, i]
	var owner := PackedInt32Array()
	owner.resize(vertices.size())
	for i in vertices.size():
		owner[i] = best[keys[i]][1]
	var result := PackedInt32Array()
	var seen := {}
	for t in range(0, indices.size() - 2, 3):
		var a: int = owner[indices[t]]
		var b: int = owner[indices[t + 1]]
		var c: int = owner[indices[t + 2]]
		if a == b or b == c or a == c:
			continue
		# The same triangle with the same winding (in any rotation) once.
		var low := mini(a, mini(b, c))
		var high := maxi(a, maxi(b, c))
		var middle := a + b + c - low - high
		var key := Vector3i(low, middle, high)
		var winding := 1 if (a == low and b == middle) or (b == low and c == middle) or (c == low and a == middle) else -1
		if seen.has(key) and seen[key] == winding:
			continue
		seen[key] = winding
		result.append(a)
		result.append(b)
		result.append(c)
	return result
