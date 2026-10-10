extends SceneTree
# Draws one surface of a model at full detail and at each of its imported LOD levels, side by side, from the imported index
# data. Usage: -- <tag> <asset> <mesh node name> [surface]; writes captures/lodlevels-<tag>-<asset>.png
func _initialize() -> void:
	call_deferred("run")

func find_mesh(node: Node, wanted: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == wanted:
		return node
	for child in node.get_children():
		var hit := find_mesh(child, wanted)
		if hit:
			return hit
	return null

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene: Node = load("res://assets/models/%s.glb" % args[1]).instantiate()
	var source := find_mesh(scene, args[2])
	var mesh: ArrayMesh = source.mesh
	var surface := int(args[3]) if args.size() > 3 else 0
	var arrays := mesh.surface_get_arrays(surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var info := RenderingServer.mesh_get_surface(mesh.get_rid(), surface)
	var variants: Array = [arrays[Mesh.ARRAY_INDEX]]
	for lod in info.get("lods", []):
		var data: PackedByteArray = lod.index_data
		var wide := vertices.size() >= 65536
		var count := data.size() / (4 if wide else 2)
		var idx := PackedInt32Array()
		idx.resize(count)
		for i in count:
			idx[i] = data.decode_u32(i * 4) if wide else data.decode_u16(i * 2)
		variants.append(idx)
	var root := Node3D.new()
	get_root().add_child(root)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.35, .5, .3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.8, .8, .8)
	root.add_child(env)
	var material := source.mesh.surface_get_material(surface)
	var spacing := 6.0
	for index in variants.size():
		var copy := arrays.duplicate()
		copy[Mesh.ARRAY_INDEX] = variants[index]
		var piece := ArrayMesh.new()
		piece.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, copy)
		piece.surface_set_material(0, material)
		var instance := MeshInstance3D.new()
		instance.mesh = piece
		instance.position = Vector3((index - (variants.size() - 1) * .5) * spacing, 0, 0)
		root.add_child(instance)
		print("LEVEL ", index, " tris=", variants[index].size() / 3)
	var camera := Camera3D.new()
	camera.fov = 40
	root.add_child(camera)
	camera.current = true
	get_root().size = Vector2i(1500, 500)
	camera.position = Vector3(0, 14, 9)
	camera.look_at(Vector3(0, 0.5, 0))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://captures/lodlevels-%s-%s.png" % [args[0], args[1]]))
	quit()
