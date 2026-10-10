extends RefCounted
# Original, cached marble/bronze street sculpture. Vertex-colour meshes share
# one material and a reduced index LOD; no per-frame mesh generation or RNG.
const MARBLE := Color(.83, .85, .81)
const PALE := Color(.93, .92, .86)
const BLUE := Color(.13, .24, .29)
const BRONZE := Color(.36, .27, .13)
const LEAF := Color(.26, .37, .20)

static func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, colour: Color) -> void:
	var normal := (b-a).cross(c-a).normalized()
	for p in [a, c, b]:
		st.set_normal(normal); st.set_color(colour); st.add_vertex(p)

static func box(st: SurfaceTool, p: Vector3, size: Vector3, colour: Color) -> void:
	var v: Array[Vector3] = []
	for y in [-1, 1]:
		for z in [-1, 1]:
			for x in [-1, 1]: v.append(p + Vector3(x, y, z) * size * .5)
	for q in [[0,1,3,2], [4,6,7,5], [0,4,5,1], [2,3,7,6], [0,2,6,4], [1,5,7,3]]:
		triangle(st, v[q[0]], v[q[1]], v[q[2]], colour)
		triangle(st, v[q[0]], v[q[2]], v[q[3]], colour)

static func sphere(st: SurfaceTool, p: Vector3, size: Vector3, colour: Color, detail: bool) -> void:
	var rings := 8 if detail else 4
	var sectors := 16 if detail else 8
	for j in rings:
		for i in sectors:
			var v: Array[Vector3] = []
			for uv in [Vector2(j,i),Vector2(j+1,i),Vector2(j+1,i+1),Vector2(j,i+1)]:
				var a: float = uv.x * PI / rings; var b: float = uv.y * TAU / sectors
				v.append(p + Vector3(sin(a)*cos(b),cos(a),sin(a)*sin(b)) * size)
			triangle(st,v[0],v[2],v[1],colour)
			triangle(st,v[0],v[3],v[2],colour)

static func robe(st: SurfaceTool, detail: bool) -> void:
	var sectors := 24 if detail else 12
	for j in 5:
		for i in sectors:
			var v: Array[Vector3] = []
			for uv in [Vector2(j,i),Vector2(j,i+1),Vector2(j+1,i+1),Vector2(j+1,i)]:
				var h: float = uv.x / 5.0; var a: float = uv.y * TAU / sectors
				var fold := 1.0 + .11 * cos(a * 12.0 + h * .8)
				v.append(Vector3(cos(a)*lerpf(.075,.051,h)*fold,.23+h*.31,sin(a)*lerpf(.055,.035,h)*fold))
			triangle(st,v[0],v[2],v[1],PALE * (.97 if i%2 else 1.0))
			triangle(st,v[0],v[3],v[2],PALE)

static func surface(kind: String, detail: bool) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Local Z follows the street. All bases stay within .09 tiles across it.
	if kind == "street_statue":
		box(st,Vector3(0,.025,0),Vector3(.18,.05,.25),MARBLE)
		box(st,Vector3(0,.115,0),Vector3(.135,.13,.18),MARBLE)
		box(st,Vector3(0,.185,0),Vector3(.16,.025,.21),PALE)
		box(st,Vector3(0,.118,.091),Vector3(.085,.04,.005),BRONZE)
		robe(st,detail)
		sphere(st,Vector3(0,.52,0),Vector3(.078,.075,.037),PALE,detail)
		sphere(st,Vector3(0,.605,0),Vector3(.024,.035,.024),MARBLE,detail)
		sphere(st,Vector3(0,.67,0),Vector3(.044,.065,.041),PALE,detail)
		sphere(st,Vector3(0,.697,-.013),Vector3(.046,.042,.036),MARBLE*.88,detail)
		sphere(st,Vector3(0,.671,.04),Vector3(.011,.022,.01),PALE,detail)
		for x in [-.077,.077]: sphere(st,Vector3(x,.50,.005),Vector3(.013,.085,.022),PALE,detail)
		if detail:
			for x in [-.017,.017]: box(st,Vector3(x,.679,.037),Vector3(.016,.004,.009),BLUE*.6)
			for i in 9:
				var a := PI*float(i)/8.0
				sphere(st,Vector3(cos(a)*.043,.713,sin(a)*.04),Vector3(.011,.006,.005),BRONZE,false)
	elif kind == "street_planter":
		box(st,Vector3(0,.035,0),Vector3(.18,.07,.64),MARBLE)
		box(st,Vector3(0,.073,0),Vector3(.15,.012,.60),Color(.22,.23,.16))
		for z in [-.23,-.12,0,.12,.23]:
			sphere(st,Vector3(0,.10,z),Vector3(.06,.04,.065),LEAF,detail)
			if detail:
				for x in [-.025,.025]: sphere(st,Vector3(x,.135,z),Vector3(.014,.009,.014),Color(.66,.30,.21),false)
	elif kind == "street_bench":
		for z in [-.18,.18]: box(st,Vector3(0,.07,z),Vector3(.13,.14,.055),MARBLE)
		if detail:
			for i in 3: box(st,Vector3((i-1)*.056,.16,0),Vector3(.053,.045,.49),PALE)
		else: box(st,Vector3(0,.16,0),Vector3(.17,.045,.49),PALE)
		box(st,Vector3(-.073,.23,0),Vector3(.025,.13,.49),MARBLE)
		box(st,Vector3(-.073,.30,0),Vector3(.034,.023,.51),PALE)
	return st.commit()

static func mesh(kind: String) -> ArrayMesh:
	var near := surface(kind,true).surface_get_arrays(0)
	var far := surface(kind,false).surface_get_arrays(0)
	var n: int = near[Mesh.ARRAY_VERTEX].size(); var f: int = far[Mesh.ARRAY_VERTEX].size()
	for channel in range(Mesh.ARRAY_MAX):
		if channel == Mesh.ARRAY_INDEX or near[channel] == null: continue
		near[channel].append_array(far[channel])
	var indices := PackedInt32Array(); var lod := PackedInt32Array()
	for i in n: indices.append(i)
	for i in f: lod.append(n+i)
	near[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,near,[],{.018:lod})
	return result
