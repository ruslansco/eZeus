extends SceneTree
# Read-only visual review of the HUD over the designated city. No save or settings writes.
func _initialize() -> void: call_deferred("run")

func capture(name: String) -> void:
	for frame in 48: await process_frame
	await RenderingServer.frame_post_draw
	var hud: Control = root.get_node("CityPilot").hud
	print("HUD_BOUNDS ", name, " root=", hud.get_global_rect())
	for panel in ["BottomBar", "StatusBar", "BuildTray", "Inspector", "MinimapPanel", "StatsGroup"]:
		print("HUD_BOUNDS ", panel, " ", hud.get_node("%" + panel).get_global_rect())
	root.get_texture().get_image().save_png("res://captures/hud-" + name + ".png")

func run() -> void:
	var city: Node3D = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.orbit.enabled = false
	city.set_process_unhandled_input(false)
	city.set_tool("select")
	root.gui_disable_input = true
	# Review every available model, including the road's intentional icon fallback.
	for group in city.hud.build_groups:
		for item in group.items: city.hud.thumbnails.request(item)
	for frame in 600:
		await process_frame
		if not city.hud.thumbnails.busy and city.hud.thumbnails.pending.is_empty(): break
	print("HUD_THUMBNAILS ", city.hud.thumbnails.cache.size(), " cached catalog assets")
	var hospital := {}
	for building in city.state.buildings:
		if building.asset == "hospital": hospital = building; break
	city.orbit.target = city.world_position(hospital.x, hospital.y, hospital.altitude)
	city.orbit.distance = 30
	city.orbit.yaw = 35
	city.orbit.refresh()
	city.inspected = Vector2i(99999,99999)
	city.hud.inspector.hide()
	city.hud.set_goals_expanded(false)
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	DisplayServer.window_move_to_foreground()
	await capture("overview-en")
	city.inspected = Vector2i(hospital.x, hospital.y)
	city.refresh_inspection()
	city.hud.open_category("Gardens and monuments")
	await capture("build-en")
	city.hud.close_build_tray()
	for building in city.state.buildings:
		if building.asset == "warehouse":
			city.inspected = Vector2i(building.x, building.y)
			city.refresh_inspection()
			break
	await capture("storage-en")
	city.change_language()
	DisplayServer.window_set_size(Vector2i(1280,720))
	city.hud.open_category("Industry")
	await capture("build-ru-720")
	city.hud.close_build_tray()
	city.close_inspection()
	city.state.events = [{"id":900001,"title":city.tr("Messages"),"text":city.tr("Return to the main menu? Progress since your last save is lost."),"actions":[{"choice":0,"label":city.tr("Stay")},{"choice":1,"label":city.tr("Main menu")}]}]
	city.update_events()
	await capture("decision-ru-720")
	# The common Theme also styles the start menu. Review its main page without opening any save.
	city.ui_layer.hide()
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	for locale in ["en", "ru"]:
		menu.language = city.UiText.set_language(locale)
		menu.retranslate()
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/hud-start-" + locale + ".png")
	print("HUD_REVIEW_DONE")
	quit()
