extends MeshInstance3D
# Dashed outline of the native playable board, like the area border in Cities: Skylines.
# Presentation only: no collision, navigation or native data; built once per city load.
const INSET := .7      # Tiles inside the outermost native cell edge.
const STEP := .5       # Height samples along the border, in tiles.
const SIMPLIFY := .75  # Straightens the one-tile staircase of diamond-shaped boards.
const LIFT := .04
const WATER := 4
var outline := PackedVector2Array()  # Simplified, inset loop in native tile coordinates.
var perimeter := 0.0
var segments := 0
var published := 0  # Corners handed to the outside tint (shader globals).

func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 4.0  # The vertex shader widens the ribbon with camera distance.
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/map_border.gdshader")
	material_override = material

func update(tiles: Dictionary, geometry: RefCounted) -> void:
	outline = inset(simplify(trace(tiles)))
	perimeter = 0.0
	segments = 0
	mesh = null
	if outline.size() < 3:
		RenderingServer.global_shader_parameter_set("map_border_count",0)
		published = 0
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in outline.size():
		var a := outline[index]
		var b := outline[(index+1)%outline.size()]
		var direction := (b-a).normalized()
		var across := Vector2(-direction.y,direction.x)
		var count := maxi(1,ceili(a.distance_to(b)/STEP))
		var previous := []
		for step in count+1:
			var point := a.lerp(b,float(step)/count)
			var height := -INF
			for side in [-.35,0.0,.35]:
				height = maxf(height,surface_height(tiles,geometry,point+across*side))
			var centre: Vector3 = geometry.world(point.x,point.y,height+LIFT)
			var pair := []
			for side in [-1.0,1.0]:
				pair.append([centre,Vector2(side,perimeter+a.distance_to(point))])
			if not previous.is_empty():
				for corner in [previous[0],previous[1],pair[1],previous[0],pair[1],pair[0]]:
					surface.set_uv(corner[1])
					# Native +Y is world -Z.
					surface.set_uv2(Vector2(across.x,-across.y))
					surface.set_normal(Vector3.UP)
					surface.add_vertex(corner[0])
				segments += 1
			previous = pair
		perimeter += a.distance_to(b)
	mesh = surface.commit()
	publish(geometry)

func publish(geometry: RefCounted) -> void:
	# The outside tint (map_outside.gdshaderinc) uses the same straight loop as the dashes.
	var image := Image.create(maxi(outline.size(),1),1,false,Image.FORMAT_RGF)
	for index in outline.size():
		var point: Vector3 = geometry.world(outline[index].x,outline[index].y,0)
		image.set_pixel(index,0,Color(point.x,point.z,0))
	RenderingServer.global_shader_parameter_set("map_border_points",ImageTexture.create_from_image(image))
	RenderingServer.global_shader_parameter_set("map_border_count",outline.size())
	published = outline.size()

func surface_height(tiles: Dictionary, geometry: RefCounted, point: Vector2) -> float:
	var cell := Vector2i(roundi(point.x),roundi(point.y))
	var tile: Array = tiles.get(cell,[])
	if tile.is_empty():
		return -INF
	if int(tile[3]) & WATER:
		return float(tile[2])*.22+.025  # The native water surface, as main.gd draws it.
	return geometry.height_at(point.x,point.y)

func trace(tiles: Dictionary) -> PackedVector2Array:
	# Directed cell edges facing outside, interior on the right (native +Y is down).
	# Corner (i,j) is native point (i-.5,j-.5).
	var next := {}
	for cell in tiles:
		var x: int = cell.x
		var y: int = cell.y
		for side in [[Vector2i.UP,Vector2i(x,y),Vector2i(x+1,y)],[Vector2i.RIGHT,Vector2i(x+1,y),Vector2i(x+1,y+1)],
				[Vector2i.DOWN,Vector2i(x+1,y+1),Vector2i(x,y+1)],[Vector2i.LEFT,Vector2i(x,y+1),Vector2i(x,y)]]:
			if not tiles.has(cell+side[0]):
				if not next.has(side[1]):
					next[side[1]] = []
				next[side[1]].append(side[2])
	# Interior holes also form loops; only the longest one is the board's edge.
	var longest := []
	while not next.is_empty():
		var start: Vector2i = next.keys()[0]
		var loop := [start]
		var corner := start
		while next.has(corner):
			var ends: Array = next[corner]
			var end: Vector2i = ends.pop_back()
			if ends.is_empty():
				next.erase(corner)
			if end == start:
				break
			loop.append(end)
			corner = end
		if loop.size() > longest.size():
			longest = loop
	# Edge midpoints lie on one straight line along a regular staircase.
	var result := PackedVector2Array()
	for index in longest.size():
		var a: Vector2 = Vector2(longest[index])
		var b: Vector2 = Vector2(longest[(index+1)%longest.size()])
		result.append((a+b)*.5-Vector2(.5,.5))
	return result

func simplify(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 4:
		return points
	var far := 0
	for index in points.size():
		if points[index].distance_squared_to(points[0]) > points[far].distance_squared_to(points[0]):
			far = index
	var keep := {0:true,far:true}
	reduce(points,0,far,keep)
	reduce(points,far,points.size(),keep)
	var indices := keep.keys()
	indices.sort()
	var result := PackedVector2Array()
	for index in indices:
		result.append(points[index%points.size()])
	return result

func reduce(points: PackedVector2Array, first: int, last: int, keep: Dictionary) -> void:
	# Douglas-Peucker over points[first..last], wrapping the closing index.
	var a := points[first]
	var b := points[last%points.size()]
	var worst := -1
	var distance := SIMPLIFY
	for index in range(first+1,last):
		var gap := Geometry2D.get_closest_point_to_segment(points[index],a,b).distance_to(points[index])
		if gap > distance:
			distance = gap
			worst = index
	if worst >= 0:
		keep[worst] = true
		reduce(points,first,worst,keep)
		reduce(points,worst,last,keep)

func inset(points: PackedVector2Array) -> PackedVector2Array:
	var area := 0.0
	for index in points.size():
		var a := points[index]
		var b := points[(index+1)%points.size()]
		area += a.x*b.y-b.x*a.y
	var flip := 1.0 if area > 0 else -1.0
	var result := PackedVector2Array()
	for index in points.size():
		var previous := points[index-1]
		var point := points[index]
		var following := points[(index+1)%points.size()]
		var d1 := (point-previous).normalized()
		var d2 := (following-point).normalized()
		var n1 := Vector2(-d1.y,d1.x)*flip
		var n2 := Vector2(-d2.y,d2.x)*flip
		var miter := (n1+n2).normalized()
		result.append(point+miter*INSET/maxf(miter.dot(n1),.35))
	return result
