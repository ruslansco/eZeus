extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var state: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	var missing := {}; var assets := {}; var markers := 0
	var initial_buildings: int = state.get("buildings", []).size()
	var initial_walkers: int = state.get("walkers", []).size()
	var initial_time: int = state.get("time", 0)
	for sample in range(61):
		for building in state.get("buildings", []):
			if building.asset in ["native_marker", "terrain_road"]:
				if sample == 0: markers += 1
			else: audit(building, "building", missing, assets)
		for walker in state.get("walkers", []):
			audit(walker, "walker", missing, assets)
		if sample == 60: break
		if sample == 0: core.command("pause 0")
		for tick in range(20): core.advance(.05)
		state = core.snapshot(false)
	var okay := initial_buildings == 834 and initial_walkers > 200 and missing.is_empty()
	var report := {"okay":okay,"initial_buildings":initial_buildings,"initial_walkers":initial_walkers,"native_markers_and_road_cells":markers,"unique_assets":assets.size(),"missing":missing,"seconds_requested":60,"native_time_initial":initial_time,"native_time_after":state.get("time",0),"native_ticks":core.diagnostics().get("ticks",0),"decision_pending":state.get("blocked",false)}
	var file := FileAccess.open("res://captures/city-coverage.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("CITY_COVERAGE ", "PASS " if okay else "FAIL ", JSON.stringify(report))
	core.close_city()
	quit(0 if okay else 1)
func audit(entity: Dictionary, category: String, missing: Dictionary, assets: Dictionary) -> void:
	var asset := str(entity.asset)
	if not ResourceLoader.exists("res://assets/models/%s.glb" % asset):
		missing["%s:%d:%s" % [category,entity.type,asset]] = true
	else: assets[asset] = true
