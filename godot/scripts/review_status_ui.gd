extends SceneTree
func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func capture(city: Node3D, name: String) -> void:
	for frame in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/status-ui-"+name+".png")
	print("STATUS_CAPTURE ",name," size=",city.hud.size)

func inspect(city: Node3D, asset: String) -> void:
	var building: Dictionary=city.state.buildings.filter(func(b):return b.asset==asset)[0]
	city.inspected=Vector2i(building.x,building.y);city.refresh_inspection()
	city.orbit.target=city.world_position(building.x,building.y,building.altitude)
	city.orbit.distance=32;city.orbit.yaw=35;city.orbit.refresh()

func run() -> void:
	if OS.get_cmdline_user_args().has("--menu"):
		await menu_review();return
	var city: Node3D=load("res://main.tscn").instantiate();root.add_child(city)
	while city.state.is_empty() or city.frame_count<80:await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.orbit.enabled=false
	if OS.get_cmdline_user_args().has("--checks"):
		var okay: bool=await load("res://scripts/validate_status_ui.gd").new().run(city)
		var previous=load("res://scripts/validate_main.gd").new();previous.city=city
		okay=await previous.run_hud_checks() and okay
		okay=await load("res://scripts/validate_context_ui.gd").new().run(city) and okay
		print("STATUS_UI_COMBINED ","PASS" if okay else "FAIL"," checks=115")
		quit(0 if okay else 1);return
	city.set_process(false);city.set_process_unhandled_input(false);root.gui_disable_input=true
	DisplayServer.window_set_size(Vector2i(1600,1000))
	inspect(city,"olive_press");city.set_tool("select")
	await capture(city,"production-"+city.language)
	var home: Dictionary=city.state.buildings.filter(func(b):return b.asset.begins_with("common_house_"))[0]
	city.inspected=Vector2i(home.x,home.y);city.refresh_inspection();city.set_overlay("water")
	await capture(city,"water-"+city.language)
	root.get_node("UiAccess").apply(125,130)
	DisplayServer.window_set_size(Vector2i(1280,720))
	inspect(city,"warehouse");city.hud.open_category("Industry");city.set_tool("olive_press")
	await capture(city,"large-720-"+city.language)
	city.hud.close_build_tray()
	var dialog: Window=load("res://ui/interface_dialog.gd").open(city.hud)
	await capture(city,"options-720-"+city.language)
	dialog.canceled.emit()
	print("STATUS_UI_REVIEW_DONE")
	quit()

func menu_review() -> void:
	var locale:="en"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="):locale=argument.get_slice("=",1)
	var scratch:=ProjectSettings.globalize_path("res://captures/status-menu-%d"%OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_save_directory",scratch);Engine.set_meta("ezeus_settings_path",scratch.path_join("settings.cfg"));Engine.set_meta("ezeus_language",locale)
	DisplayServer.window_set_size(Vector2i(1280,720))
	var menu: Control=load("res://ui/start_menu.tscn").instantiate();root.add_child(menu)
	var okay:=true;var checks:=0
	for sizes in [Vector2i(100,100),Vector2i(125,130)]:
		root.get_node("UiAccess").apply(sizes.x,sizes.y)
		for frame in 12:await process_frame
		var screen:=Rect2(Vector2.ZERO,menu.size)
		for name in ["Continue","NewGame","LoadGame","Language","Sound","Interface","Quit"]:
			var fits:=screen.encloses(menu.get_node("%"+name).get_global_rect());okay=okay and fits;checks+=1
			print("STATUS_MENU_CHECK ","PASS " if fits else "FAIL ",locale," ",sizes," ",name)
		if sizes.x==125:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://captures/status-ui-menu-720-"+locale+".png")
	menu.get_node("%Interface").pressed.emit()
	for frame in 6:await process_frame
	var hub: Window=null
	for child in menu.get_children():
		if child is Window and child.get("settings_buttons")!=null:hub=child
	var hub_ready: bool=hub!=null and hub.visible and hub.settings_buttons.size()==3 and Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(Rect2(Vector2(hub.position),Vector2(hub.size)))
	okay=okay and hub_ready;checks+=1
	print("STATUS_MENU_CHECK ","PASS " if hub_ready else "FAIL ","menu gear opens bounded game settings with display/interface/controls links")
	if hub!=null:hub.settings_buttons.display.pressed.emit()
	for frame in 6:await process_frame
	var display: Window=null
	for child in menu.get_children():
		if child is Window and child.get("preview_options")!=null:display=child
	var display_ready: bool=display!=null and display.visible and display.choices.size()==4
	okay=okay and display_ready;checks+=1
	print("STATUS_MENU_CHECK ","PASS " if display_ready else "FAIL ","menu settings opens display settings")
	if display!=null:display.cancel()
	for frame in 6:await process_frame
	if hub!=null:hub.settings_buttons.interface.pressed.emit()
	for frame in 6:await process_frame
	var dialog: Window=null
	for child in menu.get_children():
		if child is Window and child.get("sizes")!=null:dialog=child
	var opened: bool=dialog!=null and dialog.visible and dialog.sizes.size()==2;okay=okay and opened;checks+=1
	print("STATUS_MENU_CHECK ","PASS " if opened else "FAIL ","menu gear opens settings and shared interface options")
	if dialog!=null:dialog.canceled.emit()
	menu.queue_free()
	for frame in 6:await process_frame
	DirAccess.remove_absolute(scratch);Engine.remove_meta("ezeus_settings_path");Engine.remove_meta("ezeus_save_directory");Engine.remove_meta("ezeus_language")
	print("STATUS_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
