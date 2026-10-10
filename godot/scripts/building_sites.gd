extends Node3D
# Cosmetic supports and construction timber. Uses existing placements/terrain;
# never changes native heights, tiles, pathfinding, progress or timing.
const Geometry=preload("res://scripts/terrain_geometry.gd")
const STEP:=.24
const MIN_GAP:=.012
const MAX_GAP:=.88
var base_shapes: Dictionary={}
var records: Dictionary={}
var sections: Dictionary={}
var stone: StandardMaterial3D
var timber: StandardMaterial3D
var cube:=BoxMesh.new()
var rebuilt:=0
var support_vertices:=0
var scaffold_instances:=0

static func supported(asset: String) -> bool:
	# Avoid closing gates, water structures, animal reservations or ground plants.
	return asset.begins_with("common_house_") and not asset.begins_with("common_house_0") and not asset.begins_with("common_house_1") or asset.begins_with("elite_house_") or asset.begins_with("sanctuary_court_") or asset in ["fountain","well","maintenance_office","warehouse","granary","library","museum","college","observatory","theater","gymnasium","tower"]

static func constructing(building: Dictionary) -> bool:
	var asset: String=str(building.asset)
	return int(building.get("grow",100))<100 and not building.get("stretch",false) and int(building.w)>=2 and int(building.h)>=2 and (asset.begins_with("sanctuary_") or asset.begins_with("pyramid_")) and not asset.begins_with("sanctuary_court_")

func prepare() -> void:
	if stone!=null:return
	stone=StandardMaterial3D.new();stone.vertex_color_use_as_albedo=true;stone.roughness=.88
	timber=StandardMaterial3D.new();timber.albedo_color=Color(.36,.25,.14);timber.roughness=.93
	cube.size=Vector3.ONE

func shape(asset: String, batches: Node) -> Dictionary:
	if base_shapes.has(asset):return base_shapes[asset]
	var low:=INF;var high:=-INF
	var sources: Array=[]
	for piece in batches.template(asset):
		if piece.get("activity",false):continue
		var bounds: AABB=piece.transform*piece.mesh.get_aabb()
		low=minf(low,bounds.position.y);high=maxf(high,bounds.end.y)
		sources.append(piece)
	var points:=PackedVector2Array()
	var contact_top:=low
	for piece in sources:
		if (piece.transform*piece.mesh.get_aabb()).position.y>low+.09:continue
		for surface in piece.mesh.get_surface_count():
			var arrays: Array=piece.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				var point: Vector3=piece.transform*vertex
				if point.y<=low+.09:
					points.append(Vector2(point.x,point.z));contact_top=maxf(contact_top,point.y)
	var result: Dictionary={"polygon":Geometry2D.convex_hull(points) if points.size()>2 else PackedVector2Array(),"low":low if is_finite(low) else 0.0,"contact_top":contact_top if is_finite(contact_top) else 0.0,"height":high-low if is_finite(low) and is_finite(high) else 0.0}
	base_shapes[asset]=result
	return result

func support(building: Dictionary, transform: Transform3D, base: Dictionary, city: Node) -> Dictionary:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray()
	var polygon: PackedVector2Array=base.polygon
	if polygon.size()<3:return {"vertices":vertices,"normals":normals,"colors":colors}
	var edge_points:=PackedVector3Array()
	for point in polygon:
		var world: Vector3=transform*Vector3(point.x,float(base.get("contact_top",base.low)),point.y)
		var tile: Vector2=city.tile_coordinates(world)
		# Clamp within the native lot, including the street setback. Never pave
		# over a road or extend a support into the empty cells of an irregular map.
		tile.x=clampf(tile.x,float(building.x)-.46,float(building.x+building.w)-.54)
		tile.y=clampf(tile.y,float(building.y)-.46,float(building.y+building.h)-.54)
		var clamped: Vector3=city.world_position(tile.x,tile.y,0)
		clamped.y=world.y;edge_points.append(clamped)
	for index in range(edge_points.size()-1):
		var a:=edge_points[index];var b:=edge_points[index+1]
		if a.distance_squared_to(b)<.000001:continue
		var parts:=maxi(1,ceili(a.distance_to(b)/STEP))
		for part in parts:
			var p:=a.lerp(b,float(part)/parts);var q:=a.lerp(b,float(part+1)/parts)
			var pc: Vector2=city.tile_coordinates(p);var qc: Vector2=city.tile_coordinates(q)
			var pt: Array=city.tiles.get(Vector2i(pc.round()),[]);var qt: Array=city.tiles.get(Vector2i(qc.round()),[])
			if pt.is_empty() or qt.is_empty() or int(pt[3])&4 or int(qt[3])&4 or int(pt[4]) or int(qt[4]):continue
			var ph: float=city.terrain_geometry.height_at(pc.x,pc.y);var qh: float=city.terrain_geometry.height_at(qc.x,qc.y)
			var gap:=maxf(p.y-ph,q.y-qh)
			if gap<=MIN_GAP or gap>MAX_GAP:continue
			var bottom_p:=Vector3(p.x,minf(p.y,ph)-.008,p.z)
			var bottom_q:=Vector3(q.x,minf(q.y,qh)-.008,q.z)
			var normal: Vector3=(q-p).cross(Vector3.DOWN).normalized()
			var colour:=Color(.67,.65,.59) if index%2==0 else Color(.70,.68,.62)
			for point in [p,bottom_q,q,p,bottom_p,bottom_q]:
				vertices.append(point);normals.append(normal);colors.append(colour)
	return {"vertices":vertices,"normals":normals,"colors":colors}

static func beam(a: Vector3, b: Vector3, width: float) -> Transform3D:
	var length:=a.distance_to(b)
	var up: Vector3=(b-a).normalized()
	var across:=Vector3.FORWARD.cross(up).normalized() if absf(up.dot(Vector3.FORWARD))<.9 else Vector3.RIGHT.cross(up).normalized()
	return Transform3D(Basis(across,up,across.cross(up))*Basis.from_scale(Vector3(width,length,width)),(a+b)*.5)

func scaffolding(building: Dictionary, transform: Transform3D, height: float, reveal:=false) -> Array:
	var result: Array=[]
	if not constructing(building):return result
	var center:=transform.origin
	var width:=float(building.w)*.5-.09;var depth:=float(building.h)*.5-.09
	var fraction:=float(building.get("grow",100))*.01 if reveal else 1.0
	var rise:=clampf(height*transform.basis.y.length()*fraction+.16,.36,4.2)
	# The native lot contains the timber; neither a road nor a neighbouring lot
	# gains a scaffold. It rises only to the actual current construction height.
	var corners: Array=[Vector3(-width,0,-depth),Vector3(width,0,-depth),Vector3(width,0,depth),Vector3(-width,0,depth)]
	for point in corners:result.append(beam(center+point,center+point+Vector3.UP*rise,.045))
	var levels:=maxi(1,ceili(rise/.8))
	for level in range(1,levels+1):
		var lift:=Vector3.UP*(rise*level/levels-.05)
		for side in 4:
			var a: Vector3=center+corners[side]+lift;var b: Vector3=center+corners[(side+1)%4]+lift
			result.append(beam(a,b,.045))
	# Two opposed braced sides leave the other faces easy to read.
	for side in [0,2]:result.append(beam(center+corners[side]+Vector3.UP*.08,center+corners[side+1]+Vector3.UP*(rise-.05),.03))
	return result

func refresh(buildings: Array, city: Node) -> void:
	prepare();rebuilt=0
	var alive: Dictionary={};var dirty: Dictionary={}
	for building in buildings:
		var asset: String=str(building.asset)
		if not supported(asset) and not constructing(building):continue
		if not city.overlay_view.building_visible(building):continue
		var id:=int(building.id);alive[id]=true
		var transform: Transform3D=city.building_draw_transform(building)
		var key: Array=[asset,transform,city.surface_revision,building.w,building.h,building.get("grow",100)]
		if records.get(id,{}).get("key")==key:continue
		var section:=Vector2i(floori(float(building.x)/32),floori(float(building.y)/32))
		if records.has(id):dirty[records[id].section]=true
		var base:=shape(asset,city.static_batches)
		var skin: Dictionary=support(building,transform,base,city) if supported(asset) else {"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"colors":PackedColorArray()}
		records[id]={"key":key,"section":section,"skin":skin,"beams":scaffolding(building,transform,float(base.height),city.static_batches.construction.active(building))}
		dirty[section]=true
	for id in records.keys():
		if not alive.has(id):dirty[records[id].section]=true;records.erase(id)
	for section in dirty:rebuild(section)
	support_vertices=0;scaffold_instances=0
	for record in records.values():support_vertices+=record.skin.vertices.size();scaffold_instances+=record.beams.size()

func rebuild(section: Vector2i) -> void:
	var points:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray();var beams: Array=[]
	for record in records.values():
		if record.section!=section:continue
		points.append_array(record.skin.vertices);normals.append_array(record.skin.normals);colors.append_array(record.skin.colors);beams.append_array(record.beams)
	if points.is_empty() and beams.is_empty():
		if sections.has(section):sections[section].free();sections.erase(section)
		return
	var holder: Node3D=sections.get(section)
	if holder==null:
		holder=Node3D.new();add_child(holder);sections[section]=holder
	for child in holder.get_children():child.free()
	if not points.is_empty():
		var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors
		var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=stone;holder.add_child(node)
	if not beams.is_empty():
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=cube;batch.instance_count=beams.size()
		for index in beams.size():batch.set_instance_transform(index,beams[index])
		var node:=MultiMeshInstance3D.new();node.multimesh=batch;node.material_override=timber;holder.add_child(node)
	rebuilt+=1
