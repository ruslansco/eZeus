extends SceneTree
# Real renderer and GUI input; only the designated native save, read-only city.
var checks:=0
var okay:=true
var language:="en"
var wm:CanvasLayer
var core:Node
var size:=Vector2i(1600,1000)

func _initialize() -> void: call_deferred("run")
func check(value:bool,description:String) -> void:
	checks+=1;okay=okay and value
	print("ATLAS_CHECK ","PASS " if value else "FAIL ",description)
func frames(count:int=8) -> void:
	for i in count: await process_frame
func click_at(point:Vector2) -> void:
	var motion:=InputEventMouseMotion.new();motion.position=point
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		root.push_input(event,true)
	await frames()
func click(control:Control) -> void: await click_at(control.get_global_rect().get_center())
func safe(node:Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D or node is NavigationLink3D:return false
	for child in node.get_children():
		if not safe(child): return false
	return true
func geometry(node:Node) -> Vector2i:
	var total:=Vector2i.ZERO
	if node is MeshInstance3D and node.mesh!=null: total+=Vector2i(1,node.mesh.get_faces().size()/3)
	if node is MultiMeshInstance3D and node.multimesh!=null: total+=Vector2i(1,node.multimesh.mesh.get_faces().size()/3*node.multimesh.instance_count)
	for child in node.get_children(): total+=geometry(child)
	return total
func capture(suffix:String) -> void:
	await frames(12);await RenderingServer.frame_post_draw
	var output:="res://captures/world-atlas-%s-%s.png"%[language,suffix]
	root.get_texture().get_image().save_png(output)
	print("ATLAS_CAPTURE ",output)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language=arg.get_slice("=",1)
		if arg.begins_with("--size="):
			var values:=arg.get_slice("=",1).split("x");size=Vector2i(int(values[0]),int(values[1]))
	Engine.set_meta("ezeus_language",language)
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"): Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	TranslationServer.set_locale(language)
	root.size=size;root.content_scale_size=Vector2i(1440,900)
	if OS.get_cmdline_user_args().has("--native-ui"):
		await native_ui()
		return
	core=load("res://scripts/core_link.gd").new()
	root.add_child(core);core.set_process(false)
	core.simulation=ClassDB.instantiate("EZeusSimulation")
	var engine:=ProjectSettings.globalize_path("res://..").simplify_path()
	var initial:Dictionary=core.simulation.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),language)
	check(initial.has("protocol"),"designated native city loads")
	wm=load("res://ui/world_map.tscn").instantiate()
	root.add_child(wm)
	check(wm.open(core),"actual world map opens")
	await frames(20)
	var atlas=wm.atlas
	var first_build_ms:int=atlas.build_ms
	var before:Dictionary=core.simulation.snapshot(true)
	var world_before:Dictionary=core.query("world")
	check(atlas.viewport.own_world_3d and atlas.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"independent live 3D viewport")
	check(safe(atlas.scene),"scenery has no physics/navigation authority")
	check(wm.marker_nodes.size()==wm.world.cities.size() and atlas.pins.size()==wm.world.cities.size(),"one projected label and landmark for every native city")
	var align:=true;var visible_count:=0
	for city in wm.world.cities:
		var uv:=Vector2(float(city.x),float(city.y))
		var marker:Control=wm.marker_nodes[int(city.index)]
		align=align and (marker.position+marker.anchor()).distance_to(atlas.project(uv,.78))<.001
		if marker.visible:visible_count+=1
	check(align and visible_count==wm.world.cities.size(),"all overview city anchors preserve native normalized coordinates")
	var budget:=geometry(atlas.scene)
	check(budget.x<=100 and budget.y<220000,"bounded scene: %d meshes / %d triangles"%[budget.x,budget.y])
	var env:Environment=atlas.scene.get_node("WorldEnvironment").environment
	check(not env.ssr_enabled and not env.ssao_enabled and not env.volumetric_fog_enabled,"Mobile uses supported effects")
	check(atlas.clouds.size()==12 and atlas.ships.size()<=7,"bounded decorative clouds and ships")
	await capture("overview")
	var selected_before:int=wm.selected
	var foreign:int=-1
	for city in wm.world.cities:
		if not city.current and city.type=="foreign":foreign=int(city.index);break
	var marker:Control=wm.marker_nodes[foreign]
	await click_at(marker.global_position+marker.anchor()+Vector2(0,16))
	check(wm.selected==foreign and wm.city_name.text==String(wm.find_city(foreign).name),"real label click selects native city and fills diplomacy panel")
	check(wm.gift_button.disabled==not bool(wm.find_city(foreign).can_gift) and wm.raid_button.disabled==not bool(wm.find_city(foreign).can_raid),"economic/military permissions match the native response")
	await click(wm.get_node("%Next"))
	check(wm.selected!=foreign,"real arrow click cycles native cities")
	await click(wm.get_node("%Previous"))
	check(wm.selected==foreign,"previous city restores selection")
	if not wm.request_button.disabled:
		await click(wm.request_button)
		check(wm.dialog!=null and wm.dialog.visible,"native request dialog still opens")
		wm.close_dialog();await frames()
	var zoom_before:float=atlas.desired_distance
	var wheel:=InputEventMouseButton.new()
	wheel.position=atlas.global_position+atlas.size*Vector2(.25,.8);wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true
	root.push_input(wheel,true);await frames(16)
	wheel=wheel.duplicate();wheel.pressed=false;root.push_input(wheel,true)
	check(atlas.desired_distance<zoom_before,"actual mouse wheel zooms the 3D region")
	var yaw_before:float=atlas.yaw
	var point:Vector2=atlas.global_position+atlas.size*Vector2(.25,.8)
	var down:=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
	root.push_input(down,true)
	var motion:=InputEventMouseMotion.new();motion.position=point+Vector2(85,20);motion.relative=Vector2(85,20);motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true)
	down=down.duplicate();down.position=motion.position;down.pressed=false;root.push_input(down,true)
	await frames()
	check(absf(atlas.yaw-yaw_before)>.1,"actual drag orbits the regional globe")
	var anchored:=true
	for city in wm.world.cities:
		var m:Control=wm.marker_nodes[int(city.index)]
		anchored=anchored and (m.position+m.anchor()).distance_to(atlas.project(Vector2(city.x,city.y),.78))<.001
	check(anchored,"labels remain aligned after orbit and zoom")
	await click(wm.get_node("%AtlasFocus"));await frames(45)
	check(atlas.distance<17 and atlas.target.distance_to(atlas.surface_point(Vector2(wm.find_city(wm.selected).x,wm.find_city(wm.selected).y)))<.001,"Focus city flies to the selected native anchor")
	await capture("city")
	await click(wm.get_node("%AtlasOverview"));await frames()
	check(absf(atlas.distance-40)<.001 and atlas.target==Vector3.ZERO and atlas.yaw==0,"Overview restores the full region")
	var cloud_position:Vector3=atlas.clouds[0].node.position
	await frames(30)
	check(atlas.clouds[0].node.position!=cloud_position and atlas.ocean.material_override.shader.code.contains("TIME"),"clouds drift and water animates while native city stays held")
	var viewport_bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
	for button in [wm.get_node("%AtlasOverview"),wm.get_node("%AtlasFocus"),wm.get_node("%AtlasZoomIn"),wm.get_node("%Back")]:
		check(viewport_bounds.encloses(button.get_global_rect()),"control fits viewport: "+button.name)
	# Native army fractions are projected; presentation never invents their progress.
	var a:Dictionary=wm.world.cities[0];var b:Dictionary=wm.world.cities[1]
	wm.armies_layer.set_state([{"from":a.index,"to":b.index,"frac":.4,"reason":"raid","size":2}],wm.world.cities,wm.image_rect())
	check(wm.armies_layer.point(int(a.index)).distance_to(atlas.project(Vector2(a.x,a.y),.18))<.001 and wm.armies_layer.armies[0].frac==.4,"army overlay projects native endpoints/fraction without advancing it")
	wm.place_markers()
	for key in ["poseidon1","poseidon2","poseidon3","poseidon4"]:
		atlas.configure({"map":10,"image":"Poseidon_map%02d.jpg"%int(key.right(1)),"cities":wm.world.cities})
		check(atlas.map_key==key and atlas.fields.get_width()>500 and safe(atlas.scene),key+" retained regional coastline builds safely")
	atlas.configure(wm.world);wm.place_markers();wm.select_city(selected_before)
	await frames()
	var final:Dictionary=core.simulation.snapshot(true)
	check(final.tiles==before.tiles and final.buildings==before.buildings and final.walkers==before.walkers and final.money==before.money and final.time==before.time and core.query("world")==world_before,"camera/selection/animation/reviews preserve the complete native city and world")
	# The designated save is Atlantean. Review the Greece geometry independently,
	# with no invented campaign cities or dealings. Native state is still held.
	wm.markers.visible=false;wm.armies_layer.visible=false
	wm.get_node("Themed/Margin/Row/Side").visible=false
	wm.get_node("%AtlasFocus").visible=false
	wm.get_node("%AtlasTitle").text=tr("The Aegean world")
	wm.get_node("%AtlasCaption").text=tr("Greek coastline · terrain preview")
	atlas.configure({"map":0,"image":"Zeus_MapOfGreece01.JPG","cities":[]})
	atlas.yaw=-.16;atlas.pitch=.88;atlas.refresh_camera()
	await capture("greece")
	wm.get_node("Themed/Margin/Row/Side").visible=true
	wm.get_node("%AtlasFocus").visible=true
	wm.markers.visible=true;wm.armies_layer.visible=true
	atlas.configure(wm.world);wm.place_markers()
	await click(wm.get_node("%Back"))
	check(not wm.visible and not atlas.active and atlas.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Back closes the atlas and disables hidden 3D rendering")
	print("WORLD_ATLAS_REVIEW ",JSON.stringify({"passed":okay,"checks":checks,"language":language,"size":str(size),"meshes":budget.x,"triangles":budget.y,"first_build_ms":first_build_ms,"cached_build_ms":atlas.build_ms,"renderer":RenderingServer.get_current_rendering_method()}))
	wm.free();core.free();await frames(2);quit(0 if okay else 1)

func native_ui() -> void:
	var city=load("res://main.tscn").instantiate()
	root.add_child(city);current_scene=city
	while city.state.is_empty() or city.frame_count<60:await process_frame
	var retained=load("res://scripts/validate_main.gd").new()
	retained.city=city
	var passed:bool=await retained.run_world_checks()
	check(passed,"retained native world UI: requests, gifts, fulfilment, F2/Escape and pause/resume")
	var world_visible:bool=city.world.visible
	var horizon_visible:bool=city.horizon.visible
	var orbit_enabled:bool=city.orbit.enabled
	city.open_world()
	while city.world_flight.busy(): await process_frame
	await frames(8)
	check(not city.world.visible and not city.horizon.visible and not city.orbit.enabled,"covered city geometry and camera are suspended behind the atlas")
	var native_before:Dictionary=city.core.simulation.snapshot(true)
	var key:=InputEventKey.new();key.physical_keycode=KEY_SPACE;key.pressed=true
	root.push_input(key,true);key=key.duplicate();key.pressed=false;root.push_input(key,true)
	await frames(12)
	var native_after:Dictionary=city.core.simulation.snapshot(true)
	check(native_after.paused and native_after.time==native_before.time,"Space cannot restart simulation behind the world map")
	city.world_map.close()
	while city.world_flight.busy(): await process_frame
	await frames(8)
	check(city.world.visible==world_visible and city.horizon.visible==horizon_visible and city.orbit.enabled==orbit_enabled,"closing restores the original city rendering/camera state")
	print("WORLD_ATLAS_REVIEW ",JSON.stringify({"passed":okay,"checks":checks,"retained_world_passed":passed,"language":language,"mode":"native-ui","renderer":RenderingServer.get_current_rendering_method()}))
	city.free();await frames(2);quit(0 if okay else 1)
