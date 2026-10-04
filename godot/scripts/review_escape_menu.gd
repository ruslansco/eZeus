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
func frames(count:=10) -> void:
	for frame in count:await process_frame
func escape() -> void:
	for pressed in [true,false]:
		var key:=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.keycode=KEY_ESCAPE;key.pressed=pressed
		key.set_meta("review_input",true);root.push_input(key,true)
	await frames()
func right_click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_RIGHT;event.pressed=pressed
		event.set_meta("review_input",true);root.push_input(event,true)
	await frames()

func click(button: Control) -> void:
	var point:=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		event.set_meta("review_input",true);root.push_input(event,true)
	await frames()
func window() -> Window:
	var windows: Array=city.hud.get_children().filter(func(child):return child is Window and child.visible)
	return windows[-1] if not windows.is_empty() else null
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground();await frames(12);await RenderingServer.frame_post_draw
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
	check(hud.get_node("%ResourceRibbon").get_global_rect().encloses(hud.get_node("%StatsGroup").get_global_rect()) and hud.get_node("%StatsGroup").get_parent().name=="OverviewRow","native treasury, population and jobs share the top resource bar")
	hud.set_minimap_open(true);await frames();await capture("city-map")
	var chart: Control=hud.minimap
	check(chart.map_scale()*chart.occupied_radius>minf(chart.size.x,chart.size.y)*.5 and not chart._has_point(Vector2.ONE),"native chart covers circle with clipped, click-through corners")
	var map_image:=root.get_texture().get_image();var map_rect: Rect2=hud.get_node("%MinimapPanel").get_global_rect();var pixel_scale:=Vector2(map_image.get_size())/hud.size
	map_image.get_region(Rect2i(map_rect.position*pixel_scale,map_rect.size*pixel_scale)).save_png("res://captures/escape-map-detail-"+language+".png")
	var native_before: Dictionary=city.core.simulation.snapshot(true)
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
	check(absf(hud.message_panel.get_global_rect().position.y-hud.get_node("%EventRail").get_global_rect().end.y-8)<1 and absf(hud.message_panel.get_global_rect().end.x-hud.get_node("%EventRail").get_global_rect().end.x)<1,"journal opens below its right-side icon with aligned edges")
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
	var speed_popup: PopupMenu=hud.speed_button.get_popup()
	speed_popup.popup(Rect2i(Vector2i(300,300),Vector2i(180,140)))
	await frames()
	check(speed_popup.visible,"speed popup opens for right-click dismissal")
	await right_click(Vector2(speed_popup.position)+Vector2(speed_popup.size)*.5)
	check(not speed_popup.visible,"right-click folds a nested popup without selecting speed")
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
	check(hud.GAME_ACTIONS.all(func(action):return action.is_empty() or menu.buttons.has(action)) and menu.language_choice.item_count==2,"every existing city/settings action and both languages remain accessible")
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
	for action in ["display","interface","controls","sound","settings","city","trade","mythology","save","load","main_menu"]:
		await click(menu.buttons[action])
		var dialog: Window=window()
		check(dialog!=null and not menu.visible and city.core.commands_held,"menu opens "+action+" page while holding city")
		if dialog==null:continue
		await right_click(Vector2(dialog.position)+Vector2(dialog.size)*.5)
		check(menu.visible and root.get_node("UiAccess").dialog_open and window()==null,"right-click cancels "+action+" page and restores menu")
	# Settings nested inside settings return one level at a time.
	await click(menu.buttons.settings)
	var gameplay: Window=window()
	gameplay.settings_buttons.display.pressed.emit();await frames()
	var display: Window=window();var before_window:=DisplayOptions.capture(root)
	display.choices.frame_limit.select(1);display.apply_or_keep();await frames();await escape()
	check(not is_instance_valid(display) and gameplay.visible and root.size==before_window.actual_size and Engine.max_fps==before_window.frame_limit,"Escape reverts display preview, closes it and returns to gameplay settings")
	await escape();check(menu.visible and window()==null,"next Escape closes gameplay settings and restores main menu")
	var initial_language: String=city.language
	menu.language_choice.item_selected.emit(0 if initial_language=="ru" else 1);await frames()
	check(city.language!=initial_language and menu.headings["Game menu"].text==city.tr("Game menu"),"language selector updates game and menu without rebuilding controls")
	menu.language_choice.item_selected.emit(1 if initial_language=="ru" else 0);await frames()
	for dimensions in [Vector2i(1600,1000),Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(dimensions)
		for scaling in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scaling.x,scaling.y);await frames()
			check(menu.panel.get_global_rect().size.x<=hud.size.x-40 and menu.panel.get_global_rect().position.x>=20,"menu horizontal bounds fit "+str(dimensions)+" "+str(scaling))
			menu.buttons.trade.grab_focus();await frames()
			check(Rect2(Vector2.ZERO,hud.size).encloses(menu.buttons.trade.get_global_rect()),"keyboard scroll reaches last menu action "+str(dimensions)+" "+str(scaling))
			menu.buttons.resume.grab_focus();await frames()
			if dimensions==Vector2i(1280,720) and scaling.x==125:await capture("menu-large")
	root.get_node("UiAccess").apply(100,100);await escape()
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(native_before.time==after.time and native_before.money==after.money and native_before.buildings==after.buildings and native_before.events==after.events,"menu navigation preserves native city, timing and pending event callbacks")
	city.queue_free();await frames(8);city=null;await frames(4)
	print("ESCAPE_MENU_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
