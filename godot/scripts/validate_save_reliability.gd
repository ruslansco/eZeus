extends SceneTree
const Files=preload("res://scripts/save_files.gd")
const Loader=preload("res://scripts/save_loader.gd")
var okay:=true
var checks:=0
var language:="en"
var city: Node

func check(value: bool,text: String) -> void:
	checks+=1;okay=okay and value;print("SAVE_RELIABILITY_CHECK ","PASS " if value else "FAIL ",text)

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):language=arg.trim_prefix("--lang=")
	Engine.set_meta("ezeus_language",language);call_deferred("run")

func frames(count:=5) -> void:
	for i in count:await process_frame

class DialogDriver extends Node:
	var host: Node
	var choice:="confirm"
	var captured:=false
	var capture_path:=""
	func _process(_dt: float) -> void:
		var dialogs: Array=host.get_children().filter(func(child):return child is ConfirmationDialog and child.name=="SaveRecovery")
		if dialogs.is_empty():return
		var dialog: ConfirmationDialog=dialogs[0]
		if dialog.get_ok_button().disabled and dialog.dialog_text.contains(TranslationServer.translate("Checking the saved city…")):return
		set_process(false)
		if not captured and not capture_path.is_empty() and DisplayServer.get_name()!="headless":
			captured=true;await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(capture_path)
		if choice=="confirm" and not dialog.get_ok_button().disabled:dialog.confirmed.emit()
		else:dialog.canceled.emit()

func choose(path: String,choice: String,capture_name: String) -> Dictionary:
	var driver:=DialogDriver.new();driver.host=city.hud;driver.choice=choice
	driver.capture_path="res://captures/save-reliability-"+language+"-"+capture_name+".png"
	root.add_child(driver)
	var result: Dictionary=await Loader.choose_city(city.hud,path,language)
	driver.queue_free();await frames(2);return result

func run() -> void:
	var directory:=Files.directory();DirAccess.make_dir_recursive_absolute(directory)
	var core: RefCounted=ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(directory)
	var engine:=ProjectSettings.globalize_path("res://..")
	var source:=engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var source_hash:=FileAccess.get_sha256(source)
	var opened: Dictionary=core.open_city(engine,source,language)
	check(opened.has("protocol"),"only the designated city is opened for native save tests")
	if not opened.has("protocol"):quit(1);return
	var site:=Vector2i(99999,99999)
	for tile in opened.tiles:
		if int(tile[5]) and not int(tile[4]) and core.command("preview house %d %d 2"%[tile[0],tile[1]]).get("valid",false):site=Vector2i(tile[0],tile[1]);break
	check(site.x!=99999,"native rules find an asymmetric building facing fixture")
	if site.x==99999:core.close_city();quit(1);return
	core.command("build house %d %d 2"%[site.x,site.y]);core.command("speed 3")
	var view: Dictionary={"x":float(site.x)+1.25,"y":float(site.y)+1.5,"yaw":137.0,"pitch":42.0,"distance":23.5}
	var primary:=directory.path_join("reliability.ez")
	var first: Dictionary=core.save_city("reliability",view)
	check(first.has("saved") and first.get("durability_confirmed",false),"new save finishes with durability confirmation")
	check(core.check_save(primary).get("guarded",false),"native payload and presentation data share one checked file")
	var original_hash:=FileAccess.get_sha256(primary)
	var before: Dictionary=core.replay(0,-1)
	core.close_city();var loaded: Dictionary=core.open_city(engine,primary,language)
	check(loaded.has("protocol") and loaded.speed==3 and loaded.saved_camera==[view.x,view.y,view.yaw,view.pitch,view.distance],"speed and exact native-coordinate camera view survive reload")
	var building: Array=loaded.buildings.filter(func(item):return int(item.x)==site.x and int(item.y)==site.y and str(item.asset).begins_with("common_house_"))
	check(building.size()==1 and int(building[0].orientation)==2,"explicit asymmetric building facing survives reload")
	check(core.replay(0,-1).digest==before.digest,"presentation trailer leaves native gameplay state unchanged")
	for speed in 4:
		core.command("speed %d"%speed);core.save_city("speed %d"%speed,view);core.close_city()
		var speed_save: Dictionary=core.open_city(engine,directory.path_join("speed %d.ez"%speed),language)
		check(speed_save.has("protocol") and int(speed_save.speed)==speed,"native speed %d survives a save/reload"%speed)
	core.command("speed 3")
	core.save_city("reliability",view)
	check(FileAccess.get_sha256(primary+".bak1")==original_hash,"overwrite keeps the exact previous save")
	var second_hash:=FileAccess.get_sha256(primary)
	core.save_city("reliability",view)
	check(FileAccess.get_sha256(primary+".bak2")==original_hash and FileAccess.get_sha256(primary+".bak1")==second_hash,"two earlier protected copies are retained")
	core.enable_test_commands()
	for point in ["after_write","before_backup","before_replace"]:
		var committed:=FileAccess.get_sha256(primary)
		core.command("test_save_failure "+point)
		var failed: Dictionary=core.save_city("reliability",view)
		check(failed.has("error") and FileAccess.get_sha256(primary)==committed,"interruption at "+point+" preserves committed progress")
		check(core.check_save(directory.path_join(failed.temporary)).get("guarded",false),"complete interrupted staging remains a valid recovery candidate")
		DirAccess.remove_absolute(directory.path_join(failed.temporary))
	var damaged:=FileAccess.get_file_as_bytes(primary);damaged[100]=damaged[100]^1
	var file:=FileAccess.open(primary,FileAccess.WRITE);file.store_buffer(damaged);file.close()
	var live: Dictionary=core.snapshot(true)
	check(core.open_city(engine,primary,language).get("error","")=="save_checksum_failed","changed protected payload is rejected before parsing")
	var same: Dictionary=core.snapshot(true)
	check(same.time==live.time and same.money==live.money and same.buildings==live.buildings,"early corrupt-load rejection preserves the existing native board and cached building records")
	var good_backup:=FileAccess.get_sha256(primary+".bak1")
	check(core.save_city("reliability",view).has("saved") and FileAccess.get_sha256(primary+".bak1")==good_backup and FileAccess.file_exists(primary+".damaged"),"resaving preserves damaged evidence and cannot replace a good backup with bad bytes")
	check(core.save_city("bad view",{"x":NAN,"y":0,"yaw":0,"pitch":49,"distance":20}).get("error","")=="invalid_save_metadata","non-finite presentation values cannot be saved")
	core.close_city()
	# Owned city UI remains loaded while isolated probes validate candidates.
	Engine.set_meta("ezeus_load",primary);city=load("res://main.tscn").instantiate();root.add_child(city);current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty():await process_frame
	city.core.set_process(false);city.core.query("pause 1");await frames(10)
	check(absf(city.orbit.yaw-view.yaw)<.001 and absf(city.orbit.pitch-view.pitch)<.001 and absf(city.orbit.distance-view.distance)<.001,"actual scene restores saved orbit and zoom")
	var digest: String=city.core.simulation.replay(0,-1).digest
	var healthy: Dictionary=await choose(primary,"confirm","healthy")
	check(healthy.get("ok",false) and not healthy.recovered and FileAccess.get_sha256(healthy.stage)==FileAccess.get_sha256(primary),"healthy load uses the exact immutable copy proven readable by a separate process")
	Loader.clean(healthy)
	# Corrupt only our fixture, then exercise explicit recovery and cancellation.
	file=FileAccess.open(primary,FileAccess.WRITE);file.store_buffer(damaged);file.close()
	var damaged_hash:=FileAccess.get_sha256(primary)
	var declined: Dictionary=await choose(primary,"cancel","recovery")
	check(not declined.get("ok",false) and FileAccess.get_sha256(primary)==damaged_hash and city.core.simulation.replay(0,-1).digest==digest,"declining recovery keeps the active city and the original damaged file")
	var recovered: Dictionary=await choose(primary,"confirm","accepted")
	print("SAVE_RECOVERY_DIAGNOSTIC ",JSON.stringify({"ok":recovered.get("ok",false),"recovered":recovered.get("recovered",false),"error":recovered.get("error",""),"original_unchanged":FileAccess.get_sha256(primary)==damaged_hash}))
	check(recovered.get("ok",false) and recovered.recovered and FileAccess.get_sha256(primary)==damaged_hash,"backup recovery requires an explicit choice and keeps original evidence")
	Loader.clean(recovered)
	city.core.simulation.enable_test_commands();city.core.query("test_save_failure after_write")
	var interrupted: Dictionary=city.core.simulation.save_city("interrupted",view)
	var missing_primary:=directory.path_join("interrupted.ez")
	check(interrupted.has("error") and not FileAccess.file_exists(missing_primary) and Files.list(directory).any(func(entry):return entry.path==missing_primary and entry.recovery),"an interrupted first save remains discoverable even without a primary file")
	var resumed: Dictionary=await choose(missing_primary,"confirm","interrupted")
	check(resumed.get("ok",false) and resumed.recovered and resumed.kind=="pending","a complete interrupted first save can be loaded by explicit recovery")
	Loader.clean(resumed)
	var legacy_copy:=directory.path_join("legacy.ez");DirAccess.copy_absolute(source,legacy_copy)
	var legacy: Dictionary=await choose(legacy_copy,"confirm","legacy")
	check(legacy.get("ok",false) and not legacy.get("guarded",true),"existing footerless saves still receive a full isolated parser check")
	Loader.clean(legacy)
	var short_copy:=directory.path_join("truncated legacy.ez")
	var old_bytes:=FileAccess.get_file_as_bytes(source);file=FileAccess.open(short_copy,FileAccess.WRITE);file.store_buffer(old_bytes.slice(0,old_bytes.size()/2));file.close()
	var truncated: Dictionary=await choose(short_copy,"cancel","truncated")
	check(not truncated.get("ok",false) and city.core.simulation.replay(0,-1).digest==digest,"truncated legacy body is rejected by isolated parsing without touching the active city")
	var broken:=directory.path_join("broken.ez");file=FileAccess.open(broken,FileAccess.WRITE);file.store_string("not a native city");file.close()
	var rejected: Dictionary=await choose(broken,"cancel","damaged")
	check(not rejected.get("ok",false) and city.core.simulation.replay(0,-1).digest==digest,"unrecoverable file cannot discard the running city or switch to a test city")
	var newer:=directory.path_join("newer.ez");var newer_bytes:=FileAccess.get_file_as_bytes(primary+".bak1");newer_bytes[12]=7
	file=FileAccess.open(newer,FileAccess.WRITE);file.store_buffer(newer_bytes);file.close()
	var future: Dictionary=await choose(newer,"cancel","newer")
	check(not future.get("ok",false) and city.core.simulation.replay(0,-1).digest==digest,"a newer unsupported save version is refused without replacing the active game")
	check(city.sanitize_save_name("Сохранение".repeat(10)).to_utf8_buffer().size()<=64,"save-name UI respects the native UTF-8 byte limit")
	var driver:=DialogDriver.new();driver.host=city.hud;driver.choice="cancel";root.add_child(driver)
	city.core.snapshot_received.emit(city.core.query("pause 0"))
	var held: bool=city.core.commands_held
	await city.load_game(broken);driver.queue_free()
	check(current_scene==city and not city.core.simulation.snapshot(false).paused and city.core.commands_held==held and not city.save_load_busy,"public failed-load path restores the running game and its prior command hold")
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	check(FileAccess.get_sha256(source)==source_hash,"designated source remains unchanged")
	city.return_to_start();await frames(10)
	print("SAVE_RELIABILITY_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
