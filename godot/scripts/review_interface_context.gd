extends SceneTree
# Read-only review of contextual construction over the designated test city.
func _initialize() -> void: call_deferred("run")

func capture(city: Node3D, name: String) -> void:
	print("CONTEXT_CAPTURE_BEGIN ",name)
	for frame in 12: await process_frame
	print("CONTEXT_CAPTURE_DRAW ",name)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/interface-context-"+name+".png")
	print("CONTEXT_CAPTURE ",name," ",city.hud.size," tray=",city.hud.get_node("%BuildTray").get_global_rect())

func run() -> void:
	var city: Node3D=load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count<80: await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.orbit.enabled=false
	city.set_process_unhandled_input(false)
	if OS.get_cmdline_user_args().has("--checks"):
		city.set_process(false)
		var validator=load("res://scripts/validate_main.gd").new()
		validator.city=city
		var okay: bool=await validator.run_hud_checks()
		okay=await preload("res://scripts/validate_context_ui.gd").new().run(city) and okay
		print("INTERFACE_CONTEXT_CHECKS ","PASS" if okay else "FAIL")
		quit(0 if okay else 1)
		return
	root.gui_disable_input=true
	if city.language!="en":city.change_language()
	for group in city.hud.build_groups:
		for item in group.items: city.hud.thumbnails.request(item.asset)
	for frame in 600:
		await process_frame
		if not city.hud.thumbnails.busy and city.hud.thumbnails.pending.is_empty():break
	var hospital: Dictionary=city.state.buildings.filter(func(b):return b.asset=="hospital")[0]
	city.orbit.target=city.world_position(hospital.x,hospital.y,hospital.altitude)
	city.orbit.distance=30;city.orbit.yaw=35;city.orbit.refresh()
	city.set_tool("hospital")
	city.inspected=Vector2i(hospital.x,hospital.y);city.refresh_inspection()
	city.hud.open_category("Health and water")
	DisplayServer.window_set_size(Vector2i(1600,1000))
	await capture(city,"build-en")
	# Fixed review pointer over a real native quote, so capture timing cannot move the preview.
	city.set_process(false)
	var candidate:=Vector2i(99999,99999)
	var nearest:=INF
	for point in city.tiles:
		var distance: float=Vector2(point).distance_squared_to(Vector2(hospital.x,hospital.y))
		if distance>=nearest or int(city.tiles[point][4])!=0:continue
		if city.core.query("preview hospital %d %d 0"%[point.x,point.y]).get("valid",false):
			candidate=point;nearest=distance
	if candidate.x!=99999:
		city.picked=candidate;city.refresh_placement()
		hold_badge(city,city.orbit.camera.unproject_position(city.ghost.position))
		await capture(city,"placement-en")
		city.picked=Vector2i(hospital.x,hospital.y);city.placement_key="";city.refresh_placement()
		hold_badge(city,city.orbit.camera.unproject_position(city.ghost.position))
		await capture(city,"blocked-en")
	city.hud.set_process(true)
	city.hud.close_build_tray()
	for building in city.state.buildings:
		if building.asset=="warehouse":
			city.inspected=Vector2i(building.x,building.y);city.refresh_inspection();break
	print("CONTEXT_LANGUAGE before switch")
	city.change_language()
	print("CONTEXT_LANGUAGE after switch")
	DisplayServer.window_set_size(Vector2i(1280,720))
	city.hud.open_category("Industry")
	city.set_tool("olive_press")
	await capture(city,"build-ru-720")
	city.close_inspection()
	city.hud.close_build_tray();city.hud.open_category("Walls and defence");city.set_tool("wall")
	await capture(city,"wall-ru-720")
	print("CONTEXT_REVIEW_DONE")
	quit()

func hold_badge(city: Node3D, pointer: Vector2) -> void:
	city.hud.set_process(false)
	city.hud._layout_panels()
	var badge: Control=city.hud.get_node("%PlacementBadge")
	badge.show()
	var maximum: Vector2=city.hud.size-Vector2(12,118)-badge.size
	badge.position=(pointer+Vector2(22,20)).clamp(Vector2(12,72),maximum.max(Vector2(12,72)))
	city.hud.get_node("%Feedback").hide()
