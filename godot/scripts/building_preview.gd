extends RefCounted
# Catalog pictures are presentation only. Composite buildings use the native placement
# layout on a flat display surface, without placing anything or changing the city.
const StreetAvenues = preload("res://scripts/terrain_avenues.gd")
const StreetGeometry = preload("res://scripts/terrain_geometry.gd")

static func composite(tool: String) -> bool:
	return tool in ["palace", "horse_ranch"] or tool.begins_with("temple_") or tool.begins_with("pyramid_") or tool.begins_with("shrine_") or tool.begins_with("god_monument_")

static func create(item: Dictionary, factory: Callable, fit: Callable, layout: Callable, pyramid_rise: float) -> Node3D:
	var tool: String = str(item.name).get_slice(":", 0)
	if tool in ["avenue","boulevard"]: return street(tool=="boulevard")
	if tool in ["common_agora", "grand_agora"]:
		return agora(tool == "grand_agora")
	if not composite(tool):
		return factory.call(str(item.asset))
	var plan: Dictionary = layout.call(tool)
	if plan.get("pieces", []).is_empty():
		return null
	var display := Node3D.new()
	var center := Vector2(float(plan.x) + (float(plan.w) - 1) * .5, float(plan.y) + (float(plan.h) - 1) * .5)
	for piece in plan.pieces:
		var asset := str(piece.asset)
		var model: Node3D = factory.call(asset)
		if model == null:
			# Never cache a misleading, partially assembled building.
			display.free()
			return null
		var basis: Basis = fit.call(asset, float(piece.w), float(piece.h), int(piece.get("orientation", 0)))
		if asset.begins_with("pyramid_"):
			# Sprite TR/BR normals (-Blender X/+Blender Y) map to native -Y/+X.
			# Align baked face directions with the city's world -Z tile-Y axis.
			model = reflected_model(model)
			basis *= Basis(Vector3.UP, PI / 2) * Basis.from_scale(Vector3(1, pyramid_rise, 1))
		var position := Vector3(float(piece.x) + (float(piece.w) - 1) * .5 - center.x, float(piece.get("lift", 0)) * .22, -(float(piece.y) + (float(piece.h) - 1) * .5 - center.y))
		# Keep the imported root transform inside the native piece's holder.
		var holder := Node3D.new()
		holder.transform = Transform3D(basis, position)
		holder.add_child(model)
		display.add_child(holder)
	return display

static func street(boulevard: bool) -> Node3D:
	# A static catalog render of the same furniture/topology as the city. The
	# miniature has no physics, native placement authority or active viewport.
	var display := Node3D.new()
	var tiles := {}; var changed: Array[Vector2i] = []
	for x in range(-4,5):
		for y in range(-3,4):
			var road: bool = abs(x)<=3 and (y==0 or y==1 or (boulevard and y==-1))
			var kind := (3 if boulevard else 2) if road and y==0 else (1 if road else 0)
			var cell := Vector2i(x,y); changed.append(cell)
			tiles[cell] = [x,y,0,1,1 if road else 0,1,0,0,kind]
	var surface := StreetGeometry.new(); surface.update(tiles,Vector2i(-4,-3),Vector2i(9,7),changed)
	var decorations := StreetAvenues.new(); display.add_child(decorations)
	decorations.update(tiles,Vector2i(-4,-3),Vector2i(9,7),surface,changed)
	var stone := StandardMaterial3D.new(); stone.albedo_color=Color(.72,.69,.60); stone.roughness=.8
	var border := StandardMaterial3D.new(); border.albedo_color=Color(.26,.34,.35); border.roughness=.65
	for cell in tiles:
		if not int(tiles[cell][4]): continue
		var slab := MeshInstance3D.new(); var mesh := BoxMesh.new()
		mesh.size=Vector3(.985,.04,.985); slab.mesh=mesh; slab.material_override=stone
		slab.position=Vector3(cell.x,-.015,-cell.y); display.add_child(slab)
	for z in [-.5,.5] if boulevard else [-.5]:
		var stripe := MeshInstance3D.new(); var mesh := BoxMesh.new()
		mesh.size=Vector3(6.95,.003,.04); stripe.mesh=mesh; stripe.material_override=border
		stripe.position=Vector3(0,.007,z); display.add_child(stripe)
	return display

static func reflected_model(model: Node3D) -> Node3D:
	# Bake the display-only reflection into copied geometry and reverse its winding.
	# A negative Node scale reverses the two-sided GLB's lit normals in Godot.
	# Original meshes, UVs, finishes and city instances remain untouched.
	var display := Node3D.new()
	reflect_geometry(model, Transform3D.IDENTITY, display)
	model.free()
	return display

static func reflect_geometry(node: Node3D, parent: Transform3D, display: Node3D) -> void:
	var local := parent * node.transform
	if node is MeshInstance3D and node.mesh != null:
		var transform := Transform3D(Basis.from_scale(Vector3(1, 1, -1)), Vector3.ZERO) * local
		var normal_basis := transform.basis.inverse().transposed()
		var mesh := ArrayMesh.new()
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for i in vertices.size(): vertices[i] = transform * vertices[i]
			arrays[Mesh.ARRAY_VERTEX] = vertices
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i in normals.size(): normals[i] = (normal_basis * normals[i]).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals
			if arrays[Mesh.ARRAY_TANGENT] != null:
				var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				for i in range(0, tangents.size(), 4):
					var tangent := (transform.basis * Vector3(tangents[i], tangents[i+1], tangents[i+2])).normalized()
					tangents[i] = tangent.x; tangents[i+1] = tangent.y; tangents[i+2] = tangent.z
					tangents[i+3] *= -1
				arrays[Mesh.ARRAY_TANGENT] = tangents
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for i in vertices.size(): indices.append(i)
			for i in range(0, indices.size(), 3):
				var swap := indices[i+1]; indices[i+1] = indices[i+2]; indices[i+2] = swap
			arrays[Mesh.ARRAY_INDEX] = indices
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(surface, node.get_active_material(surface))
		var part := MeshInstance3D.new()
		part.mesh = mesh
		display.add_child(part)
	for child in node.get_children():
		if child is Node3D: reflect_geometry(child, local, display)

static func slab(display: Node3D, size: Vector3, position: Vector3, finish: Material) -> void:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	node.mesh = box
	node.material_override = finish
	node.position = position
	display.add_child(node)

static func agora(grand: bool) -> Node3D:
	# Newly founded agoras are empty 2x2 paved vendor plots: three beside a six-tile
	# street, or six on both sides. Do not imply that vendors are included in the cost.
	# The paving dimensions and finish match main.gd::add_plaza.
	var display := Node3D.new()
	var paving := StandardMaterial3D.new()
	paving.albedo_color = Color(.80, .72, .56)
	paving.roughness = .95
	var street := StandardMaterial3D.new()
	street.albedo_color = Color(.56, .50, .39)
	street.roughness = .95
	var road_z := 0.0 if grand else 1.0
	for x in 6:
		slab(display, Vector3(.98, .04, .98), Vector3(x - 2.5, .02, road_z), street)
	for z in [-1.5, 1.5] if grand else [-.5]:
		for x in [-2.0, 0.0, 2.0]:
			slab(display, Vector3(1.94, .06, 1.94), Vector3(x, .03, z), paving)
	display.set_meta("vendor_spaces", 6 if grand else 3)
	return display
