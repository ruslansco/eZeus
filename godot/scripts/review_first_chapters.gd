extends SceneTree
const Catalog = preload("res://scripts/build_catalog.gd")
var core: RefCounted
var checks := 0
var okay := true
var language := "en"
var report := ""

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_engine_directory",OS.get_environment("EZEUS_SCENARIO_ENGINE"))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):language=a.trim_prefix("--lang=")
	Engine.set_meta("ezeus_language",language)
	call_deferred("run")

func check(value: bool,label: String) -> void:
	checks+=1;okay=okay and value
	print("CHAPTER_CHECK ","PASS " if value else "FAIL ",label)

func permissions() -> Dictionary:
	var values: Dictionary={}
	for b in core.command("buildable").buildings:values[b.name]=b.available
	return values

func footprints(rows: Array) -> Array:
	var values:=[]
	for b in rows:values.append([b.asset,int(b.x),int(b.y),int(b.w),int(b.h)])
	values.sort_custom(func(a,b):return JSON.stringify(a)<JSON.stringify(b))
	return values

func run() -> void:
	var engine:=OS.get_environment("EZEUS_SCENARIO_ENGINE")
	report=OS.get_environment("EZEUS_SCENARIO_REPORT")
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../content/scenarios/first_light_harbor_chapters.json"))
	core=ClassDB.instantiate("EZeusSimulation");core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"));core.set_adventures_directory(engine.path_join("Adventures"))
	var list: Array=core.adventures(engine,language).adventures
	check(list.size()==1 and list[0].ref==plan.development_name,"new catalog has the three-chapter identity")
	var preview: Dictionary=core.adventure_preview(engine,"folder",plan.development_name,language)
	check(int(preview.get("episode_total",0))==3,"adventure preview reports three chapters")
	var state: Dictionary=core.open_adventure(engine,"folder",plan.development_name,language)
	check(not state.has("error") and state.tiles.size()==25992 and int(state.money)==18000,"native terrain and opening budget load")
	var before_buildings: Array=[]
	var chapter_results:=[]
	for number in 3:
		var episode: Dictionary=core.command("episode")
		check(int(episode.episode_number)==number+1 and int(episode.episode_count)==3 and episode.episode_title==plan.text[language]["Parent_Episode_%d_Title"%(number+1)],"chapter %d localized title and index"%(number+1))
		check(episode.goals.size()==plan.chapters[number].goals.size(),"chapter %d has only its own objectives"%(number+1))
		var available:=permissions()
		check(available.house and available.wheat_farm and available.fountain,"foundation buildings persist")
		check(bool(available.bibliotheke)==(number>=1) and bool(available.carding_shed)==(number>=1) and bool(available.warehouse)==(number>=1),"clothing/science/storage unlock at chapter two")
		check(bool(available.trade_post)==(number==2) and bool(available.timber_mill)==(number==2) and bool(available.tax_office)==(number==2),"trade/industry/taxes unlock at chapter three")
		if number==0:
			check(core.command("test_win").has("error"),"ordinary play cannot force victory")
			for tile in state.tiles:
				if bool(tile[5]) and core.command("preview house %d %d 0"%[int(tile[0]),int(tile[1])]).get("valid",false):
					var built: Dictionary=core.command("build house %d %d 0"%[int(tile[0]),int(tile[1])])
					check(not built.has("error"),"ordinary house is built before progression")
					break
		else:
			if footprints(core.snapshot(true).buildings)!=before_buildings:
				print("CHAPTER_CARRY_EXPECTED ",JSON.stringify(before_buildings))
				print("CHAPTER_CARRY_ACTUAL ",JSON.stringify(footprints(core.snapshot(true).buildings)))
			check(footprints(core.snapshot(true).buildings)==before_buildings,"existing city buildings carry into the next chapter")
		if number==2:
			check(not bool(episode.goals[-1].met),"BC date objective is initially unmet")
			var saw_closed:=false;var saw_open:=false
			core.command("speed 3");core.command("pause 0")
			for batch in 180:
				for i in 10:core.advance(.05)
				var partner: Dictionary=core.command("trade_partners").partners[0]
				if not partner.trading:saw_closed=true
				if saw_closed and partner.trading:saw_open=true
				if saw_open and bool(core.command("episode").goals[-1].met):break
			check(saw_closed and saw_open,"final chapter's authored trade interruption ends naturally")
			check(bool(core.command("episode").goals[-1].met),"waiting goal becomes met after the native calendar advances")
			core.command("pause 1")
		var saved: Dictionary=core.save_city("chapter-review-%d"%(number+1))
		check(saved.has("saved"),"chapter checkpoint saves")
		before_buildings=footprints(core.snapshot(true).buildings)
		core.close_city()
		var loaded: Dictionary=core.open_city(engine,OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join("chapter-review-%d.ez"%(number+1)),language)
		check(not loaded.has("error") and permissions()==available and int(core.command("episode").episode_number)==number+1,"saved chapter/permissions reload")
		chapter_results.append({"chapter":number+1,"permissions":available})
		core.enable_test_commands();core.command("test_win")
		var next: Dictionary=core.command("finish_episode")
		if number<2:
			check(next.get("next")=="episode" and not next.preview.colony,"next chapter uses the same parent city")
			check(next.preview.episode_title==plan.text[language]["Parent_Episode_%d_Title"%(number+2)],"next briefing uses its own writing")
			core.command("begin_episode")
		else:check(next.get("next")=="complete","chapter three reaches the campaign ending")
	core.close_city()
	if OS.get_cmdline_user_args().has("--visible") and okay:await visible_menu(engine,plan)
	var f:=FileAccess.open(report.path_join("result.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"okay":okay,"checks":checks,"language":language,"chapters":chapter_results,"progression_victories_are_fixtures":true},"\t"))
	print("CHAPTER_REVIEW ","PASS" if okay else "FAIL"," checks=",checks," lang=",language)
	quit(0 if okay else 1)

func visible_menu(engine: String,plan: Dictionary) -> void:
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var leaders=load("res://scripts/leaders.gd")
	if leaders.list().is_empty():leaders.create("Chapter Review")
	leaders.set_current(leaders.list()[0])
	var menu=load("res://ui/start_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	for i in 30:await process_frame
	menu.open_adventures()
	for i in 30:await process_frame
	menu.navigation.adventure_pager.select_index(0);menu.start_adventure()
	for i in 25:await process_frame
	check(menu.intro_card.body.text==plan.text[language].Parent_Episode_1_Introduction,"real menu shows the new first-chapter briefing")
	RenderingServer.force_draw(true,.016);root.get_texture().get_image().save_png(report.path_join("chapter-one-briefing.png"))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_MANIFEST")))
	Engine.set_meta("ezeus_new_game_focus",manifest.start_focus)
	menu.begin()
	for i in 130:await process_frame
	var city=current_scene
	check(city is Node3D and not city.hud.build_entries.has("timber_mill") and not city.hud.build_entries.has("bibliotheke"),"real chapter-one menu hides later unlocks")
	city.core.send("pause 1")
	for i in 10:await process_frame
	RenderingServer.force_draw(true,.016);root.get_texture().get_image().save_png(report.path_join("chapter-one-city.png"))
	city.queue_free()
	for i in 4:await process_frame
