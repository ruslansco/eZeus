extends "res://scripts/terrain_details.gd"
# Existing native water roads are bridges, never newly inferred crossings.
const DECK := .14
const HALF_WIDTH := .34

func _init() -> void:
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = .88
	materials.bridge = stone
	materials.approach = stone

func is_bridge(cell: Vector2i) -> bool:
	var tile: Array = tiles.get(cell,[])
	return not tile.is_empty() and bool(int(tile[3]) & 4) and bool(int(tile[4]))

func axis(cell: Vector2i) -> int:
	var along_x := 0
	var along_y := 0
	for delta in OFFSETS:
		var neighbor: Array = tiles.get(cell+delta,[])
		if not neighbor.is_empty() and int(neighbor[4]):
			if delta.x:
				along_x += 1
			else:
				along_y += 1
	return 0 if along_x >= along_y else 1

func approach(cell: Vector2i) -> Vector2i:
	var tile: Array = tiles.get(cell,[])
	if tile.is_empty() or int(tile[3]) & 4 or not int(tile[4]):
		return Vector2i.ZERO
	for delta in OFFSETS:
		if is_bridge(cell+delta) and tiles[cell+delta][2] == tile[2] and (bool(delta.x) == (axis(cell+delta) == 0)):
			return delta
	return Vector2i.ZERO

func layout(cell: Vector2i) -> Array:
	var ramp := approach(cell)
	if not is_bridge(cell) and ramp == Vector2i.ZERO:
		return []
	var position: Vector3 = geometry.world(cell.x,cell.y,float(tiles[cell][2])*.22)
	var yaw := PI*.5*axis(cell) if is_bridge(cell) else atan2(float(ramp.y),float(ramp.x))
	return [{"cell":cell,"kind":"bridge" if is_bridge(cell) else "approach","variant":0,"transform":Transform3D(Basis(Vector3.UP,yaw),position),"seed":0.0}]

func height_at(x: float, y: float) -> float:
	var cell := Vector2i(roundi(x),roundi(y))
	if not is_bridge(cell):
		var ramp := approach(cell)
		var across := absf(y-cell.y) if ramp.x else absf(x-cell.x)
		if ramp != Vector2i.ZERO and across <= HALF_WIDTH:
			return geometry.height_at(x,y)+clampf((x-cell.x)*ramp.x+(y-cell.y)*ramp.y+.5,0,1)*DECK
		return geometry.height_at(x,y)
	var across := absf(y-cell.y) if axis(cell) == 0 else absf(x-cell.x)
	return float(tiles[cell][2])*.22+DECK if across <= HALF_WIDTH else geometry.height_at(x,y)

func box(surface: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var p: Array[Vector3] = []
	for y in [-1,1]:
		for z in [-1,1]:
			for x in [-1,1]:
				p.append(center+Vector3(x,y,z)*size*.5)
	for indices in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
		face(surface,p[indices[0]],p[indices[2]],p[indices[1]],color)
		face(surface,p[indices[0]],p[indices[3]],p[indices[2]],color)

func mesh_for(kind: String, _variant: int) -> ArrayMesh:
	if meshes.has(kind):
		return meshes[kind]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "approach":
		var a := Vector3(-.5,0,-HALF_WIDTH)
		var b := Vector3(.5,DECK,-HALF_WIDTH)
		var c := Vector3(.5,DECK,HALF_WIDTH)
		var d := Vector3(-.5,0,HALF_WIDTH)
		face(surface,a,b,c,Color(.53,.49,.39))
		face(surface,a,c,d,Color(.53,.49,.39))
		face(surface,a,Vector3(.5,0,-HALF_WIDTH),b,Color(.47,.44,.36))
		face(surface,d,c,Vector3(.5,0,HALF_WIDTH),Color(.47,.44,.36))
		meshes[kind] = surface.commit()
		return meshes[kind]
	# Warm stone foundations, timber deck, open rails and cross-water supports.
	box(surface,Vector3(0,.025,0),Vector3(1,.12,.70),Color(.53,.49,.39))
	for index in range(7):
		box(surface,Vector3(-.43+index*.143,DECK-.022,0),Vector3(.139,.044,.68),Color(.43+.012*(index%3),.33,.21))
	for sign in [-1,1]:
		box(surface,Vector3(0,DECK+.25,sign*.315),Vector3(1,.045,.045),Color(.37,.28,.18))
		box(surface,Vector3(0,DECK+.12,sign*.315),Vector3(1,.035,.035),Color(.40,.31,.20))
		box(surface,Vector3(-.46,DECK+.13,sign*.315),Vector3(.055,.30,.055),Color(.38,.29,.19))
	box(surface,Vector3(-.46,-.20,0),Vector3(.15,.45,.49),Color(.47,.44,.36))
	var mesh := surface.commit()
	meshes[kind] = mesh
	return mesh

func rebuild(key: Vector2i) -> void:
	super.rebuild(key)
	var faces := PackedVector3Array()
	for item in records[key]:
		var start_height := DECK if item.kind == "bridge" else 0.0
		var a: Vector3 = item.transform*Vector3(-.5,start_height,-HALF_WIDTH)
		var b: Vector3 = item.transform*Vector3(.5,DECK,-HALF_WIDTH)
		var c: Vector3 = item.transform*Vector3(.5,DECK,HALF_WIDTH)
		var d: Vector3 = item.transform*Vector3(-.5,start_height,HALF_WIDTH)
		faces.append_array(PackedVector3Array([a,b,c,a,c,d]))
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.add_child(collision)
	sections[key].add_child(body)

func summary() -> Dictionary:
	var result := super.summary()
	result.batches = 0
	for node in sections.values():
		for child in node.get_children():
			if child is MultiMeshInstance3D:
				result.batches += 1
	return result
