extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var okay := true
	var count := 0
	for file in DirAccess.get_files_at("res://assets/models"):
		if not file.ends_with(".json"): continue
		var asset := file.trim_suffix(".json")
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/" + file))
		count += 1
		var resource := load("res://assets/models/%s.glb" % asset) as PackedScene
		if resource == null:
			print("ASSET_CHECK FAIL missing ", asset)
			okay = false
			continue
		var node := resource.instantiate()
		root.add_child(node)
		var meshes: Array[MeshInstance3D] = []
		collect(node, meshes)
		var vertices := 0
		var shapes := 0
		var frames_ok := true
		var clip_frames := 0
		var movement := 0.0
		for mesh in meshes:
			vertices += mesh.mesh.get_faces().size()
			shapes = max(shapes, mesh.mesh.get_blend_shape_count())
			if mesh.mesh.get_blend_shape_count() > 0:
				# Identical poses are merged as "idle_00|idle_01|..."; every one of the 35 frame
				# names (walk_01..walk_23, idle_00..idle_11) must still resolve to a stored shape.
				var names := {}
				for shape in mesh.mesh.get_blend_shape_count():
					for alias in String(mesh.mesh.get_blend_shape_name(shape)).split("|"):
						names[alias] = true
				# Soldiers, heroes and gods add contiguous clips (fight, fight2, die, bless, curse, disappear, appear) to the 35 walking and idle frames.
				var clip_sizes := {}
				var base_frames := 0
				for frame_name in names:
					var label := String(frame_name).rsplit("_", true, 1)[0]
					if label in ["walk", "idle"]:
						base_frames += 1
					else:
						clip_sizes[label] = int(clip_sizes.get(label, 0)) + 1
				var clips_ok := base_frames >= 35 and base_frames <= 36
				for index in range(1, 24):
					clips_ok = clips_ok and names.has("walk_%02d" % index)
				for index in range(12):
					clips_ok = clips_ok and names.has("idle_%02d" % index)
				for label in clip_sizes:
					var combat_clip: bool = label in ["fight", "fight2", "die", "bless", "curse", "disappear", "appear"]
					var declared: int = int(manifest.get("gathering",{}).get(str(label)+"_samples",0))
					var gathering_clip: bool = label in ["collect","carry","deposit"] and declared > 0 and int(clip_sizes[label]) == declared
					clips_ok = clips_ok and (combat_clip or gathering_clip)
					for frame in int(clip_sizes[label]):
						clips_ok = clips_ok and names.has("%s_%02d" % [label, frame])
				for label in ["collect","carry","deposit"]:
					var declared: int = int(manifest.get("gathering",{}).get(label+"_samples",0))
					if declared > 0: clips_ok = clips_ok and int(clip_sizes.get(label,0)) == declared
				frames_ok = frames_ok and clips_ok
				clip_frames = max(clip_frames, names.size() - 35)
				var base: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for arrays in mesh.mesh.surface_get_blend_shape_arrays(0):
					var posed: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
					for index in range(posed.size()):
						var offset := posed[index] if mesh.mesh.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE else posed[index] - base[index]
						movement = max(movement, offset.length())
		var good := vertices > 0 and meshes.size() > 0
		if int(manifest.get("walk_samples", 0)) > 0:
			good = good and frames_ok and shapes >= 1 and shapes <= 35 + clip_frames and movement > .01
		print("ASSET_CHECK ", "PASS " if good else "FAIL ", asset, " meshes=", meshes.size(), " triangle_vertices=", vertices, " morphs=", shapes, " clip_frames=", clip_frames, " movement=", movement)
		okay = okay and good
		node.free()
		await process_frame
	await process_frame
	print("ASSET_VALIDATION ", "PASS" if okay else "FAIL", " count=", count)
	quit(0 if okay else 1)

func collect(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		result.append(node)
	for child in node.get_children():
		collect(child, result)
