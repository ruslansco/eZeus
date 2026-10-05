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
	DisplayServer.window_move_to_foreground();await frames(12)
	RenderingServer.force_draw(true,.016)
	var output:="res://captures/world-atlas-%s-%s.png"%[language,suffix]
	root.get_texture().get_image().save_png(output)
	print("ATLAS_CAPTURE ",output)

func key(code: int, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code;event.keycode=code;event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func keyboard_checks() -> void:
	DisplayServer.window_move_to_foreground();await frames(8)
	var atlas=wm.atlas
	var bindings=load("res://scripts/key_bindings.gd")
	var selected:int=wm.selected
	for code in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
		atlas.reset_view()
		var start:Vector3=atlas.target
		key(code,true);atlas.keyboard_camera(.2);key(code,false)
		var moved:Vector3=atlas.target-start
		var axis:=Vector3.RIGHT if code in [KEY_D,KEY_RIGHT] else Vector3.LEFT if code in [KEY_A,KEY_LEFT] else Vector3.FORWARD if code in [KEY_W,KEY_UP] else Vector3.BACK
		check(moved.dot(axis)>1 and wm.selected==selected,"held %s pans the camera without cycling cities"%OS.get_keycode_string(code))
	atlas.reset_view();atlas.yaw=PI*.5
	key(KEY_W,true);atlas.keyboard_camera(.2);key(KEY_W,false)
	check(atlas.target.x< -1 and absf(atlas.target.z)<.001,"forward movement follows the camera after a quarter orbit")
	for code in [KEY_Q,KEY_E,KEY_R,KEY_F]:
		atlas.reset_view()
		var yaw:float=atlas.yaw;var pitch:float=atlas.pitch
		key(code,true);atlas.keyboard_camera(.2);key(code,false)
		var change:float=angle_difference(yaw,atlas.yaw) if code in [KEY_Q,KEY_E] else atlas.pitch-pitch
		check(change*(-1 if code in [KEY_Q,KEY_F] else 1)>.05,"held %s has the city-view orbit/tilt direction"%OS.get_keycode_string(code))
	atlas.reset_view();key(KEY_Q,true);key(KEY_E,true)
	check(not atlas.keyboard_camera(.2) and atlas.yaw==0,"opposite held orbit keys cancel")
	key(KEY_Q,false);key(KEY_E,false)
	atlas.reset_view();key(KEY_W,true);atlas.keyboard_camera(.2);key(KEY_W,false)
	var normal:float=atlas.target.z
	atlas.reset_view();key(KEY_SHIFT,true);key(KEY_W,true);atlas.keyboard_camera(.2);key(KEY_W,false);key(KEY_SHIFT,false)
	check(absf(atlas.target.z-normal*2)<.001,"Shift doubles map pan speed")
	var pose:Vector3=atlas.target;var yaw:float=atlas.yaw
	check(not atlas.keyboard_camera(.2) and atlas.target==pose and atlas.yaw==yaw,"releasing keys stops camera movement")
	atlas.reset_view();key(KEY_R,true);atlas.keyboard_camera(10);key(KEY_R,false)
	check(is_equal_approx(atlas.pitch,deg_to_rad(75)),"keyboard tilt stops at the city-view upper limit")
	key(KEY_F,true);atlas.keyboard_camera(10);key(KEY_F,false)
	check(is_equal_approx(atlas.pitch,deg_to_rad(25)),"keyboard tilt stops at the city-view lower limit")
	atlas.reset_view();key(KEY_W,true);atlas.keyboard_camera(100);key(KEY_W,false)
	check(is_equal_approx(atlas.target.z,-atlas.EXTENT.y*.5),"pan remains within regional bounds")
	atlas.reset_view();atlas.cinematic=true;key(KEY_W,true)
	check(not atlas.keyboard_camera(.2) and atlas.target==Vector3.ZERO,"flight blocks held camera keys")
	key(KEY_W,false);atlas.cinematic=false
	wm.open_dialog("Camera input fixture");key(KEY_W,true)
	check(not atlas.keyboard_camera(.2) and atlas.target==Vector3.ZERO,"native diplomacy dialogs block held camera keys")
	key(KEY_W,false);wm.close_dialog();await frames(2)
	var edit:=LineEdit.new();wm.get_node("Themed").add_child(edit);edit.grab_focus();key(KEY_W,true)
	check(not atlas.keyboard_camera(.2) and atlas.target==Vector3.ZERO,"text editing blocks held camera keys")
	key(KEY_W,false);edit.release_focus();edit.free()
	key(KEY_CTRL,true);key(KEY_W,true)
	check(not atlas.keyboard_camera(.2),"command modifiers do not pan the world")
	key(KEY_W,false);key(KEY_CTRL,false)
	key(KEY_W,true);root.focus_exited.emit();await frames(2)
	check(not atlas.keyboard_camera(.2),"losing window focus clears held camera keys")
	key(KEY_W,false)
	check(bool(bindings.assign("pan_forward",KEY_Z).ok),"map uses the shared rebindable city controls")
	key(KEY_Z,true);atlas.keyboard_camera(.2);key(KEY_Z,false)
	check(atlas.target.z< -1,"a rebound city pan key moves the world camera")
	bindings.reset("pan_forward")
	atlas.reset_view()

func water_checks() -> void:
	var atlas=wm.atlas
	# Compare deep sea against the same view with relief hidden. A submerged
	# rectangular land sheet used to change these pixels across the map patch.
	DisplayServer.window_move_to_foreground();await frames(3)
	RenderingServer.force_draw(true,.016)
	var with_land:Image=atlas.viewport.get_texture().get_image()
	atlas.terrain.visible=false
	await frames(2);RenderingServer.force_draw(true,.016)
	var sea_only:Image=atlas.viewport.get_texture().get_image()
	atlas.terrain.visible=true
	var samples:=0;var identical:=0
	for y in range(1,18):
		for x in range(1,20):
			var uv:=Vector2(x/20.0,y/18.0)
			var field:Color=atlas.sample(uv)
			if field.g>.01 or field.b>.01: continue
			var at:=Vector2i(atlas.project(uv,0))
			if at.x<0 or at.y<0 or at.x>=with_land.get_width() or at.y>=with_land.get_height(): continue
			var a:Color=with_land.get_pixelv(at);var b:Color=sea_only.get_pixelv(at)
			var difference:=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
			samples+=1
			if difference<.025: identical+=1
	check(samples>50 and identical>=samples*.95,"deep water stays continuous with relief present (%d/%d rendered samples)"%[identical,samples])
	await frames(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language=arg.get_slice("=",1)
		if arg.begins_with("--size="):
			var values:=arg.get_slice("=",1).split("x");size=Vector2i(int(values[0]),int(values[1]))
	Engine.set_meta("ezeus_language",language)
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"): Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	TranslationServer.set_locale(language)
	root.size=size;root.content_scale_size=Vector2i(1440,900)
	root.grab_focus()
	DisplayServer.window_move_to_foreground()
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
	print("ATLAS_INPUT_DIAGNOSTIC ",{"active":atlas.active,"focus":root.has_focus(),"cinematic":atlas.cinematic,"blocked":atlas.input_blocked,"update":atlas.viewport.render_target_update_mode,"own":atlas.viewport.own_world_3d,"paused":paused})
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
	var stocks:=true
	for own in wm.world.mine:
		if int(own.id)!=int(wm.find_city(wm.selected).id):continue
		for item in own.stock:
			var amount:Label=wm.goods_box.get_node_or_null("NativeStock/Stock_%d"%int(item.resource))
			stocks=stocks and amount!=null and amount.text=="%d"%int(item.count)
	check(stocks and wm.goods_box.has_node("NativeStock"),"own-city panel shows the exact native stored goods")
	await capture("overview")
	await water_checks()
	await keyboard_checks()
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
	for scale_size in [Vector2i(1152,720),Vector2i(960,600)]:
		root.content_scale_size=scale_size;await frames(8)
		var bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
		var fit:=true
		for control in [wm.get_node("%Back"),wm.get_node("Themed/Margin/Row/Side"),wm.get_node("Themed/Margin/Row/MapFrame/MapBox/AtlasToolbar")]:
			fit=fit and bounds.encloses(control.get_global_rect())
		check(fit,"map controls and city panel fit at %d%% interface size"%int(144000/scale_size.x))
		await capture("large-%d"%int(144000/scale_size.x))
	root.content_scale_size=Vector2i(1440,900);await frames(8)
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
	var side:Control=city.world_map.get_node("Themed/Margin/Row/Side")
	check(side.is_visible_in_tree() and is_equal_approx(side.modulate.a,1.0) and is_equal_approx(city.world_map.get_node("%AtlasToolbar").modulate.a,1.0),"city panel and complete toolbar restore their visibility after ascent")
	await capture("integrated")
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
