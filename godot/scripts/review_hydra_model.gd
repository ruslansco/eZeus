extends SceneTree
# Isolated geometry review. Actual city/native combat review is separate.
var world: Node3D
var camera: Camera3D
var hydra: Node3D
var parts: Array = []

func _initialize() -> void:
	call_deferred("run")

func meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children(): meshes(child,out)

func pose(label: String, at := 0) -> void:
	pose_parts(parts,label,at)

func pose_parts(collection: Array, label: String, at := 0) -> void:
	for part in collection:
		for i in part.mesh.get_blend_shape_count():
			var aliases := str(part.mesh.get_blend_shape_name(i)).split("|")
			part.set_blend_shape_value(i, 1.0 if "%s_%02d" % [label,at] in aliases else 0.0)

func shot(label: String, yaw: float, target := Vector3(0,1,-.1), distance := 5.0) -> void:
	camera.position = target + Vector3(sin(deg_to_rad(yaw)),.28,-cos(deg_to_rad(yaw))).normalized()*distance
	camera.look_at(target)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/hydra-model-"+label+".png")

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280,900))
	root.content_scale_size=Vector2i(1280,900)
	world=Node3D.new();root.add_child(world)
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.40,.44,.48)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.7,.78,.88);env.ambient_light_energy=.55
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,145,0);sun.light_energy=1.6;sun.shadow_enabled=true;world.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,-35,0);fill.light_energy=.5;world.add_child(fill)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,30);floor.mesh=plane
	var finish:=StandardMaterial3D.new();finish.albedo_color=Color(.47,.43,.37);finish.roughness=.95;floor.material_override=finish;world.add_child(floor)
	camera=Camera3D.new();camera.fov=36;world.add_child(camera);camera.current=true
	var path: String = "res://captures/hydra-candidate-v1/walker_hydra.glb"
	if "--installed" in OS.get_cmdline_user_args(): path="res://assets/models/walker_hydra.glb"
	if path.begins_with("res://captures/"):
		var document := GLTFDocument.new();var state := GLTFState.new()
		if document.append_from_file(ProjectSettings.globalize_path(path),state) != OK:
			quit(1);return
		hydra=document.generate_scene(state)
	else:
		hydra=load(path).instantiate()
	world.add_child(hydra);meshes(hydra,parts)
	var appearance := preload("res://scripts/character_appearance.gd").new()
	appearance.apply(hydra,"walker_hydra",{"monster":{"revision":"hydra_reference_v1"}})
	pose("idle")
	await shot("three",35)
	await shot("front",0)
	await shot("side",90,Vector3(0,.95,.35),5.4)
	await shot("rear",175,Vector3(0,.95,.35),5.4)
	pose("fight",5);await shot("bite",35)
	pose("fight2",12);await shot("breath",35)
	pose("die",29);await shot("fallen",35,Vector3(0,.45,.1))
	pose("idle")
	var citizen: Node3D = load("res://assets/models/walker_taxcollector.glb").instantiate()
	var god: Node3D = load("res://assets/models/walker_zeus.glb").instantiate()
	citizen.scale=Vector3.ONE*1.12;citizen.position=Vector3(-2.0,0,0);world.add_child(citizen)
	god.position=Vector3(2.0,0,0);world.add_child(god)
	for pair in [[citizen,"walker_taxcollector"],[god,"walker_zeus"]]:
		var collection: Array = [];meshes(pair[0],collection)
		pose_parts(collection,"idle")
		var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % pair[1]))
		appearance.apply(pair[0],pair[1],contract)
	await shot("scale",0,Vector3(0,1.1,.2),8.4)
	print("HYDRA_MODEL_REVIEW PASS")
	quit()
