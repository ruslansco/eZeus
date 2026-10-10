extends SceneTree
# Owned native-city review: real input, exact clocks and bounded EN/RU layouts.
var city: Node
var okay := true
var checks := 0
var language := "en"

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):language=arg.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	run.call_deferred()

func check(value: bool, description: String) -> void:
	checks+=1;okay=okay and value
	print("TIME_CHECK ","PASS " if value else "FAIL ",description)

func frames(count:=8) -> void:
	for i in count:await process_frame

func click(button: Control) -> void:
	DisplayServer.window_move_to_foreground()
	var point:=button.get_global_rect().get_center()
	root.warp_mouse(point)
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.set_meta("review_input",true)
	root.push_input(motion,true);await frames(3)
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.set_meta("review_input",true);root.push_input(event,true);await frames(3)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed
		event.set_meta("review_input",true);root.push_input(event,true);await frames(2)

func publish() -> Dictionary:
	var state: Dictionary=city.core.simulation.snapshot(false)
	city.core.snapshot_received.emit(state)
	city.static_batches.activity.advance(.1)
	city.water_life.advance(.1);city.monster_effects.advance(.1);city.thrown_shots.advance(.1)
	return state

func flush() -> Dictionary:
	while not city.core.commands.is_empty():city.core.query(city.core.commands.pop_front())
	return publish()

func capture(label: String) -> void:
	await frames(10)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/time-"+language+"-"+label+".png")

func run() -> void:
	var leaders=preload("res://scripts/leaders.gd")
	leaders.create("Time Controls Review");leaders.set_current("Time Controls Review")
	var source:=ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var copy: String=preload("res://scripts/save_files.gd").directory().path_join("time-review.ez")
	check(DirAccess.copy_absolute(source,copy)==OK,"only a disposable designated-city copy is opened")
	Engine.set_meta("ezeus_load",copy);Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city=load("res://main.tscn").instantiate();root.add_child(city);current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty():await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.set_process(false)
	city.core.commands.clear();await frames(16)
	var hud: Control=city.hud
	check(hud.speed_buttons.size()==3,"exactly three speed controls replace the old four")
	check(int(city.state.speed)==1,"the protected older city opens at the faster Normal default")
	check(hud.speed_buttons[0].button_pressed,"Normal is selected initially")
	city.core.simulation.enable_test_commands()
	var house: Dictionary=city.state.buildings.filter(func(b):return str(b.asset).begins_with("common_house"))[-1]
	check(not city.core.query("test_fire %d %d"%[house.x,house.y]).has("error"),"a native test fire is created only in the disposable city's memory")
	publish();await frames(4)
	check(city.building_fires.count()>0 and not city.building_fires.lights.is_empty(),"actual flame, smoke and light materials are rendered")
	var translations: Dictionary={}
	var csv:=FileAccess.open("res://data/ui_strings.csv",FileAccess.READ)
	while not csv.eof_reached():
		var row:=csv.get_csv_line()
		if row.size()==2:translations[row[0]]=row[1]
	for i in 3:
		var name: String=hud.SPEEDS[i]
		check(hud.speed_buttons[i].tooltip_text.contains(translations.get(name,name) if language=="ru" else name) and hud.speed_buttons[i].help_detail.contains(city.KeyBindings.label("speed_up")),"pace %d has translated hover help and actual speed shortcuts"%(i+1))
		var clock: int=city.state.time
		await click(hud.speed_buttons[i])
		check(city.core.commands.size()==1 and city.core.commands[0]=="speed %d"%(i+1),"pace %d sends exactly one native command on mouse-up"%(i+1))
		var state:=flush()
		check(state.paused and not state.running and int(state.time)==clock,"choosing pace %d preserves pause and game time"%(i+1))
		check(hud.speed_buttons.filter(func(b):return b.button_pressed).size()==1 and hud.speed_buttons[i].button_pressed,"pace %d has one unambiguous selected state"%(i+1))
		city.core.query("pause 0")
		var fire_time: float=city.building_fires.clock
		for step in 4:city.core.simulation.advance(.05)
		state=publish()
		await frames(3)
		check(int(state.time)-clock==[60,120,240][i],"pace %d advances exact 1x / 2x / 4x native time"%(i+1))
		check(is_equal_approx(city.static_batches.activity.phase,float(state.time)/30.0),"pace %d drives authored building animation from native time"%(i+1))
		check(is_equal_approx(city.building_fires.clock-fire_time,float([60,120,240][i])/300.0),"pace %d scales actual fire lights and soot with native time"%(i+1))
		check(is_equal_approx(city.water_life.clock,float(state.time)/30.0) and is_equal_approx(city.monster_effects.clock,float(state.time)) and is_equal_approx(city.thrown_shots.clock,float(state.time)),"pace %d keeps water workers and projectile/effect clocks synchronized"%(i+1))
		city.core.query("pause 1");publish()
		var phase: float=city.static_batches.activity.phase
		var effects: float=city.static_batches.activity.effect_seconds()
		var fire_clock: float=city.building_fires.clock
		var light_energy: float=city.building_fires.lights[0][0].light_energy
		city.core.simulation.advance(.25);publish();await frames(5)
		check(city.static_batches.activity.phase==phase and city.static_batches.activity.effect_seconds()==effects,"pause freezes building motion and fire/smoke time at pace %d"%(i+1))
		check(city.building_fires.clock==fire_clock and city.building_fires.lights[0][0].light_energy==light_energy,"pause freezes actual fire lights and soot at pace %d"%(i+1))
	city.core.query("speed 0")
	check(int(publish().speed)==1,"retired slow speed zero safely aliases Normal for older clients")
	await key(KEY_BRACKETLEFT);flush()
	check(int(city.state.speed)==1,"slower shortcut stops at Normal")
	await key(KEY_BRACKETRIGHT);flush()
	check(int(city.state.speed)==2 and hud.speed_buttons[1].button_pressed,"faster shortcut selects Fast")
	await key(KEY_BRACKETRIGHT);flush();await key(KEY_BRACKETRIGHT);flush()
	check(int(city.state.speed)==3 and hud.speed_buttons[2].button_pressed,"faster shortcut stops at Very fast")
	await key(KEY_BRACKETLEFT);flush()
	check(int(city.state.speed)==2,"slower shortcut returns to Fast")
	await click(hud.pause_button)
	check(city.core.commands.size()==1,"pause uses one original callback")
	check(flush().running,"Play resumes at the selected pace")
	await click(hud.pause_button)
	check(flush().paused,"Pause restores the stopped state")
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions)
		for scaling in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scaling.x,scaling.y)
			for visible_map in [false,true]:
				hud.set_minimap_open(visible_map,false);await frames(20)
				var panel: Control=hud.get_node("%TimeBar")
				var rect:=panel.get_global_rect()
				check(Rect2(Vector2.ZERO,hud.size).encloses(rect) and not rect.intersects(hud.get_node("%BottomBar").get_global_rect()),"%s %s map=%s: time controls fit clear of the construction dock"%[dimensions,scaling,visible_map])
				check(hud.speed_buttons.all(func(button):return rect.encloses(button.get_global_rect())) and rect.encloses(hud.get_node("%Date").get_global_rect()),"%s %s: every speed and full date remain visible"%[dimensions,scaling])
				check(hud.get_node("%Date").get_global_rect().end.y < hud.pause_button.get_global_rect().position.y,"the date sits above the transport controls")
				if visible_map:check(hud.get_node("%MinimapPanel").get_global_rect().end.y+4<=rect.position.y,"the open map stays above the time panel")
			await capture("%d-%d"%[dimensions.x,scaling.x])
	root.get_node("UiAccess").apply(100,100)
	# Let the native designated city's scheduled request arrive; never answer it.
	city.core.query("speed 3");city.core.query("pause 0")
	for step in 200:city.core.simulation.advance(.05)
	var blocked:=publish()
	check(blocked.blocked and not blocked.running,"a native required decision still stops time")
	var held: int=blocked.time
	await click(hud.speed_buttons[0]);flush()
	city.core.simulation.advance(.25)
	check(int(publish().time)==held and city.state.blocked,"speed selection never bypasses a native decision")
	check(FileAccess.get_sha256(copy)==FileAccess.get_sha256(source),"the copied city remains byte-identical to its protected source")
	while hud.thumbnails.busy or not hud.thumbnails.pending.is_empty():await frames(2)
	city.core.simulation.close_city()
	# Native presentation metadata still remembers each selected pace after reload.
	var saved_core: RefCounted=ClassDB.instantiate("EZeusSimulation")
	var engine:=ProjectSettings.globalize_path("res://..").simplify_path()
	var directory: String=preload("res://scripts/save_files.gd").directory()
	saved_core.set_save_directory(directory)
	for pace in [1,2,3]:
		saved_core.open_city(engine,copy,language)
		saved_core.command("speed %d"%pace)
		var saved: Dictionary=saved_core.save_city("pace-%d"%pace)
		check(not saved.has("error"),"pace %d saves only into the owned scratch directory"%pace)
		saved_core.close_city()
		var restored: Dictionary=saved_core.open_city(engine,directory.path_join("pace-%d.ez"%pace),language)
		check(int(restored.get("speed",-1))==pace and restored.paused,"pace %d reloads with its selected speed and normal paused entry"%pace)
		saved_core.close_city()
	check(FileAccess.get_sha256(copy)==FileAccess.get_sha256(source),"pace round trips preserve the protected source and designated copy")
	city.queue_free();await frames(4)
	print("TIME_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
