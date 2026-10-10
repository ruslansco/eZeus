extends Node3D
# Presentation-only geometry. Native flags determine identity, never decoration RNG.
const SECTION := 24
const GRASS_LIMIT := 96
const SHRUB_LIMIT := 48
const RESOURCES := [[8192,"black_marble"],[1024,"marble"],[4096,"orichalcum"],[256,"silver"],[128,"copper"],[512,"tall_stone"],[64,"stone"]]
const OFFSETS := [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
# Authored by tools/godot_mineral_outcrops.py: one mesh per kind:variant, vertex RGB albedo, A ore mask.
const OUTCROPS := preload("res://assets/terrain/mineral_outcrops.glb")
# Per-kind response of outcrop.gdshader; silhouettes and palettes come from the models.
const ROCK_LOOKS := {
	"stone":{"base_roughness":.93,"grain_strength":.18},
	"tall_stone":{"base_roughness":.93,"grain_strength":.2},
	"copper":{"base_roughness":.86,"grain_strength":.22,"ore_metallic":.85,"ore_roughness":.32},
	"silver":{"base_roughness":.78,"grain_strength":.16,"ore_metallic":1.0,"ore_roughness":.2},
	"orichalcum":{"base_roughness":.62,"grain_strength":.2,"ore_metallic":.9,"ore_roughness":.24,"ore_emission":.9},
	"marble":{"base_roughness":.36,"base_specular":.5,"grain_strength":.05,"vein_colour":Vector3(.40,.41,.42),"vein_strength":.55},
	"black_marble":{"base_roughness":.28,"base_specular":.5,"grain_strength":.05,"vein_colour":Vector3(.72,.72,.68),"vein_strength":.7},
}
var tiles: Dictionary = {}
var origin := Vector2i.ZERO
var extent := Vector2i.ZERO
var geometry: RefCounted
var signatures: Dictionary = {}
var sections: Dictionary = {}
var records: Dictionary = {}
var meshes: Dictionary = {}
var materials: Dictionary = {}
var rebuilds := 0
var neighbor_radius := 1
var detail_range := 1.0

func set_detail_range(value: float) -> void:
	detail_range = clampf(value, .5, 1.5)
	for kind in ["grass", "shrub"]:
		materials[kind].set_shader_parameter("fade_start", (42.0 if kind == "grass" else 65.0)*detail_range)
		materials[kind].set_shader_parameter("fade_end", (62.0 if kind == "grass" else 95.0)*detail_range)
	for section in sections.values():
		for batch in section.get_children(): apply_detail_range(batch)

func apply_detail_range(batch: MultiMeshInstance3D) -> void:
	var kind: String = batch.get_meta("kind", "")
	if kind in ["grass", "shrub"]:
		batch.visibility_range_end = (62.0 if kind == "grass" else 95.0)*detail_range+SECTION

func _init() -> void:
	for kind in ROCK_LOOKS:
		var rock := ShaderMaterial.new()
		rock.shader = preload("res://shaders/outcrop.gdshader")
		rock.set_shader_parameter("surface_noise",preload("res://assets/terrain/surface_noise.tres"))
		for parameter in ROCK_LOOKS[kind]:
			rock.set_shader_parameter(parameter,ROCK_LOOKS[kind][parameter])
		materials[kind] = rock
	for kind in ["grass","shrub"]:
		var foliage := ShaderMaterial.new()
		foliage.shader = preload("res://shaders/understory.gdshader")
		foliage.set_shader_parameter("fade_start",42.0 if kind == "grass" else 65.0)
		foliage.set_shader_parameter("fade_end",62.0 if kind == "grass" else 95.0)
		materials[kind] = foliage

func sample(cell: Vector2i, salt: int) -> float:
	return float(posmod((cell.x*73856093) ^ (cell.y*19349663) ^ (salt*83492791),104729))/104729.0

func foundation(tile: Array) -> bool:
	return tile.size() >= 8 and bool(int(tile[6]) & 8)

func resource(tile: Array) -> String:
	for item in RESOURCES:
		if int(tile[3]) & int(item[0]):
			return item[1]
	return ""

func free_ground(tile: Array) -> bool:
	# The explicit legacy bridge lacks foundation metadata; keep new props off there.
	return tile.size() >= 8 and not int(tile[4]) and not foundation(tile) and not (int(tile[3]) & 4)

func vegetation_safe(cell: Vector2i) -> bool:
	# Keep civic paving, crop fields, water and mineral patches clear of understory.
	for y in range(-1,2):
		for x in range(-1,2):
			var tile: Array = tiles.get(cell+Vector2i(x,y),[])
			if not free_ground(tile) or not (int(tile[3]) in [1,16,32]):
				return false
	return true

func placement(cell: Vector2i, kind: String, salt: int, offset: Vector2, scale: Vector3) -> Dictionary:
	var position: Vector3 = geometry.world(cell.x+offset.x,cell.y+offset.y,geometry.height_at(cell.x+offset.x,cell.y+offset.y))
	var basis := Basis(Vector3.UP,sample(cell,salt)*TAU).scaled(scale)
	return {"cell":cell,"kind":kind,"variant":int(sample(cell,salt+1)*2),"transform":Transform3D(basis,position),"seed":sample(cell,salt+2)}

func layout(cell: Vector2i) -> Array:
	var tile: Array = tiles.get(cell,[])
	if not free_ground(tile):
		return []
	var kind := resource(tile)
	if not kind.is_empty():
		# Models span at most 0.40 tiles from their centre, so scale and offset stay in the cell.
		var width := .88+sample(cell,2)*.16
		var height := .82+sample(cell,3)*.36
		var offset := Vector2(sample(cell,5)-.5,sample(cell,6)-.5)*.08
		var yaw := sample(cell,4)*TAU
		if kind in ["marble","black_marble"]:
			width = .86+sample(cell,2)*.12
			height = .85+sample(cell,3)*.3
			# Continuous mineral soil marks the whole quarry; ledges follow its perimeter.
			var boundaries := []
			for delta in OFFSETS:
				var neighbor: Array = tiles.get(cell+delta,[])
				if neighbor.is_empty() or resource(neighbor) != kind:
					boundaries.append(delta)
			if boundaries.is_empty():
				return []
			var delta: Vector2i = boundaries[int(sample(cell,7)*boundaries.size())]
			yaw = PI*.5 if delta == Vector2i.RIGHT else (PI*1.5 if delta == Vector2i.LEFT else (PI if delta == Vector2i.DOWN else 0.0))
			offset = Vector2.ZERO
		var item := placement(cell,kind,4,offset,Vector3(width,height,width))
		item.transform.basis = Basis(Vector3.UP,yaw).scaled(Vector3(width,height,width))
		return [item]
	if not (int(tile[3]) in [1,16,32]) or not vegetation_safe(cell):
		return []
	var forest := bool(int(tile[3]) & 16)
	var forest_neighbors := 0
	for delta in OFFSETS:
		var neighbor: Array = tiles.get(cell+delta,[])
		if not neighbor.is_empty() and int(neighbor[3]) & 16:
			forest_neighbors += 1
	var edge := forest_neighbors > 0 and forest_neighbors < 4
	if not edge and (not forest or sample(cell,10) > .18):
		return []
	var result := []
	if sample(cell,11) < (.76 if edge else .45):
		var offset := Vector2(sample(cell,12)-.5,sample(cell,13)-.5)*.32
		var size := .75+sample(cell,14)*.35
		result.append(placement(cell,"grass",15,offset,Vector3.ONE*size))
	if forest and edge and sample(cell,20) < .34:
		var offset := Vector2(sample(cell,21)-.5,sample(cell,22)-.5)*.24
		var size := .8+sample(cell,23)*.25
		result.append(placement(cell,"shrub",24,offset,Vector3.ONE*size))
	return result

func signature(tile: Array) -> Array:
	return [tile[2],tile[3],tile[4],int(tile[6]) & 9 if tile.size() >= 8 else 0]

func update(source: Dictionary, map_origin: Vector2i, map_extent: Vector2i, surface_geometry: RefCounted, changed: Array[Vector2i]) -> void:
	var initial := signatures.is_empty() or origin != map_origin or extent != map_extent
	if initial:
		for node in sections.values():
			node.free()
		sections.clear()
		records.clear()
		signatures.clear()
	tiles = source
	origin = map_origin
	extent = map_extent
	geometry = surface_geometry
	var dirty := {}
	for cell in changed:
		var current := signature(tiles[cell])
		if not initial and signatures.get(cell,[]) == current:
			continue
		signatures[cell] = current
		if initial:
			dirty[section_key(cell)] = true
		else:
			# Neighbor forest edges, clearance buffers and shared height corners change too.
			for y in range(-neighbor_radius,neighbor_radius+1):
				for x in range(-neighbor_radius,neighbor_radius+1):
					var neighbor := cell+Vector2i(x,y)
					if tiles.has(neighbor):
						dirty[section_key(neighbor)] = true
	for key in dirty:
		rebuild(key)

func section_key(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x-origin.x)/SECTION),floori(float(cell.y-origin.y)/SECTION))

func rebuild(key: Vector2i) -> void:
	rebuilds += 1
	if sections.has(key):
		sections[key].free()
	var node := Node3D.new()
	add_child(node)
	sections[key] = node
	var groups := {}
	var entries := []
	var counts := {"grass":0,"shrub":0}
	for y in range(origin.y+key.y*SECTION,mini(origin.y+(key.y+1)*SECTION,origin.y+extent.y)):
		for x in range(origin.x+key.x*SECTION,mini(origin.x+(key.x+1)*SECTION,origin.x+extent.x)):
			for item in layout(Vector2i(x,y)):
				if item.kind in counts:
					if counts[item.kind] >= (GRASS_LIMIT if item.kind == "grass" else SHRUB_LIMIT):
						continue
					counts[item.kind] += 1
				entries.append(item)
				var asset := "%s:%d" % [item.kind,item.variant]
				if not groups.has(asset):
					groups[asset] = []
				groups[asset].append(item)
	records[key] = entries
	for asset in groups:
		var kind: String = asset.get_slice(":",0)
		var mesh := mesh_for(kind,int(asset.get_slice(":",1)))
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_custom_data = true
		batch.mesh = mesh
		batch.instance_count = groups[asset].size()
		for index in range(batch.instance_count):
			var item: Dictionary = groups[asset][index]
			batch.set_instance_transform(index,item.transform)
			batch.set_instance_custom_data(index,Color(item.seed,0,0,1))
		var instances := MultiMeshInstance3D.new()
		instances.multimesh = batch
		instances.set_meta("kind",kind)
		instances.material_override = materials[kind]
		if kind in ["grass","shrub"]:
			instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Conservative section culling surrounds the per-fragment distance fade.
			instances.visibility_range_end = (62.0 if kind == "grass" else 95.0)+SECTION
			instances.visibility_range_end_margin = 4.0
		node.add_child(instances)
		apply_detail_range(instances)

func summary() -> Dictionary:
	var result := {"sections":sections.size(),"batches":0,"instances":0,"vertices_per_mesh":{},"counts":{}}
	for entries in records.values():
		for item in entries:
			result.instances += 1
			result.counts[item.kind] = result.counts.get(item.kind,0)+1
	for node in sections.values():
		result.batches += node.get_child_count()
	for name in meshes:
		result.vertices_per_mesh[name] = meshes[name].surface_get_array_len(0)
	return result

func face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (c-a).cross(b-a).normalized()
	for point in [a,b,c]:
		surface.set_color(color)
		surface.set_normal(normal)
		surface.add_vertex(point)

func blade(surface: SurfaceTool, base: Vector3, direction: Vector3, height: float, width: float, color: Color) -> void:
	var across := Vector3(-direction.z,0,direction.x)*width
	var middle := base+Vector3.UP*height*.55+direction*height*.12
	var tip := base+Vector3.UP*height+direction*height*.35
	var normal := Vector3(-direction.x,.35,-direction.z).normalized()
	var positions := [base-across,base+across,middle+across*.65,middle-across*.65,tip]
	for index in [0,2,1,0,3,2,3,4,2]:
		surface.set_normal(normal)
		var tint := color
		tint.a = [0.0,0.0,.55,.55,1.0][index]
		surface.set_color(tint)
		surface.add_vertex(positions[index])

func outcrop(kind: String, variant: int) -> ArrayMesh:
	if not meshes.has("stone:0"):
		var library: Node = OUTCROPS.instantiate()
		for node in library.find_children("*","MeshInstance3D",true,false):
			var name: String = node.name
			var split := name.rfind("_")
			meshes["%s:%s" % [name.substr(0,split),name.substr(split+1)]] = node.mesh
		library.free()
	return meshes["%s:%d" % [kind,variant]]

func mesh_for(kind: String, variant: int) -> ArrayMesh:
	var key := "%s:%d" % [kind,variant]
	if meshes.has(key):
		return meshes[key]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "grass":
		for index in range(9):
			var angle := index*2.4+variant
			var direction := Vector3(cos(angle),0,sin(angle))
			blade(surface,direction*(.025+.035*(index%3)),direction,.17+.035*(index%4),.012,Color(.37+.015*(index%3),.42,.22,1))
	elif kind == "shrub":
		for branch in range(5):
			var angle := branch*2.4+variant*.8
			var direction := Vector3(cos(angle),0,sin(angle))
			var height := .24+.025*(branch%3)
			var base := direction*.035
			blade(surface,base,direction,height,.005,Color(.29,.25,.16,1))
			for layer in range(3):
				var center := base+Vector3.UP*height*(.35+layer*.25)+direction*height*.2
				for sign in [-1,1]:
					var tip: Vector3 = center+direction*sign*(.085-layer*.012)+Vector3.UP*.02
					var width := Vector3(-direction.z,0,direction.x)*(.028-layer*.004)
					var color := Color(.29+.025*layer,.36+.02*layer,.23, .45+layer*.2)
					face(surface,center,tip-width,tip,color)
					face(surface,center,tip,tip+width,color)
	else:
		return outcrop(kind,variant)
	var mesh := surface.commit()
	meshes[key] = mesh
	return mesh
