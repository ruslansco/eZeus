extends "res://scripts/login_scene_3d.gd"
# Photorealistic scenic plate with the retained living portal on a registered 3D
# plane. The composition is art-directed; only ambient effects and UI are realtime.
const PLATE := preload("res://assets/menu/aegean_cinematic_v2.png")
const PORTAL_DISTANCE := preload("res://assets/menu/aegean_portal_distance.png")
# Inner opening measured on the original 1672x941 artwork. Never use viewport UVs.
const APERTURE := Rect2(1194.0/1672.0,204.0/941.0,268.0/1672.0,468.0/941.0)
const DEPTH := 20.0
var plate_node: MeshInstance3D
var portal_node: MeshInstance3D
var last_size := Vector2.ZERO
var image_rect := Rect2()
var view_motion := Vector2.ZERO

func _ready() -> void:
	if not Engine.has_meta("ezeus_menu_review"):
		for arg in OS.get_cmdline_user_args():
			if arg == "--skip-start" or arg == "--validate" or arg.begins_with("--capture=") or arg.begins_with("--bridge-port=") or arg.contains("-review"):
				return
	var started := Time.get_ticks_msec()
	rng.seed = 0x41454745414e
	_environment()
	var material := StandardMaterial3D.new()
	material.albedo_texture = PLATE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate_node = _plane("CinematicBackdrop",material)
	var portal_material := _animated("res://shaders/login_portal.gdshader")
	portal_material.set_shader_parameter("registered_aperture",true)
	portal_material.set_shader_parameter("aperture_distance",PORTAL_DISTANCE)
	portal_material.set_shader_parameter("distance_to_portal_units",256.0*9.2/268.0)
	portal_node = _plane("LivingPortal",portal_material)
	_layout()
	get_viewport().size_changed.connect(_layout)
	geometry_triangles = 4
	mesh_instances = 2
	build_msec = Time.get_ticks_msec()-started

func finish(color: Color, metallic := 0.0, rough := .78) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = rough
	material.vertex_color_use_as_albedo = true
	return material

func _environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("172128")
	# Linear tone mapping preserves the already graded scenic artwork.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("eadcc3")
	env.ambient_light_energy = .55
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "MenuKeyLight"
	sun.rotation_degrees = Vector3(-35,-25,0)
	sun.light_color = Color("ffe0a4")
	sun.light_energy = .8
	add_child(sun)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(CameraMotion)
	camera.fov = 45
	camera.near = .1
	camera.far = 40
	add_child(camera)
	camera.origin_pos = Vector3.ZERO
	camera.origin_rot = Vector3.ZERO
	camera.float_range_z = 0
	camera.float_range_y = 0
	camera.parallax_pos_scale = Vector2.ZERO
	camera.parallax_rot_scale = Vector2.ZERO
	camera.current = true

func _plane(label: String, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = QuadMesh.new()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera.add_child(node)
	return node

func _place(node: MeshInstance3D, rect: Rect2, depth: float) -> void:
	var a := camera.to_local(camera.project_position(rect.position,depth))
	var b := camera.to_local(camera.project_position(rect.end,depth))
	node.position = (a+b)*.5
	node.mesh.size = Vector2(absf(b.x-a.x),absf(b.y-a.y))

func _layout() -> void:
	if plate_node == null: return
	var size := get_viewport().get_visible_rect().size
	if size.x < 1 or size.y < 1: return
	var aspect := float(PLATE.get_width())/PLATE.get_height()
	var height := maxf(size.y,size.x/aspect)*1.018
	var dimensions := Vector2(height*aspect,height)
	image_rect = Rect2((size-dimensions)*.5+view_motion,dimensions)
	_place(plate_node,image_rect,DEPTH)
	var portal_rect := Rect2(image_rect.position+APERTURE.position*dimensions,APERTURE.size*dimensions)
	_place(portal_node,portal_rect,DEPTH-.04)
	last_size = size

func _process(delta: float) -> void:
	if camera == null: return
	var access := get_node_or_null("/root/UiAccess")
	var reduced: bool = access != null and access.reduced_motion
	camera.set_process(not reduced and not frozen)
	if frozen or reduced:
		if view_motion != Vector2.ZERO:
			view_motion = Vector2.ZERO
			_layout()
		return
	scene_time += delta
	for material in animated_materials:
		material.set_shader_parameter("scene_time",scene_time)
	# Both the plate and its effect share the same cover/crop transform. This
	# bounded drift cannot expose blank borders or detach the portal from its arch.
	view_motion = Vector2(sin(scene_time*.10)*2.0,sin(scene_time*.13)*1.2)
	_layout()

func set_review_time(value: float) -> void:
	frozen = true
	scene_time = value
	view_motion = Vector2.ZERO
	for material in animated_materials:
		material.set_shader_parameter("scene_time",value)
	camera.set_process(false)
	_layout()
