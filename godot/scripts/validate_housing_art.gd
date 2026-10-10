extends SceneTree
# Read-only housing art gate. Optional baseline refresh changes these seven
# deliberate art entries only, preserving unrelated assets in the dirty tree.
const ART = preload("res://data/housing_art.json")
var okay := true
var checks := 0
var measurements := {}

func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("HOUSING_ART_CHECK ", "PASS " if value else "FAIL ", label)
func collect(node: Node, parts: Array) -> void:
	if node is MeshInstance3D: parts.append(node)
	for child in node.get_children(): collect(child, parts)

func run() -> void:
	var previous := 0.0
	for level in 7:
		var asset := "common_house_%da" % level
		var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % asset))
		var housing: Dictionary = contract.get("housing", {})
		check(contract.source == ART.data.source and housing.get("revision", 0) == ART.data.revision and housing.get("level", -1) == level, asset + ": installed source/level matches the common-house art contract")
		var height: float = housing.get("measured_architecture_height", 0.0)
		check(absf(height - ART.data.architecture_heights[level]) < .00001 and height > previous + .15, asset + ": authored architecture grows gradually at the specified height")
		previous = height
		var before: Array = housing.get("resident_heights_before", [])
		var after: Array = housing.get("resident_heights_after", [])
		var people := before.size() > 0 and before.size() == after.size()
		for i in mini(before.size(), after.size()): people = people and absf(float(before[i]) - float(after[i])) < .00001
		check(people, asset + ": resident anatomy keeps its source height")
		var node: Node3D = load("res://assets/models/%s.glb" % asset).instantiate()
		root.add_child(node)
		var parts: Array = []; collect(node, parts)
		var stats := {"tris":0, "verts":0, "lods":0, "last_lod_tris":0}
		var uvs := true; var palette := true; var finite := true; var footprint := true
		var neutral_yard := 0; var roof_reeds := 0
		for part in parts:
			for surface in part.mesh.get_surface_count():
				var arrays: Array = part.mesh.surface_get_arrays(surface)
				uvs = uvs and arrays[Mesh.ARRAY_TEX_UV] != null and arrays[Mesh.ARRAY_TEX_UV2] != null
				palette = palette and arrays[Mesh.ARRAY_COLOR] != null
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
				for i in vertices.size():
					var point: Vector3 = part.global_transform * vertices[i]
					finite = finite and point.is_finite()
					footprint = footprint and absf(point.x) < 1.06 and absf(point.z) < 1.06
					if i >= colours.size(): continue
					var c: Color = colours[i]
					if point.y < .02 and absf(c.r-.21)<.015 and absf(c.g-.225)<.015 and absf(c.b-.17)<.015: neutral_yard += 1
					if point.y > .5 and absf(c.r-.34)<.015 and absf(c.g-.28)<.015 and absf(c.b-.16)<.015: roof_reeds += 1
				var info: Dictionary = RenderingServer.mesh_get_surface(part.mesh.get_rid(), surface)
				var stride := 4 if int(info.vertex_count)>65535 else 2
				var triangles: int = info.index_data.size()/stride/3
				var lods: Array = info.get("lods", [])
				stats.tris += triangles; stats.verts += int(info.vertex_count); stats.lods += lods.size()
				stats.last_lod_tris += lods[-1].index_data.size()/stride/3 if not lods.is_empty() else triangles
		measurements[asset] = stats
		check(uvs and palette and parts.size() <= 3, asset + ": both UVs, vertex palette and bounded PBR surfaces survive import")
		check(finite and footprint, asset + ": finite geometry fits the unchanged two-by-two footprint")
		# Simplification allocates 24K source vertices; small disconnected material
		# groups/seams permit the same five-percent allowance as the geometry gate.
		check(int(contract.vertices)<=ART.data.vertex_budget*1.05 and stats.tris<60000 and stats.verts<110000, asset + ": repeated house geometry stays within its allocation")
		check(stats.lods>0 and stats.last_lod_tris<stats.tris*.8, asset + ": imported reduced LODs remain effective")
		if level < 4: check(neutral_yard>0, asset + ": the earth yard uses muted neutral soil")
		if level < 2: check(roof_reeds>0, asset + ": starter roof keeps its brown reed palette instead of white")
		node.free()
	if "--write-baseline" in OS.get_cmdline_user_args() and okay:
		var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/geometry_baseline.json"))
		for asset in measurements: baseline.assets[asset] = {"tris":measurements[asset].tris, "verts":measurements[asset].verts}
		var output := FileAccess.open("res://data/geometry_baseline.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(baseline, "\t", true)+"\n"); output.close()
		print("HOUSING_ART_BASELINE updated only seven common-house entries")
	var report := FileAccess.open("res://captures/housing-runtime.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(measurements, "\t")+"\n"); report.close()
	print("HOUSING_ART_VALIDATION ", "PASS " if okay else "FAIL ", " checks=", checks)
	quit(0 if okay else 1)
