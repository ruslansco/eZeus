extends Node3D
# One draw per imported geometry/material batch, shared by all repeated buildings.
var templates: Dictionary = {}
# Group key -> hash of its placements and the MultiMesh nodes built for it. A rebuild
# only touches groups whose placements changed, so one new house re-uploads one batch
# instead of every building in the city.
var group_signatures: Dictionary = {}
var group_nodes: Dictionary = {}
var last_rebuilt := 0
# Model paths with a threaded load in flight (see prefetch).
var requested: Dictionary = {}
var activity := preload("res://scripts/building_activity.gd").new()

func collect(node: Node3D, parent: Transform3D, result: Array) -> void:
	var transform := parent * node.transform
	if node is MeshInstance3D and node.mesh != null:
		result.append({"mesh": node.mesh, "transform": transform, "material": node.material_override, "activity":node.has_meta("building_activity")})
	for child in node.get_children():
		if child is Node3D:
			collect(child, transform, result)

# Starts loading GLBs on worker threads so city load overlaps model reads with terrain
# building instead of paying for them one after another. Safe to call repeatedly.
func prefetch(assets: Array) -> void:
	var paths: Array = []
	for asset in assets:
		if not templates.has(asset):
			paths.append(activity.model_path(asset))
	prefetch_paths(paths)

func prefetch_paths(paths: Array) -> void:
	for path in paths:
		if requested.has(path) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			requested[path] = true

# Returns the loaded GLB, joining a threaded load when one was requested.
func load_model(path: String) -> Resource:
	if requested.erase(path):
		return ResourceLoader.load_threaded_get(path)
	return load(path)

func template(asset: String) -> Array:
	if templates.has(asset):
		return templates[asset]
	var pieces: Array = []
	if asset == "__footprint":
		var mesh := BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(.36, .42, .44)
		material.roughness = .9
		mesh.material = material
		pieces.append({"mesh": mesh, "transform": Transform3D.IDENTITY, "material": null})
	else:
		var path := activity.model_path(asset)
		if ResourceLoader.exists(path):
			var source: Node3D = load_model(path).instantiate()
			activity.apply(source,asset)
			collect(source, Transform3D.IDENTITY, pieces)
			source.free()
	templates[asset] = pieces
	return pieces

func rebuild(groups: Dictionary) -> void:
	last_rebuilt = 0
	for key in group_nodes.keys():
		if not groups.has(key) or groups[key].is_empty():
			drop(key)
	for key in groups:
		var placements: Array = groups[key]
		if placements.is_empty():
			continue
		var transforms: Array = []
		for placement in placements:
			transforms.append(placement.transform if placement is Dictionary else placement)
		var signature := transforms.hash()
		if group_signatures.get(key, 0) == signature and group_nodes.has(key):
			update_activity(group_nodes[key],placements)
			continue
		drop(key)
		var nodes: Array = []
		for piece in template(str(key).get_slice("|", 0)):
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.use_custom_data = bool(piece.get("activity",false))
			batch.mesh = piece.mesh
			batch.instance_count = placements.size()
			for index in range(placements.size()):
				batch.set_instance_transform(index, transforms[index] * piece.transform)
			var node := MultiMeshInstance3D.new()
			node.multimesh = batch
			node.material_override = piece.material
			add_child(node)
			nodes.append(node)
		group_signatures[key] = signature
		group_nodes[key] = nodes
		update_activity(nodes,placements)
		last_rebuilt += 1

func update_activity(nodes: Array, placements: Array) -> void:
	for node in nodes:
		var batch: MultiMesh = node.multimesh
		if not batch.use_custom_data:continue
		for i in placements.size():
			var placement = placements[i]
			var data := Color(0,0,0,0)
			if placement is Dictionary:
				data = Color(1.0 if placement.get("working",false) else 0.0,float(placement.get("animation_offset",0)),0,0)
			batch.set_instance_custom_data(i,data)
		# Workers/tools can move beyond their rest bounds; don't cull their swings.
		node.extra_cull_margin = .5

func drop(key) -> void:
	for node in group_nodes.get(key, []):
		node.free()
	group_nodes.erase(key)
	group_signatures.erase(key)
