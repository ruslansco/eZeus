extends SceneTree
# Small owned Metal fixture: actual imported house batches, no full-city load.
const Batches = preload("res://scripts/building_batches.gd")
var checks := 0
var okay := true
var batches: Node3D
var groups := {}
var folder := ""
var lang := "en"
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("HOUSE_RESIDENT_REVIEW_CHECK ","PASS " if value else "FAIL ",label)
func capture(label: String) -> Image:
	for frame in 6: await process_frame
	RenderingServer.force_draw(true,.016)
	var picture := root.get_texture().get_image()
	picture.save_png(folder.path_join("housing-"+label+".png"))
	return picture
func flags(active: bool) -> bool:
	var found := 0
	for group in groups:
		var matches := true
		var dynamic := 0
		for node in batches.group_nodes[group]:
			if node.multimesh.use_custom_data:
				dynamic += 1
				matches = matches and (node.multimesh.get_instance_custom_data(0).r>.5)==active
		if matches and dynamic>0: found+=1
	return found==7
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): lang=arg.trim_prefix("--lang=")
	TranslationServer.set_locale(lang)
	folder=OS.get_environment("EZEUS_HOUSING_REVIEW_DIRECTORY")
	if folder.is_empty(): push_error("Use owned tools/review_housing_art.py wrapper");quit(1);return
	var world := Node3D.new();root.add_child(world)
	var environment := WorldEnvironment.new();var settings := Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(.18,.23,.27)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color(.86,.9,1);settings.ambient_light_energy=.7
	environment.environment=settings;world.add_child(environment)
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.15;sun.shadow_enabled=true;world.add_child(sun)
	var floor := MeshInstance3D.new();var plane := PlaneMesh.new();plane.size=Vector2(28,24)
	var surface := StandardMaterial3D.new();surface.albedo_color=Color(.32,.37,.24);surface.roughness=1.0;plane.material=surface
	floor.mesh=plane;floor.position.y=-.025;world.add_child(floor)
	var camera := Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=13.0;camera.position=Vector3(7,11,14);camera.look_at(Vector3(0,1,0));camera.current=true
	batches=Batches.new();world.add_child(batches)
	var names := ["Hut","Shack","Hovel","Homestead","Tenement","Apartment","Townhouse"]
	for level in 7:
		var asset := "common_house_%da"%level
		var center := Vector3(-4.5+3.0*level,0,2) if level<4 else Vector3(-3+3*(level-4),0,-2)
		var facing := 3 if level in [2,3] else 2
		groups[asset+"|review"]=[{"transform":Transform3D(Basis(Vector3.UP,PI*.5*facing),center),"working":false,"animation_offset":0}]
		var label := Label3D.new();label.text=tr(names[level]);label.position=center+Vector3(0,.1,1.25);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=30;label.pixel_size=.009;world.add_child(label)
	batches.rebuild(groups);check(flags(false),"all seven empty households receive inactive GPU data")
	await capture("residents-empty")
	var nodes: Dictionary=batches.group_nodes.duplicate()
	for group in groups:groups[group][0].working=true
	batches.rebuild(groups)
	check(flags(true) and batches.last_rebuilt==0 and nodes==batches.group_nodes,"first occupant reveals each household without replacing geometry")
	var first_hash := 0
	var moved := false
	for phase in [0,10,20,30]:
		RenderingServer.global_shader_parameter_set("building_work_clock",float(phase))
		var picture: Image=await capture("resident-idle-%02d"%phase)
		if phase==0:first_hash=hash(picture.get_data())
		else:moved=moved or first_hash!=hash(picture.get_data())
	check(moved,"actual rendered household poses change across the four-second loop")
	await capture("residents-occupied")
	for group in groups:groups[group][0].working=false
	batches.rebuild(groups)
	check(flags(false) and batches.last_rebuilt==0,"last occupant departure hides every household without replacing geometry")
	await capture("residents-empty-again")
	print("HOUSE_RESIDENT_REVIEW ","PASS" if okay else "FAIL"," checks=",checks," lang=",lang)
	world.queue_free();await process_frame;await process_frame;quit(0 if okay else 1)
