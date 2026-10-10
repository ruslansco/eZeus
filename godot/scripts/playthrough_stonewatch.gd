extends "res://scripts/playthrough_bronze_river.gd"
# Owned campaign playthrough: genuine construction, stocks, armies and hero summon.
# The campaign's invasion choice is explicitly Fight; no live-game decisions touched.
var stage_number := 0
var fort := Rect2i(113,-15,28,22)
var fort_building := false
var enemy_seen := false
var battle_seen := false
var battle_won := false
var monster_seen := false
var hero_summoned := false
var hero_fought := false
var hall := {}
var palace_site := {}
var logged_events := {}
var invaders_seen := false
var army_stood_down := false
var hero_imports_stopped := {}
var fort_repaired := false

func choose_center() -> void:
	center = Vector2i(125,20)

func site(tool: String, partner := -1, require_road := true) -> Dictionary:
	var candidates := []
	var forest := []
	for point in tiles:
		if int(tiles[point][3]) & 16: forest.append(point)
		if abs(point.x-center.x)>32 or abs(point.y-center.y)>25 or not tiles[point][5]: continue
		if not fort_building and fort.has_point(point): continue
		candidates.append(point)
	var scores := {}
	for point in candidates:
		var score: float = point.distance_squared_to(center)
		if tool == "timber_mill":
			var nearest := INF
			for tree in forest: nearest = minf(nearest,point.distance_squared_to(tree))
			score = nearest+score*.001
		scores[point] = score
	candidates.sort_custom(func(a,b):return scores[a]<scores[b])
	for point in candidates:
		var query: Dictionary = core.command("preview %s %d %d 0 %d" % [tool,point.x,point.y,partner])
		if query.get("valid",false) and (not require_road or adjacent_road(query)):
			if Rect2i(int(query.x),int(query.y),int(query.w),int(query.h)).intersects(Rect2i(121,-7,4,4)): continue
			query.pointer = [point.x,point.y]; return query
	return {}

func at(tool: String, point: Vector2i, turn := 0) -> Dictionary:
	var query: Dictionary = core.command("preview %s %d %d %d" % [tool,point.x,point.y,turn])
	if not query.get("valid",false):
		okay = false;print("STONEWATCH_ERROR ",tool," site ",point," ",JSON.stringify(query));return {}
	command("build %s %d %d %d" % [tool,point.x,point.y,turn]);refresh();return query

func open_trade() -> void:
	var partner: Dictionary = core.command("trade_partners").partners[0]
	if not partner.water: super.open_trade(); return
	var choices: Array = tiles.keys()
	choices.sort_custom(func(a,b):return a.distance_squared_to(center)<b.distance_squared_to(center))
	var selected := {}
	var pointer := Vector2i()
	for point in choices:
		var query: Dictionary = core.command("preview pier %d %d 0 %d" % [point.x,point.y,int(partner.index)])
		if query.get("valid",false): selected=query;pointer=point;break
	if selected.is_empty(): okay=false;print("STONEWATCH_ERROR no native sea-trade site");return
	var post_x:=int(selected.tiles[4][0]);var post_y:=int(selected.tiles[4][1])
	command("demolish_area %d %d %d %d 0" % [post_x-1,post_y-1,post_x+4,post_y+4],false);refresh()
	command("build pier %d %d 0 %d" % [pointer.x,pointer.y,int(partner.index)]);refresh()
	for building in state.buildings:
		if building.asset=="trade_post": trade_building=building
	if trade_building.is_empty():okay=false;print("STONEWATCH_ERROR pier has no trade post");return
	line(Vector2i(post_x-1,post_y-1),Vector2i(post_x+4,post_y-1))
	var town:=center;center=Vector2i(post_x,post_y)
	connect_district(town);build("maintenance_office");center=town
	order(8192,1,true,32)

func prepare_fort() -> void:
	command("demolish_area 113 -15 140 6 0",false);refresh()
	line(Vector2i(125,-12),Vector2i(125,14))
	line(Vector2i(116,-3),Vector2i(138,-3))
	# South gate occupies five cells; leave its opening before placing walls.
	for edge in [[113,-15,140,-15],[113,-15,113,6],[140,-15,140,6],[113,6,122,6],[128,6,140,6]]:
		command("build_wall %d %d %d %d 0" % edge)
	at("gatehouse",Vector2i(123,5))
	var palace := at("palace",Vector2i(132,-7))
	palace_site = palace
	if not palace.is_empty():
		var x:=int(palace.x);var y:=int(palace.y);var w:=int(palace.w);var h:=int(palace.h)
		line(Vector2i(x-1,y-1),Vector2i(x+w,y-1));line(Vector2i(x-1,y+h),Vector2i(x+w,y+h))
		line(Vector2i(x-1,y-1),Vector2i(x-1,y+h));line(Vector2i(x+w,y-1),Vector2i(x+w,y+h))
		at("roadblock",Vector2i(125,3))
	var town := center;center=Vector2i(125,-4);fort_building=true
	for count in 3:build("maintenance_office")
	build("tax_office");fort_building=false;center=town
	print("STONEWATCH_FORT_SETUP ",JSON.stringify(core.command("inspect 132 -7"))," army=",JSON.stringify(core.command("army")))
	# Staffed front towers/roads cover the eastern approach to the town.
	command("demolish_area 143 9 149 21 0",false);refresh()
	line(Vector2i(144,9),Vector2i(144,22));line(Vector2i(141,14),Vector2i(147,14))
	at("tower",Vector2i(145,11));at("tower",Vector2i(145,16))
	var old := center;center=Vector2i(143,17);build("maintenance_office");center=old

func setup(number: int) -> void:
	stage_number = number
	command("pause 1");refresh()
	if number == 0:
		choose_center()
		command("demolish_area 108 10 142 30 0",false);refresh()
		for dy in [-6,0,6]:line(center+Vector2i(-16,dy),center+Vector2i(16,dy))
		line(center+Vector2i(-16,-6),center+Vector2i(-16,6));line(center+Vector2i(16,-6),center+Vector2i(16,6))
		for count in 30:build("house")
		for count in 3:build("fountain");build("maintenance_office")
		build("watchpost");build("granary");build("warehouse");build("warehouse")
		stores_near(center,{8192:16,64:16})
		for count in 2:build("common_agora");vendor("food_vendor")
		for count in 6:build("timber_mill")
		open_trade();order(64,0,true,24)
	elif number == 1:
		for count in 8:build("house")
		build("hospital")
		for count in 3:build("bibliotheke")
		for count in 2:vendor("fleece_vendor")
		order(4096,0,true,16)
		build("warehouse");stores_near(center,{8192:12,4096:12,64:8})
		gardens();prepare_fort()
	else:
		for edge in [[113,-15,140,-15],[113,-15,113,6],[140,-15,140,6],[113,6,122,6],[128,6,140,6]]:
			command("build_wall %d %d %d %d 0" % edge,false)
		order(32768,0,true,48);order(1024,0,true,16)
		var town:=center
		center=Vector2i(int(trade_building.x),int(trade_building.y))
		for point in tiles:
			if point.distance_squared_to(center)<144 and int(tiles[point][3])&16:
				command("demolish %d %d 0 0" % [point.x,point.y],false)
		refresh()
		for count in 3:build("warehouse")
		var warehouses: Array=state.buildings.filter(func(b):return b.asset=="warehouse" and Vector2i(int(b.x),int(b.y)).distance_to(center)<38)
		store(warehouses[-1],{32768:32});store(warehouses[-2],{32768:32});store(warehouses[-3],{1024:32})
		for warehouse in [warehouses[-1],warehouses[-2],warehouses[-3]]:
			var x:=int(warehouse.x);var y:=int(warehouse.y);var w:=int(warehouse.w);var h:=int(warehouse.h)
			line(Vector2i(x-1,y-1),Vector2i(x+w,y-1));line(Vector2i(x-1,y+h),Vector2i(x+w,y+h))
			line(Vector2i(x-1,y-1),Vector2i(x-1,y+h));line(Vector2i(x+w,y-1),Vector2i(x+w,y+h))
			var pier_center:=center;center=Vector2i(x,y);connect_district(pier_center);center=pier_center
		build("maintenance_office");center=town
	command("speed 3");command("pause 0")

func manage_hero_supplies() -> void:
	if stage_number!=2 or hero_summoned or core.snapshot(false).blocked:return
	for good in core.snapshot(false).city_header.stock:
		var resource:=int(good.resource)
		var target:=32 if resource==32768 else 16 if resource==1024 else 0
		if target>0 and int(good.count)>=target and not hero_imports_stopped.has(resource):
			order(resource,0,false,target);hero_imports_stopped[resource]=true
		elif target>0 and int(good.count)<target and hero_imports_stopped.has(resource):
			order(resource,0,true,48 if resource==32768 else 16);hero_imports_stopped.erase(resource)

func repair_fort() -> void:
	# Battle damage may leave ruins that ordinary wall placement cannot cover.
	for edge in [[113,-15,140,-15],[113,-15,113,6],[140,-15,140,6],[113,6,122,6],[128,6,140,6]]:
		for x in range(int(edge[0]),int(edge[2])+1):
			for y in range(int(edge[1]),int(edge[3])+1):
				if core.command("inspect %d %d" % [x,y]).has("ruin"):
					command("demolish %d %d 0 0" % [x,y],false)
		command("build_wall %d %d %d %d 0" % edge,false)
	fort_repaired=true

func army_orders() -> void:
	if stage_number != 1 or battle_won or core.snapshot(false).blocked: return
	var army: Dictionary = core.command("army")
	if int(army.get("rabble",0)) < 8: return
	for banner in army.banners:
		if banner.type != "rock_thrower" or int(banner.count) <= 0: continue
		if banner.home:
			var moved := command("banner_move %d 146 15" % int(banner.id),false)
			if moved.get("error","")=="pending_decision":return
			var called := command("banner_call %d" % int(banner.id),false)
			if called.get("error","")=="pending_decision":return

func summon() -> void:
	if stage_number != 2 or core.snapshot(false).blocked: return
	var available: Dictionary = {}
	for row in core.command("buildable").buildings: available[row.name]=row.available
	if hall.is_empty() and available.get("hero_hall_theseus",false):
		command("pause 1")
		hall=at("hero_hall_theseus",Vector2i(121,-7))
		line(Vector2i(121,-3),Vector2i(125,-3))
		var choices:=[]
		var origin:=Vector2i(123,-5)
		for x in range(114,140):
			for y in range(-14,5):choices.append(Vector2i(x,y))
		choices.sort_custom(func(a,b):return a.distance_squared_to(origin)<b.distance_squared_to(origin))
		var flowers:=0
		for point in choices:
			if core.command("preview flower_garden %d %d 0" % [point.x,point.y]).get("valid",false):
				command("build flower_garden %d %d 0" % [point.x,point.y]);flowers+=1
			if flowers>=80:break
		refresh();command("pause 0")
	if hall.is_empty() or hero_summoned: return
	var info: Dictionary = core.command("inspect %d %d" % [int(hall.x),int(hall.y)])
	if not fort_repaired and info.get("hall",{}).get("requirements",[]).any(func(r):return str(r.text).contains("Walls") and not r.met):
		repair_fort()
		info=core.command("inspect %d %d" % [int(hall.x),int(hall.y)])
	if info.get("hall",{}).get("can_summon",false):
		command("hero_summon %d %d %d" % [int(hall.x),int(hall.y),int(info.target_token)])
		hero_summoned=true

func observe() -> void:
	var observed: Dictionary=core.snapshot(true)
	for walker in observed.walkers:
		if walker.asset == "walker_minotaur": monster_seen=true
		if walker.asset == "walker_theseus" and int(walker.get("action",0)) in [4,5]:hero_fought=true
	for event in observed.get("events",[]):
		var kind:=str(event.get("kind",""))
		var fight_choice: bool = event.get("actions",[]).any(func(a):return int(a.choice)==2)
		if not logged_events.has(int(event.id)) and (kind.to_lower().contains("invasion") or fight_choice):
			print("STONEWATCH_EVENT ",JSON.stringify(event));logged_events[int(event.id)]=true
		if int(event.get("sender_index",-1))==int(plan.rival_index) and fight_choice:
			enemy_seen=true
			command("event %d 2" % int(event.id));battle_seen=true
		elif kind in ["invasionVictory","invasionVictoryMonn"]:battle_won=true
	var army: Dictionary=core.command("army")
	invaders_seen=invaders_seen or int(army.invaders)>0
	if battle_won and not army_stood_down and not core.snapshot(false).blocked:
		command("army_home");army_stood_down=true
	army_orders();manage_hero_supplies();summon()

func run() -> void:
	engine=OS.get_environment("EZEUS_SCENARIO_ENGINE");report=OS.get_environment("EZEUS_SCENARIO_REPORT")
	plan=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("EZEUS_SCENARIO_PLAN")))
	core=ClassDB.instantiate("EZeusSimulation");core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"));core.set_adventures_directory(engine.path_join("Adventures"))
	var initial: Dictionary=core.open_adventure(engine,"folder",plan.development_name,"en")
	if initial.has("error"):push_error(str(initial));quit(1);return
	for number in plan.chapters.size():
		setup(number)
		if not okay:break
		var start: float=float(core.snapshot(false).time)
		var completed:=false
		for batch in 600:
			for step in 10:core.advance(.05);ticks+=1
			observe();latest=core.command("episode")
			if not okay: break
			if batch%20==0:
				refresh();print("STONEWATCH_PROGRESS ",number+1," batch=",batch," pop=",state.population," cash=",state.money," goals=",JSON.stringify(latest.goals));write_result()
				if number==1:print("STONEWATCH_PALACE ",JSON.stringify(core.command("inspect 132 -7")))
				if number==2 and not hall.is_empty():print("STONEWATCH_HALL ",JSON.stringify(core.command("inspect 121 -7")))
			if batch%40==0 and not core.snapshot(false).blocked:core.save_city("stonewatch-chapter-%d" % (number+1))
			if latest.victory:completed=true;break
			if core.snapshot(false).blocked:
				# An order may settle a newly completed native event task after observe.
				observe();latest=core.command("episode")
				if latest.victory:completed=true;break
				if core.snapshot(false).blocked:okay=false;print("STONEWATCH_ERROR unexpected native decision or defeat ",JSON.stringify(core.snapshot(false).events));break
			await process_frame
		refresh();stages.append({"chapter":number+1,"natural_victory":completed,"time_start":start,"time_end":state.time,"population":state.population,"money":state.money,"goals":latest.goals,"army":core.command("army"),"finances":core.command("city_data")})
		if not completed:okay=false;break
		var next:=command("finish_episode")
		if number<2:command("begin_episode")
		else:okay=okay and next.get("next")=="complete" and hero_summoned and monster_seen and battle_won and invaders_seen
	write_result();core.close_city()
	print("FIRST_SCENARIO_STONEWATCH_PLAYTHROUGH ","PASS" if okay else "FAIL"," chapters=",stages.size()," commands=",commands," ticks=",ticks)
	quit(0 if okay else 1)

func write_result() -> void:
	super.write_result()
	var file:=FileAccess.open(report.path_join("defense-proof.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"invasion_seen":enemy_seen,"fight_chosen":battle_seen,"invaders_seen":invaders_seen,"battle_won":battle_won,"monster_seen":monster_seen,"hero_summoned":hero_summoned,"hero_fought":hero_fought},"\t"))
