extends "res://scripts/playthrough_bronze_river.gd"
# Ordinary placement, trade, service and reserve commands. No editor/test calls.
var orchard := Vector2i(105,-48)
var fruit_sales := 0
var grain_imports := 0
var local_oil := 0
var local_wine := 0
var elevated_fruit := false

func choose_center() -> void:
	center = Vector2i(100,0)

func open_trade() -> void:
	var town := center
	# Put the post on the orchard approach to shorten delivery trips.
	line(Vector2i(116,0),Vector2i(125,-22))
	center = Vector2i(125,-22)
	super.open_trade()
	center = town

func plant(tool: String, count: int) -> void:
	var choices := []
	for point in tiles:
		if int(tiles[point][3]) & 8: choices.append(point)
	choices.sort_custom(func(a,b): return a.distance_squared_to(orchard)<b.distance_squared_to(orchard))
	var placed := 0
	for point in choices:
		if not core.command("preview %s %d %d 0" % [tool,point.x,point.y]).get("valid",false): continue
		command("build %s %d %d 0" % [tool,point.x,point.y])
		if tool == "orange_tree" and int(tiles[point][2]) > 0: elevated_fruit = true
		placed += 1
		if placed >= count: break
	if placed != count: okay = false; print("SETTLEMENT_ERROR insufficient orchard sites ",tool," ",placed)
	refresh()

func orchard_district(kind: String, count: int) -> void:
	var town := center
	center = orchard
	# Keep construction on dry ground; the finite fertile terraces belong to trees.
	for index in count: build(kind)
	for index in 2: build("maintenance_office")
	var warehouse := build("granary" if kind == "orange_tenders_lodge" else "warehouse")
	if not warehouse.is_empty():
		store(warehouse,{128:32} if kind == "orange_tenders_lodge" else {512:24,2048:8} if local_oil == 0 else {256:16,1024:16})
	# The source has separate old road fragments. Adjacent road access does not
	# mean the harvest can reach the town's trading post.
	connect_district(town)
	center = town

func site(tool: String, partner := -1, require_road := true) -> Dictionary:
	if center != orchard: return super.site(tool,partner,require_road)
	var choices := []
	for point in tiles:
		if point.distance_squared_to(orchard)>28*28 or not bool(tiles[point][5]): continue
		choices.append(point)
	choices.sort_custom(func(a,b): return a.distance_squared_to(orchard)<b.distance_squared_to(orchard))
	for point in choices:
		var query: Dictionary = core.command("preview %s %d %d 0 %d" % [tool,point.x,point.y,partner])
		if not query.get("valid",false) or (require_road and not adjacent_road(query)): continue
		var fertile := false
		for cell in query.tiles:
			var at := Vector2i(int(cell[0]),int(cell[1]))
			if int(tiles[at][3]) & 8: fertile = true
		if fertile: continue
		query.pointer = [point.x,point.y]
		return query
	return {}

func setup(number: int) -> void:
	command("pause 1"); refresh()
	if number == 0:
		choose_center()
		command("demolish_area 83 -10 117 10 0",false); refresh()
		for dy in [-6,0,6]: line(center+Vector2i(-16,dy),center+Vector2i(16,dy))
		line(center+Vector2i(-16,-6),center+Vector2i(-16,6))
		line(center+Vector2i(16,-6),center+Vector2i(16,6))
		for index in 30: build("house")
		for index in 2: build("fountain"); build("maintenance_office")
		build("watchpost"); build("granary"); build("warehouse")
		stores_near(center,{64:32,8192:32})
		for index in 2: build("common_agora"); vendor("food_vendor")
		for index in 4: build("timber_mill")
		open_trade(); order(64,0,true,16); order(128,1,true,16)
		orchard_district("orange_tenders_lodge",5)
		plant("orange_tree",32)
	elif number == 1:
		for index in 6: build("house")
		build("hospital")
		for index in 2: build("gymnasium")
		build("college"); build("podium"); build("warehouse")
		stores_near(center,{64:32,4096:16,8192:16,2048:16})
		for index in 2: vendor("fleece_vendor")
		order(4096,0,true,8)
		orchard_district("growers_lodge",6)
		plant("olive_tree",32)
		var town := center; center = orchard
		for index in 3: build("olive_press")
		center = town
		gardens()
	else:
		for index in 6: build("house")
		build("palace"); build("tax_office"); build("gymnasium")
		orchard_district("growers_lodge",4)
		plant("vine",40)
		var town := center; center = orchard
		for index in 3: build("winery")
		center = town
		order(2048,1,true,16)
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
			var partner: Dictionary = core.command("trade_partners").partners[0]
			for goods in partner.buys:
				if int(goods.resource) == 128: fruit_sales = maxi(fruit_sales,int(goods.used))
			for goods in partner.sells:
				if int(goods.resource) == 64: grain_imports = maxi(grain_imports,int(goods.used))
			for goal in latest.goals:
				var authored: Dictionary = plan.chapters[number].goals[int(goal.index)]
				if goal.kind == "production" and int(authored.enum1) == 2048: local_oil = maxi(local_oil,int(goal.current))
				if goal.kind == "production" and int(authored.enum1) == 1024: local_wine = maxi(local_wine,int(goal.current))
				if goal.kind == "set_aside" and goal.set_aside and not reserve_done:
					command("set_aside %d" % int(goal.index)); reserve_done = true
			if batch % 20 == 0:
				refresh()
				print("TERRACES_PROGRESS ",number+1," batch=",batch," pop=",state.population," money=",state.money," date=",state.date," goals=",JSON.stringify(latest.goals))
				write_result()
			if batch % 40 == 0 and not core.snapshot(false).get("blocked",false): core.save_city("terraces-playthrough-%d" % (number+1))
			if core.command("episode").get("victory",false): completed = true; break
			if core.snapshot(false).get("blocked",false): okay = false; print("SETTLEMENT_ERROR native decision/loss blocks progress"); break
			await process_frame
		refresh()
		stages.append({"chapter":number+1,"natural_victory":completed,"time_start":begin_time,"time_end":state.time,"population":state.population,"money":state.money,"goals":core.command("episode").goals})
		if not completed: okay = false; break
		core.save_city("terraces-complete-%d" % (number+1))
		var next := command("finish_episode")
		if number < plan.chapters.size()-1: command("begin_episode")
		else: okay = okay and next.get("next") == "complete" and reserve_done and fruit_sales>0 and grain_imports>0 and elevated_fruit
	write_result(); core.close_city()
	print("FIRST_SCENARIO_TERRACES_PLAYTHROUGH ","PASS" if okay else "FAIL"," chapters=",stages.size()," ordinary_commands=",commands," ticks=",ticks)
	quit(0 if okay else 1)

func write_result() -> void:
	# Skip Bronze River's unrelated armor/closure evidence.
	var file := FileAccess.open(report.path_join("result.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"okay":okay,"chapters":stages,"latest":latest,"commands":commands,"ticks":ticks,"test_commands_used":false,"center":[center.x,center.y]},"\t"))
	if not state.is_empty():
		var world := FileAccess.open(report.path_join("settlement-snapshot.json"),FileAccess.WRITE)
		world.store_string(JSON.stringify(state))
	var proof := FileAccess.open(report.path_join("orchard-proof.json"),FileAccess.WRITE)
	proof.store_string(JSON.stringify({"elevated_orange_trees":elevated_fruit,"reserve_committed":reserve_done,"largest_annual_orange_sales":fruit_sales,"largest_annual_grain_imports":grain_imports,"local_oil":local_oil,"local_wine":local_wine},"\t"))
