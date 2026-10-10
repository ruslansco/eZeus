extends SceneTree
# Isolated, owned headless process. A bad legacy parser cannot close or damage the
# player's active city. No rendering, ticks, autosaves, preferences or decisions.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path:="";var engine:="";var output:="";var language:="en"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-save="):path=arg.trim_prefix("--probe-save=")
		if arg.begins_with("--probe-engine="):engine=arg.trim_prefix("--probe-engine=")
		if arg.begins_with("--probe-result="):output=arg.trim_prefix("--probe-result=")
		if arg.begins_with("--probe-language="):language=arg.trim_prefix("--probe-language=")
	if path.is_empty() or output.is_empty() or engine.is_empty():quit(2);return
	Engine.set_meta("ezeus_settings_path",output+".preferences-unused")
	Engine.set_meta("ezeus_save_directory",path.get_base_dir())
	var core: RefCounted=ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(path.get_base_dir())
	var result: Dictionary=core.check_save(path)
	if not result.has("error"):
		var loaded: Dictionary=core.open_city(engine,path,language)
		if loaded.has("protocol"):
			result.ok=true;result.date=loaded.date;result.population=loaded.population;result.sha256=FileAccess.get_sha256(path)
			result.episode=core.command("episode")
		else:result=loaded
	core.close_city()
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:quit(3);return
	file.store_string(JSON.stringify(result));file.close()
	quit(0 if result.get("ok",false) else 1)
