extends "res://scripts/playthrough_first_scenario.gd"
# Reuses ordinary placement helpers; this campaign has no local fleece and
# copper lies outside the town. Never enables test commands or injects stock.
var trade_building := {}
var saw_closed := false
var saw_reopened := false
var reserve_done := false
var industry := Vector2i()
var armor_sales_observed := 0
var fleece_imports_observed := 0

func connect_district(town: Vector2i) -> void:
	var bridge_cells := {}
	for point in tiles:
		if not int(tiles[point][3]) & 4: continue
		var query: Dictionary = core.command("preview bridge %d %d 0" % [point.x,point.y])
		if query.get("valid",false):
			for cell in query.tiles:
				var at := Vector2i(int(cell[0]),int(cell[1]))
				if not bridge_cells.has(at): bridge_cells[at] = point
	var roads := []
	for point in tiles:
		if int(tiles[point][4]): roads.append(point)
	roads.sort_custom(func(a,b): return a.distance_squared_to(center)<b.distance_squared_to(center))
	if roads.is_empty(): okay = false; return
	var queue := [roads[0]]
	var previous := {roads[0]:roads[0]}
	var index := 0
	var end := Vector2i()
	var found := false
	while index < queue.size():
		var point: Vector2i = queue[index]; index += 1
		if point.distance_squared_to(town) < 16 and int(tiles[point][4]):
			end = point; found = true; break
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = point+delta
			if previous.has(next) or not tiles.has(next): continue
			if int(tiles[next][4]) or bridge_cells.has(next) or (int(tiles[next][3]) & 16 and int(tiles[next][2]) == 0) or core.command("preview road %d %d 0" % [next.x,next.y]).get("valid",false):
				previous[next] = point; queue.append(next)
	if not found: okay = false; print("SETTLEMENT_ERROR no connected industrial route"); return
	while true:
		if bridge_cells.has(end) and not int(tiles[end][4]):
			var at: Vector2i = bridge_cells[end]
			command("build bridge %d %d 0" % [at.x,at.y]); refresh()
		road_at(end)
		if previous[end] == end: break
		end = previous[end]
	refresh()

func choose_center() -> void:
	var copper := []
	for point in tiles:
		if int(tiles[point][3]) & 128: copper.append(point)
	var best := -INF
	for point in tiles:
		if posmod(point.x,5) != 0 or posmod(point.y,5) != 0: continue
		var valid := true
		var meadow := 0
		for dx in range(-17,18):
			for dy in range(-10,11):
				var tile: Array = tiles.get(point+Vector2i(dx,dy),[])
				if tile.is_empty() or int(tile[2]) != 0 or int(tile[3]) & ~(1|8|16|32) or int(tile[6]) & 8:
					valid = false; break
				if int(tile[3]) & 8: meadow += 1
			if not valid: break
		if not valid or meadow < 30: continue
		var distance := INF
		for ore in copper: distance = minf(distance,point.distance_to(ore))
		var score: float = meadow - 5 * distance
		if score > best: best = score; center = point
	if best == -INF: okay = false; print("SETTLEMENT_ERROR no town rectangle")

func site(tool: String, partner := -1, require_road := true) -> Dictionary:
	if tool != "foundry": return super.site(tool,partner,require_road)
	var copper := []
	var choices := []
	var distance := {}
	for point in tiles:
		if int(tiles[point][3]) & 128: copper.append(point)
		elif bool(tiles[point][5]): choices.append(point)
	for point in choices:
		var nearest := INF
		for ore in copper: nearest = minf(nearest,point.distance_squared_to(ore))
		distance[point] = nearest + .005*point.distance_squared_to(center)
	choices.sort_custom(func(a,b): return distance[a] < distance[b])
	for point in choices:
		var query: Dictionary = core.command("preview foundry %d %d 0" % [point.x,point.y])
		if query.get("valid",false):
			query.pointer = [point.x,point.y]
			return query
	return {}

func add_road_access(preview: Dictionary) -> void:
	if adjacent_road(preview): return
	# Find an actual buildable route around copper, rocks and water instead of
	# assuming a straight line from the distant industrial district can be built.
	var starts := []
	var x := int(preview.x); var y := int(preview.y)
	var w := int(preview.w); var h := int(preview.h)
	for dx in range(w): starts.append(Vector2i(x+dx,y-1)); starts.append(Vector2i(x+dx,y+h))
	for dy in range(h): starts.append(Vector2i(x-1,y+dy)); starts.append(Vector2i(x+w,y+dy))
	var queue := []
	var previous := {}
	for point in starts:
		if core.command("preview road %d %d 0" % [point.x,point.y]).get("valid",false):
			queue.append(point); previous[point] = point
	var index := 0
	var end := Vector2i()
	var found := false
	while index < queue.size():
		var point: Vector2i = queue[index]; index += 1
		if int(tiles[point][4]): end = point; found = true; break
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = point+delta
			if previous.has(next) or not tiles.has(next): continue
			if int(tiles[next][4]) or core.command("preview road %d %d 0" % [next.x,next.y]).get("valid",false):
				previous[next] = point; queue.append(next)
	if not found: okay = false; print("SETTLEMENT_ERROR no road access"); return
	while true:
		road_at(end)
		if previous[end] == end: break
		end = previous[end]
	refresh()

func order(resource: int, direction: int, enabled: bool, quota: int) -> void:
	if trade_building.is_empty(): okay = false; return
	var x := int(trade_building.x); var y := int(trade_building.y)
	var info: Dictionary = core.command("inspect %d %d" % [x,y])
	command("trade %d %d %d %d %d %d %d" % [x,y,int(info.target_token),resource,direction,int(enabled),quota])

func open_trade() -> void:
	var partner: Dictionary = core.command("trade_partners").partners[0]
	build("pier" if partner.water else "trade_post",int(partner.index))
	for building in state.buildings:
		if building.asset in ["pier","trade_post"]: trade_building = building
	order(8192,1,true,32)

func store(building: Dictionary, goods: Dictionary) -> void:
	var x := int(building.x); var y := int(building.y)
	var info: Dictionary = core.command("inspect %d %d" % [x,y])
	for resource in info.storage.resources:
		var id := int(resource.resource)
		command("storage %d %d %d %d %d %d" % [x,y,int(info.target_token),id,1 if goods.has(id) else 0,int(goods.get(id,0))])

func stores_near(point: Vector2i, goods: Dictionary) -> void:
	for building in state.buildings:
		if building.asset == "warehouse" and Vector2i(int(building.x),int(building.y)).distance_to(point) < 38:
			store(building,goods)

func gardens() -> void:
	var homes: Array = state.buildings.filter(func(b): return str(b.asset).begins_with("common_house"))
	for home in homes:
		var origin := Vector2i(int(home.x)+1,int(home.y)+1)
		var choices := []
		for dx in range(-4,6):
			for dy in range(-4,6): choices.append(Vector2i(int(home.x)+dx,int(home.y)+dy))
		choices.sort_custom(func(a,b): return a.distance_squared_to(origin)<b.distance_squared_to(origin))
		var flowers := 0
		for point in choices:
			if core.command("preview flower_garden %d %d 0" % [point.x,point.y]).get("valid",false):
				command("build flower_garden %d %d 0" % [point.x,point.y]); flowers += 1
			if flowers >= 4: break
		var parks := 0
		for point in choices:
			if core.command("preview park %d %d 0" % [point.x,point.y]).get("valid",false):
				command("build park %d %d 0" % [point.x,point.y]); parks += 1
			if parks >= 4: break
	refresh()

func setup(number: int) -> void:
	command("pause 1"); refresh()
	if number == 0:
		choose_center()
		print("SETTLEMENT_TOWN ",center)
		if not okay: return
		command("demolish_area %d %d %d %d 0" % [center.x-17,center.y-10,center.x+17,center.y+10],false)
		refresh()
		for dy in [-6,0,6]: line(center+Vector2i(-16,dy),center+Vector2i(16,dy))
		line(center+Vector2i(-16,-6),center+Vector2i(-16,6))
		line(center+Vector2i(16,-6),center+Vector2i(16,6))
		for count in 30: build("house")
		for count in 2: build("fountain"); build("maintenance_office")
		build("watchpost"); build("granary"); build("warehouse")
		stores_near(center,{8192:32})
		for count in 2: build("common_agora"); vendor("food_vendor")
		for count in 6: build("wheat_farm")
		for count in 4: build("timber_mill")
		open_trade()
	elif number == 1:
		for count in 4: build("house")
		build("hospital"); build("bibliotheke"); build("warehouse")
		stores_near(center,{4096:16,8192:16})
		for count in 2: vendor("fleece_vendor")
		order(4096,0,true,16)
		var town := center
		var first := build("foundry")
		if first.is_empty(): return
		center = Vector2i(int(first.x),int(first.y))
		industry = center
		print("BRONZE_INDUSTRY ",center)
		for count in 3: build("foundry")
		for count in 2: build("maintenance_office")
		build("warehouse")
		stores_near(center,{16384:16,65536:16})
		for count in 4: build("armory")
		connect_district(town)
		center = town
		order(65536,1,true,32)
		gardens()
	else:
		var town := center
		center = industry
		for count in 4: build("foundry")
		for count in 2: build("armory")
		for count in 2: build("maintenance_office")
		connect_district(town)
		center = town
		for count in 6: build("house")
		build("palace"); build("tax_office")
		for count in 2: build("wheat_farm")
		order(65536,1,false,32)
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
		for batch in 700:
			for step in 10: core.advance(.05); ticks += 1
			latest = core.command("episode")
			var partner: Dictionary = core.command("trade_partners").partners[0]
			for goods in partner.buys:
				if int(goods.resource) == 65536: armor_sales_observed = maxi(armor_sales_observed,int(goods.used))
			for goods in partner.sells:
				if int(goods.resource) == 4096: fleece_imports_observed = maxi(fleece_imports_observed,int(goods.used))
			if number == 2:
				if not partner.trading: saw_closed = true
				if saw_closed and partner.trading: saw_reopened = true
				for goal in latest.goals:
					if goal.kind == "set_aside" and goal.set_aside and not reserve_done:
						command("set_aside %d" % int(goal.index)); reserve_done = true
						order(65536,1,true,32)
			if batch % 20 == 0:
				refresh()
				print("BRONZE_PROGRESS ",number+1," batch=",batch," pop=",state.population," money=",state.money," date=",state.date," goals=",JSON.stringify(latest.goals))
				write_result()
			if batch % 40 == 0 and not core.snapshot(false).get("blocked",false): core.save_city("bronze-playthrough-%d" % (number+1))
			if core.command("episode").get("victory",false): completed = true; break
			if core.snapshot(false).get("blocked",false): okay = false; print("SETTLEMENT_ERROR native decision/loss blocks progress"); break
			await process_frame
		refresh()
		stages.append({"chapter":number+1,"natural_victory":completed,"time_start":begin_time,"time_end":state.time,"population":state.population,"money":state.money,"goals":core.command("episode").goals,"finances":core.command("city_data"),"trade":core.command("trade_summary")})
		if not completed: okay = false; break
		var next := command("finish_episode")
		if number < plan.chapters.size()-1: command("begin_episode")
		else: okay = okay and next.get("next") == "complete" and saw_closed and saw_reopened and reserve_done and armor_sales_observed > 0 and fleece_imports_observed > 0
	write_result(); core.close_city()
	print("FIRST_SCENARIO_BRONZE_PLAYTHROUGH ","PASS" if okay else "FAIL"," chapters=",stages.size()," ordinary_commands=",commands," ticks=",ticks)
	quit(0 if okay else 1)

func write_result() -> void:
	super.write_result()
	var file := FileAccess.open(report.path_join("trade-proof.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"closed":saw_closed,"reopened":saw_reopened,"reserve_committed":reserve_done,"largest_observed_annual_armor_sales":armor_sales_observed,"largest_observed_annual_fleece_imports":fleece_imports_observed,"post_initial_record":trade_building},"\t"))
