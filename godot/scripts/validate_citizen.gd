extends SceneTree
# Skeletal citizen and crowd level-of-detail gate (headless, read-only).
#
# Covers the realistic physician benchmark (assets/characters/physician_v2/physician.glb), the
# baked crowd model that stands in for it at a distance (assets/models/physician_crowd.glb) and
# the swap manager (scripts/citizen_lod.gd): rig and clips, geometry and texture budgets, foot
# sliding against the 0.64-tile stride, controller determinism, crowd/skeletal agreement and
# the nearest-first pooled swap. This is technical compatibility, not visual acceptance.
const SkeletalCitizen = preload("res://scripts/skeletal_citizen.gd")
const CitizenLod = preload("res://scripts/citizen_lod.gd")
const WalkerVat = preload("res://scripts/walker_vat.gd")
const STRIDE := 0.64
const MAX_VERTICES := 36000
const MAX_MESHES := 24
const MAX_TEXTURE_SIDE := 2048
const MAX_TEXTURE_MB := 20.0
const MAX_CROWD_VERTICES := 8000
# Measure the actual rolling sandal contact, not the ankle (which rises at toe push-off).
const SLIDE_LIMIT := 0.04

var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("CITIZEN_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func collect(node: Node, out: Array) -> void:
	if node is MeshInstance3D and node.mesh != null:
		out.append(node)
	for child in node.get_children():
		collect(child, out)

func find_class_node(node: Node, kind: String) -> Node:
	if node.get_class() == kind:
		return node
	for child in node.get_children():
		var found := find_class_node(child, kind)
		if found != null:
			return found
	return null

func surface_vertices(mesh: ArrayMesh) -> int:
	var count := 0
	for surface in mesh.get_surface_count():
		count += int(RenderingServer.mesh_get_surface(mesh.get_rid(), surface).get("vertex_count", 0))
	return count

# Bone positions in the same units as the mesh vertices (the skeleton node carries the rig's
# 1.045 scale). A skinned mesh is drawn from its own vertex coordinates, so never multiply a
# mesh bound by the node transform: that overstates the height by 4.5% (side-on silhouettes of
# the skeletal citizen and its crowd stand-in are pixel identical).
func pose_signature(skeleton: Skeleton3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in skeleton.get_bone_count():
		out.append((skeleton.global_transform * skeleton.get_bone_global_pose(i)).origin)
	return out

func bone_height(skeleton: Skeleton3D, bone_name: String) -> float:
	return (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name))).origin.y

func sole_contact(skeleton: Skeleton3D, bone: int) -> Vector3:
	var rest := skeleton.get_bone_global_rest(bone)
	var deform := skeleton.global_transform * skeleton.get_bone_global_pose(bone) * rest.affine_inverse()
	var radius := Vector3(.027,.006,.058) # Blender sandal ellipsoid in Godot Y-up coordinates.
	var vertical := Vector3(deform.basis.x.y,deform.basis.y.y,deform.basis.z.y)
	var support := radius * radius * vertical / (radius * vertical).length()
	return deform * (Vector3(rest.origin.x,.006,.045)-support)

func centroid(points: PackedVector3Array) -> Vector3:
	var sum := Vector3.ZERO
	for point in points:
		sum += point
	return sum / maxf(points.size(), 1)

func max_gap(a: PackedVector3Array, b: PackedVector3Array) -> float:
	var worst := 0.0
	for i in a.size():
		worst = maxf(worst, a[i].distance_to(b[i]))
	return worst

func seek_pose(player: AnimationPlayer, skeleton: Skeleton3D, clip: String, time: float) -> PackedVector3Array:
	player.play(clip)
	player.pause()
	player.seek(time, true)
	return pose_signature(skeleton)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists(SkeletalCitizen.MODEL), "skeletal citizen model is imported")
	var scene: Node3D = load(SkeletalCitizen.MODEL).instantiate()
	root.add_child(scene)
	await process_frame
	var skeleton: Skeleton3D = find_class_node(scene, "Skeleton3D")
	var player: AnimationPlayer = find_class_node(scene, "AnimationPlayer")
	check(skeleton != null and skeleton.get_bone_count() >= 100 and skeleton.get_bone_count() <= 200, "one deformation skeleton with a game-sized bone count (%d)" % (skeleton.get_bone_count() if skeleton else 0))
	check(player != null and player.has_animation("Idle") and player.has_animation("Walk"), "Idle and Walk clips are present")
	if skeleton == null or player == null:
		finish()
		return
	var idle_length := player.get_animation("Idle").length
	var walk_length := player.get_animation("Walk").length
	check(absf(idle_length-3.0)<.001 and absf(walk_length-STRIDE)<.001, "exported loops have exact periods without an initial hold (idle %.2f, walk %.2f s)" % [idle_length, walk_length])

	# Geometry and material budgets.
	var meshes: Array = []
	collect(scene, meshes)
	var vertices := 0
	var surfaces := 0
	var textures := {}
	var weights_ok := true
	for instance in meshes:
		var mesh: ArrayMesh = instance.mesh
		vertices += surface_vertices(mesh)
		surfaces += mesh.get_surface_count()
		weights_ok = weights_ok and instance.skin != null and instance.get_node_or_null(instance.skeleton) is Skeleton3D
		for surface in mesh.get_surface_count():
			var material = instance.get_active_material(surface)
			if material is BaseMaterial3D:
				for slot in BaseMaterial3D.TEXTURE_MAX:
					var texture: Texture2D = material.get_texture(slot)
					if texture != null:
						textures[texture.resource_path if texture.resource_path != "" else str(texture.get_instance_id())] = texture
	check(weights_ok, "every mesh is skinned to the skeleton")
	check(vertices <= MAX_VERTICES and meshes.size() <= MAX_MESHES, "geometry budget: %d vertices (<= %d), %d meshes (<= %d), %d surfaces" % [vertices, MAX_VERTICES, meshes.size(), MAX_MESHES, surfaces])
	var all_compressed := true
	var largest := 0
	var megabytes := 0.0
	for key in textures:
		var image: Image = textures[key].get_image()
		if image == null:
			all_compressed = false
			continue
		all_compressed = all_compressed and image.is_compressed()
		largest = maxi(largest, maxi(image.get_width(), image.get_height()))
		megabytes += image.get_data().size() * (4.0 / 3.0 if image.has_mipmaps() else 1.0) / 1048576.0
	check(not textures.is_empty() and all_compressed, "all %d material textures are VRAM-compressed" % textures.size())
	check(largest <= MAX_TEXTURE_SIDE and megabytes <= MAX_TEXTURE_MB, "texture budget: largest %d px (<= %d), about %.1f MB (<= %.0f)" % [largest, MAX_TEXTURE_SIDE, megabytes, MAX_TEXTURE_MB])
	var blinks := 0
	for instance in meshes:
		if instance.find_blend_shape_by_name("Blink_L") >= 0 and instance.find_blend_shape_by_name("Blink_R") >= 0:
			blinks += 1
	check(blinks >= 1, "eyelid blink shapes are present for close-up blinking")

	# Loop closure: the cycle must start and end in the same pose, or the seek-driven clock pops.
	var walk_start := seek_pose(player, skeleton, "Walk", 0.0)
	var walk_end := seek_pose(player, skeleton, "Walk", walk_length * (1.0 - 1.0 / 256.0))
	var idle_start := seek_pose(player, skeleton, "Idle", 0.0)
	var idle_end := seek_pose(player, skeleton, "Idle", 3.0)
	var walk_seam := max_gap(walk_start, walk_end)
	var idle_seam := max_gap(idle_start, idle_end)
	var swing := max_gap(walk_start, seek_pose(player, skeleton, "Walk", walk_length * 0.5))
	check(swing > 0.05, "the walk clip really moves the body (%.3f units between the phases)" % swing)
	check(walk_seam < 0.01 and idle_seam < 0.01, "walk and idle loops close without a pop (walk %.4f, idle %.4f units)" % [walk_seam, idle_seam])

	# Foot sliding: one native stride (0.64 tiles) of travel is one full walk loop, so the
	# planted foot must travel backwards at exactly the ground speed.
	var foot_bones: Array = []
	var foot_offsets: Array = []
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)
		if name == "foot.L" or name == "foot.R":
			foot_bones.append(i)
			foot_offsets.append(0.0 if name == "foot.L" else .5)
	check(foot_bones.size() == 2, "both foot bones are found")
	var samples := 256
	var step_distance := STRIDE / samples
	var positions: Array = []
	var ankle_heights: Array = []
	var root_travel := 0.0
	var start_centre := centroid(walk_start)
	for k in samples + 1:
		var pose := seek_pose(player, skeleton, "Walk", walk_length * k / samples)
		positions.append([sole_contact(skeleton,foot_bones[0]), sole_contact(skeleton,foot_bones[1])])
		ankle_heights.append([pose[foot_bones[0]].y,pose[foot_bones[1]].y])
		root_travel = maxf(root_travel, Vector2(centroid(pose).x - start_centre.x, centroid(pose).z - start_centre.z).length())
	var floor_y := 1e9
	for pair in positions:
		floor_y = minf(floor_y, minf(pair[0].y, pair[1].y))
	print("CITIZEN_INFO lowest sandal contact ",floor_y)
	var foot_moved := 0.0
	var body_moved := 0.0
	var sliding_error := 0.0
	var stance := 0
	for k in samples:
		for which in 2:
			# Count actual support intervals, including both feet in double support. The
			# newly airborne foot is not planted merely because it is still near the floor.
			var phase := fposmod(float(k)/samples+foot_offsets[which],1.0)
			if phase+1.0/samples>.56:continue
			var a: Vector3 = positions[k][which]
			var b: Vector3 = positions[k + 1][which]
			foot_moved += Vector2(b.x - a.x, b.z - a.z).length()
			sliding_error += Vector2(b.x-a.x,b.z-a.z-step_distance).length()
			body_moved += step_distance
			stance += 1
	var slide := sliding_error / maxf(body_moved, 0.0001)
	print("CITIZEN_INFO stance samples ", stance, "/", samples, " foot ", snappedf(foot_moved, .001), " body ", snappedf(body_moved, .001), " slide ", snappedf(slide, .001), " root travel ", snappedf(root_travel, .001))
	check(stance >= samples / 2, "planted-foot samples exist (%d of %d)" % [stance, samples])
	check(slide <= SLIDE_LIMIT, "mean contact error against the 0.64 stride: %.1f%% of planted travel (<= %.0f%%)" % [100.0 * slide, 100.0 * SLIDE_LIMIT])
	var ground_okay := true; var clearance := 0.0; var rolling := 0.0
	for k in positions.size():
		for side in 2:
			ground_okay = ground_okay and positions[k][side].y >= -.002
			clearance = maxf(clearance,positions[k][side].y)
			if positions[k][side].y < .002: rolling = maxf(rolling,ankle_heights[k][side]-.034*1.045)
	check(ground_okay and clearance > .045, "sandals stay above the floor and clear it on swing (%.3f units)"%clearance)
	check(rolling > .01, "heel/toe roll raises the ankle while the sole stays planted (%.3f units)"%rolling)
	check(root_travel < 0.05, "the walk clip has no root motion (%.3f units)" % root_travel)
	scene.queue_free()
	await process_frame

	# Controller determinism: the pose is a function of travel and walk weight, not of history.
	var citizens: Array = []
	for i in 2:
		var model: Node3D = load(SkeletalCitizen.MODEL).instantiate()
		var controller := SkeletalCitizen.new()
		model.add_child(controller)
		model.set_meta("controller", controller)
		root.add_child(model)
		citizens.append(model)
	await process_frame
	var first: Node = citizens[0].get_meta("controller")
	var second: Node = citizens[1].get_meta("controller")
	check(first.ready_to_sample and second.ready_to_sample, "controllers build their animation tree")
	check(is_equal_approx(first.walk_length, walk_length) and is_equal_approx(first.walk_time(STRIDE * 0.5), walk_length * 0.5) and first.walk_time(STRIDE) < 0.0001 and first.walk_time(STRIDE * 0.999) > walk_length * 0.99, "one stride of travel is exactly one walk loop (clip %.2f s)" % walk_length)
	for step in 30:
		first.sample(1.0 / 20.0, 0.03)
	for step in 12:
		second.sample(1.0 / 20.0, 0.075)
	second.travel = first.travel
	second.elapsed = first.elapsed + 1.7
	first.walk_weight = 1.0
	second.walk_weight = 1.0
	first.sample(0.0, 0.0)
	second.sample(0.0, 0.0)
	var skeleton_a: Skeleton3D = find_class_node(citizens[0], "Skeleton3D")
	var skeleton_b: Skeleton3D = find_class_node(citizens[1], "Skeleton3D")
	# Walk weight decays during the zero-motion sample, so compare with the same dt on both.
	var drift := max_gap(pose_signature(skeleton_a), pose_signature(skeleton_b))
	check(drift < 0.005, "equal travel gives the same walk pose whatever the history (%.4f units apart)" % drift)
	var walk_before := pose_signature(skeleton_a)
	first.sample(0.0, 0.16)
	var walk_after := pose_signature(skeleton_a)
	check(max_gap(walk_before, walk_after) > 0.01, "travel drives the walk pose")
	var held: float = first.travel
	first.sample(1.0 / 20.0, 0.0)
	check(is_equal_approx(first.travel, held), "idling does not change the travelled distance")
	for model in citizens:
		model.queue_free()
	await process_frame

	await check_crowd()
	await check_swap()
	finish()

func check_crowd() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/physician_crowd.json")) if FileAccess.file_exists("res://assets/models/physician_crowd.json") else null
	check(manifest is Dictionary and int(manifest.get("walk_samples", 0)) == 24, "crowd model manifest keeps the 24 walking samples")
	var vat := WalkerVat.new()
	check(not vat.runtime_path("physician_crowd").is_empty(), "crowd model has fresh baked poses (run tools/bake_walker_vat.py otherwise)")
	var crowd: Node3D = load("res://assets/models/physician_crowd.glb").instantiate()
	root.add_child(crowd)
	var skeletal: Node3D = load(SkeletalCitizen.MODEL).instantiate()
	root.add_child(skeletal)
	await process_frame
	var meshes: Array = []
	collect(crowd, meshes)
	var vertices := 0
	var colours := {}
	for instance in meshes:
		var arrays: Array = instance.mesh.surface_get_arrays(0)
		vertices += arrays[Mesh.ARRAY_VERTEX].size()
		var vertex_colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		for colour in vertex_colours:
			colours[colour.to_html()] = true
	check(vertices <= MAX_CROWD_VERTICES, "crowd model stays low-poly (%d vertices, <= %d)" % [vertices, MAX_CROWD_VERTICES])
	check(colours.size() > 50, "crowd model carries colours baked from the textures (%d distinct)" % colours.size())
	# Compare the idle pose tops: head bone of the skeletal citizen plus the head's rest offset to
	# the top of its hair, against the highest vertex of the crowd model's idle_00 shape.
	var skeleton: Skeleton3D = find_class_node(skeletal, "Skeleton3D")
	var player: AnimationPlayer = find_class_node(skeletal, "AnimationPlayer")
	var skeletal_meshes: Array = []
	collect(skeletal, skeletal_meshes)
	var rest_top := -1e9
	for instance in skeletal_meshes:
		rest_top = maxf(rest_top, instance.get_aabb().end.y)
	var head_rest := bone_height(skeleton, "head")
	player.play("Idle")
	player.pause()
	player.seek(0.0, true)
	var skeletal_top := bone_height(skeleton, "head") + rest_top - head_rest
	var crowd_top := -1e9
	for instance in meshes:
		var mesh: ArrayMesh = instance.mesh
		var blends := mesh.surface_get_blend_shape_arrays(0)
		for i in mesh.get_blend_shape_count():
			if "idle_00" in String(mesh.get_blend_shape_name(i)).split("|"):
				for point in blends[i][Mesh.ARRAY_VERTEX]:
					crowd_top = maxf(crowd_top, point.y)
	check(absf(crowd_top - skeletal_top) <= 0.02 * skeletal_top, "crowd and skeletal citizens stand equally tall (%.3f vs %.3f)" % [crowd_top, skeletal_top])
	crowd.queue_free()
	skeletal.queue_free()
	await process_frame

# A minimal stand-in for BuildingBatches: the swap manager only loads models through it.
class StubBatches:
	extends RefCounted
	var loads := 0
	func load_model(path: String) -> PackedScene:
		loads += 1
		return load(path)
	func prefetch_paths(_paths: Array) -> void:
		pass

func make_walker(position: Vector3, travel: float, idle: float, moving: bool) -> Dictionary:
	var node := Node3D.new()
	root.add_child(node)
	node.position = position
	return {"node": node, "lod_role": true, "skeletal": null, "moving": moving, "walk_weight":.35 if moving else 0.0, "travel": travel, "idle": idle, "morphs": []}

func skeletal_count(walkers: Dictionary) -> int:
	var count := 0
	for id in walkers:
		if walkers[id].skeletal != null:
			count += 1
	return count

func check_swap() -> void:
	var lod := CitizenLod.new()
	var batches := StubBatches.new()
	var models := {}
	check(lod.crowd_asset("physician") == "physician_crowd" and lod.crowd_asset("transporter") == "", "only the physician is substituted by the crowd model")
	var walkers := {}
	# One walker every 0.5 units along a line away from the camera at the origin.
	for i in 40:
		walkers[i + 1] = make_walker(Vector3(0.5 * (i + 1), 0, 0), 0.2 * i, 0.1 * i, i % 2 == 0)
	var camera := Vector3.ZERO
	lod.update(walkers, Vector3(1000, 1000, 1000), batches, models)
	check(lod.pool.is_empty() and lod.active.is_empty() and batches.loads == 0, "distant physicians do not load or instantiate unused detailed models")
	lod.update(walkers, camera, batches, models)
	var expected := mini(CitizenLod.MAX_SKELETAL, int(CitizenLod.NEAR / 0.5) - 1)
	check(skeletal_count(walkers) == expected, "the nearest %d walkers inside %.0f units become skeletal (%d)" % [expected, CitizenLod.NEAR, skeletal_count(walkers)])
	var nearest_first := true
	for id in walkers:
		var position: float = walkers[id].node.position.x
		if (walkers[id].skeletal != null) != (position < CitizenLod.NEAR):
			nearest_first = false
	check(nearest_first, "the swap selects walkers by distance, nearest first")
	var seen_state := true
	for id in lod.active:
		var entry: Dictionary = lod.active[id]
		var controller: Node = entry.skeletal.get_meta("skeletal_citizen")
		seen_state = seen_state and is_equal_approx(controller.travel, entry.travel) and is_equal_approx(controller.elapsed, entry.idle) and controller.walk_weight == entry.walk_weight
	check(seen_state, "a swapped citizen continues the crowd model's walk phase, idle clock and gait")
	# Hysteresis: a walker just past NEAR stays skeletal until FAR, then is released.
	var held_id := -1
	for id in lod.active:
		if held_id < 0 or walkers[id].node.position.x > walkers[held_id].node.position.x:
			held_id = id
	walkers[held_id].node.position.x = (CitizenLod.NEAR + CitizenLod.FAR) * 0.5
	lod.update(walkers, camera, batches, models)
	check(walkers[held_id].skeletal != null, "hysteresis keeps a walker skeletal between NEAR and FAR")
	walkers[held_id].node.position.x = CitizenLod.FAR + 1.0
	lod.update(walkers, camera, batches, models)
	check(walkers[held_id].skeletal == null and not lod.active.has(held_id), "a walker beyond FAR returns to the crowd model")
	check(lod.pool.size() >= 1 and lod.pool[-1].get_parent() == null, "a released citizen goes back to the pool unattached")
	# The cap holds when everybody is close.
	for id in walkers:
		walkers[id].node.position = Vector3(0.1 * id, 0, 0)
	lod.update(walkers, camera, batches, models)
	check(skeletal_count(walkers) == CitizenLod.MAX_SKELETAL and lod.active.size() == CitizenLod.MAX_SKELETAL, "the skeletal pool never exceeds %d" % CitizenLod.MAX_SKELETAL)
	var pooled_loads := batches.loads
	# Dropping a walker hands its model back before the node is freed; a later swap reuses pooled models.
	var victim_id := -1
	for id in lod.active:
		victim_id = id
		break
	var victim: Dictionary = walkers[victim_id]
	var citizen: Node3D = victim.skeletal
	lod.drop(victim)
	check(victim.skeletal == null and citizen.get_parent() == null and not lod.active.has(victim_id), "a removed walker releases its skeletal model")
	victim.node.queue_free()
	walkers.erase(victim_id)
	lod.update(walkers, camera, batches, models)
	var reused := false
	for id in lod.active:
		reused = reused or lod.active[id].skeletal == citizen
	check(skeletal_count(walkers) == CitizenLod.MAX_SKELETAL and reused and batches.loads == pooled_loads, "pooled skeletal models are reused instead of re-instantiated")
	# Far away, nobody is skeletal and every model is returned.
	for id in walkers:
		walkers[id].node.position = Vector3(200, 0, 0)
	lod.update(walkers, camera, batches, models)
	check(skeletal_count(walkers) == 0 and lod.active.is_empty(), "no skeletal citizens when the camera is far away")
	for id in walkers:
		walkers[id].node.free()
	for citizen_model in lod.pool:
		citizen_model.free()
	await process_frame

func finish() -> void:
	print("CITIZEN_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
