extends SceneTree
# Actual menu, a disposable leader and a byte-for-byte copy of the designated save. Parsed GUI input.
var menu: Control
var language := "en"
var capture_prefix := "main-menu"
var checks := 0
var okay := true
const Leaders = preload("res://scripts/leaders.gd")
const SaveFiles = preload("res://scripts/save_files.gd")
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_menu_review", true)
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("MAIN_MENU_CHECK ", "PASS " if value else "FAIL ", description)
func frames(count := 8) -> void:
	for i in count: await process_frame
func click(button: Control, after_frames := 8) -> void:
	button.grab_focus()
	await frames()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
	await frames(after_frames)
func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
	await frames()
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/%s-%s-%s.png" % [capture_prefix,language,name])
func dialog(property: String) -> Window:
	for child in menu.get_children():
		if child is Window and child.visible and child.get(property) != null:
			return child
	return null
func text_fits(button: Button) -> bool:
	var font := button.get_theme_font("font")
	var size := button.get_theme_font_size("font_size")
	var text_size := Vector2(font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x,font.get_height(size))
	var safe_size := button.size-button.get_theme_stylebox("normal").get_minimum_size()
	return text_size.x <= safe_size.x+1 and text_size.y <= safe_size.y+1
func controls_text_fits(window: Window) -> bool:
	var buttons: Array = window.key_buttons.values()+window.reset_buttons.values()+window.get_ok_button().get_parent().find_children("*","Button",true,false)
	for button in buttons:
		if button.is_visible_in_tree() and not text_fits(button): return false
	return true
func settings_fits(window: Window) -> bool:
	var frame := Rect2(Vector2(window.position)-Vector2(6,60),Vector2(window.size)+Vector2(12,66))
	if not Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(frame): return false
	for button in window.get_ok_button().get_parent().find_children("*","Button",true,false):
		if button.is_visible_in_tree() and (not text_fits(button) or not Rect2(Vector2.ZERO,window.size).encloses(button.get_global_rect())):
			print("SETTINGS_BUTTON_BOUNDS ",button.text," fit=",text_fits(button)," rect=",button.get_global_rect()," minimum=",button.get_combined_minimum_size()," padding=",button.get_theme_stylebox("normal").get_minimum_size()," font_height=",button.get_theme_font("font").get_height(button.get_theme_font_size("font_size")))
			return false
	return true
func window_click(button: Button, window: Window) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = Vector2(window.position)+button.get_global_rect().get_center()
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
	await frames(15)
func settings_themed(window: Window) -> bool:
	return window.has_meta("settings_shell") and window.get_meta("settings_shell").finished and window.theme != menu.theme and window.theme.get_stylebox("embedded_border","Window") is StyleBoxTexture and not menu.navigation.settings_page.visible and not menu.navigation.frames.settings.visible and menu.navigation.settings_shade.visible and window.exclusive
func category_content_fits() -> bool:
	var page: Control = menu.navigation.settings_page
	var frame := page.get_global_rect()
	var reading := frame.grow_individual(-frame.size.x*.10,-frame.size.y*.13,-frame.size.x*.08,-frame.size.y*.07)
	var controls: Array = [page.get_child(0).get_child(0),menu.navigation.settings_back]+menu.navigation.settings_buttons.values()
	return controls.all(func(control): return reading.encloses(control.get_global_rect()))
func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=",1)
		if argument.begins_with("--menu-capture-prefix="): capture_prefix = argument.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	Leaders.create("Solon Review")
	Leaders.create("Aspasia Review")
	Leaders.set_current("Solon Review")
	DisplayServer.window_set_size(Vector2i(1920,1080))
	menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	await frames(25)
	check(menu.page == "main", "chosen leader opens directly on main menu")
	check(not menu.get_node("%ContinueCard").visible and menu.continue_button.disabled and menu.load_game_button.disabled and not menu.new_game_button.disabled, "empty profile emphasizes New game and hides empty Continue card")
	check(root.gui_get_focus_owner() == menu.new_game_button, "New game gets keyboard focus with no saves")
	check(menu.language_button.text == ("Русский" if language == "ru" else "English") and menu.get_node("%Interface").text == menu.tr("Settings") and menu.get_node("%Interface").focus_mode == Control.FOCUS_ALL, "current language and named keyboard-accessible Settings are clear")
	check(menu.new_game_button.get_theme_stylebox("normal") is StyleBoxTexture and menu.navigation.frames.main.texture != null, "generated Greek frame and enamel button artwork load")
	check(menu.new_game_button.get_theme_stylebox("focus") is StyleBoxTexture and menu.new_game_button.get_theme_stylebox("focus").texture == menu.new_game_button.get_theme_stylebox("normal").texture, "keyboard focus follows the enamel silhouette without a rectangular border")
	var cursor := root.get_node("GameCursor")
	check(cursor.registered_shapes.size() == 17 and cursor.textures.size() == 13 and not cursor.is_processing(), "global hardware cursor family covers every Godot shape without per-frame processing")
	var scenery = menu.get_node("LoginScene3D")
	check(scenery.camera != null and scenery.has_node("Camera3D/CinematicBackdrop") and scenery.has_node("Camera3D/LivingPortal"), "cinematic Aegean artwork preserves the registered living portal")
	check(menu.navigation.frames.size() >= 7 and not menu.get_node("%MainScroll") is ScrollContainer, "all menu frames use original artwork and the main menu has no scroll container")
	check(menu.navigation.frames.keys().all(func(page): return menu.navigation.frames[page] is TextureRect and menu.navigation.frames[page].texture == (preload("res://assets/menu/greek_menu_panel_v3.png") if page == "main" else preload("res://assets/menu/greek_menu_sheet_v3.png"))),"all full menu pages share the original carved Greek frame family")
	check(menu.find_children("ReadChapterBriefing","Button",true,false).is_empty(),"the duplicate Read chapter briefing action is removed")
	print("OLYMPIAN_SCENE build_ms=",scenery.build_msec," triangles=",scenery.geometry_triangles," batches=",scenery.mesh_instances)
	var initial_time: float = scenery.scene_time
	root.get_node("UiAccess").reduced_motion = true
	await frames(8)
	var held: float = scenery.scene_time
	await frames(8)
	check(held == scenery.scene_time and not scenery.camera.is_processing(), "reduced motion holds camera, scenic drift and portal animation")
	root.get_node("UiAccess").reduced_motion = false
	await frames(8)
	check(scenery.scene_time > initial_time and scenery.camera.is_processing(), "ordinary motion resumes after reduced-motion preview")
	await capture("new-player")
	if OS.get_cmdline_user_args().has("--olympian-art-only"):
		menu.get_node("%MainPage").hide()
		await capture("sanctuary")
		print("MAIN_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks," language=",language," art_only=true")
		quit(0 if okay else 1)
		return
	await click(menu.language_button)
	check(menu.language_button.text != ("Русский" if language == "ru" else "English") and menu.new_game_button.text == menu.tr("New game"), "language click updates labels and current language")
	await click(menu.language_button)
	check(menu.language == language, "language cycles back to requested locale")
	var engine: String = menu.engine
	var source := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var name := "The city of Solon - A new beginning on the Aegean coastline"
	var fixture := SaveFiles.directory().path_join(name + ".ez")
	check(DirAccess.copy_absolute(source,fixture) == OK, "real saved city copied only into disposable leader folder")
	var original_hash := FileAccess.get_sha256(fixture)
	menu.refresh_main()
	await frames(20)
	check(menu.get_node("%ContinueCard").visible and not menu.continue_button.disabled and menu.continue_button.text == menu.tr("Continue") and menu.get_node("%ContinueSaveName").text == name, "Continue card names latest save separately from its action")
	check(menu.latest_save.path == fixture and menu.get_node("%ContinueSaveName").tooltip_text == name and not menu.continue_info.text.is_empty(), "long save names retain full tooltip, metadata and exact native path")
	var panel: Control = menu.get_node("%MainPage")
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(panel.get_global_rect()) and panel.get_global_rect().end.x < root.get_visible_rect().size.x * .46, "content-sized menu leaves gateway visible on right")
	await capture("continue")
	await click(menu.load_game_button)
	check(menu.page == "load" and menu.save_entries.size() == 1 and menu.save_entries[0].path == fixture, "Load game lists the same exact saved city")
	var extra_files := []
	for i in 12:
		var file := SaveFiles.directory().path_join("Review slot %02d.ez" % i)
		DirAccess.copy_absolute(source,file)
		extra_files.append(file)
	menu.open_saves()
	await frames(20)
	var save_pager = menu.navigation.save_pager
	check(menu.save_list.item_count < menu.save_entries.size() and menu.save_list.get_v_scroll_bar().max_value <= menu.save_list.get_v_scroll_bar().page, "saved games fit paged rows without a scroll bar")
	await click(save_pager.next)
	check(save_pager.page == 1 and menu.save_info.text == menu.save_entries[save_pager.selected_index].detail, "save page selection retains exact native metadata")
	save_pager.search.text = "Review slot 11"
	save_pager.search.text_changed.emit(save_pager.search.text)
	await frames()
	check(menu.save_list.item_count == 1 and menu.save_entries[save_pager.selected_index].path == extra_files[11], "saved-game search retains its exact file path")
	for file in extra_files: DirAccess.remove_absolute(file)
	menu.open_saves()
	await frames()

	await capture("load")
	await click(menu.load_back)
	await click(menu.new_game_button)
	await create_timer(.2).timeout
	check(menu.page == "adventures" and not menu.editing and menu.listing.size() >= 26, "New game opens native campaign and sandbox library")
	var pager = menu.navigation.adventure_pager
	check(menu.adventure_list.item_count < menu.listing.size() and menu.adventure_list.get_v_scroll_bar().max_value <= menu.adventure_list.get_v_scroll_bar().page, "adventure catalog fits a page without a scroll bar")
	await click(pager.next)
	await create_timer(.2).timeout
	check(pager.page == 1 and menu.adventure_title.text == menu.listing[pager.selected_index].title, "Next page selects the correct native adventure")
	pager.search.text = menu.listing[2].title
	pager.search.text_changed.emit(pager.search.text)
	await create_timer(.2).timeout
	check(menu.adventure_list.item_count == 1 and pager.selected_index == 2 and menu.adventure_title.text == menu.listing[2].title, "search reaches the native campaign without changing its identity")
	pager.search.text = "there-is-no-such-campaign"
	pager.search.text_changed.emit(pager.search.text)
	await frames()
	check(menu.adventure_start.disabled and menu.adventure_list.item_count == 0, "empty search disables Start")
	pager.search.text = ""
	pager.search.text_changed.emit(pager.search.text)
	await create_timer(.2).timeout

	await capture("adventures")
	await key(KEY_ESCAPE)
	check(menu.page == "main", "Escape returns from adventure selection")
	await click(menu.navigation.extras_button)
	check(menu.page == "extras", "Extras contains the native adventure editor")
	await capture("extras")
	await click(menu.editor_button)
	check(menu.page == "adventures" and menu.editing and menu.new_row.visible and menu.adventure_start.text == menu.tr("Edit"), "quiet editor action preserves authoring flow")
	await click(menu.adventure_back)
	check(menu.page == "extras", "editor Back returns to its Extras parent")
	await click(menu.navigation.extras_back)
	await click(menu.leader_change)
	check(menu.page == "leaders" and menu.leader_list.item_count == 2, "profile action opens roster without changing saves")
	await capture("leaders")
	var other := Leaders.list().find("Aspasia Review")
	menu.leader_list.select(other)
	await click(menu.leader_proceed)
	check(menu.page == "main" and menu.leader_line.text.contains("Aspasia Review") and not menu.get_node("%ContinueCard").visible, "switching to empty leader updates identity and Continue state")
	Leaders.set_current("Solon Review")
	menu.show_page("main")
	await frames()
	menu.new_game_button.grab_focus()
	await key(KEY_TAB)
	check(root.gui_get_focus_owner() == menu.load_game_button, "Tab follows primary action into Load game")
	var roster := []
	for i in 12:
		var roster_name := "Roster Review %02d" % i
		Leaders.create(roster_name); roster.append(roster_name)
	menu.open_leaders()
	await frames(20)
	var profiles = menu.navigation.profile_pager
	check(menu.leader_list.item_count < profiles.records.size() and menu.leader_list.get_v_scroll_bar().max_value <= menu.leader_list.get_v_scroll_bar().page, "profile roster fits paged rows without a scroll bar")
	await click(profiles.next)
	check(menu.selected_leader() == profiles.records[profiles.selected_index] and not menu.leader_proceed.disabled and menu.leader_delete.disabled == not Leaders.can_delete(menu.selected_leader()), "profile paging retains identity and ownership actions")
	profiles.search.text = "there-is-no-such-profile"
	profiles.search.text_changed.emit(profiles.search.text)
	await frames()
	check(menu.leader_proceed.disabled and menu.leader_delete.disabled, "empty profile search disables Proceed and Delete")
	for roster_name in roster: Leaders.delete(roster_name)
	menu.show_page("main")
	await frames()
	await click(menu.get_node("%Interface"))
	check(menu.page == "settings" and menu.navigation.settings_buttons.has_all(["display","graphics","sound","interface","controls","game"]) and root.gui_get_focus_owner() == menu.navigation.settings_buttons.display, "Settings groups six option categories with keyboard focus")
	await capture("settings")
	check(category_content_fits() and menu.navigation.settings_buttons.display.get_theme_stylebox("normal") is StyleBoxTexture,"settings title, category choices and Back stay inside the carved reading area")
	await click(menu.navigation.settings_buttons.display)
	var settings := dialog("preview_options")
	check(settings != null, "Display category opens the existing preview/revert dialog")
	if settings != null:
		check(settings_themed(settings) and settings_fits(settings), "Display uses one padded bronze/slate shell with no competing category frame")
		check(settings.choices.values().all(func(choice): return is_equal_approx(choice.size.x,settings.choices.window_size.size.x)), "translated display choices align in one readable column")
		await capture("display")
		await window_click(settings.get_ok_button(),settings)
		await capture("display-preview")
		check(settings.pending and not settings.options_column.visible and settings_themed(settings) and settings_fits(settings), "the themed Apply action preserves native display preview and readable Keep/Revert actions")
		await window_click(settings.get_cancel_button(),settings)
		check(not settings.pending and settings.options_column.visible, "the themed Revert action restores the original display choices")
		await window_click(settings.get_cancel_button(),settings)
	await frames()
	check(menu.navigation.settings_page.visible and not menu.navigation.settings_shade.visible and root.gui_get_focus_owner() == menu.navigation.settings_buttons.display, "closing a submenu restores its category and keyboard focus")
	await click(menu.sound_button)
	var sound := dialog("sliders")
	check(sound != null and sound.sliders.size() == 5, "Audio category retains five native volume controls")
	if sound != null:
		check(settings_themed(sound) and settings_fits(sound), "Sound shares the focused shell and clear footer")
		await capture("sound")
		sound.canceled.emit()
	await frames()
	for spec in [["graphics","choice"],["interface","sizes"],["controls","key_buttons"],["game","choices"]]:
		await click(menu.navigation.settings_buttons[spec[0]])
		var child := dialog(spec[1])
		check(child != null, str(spec[0])+" category opens the retained settings page")
		if child != null:
			check(settings_themed(child) and settings_fits(child), str(spec[0])+" shell and full footer fit at default sizes")
			if spec[0] != "controls": await capture(spec[0])
		if child != null and spec[0] == "interface":
			child.sizes.ui.select(2)
			child.sizes.text.select(2)
			child.sizes.text.item_selected.emit(2)
			await frames(20)
			check(root.get_node("UiAccess").ui_size == 125 and root.get_node("UiAccess").text_size == 130 and child.theme.get_font_size("font_size","Button") == 22 and settings_fits(child), "Interface preview keeps drafts and updates its own themed text/spacing live")
			await capture("interface-preview")
		if child != null and spec[0] == "game":
			child.open_settings("res://ui/display_dialog.gd")
			await frames()
			var nested := dialog("preview_options")
			check(nested != null and not child.visible and settings_themed(nested), "nested Game to Display keeps only the active settings shell visible")
			if nested != null: nested.canceled.emit()
			await frames()
			check(child.visible and settings_themed(child) and settings_fits(child), "nested Back restores Game settings without exposing the hub")
		if child != null and spec[0] == "controls":
			check(child.key_buttons.orbit_left.get_theme_stylebox("normal") is StyleBoxFlat and controls_text_fits(child), "compact key and dialog labels fit clear surfaces without ornamental overlap")
			await capture("controls")
			child.begin_capture("orbit_left")
			await frames()
			check(controls_text_fits(child), "translated key-capture prompt fits with full text padding")
			await capture("controls-asking")
			child.end_capture()
			root.get_node("UiAccess").apply(125,130)
			await frames(20)
			check(controls_text_fits(child), "compact labels retain full padding at 125% UI and 130% text")
			await capture("controls-large")
			root.get_node("UiAccess").apply(100,100)
			await frames()
		if child != null: child.canceled.emit()
		await frames()
		if spec[0] == "interface":
			check(root.get_node("UiAccess").ui_size == 100 and root.get_node("UiAccess").text_size == 100 and menu.navigation.settings_page.visible, "Interface Cancel restores previous sizes and the category hub")
	await click(menu.navigation.settings_back)
	for size in [Vector2i(1280,800),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size)
		root.get_node("UiAccess").apply(125,130)
		await frames(25)
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(panel.get_global_rect()), "125% UI / 130% text shell fits " + str(size))
		menu.get_node("%Interface").grab_focus()
		await frames(15)
		check(menu.get_node("%MainScroll").get_global_rect().has_point(menu.get_node("%Interface").get_global_rect().get_center()) and menu.get_node("%Interface").size.x >= menu.get_node("%Interface").get_minimum_size().x, "Settings stays fully visible without scrolling")
		var actions_visible := true
		for button in [menu.continue_button,menu.new_game_button,menu.load_game_button,menu.get_node("%Interface"),menu.navigation.extras_button,menu.quit_button,menu.language_button]:
			if button.visible: actions_visible = actions_visible and panel.get_global_rect().encloses(button.get_global_rect())
		check(actions_visible, "all main choices remain fully visible at enlarged sizes")
		check(cursor.cursor_size == 60 and cursor.hotspots.arrow.x < 12 and cursor.hotspots.arrow.y < 12, "cursor follows interface size with its tip hotspot aligned")
		await capture("large-%d" % size.y)
		await click(menu.get_node("%Interface"))
		check(menu.page == "settings" and Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(menu.navigation.settings_page.get_global_rect()), "enlarged settings category page fits the viewport")
		check(category_content_fits(),"enlarged category contents stay clear of the carved frame")
		for spec in [["display","preview_options"],["graphics","choice"],["sound","sliders"],["interface","sizes"],["controls","key_buttons"],["game","choices"]]:
			await click(menu.navigation.settings_buttons[spec[0]])
			var child := dialog(spec[1])
			check(child != null and settings_themed(child) and settings_fits(child), str(spec[0])+" full shell/footer fit at enlarged "+str(size))
			if child != null:
				if spec[0] in ["display","controls","interface"]: await capture(str(spec[0])+"-large-%d" % size.y)
				child.canceled.emit()
			await frames()
		await click(menu.navigation.settings_back)
		await frames()
	root.get_node("UiAccess").apply(100,100)
	DisplayServer.window_set_size(Vector2i(1600,1000))
	menu.show_page("main")
	await frames(20)
	check(FileAccess.get_sha256(fixture) == original_hash and menu.opened == null and not Engine.has_meta("ezeus_simulation"), "menu browsing, profile switching and dialogs do not change saved city or adopt a simulation")
	if OS.get_cmdline_user_args().has("--menu-only"):
		print("MAIN_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks," language=",language," menu_only=true")
		quit(0 if okay else 1)
		return
	# Read the same copy through the native service: its current record count includes
	# components that can change as the presentation contracts evolve.
	var probe: RefCounted = ClassDB.instantiate("EZeusSimulation")
	probe.set_save_directory(SaveFiles.directory())
	var expected: Dictionary = probe.open_city(menu.engine,fixture,menu.core_language())
	var expected_buildings: int = expected.get("buildings",[]).size()
	probe.close_city()
	# Stop the reopened simulation before gameplay ticks can create livestock/components.
	await click(menu.continue_button,0)
	var deadline := Time.get_ticks_msec() + 25000
	while (current_scene == null or current_scene.scene_file_path != "res://main.tscn" or current_scene.get("state") == null or current_scene.state.is_empty() or current_scene.process_mode == Node.PROCESS_MODE_DISABLED) and Time.get_ticks_msec() < deadline:
		await process_frame
	var city: Node = current_scene
	check(city != null and city.scene_file_path == "res://main.tscn" and city.get("state") != null and not city.state.is_empty(), "actual Continue button reopens the native saved city")
	if city != null and city.scene_file_path == "res://main.tscn":
		check(root.get_node("GameCursor") == cursor and cursor.registered_shapes.size() == 17 and cursor.cursor_size == 48, "custom cursors persist from the menu into native gameplay")
		city.core.query("pause 1")
		city.core.set_process(false)
		check(not expected.has("error") and city.tiles.size() == 25992 and city.tiles.size() == expected.get("tiles",[]).size() and city.state.buildings.size() == expected_buildings, "Continue matches the native read of the full saved city (%d/%d cells, %d/%d building records)" % [city.tiles.size(),expected.get("tiles",[]).size(),city.state.buildings.size(),expected_buildings])
		city.core.simulation.close_city()
		city.queue_free()
	await frames(12)
	check(FileAccess.get_sha256(fixture) == original_hash, "Continue does not overwrite the saved city")
	print("MAIN_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks," language=",language)
	quit(0 if okay else 1)
