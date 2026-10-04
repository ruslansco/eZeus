extends SubViewportContainer
# A self-contained, cosmetic regional globe. No simulation cells, collisions,
# navigation, game RNG or city ownership exist here. Native UVs are the anchors.
signal camera_changed

# A flight drives the camera, but sea/cloud/ship animation keeps running.
var cinematic := false
const EXTENT := Vector2(32.0,28.18)
const RADIUS := 100.0
const GRID := Vector2i(256,226)
const Marker = preload("res://ui/world_marker.gd")
var viewport: SubViewport
var scene: Node3D
var camera: Camera3D
var terrain: MeshInstance3D
var ocean: MeshInstance3D
var cloud_root: Node3D
var city_root: Node3D
var fields: Image
var field_texture: Texture2D
var map_key := ""
var pins: Dictionary = {}
var selected := -1
var beacon: MeshInstance3D
var active := false
var built := false
var yaw := 0.0
var pitch := 1.03
var distance := 40.0
var desired_distance := 40.0
var target := Vector3.ZERO
var dragging := false
var pan_drag := false
var clock := 0.0
var clouds: Array = []
var ships: Array = []
var land_meshes: Dictionary = {}
var tree_mesh: Mesh
var landmark: Mesh
var build_ms := 0
var geometry_triangles := 0

func _ready() -> void:
	stretch=true
	mouse_filter=Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport=SubViewport.new()
	viewport.name="AtlasViewport"
	viewport.own_world_3d=true
	viewport.msaa_3d=Viewport.MSAA_2X
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport)
	scene=Node3D.new()
	scene.name="LivingAtlas"
	viewport.add_child(scene)
	camera=Camera3D.new()
	camera.name="AtlasCamera"
	camera.fov=43
	camera.near=.15
	camera.far=260
	scene.add_child(camera)
	camera.current=true
	_environment()
	city_root=Node3D.new()
	city_root.name="CityLandmarks"
	scene.add_child(city_root)
	resized.connect(func(): refresh_camera(); camera_changed.emit())
	set_process(false)

func _environment() -> void:
	var world:=WorldEnvironment.new()
	world.name="WorldEnvironment"
	var env:=Environment.new()
	env.background_mode=Environment.BG_SKY
	env.background_color=Color(.023,.075,.11)
	var sky:=Sky.new()
	var air:=ProceduralSkyMaterial.new()
	air.sky_top_color=Color(.06,.15,.23)
	air.sky_horizon_color=Color(.35,.48,.51)
	air.ground_horizon_color=Color(.35,.48,.51)
	air.ground_bottom_color=Color(.025,.075,.11)
	sky.sky_material=air
	env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.55,.68,.72)
	env.ambient_light_energy=.4
	env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure=1.1
	env.glow_enabled=true
	env.glow_intensity=.5
	env.glow_hdr_threshold=1.3
	env.fog_enabled=true
	env.fog_density=.003
	env.fog_light_color=Color(.075,.19,.22)
	env.fog_sky_affect=0
	env.ssr_enabled=false
	env.ssao_enabled=false
	env.volumetric_fog_enabled=false
	world.environment=env
	scene.add_child(world)
	var sun:=DirectionalLight3D.new()
	sun.name="AegeanSun"
	sun.rotation_degrees=Vector3(-43,-38,0)
	sun.light_color=Color(1,.85,.61)
	sun.light_energy=1.25
	sun.shadow_enabled=true
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance=60
	scene.add_child(sun)

func set_active(value: bool) -> void:
	active=value
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
	set_process(value)
	if not value: dragging=false

func configure(world: Dictionary) -> void:
	var key:="greece" if int(world.map)<10 else "poseidon%d"%(int(world.map)-9)
	# Native enum has eight Greece plates and four Poseidon maps.
	if String(world.image).begins_with("Poseidon"):
		key="poseidon%d"%int(String(world.image).trim_prefix("Poseidon_map").get_slice(".",0))
	if key!=map_key:
		map_key=key
		var start:=Time.get_ticks_msec()
		field_texture=load("res://assets/world/%s.png"%key)
		fields=field_texture.get_image()
		_build_landscape()
		build_ms=Time.get_ticks_msec()-start
		reset_view()
	update_cities(world.get("cities",[]))
	built=true
	refresh_camera()

func curved(x: float,z: float) -> float:
	return sqrt(maxf(1.0,RADIUS*RADIUS-x*x-z*z))-RADIUS

func sample(uv: Vector2) -> Color:
	var at:=uv.clamp(Vector2.ZERO,Vector2.ONE)*Vector2(fields.get_width()-1,fields.get_height()-1)
	var x:=int(at.x); var y:=int(at.y)
	return fields.get_pixel(x,y).lerp(fields.get_pixel(mini(x+1,fields.get_width()-1),y),at.x-x).lerp(
		fields.get_pixel(x,mini(y+1,fields.get_height()-1)).lerp(fields.get_pixel(mini(x+1,fields.get_width()-1),mini(y+1,fields.get_height()-1)),at.x-x),at.y-y)

func surface_point(uv: Vector2, lift:=0.0) -> Vector3:
	var p:=(uv-Vector2(.5,.5))*EXTENT
	return Vector3(p.x,curved(p.x,p.y)+sample(uv).r*3.6-.055+lift,p.y)

func project(uv: Vector2, lift:=.12) -> Vector2:
	return camera.unproject_position(surface_point(uv,lift))

func _mesh_grid(count: Vector2i, span: Vector2, land: bool) -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in count.y+1:
		for x in count.x+1:
			var uv:=Vector2(float(x)/count.x,float(z)/count.y)
			var p:=(uv-Vector2(.5,.5))*span
			var height:=curved(p.x,p.y)
			if land: height+=sample(uv).r*3.6-.055
			surface.set_uv(uv)
			surface.add_vertex(Vector3(p.x,height,p.y))
	for z in count.y:
		for x in count.x:
			var a:=z*(count.x+1)+x
			for i in [a,a+count.x+1,a+1,a+1,a+count.x+1,a+count.x+2]: surface.add_index(i)
	surface.generate_normals()
	return surface.commit()

func _build_landscape() -> void:
	for node in [terrain,ocean,cloud_root]:
		if is_instance_valid(node): node.free()
	for ship in ships:
		if is_instance_valid(ship.node): ship.node.free()
	ships.clear(); clouds.clear()
	var old:=scene.get_node_or_null("AtlasWoodland")
	if old!=null: old.free()
	terrain=MeshInstance3D.new()
	terrain.name="GreekRelief"
	if not land_meshes.has(map_key): land_meshes[map_key]=_mesh_grid(GRID,EXTENT,true)
	terrain.mesh=land_meshes[map_key]
	var stone:=ShaderMaterial.new()
	stone.shader=load("res://shaders/atlas_land.gdshader")
	stone.set_shader_parameter("fields",field_texture)
	terrain.material_override=stone
	scene.add_child(terrain)
	ocean=MeshInstance3D.new()
	ocean.name="LivingAegean"
	var globe:=SphereMesh.new()
	globe.radius=RADIUS;globe.height=RADIUS*2
	globe.radial_segments=128;globe.rings=64
	ocean.mesh=globe
	ocean.position.y=-RADIUS
	var sea:=ShaderMaterial.new()
	sea.shader=load("res://shaders/atlas_ocean.gdshader")
	sea.set_shader_parameter("fields",field_texture)
	ocean.material_override=sea
	ocean.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(ocean)
	_woodland()
	_clouds()
	_ships()
	geometry_triangles=GRID.x*GRID.y*2+128*64*2+1600*24+12*2+7*92

func _woodland() -> void:
	if tree_mesh==null:
		var tree:=CylinderMesh.new()
		tree.top_radius=0; tree.bottom_radius=.035; tree.height=.19
		tree.radial_segments=8; tree.rings=1
		var finish:=StandardMaterial3D.new()
		finish.albedo_color=Color(.075,.17,.095)
		finish.roughness=1
		tree.material=finish
		tree_mesh=tree
	var wood:=MultiMeshInstance3D.new()
	wood.name="AtlasWoodland"
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=tree_mesh
	var places:Array[Vector3]=[]
	var rng:=RandomNumberGenerator.new()
	rng.seed=0x41454745414e
	for i in 4500:
		var uv:=Vector2(rng.randf(),rng.randf())
		var data:=sample(uv)
		if data.b>.96 and data.a>.45 and data.r*3.6>.2 and data.r*3.6<1.2 and places.size()<1600:
			places.append(surface_point(uv,.065))
	multi.instance_count=places.size()
	for i in places.size(): multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,places[i]))
	wood.multimesh=multi
	wood.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(wood)

func _clouds() -> void:
	cloud_root=Node3D.new()
	cloud_root.name="DriftingClouds"
	scene.add_child(cloud_root)
	for i in 12:
		var cloud:=MeshInstance3D.new()
		var plane:=PlaneMesh.new()
		plane.size=Vector2(5+sin(i*2.4)*1.5,3+cos(i*1.7))
		cloud.mesh=plane
		var material:=ShaderMaterial.new()
		material.shader=load("res://shaders/atlas_cloud.gdshader")
		material.set_shader_parameter("seed",float(i)*13.7)
		cloud.material_override=material
		cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var origin:=Vector3(sin(i*2.39)*17,4.1+sin(i)*.4,cos(i*1.67)*16)
		cloud.position=origin
		cloud_root.add_child(cloud)
		clouds.append({"node":cloud,"origin":origin,"phase":float(i)*.71})

func _ships() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=0x5341494c
	var hull_finish:=StandardMaterial3D.new()
	hull_finish.albedo_color=Color(.22,.13,.055)
	var sail_finish:=StandardMaterial3D.new()
	sail_finish.albedo_color=Color(.91,.83,.62)
	sail_finish.cull_mode=BaseMaterial3D.CULL_DISABLED
	for attempt in 90:
		var uv:=Vector2(rng.randf_range(.08,.92),rng.randf_range(.08,.92))
		if sample(uv).g>.01 or ships.size()>=7: continue
		var ship:=Node3D.new()
		ship.name="DecorativeSailboat"
		var hull:=MeshInstance3D.new()
		var keel:=SphereMesh.new()
		keel.radius=.08; keel.height=.12; keel.radial_segments=12; keel.rings=4
		hull.mesh=keel; hull.scale=Vector3(.8,.55,2.4); hull.material_override=hull_finish
		ship.add_child(hull)
		var sail:=MeshInstance3D.new()
		var fabric:=QuadMesh.new()
		fabric.size=Vector2(.19,.24)
		sail.mesh=fabric; sail.position.y=.16; sail.rotation.y=PI*.5; sail.material_override=sail_finish
		ship.add_child(sail)
		ship.position=surface_point(uv,.08)
		ship.rotation.y=float(attempt)
		scene.add_child(ship)
		ships.append({"node":ship,"uv":uv,"phase":float(attempt)})

func _landmark_mesh() -> Mesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	_box(st,Vector3(0,.035,0),Vector3(.7,.07,.55),Color(.74,.66,.49))
	_box(st,Vector3(0,.09,0),Vector3(.61,.06,.46),Color(.87,.79,.61))
	for x in [-.24,-.08,.08,.24]:
		for z in [-.16,.16]: _box(st,Vector3(x,.26,z),Vector3(.045,.29,.045),Color(.87,.81,.68))
	_box(st,Vector3(0,.43,0),Vector3(.62,.075,.46),Color(.9,.76,.43,.2))
	# Pitched pediment and roof, rather than a flat stack of boxes.
	var roof:=[Vector3(-.34,.46,-.25),Vector3(.34,.46,-.25),Vector3(0,.62,-.25),Vector3(-.34,.46,.25),Vector3(.34,.46,.25),Vector3(0,.62,.25)]
	for face in [[0,2,1],[3,4,5],[0,3,5],[0,5,2],[1,2,5],[1,5,4]]:
		for index in face:
			st.set_color(Color(.65,.4,.19,.2));st.set_uv(Vector2.ZERO);st.add_vertex(roof[index])
	_box(st,Vector3(.45,.10,.32),Vector3(.18,.20,.20),Color(.76,.66,.48))
	_box(st,Vector3(.45,.23,.32),Vector3(.23,.07,.25),Color(.65,.4,.19,.2))
	_box(st,Vector3(-.29,.09,.34),Vector3(.21,.18,.20),Color(.79,.69,.51))
	_box(st,Vector3(-.29,.20,.34),Vector3(.24,.06,.25),Color(.65,.4,.19,.2))
	_box(st,Vector3(-.38,.42,.0),Vector3(.016,.78,.016),Color(.54,.35,.13))
	# A small flag is the only moving landmark geometry; UV.y marks the cloth.
	for i in [0,1,2,0,2,3]:
		var points:=[Vector3(-.38,.74,0),Vector3(-.13,.71,0),Vector3(-.13,.55,0),Vector3(-.38,.57,0)]
		st.set_color(Color(.9,.76,.43,.2)); st.set_uv(Vector2(float(i%3)/2,2)); st.set_normal(Vector3.FORWARD); st.add_vertex(points[i])
	st.index(); st.generate_normals()
	var mesh:=st.commit()
	var finish:=ShaderMaterial.new()
	finish.shader=load("res://shaders/atlas_city.gdshader")
	mesh.surface_set_material(0,finish)
	return mesh

func _box(st: SurfaceTool,center: Vector3,dimensions: Vector3,color: Color) -> void:
	var verts:Array[Vector3]=[]
	for p in [Vector3(-1,-1,-1),Vector3(1,-1,-1),Vector3(1,1,-1),Vector3(-1,1,-1),Vector3(-1,-1,1),Vector3(1,-1,1),Vector3(1,1,1),Vector3(-1,1,1)]: verts.append(center+p*dimensions*.5)
	for face in [[0,3,2,1],[4,5,6,7],[0,4,7,3],[1,2,6,5],[3,7,6,2],[0,1,5,4]]:
		for index in [0,1,2,0,2,3]:
			st.set_color(color); st.set_uv(Vector2.ZERO); st.add_vertex(verts[face[index]])

func update_cities(cities: Array) -> void:
	for child in city_root.get_children(): child.free()
	pins.clear()
	if landmark==null: landmark=_landmark_mesh()
	for city in cities:
		var pin:=MeshInstance3D.new()
		pin.name="City_%d"%int(city.index)
		pin.mesh=landmark
		var uv:=Vector2(float(city.x),float(city.y))
		pin.position=surface_point(uv,.02)
		var marker:=Marker.new()
		marker.city=city
		var tint:Color=marker.colour()
		marker.free()
		pin.set_instance_shader_parameter("allegiance",tint)
		city_root.add_child(pin)
		pins[int(city.index)]={"node":pin,"uv":uv}
	beacon=MeshInstance3D.new()
	beacon.name="SelectedCityBeacon"
	var circle:=PlaneMesh.new()
	circle.size=Vector2(1.65,1.65)
	beacon.mesh=circle
	var glow:=ShaderMaterial.new()
	glow.shader=load("res://shaders/atlas_beacon.gdshader")
	beacon.material_override=glow
	beacon.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city_root.add_child(beacon)
	select_city(selected)

func select_city(index: int) -> void:
	selected=index
	if beacon==null: return
	beacon.visible=pins.has(index)
	if beacon.visible: beacon.position=surface_point(pins[index].uv,.10)

func reset_view() -> void:
	yaw=0; pitch=1.03; distance=40; desired_distance=40; target=Vector3.ZERO
	refresh_camera()
	camera_changed.emit()

func zoom(factor: float) -> void:
	desired_distance=clampf(desired_distance*factor,12,55)

func refresh_camera() -> void:
	if camera==null: return
	# A narrow map pane retains a useful full-region overview.
	var fit:=maxf(1.0,1.1/maxf(.6,size.x/maxf(1.0,size.y)))
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance*fit
	camera.look_at(target,Vector3.UP)

func _gui_input(event: InputEvent) -> void:
	if not active or cinematic: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom(.88); accept_event()
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom(1/.88); accept_event()
		if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]:
			dragging=event.pressed; pan_drag=event.button_index==MOUSE_BUTTON_RIGHT or event.shift_pressed
			accept_event()
	if event is InputEventMouseMotion and dragging:
		if pan_drag:
			var right:=Vector3(cos(yaw),0,-sin(yaw))
			var forward:=Vector3(sin(yaw),0,cos(yaw))
			target-=right*event.relative.x*distance*.0013+forward*event.relative.y*distance*.0013
			target.x=clampf(target.x,-10,10); target.z=clampf(target.z,-9,9)
		else:
			yaw-=event.relative.x*.004
			pitch=clampf(pitch+event.relative.y*.003,.62,1.38)
		refresh_camera(); camera_changed.emit(); accept_event()
	if event is InputEventMagnifyGesture: zoom(1.0/event.factor); accept_event()
	if event is InputEventPanGesture:
		yaw-=event.delta.x*.012; pitch=clampf(pitch+event.delta.y*.008,.62,1.38)
		refresh_camera(); camera_changed.emit(); accept_event()

func _process(delta: float) -> void:
	clock+=delta
	var changed:=not cinematic and absf(distance-desired_distance)>.005
	if not cinematic: distance=lerpf(distance,desired_distance,1-exp(-delta*9))
	for cloud in clouds:
		cloud.node.position.x=cloud.origin.x+sin(clock*.025+cloud.phase)*2.5
	for ship in ships:
		var uv:Vector2=ship.uv+Vector2(sin(clock*.013+ship.phase),cos(clock*.013+ship.phase))*.008
		if sample(uv).g<.02:
			ship.node.position=surface_point(uv,.075+sin(clock*1.1+ship.phase)*.012)
			ship.node.rotation.z=sin(clock*.8+ship.phase)*.035
	if changed: refresh_camera(); camera_changed.emit()
