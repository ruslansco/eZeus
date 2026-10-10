extends "res://scripts/building_batches.gd"
# Frozen first-pass refresh methods for an owned before/after benchmark only.
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

