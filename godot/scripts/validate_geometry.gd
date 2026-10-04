extends SceneTree
# Geometry budget gate for the development GLBs (headless, read-only).
#
# Every heavy asset must keep an automatic LOD ladder, and no asset's full-detail
# triangle count may grow past its recorded baseline. The city weights each asset by
# its real instance count, so the report shows where a realtime budget is spent.
#   --write-baseline   record the current triangle counts as the new baseline
# The LOD ladder is what lets the renderer's mesh LOD threshold (project.godot) thin
# distant buildings; a model exported without one silently costs full price at any range.
const BASELINE := "res://data/geometry_baseline.json"
const LOD_REQUIRED_ABOVE := 5000
const GROWTH_TOLERANCE := 1.05

var okay := true
var writing := false

func check(value: bool, description: String) -> void:
	print("GEOMETRY_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func collect(node: Node, out: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		out.append(node.mesh)
	for child in node.get_children():
		collect(child, out)

func measure(asset: String) -> Dictionary:
	var scene: Node = load("res://assets/models/%s.glb" % asset).instantiate()
	var meshes: Array = []
	collect(scene, meshes)
	var result := {"tris": 0, "last_lod_tris": 0, "lods": 0, "blend_shapes": 0, "verts": 0}
	for mesh in meshes:
		result.blend_shapes += mesh.get_blend_shape_count()
		for surface in mesh.get_surface_count():
			var info: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), surface)
			var stride := 4 if int(info.get("vertex_count", 0)) > 65535 else 2
			var base: int = info.get("index_data", PackedByteArray()).size() / stride / 3
			var lods: Array = info.get("lods", [])
			result.verts += int(info.get("vertex_count", 0))
			result.tris += base
			result.lods += lods.size()
			result.last_lod_tris += lods[-1].get("index_data", PackedByteArray()).size() / stride / 3 if not lods.is_empty() else base
	scene.free()
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	writing = "--write-baseline" in OS.get_cmdline_user_args()
	var baseline: Dictionary = {}
	if FileAccess.file_exists(BASELINE):
		baseline = JSON.parse_string(FileAccess.get_file_as_string(BASELINE)).get("assets", {})
	var names: Array = []
	for file in DirAccess.get_files_at("res://assets/models"):
		if file.ends_with(".glb"):
			names.append(file.trim_suffix(".glb"))
	names.sort()
	check(names.size() >= 240, "all development GLBs are present (%d)" % names.size())
	var stats := {}
	var missing_lods: Array = []
	var grown: Array = []
	var unrecorded: Array = []
	for asset in names:
		var value := measure(asset)
		stats[asset] = value
		if value.tris > LOD_REQUIRED_ABOVE and value.lods == 0:
			missing_lods.append("%s (%d tris)" % [asset, value.tris])
		if not writing:
			if not baseline.has(asset):
				unrecorded.append(asset)
			elif value.tris > int(baseline[asset].tris) * GROWTH_TOLERANCE:
				grown.append("%s %d -> %d" % [asset, int(baseline[asset].tris), value.tris])
	check(missing_lods.is_empty(), "every asset above %d triangles has a LOD ladder %s" % [LOD_REQUIRED_ABOVE, str(missing_lods)])
	if writing:
		var record := {}
		for asset in names:
			record[asset] = {"tris": stats[asset].tris, "verts": stats[asset].verts}
		var file := FileAccess.open(BASELINE, FileAccess.WRITE)
		file.store_string(JSON.stringify({"note": "Full-detail triangle counts per development GLB. validate_geometry.gd fails if an asset grows more than 5% or lacks a LOD ladder. Regenerate with --write-baseline only for a deliberate art change.", "assets": record}, "\t", true) + "\n")
		file.close()
		print("GEOMETRY baseline written for %d assets" % names.size())
	else:
		check(unrecorded.is_empty(), "every asset has a recorded baseline %s" % str(unrecorded))
		check(grown.is_empty(), "no asset grew more than 5%% over its baseline %s" % str(grown))
	var total_tris := 0
	var total_last := 0
	var with_blend := 0
	for asset in names:
		total_tris += stats[asset].tris
		total_last += stats[asset].last_lod_tris
		if stats[asset].blend_shapes > 0:
			with_blend += 1
	print("GEOMETRY models: %d, full detail %.1f M triangles, lowest LODs %.2f M, morph-target models %d" % [names.size(), total_tris / 1e6, total_last / 1e6, with_blend])
	# Weight by real instance counts in the designated city.
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var state: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	var by_asset := {}
	var city_total := 0
	for entry in state.get("buildings", []) + state.get("walkers", []):
		if stats.has(entry.asset):
			by_asset[entry.asset] = by_asset.get(entry.asset, 0) + 1
			city_total += stats[entry.asset].tris
	var rows: Array = []
	for asset in by_asset:
		rows.append([by_asset[asset] * stats[asset].tris, asset, by_asset[asset]])
	rows.sort()
	rows.reverse()
	print("GEOMETRY designated city at full detail: %.1f M triangles" % (city_total / 1e6))
	for row in rows.slice(0, 8):
		print("GEOMETRY   %-26s x%-4d %.2f M  (%.0f%%)" % [row[1], row[2], row[0] / 1e6, 100.0 * row[0] / city_total])
	core.close_city()
	print("GEOMETRY_VALIDATION ", "PASS" if okay else "FAIL")
	quit(0 if okay else 1)
