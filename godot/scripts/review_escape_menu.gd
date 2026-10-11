extends SceneTree
# Owned visible review, designated save, scratch preferences. No city writes or choices answered.
const DisplayOptions = preload("res://scripts/display_settings.gd")
var city: Node3D
var okay := true
var checks := 0
var language := "en"
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks+=1;okay=okay and value
	print("ESCAPE_CHECK ","PASS " if value else "FAIL ",description)
	if not value:
		print("ESCAPE_CONTEXT ",JSON.stringify({"mode":city.mode,"goals":city.hud.goals_list.visible,"inspector":city.inspector.visible,"header_focus":city.hud._header_has_focus(),"resources":city.hud.resources_open,"help":is_instance_valid(city.city_help) and city.city_help.visible,"dialog":root.get_node("UiAccess").dialog_open,"windows":city.hud.get_children().filter(func(node):return node is Window and node.visible).map(func(node):return node.name),"focus":str(root.gui_get_focus_owner()),"menu":is_instance_valid(city.escape_menu)}))
func frames(count:=10) -> void:
	for frame in count:await process_frame
func text_fits(button: Button) -> bool:
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var space := button.size-button.get_theme_stylebox("normal").get_minimum_size()
	return font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= space.x+1 and font.get_height(font_size) <= space.y+1
func escape() -> void:
	for pressed in [true,false]:
		var key:=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.keycode=KEY_ESCAPE;key.pressed=pressed
		key.set_meta("review_input",true);root.push_input(key,true)
	await frames()

func tab() -> void:
	for pressed in [true,false]:
		var key:=InputEventKey.new();key.physical_keycode=KEY_TAB;key.keycode=KEY_TAB;key.pressed=pressed
		key.set_meta("review_input",true);root.push_input(key,true)
	await frames(2)
func right_click(point: Vector2, surface: Window=null) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=pressed
		event.set_meta("review_input",true)
		if surface==null:root.push_input(event,true)
		else:surface.window_input.emit(event)
	await frames()

func click(button: Control) -> void:
	var point:=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		event.set_meta("review_input",true);root.push_input(event,true)
	await frames()
func window_click(button: Button, surface: Window) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = Vector2(surface.position)+button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		event.set_meta("review_input",true); root.push_input(event,true)
	await frames(15)
func reach(action: String) -> void:
	var menu: Control = city.escape_menu
	var destination := "home"
	for key in menu.PAGE_ACTIONS:
		if action in menu.PAGE_ACTIONS[key]: destination = key
	if menu.page != destination:
		if menu.page != "home": await click(menu.back_button)
		if destination != "home": await click(menu.navigation_buttons[destination])

func visible_buttons(menu: Control) -> Array:
	var result: Array = menu.buttons.values().filter(func(button): return button.is_visible_in_tree())
	result.append_array(menu.navigation_buttons.values().filter(func(button): return button.is_visible_in_tree()))
	if menu.back_button.visible: result.append(menu.back_button)
	return result

func navigation_scrolls(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is Window: continue # Native dropdown popups own scrollable item lists.
		if child is ScrollContainer: result.append(child)
		result.append_array(navigation_scrolls(child))
	return result

func window() -> Window:
	var windows: Array=city.hud.get_children().filter(func(child):return child is Window and child.visible)
	return windows[-1] if not windows.is_empty() else null
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground();await frames(12);RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/escape-"+name+"-"+language+".png")
func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="):language=argument.get_slice("=",1)
	city=load("res://main.tscn").instantiate();root.add_child(city)
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count<80:await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.set_process(false);city.orbit.enabled=false
	city.close_inspection();city.set_tool("select");city.hud.close_build_tray();city.hud.set_messages_open(false);city.hud.set_goals_expanded(false)
	DisplayServer.window_set_size(Vector2i(1600,1000));await frames()
	var hud: Control=city.hud
	check(not hud.has_node("Utilities") and not hud.has_node("Language") and not hud.has_node("GameMenu"),"language and gear panel removed from game HUD")
	check(hud.get_node("%ResourceRibbon").get_global_rect().encloses(hud.get_node("%StatsGroup").get_global_rect()) and hud.get_node("%StatsGroup").get_parent().name=="OverviewRow","native treasury and population share the top resource bar")
	hud.set_minimap_open(true);await frames();await capture("city-map")
	var chart: Control=hud.minimap
	check(chart.map_scale()*chart.occupied_radius>minf(chart.size.x,chart.size.y)*.5 and not chart._has_point(Vector2.ONE),"native chart covers circle with clipped, click-through corners")
	var map_image:=root.get_texture().get_image();var map_rect: Rect2=hud.get_node("%MinimapPanel").get_global_rect();var pixel_scale:=Vector2(map_image.get_size())/hud.size
	map_image.get_region(Rect2i(map_rect.position*pixel_scale,map_rect.size*pixel_scale)).save_png("res://captures/escape-map-detail-"+language+".png")
	var native_before: Dictionary=city.core.simulation.snapshot(true)
	# This open-play fixture has no goals. A disposable presentation goal covers
	# disclosure dismissal; it never changes the native episode or callbacks.
	if hud.goals_state.get("goals",[]).is_empty():
		hud.set_goals({"met":0,"total":1,"goals":[{"kind":"population","text":city.tr("Population"),"current":native_before.population,"required":int(native_before.population)+100,"met":false,"progress":.5}]})
	hud.open_category("Industry");city.set_tool("olive_press");await frames()
	await right_click(hud.get_node("%BuildTray").get_global_rect().get_center())
	check(not hud.get_node("%BuildTray").visible and city.mode=="select","right-click over building tray dismisses it and cancels tool")
	city.set_tool("road");city.road_drag.guard=false;city.road_drag.begin(city,city.origin,"road")
	await right_click(Vector2(500,400))
	check(not city.road_drag.active and city.mode=="select","right-click cancels road drag without building")
	city.inspected=Vector2i(native_before.buildings[0].x,native_before.buildings[0].y);city.refresh_inspection();await frames()
	await right_click(city.inspector.get_global_rect().get_center())
	check(not city.inspector.visible and not city.selection.visible,"right-click on inspector closes selection")
	hud.set_messages_open(true);await frames();await right_click(hud.message_panel.get_global_rect().get_center())
	check(not hud.message_panel.visible,"right-click closes the journal")
	check(absf(hud.get_node("%EventRail").get_global_rect().end.x-(hud.size.x-16))<1,"journal icon sits at the right screen edge")
	hud.set_messages_open(true);await frames()
	var journal: Rect2=hud.message_panel.get_global_rect()
	var rail: Rect2=hud.get_node("%EventRail").get_global_rect()
	check(Rect2(Vector2.ZERO,hud.size).encloses(journal) and not journal.intersects(rail) and journal.position.y>=hud.get_node("%StatusBar").get_global_rect().end.y and absf(journal.end.x-(rail.position.x-8))<1,"journal clears the right icon rail and resource header")
	await capture("journal-right")
	hud.set_messages_open(false)
	hud.set_resources_open(true);await create_timer(.3).timeout
	await right_click(hud.get_node("%ResourcesPanel").get_global_rect().get_center());await create_timer(.3).timeout
	check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible,"right-click folds resource panel")
	hud.set_goals_expanded(true);await frames();await right_click(hud.goals_panel.get_global_rect().get_center())
	check(not hud.goals_list.visible,"right-click folds objectives")
	hud.set_decision({"id":902020,"title":city.tr("Review decision")},2);hud.set_decision_expanded(true);await frames()
	var right_commands: Array=city.core.commands.duplicate()
	await right_click(Vector2(500,400))
	check(not hud.decision_expanded and hud.decision_id==902020 and city.core.commands==right_commands,"right-click folds required decision without answering it")
	hud.set_decision({});hud.set_minimap_open(false,true)
	city.open_escape_menu();await frames();await right_click(Vector2(500,400))
	check(not is_instance_valid(city.escape_menu),"right-click closes game menu through its existing return callback")
	# The legacy overlay MenuButton is hidden by the current dock. Exercise the
	# existing nested-popup dismissal handler on a visible owned HUD fixture.
	var speed_popup := PopupMenu.new()
	hud.add_child(speed_popup); speed_popup.add_item("Review popup")
	hud._attach_right_click_back(speed_popup)
	DisplayServer.window_move_to_foreground(); await frames(3)
	speed_popup.popup(Rect2i(Vector2i(300,300),Vector2i(180,140)))
	await frames()
	check(speed_popup.visible,"a nested popup opens for right-click dismissal")
	# Popup OS events enter through Window.window_input in local coordinates.
	await right_click(Vector2(speed_popup.size)*.5,speed_popup)
	check(not speed_popup.visible,"right-click folds a nested popup without choosing an item")
	speed_popup.queue_free()
	city.close_inspection()
	hud.set_messages_open(true);await frames();await escape()
	check(not hud.message_panel.visible and not is_instance_valid(city.escape_menu),"Escape closes journal without opening settings")
	hud.set_goals_expanded(true);await frames();await escape()
	check(not hud.goals_list.visible and not is_instance_valid(city.escape_menu),"Escape folds objectives first")
	city.inspected=Vector2i(native_before.buildings[0].x,native_before.buildings[0].y);city.refresh_inspection();await frames();await escape()
	check(not city.inspector.visible and not is_instance_valid(city.escape_menu),"Escape closes building inspector first")
	hud.open_category("Industry");city.set_tool("olive_press");await frames();await escape()
	check(not hud.get_node("%BuildTray").visible and city.mode=="olive_press" and not is_instance_valid(city.escape_menu),"Escape closes construction tray first")
	await escape();check(city.mode=="select" and not is_instance_valid(city.escape_menu),"next Escape cancels active construction tool")
	city.set_overlay("water");await frames();await escape()
	check(not city.overlay_view.active() and not is_instance_valid(city.escape_menu),"Escape clears city overlay first")
	city.set_tool("road");city.road_drag.guard=false
	city.road_drag.begin(city,city.origin,"road");await escape()
	check(not city.road_drag.active and city.mode=="road" and not is_instance_valid(city.escape_menu),"Escape cancels a road drag while keeping its tool and native city untouched")
	await escape();city.open_army();await frames();await escape()
	check(not city.army_panel.visible and not is_instance_valid(city.escape_menu),"Escape closes army before opening menu")
	hud.set_decision({"id":902020,"title":city.tr("Review decision")},2);hud.set_decision_expanded(true);await frames()
	var pending_commands: Array=city.core.commands.duplicate()
	await escape()
	check(not hud.decision_expanded and hud.decision_id==902020 and city.core.commands==pending_commands and not is_instance_valid(city.escape_menu),"Escape folds a decision without sending an answer or opening settings")
	hud.set_decision({})
	city.core.commands.assign(["snapshot","episode"])
	var queue_before: Array=city.core.commands.duplicate()
	city.core.query("pause 0");await escape()
	check(is_instance_valid(city.escape_menu) and city.escape_menu.visible and city.core.simulation.snapshot(false).paused and city.core.commands_held,"Escape opens redesigned menu and synchronously pauses running city")
	if not is_instance_valid(city.escape_menu):quit(1);return
	var menu: Control=city.escape_menu
	check(menu.panel.get_theme_stylebox("panel") is StyleBoxTexture and menu.page=="home" and visible_buttons(menu).size()==6,"wood-frame main page has six choices instead of nineteen actions")
	check(navigation_scrolls(menu).is_empty(),"all game-menu navigation pages fit without scrolling")
	check(visible_buttons(menu).all(func(button):return text_fits(button) and button.size.y>=52 and button.get_theme_font_size("font_size")>=18),"larger game-menu actions have clear full labels and at least 52-pixel targets")
	check(hud.GAME_ACTIONS.all(func(action):return action.is_empty() or menu.buttons.has(action)) and menu.find_children("*","OptionButton",true,false).is_empty(),"every existing city/settings action remains accessible without an extra language choice in the hub")
	var time_before: float=city.core.simulation.snapshot(false).time
	city.core._process(.5)
	check(city.core.simulation.snapshot(false).time==time_before and city.core.commands==queue_before,"menu holds native clock and queued command order")
	await capture("menu")
	await escape()
	check(not is_instance_valid(city.escape_menu) and not city.core.simulation.snapshot(false).paused and not city.core.commands_held and city.core.commands==queue_before,"Escape returns to running city and restores original queue hold")
	city.core.commands.clear();city.core.query("pause 1");city.core.commands_held=true
	await escape();await click(city.escape_menu.buttons.resume)
	check(not is_instance_valid(city.escape_menu) and city.core.simulation.snapshot(false).paused and city.core.commands_held,"Resume button preserves an already paused city and prior queue hold")
	city.core.commands_held=false;await escape();menu=city.escape_menu
	for action in ["display","graphics","interface","controls","sound","settings","city","trade","mythology","save","load","main_menu"]:
		await reach(action)
		var parent_page: String = menu.page
		await click(menu.buttons[action])
		var dialog: Window=window()
		check(dialog!=null and not menu.visible and city.core.commands_held,"menu opens "+action+" page while holding city")
		if dialog==null:continue
		check(dialog.transparent_bg and dialog.get_theme_stylebox("embedded_border") is StyleBoxTexture,"framed "+action+" window retains its complete native input rectangle and visible art")
		await capture("dialog-"+action)
		if action=="settings": check(dialog.settings_buttons.is_empty(),"gameplay settings contain only gameplay options; other settings live in the settings hub")
		await right_click(Vector2(dialog.position)+Vector2(dialog.size)*.5)
		check(menu.visible and root.get_node("UiAccess").dialog_open and window()==null and menu.page==parent_page and root.gui_get_focus_owner()==menu.buttons[action],"right-click cancels "+action+" page and restores its parent and opener focus")
	# Settings nested inside settings return one level at a time.
	await reach("settings")
	# Legacy API callers retain the original nested behavior; both normal menu routes omit it.
	menu.suspend()
	var gameplay: Window=preload("res://ui/game_settings_dialog.gd").open(hud,true)
	menu.watch(gameplay)
	await frames()
	gameplay.settings_buttons.display.pressed.emit();await frames()
	var display: Window=window();var before_window:=DisplayOptions.capture(root)
	display.choices.frame_limit.select(1);display.apply_or_keep();await frames();await escape()
	check(not is_instance_valid(display) and gameplay.visible and root.size==before_window.actual_size and Engine.max_fps==before_window.frame_limit,"Escape reverts display preview, closes it and returns to gameplay settings")
	var graphics_options = preload("res://scripts/graphics_settings.gd")
	var original_graphics: String = graphics_options.current
	gameplay.settings_buttons.graphics.pressed.emit(); await frames()
	var graphics: Window = window()
	graphics.choice.select(0); graphics.preview(); await frames(); await escape()
	check(not is_instance_valid(graphics) and gameplay.visible and graphics_options.current == original_graphics,"Escape restores graphics preview and returns one level to game settings")
	await escape();check(menu.visible and window()==null and menu.page=="settings","next Escape closes legacy gameplay settings and restores settings hub")
	var initial_language: String=city.language
	# Normal launches remember the chosen locale. This reviewer has scratch settings;
	# its direct --script city launch otherwise intentionally disables persistence.
	city.persist_language = true
	await reach("interface"); await click(menu.buttons.interface)
	var interface_options: Window = window()
	check(interface_options.language_choice.item_count == 2 and interface_options.original_language == initial_language,"game language is grouped with interface settings and starts on the active locale")
	interface_options.language_choice.select(0 if initial_language == "ru" else 1)
	check(city.language == initial_language,"language selection remains a draft until Apply")
	await window_click(interface_options.get_cancel_button(),interface_options)
	check(city.language == initial_language and menu.visible,"Interface Cancel retains the city language and restores Settings")
	for wanted in ["en" if initial_language == "ru" else "ru",initial_language]:
		await click(menu.buttons.interface)
		interface_options = window()
		interface_options.language_choice.select(1 if wanted == "ru" else 0)
		await window_click(interface_options.get_ok_button(),interface_options)
		check(city.language == wanted and preload("res://scripts/user_settings.gd").language() == wanted and menu.title_label.text == city.tr("Settings") and menu.buttons.interface.text == city.tr("Interface"),"Interface Apply persists language and updates the city and menu without rebuilding controls")
	for dimensions in [Vector2i(1600,1000),Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(dimensions)
		for scaling in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scaling.x,scaling.y);await frames()
			if menu.page!="home": await click(menu.back_button)
			for destination in menu.PAGE_TITLES:
				if destination!="home": await click(menu.navigation_buttons[destination])
				var controls := visible_buttons(menu)
				var bounds := Rect2(Vector2.ZERO,hud.size).grow(-20)
				check(bounds.encloses(menu.panel.get_global_rect()) and controls.all(func(button): return menu.panel.get_global_rect().grow(-32).encloses(button.get_global_rect())),"complete "+destination+" frame and actions fit "+str(dimensions)+" "+str(scaling))
				check(controls.all(func(button):return text_fits(button) and button.size.y>=52),"full "+destination+" labels and larger buttons fit "+str(dimensions)+" "+str(scaling))
				if dimensions==Vector2i(1600,1000) and scaling.x==100:
					var focus_order: Array = menu.focus_controls()
					focus_order[0].grab_focus()
					var contained := true
					for index in range(1,focus_order.size()+1):
						await tab()
						contained = contained and root.gui_get_focus_owner()==focus_order[index%focus_order.size()]
					check(contained,"Tab follows the visible "+destination+" page and wraps without reaching hidden pages or the HUD")
				if dimensions==Vector2i(1600,1000) and scaling.x==100:await capture("page-"+destination)
				if dimensions==Vector2i(1280,720) and scaling.x==125:await capture("page-"+destination+"-large")
				if destination!="home":
					await escape()
					check(menu.page=="home" and root.gui_get_focus_owner()==menu.navigation_buttons[destination] and city.core.commands_held and city.core.simulation.snapshot(false).paused,"Escape from "+destination+" restores hub focus without resuming city")
			if dimensions==Vector2i(1280,720) and scaling.x==125:
				for action in ["display","graphics","interface","controls","sound","settings","save","load","main_menu"]:
					await reach(action); await click(menu.buttons[action])
					var dialog: Window = window()
					if dialog==null: check(false,"scaled "+action+" dialog opens"); continue
					var title_height: float = dialog.get_theme_constant("title_height")
					var frame := Rect2(Vector2(dialog.position)-Vector2(6,title_height),Vector2(dialog.size)+Vector2(12,title_height+6))
					check(Rect2(Vector2.ZERO,hud.size).encloses(frame),"scaled "+action+" dialog frame and footer stay inside the window")
					var footer: Array = dialog.get_ok_button().get_parent().get_children(true).filter(func(button):return button is Button and button.visible)
					check(footer.all(func(button):return text_fits(button) and button.size.y>=48),"scaled "+action+" footer has larger readable actions")
					if action in ["display","controls","settings"]: await capture("dialog-"+action+"-large")
					await right_click(Vector2(dialog.position)+Vector2(dialog.size)*.5)
				if menu.page!="home": await click(menu.back_button)
	root.get_node("UiAccess").apply(100,100);await escape()
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(native_before.time==after.time and native_before.money==after.money and native_before.buildings==after.buildings and native_before.events==after.events,"menu navigation preserves native city, timing and pending event callbacks")
	city.queue_free();await frames(8);city=null;await frames(4)
	print("ESCAPE_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
