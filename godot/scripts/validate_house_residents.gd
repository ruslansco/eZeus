extends "res://scripts/playthrough_tidebound_covenant.gd"
# Ordinary immigration and scratch saves; no resident/stock/rule injection.
const Activity = preload("res://scripts/building_activity.gd")
const Batches = preload("res://scripts/building_batches.gd")
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("HOUSE_RESIDENT_CHECK ", "PASS " if value else "FAIL ", label)
func houses(snapshot: Dictionary) -> Array:
	return snapshot.buildings.filter(func(b): return str(b.asset).begins_with("common_house_"))
func occupancy_matches(snapshot: Dictionary) -> bool:
	for b in houses(snapshot):
		var info: Dictionary = core.command("inspect %d %d" % [b.x,b.y])
		if bool(b.working) != (int(info.get("residents",0)) > 0): return false
	return true
func run() -> void:
	engine = ProjectSettings.globalize_path("res://..").simplify_path()
	core = ClassDB.instantiate("EZeusSimulation")
	var directory := OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY")
	if directory.is_empty():
		push_error("Use tools/review_housing_art.py --checks with disposable save/preferences paths")
		quit(1); return
	core.set_save_directory(directory)
	core.set_adventures_directory(engine.path_join("Adventures"))
	for lang in ["en","ru"]:
		var opened: Dictionary = core.open_adventure(engine,"folder","Tidebound Covenant Chapters",lang)
		check(opened.has("protocol"),lang+" fresh ordinary campaign opens")
		if not opened.has("protocol"): continue
		setup(0); command("pause 1")
		var empty: Dictionary = core.snapshot(true)
		check(houses(empty).size()==30 and int(empty.population)==0 and houses(empty).all(func(b): return not b.working),lang+" all thirty newly built homes have no resident")
		check(occupancy_matches(empty),lang+" visible resident state agrees with exact native occupancy")
		check(core.save_city("empty-"+lang).has("saved"),lang+" empty settlement saves to the scratch directory")
		core.close_city()
		var reopened: Dictionary = core.open_city(engine,directory.path_join("empty-"+lang+".ez"),lang)
		check(houses(reopened).size()==30 and houses(reopened).all(func(b):return not b.working),lang+" empty homes remain empty after save/reload")
		command("pause 0"); command("speed 3")
		var arrived := {}; var saw_delta := false
		for step in 800:
			core.advance(.05)
			var delta: Dictionary = core.snapshot(false)
			if delta.get("buildings_changed",false):
				saw_delta = true
				if houses(delta).any(func(b):return b.working): arrived=delta; break
			if delta.get("blocked",false): break
		check(not arrived.is_empty() and saw_delta and occupancy_matches(arrived),lang+" ordinary immigrant arrival updates the resident through a building delta")
		command("pause 1")
		check(occupancy_matches(core.snapshot(true)),lang+" occupied and empty homes agree with native counts after arrival")
		check(core.save_city("occupied-"+lang).has("saved"),lang+" occupied settlement saves to the scratch directory")
		core.close_city()
		var occupied: Dictionary=core.open_city(engine,directory.path_join("occupied-"+lang+".ez"),lang)
		check(houses(occupied).any(func(b):return b.working) and occupancy_matches(occupied),lang+" occupied household visibility survives save/reload")
		core.close_city()
	var activity := Activity.new()
	var batches := Batches.new(); root.add_child(batches)
	for level in 7:
		var asset := "common_house_%da" % level
		var info: Dictionary=activity.contract(asset)
		check(not info.is_empty() and info.metadata.building_activity.occupied_only and is_equal_approx(float(info.metadata.building_activity.work_rate),.2),asset+" fresh occupancy-only four-second activity derivative")
		var preview: Array = batches.preview_template(asset)
		check(not preview.is_empty() and preview.all(func(p):return not p.activity and not (p.material is ShaderMaterial and p.material.shader==Activity.SHADER)),asset+" placement ghost has architecture only and no household shader")
		var key := asset+"|occupancy-proof"
		var placements := [{"transform":Transform3D.IDENTITY,"working":false,"animation_offset":0}]
		batches.rebuild({key:placements}); var nodes: Array=batches.group_nodes[key].duplicate()
		placements[0].working=true;batches.rebuild({key:placements})
		var reused: bool = batches.last_rebuilt==0 and nodes==batches.group_nodes[key] and batches.last_activity_updates>0
		placements[0].working=false;batches.rebuild({key:placements})
		check(reused and batches.last_rebuilt==0 and nodes==batches.group_nodes[key],asset+" first occupant and final departure change only instance data")
	batches.free()
	print("HOUSE_RESIDENT_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
