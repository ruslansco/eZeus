extends SceneTree
# Native request callbacks over the full city, using a disposable leader/save copy. Synthetic wording only stresses layout.
const Log = preload("res://scripts/message_log.gd")
const Saves = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
var city: Node
var language := "en"
var checks := 0
var okay := true
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1; okay = okay and value
	print("DECISION_PANEL_CHECK ", "PASS " if value else "FAIL ", description)
func frames(n := 8) -> void:
	for i in n: await process_frame
func click(control: Control, button_index := MOUSE_BUTTON_LEFT) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(3)
	root.warp_mouse(control.get_global_rect().get_center())
	var motion := InputEventMouseMotion.new()
	motion.position=control.get_global_rect().get_center(); motion.set_meta("review_input",true)
	root.push_input(motion,true); await frames(3)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button_index; event.position = control.get_global_rect().get_center(); event.pressed = pressed
		event.set_meta("review_input",true); root.push_input(event,true)
		if pressed: await frames(2)
	await frames()
func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed
		event.set_meta("review_input",true); root.push_input(event,true)
	await frames()
func capture(label: String) -> void:
	DisplayServer.window_move_to_foreground(); await frames(12); RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/decision-panel-%s-%s.png" % [language,label])
func refresh() -> void:
	city.state = city.core.simulation.snapshot(false)
	city.event_signature = ""; city.update_events()
func decision() -> Dictionary:
	for event in city.state.events:
		if not Log.is_informational(event): return event
	return {}
func actions() -> Array:
	return city.hud.get_node("%EventActions").get_children()
func fresh_request() -> Dictionary:
	# Schedule an actual native troop request in the same disposable city session.
	# Reopening threaded native boards repeatedly is unnecessary for this UI test.
	var core = city.core.simulation
	city.core.commands.clear()
	city.decision_reply_pending = -1
	for entry in core.snapshot(false).events:
		core.command("event %d %d" % [entry.id, 2 if entry.actions.any(func(a): return int(a.choice) == 2) else entry.actions[0].choice])
	core.enable_test_commands(); core.command("speed 3"); core.command("pause 0")
	core.command("test_relationship 3 rival"); core.command("test_attitude 4 90")
	core.command("test_troops_request 4 3")
	for i in 300:
		core.advance(.25)
		var snapshot: Dictionary = core.snapshot(false)
		var found := false
		for entry in snapshot.events:
			if entry.actions.any(func(a): return int(a.choice) == -2): found = true
			else: core.command("event %d %d" % [entry.id,entry.actions[0].choice])
		if found: break
	refresh(); await frames()
	for command in city.core.commands: core.command(command)
	city.core.commands.clear()
	return decision()
func apply_reply() -> Dictionary:
	var command: String = city.core.commands.pop_front()
	var result: Dictionary = city.core.simulation.command(command)
	# Same snapshot-before-completion order as the embedded CoreLink.
	refresh(); city.command_finished(command, result); await frames()
	return result
func bounds(label: String) -> void:
	var card: Rect2 = city.hud.events_box.get_global_rect()
	var view: Rect2 = city.hud.get_global_rect()
	check(view.encloses(card) and card.get_center().distance_to(view.get_center()) < 2, label+": card is centered inside viewport")
	check(actions().all(func(button): return card.encloses(button.get_global_rect()) and button.size.y>=46), label+": every choice stays visible below the letter")
	check(city.hud.get_node("%EventScroll").size.y>=80 and city.hud.get_node("%DecisionFooter").get_global_rect().position.y >= city.hud.get_node("%EnvoyContent").get_global_rect().end.y, label+": reading area clears the fixed choice footer")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language=arg.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	Leaders.create("Decision Review"); Leaders.set_current("Decision Review")
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	var fixture := Saves.directory().path_join("decision review.ez")
	check(DirAccess.copy_absolute(source,fixture)==OK,"city copied only to disposable profile")
	Engine.set_meta("ezeus_load",fixture); Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1600,1000))
	city=load("res://main.tscn").instantiate(); root.add_child(city); current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty(): await process_frame
	city.core.set_process(false); city.set_process(false)
	var core=city.core.simulation
	core.enable_test_commands(); core.command("speed 3"); core.command("pause 0")
	for i in 200:
		core.advance(.05)
		if core.snapshot(false).blocked: break
	refresh(); await frames(20)
	# The owned frozen core does not drain presentation acknowledgements. Drain those before testing reply queues.
	for command in city.core.commands: core.command(command)
	city.core.commands.clear()
	var event := decision()
	check(not event.is_empty() and city.tiles.size()==25992,"real full city receives a native required decision")
	if event.is_empty(): quit(1); return
	var original := event.duplicate(true)
	var world: Dictionary=core.command("world")
	var sender: Array=world.cities.filter(func(c): return int(c.index)==int(event.sender_index))
	check(sender.size()==1 and sender[0].name==event.sender_name and sender[0].leader==event.sender_leader,"identity and portrait follow the exact native sender")
	check(city.hud.decision_expanded and city.hud.get_node("%DecisionShade").visible and city.orbit.modal_input_blocked,"new request automatically opens its modal and blocks camera input")
	check(actions().map(func(b): return int(b.get_meta("choice")))==city.hud.decision_actions(event).map(func(a): return int(a.choice)),"native choices are retained and laid out in semantic order")
	check(actions().all(func(b): return event.actions.any(func(a): return a.choice==b.get_meta("choice") and a.label==b.text)),"only currently available native actions appear with their exact labels")
	check(root.gui_get_focus_owner()==city.hud.get_node("%EventScroll"),"opening focuses the letter rather than selecting an answer")
	check(language!="ru" or city.hud.get_node("%EnvoyPause").text != "Paused · Awaiting your reply","pause hint is translated in Russian")
	var paper: StyleBoxFlat = city.hud.get_node("%EnvoyLetter").get_theme_stylebox("panel")
	var ink: Color = city.events_panel.get_child(0).get_theme_color("font_color")
	var contrast := (ink.srgb_to_linear().get_luminance()+.05)/(paper.bg_color.srgb_to_linear().get_luminance()+.05)
	check(paper.bg_color.get_luminance()<.2 and contrast>=7,"decision letter uses the shared dark panel and ivory text with at least 7:1 contrast")
	check(city.hud.decision_postponable and city.hud.get_node("%EnvoyPause").text.ends_with(city.tr("Right-click to postpone")),"Postpone shortcut is shown only for an offered native action and translated")
	bounds("default"); await capture("request")
	var before: int=core.snapshot(false).time
	await key(KEY_ENTER)
	check(city.core.commands.is_empty() and core.snapshot(false).blocked,"Enter while reading never answers a new request")
	var tab_stays_inside := true
	for i in 3+actions().size():
		await key(KEY_TAB)
		tab_stays_inside = tab_stays_inside and city.hud.events_box.is_ancestor_of(root.gui_get_focus_owner())
	check(tab_stays_inside and root.gui_get_focus_owner()==city.hud.get_node("%EventScroll"),"Tab cycles through the modal without reaching underlying city controls")
	var old_target: Vector3=city.orbit.target; var old_yaw: float=city.orbit.yaw
	var camera_key := InputEventKey.new(); camera_key.physical_keycode=KEY_Q; camera_key.pressed=true
	city.orbit._unhandled_input(camera_key); city.orbit._process(.1)
	check(city.orbit.target==old_target and city.orbit.yaw==old_yaw,"camera stays still while the correspondence modal is open")
	check(city.ui_at(city.hud,Vector2(24,300)),"dimmed backdrop blocks picking and city clicks")
	city.hud.set_messages_open(true); await frames()
	await key(KEY_ESCAPE)
	check(not city.hud.decision_expanded and not city.hud.get_node("%DecisionShade").visible and not city.hud.events_box.visible and city.hud.get_node("%DecisionReview").visible,"Escape folds into a persistent amber decision icon")
	check(city.hud.message_panel.visible,"Escape folds the foreground decision before a journal open behind it")
	city.hud.set_messages_open(false)
	core.command("pause 0")
	for i in 20: core.advance(.05)
	check(core.snapshot(false).time==before and core.snapshot(false).blocked and city.core.commands.is_empty(),"folding or requesting resume cannot bypass the native pause")
	await capture("folded")
	city.open_escape_menu(); await frames(); city.close_escape_menu(); await frames()
	for i in 10: core.advance(.05)
	check(core.snapshot(false).time==before and core.snapshot(false).blocked,"opening and closing game settings preserves the request block")
	await click(city.hud.get_node("%DecisionReview"))
	check(city.hud.decision_expanded and city.hud.decision_id==int(event.id),"review reminder reopens the same unanswered request")
	for dimensions in [Vector2i(1600,1000),Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions)
		for scale in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scale.x,scale.y); await frames(24)
			bounds(str(dimensions)+" "+str(scale))
			await capture("%d-%d" % [dimensions.x,scale.x])
	root.get_node("UiAccess").apply(100,100); DisplayServer.window_set_size(Vector2i(1600,1000)); await frames(20)
	# Long wording is a presentation fixture; the core still holds its untouched original request and callbacks.
	event=original.duplicate(true); event.text=original.text.repeat(10)
	city.state.events=[event]; city.event_signature=""; city.update_events(); await frames(20)
	var scroll: ScrollContainer=city.hud.get_node("%EventScroll"); scroll.scroll_vertical=100000; await frames()
	check(scroll.scroll_vertical>0 and scroll.get_v_scroll_bar().value+scroll.get_v_scroll_bar().page>=scroll.get_v_scroll_bar().max_value-1,"full long correspondence can be read to its last line")
	bounds("long letter"); await capture("long-letter")
	check(core.snapshot(false).events.any(func(e): return int(e.id)==int(original.id) and e.text==original.text),"scroll fixture leaves the native message untouched")
	var unavailable: Array = original.actions.map(func(a): return a.choice)
	if not unavailable.has(0): check(not actions().any(func(b): return int(b.get_meta("choice"))==0),"unavailable Dispatch is omitted rather than invented")
	refresh(); await frames()
	for command in city.core.commands: core.command(command)
	city.core.commands.clear()
	var button: Button=actions()[0]; var choice: int=button.get_meta("choice")
	button.grab_focus(); await key(KEY_ENTER)
	check(city.core.commands.size()==1 and city.core.commands[0]=="event %d %d" % [original.id,choice],"explicit keyboard answer queues exactly its original native callback")
	var result: Dictionary=core.command(city.core.commands.pop_front())
	refresh(); await frames()
	check(not result.has("error") and not core.snapshot(false).events.any(func(e): return int(e.id)==int(original.id)),"native answer consumes only the selected request")
	check(not city.hud.decision_expanded and not city.hud.get_node("%DecisionShade").visible and not city.orbit.modal_input_blocked,"answer removes modal and restores city camera input")
	# Troop requests use the actual native event and enlisting session, including cancellation.
	core.command("test_relationship 3 rival"); core.command("test_attitude 4 90")
	core.command("test_troops_request 4 3"); core.command("pause 0")
	var troop: Dictionary={}
	for i in 300:
		core.advance(.25)
		var snapshot: Dictionary=core.snapshot(false)
		for entry in snapshot.events:
			if entry.actions.any(func(a): return int(a.choice)==-2): troop=entry
			else: core.command("event %d %d" % [entry.id,entry.actions[0].choice])
		if not troop.is_empty(): break
	refresh(); await frames(20)
	check(not troop.is_empty() and core.snapshot(false).blocked,"native troop request also holds the clock")
	if not troop.is_empty():
		var dispatch: Button=actions().filter(func(b): return int(b.get_meta("choice"))==-2)[0]
		check(dispatch==actions()[-1] and dispatch.theme_type_variation=="EnvoyPrimary","Send troops is emphasized on the right after Refuse and Postpone")
		await click(dispatch)
		check(city.enlist_dialog!=null and core.snapshot(false).blocked,"Send troops opens existing enlistment without prematurely answering")
		if city.enlist_dialog!=null: city.enlist_dialog.cancel(); await frames()
		check(city.enlist_dialog==null and core.snapshot(false).blocked and core.snapshot(false).events.any(func(e): return int(e.id)==int(troop.id)),"canceling enlistment leaves the exact request waiting and paused")
		await capture("troops")
		DisplayServer.window_set_size(Vector2i(1280,720)); root.get_node("UiAccess").apply(125,130); await frames(24)
		bounds("three-choice troop request at 125% interface / 130% text")
		await capture("troops-large")
	# Explicit presentation fixtures exercise other native choice meanings without calling their callbacks.
	var invasion := {"kind":"invasion","actions":[{"choice":0,"label":"Surrender"},{"choice":1,"label":"Bribe"},{"choice":2,"label":"Defend"}]}
	check(not city.hud.decision_can_postpone(invasion),"invasion choice 1 is Bribe and cannot be treated as Postpone")
	check(city.hud.decision_actions(invasion).map(func(a): return a.choice)==[0,1,2] and city.hud.decision_action_style(invasion,2)=="EnvoyPrimary" and city.hud.decision_action_style(invasion,0)=="EnvoyAction","invasion ordering never mistakes Surrender for the positive action")
	var destinations := {"actions":[{"choice":1001,"label":"Receive — A"},{"choice":1002,"label":"Receive — B"}]}
	check(not city.hud.decision_can_postpone(destinations),"receiving-city decisions without Postpone never gain an invented dismissal action")
	check(city.hud.decision_actions(destinations).size()==2 and destinations.actions.all(func(a): return city.hud.decision_action_style(destinations,a.choice)=="EnvoyAction"),"multiple receiving cities remain equal destination choices")
	check(city.hud.decision_action_style({"actions":[{"choice":1001}]},1001)=="EnvoyPrimary","a single eligible receiving city gets the primary action emphasis")
	for fixture_event in [invasion, destinations]:
		fixture_event.id = 900100 + int(fixture_event == destinations)
		fixture_event.title = "Review fixture"; fixture_event.text = "Review fixture"
		city.state.events = [fixture_event]; city.event_signature = ""; city.update_events(); await frames()
		city.core.commands.clear()
		await click(city.hud.get_node("%EventScroll"), MOUSE_BUTTON_RIGHT)
		check(not city.hud.decision_expanded and city.core.commands.is_empty() and core.snapshot(false).blocked,"right-click folds a non-postponable decision without invoking another native choice")
	refresh(); await frames()
	# The full-city captures are finished. Exercise repeated native replies with
	# 2D Controls only, avoiding the local Metal full-city frame-fence stall.
	root.disable_3d = true
	await frames()
	# Both dismissal routes must use the native Postpone callback, exactly like the button.
	for route in ["expanded right-click", "folded icon right-click", "Postpone button", "manually paused right-click"]:
		event = await fresh_request()
		check(not event.is_empty() and city.hud.decision_postponable, route+": actual native request offers Postpone")
		if event.is_empty(): continue
		var manually_paused: bool = route == "manually paused right-click"
		var requests_before: int = core.command("world").requests.size()
		var treasury_before: int = core.snapshot(false).money
		if manually_paused: core.command("pause 1"); refresh(); await frames()
		if route == "folded icon right-click": await key(KEY_ESCAPE)
		var target: Control = city.hud.get_node("%DecisionReview") if route == "folded icon right-click" else city.hud.get_node("%EventScroll")
		if route == "Postpone button":
			await click(actions().filter(func(b): return int(b.get_meta("choice")) == 1)[0])
		else:
			await click(target, MOUSE_BUTTON_RIGHT)
			await click(target, MOUSE_BUTTON_RIGHT)
		check(city.core.commands == ["event %d 1" % event.id] and actions().all(func(b): return b.disabled), route+": queues one exact Postpone reply without extra pause/resume commands")
		if city.core.commands.is_empty(): continue
		result = await apply_reply()
		check(not result.has("error") and not core.snapshot(false).blocked and not city.hud.decision_expanded and not city.hud.get_node("%DecisionReview").visible and not city.orbit.modal_input_blocked, route+": native reply releases its block and removes the notification")
		check(core.command("world").requests.size() == requests_before and core.snapshot(false).money == treasury_before, route+": postpones the outstanding request without refusing or paying it")
		before = core.snapshot(false).time
		core.advance(.05)
		check(core.snapshot(false).paused == manually_paused and (core.snapshot(false).time == before if manually_paused else core.snapshot(false).time > before), route+": preserves the user's pause state and running clock")
	# Retry safety: a full queue or rejected callback must not hide an unanswered request.
	event = await fresh_request()
	for i in 16: city.core.commands.append("snapshot")
	await click(city.hud.get_node("%EventScroll"), MOUSE_BUTTON_RIGHT)
	check(city.hud.decision_expanded and core.snapshot(false).blocked and city.decision_reply_pending == -1 and city.core.commands.size() == 16,"full queue keeps the pending request visible and retryable")
	city.core.commands.clear()
	await click(city.hud.get_node("%EventScroll"), MOUSE_BUTTON_RIGHT)
	var failed_command: String = city.core.commands.pop_front()
	city.command_finished(failed_command, {"error":"decision_interface_required"}); await frames()
	check(city.hud.decision_expanded and actions().all(func(b): return not b.disabled) and city.decision_reply_pending == -1 and core.snapshot(false).blocked,"a rejected reply restores active choices and preserves the original native block")
	await click(city.hud.get_node("%EventScroll"), MOUSE_BUTTON_RIGHT)
	await apply_reply()
	check(FileAccess.get_sha256(fixture)==FileAccess.get_sha256(source),"copied saved city is never written during the review")
	print("DECISION_PANEL_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
