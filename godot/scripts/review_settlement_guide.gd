extends SceneTree
var city: Node
var okay := true
var checks := 0
var language := "en"

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language=arg.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	run.call_deferred()

func check(value: bool, description: String) -> void:
	checks+=1; okay=okay and value
	print("SETTLEMENT_CHECK ","PASS " if value else "FAIL ",description)

func frames(count:=8) -> void:
	for i in count: await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await frames(8)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/settlement-"+language+"-"+label+".png")

func run() -> void:
	var leaders=preload("res://scripts/leaders.gd")
	leaders.create("Settlement Guide Review");leaders.set_current("Settlement Guide Review")
	var source:=ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var copy: String=preload("res://scripts/save_files.gd").directory().path_join("settlement-review.ez")
	check(DirAccess.copy_absolute(source,copy)==OK,"review opens only a disposable copy of the designated city")
	Engine.set_meta("ezeus_load",copy);Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city=load("res://main.tscn").instantiate();root.add_child(city);current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty():await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.set_process(false)
	city.core.commands.clear();city.hud.set_decision({},0)
	await create_timer(1.6).timeout
	city.open_city_help("guide")
	var keys := ["Start guided setup","Explore on my own","Skip this step","Select %s","Plan your next steps","Reply to the pending decision before city time can resume.","Inspect food trade"]
	var translations := {}
	var csv := FileAccess.open("res://data/ui_strings.csv",FileAccess.READ)
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size()==2 and row[0] in keys: translations[row[0]]=row[1]
	check(keys.all(func(key):return translations.has(key) and city.tr(key)==(translations[key] if language=="ru" else key)),"guide controls and pending-decision help retain the complete imported EN/RU wording")
	var before: Dictionary=city.core.simulation.snapshot(true)
	await preload("res://scripts/settlement_guide_checks.gd").new().run(city,check,capture)
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions)
		for scaling in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(scaling.x,scaling.y)
			city.city_help.offer();city.city_help.age=-1000
			await frames(24)
			var help: Control=city.city_help
			check(Rect2(Vector2.ZERO,city.hud.size).encloses(help.card.get_global_rect()),str(dimensions)+" "+str(scaling)+": optional introduction stays within the viewport")
			await capture("welcome-%d-%d"%[dimensions.x,scaling.x])
			help.begin_guide();await frames(16)
			check(Rect2(Vector2.ZERO,city.hud.size).encloses(help.card.get_global_rect()) and help.body.find_child("GuideBuild",true,false)!=null,str(dimensions)+" "+str(scaling)+": current task and build action remain reachable")
			var button: Button=help.body.find_child("GuideBuild",true,false)
			check(help.scroll.get_global_rect().encloses(button.get_global_rect()),str(dimensions)+" "+str(scaling)+": primary action fits without scrolling")
			await capture("task-%d-%d"%[dimensions.x,scaling.x])
	root.get_node("UiAccess").apply(100,100)
	var after: Dictionary=city.core.simulation.snapshot(true)
	before.erase("sequence");after.erase("sequence")
	check(before==after and city.core.commands.is_empty(),"guide learning, tool selection, offers, and scaling preserve every native game-state field")
	check(FileAccess.get_sha256(copy)==FileAccess.get_sha256(source),"the copied city remains byte-identical to its protected source")
	while city.hud.thumbnails.busy or not city.hud.thumbnails.pending.is_empty():await frames(2)
	city.core.simulation.close_city();city.queue_free();await frames(4)
	print("SETTLEMENT_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
