extends SceneTree
var city: Node3D
var okay := true
var checks := 0
var props: Array = []
var names := ["Hut", "Shack", "Hovel", "Homestead", "Tenement", "Apartment", "Townhouse"]
var capture_folder := "res://captures"

func _initialize() -> void:
	if not OS.get_environment("EZEUS_HOUSING_REVIEW_DIRECTORY").is_empty():
		capture_folder=OS.get_environment("EZEUS_HOUSING_REVIEW_DIRECTORY")
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("HOUSING_REVIEW_CHECK ", "PASS " if value else "FAIL ", label)
func frames(count := 12) -> void:
	for i in count: await process_frame
func capture(label: String, target: Vector3, distance: float, yaw := 0.0, pitch := 34.0) -> void:
	city.orbit.target = target; city.orbit.distance = distance
	city.orbit.yaw = yaw; city.orbit.pitch = pitch; city.orbit.refresh()
	await frames(); RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png(capture_folder.path_join("housing-%s.png" % label))

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 70: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
	city.orbit.enabled = false; city.ui_layer.visible = false
	DisplayServer.window_move_to_foreground()
	var original: Dictionary = city.core.simulation.snapshot(true)
	var free := {}
	for tile in original.tiles:
		if int(tile[5]) and not int(tile[4]) and not (int(tile[3]) & (4|16|2048|32768)): free[Vector2i(tile[0],tile[1])] = tile
	var base := Vector2i(-1, -1)
	for cell in free:
		var clear := true
		for x in range(-7, 8):
			for y in range(-3, 6):
				var other: Array = free.get(cell+Vector2i(x,y), [])
				if other.is_empty() or int(other[2])!=int(free[cell][2]): clear=false; break
			if not clear: break
		if clear: base=cell; break
	check(base.x>=0, "clear level native ground exists for the render-only housing gallery")
	if base.x<0: city.queue_free(); quit(1); return
	var centers: Array[Vector3] = []
	for level in 7:
		var asset := "common_house_%da" % level
		var node: Node3D = city.model(asset)
		check(node!=null, asset+": real installed model resolves without a placeholder")
		if node==null: continue
		var offset := Vector2(-4.5 + 3.0*level, 0) if level<4 else Vector2(-3+3*(level-4), 4)
		var center: Vector3 = city.world_position(base.x+offset.x,base.y+offset.y,int(free[base][2]))
		centers.append(center); city.world.add_child(node); props.append(node)
		# Show the dressed entrance toward the gallery camera. Native placement
		# and the live city's road-facing adapter are tested separately below.
		var facing := 3 if level in [2,3] else 2
		node.position=center; node.basis=city.model_basis(asset,2,2,facing)
		check(node.basis.get_scale().is_equal_approx(Vector3.ONE), asset+": native two-by-two placement retains full authored height")
		var label := Label3D.new(); label.text="%d · %s"%[level+1,names[level]]
		label.font_size=34; label.pixel_size=.006
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.no_depth_test=true
		city.world.add_child(label); props.append(label); label.position=center+Vector3(0,.16,1.16)
	await capture("progression",city.world_position(base.x,base.y+1.8,int(free[base][2]))+Vector3.UP*.7,20,0,31)
	await capture("starter-levels",centers[0].lerp(centers[1],.5)+Vector3.UP*.4,7.5,0,32)
	await capture("upper-levels",centers[4].lerp(centers[6],.5)+Vector3.UP*1.0,13,0,30)
	# Render fixtures exercise actual MultiMesh/VAT visibility without editing
	# native occupancy. The native immigration/save test covers its authority.
	for prop in props: prop.visible=false
	var residents := preload("res://scripts/building_batches.gd").new()
	city.world.add_child(residents)
	var groups := {}
	for level in 7:
		var asset := "common_house_%da" % level
		var facing := 3 if level in [2,3] else 2
		groups[asset+"|residents"]=[{"transform":Transform3D(city.model_basis(asset,2,2,facing),centers[level]),"working":false,"animation_offset":0}]
	residents.rebuild(groups)
	await capture("residents-empty",centers[0].lerp(centers[1],.5)+Vector3.UP*.4,7.5,0,32)
	var original_nodes := residents.group_nodes.duplicate()
	for group in groups: groups[group][0].working=true
	residents.rebuild(groups)
	check(residents.last_rebuilt==0 and residents.group_nodes==original_nodes,"occupying all seven render fixtures reuses their geometry")
	for group in groups:
		var visible_resident := false
		for node in residents.group_nodes[group]:
			if node.multimesh.use_custom_data:
				visible_resident=visible_resident or node.multimesh.get_instance_custom_data(0).r>.5
		check(visible_resident,str(group)+": GPU receives occupied visibility")
	for phase in [0,10,20,30]:
		RenderingServer.global_shader_parameter_set("building_work_clock",float(phase))
		await capture("resident-idle-%02d"%phase,centers[0].lerp(centers[1],.5)+Vector3.UP*.4,6.0,0,32)
	await capture("residents-occupied",city.world_position(base.x,base.y+1.8,int(free[base][2]))+Vector3.UP*.7,20,0,31)
	for group in groups: groups[group][0].working=false
	residents.rebuild(groups)
	var hidden := true
	for group in groups:
		for node in residents.group_nodes[group]:
			if node.multimesh.use_custom_data: hidden=hidden and node.multimesh.get_instance_custom_data(0).r<.5
	check(hidden and residents.last_rebuilt==0,"final resident departure hides households without replacing geometry")
	residents.free()
	# Test the existing level-change replacement with one real building's ID and
	# unchanged placement. These copies never enter the native core or a save.
	var live_houses: Array = original.buildings.filter(func(b):return str(b.asset).begins_with("common_house_"))
	check(not live_houses.is_empty(),"the native designated city contains common housing")
	if not live_houses.is_empty():
		var house: Dictionary = live_houses[0]
		var anchor := "%d,%d"%[house.x,house.y]
		var transform: Transform3D = city.building_placements[anchor].transform
		for level in 7:
			var copy: Dictionary = original.duplicate(true)
			copy.buildings_changed=true
			for b in copy.buildings:
				if int(b.id)==int(house.id): b.asset="common_house_%da"%level
			city.receive_state(copy)
			var shown: Dictionary = city.building_index[int(house.id)]
			var placed: Dictionary = city.building_placements[anchor]
			check(shown.asset=="common_house_%da"%level and int(shown.w)==2 and int(shown.h)==2 and placed.transform.origin.is_equal_approx(transform.origin), "level %d replacement keeps the native house ID, foundation and footprint"%level)
		city.receive_state(original)
		var focus: Dictionary = live_houses[int(live_houses.size()/2)]
		var point: Vector3 = city.world_position(focus.x+.5,focus.y+.5,focus.altitude)
		for prop in props: prop.visible=false
		city.ui_layer.visible=true
		await capture("city-houses",point+Vector3.UP*.5,17,45,40)
		# Catalog thumbnail uses the same new starter model, on demand only.
		city.set_tool("house"); city.hud.open_category("Housing and roads")
		for i in 160:
			var texture: Texture2D=city.hud.thumbnails.request({"name":"house","asset":"common_house_0a","w":2,"h":2})
			if texture!=null: break
			await process_frame
		var thumbnail: Texture2D=city.hud.thumbnails.request({"name":"house","asset":"common_house_0a","w":2,"h":2})
		check(thumbnail!=null,"housing catalog caches the installed starter-house render")
		await capture("catalog",point+Vector3.UP*.5,17,45,40)
	var after: Dictionary=city.core.simulation.snapshot(true)
	original.erase("sequence"); after.erase("sequence")
	check(original==after,"gallery, height changes and catalog review alter no native game-state field")
	for node in props:
		if is_instance_valid(node): node.queue_free()
	print("HOUSING_REVIEW ", "PASS " if okay else "FAIL ", "checks=", checks)
	city.queue_free(); await frames(2); quit(0 if okay else 1)
