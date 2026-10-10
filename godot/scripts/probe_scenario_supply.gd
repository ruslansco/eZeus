extends SceneTree
# Read-only diagnosis of the wrapper's disposable natural-playthrough checkpoint.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_MANIFEST")))
	var core = ClassDB.instantiate("EZeusSimulation")
	core.set_adventures_directory(str(manifest.engine).path_join("Adventures"))
	var saved := OS.get_environment("EZEUS_SCENARIO_PROBE_SAVE")
	if saved.is_empty(): saved = str(manifest.report).path_join("natural-playthrough/saves/bronze-playthrough-2.ez")
	core.set_save_directory(saved.get_base_dir())
	var state: Dictionary = core.open_city(manifest.engine,saved,"en")
	if state.has("error"): push_error(str(state)); quit(1); return
	var output := {"attention":core.command("city_attention"),"city":core.command("city_data"),"trade":core.command("trade_summary"),"production":[]}
	for building in state.buildings:
		if building.asset in ["armory","foundry","refinery","warehouse","trade_post","pier","fleece_vendor","food_vendor","bibliotheke"]:
			output.production.append(core.command("inspect %d %d" % [int(building.x),int(building.y)]))
	var file := FileAccess.open(OS.get_environment("EZEUS_SCENARIO_REPORT").path_join("supply.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t"))
	core.close_city(); quit()
