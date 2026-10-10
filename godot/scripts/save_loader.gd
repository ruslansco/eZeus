extends RefCounted
# Read/parse an immutable private copy in an owned headless process before the
# current city is replaced. Never restores a backup silently or edits a source.
const Files=preload("res://scripts/save_files.gd")
var cancelled:=false
var accepted:=false
var rejected:=false
var process_id:=-1

static func choose_city(parent: Node, path: String, language:= "en") -> Dictionary:
	var loader: RefCounted=load("res://scripts/save_loader.gd").new()
	return await loader.choose(parent,path,language)

func choose(parent: Node, path: String, language: String) -> Dictionary:
	var tree:=parent.get_tree()
	var access: Node=tree.root.get_node("UiAccess")
	var previous: bool=access.dialog_open
	access.dialog_open=true
	var dialog:=ConfirmationDialog.new();dialog.name="SaveRecovery";dialog.title=TranslationServer.translate("Load saved city")
	dialog.dialog_autowrap=true
	dialog.ok_button_text=TranslationServer.translate("Load recovered copy")
	dialog.cancel_button_text=TranslationServer.translate("Cancel")
	dialog.dialog_text=TranslationServer.translate("Checking the saved city…")
	dialog.dialog_hide_on_ok=false;dialog.get_ok_button().disabled=true
	dialog.confirmed.connect(func():accepted=true)
	dialog.canceled.connect(func():cancelled=true)
	dialog.close_requested.connect(func():cancelled=true)
	parent.add_child(dialog);dialog.popup_centered(Vector2i(520,230))
	var options: Array=Files.candidates(path)
	var best: Dictionary={};var primary: Dictionary={};var error:="save_not_found"
	var core: RefCounted=ClassDB.instantiate("EZeusSimulation")
	for option in options:
		if cancelled:break
		# Native integrity checks are pure and safe while the parent's core owns
		# gameplay. Legacy complete parsing is isolated in probe() below.
		var integrity: Dictionary=core.check_save(option.path)
		if integrity.has("error"):
			if option.kind=="primary":error=str(integrity.error)
			continue
		if not primary.is_empty() and (option.kind!="pending" or int(option.modified)<int(primary.modified)):continue
		var checked: Dictionary=await probe(parent,str(option.path),language)
		if not checked.get("ok",false):
			if option.kind=="primary":error=str(checked.get("error","invalid_save"))
			continue
		checked.kind=option.kind;checked.modified=option.modified;checked.origin=path
		if option.kind=="primary":primary=checked;best=checked
		else:
			if best.is_empty() or int(option.modified)>int(best.modified) or best.get("kind","")=="primary":
				if not best.is_empty() and best!=primary:clean(best)
				best=checked
			else:clean(checked)
			if option.kind=="backup" or primary.is_empty():break
	if not best.is_empty() and not cancelled:
		if best.kind!="primary":
			var local_time:=int(best.modified)+int(Time.get_time_zone_from_system().bias)*60
			var date:=Time.get_datetime_string_from_unix_time(local_time,true).replace("T"," ")
			dialog.dialog_text=TranslationServer.translate("A readable recovery copy from %s is available. Load it? Your original save will be kept.")%date
			dialog.get_ok_button().disabled=false
			if not primary.is_empty():
				dialog.cancel_button_text=TranslationServer.translate("Use saved version")
			while not accepted and not cancelled:await tree.process_frame
			if cancelled and not primary.is_empty():clean(best);best=primary;cancelled=false
	else:
		if not cancelled:
			dialog.dialog_text=TranslationServer.translate("This save needs a newer game version. Your current city and the saved files are unchanged.") if error=="incompatible_save" else TranslationServer.translate("This city could not be loaded. No readable recovery copy was found. Your current city and the saved files are unchanged.")
			dialog.cancel_button_text=TranslationServer.translate("Close")
			while not cancelled:await tree.process_frame
	if cancelled:
		clean(best)
		if primary!=best:clean(primary)
		best={"error":error,"cancelled":true}
	elif best.is_empty():best={"error":error}
	else:
		if primary!=best:clean(primary)
		best.recovered=best.kind!="primary"
	access.dialog_open=previous
	dialog.hide();dialog.queue_free()
	await tree.process_frame
	return best

func probe(parent: Node, source: String, language: String) -> Dictionary:
	var folder:=Files.staging().path_join("%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()])
	if DirAccess.make_dir_recursive_absolute(folder)!=OK:return {"error":"save_directory_unavailable"}
	var copy:=folder.path_join("verified.ez");var output:=folder.path_join("result.json")
	if DirAccess.copy_absolute(source,copy)!=OK:DirAccess.remove_absolute(folder);return {"error":"save_not_found"}
	var engine: String=str(Engine.get_meta("ezeus_engine_directory",ProjectSettings.globalize_path("res://..")))
	var arguments:=PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://scripts/save_probe.gd","--log-file",folder.path_join("probe.log"),"--","--silent","--probe-save="+copy,"--probe-result="+output,"--probe-engine="+engine,"--probe-language="+language])
	process_id=OS.create_process(OS.get_executable_path(),arguments,false)
	if process_id<=0:clean({"stage":copy});return {"error":"save_check_failed"}
	var deadline:=Time.get_ticks_msec()+30000
	while OS.is_process_running(process_id) and not cancelled and Time.get_ticks_msec()<deadline:await parent.get_tree().create_timer(.05).timeout
	if OS.is_process_running(process_id):OS.kill(process_id)
	process_id=-1
	var result: Dictionary={"error":"invalid_save"}
	if FileAccess.file_exists(output):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(output))
		if parsed is Dictionary:result=parsed
	if result.get("ok",false) and not cancelled and str(result.get("sha256",""))==FileAccess.get_sha256(copy):result.stage=copy
	else:clean({"stage":copy});result={"error":result.get("error","invalid_save")}
	return result

static func clean(result: Dictionary) -> void:
	var path: String=str(result.get("stage",""))
	if path.is_empty():return
	if not DirAccess.dir_exists_absolute(path.get_base_dir()):return
	# A private, freshly allocated probe folder contains only our own files.
	for file in DirAccess.get_files_at(path.get_base_dir()):DirAccess.remove_absolute(path.get_base_dir().path_join(file))
	DirAccess.remove_absolute(path.get_base_dir())
