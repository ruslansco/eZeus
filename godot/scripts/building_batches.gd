extends Node3D
# One draw per imported geometry/material batch, shared by all repeated buildings.
var templates: Dictionary = {}
# Group key -> hash of its placements and the MultiMesh nodes built for it. A rebuild
# only touches groups whose placements changed, so one new house re-uploads one batch
# instead of every building in the city.
var group_signatures: Dictionary = {}
var group_nodes: Dictionary = {}
var last_rebuilt := 0
var last_activity_updates := 0
# Model path -> WorkerThreadPool task warming its imported file (see prefetch).
var requested: Dictionary = {}
var activity := preload("res://scripts/building_activity.gd").new()
var finish := preload("res://scripts/building_finish.gd").new()
var construction := preload("res://scripts/building_construction.gd").new()

func collect(node: Node3D, parent: Transform3D, result: Array) -> void:
	var transform := parent * node.transform
	if node is MeshInstance3D and node.mesh != null:
		result.append({"mesh": node.mesh, "transform": transform, "material": node.material_override, "activity":node.has_meta("building_activity"),"construction":node.has_meta("construction_reveal")})
	for child in node.get_children():
		if child is Node3D:
			collect(child, transform, result)

# Loads GLBs on worker threads in parallel, then waits for them all before returning (join), so
# no worker builds meshes or materials while the main thread renders or builds terrain: Godot's
# BaseMaterial3D races the renderer when a loading thread sets up a material during a frame
# (crashes in material_set_shader). Every load is collected straight away into `loaded`, which
# this node releases when it leaves the tree, before the renderer shuts down; a ResourceLoader
# load left uncollected would keep its materials until engine exit (a crash in BaseMaterial3D's
# destructor or an endless "Parameter material is null" flood). Safe to call repeatedly.
var loaded: Dictionary = {}
var ever_requested: Dictionary = {}

func prefetch(assets: Array) -> void:
	var paths: Array = []
	for asset in assets:
		if not templates.has(asset):
			paths.append(activity.model_path(asset))
	prefetch_paths(paths)

func prefetch_paths(paths: Array) -> void:
	for path in paths:
		if requested.has(path) or loaded.has(path) or not ResourceLoader.exists(path):
			continue
		# The dummy renderer's resource IDs are not safe to initialize from
		# parallel GLB loaders. Headless CI/probes have no display to accelerate.
		if DisplayServer.get_name()=="headless":
			loaded[path]=load(path)
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			requested[path] = true
			ever_requested[path] = true
	join()

# Waits for every load in flight and keeps the results (the main thread does nothing else meanwhile).
func join() -> void:
	for path in requested:
		var resource := ResourceLoader.load_threaded_get(path)
		if resource != null:
			loaded[path] = resource
	requested.clear()

# True when the model is ready to instantiate without waiting.
func warmed(path: String) -> bool:
	return not requested.has(path)

# Returns the loaded GLB from the parallel load when there was one.
func load_model(path: String) -> Resource:
	if requested.has(path):
		join()
	if loaded.has(path):
		return loaded[path]
	return load(path)

# Models loaded ahead are released with the node, before the renderer goes.
func _exit_tree() -> void:
	join()
	loaded.clear()
	# Diagnostic: any path the loader still tracks as a threaded load would outlive the renderer.
	var left := ever_requested.keys().filter(func(p): return ResourceLoader.load_threaded_get_status(p) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)
	print("BATCH_LOADS_LEFT ", left.size(), " ", left.slice(0, 5))

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
			construction.apply(source,asset)
			finish.apply(source,asset)
			collect(source, Transform3D.IDENTITY, pieces)
			source.free()
	templates[asset] = pieces
	return pieces

func rebuild(groups: Dictionary) -> void:
	last_rebuilt = 0
	last_activity_updates = 0
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
		# A group keeps the same imported template. Reuse its GPU objects when goods
		# move or its instance count changes instead of destroying/recreating them.
		var nodes: Array = group_nodes.get(key, [])
		var pieces: Array = template(str(key).get_slice("|", 0))
		for p in pieces.size():
			var piece: Dictionary = pieces[p]
			var node: MultiMeshInstance3D
			if p < nodes.size():
				node = nodes[p]
			else:
				node = MultiMeshInstance3D.new()
				var fresh := MultiMesh.new()
				fresh.transform_format = MultiMesh.TRANSFORM_3D
				fresh.use_custom_data = bool(piece.get("activity", false)) or bool(piece.get("construction",false))
				fresh.mesh = piece.mesh
				node.multimesh = fresh
				node.material_override = piece.material
				if fresh.use_custom_data: node.extra_cull_margin = .5
				add_child(node)
				nodes.append(node)
			var batch: MultiMesh = node.multimesh
			if batch.instance_count != placements.size():
				batch.instance_count = placements.size()
				node.remove_meta("activity_data")
			for index in range(placements.size()):
				batch.set_instance_transform(index, transforms[index] * piece.transform)
		group_signatures[key] = signature
		group_nodes[key] = nodes
		update_activity(nodes,placements)
		last_rebuilt += 1

func update_activity(nodes: Array, placements: Array) -> void:
	var data := PackedColorArray()
	for node in nodes:
		var batch: MultiMesh = node.multimesh
		if not batch.use_custom_data:continue
		if data.is_empty():
			for placement in placements:
				data.append(Color(1.0 if placement.get("working",false) else 0.0,float(placement.get("animation_offset",0)),1.0 if placement.get("constructing",false) else 0.0,float(placement.get("construction_top",0))) if placement is Dictionary else Color(0,0,0,0))
		var previous: PackedColorArray = node.get_meta("activity_data", PackedColorArray())
		if previous == data: continue
		for i in data.size():
			if previous.size() == data.size() and previous[i] == data[i]: continue
			batch.set_instance_custom_data(i,data[i])
			last_activity_updates += 1
		node.set_meta("activity_data", data)

func drop(key) -> void:
	for node in group_nodes.get(key, []):
		node.free()
	group_nodes.erase(key)
	group_signatures.erase(key)
