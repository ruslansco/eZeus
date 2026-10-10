extends Node3D
# Original wheat overlays for the existing villa's five field tiles. Native growth
# arrives separately from architecture; GPU instance data changes without a rebuild.
const SHADER := preload("res://shaders/farm_wheat.gdshader")
const FIELDS := [Vector3(1,0,-1),Vector3(1,0,0),Vector3(1,0,1),Vector3(0,0,1),Vector3(-1,0,1)]
const CELL_SIZE := 16
var mesh: ArrayMesh
var material: ShaderMaterial
var nodes := {}
var signatures := {}
var data := {}
var last_rebuilt := 0
var last_updates := 0

func triangle(arrays: Array, a: Vector3, b: Vector3, c: Vector3, part: float, anchor: Vector3, tint: Color) -> void:
	var normal := (b-a).cross(c-a).normalized()
	for point in [a,b,c]:
		arrays[Mesh.ARRAY_VERTEX].append(point)
		arrays[Mesh.ARRAY_NORMAL].append(normal)
		arrays[Mesh.ARRAY_TEX_UV].append(Vector2(part,anchor.y))
		arrays[Mesh.ARRAY_TEX_UV2].append(Vector2(anchor.x,anchor.z))
		arrays[Mesh.ARRAY_COLOR].append(tint)

func blade(arrays: Array, base: Vector3, top: Vector3, width: float, direction: Vector3, part: float, tint: Color) -> void:
	var side := direction*width
	triangle(arrays,base-side,base+side,top+side,part,base,tint)
	triangle(arrays,base-side,top+side,top-side,part,base,tint)

func wheat_mesh() -> ArrayMesh:
	if mesh != null: return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array()
	var middle := PackedInt32Array()
	var distant := PackedInt32Array()
	# Local deterministic art noise; never simulation RNG or global randf().
	var rng := RandomNumberGenerator.new()
	rng.seed = 3109
	for row in 5:
		for plant in 10:
			var start: int = arrays[Mesh.ARRAY_VERTEX].size()
			for stem in 2:
				var base := Vector3(-.40+plant*.8/9+rng.randf_range(-.015,.015),0,-.4+row*.2+rng.randf_range(-.015,.015))
				var height := rng.randf_range(.48,.57)
				var top := base+Vector3(rng.randf_range(-.025,.025),height,rng.randf_range(-.025,.025))
				var tint := Color(rng.randf_range(.86,1.12),rng.randf_range(.90,1.06),1)
				blade(arrays,base,top,.009,Vector3.RIGHT,0,tint)
				blade(arrays,base,top,.009,Vector3.FORWARD,0,tint)
				for sign_value in [-1,1]:
					var root_point := base.lerp(top,.32 if sign_value==1 else .58)
					var tip := root_point+Vector3(sign_value*.07,.075,sign_value*.035)
					triangle(arrays,root_point,root_point+Vector3(.008,.028,.018),tip,0,root_point,tint)
					triangle(arrays,root_point,tip,root_point+Vector3(-.008,.028,-.018),0,root_point,tint)
				# Crossed tapered grain heads, then two fine awns at the tip.
				for side in [Vector3.RIGHT,Vector3.FORWARD]:
					var waist := top+Vector3.UP*.045
					var ear_tip := top+Vector3.UP*.105
					triangle(arrays,top,waist-side*.022,ear_tip,1,top,tint)
					triangle(arrays,top,ear_tip,waist+side*.022,1,top,tint)
					triangle(arrays,ear_tip-side*.003,ear_tip+side*.003,ear_tip+Vector3.UP*.035+side*.012,1,top,tint)
			var end: int = arrays[Mesh.ARRAY_VERTEX].size()
			if plant%2==0:
				for i in range(start,end): middle.append(i)
			if plant%4==0 and row%2==0:
				for i in range(start,end): distant.append(i)
	var indices := PackedInt32Array()
	for i in arrays[Mesh.ARRAY_VERTEX].size(): indices.append(i)
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{7.0:middle,18.0:distant})
	return mesh

func refresh(observations: Array, city: Node) -> void:
	var groups := {}
	for crop in observations:
		if crop.get("crop","") != "wheat": continue
		var building: Dictionary = city.building_index.get(int(crop.id),{})
		if building.is_empty() or not city.overlay_view.building_visible(building): continue
		var transform: Transform3D = city.building_draw_transform(building)
		var key := "%d:%d" % [floori(float(building.x)/CELL_SIZE),floori(float(building.y)/CELL_SIZE)]
		if not groups.has(key): groups[key] = []
		for field in clampi(int(crop.get("fields",0)),0,5):
			# Blender +Y maps to Godot -Z. Match the base GLB's front L exactly.
			var offset: Vector3 = FIELDS[field]
			offset.z = -offset.z
			offset.y = .028
			var local := Transform3D(Basis.IDENTITY,offset)
			groups[key].append({"id":int(crop.id),"field":field,"transform":transform*local,"progress":clampf(float(crop.progress),0,1)})
	refresh_groups(groups)

func refresh_groups(groups: Dictionary) -> void:
	last_rebuilt = 0
	last_updates = 0
	for key in nodes.keys():
		if not groups.has(key):
			nodes[key].free()
			nodes.erase(key); signatures.erase(key); data.erase(key)
	for key in groups:
		var placements: Array = groups[key]
		var layout := placements.map(func(item): return [item.id,item.field,item.transform])
		if signatures.get(key,[]) != layout:
			if not nodes.has(key):
				var node := MultiMeshInstance3D.new()
				var batch := MultiMesh.new()
				batch.transform_format = MultiMesh.TRANSFORM_3D
				batch.use_custom_data = true
				batch.mesh = wheat_mesh()
				node.multimesh = batch
				if material == null:
					material = ShaderMaterial.new(); material.shader = SHADER
				node.material_override = material
				node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				node.extra_cull_margin = .12
				node.visibility_range_end = 110
				add_child(node)
				nodes[key] = node
			var batch: MultiMesh = nodes[key].multimesh
			batch.instance_count = placements.size()
			for i in placements.size(): batch.set_instance_transform(i,placements[i].transform)
			signatures[key] = layout
			data.erase(key)
			last_rebuilt += 1
		var next := PackedColorArray()
		for item in placements: next.append(Color(item.progress,fmod(item.id*.173+item.field*.217,1.0),0,0))
		var previous: PackedColorArray = data.get(key,PackedColorArray())
		for i in next.size():
			if previous.size()==next.size() and previous[i]==next[i]: continue
			nodes[key].multimesh.set_instance_custom_data(i,next[i])
			last_updates += 1
		data[key] = next
