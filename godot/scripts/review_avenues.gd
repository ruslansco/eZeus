extends SceneTree
const Layout = preload("res://scripts/street_layout.gd")
const Walkers = preload("res://scripts/walker_streets.gd")
var city: Node3D
var okay := true
var checks := 0
var actors: Array = []
var sites: Array[Vector2i] = []

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("AVENUE_CHECK ","PASS " if value else "FAIL ",label)

func frames(count := 10) -> void:
	for i in count: await process_frame

func capture(label: String, target: Vector3, distance: float, yaw := 25.0) -> void:
	city.orbit.target=target; city.orbit.distance=distance; city.orbit.pitch=45; city.orbit.yaw=yaw; city.orbit.refresh()
	await frames(14); RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/avenues-%s.png"%label)

func run() -> void:
	city=load("res://main.tscn").instantiate(); root.add_child(city)
	while city.state.is_empty() or city.frame_count < 70: await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.set_process(false)
	city.orbit.enabled=false; city.ui_layer.visible=false
	DisplayServer.window_move_to_foreground()
	var original: Dictionary=city.core.simulation.snapshot(true)
	var free := {}
	for tile in original.tiles:
		if int(tile[5]) and not int(tile[4]) and not (int(tile[3]) & (4|16|2048|32768)): free[Vector2i(tile[0],tile[1])] = tile
	var base := Vector2i(-1,-1)
	for cell in free:
		var clear := true
		for x in range(-9,10):
			for y in range(-4,7):
				var other: Array=free.get(cell+Vector2i(x,y),[])
				if other.is_empty() or int(other[2])!=int(free[cell][2]): clear=false; break
			if not clear: break
		if clear: base=cell; break
	check(base.x>=0,"a clear level native two/three-cell street gallery exists")
	if base.x<0: city.queue_free(); quit(1); return
	for spec in [["avenue",-2,2],["boulevard",3,3]]:
		var a:=base+Vector2i(-8,spec[1]); var b:=base+Vector2i(8,spec[1]); sites.append(a)
		var command: String="%s %d %d %d %d"%[spec[0],a.x,a.y,b.x,b.y]
		var plan: Dictionary=city.core.query("preview_path "+command)
		check(plan.get("complete",false) and plan.get("tiles",[]).all(func(t):return bool(t[3])),spec[0]+": the native drag plan accepts a clear strip")
		var before: Dictionary=city.core.simulation.snapshot(true)
		var built: Dictionary=city.core.query("build_path "+command)
		var after: Dictionary=city.core.simulation.snapshot(true)
		check(not built.has("error") and int(after.money)==int(before.money)-int(plan.get("cost",0)),spec[0]+": construction uses the exact native quote")
		var changed: Array=after.tiles.filter(func(t):return int(t[0])>=a.x and int(t[0])<=b.x and abs(int(t[1])-a.y)<=1 and int(t[4]))
		check(changed.size()==17*int(spec[2]),spec[0]+": native construction keeps its two/three-cell width")
		check(changed.filter(func(t):return int(t[8])==int(spec[2])).size()==17,spec[0]+": each median is exposed as a walkable native road")
		var undone: Dictionary=city.core.query("undo")
		check(not undone.has("error") and int(undone.get("money",0))==int(before.money),spec[0]+": its native drag undo refunds the quoted cost")
		city.core.simulation.replay(4)
		var cleared: Dictionary=city.core.simulation.snapshot(true)
		check(cleared.tiles.filter(func(t):return int(t[4])).size()==before.tiles.filter(func(t):return int(t[4])).size(),spec[0]+": native undo removes the whole strip, including its flank tiles")
		city.core.query("build_path "+command)
		after=city.core.simulation.snapshot(true)
		city.receive_state(after)
	var snapshot: Dictionary=city.core.simulation.snapshot(true)
	var live_walkers: Array=city.state.walkers
	# Render fixtures use actual citizens through the ordinary update/pose path.
	# They do not exist in, or write to, the native simulation.
	var fixtures: Array=[]
	for index in sites.size():
		for row in range(-1,2):
			var native_y: int=sites[index].y+row
			if not Layout.kind(city.tiles,Vector2i(base.x,native_y)): continue
			fixtures.append({"id":-8100-index*10-row,"asset":"philosopher","role":"philosopher","type":-1,"x":base.x-5+row*2+.5,"y":native_y+.5,"altitude":free[base][2],"lift":0,"action":1,"orientation":2})
	city.state.walkers=fixtures; city.update_walkers(); city._process(.1)
	for person in fixtures: actors.append(city.walkers[int(person.id)].node)
	check(fixtures.size()==5 and fixtures.all(func(p):return city.walkers[int(p.id)].get("human",false)),"every native lane is reviewed with a real citizen model")
	await capture("two-and-three-tile-streets",city.world_position(base.x,base.y,int(free[base][2])),24)
	await capture("avenue",city.world_position(base.x-2,sites[0].y+.5,int(free[base][2]))+Vector3.UP*.3,10,0)
	await capture("boulevard",city.world_position(base.x+1,sites[1].y,int(free[base][2]))+Vector3.UP*.3,11,0)
	# Repeated forward/cross-lane native observations catch lateral visual drift
	# while preserving the native track and normal citizen gait/heading pipeline.
	var positions_kept:=true; var paved:=true
	for step in 100:
		for person in fixtures: person.x=float(base.x-6)+float(step)*.12+.5
		city.update_walkers(); city._process(.1)
		for person in fixtures:
			var entry: Dictionary=city.walkers[int(person.id)]
			positions_kept=positions_kept and entry.native_position.is_equal_approx(city.walker_world_position(person))
			paved=paved and Layout.kind(city.tiles,Walkers.cell_at(city,entry.node.position))>0
		await process_frame
	check(positions_kept and paved,"100 moving citizen samples per lane stay on the paved road and retain native positions")
	await capture("moving-citizens",city.world_position(base.x+5,sites[1].y,int(free[base][2]))+Vector3.UP*.3,8,-25)
	city.ui_layer.visible=true
	for tool in ["avenue","boulevard"]:
		city.set_tool(tool); city.hud.close_build_tray(); city.hud.open_category("Gardens and monuments")
		for i in 160:
			if city.hud.thumbnails.cache.get(tool) != null: break
			await process_frame
		check(city.hud.thumbnails.cache.get(tool) != null and city.hud.get_node("%ContextFacts").text==city.tr("Street width: %d tiles")%[2 if tool=="avenue" else 3],tool+": catalog shows its own rendered street and correct full width")
		await capture("catalog-"+tool,city.world_position(base.x,base.y,int(free[base][2])),25)
	city.ui_layer.visible=false
	var after: Dictionary=city.core.simulation.snapshot(true)
	snapshot.erase("sequence"); after.erase("sequence")
	check(snapshot==after,"sculpture, foliage, capture and moving citizen fixtures change no native game-state field")
	city.state.walkers=live_walkers
	for node in actors:
		if is_instance_valid(node): node.queue_free()
	city.walkers.clear(); city.queue_free(); await frames(2)
	print("AVENUE_REVIEW ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
