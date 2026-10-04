extends SceneTree
# Render the actual start menu without opening a city or touching player preferences.
# -- --menu-lang=ru --menu-size=1920x1080 --menu-time=6 --menu-output=/absolute/file.png
var scratch := ""
var okay := true
var checks := 0
func check(value: bool, description: String) -> void:
	checks+=1
	okay=okay and value
	print("MENU_CHECK ","PASS " if value else "FAIL ",description)
func frames(count: int) -> void:
	for i in count: await process_frame
func click(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.position=button.get_global_rect().get_center()
	event.pressed=true
	root.push_input(event,true)
	event=event.duplicate()
	event.pressed=false
	root.push_input(event,true)
	await frames(3)
func scenery_safe(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D: return false
	for child in node.get_children():
		if not scenery_safe(child): return false
	return true

func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var language := "en"
	var size := Vector2i(1920,1080)
	var output := "res://captures/menu-hades-en.png"
	var time := 6.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--menu-lang="): language=arg.get_slice("=",1)
		if arg.begins_with("--menu-size="):
			var parts := arg.get_slice("=",1).split("x")
			size=Vector2i(int(parts[0]),int(parts[1]))
		if arg.begins_with("--menu-time="): time=float(arg.get_slice("=",1))
		if arg.begins_with("--menu-output="): output=arg.get_slice("=",1)
	scratch=ProjectSettings.globalize_path("res://captures/menu-review-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_save_directory",scratch)
	Engine.set_meta("ezeus_settings_path",scratch.path_join("settings.cfg"))
	Engine.set_meta("ezeus_menu_review",true)
	Engine.set_meta("ezeus_language",language)
	root.size=size
	root.content_scale_size=Vector2i(1440,810) if size.x>size.y*1.7 else Vector2i(1440,900)
	var menu: Control=load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	var backdrop=menu.get_node("LoginScene3D")
	backdrop.set_review_time(time)
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	check(error==OK,"actual menu frame captured")
	check(menu.page=="main" and menu.get_node("%MainPage").visible,"main menu visible")
	check(menu.new_game_button.text==("Новая игра" if language=="ru" else "New game"),"requested language")
	check(menu.continue_button.disabled and menu.load_game_button.disabled,"empty scratch saves do not offer Continue or Load")
	check(scenery_safe(backdrop),"scenery has no collision or navigation authority")
	check(backdrop.geometry_triangles<400000 and backdrop.mesh_instances<=32,"bounded menu geometry")
	check(not backdrop.get_node("WorldEnvironment").environment.ssr_enabled and not backdrop.get_node("WorldEnvironment").environment.ssao_enabled,"Mobile uses supported effects")
	var bounds := Rect2(Vector2.ZERO,root.get_visible_rect().size)
	for button in [menu.new_game_button,menu.language_button,menu.sound_button,menu.quit_button]:
		check(bounds.encloses(button.get_global_rect()),"button fits viewport: "+button.name)
	var old_label: String=menu.new_game_button.text
	await click(menu.language_button)
	check(menu.new_game_button.text!=old_label,"actual mouse click switches language")
	await click(menu.language_button)
	check(menu.new_game_button.text==old_label,"actual mouse click switches back")
	await click(menu.new_game_button)
	check(menu.page=="adventures" and menu.listing.size()>=20,"actual mouse click opens adventures")
	await click(menu.adventure_back)
	check(menu.page=="main","adventure Back returns to menu")
	menu.open_saves()
	await frames(3)
	check(menu.page=="load" and menu.save_list.item_count==0,"empty scratch load page")
	await click(menu.load_back)
	check(menu.page=="main","load Back returns to menu")
	check(menu.opened==null and not Engine.has_meta("ezeus_simulation"),"review opens no native city or adventure")
	var start := Time.get_ticks_usec()
	for i in 120: await process_frame
	var frame_ms := (Time.get_ticks_usec()-start)/120000.0
	print("MENU_REVIEW ", JSON.stringify({"output":output,"language":language,"size":size,"save":false,"mesh_instances":backdrop.mesh_instances,"triangles":backdrop.geometry_triangles,"build_ms":backdrop.build_msec,"average_frame_ms":frame_ms,"renderer":RenderingServer.get_current_rendering_method(),"checks":checks,"passed":okay}))
	menu.queue_free()
	await process_frame
	if FileAccess.file_exists(scratch.path_join("settings.cfg")):
		DirAccess.remove_absolute(scratch.path_join("settings.cfg"))
	DirAccess.remove_absolute(scratch)
	quit(0 if okay else 1)
