extends "res://scripts/login_scene_3d.gd"
const BAKE := "res://assets/menu/olympian_sanctuary.scn"
const BAKE_MANIFEST := "res://assets/menu/olympian_sanctuary.json"
const BAKE_INPUTS := ["res://scripts/olympian_menu_world.gd", "res://scripts/login_scene_3d.gd", "res://shaders/olympian_finish.gdshader", "res://shaders/olympian_ground.gdshader", "res://shaders/aegean_water.gdshader", "res://shaders/login_portal.gdshader", "res://assets/models/common_house_3a.glb", "res://assets/models/common_house_5a.glb", "res://assets/models/sanctuary_statue_zeus.glb"]
# Original, presentation-only Aegean sanctuary. The inherited portal is retained.
# All randomness is local; the city is a scenic model with no simulation authority.


func _ready() -> void:
	if not Engine.has_meta("ezeus_menu_review"):
		for arg in OS.get_cmdline_user_args():
			if arg == "--skip-start" or arg == "--validate" or arg.begins_with("--capture=") or arg.begins_with("--bridge-port=") or arg.contains("-review"):
				return
	var started := Time.get_ticks_msec()
	rng.seed = 0x4f4c594d505553
	_materials()
	_environment()
	if load_baked_geometry():
		build_msec = Time.get_ticks_msec()-started
		return
	# Reuse the original hollow arch, relief masonry and living flame shader at a human scale.
	_gateway()
	_flush_batches()
	var portal_pose := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.48),Vector3(29,5,5)-ORIGIN*.48)
	for child in get_children():
		if child is MeshInstance3D:
			child.transform = portal_pose * child.transform
	_landscape()
	_sanctuary()
	_city()
	_gardens()
	_flush_batches()
	build_msec = Time.get_ticks_msec()-started

func finish(color: Color, metallic := 0.0, rough := .78) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = rough
	material.vertex_color_use_as_albedo = true
	return material

func _materials() -> void:
	finishes.basalt = finish(Color("bcaa83"))
	finishes.edge = finish(Color("eee1bf"))
	finishes.floor = finish(Color("d5c6a4"))
	finishes.cliff = _stone(Color("c3b58c"),.13,.97)
	finishes.statue = finish(Color("f3e6c8"))
	finishes.bronze = finish(Color("b48b40"),.72,.30)
	finishes.black = finish(Color("153944"))
	finishes.roof = finish(Color("ad5538"))
	finishes.roof_light = finish(Color("cf8050"))
	finishes.leaf = finish(Color("506444"))
	finishes.cypress = finish(Color("304e3b"))
	finishes.trunk = finish(Color("6b5740"))
	finishes.sail = finish(Color("eee2bc"))
	finishes.soil = finish(Color("929568"))
	finishes.mountain = finish(Color("82999b"))
	for entry in [["edge","d0c2a2",0.0],["basalt","ac9871",1.0],["floor","b5a583",0.0],["roof","98442e",1.0],["roof_light","b36943",1.0]]:
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/olympian_finish.gdshader")
		material.set_shader_parameter("tint",Color(entry[1]))
		material.set_shader_parameter("masonry",entry[2])
		finishes[entry[0]] = material

func _environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://shaders/olympian_sky.gdshader")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("adc9db")
	env.ambient_light_energy = .35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = .85
	env.fog_enabled = true
	env.fog_light_color = Color("c8d2cf")
	env.fog_density = .0008
	env.fog_sky_affect = .08
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "AegeanSun"
	sun.rotation_degrees = Vector3(-27,-42,0)
	sun.light_color = Color("ffe3ad")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 150
	add_child(sun)
	portal_light = _light("PortalSpill",Vector3(29,9,8),Color(1,.48,.13),2,8)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(CameraMotion)
	camera.position = Vector3(-3,23,54)
	camera.fov = 49
	camera.near = .1
	camera.far = 650
	add_child(camera)
	camera.look_at(Vector3(4,13,-55))
	camera.origin_pos = camera.position
	camera.origin_rot = camera.rotation
	camera.float_range_z = .10
	camera.float_range_y = .035
	camera.parallax_pos_scale = Vector2(.20,.08)
	camera.parallax_rot_scale = Vector2(.002,.001)
	camera.current = true

func ground_height(x: float, z: float) -> float:
	var coast := -39.0 + sin(z*.033)*11.0
	var land := smoothstep(coast-10.0,coast+14.0,x)
	var hill := 18.0*exp(-pow((x-18.0)/29.0,2.0)-pow((z+72.0)/32.0,2.0))
	return -1.2 + land*(3.3+hill+sin(x*.058+z*.017)*1.4+cos(z*.09)*.8)

func _landscape() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi in 86:
		for xi in 86:
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var x: float = -100+(xi+corner.x)*3
				var z: float = -235+(zi+corner.y)*3
				var y := ground_height(x,z)
				var color := Color("a2a675").lerp(Color("d6c69b"),1.0-smoothstep(-.5,2.4,y))
				color = color.lerp(Color("737f54"),clampf(sin(x*.18)*cos(z*.14)*.3,0,.3))
				tool.set_color(color.srgb_to_linear())
				tool.set_uv(Vector2(x,z)*.04)
				tool.add_vertex(Vector3(x,y,z))
	tool.generate_normals()
	tool.index()
	var land := ShaderMaterial.new()
	land.shader = load("res://shaders/olympian_ground.gdshader")
	finishes.terrain = land
	_batch(tool.commit(),Transform3D.IDENTITY,"terrain")
	var water := PlaneMesh.new()
	water.size = Vector2(1100,1000)
	_instance("AegeanSea",water,Vector3(-100,-.45,-220),_animated("res://shaders/aegean_water.gdshader"))
	# Atmospheric island silhouettes, geometrically separated from the nearer coast.
	for i in 18:
		var p := Vector3(-270+i*32,0,-290-rng.randf_range(0,75))
		mountain(p,Vector3(rng.randf_range(30,58),rng.randf_range(18,42),rng.randf_range(22,44)))
	mountain(Vector3(70,0,-330),Vector3(110,72,65))
	# The cliff of the acropolis supports the whole sanctuary, not a floating temple.
	for i in 16:
		var a := i*TAU/16.0
		_rock(Vector3(18+cos(a)*21,10,-72+sin(a)*18),Vector3(6,8,6),a)

func doric(p: Vector3, height: float, radius: float) -> void:
	_box(p+Vector3(0,.18,0),Vector3(radius*2.7,.36,radius*2.7),"edge")
	_cylinder(p+Vector3(0,height*.5,0),radius,height-.5,"edge",radius*.82)
	_cylinder(p+Vector3(0,height-.45,0),radius*1.28,.3,"edge")
	_box(p+Vector3(0,height-.12,0),Vector3(radius*2.9,.25,radius*2.9),"edge")
	# Faceted fluting with actual recess shadows at foreground viewing distances.
	if height > 6:
		for i in 16:
			var a := i*TAU/16
			_cylinder(p+Vector3(sin(a)*radius*.92,height*.5,cos(a)*radius*.92),radius*.07,height-.9,"floor",radius*.05)

func roof(p: Vector3, width: float, depth: float, rise: float, key := "roof") -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-width*.5,0,-depth*.5)
	var b := Vector3(width*.5,0,-depth*.5)
	var c := Vector3(0,rise,-depth*.5)
	var d := Vector3(-width*.5,0,depth*.5)
	var e := Vector3(width*.5,0,depth*.5)
	var f := Vector3(0,rise,depth*.5)
	for face in [[a,b,c],[d,f,e],[a,c,f,d],[b,e,f,c],[a,d,e,b]]:
		var center := Vector3(0,rise*.33,0)
		var points := []
		for v in face: points.append(v-center)
		_face(tool,points,Color.WHITE)
	tool.index()
	_batch(tool.commit(),Transform3D(Basis.IDENTITY,p+Vector3(0,rise*.33,0)),key)

func temple(p: Vector3, width: float, depth: float, height: float) -> void:
	for i in 3:
		_box(p+Vector3(0,.18+i*.32,0),Vector3(width+3-i*.6,.34,depth+3-i*.6),"edge")
	_box(p+Vector3(0,height*.45,0),Vector3(width*.58,height*.78,depth*.64),"basalt")
	for side in [-1.0,1.0]:
		for i in 6:
			doric(p+Vector3((i/5.0-.5)*(width-.8),1,side*(depth*.5-.4)),height,.34*width/10)
		for i in range(1,10):
			doric(p+Vector3(side*(width*.5-.4),1,(i/10.0-.5)*(depth-.8)),height,.34*width/10)
	_box(p+Vector3(0,height+1.1,0),Vector3(width+.6,.7,depth+.6),"edge")
	_box(p+Vector3(0,height+1.65,0),Vector3(width+1.1,.36,depth+1.1),"floor")
	roof(p+Vector3(0,height+1.85,0),width+1.4,depth+1.4,width*.19)
	# Pale pediment faces and cornice catch the late afternoon sunlight.
	for side in [-1.0,1.0]:
		roof(p+Vector3(0,height+1.86,side*(depth+.95)*.5),width+1.35,.18,width*.19,"edge")
		for i in 13:
			_box(p+Vector3((i/12.0-.5)*width,height+1.18,side*(depth+.64)*.5),Vector3(.14,.48,.09),"bronze",Vector3.ZERO,.01)
	_cylinder(p+Vector3(0,height+1.85+width*.19,0),.16,depth+1.6,"roof_light",-1,Vector3(PI*.5,0,0))

func _sanctuary() -> void:
	# Acropolis: broad enclosure, propylaea, the main temple and a smaller shrine.
	_box(Vector3(18,15.4,-72),Vector3(43,11,35),"basalt",Vector3.ZERO,.2)
	for i in 10:
		_box(Vector3(-3.8,9+i*1.2,-72),Vector3(.3,.10,35),"floor")
		_box(Vector3(18,9+i*1.2,-54.4),Vector3(43,.10,.25),"floor")
	for x in range(0,40,3):
		if x > 9 and x < 20: continue
		doric(Vector3(x,21.2,-55.6),3.6,.23)
		_box(Vector3(x,25,-55.6),Vector3(3.1,.38,2.1),"edge")
	_box(Vector3(18,21,-72),Vector3(44,.35,36),"edge")
	temple(Vector3(20,21.3,-76),18,27,8)
	temple(Vector3(-1,17,-55),8,12,4)
	for i in 22:
		_box(Vector3(14,4+i*.78,-23-i*1.65),Vector3(7,.8,1.72),"floor")
	# Foreground terrace and open colonnade frame the vista.
	_box(Vector3(4,4,27),Vector3(106,2,47),"basalt",Vector3.ZERO,.14)
	for x in range(-42,55,4):
		for z in range(7,51,4):
			_box(Vector3(x,5.02,z),Vector3(3.97,.12,3.97),"floor",Vector3.ZERO,.018)
	for x in range(-38,53,3):
		if x > 19 and x < 37: continue
		_box(Vector3(x,5.9,5),Vector3(.44,1.7,.5),"edge")
		_box(Vector3(x,6.85,5),Vector3(3,.2,.7),"edge")
	for z in [12,23,34]:
		doric(Vector3(25,5,z+13),21,1.0)
	_box(Vector3(25,26.3,36),Vector3(3,.8,29),"edge")
	# Bronze votive bowls and a Zeus sculpture reuse only the retained local model.
	for x in [21.0,37.0]:
		_cylinder(Vector3(x,5.9,10),.65,1.8,"edge",.48)
		_cylinder(Vector3(x,6.9,10),.86,.32,"bronze",1.0)
	var path := "res://assets/models/sanctuary_statue_zeus.glb"
	if ResourceLoader.exists(path):
		var statue: Node3D = load(path).instantiate()
		_statue_meshes(statue,Transform3D(Basis(Vector3.UP,PI).scaled(Vector3.ONE*1.6),Vector3(41,6,3)))
		statue.free()

func _city() -> void:
	var homes: Dictionary = {}
	for x in [-17.0,43.0,65.0]:
		for i in 60:
			var z := -145.0+i*2.1
			var px: float = x+sin(z*.035)*3.5
			_box(Vector3(px,ground_height(px,z)+.035,z),Vector3(2.0,.09,2.2),"floor",Vector3.ZERO,.01)
	for i in 155:
		var x := rng.randf_range(-30,85)
		var z := rng.randf_range(-151,-12)
		if Vector2((x-18)/1.1,z+72).length() < 29 or (absf(x-14)<7 and z > -65): continue
		if absf(x+17-sin(z*.035)*3.5)<3.8 or absf(x-43-sin(z*.035)*3.5)<3.8 or absf(x-65-sin(z*.035)*3.5)<3.8: continue
		var y := ground_height(x,z)
		if y < 1.3: continue
		if z > -65 and i%2 == 0:
			var model := "common_house_3a" if i%4 == 0 else "common_house_5a"
			if not homes.has(model): homes[model] = []
			homes[model].append(Transform3D(Basis(Vector3.UP,float(i%4)*PI*.5).scaled(Vector3.ONE*1.8),Vector3(x,y,z)))
			continue
		var width := rng.randf_range(2.8,5.2)
		var depth := rng.randf_range(3.5,6.5)
		var height := rng.randf_range(1.8,3.5)
		_box(Vector3(x,y+height*.5,z),Vector3(width,height,depth),"basalt")
		roof(Vector3(x,y+height,z),width+.5,depth+.5,width*.26,"roof" if i%3 else "roof_light")
		_box(Vector3(x,y+.7,z+depth*.5+.02),Vector3(.58,1.4,.05),"black")
		for side in [-1,1]:
			_box(Vector3(x+side*width*.3,y+height*.66,z+depth*.5+.03),Vector3(.38,.5,.04),"black")
	for model in homes:
		var source: Node3D = load("res://assets/models/"+model+".glb").instantiate()
		model_batches(source,Transform3D.IDENTITY,homes[model])
		source.free()
	temple(Vector3(49,ground_height(49,-35),-35),10,16,4.5)
	# Harbour piers and linen-sailed boats read as a living coastal civilization.
	for i in 4:
		_box(Vector3(-45-i*5,.3,-60-i*17),Vector3(17,.9,2.2),"basalt")
	for i in 14:
		var p := Vector3(rng.randf_range(-128,-54),.15,rng.randf_range(-185,-12))
		_sphere(p,Vector3(.85,.52,3.1),"trunk")
		_cylinder(p+Vector3(0,2,0),.065,4,"trunk")
		_box(p+Vector3(0,3.8,0),Vector3(3,.07,.09),"trunk")
		_box(p+Vector3(0,2.6,.08),Vector3(2.8,2.3,.04),"sail",Vector3(0,.3,0),.01)

func _gardens() -> void:
	for i in 200:
		var p := Vector3(rng.randf_range(-32,105),0,rng.randf_range(-165,-8))
		p.y = ground_height(p.x,p.z)
		if p.y < 1.2 or Vector2(p.x-18,p.z+72).length() < 27: continue
		tree(p,i%3==0,rng.randf_range(.6,1.25))
	for p in [Vector3(40,5,20),Vector3(-12,5,9),Vector3(19,5,3),Vector3(44,5,-3)]:
		tree(p,false,1.7)

func tree(p: Vector3, slender: bool, s: float) -> void:
	_cylinder(p+Vector3(0,s,0),.12*s,2.1*s,"trunk",.08*s)
	if slender:
		_sphere(p+Vector3(0,2.5*s,0),Vector3(.52,2.3,.52)*s,"cypress")
	else:
		for j in 5:
			var a := j*2.4
			_cylinder(p+Vector3(cos(a)*.48,1.55,sin(a)*.48)*s,.06*s,1.3*s,"trunk",.028*s,Vector3(sin(a)*.7,0,cos(a)*.7))
		var foliage := SurfaceTool.new()
		foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 400:
			var a := rng.randf()*TAU
			var radius := sqrt(rng.randf())*1.8
			var center := Vector3(cos(a)*radius,2.35+rng.randf_range(-.5,.7),sin(a)*radius)
			var side := Vector3(cos(a),.2,sin(a))*.11
			var up := Vector3(-sin(a)*.11,.09,cos(a)*.11)
			var tint := Color("7c8b50").lerp(Color("344f32"),rng.randf())
			for v in [center-side,center+up,center+side,center-side,center+side,center-up]:
				foliage.set_normal(Vector3.UP)
				foliage.set_color(tint.srgb_to_linear())
				foliage.set_uv(Vector2.ZERO)
				foliage.add_vertex(v*s)
		foliage.index()
		if not finishes.has("olive"):
			finishes.olive = finish(Color.WHITE)
			finishes.olive.cull_mode = BaseMaterial3D.CULL_DISABLED
		_batch(foliage.commit(),Transform3D(Basis.IDENTITY,p),"olive")

func _process(delta: float) -> void:
	if camera == null: return
	var access := get_node_or_null("/root/UiAccess")
	var reduced: bool = access != null and access.reduced_motion
	camera.set_process(not reduced and not frozen)
	if reduced:
		camera.position = camera.origin_pos
		camera.rotation = camera.origin_rot
	if frozen or reduced: return
	scene_time += delta
	for material in animated_materials:
		material.set_shader_parameter("scene_time",scene_time)
	portal_light.light_energy = 2.0+sin(scene_time*1.3)*.1

func _sphere(pos: Vector3, size: Vector3, key: String) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	_batch(mesh,Transform3D(Basis.IDENTITY.scaled(size),pos),key)

func _cylinder(pos: Vector3, radius: float, height: float, key: String, top := -1.0, angles := Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 16
	_batch(mesh,Transform3D(Basis.from_euler(angles),pos),key)

func mountain(p: Vector3, size: Vector3) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi in 32:
		for xi in 48:
			for corner in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var x: float = (xi+corner.x)/24.0-1.0
				var z: float = (zi+corner.y)/16.0-1.0
				var envelope := maxf(0,1.0-x*x)*maxf(0,1.0-z*z)
				var ridge := .60+sin(x*9.0+z*3.1+p.x)*.16+sin(x*18.0-z*7.0)*.08+cos(x*32+z*19)*.045
				var y := pow(envelope,1.4)*ridge
				tool.set_color(Color.WHITE)
				tool.set_uv(Vector2(x,z))
				tool.add_vertex(Vector3(x,y,z)*size)
	tool.generate_normals()
	tool.index()
	_batch(tool.commit(),Transform3D(Basis.IDENTITY,p),"mountain")

func model_batches(node: Node, pose: Transform3D, placements: Array) -> void:
	if node is Node3D: pose = pose*node.transform
	if node is MeshInstance3D:
		var batch := MultiMeshInstance3D.new()
		batch.name = "ScenicCourtyardHouses"
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.mesh = node.mesh
		batch.multimesh.instance_count = placements.size()
		for i in placements.size(): batch.multimesh.set_instance_transform(i,placements[i]*pose)
		batch.lod_bias = .65
		add_child(batch)
		mesh_instances += 1
	for child in node.get_children(): model_batches(child,pose,placements)

func load_baked_geometry() -> bool:
	if Engine.has_meta("ezeus_rebuild_menu") or not FileAccess.file_exists(BAKE_MANIFEST) or not ResourceLoader.exists(BAKE): return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BAKE_MANIFEST))
	if not data is Dictionary: return false
	for path in BAKE_INPUTS:
		if data.get("inputs",{}).get(path,"") != FileAccess.get_sha256(path): return false
	var scene: PackedScene = load(BAKE)
	if scene == null: return false
	var geometry := scene.instantiate()
	for child in geometry.get_children():
		geometry.remove_child(child)
		add_child(child)
		if child.name in ["LivingPortal","AegeanSea"] and child.material_override is ShaderMaterial:
			animated_materials.append(child.material_override)
	geometry.free()
	geometry_triangles = int(data.get("triangles",0))
	mesh_instances = int(data.get("batches",0))
	return true
