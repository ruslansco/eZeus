extends SceneTree
# Owned review: actual native observations, UI input and GPU finish integration.
const Guidance=preload("res://ui/city_guidance.gd")
const Contact=preload("res://scripts/walker_ground_contact.gd")
var city: Node
var okay:=true
var checks:=0
var language:="en"
var timings:=[]
var finish_performance: Array=[]

func check(value: bool, text: String) -> void:
	checks+=1;okay=okay and value
	print("CITY_CLARITY_CHECK ","PASS " if value else "FAIL ",text)

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):language=arg.trim_prefix("--lang=")
	Engine.set_meta("ezeus_language",language)
	call_deferred("run")

func frames(count:=5) -> void:
	for i in count:await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/city-clarity-"+language+"-"+name+".png")

func run() -> void:
	var Leaders=load("res://scripts/leaders.gd")
	Leaders.create("City Help Review");Leaders.set_current("City Help Review")
	var source:=ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var copy: String=load("res://scripts/save_files.gd").directory().path_join("city-help-review.ez")
	check(DirAccess.copy_absolute(source,copy)==OK,"review uses a disposable copy of the designated city")
	var core: RefCounted=ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(copy.get_base_dir())
	var engine:=ProjectSettings.globalize_path("res://..")
	var loaded: Dictionary=core.open_city(engine,copy,language)
	check(loaded.has("protocol"),"native replay opens the disposable city successfully before comparing outcomes")
	if not loaded.has("protocol"):core.close_city();quit(1);return
	var before_reads: Dictionary=core.replay(0,4242)
	for i in 20:core.command("city_attention")
	var after_reads: Dictionary=core.replay(0,-1)
	check(before_reads.get("save","a")==after_reads.get("save","b") and before_reads.get("digest","a")==after_reads.get("digest","b"),"attention reads preserve same-session native state and serialized save bytes")
	var audited: Dictionary=core.replay(60,-1);core.close_city()
	core.open_city(engine,copy,language);core.replay(0,4242)
	var control: Dictionary=core.replay(60,-1);core.close_city()
	var replay_evidence:=FileAccess.open("res://captures/city-help-replay-comparison.json",FileAccess.WRITE)
	replay_evidence.store_string(JSON.stringify({"audited":audited,"control":control},"\t"));replay_evidence.close()
	check(audited.has("digest") and control.has("digest") and audited.digest==control.digest and audited.sections==control.sections and int(audited.off_thread_draws)==0 and int(control.off_thread_draws)==0,"attention report preserves seeded native gameplay replay with no worker-thread RNG")
	first_settlement_checks(core,engine,copy)
	Engine.set_meta("ezeus_load",copy);Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city=load("res://main.tscn").instantiate();root.add_child(city);current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty():await process_frame
	city.core.simulation.command("pause 1");city.core.set_process(false)
	await frames(10)
	var selected: Dictionary={}
	for building in city.state.buildings:
		if building.asset=="warehouse":selected=building;break
	var before: Dictionary=city.core.query("inspect %d %d"%[selected.x,selected.y])
	var clock: int=city.state.time
	var report: Dictionary={}
	for i in 20:
		var began:=Time.get_ticks_usec();report=city.core.query("city_attention");timings.append((Time.get_ticks_usec()-began)/1000.0)
	check(report.get("kind","")=="city_attention" and report.has("settlement"),"separate native attention report is available")
	check(int(report.settlement.roads)>0,"guide recognizes the designated city's existing static roads")
	var after: Dictionary=city.core.query("inspect %d %d"%[selected.x,selected.y])
	check(before.target_token==after.target_token and before.storage==after.storage,"background reports preserve inspector tokens and storage observations")
	check(city.core.simulation.snapshot(false).time==clock,"attention reads leave the native clock paused")
	var accurate:=true
	var kinds: Dictionary={}
	for item in report.get("items",[]):
		var native: Dictionary=city.core.query("inspect %d %d"%[item.x,item.y])
		for flag in item.flags:
			kinds[flag]=true
			match str(flag):
				"no_road":accurate=accurate and not native.road_access
				"no_workers":accurate=accurate and int(native.get("employees",-1))==0 and int(native.get("max_employees",0))>0
				"understaffed":accurate=accurate and int(native.get("employees",0))>0 and int(native.employees)<int(native.max_employees)
				"housing_decline":accurate=accurate and int(native.get("supported_level",99))<int(native.get("level",0))
				"waiting_input":accurate=accurate and native.get("production",{}).get("input",{}).get("count",999)<item.input.per_output
				"waiting_dispatch":accurate=accurate and native.get("production",{}).get("outputs",[]).any(func(output):return int(output.get("overflow",0))>0 or (int(output.get("capacity",0))>0 and int(output.get("count",0))>=int(output.capacity)))
	check(accurate and not kinds.is_empty(),"live warnings agree with native inspection: "+str(kinds.keys()))
	var help_button: Button=city.hud.get_node("%StatsRow/CityHelpButton")
	check(help_button.is_visible_in_tree() and city.hud.get_node("%ResourceRibbon").get_global_rect().encloses(help_button.get_global_rect()),"city help has a visible discoverable button in the resource header")
	help_button.pressed.emit();await frames()
	check(city.city_help.tab_buttons.attention.text!="Issues" and city.city_help.tab_buttons.guide.text!="Guide" and city.tr("All")!="All" and city.tr("Refresh")!="Refresh" if language=="ru" else true,"help titles and filter controls are translated")
	check(city.city_help.visible and not root.get_node("UiAccess").dialog_open,"attention is non-modal and does not hold the command queue")
	var paused: bool=city.core.simulation.snapshot(false).paused
	city.city_help.refresh();check(city.core.simulation.snapshot(false).paused==paused,"opening and refreshing help preserve pause state")
	await issues_checks()
	if not report.items.is_empty():
		var buttons: Array=city.city_help.body.find_children("*","Button",true,false).filter(func(node):return node.has_meta("attention_item"))
		var item: Dictionary=buttons[0].get_meta("attention_item")
		buttons[0].pressed.emit()
		check(city.inspected==Vector2i(int(item.x),int(item.y)) and city.inspector.visible,"clicking an attention item opens its actual building")
		var old: Vector2i=city.inspected
		var stale: Dictionary=item.duplicate();stale.id=-1
		city.focus_attention(stale)
		check(city.inspected==old,"stale warning cannot select a replacement building")
		var corner: Dictionary=item.duplicate();corner.x=int(item.x)+int(item.w)-1;corner.y=int(item.y)+int(item.h)-1
		city.focus_attention(corner)
		check(city.inspected==Vector2i(int(corner.x),int(corner.y)) and city.inspector.visible,"a native far-corner target inside its rendered footprint opens the same building")
	await capture("attention")
	city.open_city_help("guide");await frames()
	check(city.city_help.step==city.city_help.first_open_step(),"the guide opens on the first step this city has not done yet")
	check(city.city_help.STEPS.size()==6,"settlement guide covers roads, people, water, food, maintenance and sustainable jobs")
	for i in 5:
		city.city_help.step=i;city.city_help.render()
		check(city.city_help.milestone(i)==(int(report.settlement.get(city.city_help.STEPS[i][2],0))>0),"guide milestone %d uses native city observations"%(i+1))
	check(not city.city_help.milestone(5),"a city with vacant jobs is not marked sustainable")
	var native_report: Dictionary=city.city_help.report
	city.city_help.report={"items":[],"settlement":{"fed":3,"watered":3,"maintenance":1,"employed":12}}
	check(city.city_help.milestone(5),"a supplied, maintained and staffed settlement meets the final guide milestone")
	city.city_help.report=native_report
	city.city_help.step=0;city.city_help.render();await frames();await capture("guide")
	await guide_checks()
	var access: Node=root.get_node("UiAccess")
	access.apply(125,130);DisplayServer.window_set_size(Vector2i(1280,720));await frames(10)
	city.city_help.fit();await frames()
	var bounds: Rect2=city.city_help.card.get_global_rect()
	check(Rect2(Vector2.ZERO,city.hud.size).encloses(bounds),"guide fits enlarged interface and text in logical viewport: "+str(bounds)+" viewport="+str(city.hud.size))
	check(city.hud.get_node("%ResourceRibbon").get_global_rect().encloses(help_button.get_global_rect()),"help button stays inside the header with enlarged text")
	var bar: VScrollBar=city.city_help.scroll.get_v_scroll_bar()
	check(city.city_help.body.get_combined_minimum_size().y<=city.city_help.scroll.size.y+1 or (bar.visible and bar.size.x>=4),"an enlarged guide that must scroll shows a visible scroll bar")
	await capture("large-guide")
	var sound: Window=load("res://ui/sound_dialog.gd").open(city.hud);await frames()
	check(Rect2(Vector2.ZERO,Vector2(DisplayServer.window_get_size())).encloses(Rect2(Vector2(sound.position),Vector2(sound.size))) if DisplayServer.get_name()!="headless" else true,"soundscape option fits enlarged text in a 720p window")
	await capture("large-sound")
	sound.canceled.emit();await frames()
	access.apply(100,100);DisplayServer.window_set_size(Vector2i(1920,1080));await frames()
	city.city_help.hide()
	var frozen_signature: String=city.city_help.signature
	city.city_help._process(30)
	check(city.city_help.signature==frozen_signature,"folded help performs no native report refresh")
	city.close_inspection();city.core.simulation.command("pause 0")
	city.open_escape_menu();await frames()
	city.escape_menu.buttons.guide.pressed.emit();await frames()
	check(city.city_help.visible and not city.core.commands_held and not city.core.simulation.snapshot(false).paused,"opening guide from Game menu restores the running city and command queue")
	city.core.simulation.command("pause 1")
	var escape:=InputEventKey.new();escape.pressed=true;escape.physical_keycode=KEY_ESCAPE
	city._input(escape)
	check(not city.city_help.visible and not is_instance_valid(city.escape_menu),"Escape folds guide without opening another pause menu")
	for status in ["no_workers","understaffed","no_road","waiting_input","waiting_dispatch","no_target","industry_paused","housing_decline","construction"]:
		var advice: String=Guidance.advice({"employees":2,"max_employees":8,"input":{"resource":8192,"count":1,"per_output":4},"missing":[0,1],"progress":37},status)
		check(not advice.is_empty() and (not advice.contains("jobs are vacant") if language=="ru" else true),"translated actionable advice for "+status)
	inspector_status_checks()
	finish_checks()
	contact_checks()
	preload("res://scripts/city_site_checks.gd").new().run(city,check)
	audio_checks()
	road_warning_check()
	await frames(12)
	city.orbit.distance=18;city.orbit.snap_to_ground();await frames(12);await capture("city-finish")
	await profile_finish()
	if DisplayServer.get_name()!="headless":await preload("res://scripts/city_site_checks.gd").new().visual(city,language)
	var evidence: Dictionary={"language":language,"report_ms":timings,"issue_count":report.items.size(),"flags":kinds.keys(),"contact_samples":city.walker_contact.samples,"finish_performance":finish_performance,"support_vertices":city.building_sites.support_vertices,"scaffold_instances":city.building_sites.scaffold_instances}
	var menu_scene: String=city.START_MENU
	city.return_to_start();await frames(10)
	check(is_instance_valid(current_scene) and current_scene.scene_file_path==menu_scene,"finished city returns to the start menu with the new materials installed")
	evidence.checks=checks;evidence.okay=okay
	var output:=FileAccess.open("res://captures/city-clarity-"+language+("-headless" if DisplayServer.get_name()=="headless" else "")+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(evidence,"\t"));output.close()
	print("CITY_CLARITY_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks);quit(0 if okay else 1)

func first_settlement_checks(core: RefCounted, engine: String, copy: String) -> void:
	# Start from empty owned land using normal commands on the disposable copy.
	# No new adventure/personal save is opened, and no test stock/residents are used.
	var opened: Dictionary=core.open_city(engine,copy,language)
	check(opened.has("protocol"),"first-settlement smoke opens only the designated disposable copy")
	if not opened.has("protocol"):core.close_city();return
	var x:=int(opened.origin[0]);var y:=int(opened.origin[1]);var far_x:=x+int(opened.extent[0])-1;var far_y:=y+int(opened.extent[1])-1
	var plan: Dictionary=core.command("preview_demolish_area %d %d %d %d"%[x,y,far_x,far_y])
	check(plan.get("valid",false),"disposable designated city can provide an empty-land first-settlement fixture")
	if not plan.get("valid",false):core.close_city();return
	var cleared: Dictionary=core.command("demolish_area %d %d %d %d 1 %d"%[x,y,far_x,far_y,int(plan.target_token)])
	check(not cleared.has("error"),"first-settlement fixture clears owned buildings only in memory through native demolition")
	core.replay(40,4242)
	var empty: Dictionary=core.command("city_attention")
	check(int(empty.settlement.houses)==0 and int(empty.settlement.residents)==0 and int(empty.settlement.watered)==0 and int(empty.settlement.fed)==0 and int(empty.settlement.maintenance)==0,"empty native settlement has no resident, water, food or maintenance milestones")
	var state: Dictionary=core.snapshot(true);var tiles: Dictionary={}
	for tile in state.tiles:tiles[Vector2i(int(tile[0]),int(tile[1]))]=tile
	var plot:=Vector2i(99999,99999)
	for cell in tiles:
		var tile: Array=tiles[cell]
		if not int(tile[5]) or int(tile[3])&4 or int(tile[6])&1:continue
		var clear:=true
		for dx in range(0,14):
			for dy in range(0,4):
				var other: Array=tiles.get(cell+Vector2i(dx,dy),[])
				if other.is_empty() or not int(other[5]) or other[2]!=tile[2] or int(other[3])&4 or int(other[6])&1:clear=false;break
			if not clear:break
		if clear and core.command("preview house %d %d 0"%[cell.x+1,cell.y+1]).get("valid",false):plot=cell;break
	check(plot.x!=99999,"native rules find a compact level site for the first road, homes and services")
	if plot.x==99999:core.close_city();return
	var road: Dictionary=core.command("build_road %d %d %d %d"%[plot.x,plot.y,plot.x+13,plot.y])
	check(not road.has("error") and int(core.command("city_attention").settlement.roads)==int(empty.settlement.roads)+14,"first-settlement road construction adds exactly its fourteen native road cells")
	var house: Dictionary=core.command("build house %d %d 0"%[plot.x+1,plot.y+1])
	var homes: Dictionary=core.command("city_attention")
	check(not house.has("error") and int(homes.settlement.houses)==1 and int(homes.settlement.residents)==0,"placing an empty home does not pretend residents or water have already arrived")
	for service in [["fountain",plot.x+5],["maintenance_office",plot.x+9]]:
		var preview: Dictionary=core.command("preview %s %d %d 0"%[service[0],service[1],plot.y+1])
		check(preview.get("valid",false),"first-settlement "+str(service[0])+" fits beside the native road")
		if not preview.get("valid",false):continue
		core.command("build %s %d %d 0"%[service[0],service[1],plot.y+1])
		var current: Dictionary=core.command("city_attention")
		var affected: Array=current.items.filter(func(item):return int(item.x)==service[1] and int(item.y)==plot.y+1)
		check(not affected.is_empty() and affected[0].flags.has("no_workers") and not affected[0].flags.has("no_road"),"first-settlement "+str(service[0])+" explains real worker shortage despite a valid edge road")
	core.close_city()

# The Issues tab: counted filter pills, severity cards that are one click target each, the pager and the empty state.
func issues_checks() -> void:
	var help: Control=city.city_help
	var items: Array=help.report.get("items",[])
	var cards: Array=help.body.find_children("*","Button",true,false).filter(func(node):return node.has_meta("attention_item"))
	check(cards.size()==mini(items.size(),help.PAGE_SIZE),"Issues shows one clickable card per warning on the page")
	var pills: Array=help.body.find_children("*","Button",true,false).filter(func(node):return node.theme_type_variation=="IssueFilter")
	check(pills.size()==help.FILTERS.size() and pills[0].button_pressed and pills[0].text.ends_with(city.hud.group_digits(items.size())),"filter pills show their counts with All selected")
	if not cards.is_empty():
		var card: Control=cards[0].get_parent()
		check(card.theme_type_variation=="IssueCard"+help.SEVERITY.get(help.status_for(cards[0].get_meta("attention_item")),"Info"),"each card carries its warning's severity edge")
		check(cards[0].get_global_rect().is_equal_approx(card.get_global_rect()),"the whole card is one click target")
	await capture("issues")
	var ids: Array=help.FILTERS.map(func(spec):return spec[0])
	var empty_ids: Array=ids.filter(func(id):return id!="all" and not items.any(func(item):return help.matches(item,id)))
	var used_ids: Array=ids.filter(func(id):return id!="all" and items.any(func(item):return help.matches(item,id)))
	if not empty_ids.is_empty():check(pills[ids.find(empty_ids[0])].disabled,"a filter pill with nothing in it is disabled: "+str(empty_ids[0]))
	if not used_ids.is_empty():
		var chosen: String=used_ids[0]
		pills[ids.find(chosen)].pressed.emit();await frames()
		cards=help.body.find_children("*","Button",true,false).filter(func(node):return node.has_meta("attention_item"))
		var expected: int=items.filter(func(item):return help.matches(item,chosen)).size()
		check(help.filter_id==chosen and cards.size()==mini(expected,help.PAGE_SIZE) and cards.all(func(node):return help.matches(node.get_meta("attention_item"),chosen)),"a filter pill narrows the cards to its warnings: "+chosen)
	help.filter_id="all";help.page=0;help.signature="";help.render();await frames()
	if items.size()>help.PAGE_SIZE:
		var range_text: String=city.tr("%d–%d of %d")%[1,help.PAGE_SIZE,items.size()]
		check(help.body.find_children("*","Label",true,false).any(func(node):return node.text==range_text),"the pager shows the visible range: "+range_text)
	var native: Dictionary=help.report
	help.age=-1000.0
	help.report={"items":[],"settlement":native.get("settlement",{})};help.signature="";help.render();await frames()
	var calm: Array=help.body.find_children("*","Label",true,false).filter(func(node):return node.text==city.tr("Nothing needs attention right now."))
	check(calm.size()==1 and help.body.find_children("*","Button",true,false).filter(func(node):return node.has_meta("attention_item")).is_empty(),"a city with no warnings shows a calm empty state")
	await capture("issues-empty")
	help.report=native;help.age=0.0;help.signature="";help.render();await frames()

# The stepper: tabs, live status, dock pointers, Build and view actions, Back/Next, folding and the opt-out link.
func guide_checks() -> void:
	var help: Control=city.city_help
	var Settings=preload("res://scripts/user_settings.gd")
	check(help.tab_buttons.guide.button_pressed and not help.tab_buttons.attention.button_pressed,"the Guide tab is the selected segment")
	var settlement: Dictionary=help.report.get("settlement",{})
	var chip: Node=help.body.find_child("StepStatus",true,false)
	var chip_text: String=chip.find_children("*","Label",true,false)[0].text if chip!=null else ""
	check(chip!=null and chip.theme_type_variation==("GuideChipDone" if help.milestone(0) else "GuideChipTodo") and chip_text.contains(city.tr("Done") if help.milestone(0) else city.tr("Not yet")) and chip_text.contains(city.hud.group_digits(int(settlement.get("roads",0)))),"the current step shows its native state and road count: "+chip_text)
	check(help.scroll.custom_minimum_size.y<=help.body.get_combined_minimum_size().y+1,"the guide card is sized to its content")
	var map: Control=city.hud.get_node("%MinimapPanel")
	if map.is_visible_in_tree():check(not help.card.get_global_rect().intersects(map.get_global_rect()),"the guide stops above the open minimap")
	var native_report: Dictionary=help.report
	help.age=-1000.0  # hold the five-second refresh so the fresh-city sample stays in place
	help.report={"items":[],"settlement":{"roads":14,"houses":0,"residents":0,"watered":0,"fed":0,"employed":0,"maintenance":0}}
	help.step=1;help.render();await frames()
	var house: Control=city.hud.tool_buttons.get("house")
	var marks: Array=help.targets()
	check(house!=null and marks.size()==1 and marks[0]==house,"a step not yet done points at the dock tool that builds it")
	chip=help.body.find_child("StepStatus",true,false)
	check(chip.theme_type_variation=="GuideChipTodo" and chip.find_children("*","Label",true,false)[0].text.contains(city.tr("Not yet")),"an unfinished step says Not yet with its count")
	await capture("guide-fresh")
	help.body.find_child("NextStep",true,false).pressed.emit();await frames()
	check(help.step==2,"Next step advances exactly one step")
	var category: Control=city.hud.category_buttons.get("Health and water")
	if category!=null:
		marks=help.targets()
		check(marks.size()==1 and marks[0]==category,"the water step points at the Health and water category")
		var build: Array=help.body.find_children("*","Button",true,false).filter(func(node):return node.text==city.tr("Health and water"))
		build[0].pressed.emit();await frames()
		check(city.hud.get_node("%BuildTray").visible and city.hud.active_category=="Health and water" and help.targets().is_empty(),"Build opens the step's category and the pointer stops once it is open")
		city.hud.close_build_tray();await frames()
	help.view_button.pressed.emit();await frames()
	check(city.hud.current_overlay=="water","the step's view button shows its overlay")
	help.view_button.pressed.emit();await frames()
	check(city.hud.current_overlay=="normal","pressing the view button again returns to the normal view")
	# Each overlay change posts a timed notice pill. Let it finish here: later pauses stretch it into the draw-call profile.
	var notice: Control=city.hud.get_node("%Feedback");var waited:=0.0
	while notice.visible and waited<6.0:await process_frame;waited+=get_root().get_process_delta_time()
	var back: Array=help.body.find_children("*","Button",true,false).filter(func(node):return node.text==city.tr("Back"))
	back[0].pressed.emit();await frames()
	check(help.step==1,"Back returns one step")
	var tall: float=help.card.size.y
	help.set_folded(true);await frames()
	check(help.summary.visible and not help.scroll.visible and help.card.size.y<tall*.4 and help.summary.text.contains(city.tr(help.STEPS[1][0])),"the collapsed guide keeps a one-line tracker with the current step")
	await capture("guide-folded")
	help.summary.pressed.emit();await frames()
	check(not help.folded and help.scroll.visible,"the tracker line expands the guide again")
	var skip: Array=help.body.find_children("*","Button",true,false).filter(func(node):return node.text==city.tr("Don't offer again"))
	skip[0].pressed.emit()
	check(not help.visible and Settings.get_value("interface","settlement_guide_finished",false),"Don't offer again hides the guide and stops automatic offers")
	Settings.set_value("interface","settlement_guide_finished",false)
	help.report=native_report;city.open_city_help("guide");help.step=0;help.render();await frames()
	check(help.age<5.0,"reopening the guide restores its normal refresh")

func inspector_status_checks() -> void:
	var summary=load("res://ui/inspection_summary.gd").new()
	var producer: Dictionary={"employees":8,"max_employees":8,"production":{"status":"operational","outputs":[{"count":4,"capacity":4}]}}
	check(summary.state_for(producer)=="waiting_dispatch" and producer.production.status=="operational","full output gets pickup advice without changing the native production state")
	producer.employees=2
	check(summary.state_for(producer)=="understaffed","vacant jobs take priority over the output-stock hint")
	producer.production.status="waiting_input"
	check(summary.state_for(producer)=="waiting_input","the native reason for stopped production remains authoritative")
	var home: Dictionary={"residents":12,"level":2,"supported_level":2,"missing":[0]}
	check(summary.state_for(home)=="housing","optional next-level housing needs do not become a decline warning")
	home.supported_level=1
	check(summary.state_for(home)=="housing_decline","an occupied home unable to maintain its current level gets a decline warning")
	home.residents=0;home.road_access=false
	check(summary.state_for(home)=="no_road","an empty disconnected house explains its missing road instead of only vacant capacity")
	summary.free()

func road_warning_check() -> void:
	var candidate:=Vector2i(99999,99999)
	var attempts:=0
	var candidates: Array=city.tiles.keys()
	var focus:=Vector2i(int(city.state.focus[0]),int(city.state.focus[1]))
	candidates.sort_custom(func(a,b):return a.distance_squared_to(focus)<b.distance_squared_to(focus))
	for cell in candidates:
		var tile: Array=city.tiles[cell]
		if int(tile[5])!=1 or int(tile[4])!=0 or (int(tile[3])&16)!=0:continue
		var found: bool=false
		for dx in range(-1,3):
			for dy in range(-1,3):
				var neighbour: Array=city.tiles.get(cell+Vector2i(dx,dy),[])
				if neighbour.is_empty() or int(neighbour[4])!=0:found=true
		if found:continue
		var preview: Dictionary=city.core.query("preview maintenance_office %d %d 0"%[cell.x,cell.y])
		attempts+=1
		if preview.get("valid",false):candidate=cell;break
		if attempts>=24:break
	check(candidate.x!=99999,"native placement finds an isolated maintenance-office fixture")
	if candidate.x==99999:return
	var built: Dictionary=city.core.query("build maintenance_office %d %d 0"%[candidate.x,candidate.y])
	check(not built.has("error"),"disposable fixture uses real native construction")
	if built.has("error"):return
	city.core.snapshot_received.emit(built)
	var report: Dictionary=city.core.query("city_attention")
	var issues: Array=report.items.filter(func(item):return int(item.x)==candidate.x and int(item.y)==candidate.y)
	check(not issues.is_empty() and issues[0].flags.has("no_road"),"a newly disconnected building has a clickable native road-access warning")
	if not issues.is_empty():
		city.city_help.filter_id="roads"
		check(city.city_help.status_for(issues[0])=="no_road","road filter leads with road access even when the building also lacks workers")
		city.city_help.filter_id="all"
		city.focus_attention(issues[0]);check(not city.inspector_controls.value.road_access,"road warning opens the disconnected building's exact inspector")
	city.core.snapshot_received.emit(city.core.query("undo"))
	var after: Dictionary=city.core.query("city_attention")
	check(after.items.filter(func(item):return int(item.x)==candidate.x and int(item.y)==candidate.y).is_empty(),"undo removes the road warning without leaving a stale target")

func finish_checks() -> void:
	var changed:=0
	for name in ["common_house_2a","fountain","wall_5","tower","gatehouse","warehouse","sanctuary_temple_0"]:
		var pieces: Array=city.static_batches.template(name)
		var finishes:=pieces.filter(func(piece):return piece.material is ShaderMaterial and piece.material.shader in [city.static_batches.finish.SHADER,city.static_batches.construction.SHADER])
		changed+=finishes.size()
		check(not pieces.is_empty() and not finishes.is_empty(),name+" uses shared architecture finish without new geometry")
	check(changed>6,"stone finish is reused across everyday buildings and defences")
	check(not city.static_batches.finish.eligible("walker_hydra") and not city.static_batches.finish.eligible("transporter"),"monster and citizen finishes retain their existing art adapters")
	var box:=BoxMesh.new();var material:=StandardMaterial3D.new();material.metallic=1;material.vertex_color_use_as_albedo=true;box.material=material
	var prop:=MeshInstance3D.new();prop.mesh=box
	city.static_batches.finish.apply(prop,"tower");check(prop.material_override==null,"architecture adapter preserves metal surfaces")
	material.metallic=0;material.albedo_texture=GradientTexture2D.new()
	city.static_batches.finish.apply(prop,"tower");check(prop.material_override==null,"architecture adapter preserves textured surfaces");prop.free()
	# Exercise the actual runtime material cache and native construction bar.
	var animated: bool=false
	for material_key in city.static_batches.activity.materials:
		var work: ShaderMaterial=city.static_batches.activity.materials[material_key]
		animated=animated or work.get_shader_parameter("smooth_work")
	check(animated,"live authored work materials enable bounded cubic interpolation")
	var saved=city.static_batches.activity.phase
	city.static_batches.activity.running=false;city.static_batches.activity.to_phase=saved;city.static_batches.activity.advance(.3)
	check(city.static_batches.activity.phase==saved,"smooth work still holds the exact pose while paused")
	var Inspector=load("res://scripts/building_inspector.gd")
	var panel=Inspector.new();root.add_child(panel)
	panel.build_monument({"title":"Test","finished":false});panel.construction_bar.value=37
	check(panel.construction_bar.show_percentage and panel.construction_bar.value==37,"construction has a visible percentage bar")
	panel.queue_free()

class SlopeCity extends Node:
	var terrain_geometry: Dictionary={"near_slope":{Vector2i.ZERO:true}}
	var surface_revision:=1
	var calls:=0
	func tile_coordinates(point: Vector3) -> Vector2:return Vector2(point.x,point.z)
	func walker_surface_position(point: Vector3, offset: float, _bridge: bool) -> Vector3:
		calls+=1;return Vector3(point.x,point.x*.3+offset,point.z)

func contact_checks() -> void:
	var fixture:=SlopeCity.new();var support:=Contact.new();var node:=Node3D.new()
	var entry: Dictionary={"node":node,"human":true,"offset":0.0,"action":1}
	var lift:=support.lift(entry,Vector3.ZERO,fixture)
	check(is_equal_approx(lift,.03),"sloped sole support prevents upper foot penetration")
	support.lift(entry,Vector3.ZERO,fixture)
	check(fixture.calls==4,"stationary slope support reuses its sampled heights")
	support.lift(entry,Vector3(.01,.003,0),fixture)
	check(fixture.calls==4,"small sub-tile travel reuses the local slope support")
	fixture.surface_revision+=1;support.lift(entry,Vector3.ZERO,fixture)
	check(fixture.calls==8,"terrain edits invalidate slope support")
	fixture.terrain_geometry.near_slope.clear();fixture.surface_revision+=1
	check(support.lift(entry,Vector3.ZERO,fixture)==0 and fixture.calls==8,"level ground adds no support samples or lift")
	fixture.terrain_geometry.near_slope[Vector2i.ZERO]=true;entry.waterborne=true
	check(support.lift(entry,Vector3.ZERO,fixture)==0,"boats retain native water height")
	node.free();fixture.free()

func audio_checks() -> void:
	var audio: Node=root.get_node("GameAudio")
	audio.enabled=false
	audio.set_original_soundscape(true);audio.music_kind="";audio.play_music("city")
	check(audio.music_track==audio.ORIGINAL_SCORE,"original score option selects the shipped composition")
	for path in [audio.ORIGINAL_SCORE,audio.ORIGINAL_AMBIENCE]:
		var stream: AudioStream=audio.load_stream(path)
		check(stream is AudioStreamWAV and is_equal_approx(stream.get_length(),48),"original WAV loads through imported resources: "+str(path.get_file()))
	audio.set_original_soundscape(false);audio.music_kind="";audio.play_music("city")
	check(audio.music_track.begins_with("Audio/Music/"),"soundscape toggle retains the previous soundtrack option")
	audio.set_original_soundscape(true);audio.music_kind="";audio.play_music("battle")
	check(audio.music_track.begins_with("Audio/Music/Battle"),"battle cues preserve their existing soundtrack")

func profile_finish() -> void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var originals: Dictionary={}
	for group in city.static_batches.group_nodes.values():
		for node in group:
			if node.material_override!=null and node.material_override.has_meta("architecture_source"):originals[node]=node.material_override
	var modes: Array=[false,true,false,true]
	var anchor: Vector3=city.orbit.target
	city.orbit.set_process(false)
	for enabled in modes:
		for node in originals:node.material_override=originals[node] if enabled else originals[node].get_meta("architecture_source")
		for material in city.static_batches.activity.materials.values():material.set_shader_parameter("smooth_work",enabled)
		await frames(30)
		var cpu:=0.0;var gpu:=0.0;var draws:=0.0
		for i in 80:
			city.orbit.target=anchor+Vector3(3*sin(i*.05),0,3*cos(i*.05));city.orbit.snap_to_ground()
			await process_frame
			cpu+=RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
			gpu+=RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		finish_performance.append({"finish":enabled,"cpu_render_ms":cpu/80,"gpu_render_ms":gpu/80,"draw_calls":draws/80})
		city.orbit.target=anchor;city.orbit.snap_to_ground()
	check(absf(finish_performance[0].draw_calls-finish_performance[1].draw_calls)<1,"finish adds no draw calls in the same moving city view")
	print("CITY_CLARITY_PERFORMANCE ",JSON.stringify(finish_performance))
