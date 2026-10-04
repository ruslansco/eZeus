extends Node3D
# Presentation-only Gates of Hades. Local deterministic geometry, batched by finish.
# No simulation, gameplay RNG, collisions or navigation are created here.
const ORIGIN := Vector3(5.5, 0.0, -3.0)
const CameraMotion = preload("res://scripts/login_camera.gd")
const STONE_DIFF = preload("res://assets/menu/rock_06_diff_2k.jpg")
const STONE_NORMAL = preload("res://assets/menu/rock_06_nor_gl_2k.jpg")
const STONE_ROUGH = preload("res://assets/menu/rock_06_rough_2k.jpg")
var rng := RandomNumberGenerator.new()
var batches: Dictionary = {}
var finishes: Dictionary = {}
var animated_materials: Array[ShaderMaterial] = []
var fire_lights: Array[OmniLight3D] = []
var scene_time := 0.0
var camera: Camera3D
var portal_light: OmniLight3D
var mesh_instances := 0
var geometry_triangles := 0
var build_msec := 0
var frozen := false

func _ready() -> void:
	# City automation skips this scenery entirely. Ordinary menus and reviewers build it.
	if not Engine.has_meta("ezeus_menu_review"):
		for arg in OS.get_cmdline_user_args():
			if arg == "--skip-start" or arg == "--validate" or arg.begins_with("--capture=") or arg.begins_with("--bridge-port=") or arg.contains("-review"):
				return
	var started := Time.get_ticks_msec()
	rng.seed = 0x4841444553
	_materials()
	_environment()
	_landscape()
	_gateway()
	_guardian(-1.0)
	_guardian(1.0)
	_approach()
	_atmosphere()
	_soul_paths()
	_flush_batches()
	build_msec = Time.get_ticks_msec() - started

func _stone(color: Color, scale_value: float, rough: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader=load("res://shaders/menu_stone.gdshader")
	m.set_shader_parameter("stone_color",STONE_DIFF)
	m.set_shader_parameter("stone_normal",STONE_NORMAL)
	m.set_shader_parameter("stone_rough",STONE_ROUGH)
	m.set_shader_parameter("base_color",color)
	m.set_shader_parameter("scale_value",scale_value)
	m.set_shader_parameter("normal_strength",.11 if rough>.9 else .19)
	return m

func _materials() -> void:
	finishes.basalt = _stone(Color(.30,.32,.33), .28, .92)
	finishes.edge = _stone(Color(.53,.51,.45), .32, .80)
	finishes.floor = _stone(Color(.36,.37,.35), .40, .64)
	finishes.cliff = _stone(Color(.23,.26,.28), .12, .98)
	finishes.statue = _stone(Color(.46,.46,.43), .46, .88)
	finishes.statue.set_shader_parameter("palette_strength",0.0)
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(.28,.18,.074)
	bronze.metallic = .82
	bronze.roughness = .44
	bronze.vertex_color_use_as_albedo = true
	finishes.bronze = bronze
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(.012,.016,.018)
	black.roughness = 1.0
	finishes.black = black
	var coal := StandardMaterial3D.new()
	coal.albedo_color = Color(.055,.014,.008)
	coal.emission_enabled = true
	coal.emission = Color(1.0,.16,.008)
	coal.emission_energy_multiplier = 1.5
	finishes.coal = coal

func _animated(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	animated_materials.append(m)
	return m

func _environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := _animated("res://shaders/login_sky.gdshader")
	sky_material.set_shader_parameter("cloud_sky",load("res://assets/menu/cloud_sky_2k.exr"))
	sky.sky_material = sky_material
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(.34,.43,.53)
	env.ambient_light_energy = .34
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	env.glow_enabled = true
	env.glow_intensity = .65
	env.glow_bloom = .06
	env.glow_hdr_threshold = 1.3
	env.fog_enabled = true
	env.fog_light_color = Color(.085,.13,.16)
	env.fog_density = .0035
	env.fog_sky_affect = .18
	# Mobile has no SSR, SSAO or volumetric fog; the scene uses actual geometry and mist cards.
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false
	world.environment = env
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-38,-32,0)
	moon.light_color = Color(.54,.68,.84)
	moon.light_energy = 1.0
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	moon.directional_shadow_max_distance = 85.0
	add_child(moon)
	portal_light = _light("PortalSpill", ORIGIN+Vector3(0,8,2.4), Color(1.0,.27,.065), 5.0, 15.0)
	_light("PortalThreshold", ORIGIN+Vector3(0,3,4.0), Color(1.0,.34,.10), 3.0, 11.0)
	_light("ArchRim", ORIGIN+Vector3(0,18,-3), Color(.20,.47,.57), 3.0, 17.0)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(CameraMotion)
	camera.position = Vector3(-2.7,5.3,29)
	camera.fov = 45.0
	camera.near = .2
	camera.far = 240.0
	add_child(camera)
	camera.look_at(Vector3(0,9.5,-3))
	# Camera script readied before look_at: capture the authored pose after aiming.
	camera.origin_pos = camera.position
	camera.origin_rot = camera.rotation
	camera.float_range_z = .16
	camera.float_range_y = .055
	camera.parallax_pos_scale = Vector2(.30,.14)
	camera.parallax_rot_scale = Vector2(.008,.005)
	camera.current = true

func _light(label: String, pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = label
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 1.25
	add_child(light)
	return light

func _batch(mesh: Mesh, transform: Transform3D, key: String) -> void:
	if not batches.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key] = tool
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		# Primitive meshes omit COLOR; fill it explicitly before joining coloured masonry.
		# Otherwise SurfaceTool supplies black for those vertices in the combined surface.
		if arrays[Mesh.ARRAY_COLOR] == null or arrays[Mesh.ARRAY_COLOR].is_empty():
			var colors := PackedColorArray()
			colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
			colors.fill(Color.WHITE)
			arrays[Mesh.ARRAY_COLOR]=colors
			var colored := ArrayMesh.new()
			colored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			batches[key].append_from(colored,0,transform)
		else:
			batches[key].append_from(mesh,surface,transform)

func _flush_batches() -> void:
	for key in batches:
		var mesh: ArrayMesh = batches[key].commit()
		mesh.surface_set_material(0, finishes[key])
		var node := MeshInstance3D.new()
		node.name = "Masonry_" + key
		node.mesh = mesh
		add_child(node)
		mesh_instances += 1
		geometry_triangles += mesh.surface_get_array_index_len(0) / 3
	batches.clear()

# Every block has bevels. Shared triplanar scans avoid stretched UVs on the large arch.
func _bevel_box(size: Vector3, bevel: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size*.5
	var b := minf(bevel, minf(h.x,minf(h.y,h.z))*.45)
	var tint := Color.from_hsv(.10, rng.randf_range(.0,.06), rng.randf_range(.82,1.0))
	for axis in 3:
		var u := (axis+1)%3
		var v := (axis+2)%3
		for side in [-1.0,1.0]:
			var face: Array[Vector3] = []
			for pair in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis]=h[axis]*side
				p[u]=(h[u]-b)*pair.x
				p[v]=(h[v]-b)*pair.y
				face.append(p)
			_face(tool,face,tint)
		# Bevel edges between this axis and its successor.
		for sa in [-1.0,1.0]:
			for su in [-1.0,1.0]:
				var face: Array[Vector3] = []
				for pair in [Vector2(0,-1),Vector2(1,-1),Vector2(1,1),Vector2(0,1)]:
					var p := Vector3.ZERO
					p[axis]=(h[axis]-(b if pair.x>0 else 0.0))*sa
					p[u]=(h[u]-(0.0 if pair.x>0 else b))*su
					p[v]=(h[v]-b)*pair.y
					face.append(p)
				_face(tool,face,tint)
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				_face(tool,[Vector3(h.x,h.y-b,h.z-b)*Vector3(sx,sy,sz),Vector3(h.x-b,h.y,h.z-b)*Vector3(sx,sy,sz),Vector3(h.x-b,h.y-b,h.z)*Vector3(sx,sy,sz)],tint)
	tool.index()
	return tool.commit()

func _face(tool: SurfaceTool, points: Array, tint: Color) -> void:
	var normal: Vector3 = (points[1]-points[0]).cross(points[2]-points[0]).normalized()
	var center := Vector3.ZERO
	for point in points:
		center += point
	if normal.dot(center) < 0.0:
		points.reverse()
		normal = -normal
	for i in range(1,points.size()-1):
		# Godot front faces are clockwise.
		for j in [0,i+1,i]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(points[j].x,points[j].y))
			tool.set_color(tint)
			tool.add_vertex(points[j])

func _box(pos: Vector3, size: Vector3, key: String, angles := Vector3.ZERO, bevel := .055) -> void:
	_batch(_bevel_box(size,bevel),Transform3D(Basis.from_euler(angles),pos),key)

func _gbox(pos: Vector3, size: Vector3, key: String, angles := Vector3.ZERO, bevel := .055) -> void:
	_box(pos+ORIGIN,size,key,angles,bevel)

func _cylinder(pos: Vector3, radius: float, height: float, key: String, top := -1.0, angles := Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius=radius
	mesh.top_radius=radius if top<0 else top
	mesh.height=height
	mesh.radial_segments=32
	_batch(mesh,Transform3D(Basis.from_euler(angles),pos),key)

func _sphere(pos: Vector3, size: Vector3, key: String) -> void:
	var mesh := SphereMesh.new()
	mesh.radius=1.0
	mesh.height=2.0
	mesh.radial_segments=32
	mesh.rings=16
	_batch(mesh,Transform3D(Basis.IDENTITY.scaled(size),pos),key)

func _rock(pos: Vector3, size: Vector3, angle := 0.0) -> void:
	var source := SphereMesh.new()
	source.radial_segments=36
	source.rings=20
	source.radius=1.0
	source.height=2.0
	var arrays := source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	for i in vertices.size():
		var v := vertices[i]
		var distortion := 1.0+sin(v.x*5.0+v.y*3.0)*cos(v.z*4.0-v.x*2.0)*.12
		vertices[i]=v*distortion
		colors.append(Color(.88,.90,.92))
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tool := SurfaceTool.new()
	tool.create_from(mesh,0)
	mesh=tool.commit()
	_batch(mesh,Transform3D(Basis(Vector3.UP,angle).scaled(size),pos),"cliff")

func _landscape() -> void:
	# Jagged canyon walls recede in layers, with open space for the menu at left.
	for side in [-1.0,1.0]:
		for i in 27:
			var z := rng.randf_range(-76,18)
			var x: float = side*rng.randf_range(17,34)+5.5
			var height := rng.randf_range(4,14)
			_rock(Vector3(x,height*.38-2,z),Vector3(rng.randf_range(3,7),height,rng.randf_range(4,10)),rng.randf()*TAU)
		for i in 16:
			var x: float = side*rng.randf_range(12,27)+5.5
			var z := rng.randf_range(-25,24)
			_rock(Vector3(x,-.8,z),Vector3(rng.randf_range(2,5),rng.randf_range(.7,2.4),rng.randf_range(2,5)),rng.randf()*TAU)
	# Underworld ruin silhouettes, at genuine depth rather than painted on the sky.
	for side in [-1.0,1.0]:
		for i in 5:
			var pos := Vector3(side*(18+i*3.4)+5.5,0,-39-i*4)
			_cylinder(pos+Vector3(0,5.0,0),.55,9.0,"basalt",.40)
			_box(pos+Vector3(0,9.4,0),Vector3(1.4,.5,1.4),"edge")
			if i<3:
				_box(pos+Vector3(side*1.7,9.9,0),Vector3(3.4,.45,1.5),"basalt")
	var water := PlaneMesh.new()
	water.size=Vector2(170,180)
	_instance("RiverStyx",water,Vector3(5.5,-1.05,-30),_animated("res://shaders/menu_water.gdshader"))

func _gateway() -> void:
	# Sixteen wide steps and a rock-supported platform.
	_gbox(Vector3(0,.55,-1),Vector3(22,1.0,14),"basalt",Vector3.ZERO,.16)
	for i in 14:
		var rise := .16*float(i+1)
		_gbox(Vector3(0,rise*.5,10.0-i*.63),Vector3(15.8,rise,.68),"floor")
		# Worn pale stair noses pick up both moonlight and the portal spill.
		_gbox(Vector3(0,rise-.035,10.26-i*.63),Vector3(15.85,.065,.14),"edge",Vector3.ZERO,.015)
	for side in [-1.0,1.0]:
		for row in 12:
			for block in 2:
				var x: float = side*6.3+(block-.5)*1.78
				_gbox(Vector3(x,2.65+row*1.23,-.1),Vector3(1.74,1.18,3.5),"basalt",Vector3.ZERO,.065)
		for y in [2.2,3.0,15.5,16.2]:
			_gbox(Vector3(side*6.3,y,-.1),Vector3(4.35,.36,4.1),"edge")
		# Fluted engaged columns and deep bronze rings.
		_column(ORIGIN+Vector3(side*6.25,3.0,2.0),12.3,.68)
		_gbox(Vector3(side*6.3,17.2,-.2),Vector3(4.45,1.5,4.3),"basalt")
		_gbox(Vector3(side*6.3,18.1,-.2),Vector3(4.9,.36,4.7),"edge")
		_gbox(Vector3(side*6.3,19.0,-.2),Vector3(3.5,1.5,3.7),"basalt")
		_gbox(Vector3(side*6.3,19.9,-.2),Vector3(4.1,.28,4.3),"edge")
		_gbox(Vector3(side*6.3,20.55,-.2),Vector3(2.6,1.0,2.6),"basalt")
	# Radially cut voussoirs: real hollow arch, not a solid prism over a glowing rectangle.
	for i in 23:
		var a := float(i)*PI/23.0+.012
		var b := float(i+1)*PI/23.0-.012
		_arch_stone(a,b,4.65,5.6,13.8,2.1,"edge")
		_arch_stone(a,b,5.62,5.96,13.8,2.28,"bronze")
	_gbox(Vector3(0,20.35,0),Vector3(8.75,1.05,3.2),"basalt")
	_gbox(Vector3(0,21.02,0),Vector3(9.5,.3,3.7),"edge")
	# Greek key frieze, built as small relief blocks instead of a flat decal.
	for i in 18:
		var x: float = -7.5+i*.87
		if absf(x)<4.9: continue
		_gbox(Vector3(x,16.0,1.94),Vector3(.64,.07,.065),"bronze",Vector3.ZERO,.01)
		_gbox(Vector3(x-.28,16.21,1.94),Vector3(.07,.48,.065),"bronze",Vector3.ZERO,.01)
		_gbox(Vector3(x,16.43,1.94),Vector3(.64,.07,.065),"bronze",Vector3.ZERO,.01)
		_gbox(Vector3(x+.28,16.30,1.94),Vector3(.07,.30,.065),"bronze",Vector3.ZERO,.01)
	# Keystone medallion and Hades' bident, a restrained emblem of the underworld.
	_cylinder(ORIGIN+Vector3(0,20.1,1.8),.86,.20,"bronze",-1,Vector3(PI*.5,0,0))
	_cylinder(ORIGIN+Vector3(0,20.1,1.92),.70,.12,"basalt",-1,Vector3(PI*.5,0,0))
	_gbox(Vector3(0,20.12,2.02),Vector3(.10,1.15,.09),"bronze",Vector3.ZERO,.015)
	for side in [-1.0,1.0]:
		_gbox(Vector3(side*.25,20.45,2.02),Vector3(.10,.65,.09),"bronze",Vector3.ZERO,.015)
	_gbox(Vector3(0,20.14,2.02),Vector3(.55,.10,.09),"bronze",Vector3.ZERO,.015)
	var doorway := QuadMesh.new()
	doorway.size=Vector2(9.3,16.2)
	_instance("LivingPortal",doorway,ORIGIN+Vector3(0,10.3,.4),_animated("res://shaders/login_portal.gdshader"))

func _column(pos: Vector3, height: float, radius: float) -> void:
	_box(pos+Vector3(0,.24,0),Vector3(radius*2.7,.48,radius*2.7),"edge")
	_cylinder(pos+Vector3(0,.62,0),radius*1.14,.32,"bronze")
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 14
	var segments := 144
	for y in rings:
		for a in segments:
			var points: Array[Vector3] = []
			for pair in [Vector2(a,y),Vector2(a+1,y),Vector2(a+1,y+1),Vector2(a,y+1)]:
				var f: float = pair.y/float(rings)
				var angle: float = pair.x/float(segments)*TAU
				var r: float = radius*(1.0-f*.14+sin(f*PI)*.025)*(1.0-.09*(.5+.5*cos(angle*24.0)))
				points.append(Vector3(sin(angle)*r,.8+f*(height-1.5),cos(angle)*r))
			for index in [0,2,1,0,3,2]:
				tool.set_uv(Vector2(points[index].x,points[index].y))
				tool.set_color(Color.WHITE)
				tool.add_vertex(points[index])
	tool.generate_normals()
	tool.index()
	_batch(tool.commit(),Transform3D(Basis.IDENTITY,pos),"edge")
	_cylinder(pos+Vector3(0,height-.6,0),radius*1.16,.32,"bronze")
	_box(pos+Vector3(0,height-.25,0),Vector3(radius*2.9,.5,radius*2.9),"edge")

func _arch_stone(a: float, b: float, inner: float, outer: float, spring: float, front: float, key: String) -> void:
	var points: Array[Vector3] = []
	for z in [-1.6,front]:
		for p in [Vector2(cos(a)*inner,sin(a)*inner),Vector2(cos(b)*inner,sin(b)*inner),Vector2(cos(b)*outer,sin(b)*outer),Vector2(cos(a)*outer,sin(a)*outer)]:
			points.append(Vector3(p.x,p.y+spring,z))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3.ZERO
	for p in points:
		center+=p/8.0
	for ids in [[0,1,2,3],[7,6,5,4],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]]:
		var face: Array[Vector3] = []
		for id in ids:
			face.append(points[id]-center)
		# Center each block for the outward normal test.
		_face(tool,face,Color(.91,.89,.84))
	tool.index()
	_batch(tool.commit(),Transform3D(Basis.IDENTITY,ORIGIN+center),key)

func _guardian(side: float) -> void:
	var p := ORIGIN+Vector3(side*8.2,2.1,5.0)
	_box(p+Vector3(0,.3,0),Vector3(3.2,.6,3.2),"basalt")
	_box(p+Vector3(0,.82,0),Vector3(3.0,.28,3.0),"edge")
	# Reuse the authored crowned Hades sculpture, including its anatomical face,
	# beard, hands and draped chiton, as a stone sentinel. Source GLB is untouched.
	var statue: Node3D=load("res://assets/menu/hades_guardian.glb").instantiate()
	var pose := Transform3D(Basis(Vector3.UP,PI-side*.15).scaled(Vector3.ONE*1.37),p+Vector3(0,.98,0))
	_statue_meshes(statue,pose)
	statue.free()
	_light("GuardianRim",p+Vector3(-side*.5,5.0,-2.0),Color(.20,.48,.55),2.8,7.0)

func _statue_meshes(node: Node, parent_pose: Transform3D) -> void:
	var pose := parent_pose
	if node is Node3D:
		pose=parent_pose*node.transform
	if node is MeshInstance3D:
		_batch(node.mesh,pose,"statue")
	for child in node.get_children():
		_statue_meshes(child,pose)

func _approach() -> void:
	# A broken causeway over the Styx, laid as individual worn slabs.
	for row in 12:
		for col in 7:
			var pos := Vector3(5.5+(col-3)*1.82,-.10,9.0+row*1.65)
			_box(pos,Vector3(1.78,.35,1.59),"floor",Vector3(0,rng.randf_range(-.007,.007),0),.07)
	for side in [-1.0,1.0]:
		for i in 5:
			var p := Vector3(5.5+side*6.65,.0,10+i*3.5)
			_box(p+Vector3(0,.3,0),Vector3(.75,.6,.75),"basalt")
			_box(p+Vector3(0,.9,0),Vector3(.42,.8,.42),"edge")
			_box(p+Vector3(0,1.36,0),Vector3(.7,.18,.7),"edge")
		for i in 13:
			_rock(ORIGIN+Vector3(side*rng.randf_range(9,14),-.25,rng.randf_range(1,28)),Vector3(rng.randf_range(.3,1.3),rng.randf_range(.2,.6),rng.randf_range(.4,1.4)),rng.randf()*TAU)
		_brazier(ORIGIN+Vector3(side*5.55,1.0,9.2),int(side+1))
		_brazier(ORIGIN+Vector3(side*7.25,.2,19.0),int(side+3))
	# Broken column fragments provide readable human-scale detail in the foreground.
	_cylinder(Vector3(-5.3,.35,18.0),.7,4.4,"edge",.58,Vector3(0,.45,PI*.5))
	_box(Vector3(-7.0,.2,20),Vector3(1.5,.6,1.5),"edge",Vector3(.08,.2,.13))

func _brazier(pos: Vector3, index: int) -> void:
	_box(pos+Vector3(0,.18,0),Vector3(1.6,.36,1.6),"basalt")
	_cylinder(pos+Vector3(0,.9,0),.55,1.3,"edge",.38)
	_cylinder(pos+Vector3(0,1.58,0),.75,.28,"bronze",.83)
	_cylinder(pos+Vector3(0,1.75,0),.67,.12,"coal")
	for i in 8:
		var a := i*TAU/8.0
		_cylinder(pos+Vector3(sin(a)*.77,1.94,cos(a)*.77),.033,.64,"bronze",.009)
	var flame := _animated("res://shaders/menu_flame.gdshader")
	flame.set_shader_parameter("offset",float(index)*1.37)
	var quad := QuadMesh.new()
	quad.size=Vector2(1.75,2.6)
	_instance("BrazierFlame",quad,pos+Vector3(0,2.68,0),flame)
	var cross := _instance("BrazierFlameCross",quad,pos+Vector3(0,2.68,0),flame)
	cross.rotation.y=PI*.5
	var light := _light("Firelight",pos+Vector3(0,2.2,0),Color(1.0,.37,.095),3.4,9.0)
	fire_lights.append(light)
	_particles(pos+Vector3(0,1.85,0),44,Vector3(.6,.05,.6),Color(1.0,.33,.035),false)

func _instance(label: String, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=label
	node.mesh=mesh
	node.position=pos
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	mesh_instances+=1
	return node

func _particles(pos: Vector3, amount: int, area: Vector3, color: Color, souls: bool) -> void:
	var particles := GPUParticles3D.new()
	particles.name="WanderingSouls" if souls else "FireEmbers"
	particles.position=pos
	particles.amount=amount
	particles.lifetime=8.0 if souls else 3.8
	particles.preprocess=particles.lifetime
	particles.visibility_aabb=AABB(-area-Vector3(3,2,3),area*2.0+Vector3(6,12,6))
	var process := ParticleProcessMaterial.new()
	process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents=area
	process.direction=Vector3(.15,1.0,0)
	process.spread=35.0
	process.initial_velocity_min=.12 if souls else .6
	process.initial_velocity_max=.35 if souls else 1.7
	process.gravity=Vector3(.04,.05,0)
	process.scale_min=.65
	process.scale_max=1.35
	var gradient := Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.16,.6,1])
	gradient.colors=PackedColorArray([Color(color,0),Color(color,.8),Color(color,.5),Color(color,0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient=gradient
	process.color_ramp=ramp
	particles.process_material=process
	var m := StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo=true
	m.albedo_color=Color(1.5,1.5,1.5)
	var mesh := SphereMesh.new()
	mesh.radius=.025 if souls else .015
	mesh.height=mesh.radius*2.0
	mesh.radial_segments=8
	mesh.rings=4
	mesh.material=m
	particles.draw_pass_1=mesh
	particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)

func _atmosphere() -> void:
	for i in 7:
		var mist := _animated("res://shaders/menu_mist.gdshader")
		mist.set_shader_parameter("offset",float(i)*2.77)
		mist.set_shader_parameter("tint",Color(.19,.28,.31,.12 if i<4 else .075))
		var plane := QuadMesh.new()
		plane.size=Vector2(65,5.0)
		_instance("DriftingMist",plane,Vector3(4,1.0,-28+i*8),mist)
	_particles(ORIGIN+Vector3(0,8,2.0),100,Vector3(4.3,6.0,1.0),Color(.20,.60,.58),true)

func _soul_paths() -> void:
	for i in 5:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in 120:
			for sample in [Vector2(0,0),Vector2(1,1),Vector2(1,0),Vector2(0,0),Vector2(0,1),Vector2(1,1)]:
				var t: float = (segment+sample.y)/120.0
				var a: float = t*TAU*1.15+i*TAU/5.0
				var radius := 10.0*(1.0-t)+.2
				var pos := Vector3(cos(a)*radius,3.8+t*4.4+sin(t*PI)*1.6,sin(a)*radius*.4+3.0+(1.0-t)*5.0)
				pos.y+=(sample.x-.5)*.11
				tool.set_normal(Vector3.FORWARD)
				tool.set_uv(Vector2(sample.x,t))
				tool.add_vertex(pos)
		var material := _animated("res://shaders/menu_soul.gdshader")
		material.set_shader_parameter("phase",float(i)*.19)
		tool.index()
		_instance("SoulTrail",tool.commit(),ORIGIN,material)

func _process(delta: float) -> void:
	if portal_light == null or frozen:
		return
	scene_time+=delta
	for material in animated_materials:
		material.set_shader_parameter("scene_time",scene_time)
	portal_light.light_energy=5.0+sin(scene_time*1.3)*.28+sin(scene_time*3.7)*.12
	for i in fire_lights.size():
		fire_lights[i].light_energy=3.4+sin(scene_time*7.0+i*2.17)*.32+sin(scene_time*11.3+i)*.16

func set_review_time(value: float) -> void:
	frozen=true
	scene_time=value
	for material in animated_materials:
		material.set_shader_parameter("scene_time",value)
	camera.set_process(false)
	camera.position=camera.origin_pos
	camera.rotation=camera.origin_rot
