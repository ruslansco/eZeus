extends RefCounted

const SCALE := .22
const ELEVATION := 1
const WALKABLE := 2
const FOUNDATION := 8
const SUBDIVISIONS := 4
const OFFSETS := [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]
var tiles: Dictionary = {}
var origin := Vector2i.ZERO
var extent := Vector2i.ZERO
var corners: Dictionary = {}
var profiles: Dictionary = {}
var normals: Dictionary = {}
var bottom := -1.2
# Sloped cells and, for every cell, how many sloped cells lie in its 3x3 neighbourhood.
# A level cell with none keeps every corner normal exactly up, so it skips the shared
# normal search (the dominant cost of building terrain at city load).
var slope_state: Dictionary = {}
var near_slope: Dictionary = {}

func update(source: Dictionary, map_origin: Vector2i, map_extent: Vector2i, changed: Array[Vector2i]) -> void:
	if tiles.is_empty() or origin != map_origin or extent != map_extent:
		corners.clear()
		profiles.clear()
		normals.clear()
		slope_state.clear()
		near_slope.clear()
		bottom = INF
		for tile in source.values():
			bottom = minf(bottom,float(tile[2])*SCALE-1.2)
		tiles = source
		for cell in source:
			if sloped(cell):
				mark_slope(cell,true)
	tiles = source
	origin = map_origin
	extent = map_extent
	for cell in changed:
		var now := sloped(cell)
		if now != slope_state.get(cell,false):
			mark_slope(cell,now)
	# Heights only change with explicit native geometry observations, not roads
	# or placement availability on a level tile. Shared corners span sections.
	for cell in changed:
		for y in range(-1,2):
			for x in range(-1,2):
				profiles.erase(cell + Vector2i(x,y))
		for offset in OFFSETS:
			corners.erase(cell + offset)
	if not changed.is_empty():
		normals.clear()

func mark_slope(cell: Vector2i, value: bool) -> void:
	if value:
		slope_state[cell] = true
	else:
		slope_state.erase(cell)
	for y in range(-1,2):
		for x in range(-1,2):
			var key := cell + Vector2i(x,y)
			var count: int = near_slope.get(key,0) + (1 if value else -1)
			if count > 0:
				near_slope[key] = count
			else:
				near_slope.erase(key)

func flags(cell: Vector2i) -> int:
	var tile: Array = tiles.get(cell, [])
	return int(tile[6]) if tile.size() >= 8 else 0

func sloped(cell: Vector2i) -> bool:
	var tile: Array = tiles.get(cell, [])
	return not tile.is_empty() and bool(flags(cell) & ELEVATION) and not (flags(cell) & FOUNDATION) and not (int(tile[3]) & 4)

func corner_height(key: Vector2i) -> float:
	if corners.has(key):
		return corners[key]
	var result := -INF
	for y in range(-1,1):
		for x in range(-1,1):
			var tile: Array = tiles.get(key + Vector2i(x,y), [])
			if not tile.is_empty():
				result = maxf(result, float(tile[2]) * SCALE)
	corners[key] = result
	return result

func profile(cell: Vector2i) -> PackedFloat32Array:
	if profiles.has(cell):
		return profiles[cell]
	var result := PackedFloat32Array()
	var tile: Array = tiles[cell]
	var slope := sloped(cell)
	for offset in OFFSETS:
		result.append(corner_height(cell + offset) if slope else float(tile[2]) * SCALE)
	profiles[cell] = result
	return result

func interpolate(p: PackedFloat32Array, u: float, v: float) -> float:
	return lerpf(lerpf(p[0],p[1],u),lerpf(p[3],p[2],u),v)

func height_at(x: float, y: float) -> float:
	var cell := Vector2i(roundi(x),roundi(y))
	if not tiles.has(cell):
		return 0.0
	var p := profile(cell)
	var u := clampf(x - cell.x + .5,0,1)
	var v := clampf(y - cell.y + .5,0,1)
	# Sample the same two-triangle subquad used by the mesh, including saddles.
	var ix := mini(int(u * SUBDIVISIONS),SUBDIVISIONS-1)
	var iy := mini(int(v * SUBDIVISIONS),SUBDIVISIONS-1)
	var step := 1.0/SUBDIVISIONS
	var a := interpolate(p,ix*step,iy*step)
	var b := interpolate(p,(ix+1)*step,iy*step)
	var c := interpolate(p,(ix+1)*step,(iy+1)*step)
	var d := interpolate(p,ix*step,(iy+1)*step)
	u = u*SUBDIVISIONS-ix
	v = v*SUBDIVISIONS-iy
	return a+(b-a)*u+(c-b)*v if u >= v else a+(c-d)*u+(d-a)*v

func world(x: float, y: float, height: float) -> Vector3:
	return Vector3(x-origin.x-(extent.x-1)*.5,height,-(y-origin.y-(extent.y-1)*.5))

func normal_at(p: PackedFloat32Array, u: float, v: float) -> Vector3:
	var dx := lerpf(p[1]-p[0],p[2]-p[3],v)
	var dy := lerpf(p[3]-p[0],p[2]-p[1],u)
	return Vector3(-dx,1,dy).normalized()

func shared_normal(cell: Vector2i, u: float, v: float, height: float) -> Vector3:
	var key := Vector3(cell.x+u-.5,cell.y+v-.5,height)
	if normals.has(key):
		return normals[key]
	var sum := Vector3.ZERO
	var xs := [-1,0] if is_zero_approx(u) else ([0,1] if is_equal_approx(u,1) else [0])
	var ys := [-1,0] if is_zero_approx(v) else ([0,1] if is_equal_approx(v,1) else [0])
	for dy in ys:
		for dx in xs:
			var neighbor := cell+Vector2i(dx,dy)
			if not tiles.has(neighbor):
				continue
			var p := profile(neighbor)
			var nu: float = u-dx
			var nv: float = v-dy
			if absf(interpolate(p,nu,nv)-height) < .0001:
				sum += normal_at(p,nu,nv)
	var result := sum.normalized() if not sum.is_zero_approx() else Vector3.UP
	normals[key] = result
	return result

func vertex(surface: SurfaceTool, position: Vector3, normal: Vector3, water: bool, rock: bool) -> void:
	surface.set_normal(normal)
	surface.set_color(Color.WHITE)
	surface.set_uv(Vector2(position.x,position.z)/12.0)
	surface.set_uv2(Vector2(1 if water else 0,1 if rock else 0))
	surface.add_vertex(position)

func add_top(surface: SurfaceTool, cell: Vector2i, radius := .5, lift := 0.0) -> int:
	var p := profile(cell)
	var slope := sloped(cell)
	var parts := SUBDIVISIONS if slope else 1
	var water := bool(int(tiles[cell][3]) & 4)
	if not slope and not near_slope.has(cell):
		# Level cell with no sloped neighbour: same corners and upward normals as the
		# general path below, without the per-corner shared normal search.
		var level := p[0]
		for index in [0,2,1,0,3,2]:
			var delta: Vector2i = OFFSETS[index]
			vertex(surface,world(cell.x+(float(delta.x)-.5)*radius*2,cell.y+(float(delta.y)-.5)*radius*2,level+lift),Vector3.UP,water,false)
		return 6
	var rock := slope and not (flags(cell) & WALKABLE)
	for y in range(parts):
		for x in range(parts):
			var points: Array[Vector3] = []
			var normals: Array[Vector3] = []
			for delta in OFFSETS:
				var u := float(x + delta.x)/parts
				var v := float(y + delta.y)/parts
				var nx := cell.x + (u-.5)*radius*2
				var ny := cell.y + (v-.5)*radius*2
				var height := interpolate(p,.5+(u-.5)*radius*2,.5+(v-.5)*radius*2)
				points.append(world(nx,ny,height+lift))
				normals.append(shared_normal(cell,u,v,height))
			for index in [0,2,1,0,3,2]:
				vertex(surface,points[index],normals[index],water,rock)
	return parts*parts*6

func add_sides(surface: SurfaceTool, cell: Vector2i) -> int:
	var p := profile(cell)
	var faces := 0
	var edges := [[0,1,Vector2i(0,-1),3,2],[1,2,Vector2i(1,0),0,3],[2,3,Vector2i(0,1),1,0],[3,0,Vector2i(-1,0),2,1]]
	for edge in edges:
		var neighbor: Vector2i = cell + edge[2]
		var other := profile(neighbor) if tiles.has(neighbor) else PackedFloat32Array([bottom,bottom,bottom,bottom])
		var lower_a := float(other[edge[3]])
		var lower_b := float(other[edge[4]])
		if p[edge[0]] <= lower_a+.0001 and p[edge[1]] <= lower_b+.0001:
			continue
		var da: Vector2i = OFFSETS[edge[0]]
		var db: Vector2i = OFFSETS[edge[1]]
		var a := world(cell.x+da.x-.5,cell.y+da.y-.5,p[edge[0]])
		var b := world(cell.x+db.x-.5,cell.y+db.y-.5,p[edge[1]])
		var c := Vector3(b.x,minf(b.y,lower_b),b.z)
		var d := Vector3(a.x,minf(a.y,lower_a),a.z)
		var normal := Vector3(edge[2].x,0,-edge[2].y)
		for point in [a,b,c,a,c,d]:
			vertex(surface,point,normal,false,true)
		faces += 1
	return faces

func footprint_mesh(cell: Vector2i, missing_height := 0.0) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if tiles.has(cell):
		add_top(surface,cell,.48,.06)
	else:
		# Only a red UI marker may extend outside the map, never terrain/collision.
		var points: Array[Vector3] = []
		for delta in OFFSETS:
			points.append(world(cell.x+(delta.x-.5)*.96,cell.y+(delta.y-.5)*.96,missing_height+.06))
		for index in [0,2,1,0,3,2]:
			vertex(surface,points[index],Vector3.UP,false,false)
	return surface.commit()
