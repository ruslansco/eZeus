extends SceneTree
# Baked-pose gate (headless, read-only): every animated model's runtime derivative must
# carry exactly the source's rest geometry and poses.
#
# For each animated model (manifest walk_samples > 0) with a fresh derivative it checks that
# the imported runtime meshes have no morph targets or shadow mesh, that every vertex has a
# unique integer texel address in CUSTOM0, and that the position set of each pose
# (rest vertex + texture displacement) of every distinct pose matches the source's blend
# shapes in bounds and second moment. A derivative older than its source is reported as a warning: the game then
# falls back to blend shapes (more video memory) until tools/bake_walker_vat.py is run.
const WalkerVat = preload("res://scripts/walker_vat.gd")
var okay := true
var worst_gap := 0.0
# Quantized rest positions and half-float displacements stay far below this; a swapped
# or shifted pose is far above it (see the validation document).
const TOLERANCE := .004

func check(value: bool, description: String) -> void:
	print("POSE_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func collect(node: Node, out: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh != null:
		out[str(node.name)] = node
	for child in node.get_children():
		collect(child, out)

# Order-independent fingerprint of a point set: bounds, mean squared length and the means of
# two high-frequency functions of position. The latter change measurably when a limb moves by
# a few hundredths of a unit, so neighbouring walk frames cannot be confused.
func summarize(points: PackedVector3Array) -> Dictionary:
	var low := Vector3(1e9, 1e9, 1e9)
	var high := -low
	var squares := 0.0
	var wave_a := 0.0
	var wave_b := 0.0
	for p in points:
		low = low.min(p)
		high = high.max(p)
		squares += p.length_squared()
		wave_a += sin(41.0 * p.x + 17.0 * p.y) * cos(29.0 * p.z)
		wave_b += cos(37.0 * p.z - 23.0 * p.x) * sin(31.0 * p.y)
	var n := float(maxi(points.size(), 1))
	return {"low": low, "high": high, "mean_square": squares / n, "wave_a": wave_a / n, "wave_b": wave_b / n}

func distance(a: Dictionary, b: Dictionary) -> float:
	return maxf(maxf((a.low - b.low).length(), (a.high - b.high).length()), maxf(maxf(absf(a.mean_square - b.mean_square), absf(a.wave_a - b.wave_a)), absf(a.wave_b - b.wave_b)))

func shape_index(mesh: ArrayMesh, frame: String) -> int:
	for i in mesh.get_blend_shape_count():
		if frame in String(mesh.get_blend_shape_name(i)).split("|"):
			return i
	return -1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var vat := WalkerVat.new()
	var animated: Array = []
	for file in DirAccess.get_files_at("res://assets/models"):
		if file.ends_with(".json"):
			var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/" + file))
			if manifest is Dictionary and int(manifest.get("walk_samples", 0)) > 0:
				animated.append(file.trim_suffix(".json"))
	animated.sort()
	var stale: Array = []
	var verified := 0
	var frames_checked := 0
	for asset in animated:
		if vat.runtime_path(asset).is_empty():
			stale.append(asset)
			continue
		var contract: Dictionary = vat.contracts[asset]
		var source_parts := {}
		var runtime_parts := {}
		var source_scene: Node = load("res://assets/models/%s.glb" % asset).instantiate()
		var runtime_scene: Node = load("res://assets/models/runtime/%s.glb" % asset).instantiate()
		collect(source_scene, source_parts)
		collect(runtime_scene, runtime_parts)
		var bytes := FileAccess.get_file_as_bytes("res://assets/models/runtime/%s.vat" % asset)
		var image := Image.create_from_data(int(contract.width), int(contract.height), false, Image.FORMAT_RGBAH, bytes)
		var good: bool = image != null and runtime_parts.size() >= contract.parts.size()
		for part_name in contract.parts:
			var info: Dictionary = contract.parts[part_name]
			var runtime_node: MeshInstance3D = runtime_parts.get(part_name)
			var source_node: MeshInstance3D = source_parts.get(part_name)
			if runtime_node == null or source_node == null:
				good = false
				continue
			var runtime_mesh: ArrayMesh = runtime_node.mesh
			var source_mesh: ArrayMesh = source_node.mesh
			var arrays := runtime_mesh.surface_get_arrays(0)
			var base: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var address = arrays[Mesh.ARRAY_CUSTOM0]
			good = good and runtime_mesh.get_blend_shape_count() == 0 and runtime_mesh.shadow_mesh == null and address != null and address.size() == base.size() * 2
			if not good:
				continue
			var seen := {}
			for i in base.size():
				var index := int(address[i * 2]) + 1024 * int(address[i * 2 + 1])
				good = good and address[i * 2] == floorf(address[i * 2]) and address[i * 2 + 1] == floorf(address[i * 2 + 1]) and index >= 0 and index < base.size() and not seen.has(index)
				seen[index] = true
			var source_arrays := source_mesh.surface_get_arrays(0)
			var source_base: PackedVector3Array = source_arrays[Mesh.ARRAY_VERTEX]
			var source_blends := source_mesh.surface_get_blend_shape_arrays(0)
			good = good and source_base.size() == base.size()
			if not good:
				continue
			# One frame name per distinct pose, plus the rest pose when a frame resolves to it.
			var names: Array = info.frames.keys()
			names.sort()
			var by_pose := {}
			for frame in names:
				if not by_pose.has(int(info.frames[frame])):
					by_pose[int(info.frames[frame])] = frame
			for pose_key in by_pose:
				var frame: String = by_pose[pose_key]
				var pose := int(info.frames[frame])
				var posed := PackedVector3Array()
				posed.resize(base.size())
				var largest_delta := 0.0
				for i in base.size():
					var delta := Vector3.ZERO
					if pose >= 0:
						var color := image.get_pixel(int(address[i * 2]), int(info.row) + pose * int(info.rows) + int(address[i * 2 + 1]))
						delta = Vector3(color.r, color.g, color.b)
					largest_delta = maxf(largest_delta, delta.length())
					posed[i] = base[i] + delta
				var shape := shape_index(source_mesh, frame)
				var expected: PackedVector3Array = source_blends[shape][Mesh.ARRAY_VERTEX] if shape >= 0 else source_base
				frames_checked += 1
				var fingerprint := summarize(expected)
				var gap := distance(summarize(posed), fingerprint)
				worst_gap = maxf(worst_gap, gap)
				# A pose that moves a part a long way from its rest position (a god's disappearing clip) differs from the source by a few
				# millimetres more than a walking pose does; the allowance grows with the largest displacement (0.3 percent of it). Half
				# floats account for part of that; I did not establish whether the baker's merging of near-identical poses adds the rest.
				var allowance := maxf(TOLERANCE, largest_delta * .003)
				if gap > allowance:
					good = false
					print("POSE_CHECK detail ", asset, " ", part_name, " frame ", frame, " differs from the source blend shape (gap ", gap, ", allowed ", allowance, ", largest displacement ", largest_delta, ")")
		source_scene.free()
		runtime_scene.free()
		verified += 1
		check(good, "%s: baked poses match the source blend shapes" % asset)
		await process_frame
	check(verified + stale.size() == animated.size() and verified > 0, "%d animated models: %d verified, %d without a fresh derivative" % [animated.size(), verified, stale.size()])
	if not stale.is_empty():
		print("POSE_CHECK WARN no fresh baked poses (the game uses blend shapes, which costs video memory; run tools/bake_walker_vat.py and import): ", stale)
	print("POSE_VALIDATION ", "PASS" if okay else "FAIL", " frames=", frames_checked, " worst fingerprint gap=", worst_gap)
	quit(0 if okay else 1)
