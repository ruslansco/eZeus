extends SceneTree
# Ordinary player commands and native ticks only. No test_win/stock/money/allow.
var core: RefCounted
var engine := ""
var report := ""
var plan := {}
var state := {}
var tiles := {}
var center := Vector2i()
var okay := true
var commands := 0
var ticks := 0
var stages := []
var latest := {}

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func refresh() -> void:
	state = core.snapshot(true)
	tiles.clear()
	for t in state.tiles: tiles[Vector2i(int(t[0]), int(t[1]))] = t

func command(text: String, required := true) -> Dictionary:
	assert(not text.begins_with("test_"))
	commands += 1
	var result: Dictionary = core.command(text)
	if result.has("error") and required:
		okay = false
		print("SETTLEMENT_ERROR ", text, " ", result.error)
	return result

func road_at(point: Vector2i) -> void:
	if not tiles.has(point): return
	var row: Array = tiles[point]
	if int(row[4]): return
	if int(row[3]) & 16:
		command("demolish %d %d 0 0" % [point.x, point.y], false)
	command("build road %d %d 0" % [point.x, point.y], false)

func line(a: Vector2i, b: Vector2i) -> void:
	for x in range(mini(a.x,b.x), maxi(a.x,b.x)+1): road_at(Vector2i(x,a.y))
	for y in range(mini(a.y,b.y), maxi(a.y,b.y)+1): road_at(Vector2i(b.x,y))
	refresh()

func road_distance(point: Vector2i) -> int:
	var distance := 9999
	for p in tiles:
		if int(tiles[p][4]): distance = mini(distance, absi(point.x-p.x)+absi(point.y-p.y))
	return distance

func adjacent_road(preview: Dictionary) -> bool:
	var x: int = int(preview.x); var y: int = int(preview.y)
	var w: int = int(preview.w); var h: int = int(preview.h)
	for dx in range(-1,w+1):
		for dy in [-1,h]:
			var p := Vector2i(x+dx,y+dy)
			if tiles.has(p) and int(tiles[p][4]): return true
	for dy in range(h):
		for dx in [-1,w]:
			var p := Vector2i(x+dx,y+dy)
			if tiles.has(p) and int(tiles[p][4]): return true
	return false

func site(tool: String, partner := -1, require_road := true) -> Dictionary:
	var candidates := []
	for p in tiles:
		if abs(p.x-center.x)>38 or abs(p.y-center.y)>30: continue
		if not bool(tiles[p][5]): continue
		candidates.append(p)
	if tool=="timber_mill":
		var forests:=[]
		for p in tiles:
			if int(tiles[p][3])&16:forests.append(p)
		var distances: Dictionary={}
		for p in candidates:
			var nearest:=99999.0
			for forest in forests:nearest=minf(nearest,p.distance_squared_to(forest))
			distances[p]=nearest
		candidates.sort_custom(func(a,b):return distances[a]<distances[b])
	else:candidates.sort_custom(func(a,b): return a.distance_squared_to(center)<b.distance_squared_to(center))
	for p in candidates:
		var query: Dictionary = core.command("preview %s %d %d 0 %d" % [tool,p.x,p.y,partner])
		if query.get("valid",false) and (not require_road or adjacent_road(query)):
			query.pointer=[p.x,p.y]
			return query
	return {}

func add_road_access(preview: Dictionary) -> void:
	if adjacent_road(preview): return
	var corner := Vector2i(int(preview.x)-1,int(preview.y)-1)
	var nearest := center
	var distance := 999999
	for p in tiles:
		if int(tiles[p][4]) and p.distance_squared_to(corner)<distance:
			distance=p.distance_squared_to(corner);nearest=p
	line(corner,nearest)

func build(tool: String, partner := -1) -> Dictionary:
	var place := site(tool,partner)
	if place.is_empty(): place=site(tool,partner,false)
	if place.is_empty():
		okay=false;print("SETTLEMENT_ERROR no site for ",tool)
		return {}
	add_road_access(place)
	var answer := command("build %s %d %d 0 %d" % [tool,int(place.pointer[0]),int(place.pointer[1]),partner])
	refresh()
	return place if not answer.has("error") else {}

func vendor(tool: String) -> void:
	for b in state.buildings:
		if b.asset != "agora_space": continue
		var result: Dictionary = core.command("preview %s %d %d 0" % [tool,int(b.x)+1,int(b.y)+1])
		if result.get("valid",false):
			command("build %s %d %d 0" % [tool,int(b.x)+1,int(b.y)+1])
			refresh();return
	okay=false;print("SETTLEMENT_ERROR no agora slot for ",tool)

func choose_center() -> void:
	var best := -INF
	for p in tiles:
		if posmod(p.x,5)!=0 or posmod(p.y,5)!=0: continue
		var valid := true;var meadow := 0
		for dx in range(-17,18):
			for dy in range(-10,11):
				var t: Array=tiles.get(p+Vector2i(dx,dy),[])
				if t.is_empty() or int(t[2])!=0 or int(t[3])&~(1|8|16|32) or int(t[6])&8:
					valid=false;break
				if int(t[3])&8:meadow+=1
			if not valid:break
		if not valid or meadow<30: continue
		var score: float=meadow-.3*p.distance_to(Vector2i(127,-34))
		if score>best: best=score;center=p
	if best == -INF: okay=false;print("SETTLEMENT_ERROR no town rectangle")

func setup(number: int) -> void:
	command("pause 1")
	refresh()
	if number==0:
		choose_center()
		print("SETTLEMENT_TOWN ",center)
		if not okay:return
		command("demolish_area %d %d %d %d 0" % [center.x-17,center.y-10,center.x+17,center.y+10],false)
		refresh()
		for dy in [-6,0,6]: line(center+Vector2i(-16,dy),center+Vector2i(16,dy))
		line(center+Vector2i(-16,-6),center+Vector2i(-16,6))
		line(center+Vector2i(16,-6),center+Vector2i(16,6))
		for i in 26: build("house")
		for i in 2:build("fountain");build("maintenance_office")
		build("watchpost")
		build("granary")
		build("common_agora");vendor("food_vendor")
		for i in 4:build("wheat_farm")
	elif number==1:
		for i in 4:build("house")
		build("common_agora");vendor("food_vendor")
		build("warehouse")
		build("hospital")
		build("bibliotheke")
		for i in 4:build("carding_shed")
		for i in 16:build("sheep")
		vendor("fleece_vendor")
		# Put small appeal buildings around the homes rather than clustering all
		# gardens beside warehouses/workshops in the town center.
		var homes: Array=state.buildings.filter(func(b):return str(b.asset).begins_with("common_house"))
		for home in homes:
			var flowers:=0
			var choices:=[]
			var origin:=Vector2i(int(home.x)+1,int(home.y)+1)
			for dx in range(-4,6):
				for dy in range(-4,6):choices.append(Vector2i(int(home.x)+dx,int(home.y)+dy))
			choices.sort_custom(func(a,b):return a.distance_squared_to(origin)<b.distance_squared_to(origin))
			for p in choices:
				var query: Dictionary=core.command("preview flower_garden %d %d 0"%[p.x,p.y])
				if query.get("valid",false):
					command("build flower_garden %d %d 0"%[p.x,p.y]);flowers+=1
				if flowers>=4:break
			var planted:=0
			for dx in range(-2,5):
				for dy in [-2,4]:
					var x: int=int(home.x)+dx;var y: int=int(home.y)+dy
					if core.command("preview park %d %d 0"%[x,y]).get("valid",false):
						command("build park %d %d 0"%[x,y]);planted+=1
					if planted>=4:break
				if planted>=4:break
		refresh()
	else:
		build("palace")
		build("tax_office")
		for i in 4:build("timber_mill")
		for i in 2:build("wheat_farm")
		var partners: Array=core.command("trade_partners").partners
		var partner: Dictionary=partners[0]
		var at:=build("pier" if partner.water else "trade_post",int(partner.index))
		if at.is_empty():return
		var post: Dictionary={}
		for b in state.buildings:
			if b.asset=="trade_post":post=b
		var info: Dictionary=core.command("inspect %d %d" % [int(post.x),int(post.y)])
		command("trade %d %d %d 8192 1 1 32" % [int(post.x),int(post.y),int(info.target_token)])
	command("speed 3");command("pause 0")

func run() -> void:
	engine=OS.get_environment("EZEUS_SCENARIO_ENGINE");report=OS.get_environment("EZEUS_SCENARIO_REPORT")
	plan=JSON.parse_string(FileAccess.get_file_as_string("res://../content/scenarios/first_light_harbor_chapters.json"))
	core=ClassDB.instantiate("EZeusSimulation");core.set_save_directory(OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"));core.set_adventures_directory(engine.path_join("Adventures"))
	var opened: Dictionary=core.open_adventure(engine,"folder",plan.development_name,"en")
	if opened.has("error"):push_error(str(opened));quit(1);return
	for number in 3:
		setup(number)
		if not okay:break
		var begin_time: float=float(core.snapshot(false).time)
		var completed:=false
		for batch in 400:
			for i in 10:core.advance(.05);ticks+=1
			if batch%20==0:
				latest=core.command("episode")
				var now: Dictionary=core.snapshot(false)
				print("SETTLEMENT_PROGRESS ",number+1," batch=",batch," pop=",now.population," money=",now.money," date=",now.date," goals=",JSON.stringify(latest.goals))
				write_result()
			if batch%40==0 and not core.snapshot(false).get("blocked",false):core.save_city("playthrough-chapter-%d" % (number+1))
			if core.command("episode").get("victory",false):completed=true;break
			if core.snapshot(false).get("blocked",false):okay=false;print("SETTLEMENT_ERROR native decision/loss blocks progress");break
			await process_frame
		refresh()
		stages.append({"chapter":number+1,"natural_victory":completed,"time_start":begin_time,"time_end":state.time,"population":state.population,"money":state.money,"goals":core.command("episode").goals,"finances":core.command("city_data")})
		if not completed:okay=false;break
		var next:=command("finish_episode")
		if number<2:command("begin_episode")
		else:okay=okay and next.get("next")=="complete"
	write_result();core.close_city()
	print("SETTLEMENT_PLAYTHROUGH ","PASS" if okay else "FAIL"," chapters=",stages.size()," ordinary_commands=",commands," ticks=",ticks)
	quit(0 if okay else 1)

func write_result() -> void:
	var f:=FileAccess.open(report.path_join("result.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"okay":okay,"chapters":stages,"latest":latest,"commands":commands,"ticks":ticks,"test_commands_used":false,"center":[center.x,center.y]},"\t"))
	if not state.is_empty():
		var world:=FileAccess.open(report.path_join("settlement-snapshot.json"),FileAccess.WRITE)
		world.store_string(JSON.stringify(state))
