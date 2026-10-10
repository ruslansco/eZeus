extends SceneTree
# Actual normal-menu/Continue flows over owned chapter fixtures. Never user profiles.
const Saves = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
const Campaigns = preload("res://scripts/campaign_library.gd")
var language := "en"
var report := ""
var engine := ""
var okay := true
var checks := 0
var menu: Control
var checkpoints := {}
var old_source := ""
var old_hash := ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.trim_prefix("--lang=")
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	engine = ProjectSettings.globalize_path("res://..").simplify_path()
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_language",language)
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("CAMPAIGN_LIBRARY_CHECK ","PASS " if value else "FAIL ",label)

func frames(count := 10) -> void:
	for frame in count: await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png(report.path_join(label+".png"))

func new_menu() -> void:
	menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu); current_scene = menu
	await frames(25)

func remove_scene() -> void:
	current_scene.queue_free()
	await frames(8)

func fixture(ref: String, chapter: int) -> Dictionary:
	Saves.activate(ref)
	DirAccess.make_dir_recursive_absolute(Saves.directory())
	var core = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(Saves.directory())
	var state: Dictionary = core.open_adventure(engine,"folder",ref,language)
	check(state.has("protocol"),"native fixture opens "+ref)
	var site := Vector2i()
	for tile in state.tiles:
		if core.command("preview house %d %d 0" % [int(tile[0]),int(tile[1])]).get("valid",false):
			site = Vector2i(int(tile[0]),int(tile[1]))
			core.command("build house %d %d 0" % [site.x,site.y]); break
	core.enable_test_commands()
	for step in chapter-1:
		core.command("test_win"); core.command("finish_episode"); core.command("begin_episode")
	var episode: Dictionary = core.command("episode")
	var observed: Dictionary = core.snapshot(true)
	var view := {"x":float(site.x),"y":float(site.y),"yaw":47.0,"pitch":49.0,"distance":30.0}
	check(core.save_city("autosave 1",view).has("saved"),"chapter fixture saves in its campaign slot")
	var path := Saves.directory().path_join("autosave 1.ez")
	var info: Dictionary = core.save_info(path)
	check(info.get("campaign_ref","") == ref and int(info.get("episode_number",0)) == chapter and info.get("hint_only",false),"bounded saved identity/chapter hint matches native state")
	var digest: String = core.replay(0,-1).digest
	var reader = ClassDB.instantiate("EZeusSimulation")
	reader.save_info(path); reader = null
	check(core.replay(0,-1).digest == digest,"informational reader preserves the owned game's native state")
	var value := {"path":path,"ref":ref,"chapter":chapter,"money":observed.money,"house":[site.x,site.y],"hash":FileAccess.get_sha256(path),"episode":episode}
	core.close_city(); Saves.activate("")
	return value

func index_of(ref: String) -> int:
	for index in menu.listing.size():
		if menu.listing[index].ref == ref: return index
	return -1

func run() -> void:
	preload("res://scripts/ui_text.gd").set_language(language)
	DisplayServer.window_set_size(Vector2i(1600,1000))
	Leaders.create("Library Review"); Leaders.set_current("Library Review")
	checkpoints.first = fixture("First Light Harbor Chapters",2)
	await create_timer(1.1).timeout
	checkpoints.tidebound = fixture("Tidebound Covenant Chapters",3)
	await create_timer(1.1).timeout
	checkpoints.sunlit = fixture("Sunlit Terraces Chapters",3)
	await create_timer(1.1).timeout
	checkpoints.stonewatch = fixture("Stonewatch Chapters",3)
	await create_timer(1.1).timeout
	checkpoints.bronze = fixture("Bronze River Chapters",3)
	check(checkpoints.values().map(func(c):return c.path).size() == 5 and checkpoints.values().all(func(c):return checkpoints.values().filter(func(d):return c.path==d.path).size()==1 and FileAccess.get_sha256(c.path)==c.hash),"identical autosave names never overwrite another campaign")
	# A previous-launcher profile is offered in place, then continued into the local
	# profile. The original and its bytes stay intact throughout the actual load.
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaigns.INDEX))
	for item in index.campaigns: item.profile_roots = []
	var previous := report.path_join("previous/saves")
	index.campaigns[-1].profile_roots = [previous.trim_prefix(engine+"/")]
	var index_path := report.path_join("library-index.json")
	var file := FileAccess.open(index_path,FileAccess.WRITE); file.store_string(JSON.stringify(index)); file.close()
	Engine.set_meta("ezeus_campaign_library_path",index_path)
	var old_folder := previous.path_join("Earlier Player")
	DirAccess.make_dir_recursive_absolute(old_folder)
	var old = ClassDB.instantiate("EZeusSimulation")
	old.set_save_directory(old_folder)
	check(old.open_adventure(engine,"folder","First Light Harbor",language).has("protocol"),"preserved previous version opens for a disposable fixture")
	old.save_city("Earlier harbor"); old_source = old_folder.path_join("Earlier harbor.ez")
	old_hash = FileAccess.get_sha256(old_source); old.close_city()
	Engine.set_meta("ezeus_include_campaign_profiles",true)
	check(Leaders.list().has("Earlier Player") and not Leaders.can_delete("Earlier Player"),"previous profile is visible and its source deletion is disabled")
	await new_menu()
	check(menu.latest_save.path == checkpoints.bronze.path and menu.continue_info.text.contains(Campaigns.title("Bronze River Chapters")) and menu.continue_info.text.contains(Campaigns.chapter_title("Bronze River Chapters",3)),"Continue names the newest campaign and exact chapter")
	await capture("main-continue")
	menu.open_saves()
	var autosaves: Array = menu.save_entries.filter(func(row): return row.name == "autosave 1")
	check(autosaves.size() == 5 and autosaves[0].info.campaign_ref != autosaves[1].info.campaign_ref and menu.save_list.get_item_text(0).contains(Campaigns.title("Bronze River Chapters")),"Load game distinguishes identically named autosaves alongside native retry checkpoints")
	menu.open_adventures(); await create_timer(.25).timeout; await frames()
	check(menu.listing.size() >= 31 and menu.listing[0].ref == "First Light Harbor Chapters" and menu.listing[1].ref == "Bronze River Chapters" and menu.listing[2].ref == "Stonewatch Chapters" and menu.listing[3].ref == "Sunlit Terraces Chapters" and menu.listing[4].ref == "Tidebound Covenant Chapters","five authored campaigns appear first in the normal library")
	check(index_of("First Light Harbor") == -1,"previous prototype is reserved for existing saves")
	for ref in ["First Light Harbor Chapters","Bronze River Chapters","Stonewatch Chapters","Sunlit Terraces Chapters","Tidebound Covenant Chapters"]:
		var selected := index_of(ref); menu.navigation.adventure_pager.select_index(selected); menu.show_adventure(selected)
		await create_timer(.25).timeout; await frames()
		var artwork:=str(Campaigns.record(ref).art)
		check(menu.adventure_image.texture!=null and menu.adventure_art.loaded_paths.get(artwork,"")==artwork and menu.adventure_image.texture.get_size()==Vector2(960,360),"campaign card displays its own static city image")
		check(menu.chapter_picker.item_count == 3 and menu.chapter_picker.visible and menu.adventure_episodes.text.contains(menu.tr("Mortal")),"three chapter previews and default difficulty for "+ref)
		for chapter in 3:
			menu.chapter_picker.select(chapter); menu.chapter_picker.item_selected.emit(chapter)
			check(menu.adventure_episode.text.contains(Campaigns.chapter_title(ref,chapter+1)) and menu.adventure_goals.get_child_count() == menu.card_preview.chapters[chapter].goals.size(),"chapter %d has its own native title/objectives" % (chapter+1))
		check(menu.campaign_progress.text.contains(Campaigns.chapter_title(ref,2 if ref.begins_with("First") else 3)),"campaign card reports the saved chapter")
		check(menu.find_children("ReadChapterBriefing","Button",true,false).is_empty(),"chapter previews have no duplicate briefing action")
		var wait_goal: Dictionary = menu.card_preview.chapters[-1].goals[-1]
		check(menu.preview_goal_text(wait_goal).contains("10" if ref.begins_with("Stonewatch") else "6") and menu.preview_goal_text(wait_goal).contains("2") and not menu.preview_goal_text(wait_goal).contains("BC"),"future chapter waiting goal displays its relative duration")
		await capture("library-"+("first-light" if ref.begins_with("First") else "stonewatch" if ref.begins_with("Stonewatch") else "sunlit-terraces" if ref.begins_with("Sunlit") else "tidebound-covenant" if ref.begins_with("Tidebound") else "bronze-river"))
		menu.start_adventure(); await frames(30)
		check(menu.page == "intro" and int(menu.opened.command("episode").episode_number) == 1,"previewing chapter three still starts a new game at chapter one")
		var introduction: String = menu.opened.command("episode").introduction
		check("".join(menu.navigation.story_pages) == introduction,"Start shows the complete native story on the next screen")
		var fits := true
		for part in menu.navigation.story_pages.size():
			menu.navigation.story_page = part; menu.navigation.show_intro_story(); await frames()
			fits = fits and menu.intro_text.get_minimum_size().y <= menu.navigation.story_slot.size.y+1
		check(fits,"every story page fits on the normal briefing screen without scrolling")
		menu.close_intro(); await frames()
	for size in [Vector2i(1280,800),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size); root.get_node("UiAccess").apply(125,130); await frames(25)
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(menu.get_node("%AdventurePage").get_global_rect()),"campaign page fits enlarged interface/text at "+str(size))
	root.get_node("UiAccess").apply(100,100); DisplayServer.window_set_size(Vector2i(1600,1000)); await frames()
	if OS.get_cmdline_user_args().has("--menu-only"):
		await remove_scene()
		finish()
		return
	menu.show_page("main"); menu.continue_button.pressed.emit()
	await wait_city(checkpoints.bronze)
	if current_scene is Node3D:
		check(current_scene.hud.build_entries.has("armory") and current_scene.hud.build_entries.has("tax_office"),"Continue restores chapter-three building permissions")
		check(current_scene.save_directory() == checkpoints.bronze.path.get_base_dir(),"continued city writes into its own campaign slot")
		await capture("continued-bronze")
		await remove_scene(); await new_menu()
	menu.load_save(checkpoints.first.path)
	await wait_city(checkpoints.first)
	if current_scene is Node3D:
		check(current_scene.hud.build_entries.has("bibliotheke") and not current_scene.hud.build_entries.has("timber_mill"),"loading First Light restores its second-chapter permissions")
		check(current_scene.save_directory() == checkpoints.first.path.get_base_dir(),"switching campaigns changes the write slot only after successful preflight")
		await remove_scene()
	await new_menu();menu.load_save(checkpoints.stonewatch.path)
	await wait_city(checkpoints.stonewatch)
	if current_scene is Node3D:
		check(current_scene.hud.build_entries.has("wall") and current_scene.hud.build_entries.has("wine_vendor") and not current_scene.hud.build_entries.has("hero_hall_theseus"),"Stonewatch restores final-chapter tools while retaining the native hero gate")
		check(current_scene.save_directory() == checkpoints.stonewatch.path.get_base_dir(),"Stonewatch has its own continued write slot")
		await remove_scene()
	await new_menu(); menu.load_save(checkpoints.sunlit.path)
	await wait_city(checkpoints.sunlit)
	if current_scene is Node3D:
		check(current_scene.hud.build_entries.has("winery") and current_scene.hud.build_entries.has("gymnasium") and not current_scene.hud.build_entries.has("bibliotheke"),"Sunlit Terraces restores vineyards and Greek culture tools")
		check(current_scene.save_directory() == checkpoints.sunlit.path.get_base_dir(),"Sunlit Terraces has its own continued write slot")
		await remove_scene()
	await new_menu(); menu.load_save(checkpoints.tidebound.path)
	await wait_city(checkpoints.tidebound)
	if current_scene is Node3D:
		check(current_scene.hud.build_entries.has("timber_mill") and current_scene.hud.build_entries.has("bibliotheke") and not current_scene.hud.build_entries.has("trade_post"),"Tidebound Covenant restores local supply and Atlantean science without trade")
		check(current_scene.save_directory() == checkpoints.tidebound.path.get_base_dir(),"Tidebound Covenant has its own continued write slot")
		await remove_scene()
	Leaders.set_current("Earlier Player"); await new_menu()
	check(menu.latest_save.path == old_source,"Continue can find an earlier-launcher save without copying it")
	menu.continue_button.pressed.emit()
	await wait_city({"ref":"First Light Harbor","chapter":1,"money":18000})
	if current_scene is Node3D:
		check(current_scene.save_game("Continued earlier harbor"),"continued previous profile can save into its new local campaign slot")
		check(current_scene.save_directory().begins_with(Saves.root()) and FileAccess.get_sha256(old_source) == old_hash,"previous source bytes remain intact after Continue and Save")
		await remove_scene()
	Leaders.set_current("Library Review")
	for ref in ["First Light Harbor Chapters","Bronze River Chapters","Stonewatch Chapters","Sunlit Terraces Chapters","Tidebound Covenant Chapters"]:
		await new_menu(); menu.open_adventures(); await create_timer(.25).timeout
		var selected := index_of(ref); menu.navigation.adventure_pager.select_index(selected); menu.show_adventure(selected)
		await create_timer(.25).timeout; menu.start_adventure(); await frames(30)
		menu.intro_card.primary.pressed.emit()
		await wait_city({"ref":ref,"chapter":1,"money":18000 if ref.begins_with("First") else 36000 if ref.begins_with("Stonewatch") or ref.begins_with("Sunlit") or ref.begins_with("Tidebound") else 24000})
		if current_scene is Node3D:
			var focus: Array = Campaigns.record(ref).start_focus
			var view: Dictionary = current_scene.save_view()
			check(Vector2(view.x,view.y).distance_to(Vector2(focus[0],focus[1])) < .5,"normal Begin applies the campaign's presentation focus")
			await remove_scene()
	Leaders.create("Delete Review"); Leaders.set_current("Delete Review"); Saves.activate("Bronze River Chapters")
	DirAccess.make_dir_recursive_absolute(Saves.directory())
	var disposable := FileAccess.open(Saves.directory().path_join("owned.txt"),FileAccess.WRITE); disposable.store_string("owned fixture"); disposable.close()
	check(Leaders.delete("Delete Review") and not DirAccess.dir_exists_absolute(Saves.root().path_join("Delete Review")),"explicit leader deletion handles owned nested campaign slots")
	finish()

func finish() -> void:
	check(FileAccess.get_sha256(old_source) == old_hash and FileAccess.get_sha256(checkpoints.first.path) == checkpoints.first.hash and FileAccess.get_sha256(checkpoints.bronze.path) == checkpoints.bronze.hash and FileAccess.get_sha256(checkpoints.stonewatch.path) == checkpoints.stonewatch.hash and FileAccess.get_sha256(checkpoints.sunlit.path) == checkpoints.sunlit.hash and FileAccess.get_sha256(checkpoints.tidebound.path) == checkpoints.tidebound.hash,"all source checkpoint bytes remain unchanged")
	var result := FileAccess.open(report.path_join("result.json"),FileAccess.WRITE)
	result.store_string(JSON.stringify({"okay":okay,"checks":checks,"language":language,"structural_chapter_wins_are_fixtures":true,"menu_only":OS.get_cmdline_user_args().has("--menu-only"),"checkpoints":checkpoints},"\t"))
	print("CAMPAIGN_LIBRARY_REVIEW ","PASS" if okay else "FAIL"," checks=",checks," lang=",language)
	quit(0 if okay else 1)

func wait_city(expected: Dictionary) -> void:
	var deadline := Time.get_ticks_msec()+45000
	while Time.get_ticks_msec() < deadline:
		if current_scene is Node3D and not current_scene.state.is_empty(): break
		await process_frame
	check(current_scene is Node3D and not current_scene.state.is_empty(),"guarded menu load reaches the city scene")
	if not current_scene is Node3D: return
	await frames(30)
	var episode: Dictionary = current_scene.core.query("episode")
	check(episode.get("campaign_ref","") == expected.ref and int(episode.episode_number) == int(expected.chapter),"immutable preflight loads the correct campaign/chapter")
	check(int(current_scene.state.money) == int(expected.money) and current_scene.state.paused,"restored treasury and native pause-on-load are preserved")
