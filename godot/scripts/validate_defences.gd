extends SceneTree
const Perch = preload("res://scripts/defence_perch.gd")
var okay := true
var checks := 0
var measurements := {}

func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("DEFENCE_CHECK ", "PASS " if value else "FAIL ", description)

func collect(node: Node, parts: Array) -> void:
	if node is MeshInstance3D: parts.append(node)
	for child in node.get_children(): collect(child, parts)

func run() -> void:
	var names: Array = ["tower", "gatehouse"]
	for mask in 16: names.append("wall_%d" % mask)
	for asset in names:
		var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % asset))
		check(contract.source == "eZeus/tools/godot_defences.py" and contract.defence == Perch.ART.data, asset + " model and roof contract match the installed builder")
		var node: Node = load("res://assets/models/%s.glb" % asset).instantiate()
		root.add_child(node)
		var parts: Array = []; collect(node, parts)
		var stats := {"tris": 0, "verts": 0, "lods": 0, "last_lod_tris": 0}
		var uvs := true
		var clear_passage := true
		for part in parts:
			for surface in part.mesh.get_surface_count():
				var arrays: Array = part.mesh.surface_get_arrays(surface)
				uvs = uvs and arrays[Mesh.ARRAY_TEX_UV] != null
				if asset == "gatehouse":
					for vertex in arrays[Mesh.ARRAY_VERTEX]:
						var point: Vector3 = part.global_transform * vertex
						if point.y > .1 and point.y < 2.15 and absf(point.z) < 1.02 and absf(point.x) < .5:
							clear_passage = false
				var info: Dictionary = RenderingServer.mesh_get_surface(part.mesh.get_rid(), surface)
				var stride := 4 if int(info.vertex_count) > 65535 else 2
				var triangles: int = info.index_data.size() / stride / 3
				var lods: Array = info.get("lods", [])
				stats.tris += triangles; stats.verts += int(info.vertex_count); stats.lods += lods.size()
				stats.last_lod_tris += lods[-1].index_data.size() / stride / 3 if not lods.is_empty() else triangles
		measurements[asset] = stats
		check(uvs and parts.size() <= 3, asset + " preserves authored UVs and at most three surfaces")
		var budget := 25000 if asset == "gatehouse" else (10000 if asset == "tower" else 6000)
		check(stats.tris <= budget and stats.verts <= (34000 if asset == "gatehouse" else budget), asset + " imported geometry stays within its allocation")
		check(stats.lods > 0 and stats.last_lod_tris < stats.tris, asset + " has reduced imported LODs")
		if asset == "gatehouse": check(clear_passage, "the imported portal columns/doors leave the full native one-tile passage clear")
		node.free()
	var perch := Perch.new()
	var tower := {"asset": "tower", "x": 10, "y": 20, "w": 2, "h": 2, "altitude": 7}
	perch.refresh([tower])
	check(perch.cells.size() == 4, "all four native tower cells resolve the same platform")
	var walker := {"x": 10.01, "y": 21.99, "lift": 2.57}
	var before := walker.duplicate(true)
	var roof: Dictionary = perch.roof(walker)
	var safe := Perch.safe_point(Vector2(9.51, 21.49), roof)
	check(absf(safe.x - 10.5) <= .58 and absf(safe.y - 20.5) <= .58 and Perch.lift(roof, 2.57) == 3.05, "extreme native positions stay inside the tower battlements at the exact model height")
	check(walker == before and tower.altitude == 7, "projection leaves native coordinates and foundation unchanged")
	walker.lift = 0.0
	check(perch.roof(walker).is_empty(), "ground archers retain their original path and height")
	for mask in 16:
		perch.refresh([{"asset": "wall_%d" % mask, "x": 10, "y": 20, "w": 1, "h": 1, "altitude": 0}])
		var wall: Dictionary = perch.roof({"x": 10.5, "y": 20.5, "lift": .8})
		var bounded := true
		for dx in [-.49, 0.0, .49]:
			for dy in [-.49, 0.0, .49]:
				var point := Perch.safe_point(Vector2(10 + dx, 20 + dy), wall) - Vector2(10, 20)
				var nearest := point.length()
				for bit in Perch.DIRS:
					if mask & int(bit):
						var direction: Vector2 = Perch.DIRS[bit]
						nearest = minf(nearest, point.distance_to(direction * clampf(point.dot(direction), 0, .5)))
				bounded = bounded and nearest <= .15001
		check(bounded and Perch.lift(wall, .8) == 2.0, "mask %d keeps interpolated patrol points on its connected walk" % mask)
	perch.refresh([])
	check(perch.cells.is_empty(), "demolition/reload clears the footprint cache")
	var file := FileAccess.open("res://captures/defence-runtime.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements, "\t") + "\n"); file.close()
	print("DEFENCE_VALIDATION ", "PASS " if okay else "FAIL ", checks, " checks")
	quit(0 if okay else 1)
