extends SceneTree
# Local authoring tool. The Python wrapper supplies an isolated compatibility root.
var core: RefCounted
var output := {}
var engine := ""
var report := ""
var okay := true
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("FIRST_SCENARIO_CHECK ", "PASS " if value else "FAIL ", message)

func command(text: String) -> Dictionary:
	var result: Dictionary = core.command(text)
	if result.has("error"):
		check(false, text + ": " + str(result.error))
	return result

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		check(false, "cannot write " + path)
		return
	file.store_string(JSON.stringify(value, "\t"))

func run() -> void:
	engine = OS.get_environment("EZEUS_SCENARIO_ENGINE")
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	var plan_path := OS.get_environment("EZEUS_SCENARIO_PLAN")
	if plan_path.is_empty(): plan_path = "res://../content/scenarios/first_light_harbor_chapters.json"
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var build := OS.get_cmdline_user_args().has("--build")
	core = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	core.set_adventures_directory(engine.path_join("Adventures"))
	var listing: Dictionary = core.adventures(engine, "en")
	var candidates: Array = listing.get("adventures", []).filter(func(a): return a.kind == "pak")
	check(candidates.size() == 1, "one isolated source is listed")
	if candidates.size() != 1:
		quit(1)
		return
	var state: Dictionary = core.open_editor(engine, "pak", candidates[0].ref, "en")
	check(not state.has("error") and state.get("editor", false), "source imports into the native editor")
	if state.has("error"):
		quit(1)
		return
	var original: Dictionary = command("editor")
	var original_world: Dictionary = command("editor_world")
	output.source = {"overview": original, "world": original_world, "extent": state.get("extent"), "focus": state.get("focus"), "tiles": state.get("tiles", []).size()}
	output.source.city_forms = []
	for city in original_world.cities: output.source.city_forms.append(command("editor_city %d" % int(city.index)))
	write_json(report.path_join("source-terrain.json"), state)
	if build:
		var before_tiles: Array = core.snapshot(true).tiles
		check(core.command("editor_single_parent ../invalid").get("error") == "invalid_name", "invalid adaptation name refused")
		var fresh: Dictionary = command("editor_single_parent " + str(plan.development_name))
		check(fresh.get("parent", []).size() == 1 and fresh.get("colonies", []).is_empty(), "one new parent episode and no colony boards")
		check(core.snapshot(true).tiles == before_tiles, "parent terrain preserved during campaign separation")
		command("editor_date 1 0 %d" % int(plan.start_year))
		command("editor_difficulty %d" % int(plan.difficulty))
		for funds in fresh.funds:
			command("editor_funds %d %d" % [int(funds.player), int(plan.initial_funds)])
		command("editor_prices_reset")
		var world: Dictionary = command("editor_world")
		var parent_id: int = int(command("editor_episode p 0").cities[0].id)
		var parent_index := -1
		var partner_index := -1
		for city in world.cities:
			if int(city.id) == parent_id:
				parent_index = int(city.index)
			elif not bool(city.on_board) and partner_index < 0 and str(city.type) == "Foreign city":
				partner_index = int(city.index)
		# Native type labels can vary; use the typed field for selection.
		if partner_index < 0:
			for city in world.cities:
				var form: Dictionary = command("editor_city %d" % int(city.index))
				for field in form.fields:
					if field.id == "type" and int(field.value) == 2 and not city.on_board and partner_index < 0:
						partner_index = int(city.index)
		if plan.has("partner_index"): partner_index = int(plan.partner_index)
		check(parent_index >= 0 and partner_index >= 0, "parent and an existing off-board trade partner found")
		if partner_index < 0:
			quit(1)
			return
		var rival_index := int(plan.get("rival_index",-1))
		for city in world.cities:
			var index: int = int(city.index)
			command("editor_city_name %d %s" % [index, plan.text.en.parent_name if index == parent_index else plan.text.en.partner_name if index == partner_index else str(plan.get("rival_name","")) if index == rival_index else "Outer Anchorage %d" % index])
			command("editor_city_leader %d %s" % [index, str(plan.get("rival_leader",plan.text.en.leader)) if index == rival_index else plan.text.en.leader])
			command("editor_city_set %d visible %d" % [index, int(index in [parent_index, partner_index,rival_index])])
			if index != parent_index:
				command("editor_city_set %d active %d" % [index, 0 if index in [partner_index,rival_index] else 1])
			command("editor_city_set %d tribute_count 0" % index)
			var form: Dictionary = command("editor_city %d" % index)
			for side in ["buys", "sells"]:
				for trade in form[side]:
					command("editor_city_trade %d %s %d 0" % [index, side, int(trade.resource)])
		command("editor_city_set %d relationship 1" % partner_index)
		if rival_index >= 0:
			command("editor_city_set %d relationship 2" % rival_index)
			command("editor_city_set %d nationality 0" % rival_index)
			command("editor_city_set %d military 1" % rival_index)
			output.rival_team = command("editor_city_team %d 1" % rival_index)
		for side in ["buys", "sells"]:
			for resource in plan.trade[side]:
				command("editor_city_trade %d %s %d %d" % [partner_index, side, int(resource), int(plan.trade[side][resource])])
		var types: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report.path_join("building-types.json")))
		for number in plan.chapters.size():
			var chapter: Dictionary = plan.chapters[number]
			if number > 0: command("editor_episode_add")
			var ep: Dictionary = command("editor_episode p %d" % number)
			for city in ep.cities:
				command("editor_gods p %d %d -" % [number, int(city.id)])
				command("editor_max_sanctuaries p %d %d 0" % [number, int(city.id)])
				for building in city.buildings:
					var allowed := false
					for name in chapter.allowed_buildings: allowed = allowed or int(types[name]) == int(building.type)
					command("editor_building p %d %d %d %d" % [number, int(city.id), int(building.type), int(allowed)])
			for goal in chapter.goals:
				var added: Dictionary = command("editor_goal_add p %d %d" % [number, int(goal.type)])
				var index: int = added.goals.size() - 1
				for field in goal:
					if field != "type": command("editor_goal_set p %d %d %s %d" % [number, index, field, int(goal[field])])
			if chapter.has("challenge"):
				var challenge: Dictionary = chapter.challenge
				var partner_id: int = int(world.cities[partner_index].id)
				var event: Dictionary = command("editor_event_add p %d %d %d" % [number, parent_id, int(challenge.event_type)])
				var fields := {"city_min": partner_id, "city_max": partner_id, "god": int(challenge.god), "years_min": int(challenge.year), "years_max": int(challenge.year), "months": int(challenge.month), "days": 0, "duration": int(challenge.duration_days), "repeat": 1, "complete": 0}
				for field in fields: command("editor_event_set p %d %d %d %s %d" % [number, parent_id, int(event.index), field, int(fields[field])])
			for specification in chapter.get("events",[]):
				var event: Dictionary = command("editor_event_add p %d %d %d" % [number,parent_id,int(specification.type)])
				for field in specification.get("fields",{}):
					var value: int = int(specification.fields[field])
					if field in ["city_min","city_max"] and specification.get("target","") == "rival": value = int(world.cities[rival_index].id)
					command("editor_event_set p %d %d %d %s %d" % [number,parent_id,int(event.index),field,value])
				var authored_event: Dictionary = command("editor_event p %d %d %d" % [number,parent_id,int(event.index)])
				if specification.get("target","") == "rival":
					check(authored_event.fields.filter(func(f):return f.id in ["city_min","city_max"]).all(func(f):return int(f.value)==int(world.cities[rival_index].id)),"invasion selects the authored rival")
		for marker in plan.get("markers",[]):
			command("editor_paint %s %d square 1 %d %d" % [marker.tool,int(marker.id),int(marker.x),int(marker.y)])
		command("editor_save")
		output.authored = {"overview": command("editor"), "episodes": [], "world": command("editor_world"), "partner_index": partner_index}
		for number in plan.chapters.size():
			var authored: Dictionary = command("editor_episode p %d" % number)
			output.authored.episodes.append(authored)
			check(authored.goals.size() == plan.chapters[number].goals.size(), "chapter %d objectives authored" % (number + 1))
		write_json(report.path_join("adapted-terrain.json"), core.snapshot(true))
	core.close_city()
	output.okay = okay
	output.checks = checks
	write_json(report.path_join("authoring.json"), output)
	print("FIRST_SCENARIO_AUTHORING ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
