extends SceneTree
var city: Node3D
var checks := 0
var okay := true
func _initialize() -> void:
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"): Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	create_timer(80).timeout.connect(func(): quit(2))
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1; okay = okay and value
	print("ENVOY_CHECK ", "PASS " if value else "FAIL ", description)
func frames(n := 8) -> void:
	for i in n: await process_frame
func capture(label: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/envoy-"+label+"-"+city.language+".png")
func run() -> void:
	city=load("res://main.tscn").instantiate();root.add_child(city)
	while city.state.is_empty() or city.frame_count < 60: await process_frame
	city.core.set_process(false);city.set_process(false);city.orbit.enabled=false
	var core=city.core.simulation
	core.command("speed 3");core.command("pause 0")
	for i in 200:
		core.advance(.05)
		if core.snapshot(false).blocked:break
	city.state=core.snapshot(false);city.event_signature="";city.update_events()
	var decisions: Array=city.state.events.filter(func(e):return not load("res://scripts/message_log.gd").is_informational(e))
	check(not decisions.is_empty(),"native city request arrives")
	if decisions.is_empty():quit(1);return
	var event: Dictionary=decisions[0]
	var world: Dictionary=core.command("world")
	var sender: Array=world.cities.filter(func(c):return int(c.index)==int(event.sender_index))
	check(sender.size()==1 and sender[0].name==event.sender_name and sender[0].leader==event.sender_leader,"native sender matches the world city and leader")
	check(city.hud.decision_expanded,"new decision opens automatically")
	var before: int=core.snapshot(false).time
	city.hud.set_decision_expanded(false)
	core.command("pause 0")
	for i in 20:core.advance(.05)
	check(core.snapshot(false).time==before and core.snapshot(false).blocked,"folding and resume cannot bypass a required decision")
	city.hud.set_decision_expanded(true)
	check(city.hud.get_node("%EventActions").get_child_count()==event.actions.size(),"all exact native actions appear below the message")
	check(city.hud.envoy_portrait.sender_index==int(event.sender_index),"portrait uses native world index")
	for window_size in [Vector2i(1600,1000),Vector2i(1280,720)]:
		DisplayServer.window_set_size(window_size)
		for scale in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scale.x,scale.y);await frames(18)
			var rect: Rect2=city.hud.events_box.get_global_rect()
			check(rect.position.x < city.hud.size.x*.35,"card is left aligned "+str(window_size)+str(scale))
			check(rect.position.y>=0 and rect.end.y<=city.hud.get_node("%TimeGroup").position.y,"card stays above time controls "+str(window_size)+str(scale))
			var actions: Rect2=city.hud.get_node("%EventActionScroll").get_global_rect()
			check(rect.encloses(actions) and actions.size.y>0,"actions remain in bounded card "+str(window_size)+str(scale))
			await capture(str(window_size.x)+"-"+str(scale.x))
	root.get_node("UiAccess").apply(100,100)
	var original_text: String=event.text
	event.text=original_text.repeat(8);city.state.events=[event];city.event_signature="";city.update_events();await frames()
	check(city.hud.get_node("%EventScroll").get_v_scroll_bar().max_value>city.hud.get_node("%EventScroll").size.y,"long correspondence scrolls separately from actions")
	var choices: Array=city.hud.get_node("%EventActions").get_children()
	city.core.commands.clear();choices[0].pressed.emit()
	check(city.core.commands.size()==1 and city.core.commands[0]=="event %d %d" % [event.id,event.actions[0].choice],"button queues the exact native callback")
	city.core.commands.clear()
	var answer: Dictionary=core.command("event %d %d" % [event.id,event.actions[0].choice])
	check(not answer.has("error") and not answer.blocked,"explicit native action releases the request block")
	print("ENVOY_REVIEW ","PASS" if okay else "FAIL"," checks=",checks," world_cities=",world.cities.size())
	quit(0 if okay else 1)
