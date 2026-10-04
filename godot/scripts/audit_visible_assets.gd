extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var state: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	var buildings := {}
	var walkers := {}
	for b in state.get("buildings", []):
		var key := str(int(b.type))
		if not buildings.has(key):
			var info: Dictionary = core.command("inspect %d %d" % [int(b.x), int(b.y)])
			buildings[key] = {"count":0,"asset":b.asset,"name":info.get("name", ""),"footprints":{}}
		buildings[key].count += 1
		buildings[key].footprints["%dx%d" % [b.w,b.h]] = true
	for w in state.get("walkers", []):
		var key := str(int(w.type))
		if not walkers.has(key):
			walkers[key] = {"count":0,"asset":w.asset}
		walkers[key].count += 1
	var report := {"buildings":buildings,"walkers":walkers,"total_buildings":state.get("buildings", []).size(),"total_walkers":state.get("walkers", []).size()}
	var file := FileAccess.open("res://captures/visible-asset-audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("VISIBLE_ASSET_AUDIT ", JSON.stringify(report))
	core.close_city()
	quit()
