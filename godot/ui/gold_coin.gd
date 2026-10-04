extends SubViewport
# Original procedural drachma: milled edge, raised rim and embossed lightning.
# One 96px render shared by the HUD; no per-card world or continuous rendering.
func _ready() -> void:
	size = Vector2i(96,96)
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("e7ac32")
	gold.metallic = .65
	gold.roughness = .28
	var relief := StandardMaterial3D.new()
	relief.albedo_color = Color("ffdb70")
	relief.metallic = .5
	relief.roughness = .24
	var model := Node3D.new()
	add_child(model)
	model.rotation_degrees = Vector3(68,-12,-16)
	var disc := CylinderMesh.new()
	disc.top_radius = .9; disc.bottom_radius = .9; disc.height = .16
	disc.radial_segments = 64
	part(model,disc,gold,Vector3.ZERO)
	var rim := TorusMesh.new()
	rim.inner_radius = .76; rim.outer_radius = .87
	rim.rings = 48; rim.ring_segments = 8
	part(model,rim,relief,Vector3(0,.09,0))
	for i in 40:
		var angle := i*TAU/40
		var bead := SphereMesh.new()
		bead.radius = .026; bead.height = .052
		bead.radial_segments = 6; bead.rings = 3
		part(model,bead,relief,Vector3(cos(angle)*.70,.09,sin(angle)*.70))
	var bolt := PackedVector2Array([Vector2(.08,-.56),Vector2(-.32,.06),Vector2(-.04,.06),Vector2(-.13,.53),Vector2(.34,-.16),Vector2(.06,-.16)])
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(bolt)
	for index in indices: mesh.add_vertex(Vector3(bolt[index].x,.125,bolt[index].y))
	mesh.generate_normals()
	relief.cull_mode = BaseMaterial3D.CULL_DISABLED
	part(model,mesh.commit(),relief,Vector3.ZERO)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.15
	camera.position = Vector3(0,0,4)
	add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30,-35,0)
	key.light_energy = 1.8
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20,120,0)
	fill.light_energy = .65
	add_child(fill)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_CLEAR_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = .65
	add_child(world)
	if DisplayServer.get_name() != "headless":
		for frame in 3:
			render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw

	render_target_update_mode = SubViewport.UPDATE_DISABLED

func part(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
