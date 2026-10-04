extends Node3D
# Cosmetic countryside outside the exact native footprint. No physics, navigation,
# simulation cells or native random draws. A stitched adaptive mesh meets native edges.
const FIELD_STEP := 8
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const WATER := 4
var tiles: Dictionary
var geometry: RefCounted
var map_origin: Vector2i
var map_extent: Vector2i
var start: Vector2i
var side := 1024
var field_width := 129
var prefix := PackedInt32Array()
var field: Image
var field_texture: ImageTexture
var native_mask: ImageTexture
var sea_level := .025
var has_ocean := false
var roots: Dictionary
var leaves: Array[Dictionary] = []
var vertices := {}
var edge_heights := {}
var boundary: Array[Vector2i] = []
var noise := FastNoiseLite.new()
var land := MeshInstance3D.new()
var trees := Node3D.new()
var vertex_count := 0
var tree_count := 0
var build_usec := 0

func _init() -> void:
	noise.seed = 73129
	noise.frequency = .009
	noise.fractal_octaves = 2
	land.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(land)
	add_child(trees)

func update(source: Dictionary, origin: Vector2i, extent: Vector2i, surface: RefCounted, forest: Node3D) -> void:
	var began := Time.get_ticks_usec()
	tiles = source
	geometry = surface
	map_origin = origin
	map_extent = extent
	side = 1024
	while side < maxi(extent.x, extent.y) + 768: side *= 2
	start = origin + Vector2i(floori(extent.x*.5-side*.5), floori(extent.y*.5-side*.5))
	field_width = side / FIELD_STEP + 1
	boundary.clear(); edge_heights.clear(); vertices.clear(); leaves.clear()
	var lowest := INF
	for cell in tiles:
		if DIRECTIONS.any(func(d): return not tiles.has(cell+d)):
			boundary.append(cell)
			if int(tiles[cell][3]) & WATER: lowest = minf(lowest, float(tiles[cell][2])*.22)
	has_ocean = lowest != INF
	if not has_ocean:
		for tile in tiles.values(): lowest = minf(lowest, float(tile[2])*.22)
	sea_level = (lowest if lowest != INF else 0.0) + .025
	_make_field()
	_make_prefix()
	roots = _subdivide(start.x, start.y, side)
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	vertex_count = 0
	for leaf in leaves: _emit_leaf(mesh, leaf)
	mesh.index()
	land.mesh = mesh.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/surroundings.gdshader")
	material.set_shader_parameter("surface_noise", preload("res://assets/terrain/surface_noise.tres"))
	material.set_shader_parameter("ground_normal", preload("res://assets/terrain/ground_normal.tres"))
	material.set_shader_parameter("sea_level", sea_level if has_ocean else -100.0)
	land.material_override = material
	_make_trees(forest)
	# Scratch fields are retained only for visual sampling/review, never exported as native tiles.
	build_usec = Time.get_ticks_usec() - began

func world(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x-.5-map_origin.x-(map_extent.x-1)*.5, height, -(point.y-.5-map_origin.y-(map_extent.y-1)*.5))

func _make_field() -> void:
	var nearest := PackedInt32Array(); nearest.resize(field_width*field_width); nearest.fill(-1)
	var distance := PackedFloat32Array(); distance.resize(nearest.size()); distance.fill(INF)
	for index in boundary.size():
		var p := Vector2(boundary[index]-start)+Vector2(.5,.5)
		var grid := Vector2i(roundi(p.x/FIELD_STEP), roundi(p.y/FIELD_STEP))
		var slot := grid.y*field_width+grid.x
		var gap := p.distance_to(Vector2(grid)*FIELD_STEP)
		if gap < distance[slot]: nearest[slot]=index; distance[slot]=gap
	for direction in [1,-1]:
		for y in range(0 if direction==1 else field_width-1, field_width if direction==1 else -1, direction):
			for x in range(0 if direction==1 else field_width-1, field_width if direction==1 else -1, direction):
				var index := y*field_width+x
				for offset in [Vector2i(-direction,0),Vector2i(0,-direction),Vector2i(-direction,-direction),Vector2i(direction,-direction)]:
					var q: Vector2i = Vector2i(x,y)+offset
					if q.x<0 or q.y<0 or q.x>=field_width or q.y>=field_width: continue
					var candidate: int = q.y*field_width+q.x
					var gap: float = distance[candidate]+FIELD_STEP*(1.41421356 if offset.x!=0 and offset.y!=0 else 1.0)
					if gap < distance[index]: nearest[index]=nearest[candidate];distance[index]=gap
	field = Image.create(field_width, field_width, false, Image.FORMAT_RGBAH)
	for y in field_width:
		for x in field_width:
			var index := y*field_width+x
			var tile: Array = tiles[boundary[nearest[index]]]
			var flags := int(tile[3])
			var vegetation := .75 if flags&16 else .0
			# Chamfer labels find the nearby boundary; recompute its true distance.
			# Adding the grid-to-seed error to every step made an artificial wet rim.
			var gap := Vector2(start+Vector2i(x,y)*FIELD_STEP).distance_to(Vector2(boundary[nearest[index]])+Vector2(.5,.5))
			field.set_pixel(x,y,Color(0 if flags&WATER else 1, vegetation, float(tile[2])*.22, gap))
	# Soften the distant land/water continuation; keep the exact near-rim field.
	# A nearest-boundary classification alone extrudes long straight coastal cliffs.
	var original: Image = field.duplicate()
	for y in range(2,field_width-2):
		for x in range(2,field_width-2):
			var data := original.get_pixel(x,y)
			if data.a<20:continue
			var mass := 0.0
			for dy in range(-2,3):
				for dx in range(-2,3):mass+=original.get_pixel(x+dx,y+dy).r
			data.r=lerpf(data.r,mass/25.0,smoothstep(20,60,data.a))
			field.set_pixel(x,y,data)
	field_texture = ImageTexture.create_from_image(field)
	var mask := Image.create(map_extent.x,map_extent.y,false,Image.FORMAT_R8)
	mask.fill(Color.BLACK)
	for cell in tiles: mask.set_pixelv(cell-map_origin,Color.WHITE)
	native_mask = ImageTexture.create_from_image(mask)

func sample(point: Vector2) -> Color:
	var p := (point-Vector2(start))/FIELD_STEP
	var x := clampi(floori(p.x),0,field_width-2);var y := clampi(floori(p.y),0,field_width-2)
	return field.get_pixel(x,y).lerp(field.get_pixel(x+1,y),clampf(p.x-x,0,1)).lerp(field.get_pixel(x,y+1).lerp(field.get_pixel(x+1,y+1),clampf(p.x-x,0,1)),clampf(p.y-y,0,1))

func _native_edge(point: Vector2) -> Variant:
	if point.x != floorf(point.x) or point.y != floorf(point.y): return null
	var key := Vector2i(point)
	if edge_heights.has(key): return edge_heights[key]
	var highest := -INF
	for y in range(-1,1):
		for x in range(-1,1):
			var cell := key+Vector2i(x,y)
			if not tiles.has(cell): continue
			var tile: Array = tiles[cell]
			if int(tile[3])&WATER: highest=maxf(highest,float(tile[2])*.22-.48)
			else: highest=maxf(highest,geometry.interpolate(geometry.profile(cell),float(-x),float(-y)))
	var result: Variant = highest if highest != -INF else null
	edge_heights[key]=result
	return result

func height(point: Vector2) -> float:
	var edge: Variant = _native_edge(point)
	if edge != null: return float(edge)
	var data := sample(point)
	var gap := maxf(data.a,0)
	var n := noise.get_noise_2d(point.x,point.y)
	var ridge := pow(1.0-absf(noise.get_noise_2d(point.x*.65+87,point.y*.65-132)),2.0)
	var foothills := (2.5+n*2.2)*smoothstep(3,35,gap)
	var mountains := (ridge*19+pow(maxf(n+.2,0),2)*14)*smoothstep(35,150,gap)
	var land_height := data.b+foothills+mountains
	var exterior := smoothstep(260,340,gap)
	if has_ocean:
		# Lower the distant hills before the coastal fade, avoiding an island-sized cliff.
		land_height=lerpf(land_height,sea_level+.06,smoothstep(210,310,gap))
		# Perturb existing coastal transitions, never manufacture islands in open sea.
		var mass := clampf(data.r + n*.7*4.0*data.r*(1.0-data.r)*smoothstep(15,140,gap),0,1)*(1.0-exterior)
		return lerpf(sea_level-.7,land_height,smoothstep(.25,.8,mass))
	return lerpf(land_height,sea_level-.025,exterior)

func _make_prefix() -> void:
	var width := map_extent.x+1
	prefix.resize(width*(map_extent.y+1));prefix.fill(0)
	for y in map_extent.y:
		var row := 0
		for x in map_extent.x:
			if tiles.has(map_origin+Vector2i(x,y)): row+=1
			prefix[(y+1)*width+x+1]=prefix[y*width+x+1]+row

func _count(x: int,y: int,length: int) -> int:
	var a := Vector2i(clampi(x-map_origin.x,0,map_extent.x),clampi(y-map_origin.y,0,map_extent.y))
	var b := Vector2i(clampi(x+length-map_origin.x,0,map_extent.x),clampi(y+length-map_origin.y,0,map_extent.y))
	var width := map_extent.x+1
	return prefix[b.y*width+b.x]-prefix[a.y*width+b.x]-prefix[b.y*width+a.x]+prefix[a.y*width+a.x]

func _subdivide(x: int,y: int,length: int) -> Dictionary:
	var count := _count(x,y,length)
	var node := {"x":x,"y":y,"size":length,"native":count==length*length}
	if node.native: return node
	var data := sample(Vector2(x+length*.5,y+length*.5))
	var gap := data.a
	var limit := 32 if data.r<.1 and gap>80 else (16 if gap>220 else 8)
	var allowed := clampi(int(maxf(gap-length*.71,0)*.32),1,limit)
	if length>1 and (count>0 or length>allowed):
		var half := length/2
		node.children=[_subdivide(x,y,half),_subdivide(x+half,y,half),_subdivide(x,y+half,half),_subdivide(x+half,y+half,half)]
	else: leaves.append(node)
	return node

func _leaf_at(point: Vector2) -> Dictionary:
	var node := roots
	while node.has("children"):
		var half: float=node.size*.5
		var index := (1 if point.x>=node.x+half else 0)+(2 if point.y>=node.y+half else 0)
		node=node.children[index]
	return node

# Split a long edge wherever the adjacent leaf ends, so both meshes share every edge vertex.
func _edge(a: Vector2,b: Vector2,outside: Vector2,points: Array[Vector2]) -> void:
	points.append(a)
	var along := (b-a).normalized()
	var total := a.distance_to(b)
	var travel := 0.0
	while travel < total-.001:
		var probe := a+along*(travel+.001)+outside*.001
		var neighbor := _leaf_at(probe)
		var end: float
		if along.x>0: end=neighbor.x+neighbor.size-a.x
		elif along.x<0: end=a.x-neighbor.x
		elif along.y>0: end=neighbor.y+neighbor.size-a.y
		else: end=a.y-neighbor.y
		travel=minf(total,maxf(end,travel+.001))
		if travel<total-.001: points.append(a+along*travel)

func _vertex(point: Vector2) -> Array:
	if vertices.has(point): return vertices[point]
	var h := height(point)
	var dx := (height(point+Vector2(.5,0))-height(point-Vector2(.5,0)))
	var dy := (height(point+Vector2(0,.5))-height(point-Vector2(0,.5)))
	var data := sample(point)
	# Native cover continues only across the rim; extruded further, the nearest
	# boundary tile's forest/meadow formed long straight stripes in open country.
	var cover := data.g*(1.0-smoothstep(4,18,data.a))
	var result := [world(point,h),Vector3(-dx,1,dy).normalized(),Color(cover,0,0,smoothstep(3,25,data.a))]
	vertices[point]=result
	return result

func _emit_leaf(surface: SurfaceTool,leaf: Dictionary) -> void:
	var x: float=leaf.x;var y: float=leaf.y;var size: float=leaf.size
	# Deep seabed needs no geometry: the continuous ocean supplies its surface.
	if has_ocean and sample(Vector2(x+size*.5,y+size*.5)).a>18:
		var submerged := true
		for p in [Vector2(x,y),Vector2(x+size,y),Vector2(x+size,y+size),Vector2(x,y+size),Vector2(x+size*.5,y+size*.5)]:
			if height(p)>sea_level-.08: submerged=false;break
		if submerged: return
	var points: Array[Vector2]=[]
	_edge(Vector2(x,y),Vector2(x+size,y),Vector2.UP,points)
	_edge(Vector2(x+size,y),Vector2(x+size,y+size),Vector2.RIGHT,points)
	_edge(Vector2(x+size,y+size),Vector2(x,y+size),Vector2.DOWN,points)
	_edge(Vector2(x,y+size),Vector2(x,y),Vector2.LEFT,points)
	var center := Vector2(x+size*.5,y+size*.5)
	for index in points.size():
		for point in [center,points[(index+1)%points.size()],points[index]]:
			var value := _vertex(point)
			surface.set_normal(value[1]);surface.set_color(value[2]);surface.add_vertex(value[0]);vertex_count+=1

func _make_trees(forest: Node3D) -> void:
	for child in trees.get_children(): child.free()
	tree_count=0
	var batches := {}
	# A bounded woodland fringe hides abrupt forest cuts; only cosmetic outside cells qualify.
	for cell in boundary:
		if not (int(tiles[cell][3])&16): continue
		for d in DIRECTIONS:
			if tiles.has(cell+d): continue
			for depth in range(2,38,4):
				if tree_count>=800: break
				var hash_value := posmod(cell.x*73856093+cell.y*19349663+depth*83492791,997)
				if float(hash_value)/997.0<smoothstep(5,40,depth)*.8:continue
				var point := Vector2(cell+d*depth)+Vector2(.5,.5)
				point+=Vector2(float(hash_value%17)/17.0-.5,float(hash_value%23)/23.0-.5)*4
				if tiles.has(Vector2i(floori(point.x),floori(point.y))) or height(point)<=sea_level+.15: continue
				var kind := "olive" if hash_value%4 else "cypress"
				var key := "%s:%d:%d"%[kind,floori(point.x/32),floori(point.y/32)]
				if not batches.has(key): batches[key]={"kind":kind,"transforms":[]}
				var basis := Basis(Vector3.UP,float(hash_value)/997*TAU).scaled(Vector3.ONE*(.8+float(hash_value%11)/20))
				batches[key].transforms.append(Transform3D(basis,world(point,height(point))))
				tree_count+=1
	for batch in batches.values():
		var multimesh := MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.mesh=forest.mesh_for(batch.kind,0)
		multimesh.instance_count=batch.transforms.size()
		for index in batch.transforms.size(): multimesh.set_instance_transform(index,batch.transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh=multimesh
		instance.material_override=forest.materials[batch.kind]
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end=240
		trees.add_child(instance)
