extends "res://scripts/terrain_details.gd"
# Independent presentation trees; the native forest flag remains authoritative.

func _init() -> void:
	var foliage := ShaderMaterial.new()
	foliage.shader = preload("res://shaders/tree.gdshader")
	foliage.set_shader_parameter("surface_noise",preload("res://assets/terrain/surface_noise.tres"))
	materials.olive = foliage
	materials.cypress = foliage

func layout(cell: Vector2i) -> Array:
	var tile: Array = tiles.get(cell,[])
	if not free_ground(tile) or not (int(tile[3]) & 16):
		return []
	var kind := "cypress" if sample(cell,51) < .27 else "olive"
	var offset := Vector2(sample(cell,52)-.5,sample(cell,53)-.5)*.10
	var width := .86+sample(cell,54)*.14
	var height := .85+sample(cell,55)*.30
	return [placement(cell,kind,56,offset,Vector3(width,height,width))]

func branch(surface: SurfaceTool, start: Vector3, end: Vector3, radius: float, taper: float) -> void:
	var axis := (end-start).normalized()
	var across := axis.cross(Vector3.FORWARD).normalized()
	if across.length_squared() < .1:
		across = Vector3.RIGHT
	var perpendicular := axis.cross(across).normalized()
	for index in range(6):
		var a := TAU*index/6.0
		var b := TAU*(index+1)/6.0
		var u := across*cos(a)+perpendicular*sin(a)
		var v := across*cos(b)+perpendicular*sin(b)
		var color := Color(.32,.29,.23,0)
		face(surface,start+u*radius,end+v*radius*taper,start+v*radius,color)
		face(surface,start+u*radius,end+u*radius*taper,end+v*radius*taper,color)

func leaf(surface: SurfaceTool, center: Vector3, angle: float, length: float, color: Color) -> void:
	var along := Vector3(cos(angle),.2*sin(angle*2.7),sin(angle)).normalized()*length
	var across := Vector3(-sin(angle),.25,cos(angle)).normalized()*length*.28
	var ridge := center+Vector3.UP*length*.10
	face(surface,center-along,center-across,ridge,color*.94)
	face(surface,center-across,center+along,ridge,color)
	face(surface,center+along,center+across,ridge,color*1.06)
	face(surface,center+across,center-along,ridge,color)

func crown(surface: SurfaceTool, center: Vector3, radii: Vector3, seed: int, detailed: bool, color: Color) -> void:
	# Small lobes form airy, asymmetric crowns; leaf blades break up their silhouette.
	var sectors := 8 if detailed else 6
	var rings := 5 if detailed else 3
	for layer in range(rings):
		var p := PI*layer/rings
		var q := PI*(layer+1)/rings
		for index in range(sectors):
			var a := TAU*index/sectors
			var b := TAU*(index+1)/sectors
			var points: Array[Vector3] = []
			for uv in [Vector2(p,a),Vector2(p,b),Vector2(q,b),Vector2(q,a)]:
				var radius := 1.0+.12*sin(uv.y*3+seed+uv.x*4)
				points.append(center+Vector3(sin(uv.x)*cos(uv.y),cos(uv.x),sin(uv.x)*sin(uv.y))*radii*radius)
			var tint := color*(.90+.10*sin(index*2.1+layer+seed))
			# Explicit ellipsoid normals avoid the old flat polygon canopy shading.
			for indices in [[0,2,1],[0,3,2]]:
				for i in indices:
					var point: Vector3 = points[i]
					var delta := (point-center)/radii
					surface.set_normal((delta/radii).normalized())
					surface.set_color(Color(tint.r,tint.g,tint.b,.5+clampf(point.y/2.0,0,.45)))
					surface.add_vertex(point)
	if detailed:
		for index in range(30):
			var a := index*2.39996+seed
			var y := .88-float(index)/29.0*1.76
			var radial := sqrt(1-y*y)
			var point := center+Vector3(cos(a)*radial,y,sin(a)*radial)*radii*1.02
			leaf(surface,point,a,.035 if radii.y < .2 else .045,Color(color.r*.93,color.g*1.04,color.b*1.04,.9))

func tree_surface(kind: String, variant: int, detailed: bool) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "olive":
		var knee := Vector3(-.03+variant*.045,.24,.035)
		var fork := Vector3(.025*variant,.48,.025)
		branch(surface,Vector3.ZERO,knee,.055,.82)
		branch(surface,knee,fork,.045,.65)
		for index in range(5):
			var a := index*2.4+variant*.8
			var center := Vector3(cos(a)*(.17+.02*(index%2)),.94+.14*(index%3),sin(a)*.18)
			branch(surface,fork,center,.024,.30)
			var color := Color(.34+.015*(index%3),.40+.01*(index%2),.25,.8)
			crown(surface,center,Vector3(.19,.17+.02*(index%2),.18),index+variant*7,detailed,color)
			if detailed:
				branch(surface,center-Vector3(0,.08,0),center+Vector3(cos(a)*.12,.04,sin(a)*.12),.009,.2)
	else:
		branch(surface,Vector3.ZERO,Vector3(.015*variant,1.65,0),.035,.15)
		for index in range(6):
			var a := index*2.4+variant
			var width := .18*(1-float(index)/7.5)
			var center := Vector3(cos(a)*.022,.40+index*.245,sin(a)*.024)
			crown(surface,center,Vector3(width,.27,width),index+variant*6,detailed,Color(.19,.32,.23,.8))
	return surface.commit()

func mesh_for(kind: String, variant: int) -> ArrayMesh:
	var key := "%s:%d" % [kind,variant]
	if meshes.has(key):
		return meshes[key]
	var near := tree_surface(kind,variant,true).surface_get_arrays(0)
	var far := tree_surface(kind,variant,false).surface_get_arrays(0)
	var near_count: int = near[Mesh.ARRAY_VERTEX].size()
	var far_count: int = far[Mesh.ARRAY_VERTEX].size()
	for channel in range(Mesh.ARRAY_MAX):
		if channel == Mesh.ARRAY_INDEX or near[channel] == null:
			continue
		var combined = near[channel]
		combined.append_array(far[channel])
		near[channel] = combined
	var vertices: PackedVector3Array = near[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()):
		var radial := Vector2(vertices[index].x,vertices[index].z)
		if radial.length() > .412:
			radial = radial.normalized()*.412
			vertices[index].x = radial.x
			vertices[index].z = radial.y
	near[Mesh.ARRAY_VERTEX] = vertices
	var indices := PackedInt32Array()
	var reduced := PackedInt32Array()
	for index in range(near_count):
		indices.append(index)
	for index in range(far_count):
		reduced.append(near_count+index)
	near[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	# Godot selects the reduced index set by projected geometric error, including MultiMesh.
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,near,[],{.025:reduced})
	mesh.custom_aabb = mesh.get_aabb().grow(.025)
	meshes[key] = mesh
	return mesh
