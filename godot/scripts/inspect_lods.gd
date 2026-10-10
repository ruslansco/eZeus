extends SceneTree
# For each named model, every surface at full detail and at each imported LOD level: triangles, the area its upward-facing
# triangles cover seen from above (a roof's footprint), and its highest point. A roof that a LOD drops shows as 0 area.
func _initialize() -> void:
	call_deferred("run")

func walk(node: Node, out: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		out.append(node)
	for child in node.get_children():
		walk(child, out)

func stats(vertices: PackedVector3Array, indices: PackedInt32Array) -> String:
	var area := 0.0
	var top := -1e9
	for i in range(0, indices.size() - 2, 3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i + 1]]
		var c := vertices[indices[i + 2]]
		var n := (b - a).cross(c - a)
		if n.y > 0:
			area += n.y * .5
		top = maxf(top, maxf(a.y, maxf(b.y, c.y)))
	return "tris=%d topArea=%.2f maxY=%.2f" % [indices.size() / 3, area, top]

func run() -> void:
	var names: PackedStringArray = OS.get_cmdline_user_args()
	for asset in names:
		var scene: Node = load("res://assets/models/%s.glb" % asset).instantiate()
		var meshes: Array = []
		walk(scene, meshes)
		for node in meshes:
			var mesh: ArrayMesh = node.mesh
			for s in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(s)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var info := RenderingServer.mesh_get_surface(mesh.get_rid(), s)
				var full: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				print("LOD ", asset, " ", node.name, " s", s, " full  ", stats(vertices, full))
				var level := 0
				for lod in info.get("lods", []):
					var data: PackedByteArray = lod.index_data
					var count := data.size() / (2 if vertices.size() < 65536 else 4)
					var idx := PackedInt32Array()
					idx.resize(count)
					for i in count:
						idx[i] = data.decode_u16(i * 2) if vertices.size() < 65536 else data.decode_u32(i * 4)
					level += 1
					print("LOD ", asset, " ", node.name, " s", s, " lod", level, " ", stats(vertices, idx), " edge=", lod.get("edge_length", -1))
		scene.free()
	quit()
