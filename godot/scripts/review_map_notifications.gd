extends SceneTree
# Only the designated city. Layout fixtures never answer native decisions or write a city.
var city: Node3D
var checks := 0
var okay := true
var sample_messages: Array = []

func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"):
		Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1; okay = okay and value
	print("MAP_NOTICE_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 8) -> void:
	for frame in count: await process_frame

func click(control: Control) -> void:
	await frames()
	var point := control.get_global_rect().get_center()
	var move := InputEventMouseMotion.new(); move.position = point; root.push_input(move, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.position = point; event.pressed = pressed
		root.push_input(event, true)
	await frames()

func ground_cell() -> Vector2i:
	for section in city.terrain_details.records.values():
		for item in section:
			if item.kind in ["stone", "tall_stone", "copper", "silver", "marble", "black_marble", "orichalcum"]:
				return item.cell
	for cell in city.tiles:
		if not city.core.query("inspect %d %d" % [cell.x, cell.y]).has("footprint"):
			return cell
	return city.origin

func fixture() -> void:
	city.hud.set_decision({})
	for child in city.hud.events_panel.get_children(): child.free()
	for child in city.hud.toasts.get_children(): child.free()
	city.hud.alert_queue.clear()
	if not sample_messages.is_empty():
		for index in 3:
			var event: Dictionary=sample_messages[index]
			city.hud.show_toast(-10-index, str(event.title).substr(0,1).to_upper()+str(event.title).substr(1),str(event.text))
	else:
		var title: String = city.tr("Water")
		var body: String = city.tr("Homes assessed: %d") % 152 + "\n" + city.tr("Click to read the full message") + "\n"
		for index in 3: city.hud.show_toast(-10-index, title + " · " + str(index+1), body.repeat(12))

func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12); await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	screenshot.save_png("res://captures/map-notices-" + name + "-" + city.language + ".png")
	if name == "map-reading":
		var panel: Rect2 = city.hud.get_node("%MinimapPanel").get_global_rect()
		var pixel_scale: Vector2 = Vector2(screenshot.get_size()) / city.hud.size
		var region := Rect2i(panel.position * pixel_scale, panel.size * pixel_scale)
		screenshot.get_region(region).save_png("res://captures/map-notices-map-detail-" + city.language + ".png")
	print("MAP_NOTICE_CAPTURE ", name, " viewport=", city.hud.size)

func run() -> void:
	city = load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 80: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false); city.orbit.enabled = false
	if OS.get_cmdline_user_args().has("--native-map"):
		city.core.set_process(true)
		var previous=load("res://scripts/validate_main.gd").new();previous.city=city
		var passed: bool=await previous.run_minimap_checks()
		print("MAP_NOTICE_NATIVE_MAP ","PASS" if passed else "FAIL", " checks=8")
		quit(0 if passed else 1);return
	if OS.get_cmdline_user_args().has("--checks"):
		await validate()
		await aegean_checks()
		await nova_checks()
		print("MAP_NOTICE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
		quit(0 if okay else 1); return
	# Actual engine-written news, raised only in this disposable review; no native callbacks are supplied.
	city.core.simulation.enable_test_commands()
	for command in ["test_raise godVisit god zeus","test_raise monsterSlain monster hydra","test_raise famineAllyComply city 1"]:
		var result: Dictionary=city.core.query(command)
		sample_messages.append(result.events[-1])
	root.gui_disable_input = true
	DisplayServer.window_set_size(Vector2i(1600,1000)); await frames()
	city.hud.set_minimap_open(false)
	city.hud.set_goals(city.core.query("episode"))
	await capture("nova-idle")
	city.hud.set_minimap_open(true); await capture("nova-map"); city.hud.set_minimap_open(false)
	city.state.events = city.core.simulation.snapshot(false).events
	city.event_signature="";city.update_events()
	city.hud.set_messages_open(true);await frames()
	await capture("nova-journal")
	city.hud.set_messages_open(false)
	city.hud.open_category("Industry")
	city.set_tool("olive_press")
	DisplayServer.window_move_to_foreground()
	var thumbnail_deadline := Time.get_ticks_msec() + 10000
	while (city.hud.thumbnails.busy or not city.hud.thumbnails.pending.is_empty()) and Time.get_ticks_msec() < thumbnail_deadline:
		await frames()
	await capture("nova-build")
	city.hud.close_build_tray();city.set_tool("road"); await capture("nova-road"); city.set_tool("select")
	fixture(); city.hud.set_minimap_open(false)
	await capture("compact")
	city.hud.set_minimap_open(true); city.hud.toasts.get_child(0).set_expanded(true)
	await capture("map-reading")
	city.inspected=ground_cell();city.refresh_inspection()
	await capture("map-ground")
	city.close_inspection()
	fixture(); city.hud.set_decision({"id":902020,"title":city.tr("Review decision")},2)
	await capture("decision-chip")
	for action in [city.tr("Accept"), city.tr("Refuse")]:
		var button := Button.new(); button.text = action; city.hud.events_panel.add_child(button)
	var detail := Label.new(); detail.text = str(sample_messages[0].text).repeat(4); detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city.hud.events_panel.add_child(detail); city.hud.set_decision_expanded(true)
	root.get_node("UiAccess").apply(125,130); DisplayServer.window_set_size(Vector2i(1280,720))
	await capture("decision-720")
	city.hud.set_decision({}); city.hud.set_messages_open(true); city.hud.set_messages(city.message_log.entries + [{"id":-21,"date":city.hud.date_label.text,"title":str(sample_messages[0].title).capitalize(),"text":str(sample_messages[0].text)}])
	city.hud.message_list.get_child(0).set_expanded(true)
	city.hud.open_category("Industry")
	await capture("history-720")
	city.hud.set_messages_open(false);city.hud.close_build_tray();fixture()
	city.inspected=ground_cell();city.refresh_inspection();city.hud.set_minimap_open(true)
	await capture("map-ground-720")
	var warehouse: Dictionary=city.state.buildings.filter(func(b):return b.asset=="warehouse")[0]
	city.inspected=Vector2i(warehouse.x,warehouse.y);city.refresh_inspection();city.hud.set_minimap_open(true)
	await capture("map-inspector-720")
	print("MAP_NOTICE_REVIEW_DONE"); quit()

func validate() -> void:
	var hud: Control = city.hud
	var native_before: Dictionary = city.core.simulation.snapshot(true)
	var queued_before: int=city.core.commands.size()
	await click(hud.pause_button)
	check(city.core.commands.size()==queued_before+1 and city.core.commands[-1]=="pause 0","the top bar pause uses the original native command")
	city.core.commands.pop_back()
	var original_speed: int=int(city.state.speed)
	await click(hud.speed_buttons[3])
	check(city.core.commands.size()==queued_before+1 and city.core.commands[-1]=="speed 3","the top bar's fourth chevron forwards the native top speed through real input")
	if city.core.commands.size()>queued_before:city.core.commands.pop_back()
	hud.set_speed(original_speed)
	hud.set_minimap_open(true)
	check(hud.get_node("%MinimapPanel").visible and not hud.get_node("%MapPeek").visible and hud.get_node("%MapToggle").button_pressed, "map is open without the removed corner shortcut")
	await click(hud.get_node("%MapToggle")); await click(hud.get_node("%MapToggle"))
	check(hud.get_node("%MinimapPanel").visible, "toolbar folds and reopens the live map through real input")
	var sample := Vector2(city.origin) + Vector2(city.extent) * .5
	var click_event := InputEventMouseButton.new();click_event.button_index=MOUSE_BUTTON_LEFT;click_event.pressed=true;click_event.position=hud.minimap.cell_to_point(sample)
	hud.minimap._gui_input(click_event)
	check(city.tile_coordinates(city.orbit.target).distance_to(sample)<.6 and absf(city.orbit.target.y-city.orbit.height_at(city.orbit.target.x,city.orbit.target.z))<.01,"minimap navigation retains native coordinates and ground height")
	click_event.pressed=false;hud.minimap._input(click_event)
	check(not hud.minimap.dragging,"release outside the minimap ends navigation")
	hud.minimap.set_camera(sample,90)
	check(hud.minimap.camera_known and hud.minimap.camera_cell==sample and hud.minimap.camera_yaw==90,"map camera marker follows orbit without rotating native coordinates")
	root.gui_release_focus()
	var overview_key := InputEventKey.new(); overview_key.physical_keycode = KEY_HOME; overview_key.pressed = true
	root.push_input(overview_key, true)
	overview_key.pressed = false; root.push_input(overview_key, true); await frames()
	check(is_equal_approx(city.orbit.distance,minf(maxf(city.extent.x,city.extent.y)*.95,city.orbit.maximum_distance)),"Home retains the bounded overview without a compass button")
	await click(hud.get_node("%MapClose"))
	check(not hud.get_node("%MinimapPanel").visible and not hud.get_node("%MapPeek").visible,"map close folds it while the toolbar retains the entry point")
	var scratch:="res://captures/map-pref-%d.cfg"%OS.get_process_id()
	var old_settings_path: Variant=Engine.get_meta("ezeus_settings_path",null)
	Engine.set_meta("ezeus_settings_path",scratch)
	var settings=load("res://scripts/user_settings.gd")
	settings.set_value("interface","language",city.language);settings.set_value("sound","music",.37)
	hud.set_minimap_open(true,true)
	check(settings.get_value("interface","minimap_visible",false)==true and settings.language()==city.language and is_equal_approx(settings.get_value("sound","music",0),.37),"map preference persists independently of language and sound")
	hud.set_minimap_open(false,true);check(settings.get_value("interface","minimap_visible",true)==false,"folded preference can be remembered")
	DirAccess.remove_absolute(scratch)
	if old_settings_path!=null:Engine.set_meta("ezeus_settings_path",old_settings_path)
	else:Engine.remove_meta("ezeus_settings_path")
	fixture();await frames()
	var chip: Control=hud.toasts.get_child(0)
	var dismissed: Array=[];var listener:=func(id):dismissed.append(id)
	hud.message_dismissed.connect(listener)
	check(hud.toasts.get_child_count()==1 and hud.alert_queue.size()==2 and not chip.expanded and chip.open and chip.body_scroll.visible and chip.size.y<=chip.OPEN_HEIGHT+90,"urgent news shows one notice with its text in full and queues the rest")
	await click(chip)
	check(chip.expanded and chip.body_scroll.visible and dismissed.is_empty(),"reading expands the full message without dismissing or answering it")
	var remaining: float=chip.remaining
	chip._process(3)
	check(is_equal_approx(remaining,chip.remaining),"reading suspends expiration")
	var reading_id: int=chip.message_id
	hud.show_toast(-99,"New message","More news")
	check(hud.toasts.get_child_count()==1 and chip.message_id==reading_id and chip.expanded and hud.alert_queue.size()==3,"incoming urgent news keeps the message being read and queues the rest")
	chip=hud.toasts.get_child(0);hud.set_messages_open(true);await frames();remaining=chip.remaining;chip._process(3)
	check(is_equal_approx(remaining,chip.remaining),"messages hidden by history do not expire while hidden")
	hud.set_messages_open(false);await frames()
	chip.set_expanded(false);hud.set_process(false)
	var scroll: ScrollContainer=hud.get_node("%ToastScroll")
	scroll.offset_bottom=scroll.offset_top;remaining=chip.remaining;chip._process(3)
	check(is_equal_approx(remaining,chip.remaining),"fully clipped chips wait until they are actually visible")
	hud.set_process(true);await frames()
	var expired_id: int=chip.message_id
	var motion:=InputEventMouseMotion.new();motion.position=Vector2(20,400);root.push_input(motion,true)
	chip.remaining=.01;chip._process(.02)
	check(dismissed.has(expired_id) and chip.get_parent()==null,"visible unread news expires through the existing dismissal signal")
	var old_choices: int=city.core.commands.size()
	hud.set_decision({"id":902000,"title":"An envoy arrives"},2)
	check(hud.events_box.visible and hud.decision_expanded and hud.get_node("%EventScroll").visible,"required decision automatically opens its correspondence card")
	hud.set_decision_expanded(false)
	hud.retranslate()
	check(hud.get_node("%DecisionCaption").text.contains("2") and hud.decision_id==902000,"retranslation retains the pending decision count and identity")
	await click(hud.get_node("%DecisionToggle"))
	check(hud.decision_expanded and hud.get_node("%EventScroll").visible and not hud.get_node("%ToastScroll").visible,"review exposes decision contents and gives them visual priority")
	await click(hud.get_node("%DecisionToggle"))
	check(not hud.decision_expanded and city.core.commands.size()==old_choices,"folding a decision sends no outcome to the native engine")
	hud.set_decision({})
	var warehouse: Dictionary=city.state.buildings.filter(func(b):return b.asset=="warehouse")[0]
	var ground:=ground_cell()
	for window_size in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(window_size)
		for sizes in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(sizes.x,sizes.y);hud.close_build_tray();hud.set_messages_open(false);city.close_inspection();hud.set_minimap_open(true);await frames()
			var map_before: Rect2=hud.get_node("%MinimapPanel").get_global_rect()
			city.inspected=ground;city.refresh_inspection();await frames()
			var ground_fixed: bool=hud.inspector_text.visible and map_before.is_equal_approx(hud.get_node("%MinimapPanel").get_global_rect())
			city.inspected=Vector2i(warehouse.x,warehouse.y);city.refresh_inspection();await frames()
			check(ground_fixed and map_before.is_equal_approx(hud.get_node("%MinimapPanel").get_global_rect()),"%s %s ground and building inspection never move the map"%[window_size,sizes])
			var screen:=Rect2(Vector2.ZERO,hud.size)
			var strip: Rect2=hud.get_node("%StatusBar").get_global_rect()
			var stats_fit:=true
			for name in ["Money","Citizens","Jobs"]:
				stats_fit=stats_fit and strip.grow(1).encloses(hud.get_node("%"+name).get_global_rect())
			var time: Rect2=hud.get_node("%TimeBar").get_global_rect()
			var time_fit: bool=strip.grow(1).encloses(time)
			for name in ["Pause","Speed","Date","Housing"]: time_fit=time_fit and strip.grow(1).encloses(hud.get_node("%"+name).get_global_rect())
			check(stats_fit and time_fit and screen.encloses(strip) and strip.size.y<=hud.size.y*.45 and not time.intersects(hud.get_node("%StatsGroup").get_global_rect()) and not hud.get_node("%StatsGroup").get_global_rect().intersects(hud.get_node("%WelfareGroup").get_global_rect()),"%s %s native header with its time bar and utility controls fit without overlap"%[window_size,sizes])
			check(screen.encloses(hud.get_node("%MinimapPanel").get_global_rect()) and not hud.get_node("%MinimapPanel").get_global_rect().intersects(hud.get_node("%BottomBar").get_global_rect()),"%s %s map clears toolbar"%[window_size,sizes])
			check(not hud.inspector.get_global_rect().intersects(hud.get_node("%MinimapPanel").get_global_rect()) and not hud.inspector.get_global_rect().intersects(hud.get_node("%ToastScroll").get_global_rect()),"%s %s map and news clear the open inspector"%[window_size,sizes])
			check(screen.encloses(hud.get_node("%ToastScroll").get_global_rect()) and hud.get_node("%ToastScroll").size.y<=toasts_height(hud)+1,"%s %s notification hit area follows visible contents"%[window_size,sizes])
			hud.set_messages_open(true);hud.open_category("Industry");await frames()
			check(screen.encloses(hud.message_panel.get_global_rect()) and hud.message_panel.get_global_rect().end.y<hud.get_node("%BuildTray").position.y,"%s %s history clears construction tray"%[window_size,sizes])
			hud.set_messages_open(false);hud.close_build_tray()
		root.get_node("UiAccess").apply(100,100)
	check(city.core.simulation.snapshot(true).money==native_before.money and city.core.simulation.snapshot(true).time==native_before.time and city.core.simulation.snapshot(true).walkers==native_before.walkers and city.core.simulation.snapshot(true).buildings==native_before.buildings,"UI/navigation checks leave native treasury, date and buildings intact")
	hud.message_dismissed.disconnect(listener)
	for child in hud.toasts.get_children():child.free()
	hud.alert_queue.clear()
	# Exercise the established native event/log integration, not just the new card component.
	var previous=load("res://scripts/validate_main.gd").new();previous.city=city
	check(await previous.run_message_checks(),"existing event deduplication, native dismissal and translated history checks pass")
	var original_events: Array=city.state.get("events",[]).duplicate(true)
	city.state.events=[{"id":903000,"title":"An envoy arrives","text":"Receive the envoy?","actions":[{"choice":0,"label":"Yes"},{"choice":1,"label":"No"}]}]
	city.event_signature="";city.update_events();await frames()
	var choices: Array=hud.get_node("%EventActions").get_children().filter(func(child):return child is Button)
	var queue_size: int=city.core.commands.size()
	await click(choices[0])
	check(city.core.commands.size()==queue_size+1 and city.core.commands[-1]=="event 903000 0","explicit decision choice retains the native event ID and callback value")
	city.core.commands.pop_back()
	hud.set_decision_expanded(true);city.event_signature="";city.update_events()
	check(hud.decision_expanded,"refreshing the same pending decision preserves reading state")
	city.state.events=original_events;city.event_signature="";city.update_events()
	check(not hud.events_box.visible or hud.decision_id!=903000,"resolved or replaced decisions clear the old disclosure")

func toasts_height(hud: Control) -> float:
	return hud.toasts.get_combined_minimum_size().y

func aegean_checks() -> void:
	var hud: Control = city.hud
	var policy = load("res://scripts/notification_policy.gd")
	var log_type = load("res://scripts/message_log.gd")
	var old_log = city.message_log
	var old_events: Array = city.state.events
	var old_commands: Array[String] = city.core.commands.duplicate()
	var old_ack: Dictionary = city.pending_info_ack.duplicate()
	city.message_log = log_type.new(); city.core.commands.clear(); city.pending_info_ack.clear()
	for child in hud.toasts.get_children(): child.free()
	hud.alert_queue.clear(); hud.set_messages_open(false)
	var routine := {"id":910000,"kind":"employees","title":"employees needed","text":"More workers are needed.","actions":[{"choice":-1,"label":"Dismiss"}]}
	city.state.events = [routine]; city.event_signature=""; city.update_events(); await frames()
	check(hud.toasts.get_child_count()==0 and city.message_log.entries.size()==1 and city.message_log.unread==1,"labour warning quietly enters the journal with an unread count")
	check(city.core.commands==["event 910000 -1"],"quiet delivery retains history before forwarding the native informational acknowledgement")
	city.event_signature=""; city.update_events()
	check(city.core.commands==["event 910000 -1"] and city.message_log.entries.size()==1,"repeated snapshots neither acknowledge nor record a quiet event twice")
	var monthly: Dictionary = routine.duplicate(true); monthly.kind="monthlySummary"; monthly.id=910001
	check(policy.delivery(monthly)=="journal","monthly reports are quiet without depending on their translated title")
	var required: Dictionary = routine.duplicate(true); required.actions=[{"choice":0,"label":"Yes"}]
	check(policy.delivery(required)=="decision","native choices override even a routine event kind")
	var unknown: Dictionary = routine.duplicate(true); unknown.erase("kind")
	check(policy.delivery(unknown)=="alert","events lacking native kind metadata retain a conservative visible fallback")
	# Backpressure must never make a retained event disappear without acknowledgement.
	city.core.commands.clear()
	for index in 16: city.core.commands.append("pause 1")
	var delayed: Dictionary = routine.duplicate(true); delayed.id=910002
	city.state.events=[delayed]; city.event_signature=""; city.update_events()
	check(city.pending_info_ack.has(910002) and city.message_log.entries.size()==2,"a full command queue retains the quiet event's pending acknowledgement")
	city.core.commands.clear(); city.update_events(); city.update_events()
	check(city.core.commands==["event 910002 -1"] and city.pending_info_ack.is_empty(),"available queue space retries the acknowledgement exactly once")
	hud.set_messages_open(true); await frames()
	check(hud.message_list.get_child_count()==1 and hud.message_list.get_child(0).title_text.contains("×2"),"identical native labour warnings group without deleting the original records")
	var row: Control = hud.message_list.get_child(0)
	row.set_expanded(true); await frames()
	var repeated: Dictionary = delayed.duplicate(true); repeated.id=910003
	city.state.events=[repeated]; city.event_signature=""; city.update_events(); await frames()
	check(hud.message_list.get_child(0)==row and row.expanded and row.body_text.count("More workers are needed.")==3,"group refresh retains the reading row and all full occurrence text")
	var different: Dictionary = routine.duplicate(true); different.id=910004; different.text="A different district needs workers."
	city.state.events=[different]; city.event_signature=""; city.update_events(); await frames()
	check(hud.message_list.get_child_count()==2 and hud.message_list.get_child(0)==row,"a different warning stays separate and incoming news does not displace active reading")
	check(hud.message_panel.size.y < city.hud.size.y*.65,"short journal hugs its contents instead of occupying the full screen height")
	var first_id: int = row.get_instance_id()
	for index in 8: hud.set_messages(city.message_log.entries)
	check(hud.message_list.get_child(0).get_instance_id()==first_id,"unchanged journal refreshes reuse the existing Controls")
	hud.set_messages_open(false)
	# Real event metadata is authored by the existing C++ event path, never inferred from the localized title.
	city.core.simulation.enable_test_commands()
	var native: Dictionary = city.core.query("test_raise employees")
	var native_event: Dictionary = native.events[-1]
	check(native_event.get("kind","")=="employees" and policy.delivery(native_event)=="journal","native employee event exposes stable metadata for quiet delivery")
	city.core.query("event %d -1" % int(native_event.id))
	# Empty margins pass through; all supported categories and the full menu remain available.
	check(hud.get_node("%StatusBar").mouse_filter==Control.MOUSE_FILTER_IGNORE and hud.get_node("%BottomBar").size.x < hud.size.x,"floating shell passes input through header gaps and bounds the dock")
	check(hud.category_buttons.values().filter(func(button):return not button.disabled).size()==hud.build_groups.size() and hud.build_groups.all(func(group):return hud.category_buttons.has(group.title) and not hud.category_buttons[group.title].disabled),"every native construction category remains accessible")
	var thumbnails: Node=hud.thumbnails
	while thumbnails.busy or not thumbnails.pending.is_empty(): await frames()
	check(thumbnails.viewport==null or thumbnails.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"thumbnail rendering remains demand-driven after catalog browsing")
	var access: Node=root.get_node("UiAccess")
	var saved_motion: bool=access.reduced_motion
	var dialog: Window=load("res://ui/interface_dialog.gd").open(hud)
	access.reduced_motion=not saved_motion
	dialog.canceled.emit();await frames()
	check(access.reduced_motion==saved_motion,"Cancel restores the original interface motion preference")
	var warehouse: Dictionary=city.state.buildings.filter(func(building):return building.asset=="warehouse")[0]
	city.inspected=Vector2i(warehouse.x,warehouse.y);city.refresh_inspection()
	var editor: VBoxContainer=city.inspector_controls
	var resource: int=editor.value.storage.resources[0].resource
	var token: int=editor.value.target_token
	var draft: int=0 if int(editor.rows[resource].limit.value)>0 else 4
	editor.rows[resource].limit.value=draft;editor.edit_storage(resource,600000)
	hud.set_messages_open(true);city.refresh_inspection();await frames()
	check(not hud.inspector.visible and editor.rows[resource].dirty,"journal hides the inspector presentation while retaining its unfinished edit")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true;root.push_input(escape,true);await frames()
	check(not hud.message_panel.visible and hud.inspector.visible and editor.rows[resource].dirty and int(editor.value.target_token)==token and int(editor.rows[resource].limit.value)==draft,"Escape closes the journal and restores the same inspector draft and target")
	city.close_inspection();city.core.commands.clear();city.pending_info_ack.clear()
	var burst: Array=[]
	for index in 8:
		var event: Dictionary=routine.duplicate(true);event.id=911000+index;burst.append(event)
	city.state.events=burst;city.event_signature="";city.update_events()
	check(city.core.commands.size()==4 and city.pending_info_ack.size()==4,"quiet news bursts leave command queue capacity for player actions")
	city.message_log=old_log;city.state.events=old_events;city.core.commands=old_commands;city.pending_info_ack=old_ack
	city.event_signature="";city.update_events()

# The new ribbon is a view of current-city native caches. It never opens a second polling path.
func nova_checks() -> void:
	var hud: Control=city.hud
	city.set_tool("select"); city.close_inspection(); hud.close_build_tray(); hud.set_messages_open(false)
	root.get_node("UiAccess").apply(100,100);DisplayServer.window_set_size(Vector2i(1440,900));await frames()
	var before: Dictionary=city.core.simulation.snapshot(true)
	var header: Dictionary=before.city_header
	var world: Dictionary=city.core.query("world")
	var mine: Dictionary=world.mine.filter(func(c):return c.current)[0]
	check(header.name==mine.name and hud.get_node("%CityName").text==mine.name,"city plaque matches the current native city, including its tooltip")
	var stock := {};var food := 0
	for entry in mine.stock:
		stock[int(entry.resource)]=int(entry.count)
		if int(entry.resource)<=128: food+=int(entry.count)
	var matched: bool=header.stock.size()==24
	for entry in header.stock:
		if int(entry.resource)==255:matched=matched and int(entry.count)==food
		elif stock.has(int(entry.resource)):matched=matched and int(entry.count)==int(stock[int(entry.resource)])
	check(matched,"giftable ribbon goods match the independent world stock query; native non-giftable types remain included")
	var jobs: Dictionary=header.employment
	check(int(jobs.employable)==int(jobs.employed)+int(jobs.unemployed) and int(jobs.vacancies)>=0 and hud.get_node("%Jobs").tooltip_text.contains(str(int(jobs.employed))),"job shortcut exposes native employment and vacancy totals")
	var overlay_before: String=city.overlay_view.mode
	for spec in [[hud.resource_buttons[255],"supplies"],[hud.resource_buttons[8192],"distribution"],[hud.welfare_buttons.water,"water"],[hud.get_node("%Jobs"),"industry"]]:
		await click(spec[0]);check(city.overlay_view.mode==spec[1] and hud.current_tool=="select","header shortcut opens native %s view without changing the tool"%spec[1])
	city.set_overlay(overlay_before)
	hud.set_minimap_open(true);await frames()
	var map: Control=hud.minimap
	var cropped:=false;var roundtrips:=true
	for cell in city.tiles:
		var point: Vector2=map.cell_to_point(Vector2(cell))
		cropped=cropped or point.distance_to(map.size*.5)>minf(map.size.x,map.size.y)*.5
		roundtrips=roundtrips and map.point_to_cell(point).distance_to(Vector2(cell))<.0001
	check(cropped and roundtrips,"chart fills and clips to the circle; all 25,992 native cells retain picking round trips within 0.0001 tile")
	check(not map._has_point(Vector2(1,1)) and map._has_point(map.size*.5) and hud.get_node("%MinimapPanel").mouse_filter==Control.MOUSE_FILTER_IGNORE,"circular map corners pass input through to the city")
	check(hud.get_node("%MinimapPanel").position.x<24 and hud.get_node("%MinimapPanel").get_global_rect().end.x<hud.get_node("%BottomBar").position.x and hud.messages_button.get_parent().name=="RailColumn","map takes the bottom-left corner beside the dock; the journal stays on the rail")
	for window_size in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(1920,1080)]:
		DisplayServer.window_set_size(window_size)
		for sizes in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(sizes.x,sizes.y);city.set_tool("road");hud.close_build_tray();await frames()
			var queued: int=city.core.commands.size()
			await click(hud.speed_buttons[1])
			check(city.core.commands.size()==queued+1 and city.core.commands[-1]=="speed 1","%s %s a speed chevron sends its native speed"%[window_size,sizes])
			city.core.commands.pop_back()
			var card: Control=hud.get_node("%ActiveToolCard")
			check(card.visible and Rect2(Vector2.ZERO,hud.size).encloses(card.get_global_rect()) and not card.get_global_rect().intersects(hud.get_node("%BottomBar").get_global_rect()) and not card.get_global_rect().intersects(hud.goals_panel.get_global_rect()),"%s %s selected road card fits above dock and native objectives"%[window_size,sizes])
			check(hud.get_node("%ActiveToolTitle").text==city.tr(hud.build_entries.road.label) and hud.get_node("%ActiveToolPrice").text.contains(hud.cost_text(hud.build_entries.road)),"selected card retains translated name and exact native catalogue cost")
	await click(hud.get_node("%ActiveToolClose"));check(hud.current_tool=="select" and not hud.get_node("%ActiveToolCard").visible,"selected card close returns to inspection through the existing tool action")
	var long_header: Dictionary=header.duplicate(true);long_header.name="A very long native city name · ".repeat(12)
	for entry in long_header.stock:entry.count=123456789
	hud.set_city_header(long_header)
	root.get_node("UiAccess").apply(125,130);DisplayServer.window_set_size(Vector2i(1280,720));await frames()
	var ribbon: Rect2=hud.get_node("%ResourceRibbon").get_global_rect()
	check(Rect2(Vector2.ZERO,hud.size).encloses(ribbon) and hud.get_node("%CityName").tooltip_text==long_header.name and hud.resource_buttons.size()==24,"long city names and large stocks stay bounded while retaining full tooltips and every good")
	hud.set_city_header(header);root.get_node("UiAccess").apply(100,100);await frames()
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(before.time==after.time and before.money==after.money and before.city_header==after.city_header and before.buildings==after.buildings,"header navigation, resizing and chart picking leave native city state unchanged")
