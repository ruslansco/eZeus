extends SceneTree
# Actual farm GLB, crop batches and inspector, with presentation-only growth samples.
const Crops = preload("res://scripts/farm_crops.gd")
const Inspector = preload("res://scripts/building_inspector.gd")
const Batches = preload("res://scripts/building_batches.gd")
var checks := 0
var okay := true
var language := "en"
var in_city := false

class Visibility extends RefCounted:
	var shown := true
	func building_visible(_building: Dictionary) -> bool: return shown

class Placement extends Node:
	var building_index := {}
	var overlay_view := Visibility.new()
	var transform := Transform3D.IDENTITY
	func building_draw_transform(_building: Dictionary) -> Transform3D: return transform

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("FARM_REVIEW_CHECK ","PASS " if value else "FAIL ",message)

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func frames(count := 12) -> void:
	for i in count: await process_frame

func capture(label: String) -> void:
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/wheat-%s-%s.png" % [language,label])

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language=argument.get_slice("=",1)
		elif argument=="--city": in_city=true
	load("res://scripts/ui_text.gd").set_language(language)
	if in_city:
		await run_city()
		return
	DisplayServer.window_set_title("Wheat growth • owned review")
	DisplayServer.window_set_size(Vector2i(1440,900))
	var world := Node3D.new(); root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(.47,.55,.57)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(.95,.94,.89)
	environment.environment.ambient_light_energy = .65
	world.add_child(environment)
	var light := DirectionalLight3D.new(); light.rotation_degrees=Vector3(-55,-40,0)
	light.light_energy=1.3; light.shadow_enabled=true; world.add_child(light)
	var floor_mesh := MeshInstance3D.new(); floor_mesh.mesh=PlaneMesh.new()
	floor_mesh.mesh.size=Vector2(30,30)
	var floor_material := StandardMaterial3D.new(); floor_material.albedo_color=Color(.36,.40,.23)
	floor_mesh.material_override=floor_material; world.add_child(floor_mesh)
	var camera := Camera3D.new(); camera.position=Vector3(5,5,-7)
	world.add_child(camera); camera.look_at(Vector3(.6,.25,0)); camera.current=true; camera.fov=32
	var batches := Batches.new(); world.add_child(batches)
	batches.rebuild({"farm|review":[{"transform":Transform3D.IDENTITY}]})
	var crop_layer := Crops.new(); world.add_child(crop_layer)
	var placement := Placement.new(); root.add_child(placement)
	var building := {"id":1,"asset":"farm","x":0,"y":0,"w":3,"h":3,"altitude":0,"orientation":0}
	placement.building_index[1]=building
	var host := Control.new(); host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter=Control.MOUSE_FILTER_IGNORE; host.theme=load("res://ui/lapis_gold.tres"); root.add_child(host)
	var panel := PanelContainer.new(); panel.theme_type_variation="Card"
	panel.position=Vector2(1050,180); panel.size=Vector2(360,0); host.add_child(panel)
	var inspector := Inspector.new(); panel.add_child(inspector)
	var info := {"x":0,"y":0,"target_token":1,"can_edit":false,"production":{"status":"operational","harvest_progress":0,"outputs":[{"resource":64,"count":0,"capacity":8,"overflow":0}],"industries":[]}}
	# A static fixture caption makes the growth samples explicit; no native maturity is granted.
	var caption := Label.new(); caption.position=Vector2(24,24); caption.text="Wheat growth • presentation samples" if language=="en" else "Рост пшеницы • образцы отображения"
	host.add_child(caption)
	RenderingServer.global_shader_parameter_set("building_work_clock",0.0)
	var original_architecture: Array=batches.group_nodes["farm|review"].duplicate()
	var crop := {"id":1,"crop":"wheat","progress":0.0,"fields":5}
	for percent in [0,20,50,85,98]:
		crop.progress=percent*.01
		crop_layer.refresh([crop],placement)
		info.production.harvest_progress=crop.progress
		inspector.show_inspection(info)
		check(crop_layer.nodes.size()==1 and crop_layer.nodes["0:0"].multimesh.instance_count==5,"%d%% renders all five wheat fields in one spatial batch" % percent)
		check(is_equal_approx(crop_layer.nodes["0:0"].multimesh.get_instance_custom_data(0).r,percent*.01),"%d%% GPU instance data matches the observed readiness" % percent)
		check(inspector.harvest_label.text==tr("Harvest readiness: %d%%") % percent and is_equal_approx(inspector.harvest_bar.value,percent),"%d%% translated inspector and crop growth agree" % percent)
		await capture("%02d" % percent)
	check(original_architecture==batches.group_nodes["farm|review"],"all growth samples retain the same original farm architecture")
	var crop_nodes: Array=crop_layer.nodes.values().duplicate()
	crop.progress=.3; crop_layer.refresh([crop],placement)
	check(crop_layer.last_rebuilt==0 and crop_layer.nodes.values()==crop_nodes,"post-harvest regrowth reuses GPU geometry")
	crop.fields=2; crop_layer.refresh([crop],placement)
	check(crop_layer.nodes["0:0"].multimesh.instance_count==2,"native reduced field coverage leaves the remaining furrows bare")
	placement.overlay_view.shown=false; crop_layer.refresh([crop],placement)
	check(crop_layer.nodes.is_empty(),"hidden farm overlays remove wheat alongside their architecture")
	placement.overlay_view.shown=true; crop.fields=5; crop.progress=.85
	for turn in 4:
		placement.transform=Transform3D(Basis(Vector3.UP,turn*PI*.5),Vector3.ZERO)
		batches.rebuild({"farm|review":[{"transform":placement.transform}]})
		crop_layer.refresh([crop],placement)
		for field in 5:
			var position: Vector3=crop_layer.nodes["0:0"].multimesh.get_instance_transform(field).origin
			var expected: Vector3=placement.transform*Vector3(Crops.FIELDS[field].x,.028,-Crops.FIELDS[field].z)
			check(position.is_equal_approx(expected),"facing %d field %d shares the farm's original foundation transform" % [turn,field])
	print("FARM_REVIEW ","PASS" if okay else "FAIL"," checks=",checks)
	world.queue_free(); placement.queue_free(); host.queue_free()
	await process_frame
	quit(0 if okay else 1)

func run_city() -> void:
	DisplayServer.window_set_title("Wheat farm • owned city review")
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var city: Node3D = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count<80: await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.set_process(false)
	city.orbit.enabled=false
	if city.house_card.panel!=null: city.house_card.panel.hide()
	root.warp_mouse(Vector2(10,80))
	var original: Dictionary=city.core.simulation.snapshot(true)
	var farm := {}
	for building in original.buildings:
		for crop in original.farm_crops:
			if int(crop.id)==int(building.id) and crop.crop=="wheat": farm=building; break
		if not farm.is_empty(): break
	if farm.is_empty():
		for tile in original.tiles:
			if int(tile[5])==0 or (int(tile[3])&8)==0: continue
			var quote: Dictionary=city.core.query("preview wheat_farm %d %d 0" % [tile[0],tile[1]])
			if not quote.get("valid",false): continue
			city.core.query("build wheat_farm %d %d 0" % [tile[0],tile[1]])
			for building in city.core.simulation.snapshot(true).buildings:
				if int(building.x)==int(quote.x) and int(building.y)==int(quote.y): farm=building; break
			break
	check(not farm.is_empty(),"native wheat farm found or built only in the designated city held in memory")
	if farm.is_empty(): quit(1); return
	city.core.query("set_priority 0 5")
	city.core.simulation.replay(300,7)
	var state: Dictionary=city.core.simulation.snapshot(true)
	city.receive_state(state)
	var current := {}
	for crop in state.farm_crops:
		if int(crop.id)==int(farm.id): current=crop; break
	check(not current.is_empty() and float(current.progress)>0,"ordinary native ticks grow wheat through the actual game observation path")
	city.set_tool("select")
	city.inspected=Vector2i(int(farm.x),int(farm.y))
	city.refresh_inspection()
	city.orbit.target=city.world_position(farm.x+1,farm.y+1,farm.altitude)
	city.orbit.distance=14; city.orbit.pitch=55; city.orbit.yaw=135; city.orbit.refresh()
	var panel: Node=city.inspector_controls
	check(panel.harvest_label!=null and is_equal_approx(panel.harvest_bar.value,float(current.progress)*100),"live inspector percentage matches the wheat mesh's native progress")
	check(not city.farm_crops.nodes.is_empty(),"normal receive_state creates the crop batches")
	var before: Dictionary=city.core.simulation.replay(0,-1)
	await capture("city-native")
	# Render-only mature sample for visual scale/context; native state remains untouched.
	var fixture: Dictionary=state.duplicate(true)
	for crop in fixture.farm_crops:
		if int(crop.id)==int(farm.id): crop.progress=.85
	city.receive_state(fixture)
	var crop_nodes: Array=city.farm_crops.nodes.values().duplicate()
	var architecture: Array=city.static_batches.group_nodes.values().duplicate()
	var renders: int=city.building_render_updates
	for crop in fixture.farm_crops:
		if int(crop.id)==int(farm.id): crop.progress=.95
	city.receive_state(fixture)
	check(city.building_render_updates==renders and city.static_batches.group_nodes.values()==architecture and city.farm_crops.nodes.values()==crop_nodes,"growth snapshots reuse the live building and crop GPU objects")
	var sample_info: Dictionary=panel.value.duplicate(true)
	sample_info.production.harvest_progress=.95
	panel.show_inspection(sample_info)
	var sample_caption := Label.new()
	sample_caption.position=Vector2(24,72)
	sample_caption.text="Mature wheat • presentation sample" if language=="en" else "Спелая пшеница • образец отображения"
	city.hud.add_child(sample_caption)
	await capture("city-mature-sample")
	sample_caption.queue_free()
	city.receive_state(state)
	city.refresh_inspection()
	check(city.core.simulation.replay(0,-1).save==before.save,"crop samples and panel inspection change no serialized native state or RNG")
	city.core.commands.clear()
	print("FARM_REVIEW ","PASS" if okay else "FAIL"," checks=",checks)
	city.queue_free()
	await process_frame
	quit(0 if okay else 1)
