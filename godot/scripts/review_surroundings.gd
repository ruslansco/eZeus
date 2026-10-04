extends SceneTree
var okay := true
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	checks+=1;okay=okay and value
	print("SURROUNDINGS_CHECK ","PASS " if value else "FAIL ",description)
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/surroundings-"+name+".png")
func count_physics(node: Node) -> int:
	var count := 1 if node is CollisionObject3D else 0
	for child in node.get_children(): count+=count_physics(child)
	return count
func run() -> void:
	var city: Node3D=load("res://main.tscn").instantiate()
	root.add_child(city)
	city.set_process_unhandled_input(false)
	root.gui_disable_input=true
	while city.state.is_empty() or city.frame_count<80: await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.orbit.enabled=false
	city.set_tool("select");city.close_inspection();city.hud.set_goals_expanded(false)
	var native: Dictionary=city.core.simulation.snapshot(true)
	var scenery: Node3D=city.horizon.surroundings
	check(city.tiles.size()==25992,"the designated native map retains all 25,992 cells")
	check(city.horizon.ready_for_review and scenery.vertex_count>0,"cosmetic countryside and ocean are generated")
	check(count_physics(city.horizon)==0,"scenery has no collision, navigation or placement surfaces")
	check(scenery.leaves.all(func(leaf): return scenery._count(leaf.x,leaf.y,leaf.size)==0),"every scenery quad lies outside native tile footprints")
	check(scenery.vertex_count<350000,"adaptive scenery stays under 350,000 submitted vertices (%d)"%scenery.vertex_count)
	check(scenery.land.mesh.surface_get_array_index_len(0)==scenery.vertex_count and scenery.land.mesh.surface_get_array_len(0)<scenery.vertex_count/2,"indexed terrain reuses shared vertices instead of storing every triangle corner")
	var border=city.horizon.border
	var inside: bool=border.outline.size()>=4
	for point in border.outline:
		inside=inside and city.tiles.has(Vector2i(roundi(point.x),roundi(point.y)))
	check(inside,"the dashed map border's corners lie on native tiles, just inside the edge (%s)"%str(border.outline))
	check(border.published==border.outline.size() and border.published>=3,"the outside tint uses the same straight border loop as the dashes")
	check(border.mesh!=null and border.perimeter>2*maxi(city.extent.x,city.extent.y),"the dashed map border runs around the whole board (%.0f tiles, %d segments)"%[border.perimeter,border.segments])
	check(scenery.tree_count<=800 and scenery.trees.get_child_count()<100,"woodland fringe stays within instance and spatial-batch caps (%d/%d)"%[scenery.tree_count,scenery.trees.get_child_count()])
	var mismatch := 0.0
	var rim_checked := 0
	for cell in scenery.boundary:
		if int(city.tiles[cell][3])&4: continue
		for offset in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.ONE,Vector2i.DOWN]:
			var point:=Vector2(cell+offset)
			if not scenery.vertices.has(point): continue
			var expected := -INF
			for y in range(-1,1):
				for x in range(-1,1):
					var neighbor:=Vector2i(point)+Vector2i(x,y)
					if city.tiles.has(neighbor) and not int(city.tiles[neighbor][3])&4:
						expected=maxf(expected,city.terrain_geometry.interpolate(city.terrain_geometry.profile(neighbor),float(-x),float(-y)))
			mismatch=maxf(mismatch,absf(scenery.vertices[point][0].y-expected));rim_checked+=1
	check(rim_checked>100 and mismatch<.00001,"submitted rim vertices match native land profiles (%d corners)"%rim_checked)
	var maximum: float=city.orbit.maximum_distance
	check(absf(maximum-maxf(60,maxf(city.extent.x,city.extent.y)*1.05))<.001,"maximum zoom is map-scaled (%.1f units)"%maximum)
	var screen:=root.get_visible_rect().size*.5
	# This scenery reviewer isolates the city cap; the full zoom/atlas transition
	# is exercised with actual enabled-camera input in review_world_flight.gd.
	city.orbit.world_zoom_requested.disconnect(city.open_world)
	for frame in 30:city.orbit.zoom_at(screen,1.1)
	check(city.orbit.distance<=maximum+.001,"repeated mouse-wheel zoom cannot exceed the limit")
	var pinch:=InputEventMagnifyGesture.new();pinch.position=screen;pinch.factor=.5
	city.orbit.enabled=true
	for frame in 8:city.orbit._unhandled_input(pinch)
	city.orbit.enabled=false
	check(city.orbit.distance<=maximum+.001,"trackpad pinch uses the same maximum")
	var home:=InputEventKey.new();home.physical_keycode=KEY_HOME;home.pressed=true
	city._unhandled_input(home)
	check(city.orbit.distance<maximum and city.orbit.target.x==0 and city.orbit.target.z==0,"Home retains a usable full-city overview")
	city.orbit.world_zoom_requested.connect(city.open_world)
	var ramp:=false;var hills:=false
	for leaf in scenery.leaves:
		var p:=Vector2(leaf.x+leaf.size*.5,leaf.y+leaf.size*.5)
		if scenery.height(p)>scenery.sea_level+8:hills=true
		if scenery.sample(p).a<30 and scenery.height(p)>scenery.sea_level+.5:ramp=true
	check(hills and ramp,"native land leads through foothills to distant mountains")
	print("SURROUNDINGS_BUDGET vertices=",scenery.vertex_count," leaves=",scenery.leaves.size()," trees=",scenery.tree_count," cpu_ms=",scenery.build_usec/1000.0)
	# Matched panoramic views reveal any straight map cuts; close borders show terrain joins.
	DisplayServer.window_set_size(Vector2i(1440,900))
	city.orbit.target=Vector3.ZERO;city.orbit.distance=maximum;city.orbit.pitch=65
	for yaw in [0,45,135,225,315]:
		city.orbit.yaw=yaw;city.orbit.refresh();await capture("overview-%d"%yaw)
	city.orbit.pitch=28;city.orbit.yaw=45;city.orbit.refresh();await capture("low-angle")
	var land_cell: Vector2i=scenery.boundary[0]
	for cell in scenery.boundary:
		if not int(city.tiles[cell][3])&4 and int(city.tiles[cell][3])&16:land_cell=cell;break
	city.orbit.target=city.world_position(land_cell.x,land_cell.y,city.tiles[land_cell][2])
	city.orbit.distance=45;city.orbit.pitch=48;city.orbit.yaw=45;city.orbit.refresh();await capture("land-edge")
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(native.time==after.time and native.money==after.money and native.tiles==after.tiles and native.buildings==after.buildings and native.walkers==after.walkers,"landscape generation, orbit and zoom preserve native state")
	# A tiny presentation-only inland fixture derived from a real land tile. It never enters C++.
	var inland_tiles := {}
	for y in 5:
		for x in 5:
			var tile: Array=city.tiles[land_cell].duplicate()
			tile[0]=x;tile[1]=y;tile[2]=2;tile[3]=16;tile[4]=0
			if tile.size()>6:tile[6]=0
			inland_tiles[Vector2i(x,y)]=tile
	var inland_geometry:=preload("res://scripts/terrain_geometry.gd").new()
	inland_geometry.update(inland_tiles,Vector2i.ZERO,Vector2i(5,5),[])
	var inland:=preload("res://scripts/horizon.gd").new()
	city.add_child(inland);inland.visible=false
	inland.update(inland_tiles,Vector2i.ZERO,Vector2i(5,5),inland_geometry,city.terrain_style,city.forest_batches)
	check(not inland.ocean.visible and inland.far_ground.visible and not inland.surroundings.has_ocean,"inland fixture extends into countryside without an invented ocean")
	check(inland.surroundings.height(Vector2(-1,2))>=.44-.001 and count_physics(inland)==0,"inland rim retains elevation and stays cosmetic")
	inland.queue_free()
	var report:={"language":city.language,"checks":checks,"passed":okay,"native_tiles":city.tiles.size(),"vertices":scenery.vertex_count,"indexed_vertices":scenery.land.mesh.surface_get_array_len(0),"leaves":scenery.leaves.size(),"trees":scenery.tree_count,"tree_batches":scenery.trees.get_child_count(),"build_ms":scenery.build_usec/1000.0,"maximum_zoom":maximum,"old_maximum_zoom":maxf(city.extent.x,city.extent.y)*1.6,"has_ocean":scenery.has_ocean,"native_state_unchanged":native.time==after.time and native.tiles==after.tiles}
	var file:=FileAccess.open("res://captures/surroundings-review.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"))
	var locale_report:=FileAccess.open("res://captures/surroundings-review-"+city.language+".json",FileAccess.WRITE);locale_report.store_string(JSON.stringify(report,"\t"))
	print("SURROUNDINGS_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
