extends SceneTree
# Isolated studio. Imports candidates directly; never opens or writes a city.
const NAMES := ["cyclops","talos","hector","minotaur","satyr","medusa","maenads","harpies","calydonianboar","cerberus","chimera","sphinx","dragon","echidna","scylla","kraken"]
var parts: Array = []
var camera: Camera3D
var subject: Node3D
var world: Node3D
var label: Label
var output_dir := "res://captures/monsters"
var camera_distance := 6.4

func _initialize() -> void: call_deferred("run")

func collect(node: Node) -> void:
	if node is MeshInstance3D: parts.append(node)
	for child in node.get_children(): collect(child)

func pose(clip: String, frame: int) -> void:
	for part in parts:
		for i in part.mesh.get_blend_shape_count():
			var aliases := str(part.mesh.get_blend_shape_name(i)).split("|")
			part.set_blend_shape_value(i, 1.0 if "%s_%02d" % [clip,frame] in aliases else 0.0)

func capture(name: String, view: String, clip: String, frame: int, yaw: float) -> void:
	pose(clip,frame)
	var target := Vector3(0,1,-.0)
	camera.position=target+Vector3(sin(deg_to_rad(yaw)),.23,-cos(deg_to_rad(yaw))).normalized()*camera_distance
	camera.look_at(target)
	label.text=name.to_upper()+"  /  "+view.to_upper()
	if view == "scale": label.text="CITIZEN  /  "+name.to_upper()+"  /  ZEUS"
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join("%s-%s.png" % [name,view]))

func run() -> void:
	DisplayServer.window_set_size(Vector2i(900,800));root.content_scale_size=Vector2i(900,800)
	var models := "res://captures/monster-candidates-v1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--models="): models = arg.trim_prefix("--models=")
		if arg.begins_with("--output-dir="): output_dir = arg.trim_prefix("--output-dir=")
		if arg.begins_with("--distance="): camera_distance = float(arg.trim_prefix("--distance="))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	world=Node3D.new();root.add_child(world)
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.36,.39,.42)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.75,.80,.89);env.ambient_light_energy=.7
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.environment=env;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,145,0);sun.light_energy=1.6;sun.shadow_enabled=true;world.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,-35,0);fill.light_energy=.6;world.add_child(fill)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,30);floor.mesh=plane
	var finish:=StandardMaterial3D.new();finish.albedo_color=Color(.47,.43,.37);finish.roughness=.95;floor.material_override=finish;world.add_child(floor)
	camera=Camera3D.new();camera.fov=36;world.add_child(camera);camera.current=true
	label=Label.new();label.position=Vector2(24,20);label.add_theme_font_size_override("font_size",26);root.add_child(label)
	var appearance:=preload("res://scripts/character_appearance.gd").new()
	var names: Array = NAMES.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="): names=Array(arg.trim_prefix("--only=").split(","))
	for name in names:
		var asset: String="walker_"+name
		var candidate:=not "--installed" in OS.get_cmdline_user_args()
		var path: String=models.path_join("%s.glb" % asset) if candidate else "res://assets/models/%s.glb" % asset
		var doc:=GLTFDocument.new();var state:=GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path),state)!=OK: quit(1);return
		subject=doc.generate_scene(state);world.add_child(subject);parts.clear();collect(subject)
		appearance.apply(subject,asset,{"monster":{"revision":"monster_reference_v1"}})
		await capture(name,"three","idle",0,30)
		await capture(name,"front","idle",0,0)
		await capture(name,"side","idle",0,90)
		if "--back" in OS.get_cmdline_user_args(): await capture(name,"back","idle",0,180)
		await capture(name,"attack","fight",6,30)
		await capture(name,"fallen","die",29,30)
		if "--scale" in OS.get_cmdline_user_args():
			var comparison: Array = []
			for pair in [["walker_taxcollector",-1.8,1.12],["walker_zeus",1.8,1.0]]:
				var node: Node3D=load("res://assets/models/%s.glb" % pair[0]).instantiate()
				node.position.x=pair[1];node.scale=Vector3.ONE*pair[2];world.add_child(node)
				collect(node);comparison.append(node)
				var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/%s.json" % pair[0]))
				appearance.apply(node,pair[0],contract)
			var distance_before := camera_distance
			camera_distance=8.2
			await capture(name,"scale","idle",0,0)
			camera_distance=distance_before
			for node in comparison: node.free()
		subject.free();parts.clear()
	print("MONSTER_CATALOG_REVIEW PASS ",names.size())
	quit()
