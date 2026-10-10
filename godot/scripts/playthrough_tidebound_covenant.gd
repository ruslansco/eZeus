extends "res://scripts/playthrough_bronze_river.gd"
# Ordinary economy proof: no imports, tribute, editor, stock or victory injection.
var committed := {}
var production := {64:0,4096:0,8192:0}
var no_trade := true

func choose_center() -> void:
	center = Vector2i(110,-45)

func pasture(count: int) -> void:
	var choices := []
	var placed := []
	for point in tiles:
		if int(tiles[point][3]) & 8 and point.distance_squared_to(center) < 18*18:
			choices.append(point)
	choices.sort_custom(func(a,b): return a.distance_squared_to(center)<b.distance_squared_to(center))
	for point in choices:
		# Native placement permits several animals on one cell. Give shepherds
		# distinct grazing sites instead of repeatedly selecting the same cell.
		if placed.any(func(p): return p.distance_squared_to(point)<4): continue
		if not core.command("preview sheep %d %d 0" % [point.x,point.y]).get("valid",false): continue
		command("build sheep %d %d 0" % [point.x,point.y])
		placed.append(point)
		if placed.size() == count: break
	if placed.size() != count: okay = false; print("SETTLEMENT_ERROR insufficient separate pasture sites")
	refresh()

func setup(number: int) -> void:
	command("pause 1"); refresh()
	if number == 0:
		choose_center()
		for dy in [-6,0,6]: line(center+Vector2i(-16,dy),center+Vector2i(16,dy))
		line(center+Vector2i(-16,-6),center+Vector2i(-16,6))
		line(center+Vector2i(16,-6),center+Vector2i(16,6))
		# Reserve a town exit before placing dense housing and civic footprints.
		line(center,Vector2i(110,-70))
		for index in 30: build("house")
		for index in 2: build("fountain"); build("maintenance_office")
		build("watchpost"); build("granary"); build("warehouse")
		for index in 2: build("common_agora"); vendor("food_vendor")
		for index in 6: build("wheat_farm")
	elif number == 1:
		for index in 6: build("house")
		build("hospital"); build("bibliotheke"); build("observatory")
		build("palace"); build("tax_office"); build("warehouse")
		stores_near(center,{4096:32})
		for index in 2: vendor("fleece_vendor")
		gardens()
		# Keep pasture outside the gardened housing district. Decorative placement
		# can replace native livestock reservations while the city is paused.
		var town := center
		center = Vector2i(110,-70)
		line(town,center)
		for index in 6: build("carding_shed")
		build("maintenance_office")
		var shed_store := build("warehouse")
		if not shed_store.is_empty(): store(shed_store,{4096:32})
		pasture(24)
		connect_district(town)
		center = town
	else:
		for index in 6: build("house")
		build("granary")
		# Fleece-filled bays cannot receive the first timber delivery. Keep one
		# dedicated timber store rather than changing orders on full warehouses.
		var timber_store := build("warehouse")
		if not timber_store.is_empty(): store(timber_store,{8192:32})
		var town := center
		for index in 4:
			var mill := build("timber_mill")
			if not mill.is_empty():
				center = Vector2i(int(mill.x),int(mill.y))
				connect_district(town)
				center = town
		for index in 2: build("wheat_farm")
		build("maintenance_office"); build("tax_office")
		gardens()
	command("speed 3"); command("pause 0")

func run() -> void:
	engine = OS.get_environment("EZEUS_SCENARIO_ENGINE")
	report = OS.get_environment("EZEUS_SCENARIO_REPORT")
	plan = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_PLAN")))
	core = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	core.set_adventures_directory(engine.path_join("Adventures"))
	var opened: Dictionary = core.open_adventure(engine,"folder",plan.development_name,"en")
	if opened.has("error"): push_error(str(opened)); quit(1); return
	for number in plan.chapters.size():
		setup(number)
		if not okay: break
		var begin_time: float = float(core.snapshot(false).time)
		var completed := false
		for batch in 900:
			for step in 10: core.advance(.05); ticks += 1
			latest = core.command("episode")
			for partner in core.command("trade_partners").partners:
				no_trade = no_trade and partner.buys.is_empty() and partner.sells.is_empty()
			for goal in latest.goals:
				var authored: Dictionary = plan.chapters[number].goals[int(goal.index)]
				if goal.kind == "production":
					var resource := int(authored.enum1)
					production[resource] = maxi(production[resource],int(goal.current))
				if goal.kind == "set_aside" and goal.set_aside and not committed.has(int(goal.index)):
					command("set_aside %d" % int(goal.index)); committed[int(goal.index)] = int(authored.enum1)
			if batch % 20 == 0:
				refresh()
				print("COVENANT_PROGRESS ",number+1," batch=",batch," pop=",state.population," money=",state.money," date=",state.date," goals=",JSON.stringify(latest.goals))
				write_result()
			if batch % 40 == 0 and not core.snapshot(false).get("blocked",false): core.save_city("covenant-playthrough-%d" % (number+1))
			if core.command("episode").get("victory",false): completed = true; break
			if core.snapshot(false).get("blocked",false): okay = false; print("SETTLEMENT_ERROR native decision/loss blocks progress"); break
			await process_frame
		refresh()
		stages.append({"chapter":number+1,"natural_victory":completed,"time_start":begin_time,"time_end":state.time,"population":state.population,"money":state.money,"goals":core.command("episode").goals})
		if not completed: okay = false; break
		var next := command("finish_episode")
		if number < plan.chapters.size()-1: command("begin_episode")
		else: okay = okay and next.get("next") == "complete" and committed.size() == 2 and no_trade
	write_result(); core.close_city()
	print("FIRST_SCENARIO_COVENANT_PLAYTHROUGH ","PASS" if okay else "FAIL"," chapters=",stages.size()," ordinary_commands=",commands," ticks=",ticks)
	quit(0 if okay else 1)

func write_result() -> void:
	var file := FileAccess.open(report.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"okay":okay,"chapters":stages,"latest":latest,"commands":commands,"ticks":ticks,"test_commands_used":false,"center":[center.x,center.y]},"\t"))
	if not state.is_empty():
		var world := FileAccess.open(report.path_join("settlement-snapshot.json"),FileAccess.WRITE)
		world.store_string(JSON.stringify(state))
	var proof := FileAccess.open(report.path_join("self-supply-proof.json"),FileAccess.WRITE)
	proof.store_string(JSON.stringify({"no_trade":no_trade,"committed_reserves":committed,"largest_annual_local_production":production},"\t"))
