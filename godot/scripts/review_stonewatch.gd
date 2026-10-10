extends SceneTree
# Template/menu/checkpoint checks. Fixture wins are separate from normal gameplay.
var core: RefCounted
var okay := true
var checks := 0
var language := "en"
var report := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):language=arg.trim_prefix("--lang=")
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_engine_directory",OS.get_environment("EZEUS_SCENARIO_ENGINE"))
	Engine.set_meta("ezeus_language",language)
	call_deferred("run")

func check(value: bool,label: String) -> void:
	checks+=1;okay=okay and value
	print("STONEWATCH_CHECK ","PASS " if value else "FAIL ",label)

func permissions() -> Dictionary:
	var result: Dictionary={}
	for b in core.command("buildable").buildings:result[b.name]=b.available
	return result

func footprint() -> Array:
	var result: Array=[]
	for b in core.snapshot(true).buildings:result.append([b.asset,b.x,b.y,b.w,b.h])
	result.sort_custom(func(a,b):return JSON.stringify(a)<JSON.stringify(b));return result

func run() -> void:
	var engine:=OS.get_environment("EZEUS_SCENARIO_ENGINE");report=OS.get_environment("EZEUS_SCENARIO_REPORT")
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_PLAN")))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_MANIFEST")))
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(str(manifest.report).path_join("source-terrain.json")))
	core=ClassDB.instantiate("EZeusSimulation");core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"));core.set_adventures_directory(engine.path_join("Adventures"))
	var listing: Array=core.adventures(engine,language).adventures
	check(listing.size()==1 and listing[0].ref==plan.development_name,"isolated new campaign identity")
	var preview: Dictionary=core.adventure_preview(engine,"folder",plan.development_name,language)
	check(preview.chapters.size()==3 and int(preview.episode_total)==3,"three native parent chapter previews")
	core.open_editor(engine,"folder",plan.development_name,language)
	var authored_world: Dictionary=core.command("editor_world")
	check(int(authored_world.cities[0].team)!=int(authored_world.cities[int(plan.rival_index)].team),"export/reload retains opposing native combat teams")
	check(core.command("editor_city_team 8 -1").get("error","")=="invalid_team" and core.command("editor_city_team 8 10").get("error","")=="invalid_team","editor refuses invalid combat teams")
	check(core.command("editor_city_team 999 1").get("error","")=="unknown_city" and core.command("editor_city_team 0 1").get("error","")=="foreign_city_required","team authoring rejects missing/player cities")
	core.close_city()
	var state: Dictionary=core.open_adventure(engine,"folder",plan.development_name,language)
	check(core.command("editor_city_team 8 1").get("error","")=="not_editing","ordinary gameplay refuses combat-team authoring")
	check(state.tiles.size()==25992 and int(state.money)==36000,"complete map and opening funds")
	var terrain:=true
	for index in state.tiles.size():terrain=terrain and state.tiles[index].slice(0,4)==source.tiles[index].slice(0,4)
	check(terrain,"retained terrain, height and coordinates")
	var partners: Array=core.command("trade_partners").partners
	check(partners.size()==1 and partners[0].water and partners[0].sells.any(func(g):return int(g.resource)==32768),"sea partner supplies food and the hero's marble")
	var old:=[]
	for number in 3:
		var episode: Dictionary=core.command("episode")
		check(int(episode.episode_number)==number+1 and episode.episode_title==plan.text[language]["Parent_Episode_%d_Title" % (number+1)],"chapter index/localized title")
		check(episode.goals.size()==plan.chapters[number].goals.size(),"chapter-specific objective count")
		check(episode.voice.is_empty() and episode.victory_voice.is_empty(),"original adventure narrations excluded")
		var available:=permissions()
		check(available.house and available.timber_mill and available.pier and not available.foundry,"forest/sea-trade foundations without local metal industry")
		check(bool(available.wall)==(number>=1) and bool(available.palace)==(number>=1) and bool(available.bibliotheke)==(number>=1),"defense/civic/science tools unlock in chapter two")
		check(bool(available.wine_vendor)==(number==2) and bool(available.elite_house)==(number==2),"later optional housing tools unlock in chapter three")
		if number>0:check(footprint()==old,"constructed city carries between parent chapters")
		if number==0:
			check(core.command("test_win").has("error"),"ordinary play cannot force victory")
			for tile in state.tiles:
				if core.command("preview house %d %d 0" % [int(tile[0]),int(tile[1])]).get("valid",false):
					check(not core.command("build house %d %d 0" % [int(tile[0]),int(tile[1])]).has("error"),"ordinary house built for carry/save checks");break
		var checkpoint:="stonewatch-review-%d" % number
		check(core.save_city(checkpoint).has("saved"),"chapter checkpoint saves")
		var saved_footprint:=footprint();core.close_city()
		check(core.open_city(engine,OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join(checkpoint+".ez"),language).has("protocol") and permissions()==available and footprint()==saved_footprint,"checkpoint reload preserves chapter/permissions/buildings")
		if number==1:
			check(not core.command("episode").goals[-1].met,"future BC defense waiting goal starts false")
			core.command("speed 3");core.command("pause 0")
			var decision: Dictionary={}
			for batch in 180:
				for tick in 10:core.advance(.05)
				var observation: Dictionary=core.snapshot(true)
				for event in observation.events:
					if event.get("actions",[]).any(func(action):return int(action.choice)==2):decision=event
				if not decision.is_empty():break
			check(not decision.is_empty() and core.snapshot(false).blocked,"authored invasion presents its native blocking decision")
			check(core.save_city("pending-invasion").get("error","")=="pending_decision","pending invasion cannot be saved or silently dismissed")
			core.close_city();core.open_city(engine,OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY").path_join(checkpoint+".ez"),language)
		if number==2:
			check(not core.command("episode").goals[1].met and not permissions().hero_hall_theseus,"slaying initially unmet and hero hall gated by the monster event")
			core.command("speed 3");core.command("pause 0")
			var minotaur:=false
			for batch in 180:
				for tick in 10:core.advance(.05)
				minotaur=core.snapshot(true).walkers.any(func(w):return w.asset=="walker_minotaur")
				if minotaur:break
			check(minotaur and permissions().hero_hall_theseus,"scheduled native Minotaur unlocks Theseus's hall")
			check(not core.command("episode").goals[1].met,"monster arrival alone cannot satisfy slaying")
			core.command("pause 1")
		old=footprint();core.enable_test_commands();core.command("test_win")
		var next: Dictionary=core.command("finish_episode")
		if number<2:check(next.get("next")=="episode" and not next.preview.colony,"next chapter stays in the same city");core.command("begin_episode")
		else:check(next.get("next")=="complete","final native campaign ending")
	core.close_city()
	if OS.get_cmdline_user_args().has("--visible") and okay:await visible_menu(plan,manifest)
	var file:=FileAccess.open(report.path_join("result.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"okay":okay,"checks":checks,"language":language,"structural_wins_are_fixtures":true},"\t"))
	print("FIRST_SCENARIO_STONEWATCH_REVIEW ","PASS" if okay else "FAIL"," checks=",checks," lang=",language)
	quit(0 if okay else 1)

func visible_menu(plan: Dictionary,manifest: Dictionary) -> void:
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var leaders=load("res://scripts/leaders.gd");leaders.create("Stonewatch Review");leaders.set_current("Stonewatch Review")
	var menu=load("res://ui/start_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	for frame in 25:await process_frame
	menu.open_adventures()
	for frame in 30:await process_frame
	check(menu.chapter_picker.item_count==3 and menu.listing[0].ref==plan.development_name,"real campaign browser exposes all three chapters")
	menu.start_adventure()
	for frame in 30:await process_frame
	var expected:=str(plan.text[language].Parent_Episode_1_Introduction).replace("@P","\n\n   ")
	check(str(menu.intro_card.body.text).strip_edges()==expected.strip_edges(),"complete authored opening briefing")
	RenderingServer.force_draw(true,.016);root.get_texture().get_image().save_png(report.path_join("stonewatch-briefing.png"))
	Engine.set_meta("ezeus_new_game_focus",manifest.start_focus);menu.begin()
	for frame in 140:await process_frame
	var city=current_scene
	check(city is Node3D and city.hud.build_entries.has("timber_mill") and not city.hud.build_entries.has("wall") and not city.hud.build_entries.has("palace"),"real opening Build menu respects chapter gates")
	city.core.send("pause 1")
	for frame in 10:await process_frame
	RenderingServer.force_draw(true,.016);root.get_texture().get_image().save_png(report.path_join("stonewatch-opening.png"))
	city.queue_free()
	for frame in 8:await process_frame
