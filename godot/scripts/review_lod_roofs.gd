extends SceneTree
# Captures each named model at several camera distances (the mesh LOD switches with screen size), into
# captures/lod-<tag>-<asset>-<distance>.png. Usage: -- <tag> <asset>...
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := args[0]
	var root := Node3D.new()
	get_root().add_child(root)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -32, 0)
	root.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.35, .5, .3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.8, .8, .8)
	root.add_child(env)
	var camera := Camera3D.new()
	camera.fov = 50
	root.add_child(camera)
	camera.current = true
	get_root().size = Vector2i(900, 500)
	var model: Node3D
	for index in range(1, args.size()):
		model = load("res://assets/models/%s.glb" % args[index]).instantiate()
		root.add_child(model)
		for distance in [8, 30, 70, 130]:
			camera.position = Vector3(0, distance * .7, distance * .7)
			camera.look_at(Vector3(0, 0.5, 0))
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path("res://captures/lod-%s-%s-%d.png" % [tag, args[index], distance])
			get_root().get_texture().get_image().save_png(path)
		model.free()
	quit()
