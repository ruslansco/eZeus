extends RefCounted
# Integration gate for contextual construction, using real Controls and native read-only quotes.
var city
var okay:=true
var checks:=0

func check(value: bool, description: String) -> void:
	checks+=1
	okay=city.check(value,description) and okay

func move(point: Vector2) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=point
	city.get_viewport().push_input(event,true)
	for frame in 3:await city.get_tree().process_frame

func click(control: Control) -> void:
	var point:=control.get_global_rect().get_center()
	await move(point)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		city.get_viewport().push_input(event,true)
	for frame in 3:await city.get_tree().process_frame

func run(scene: Node3D) -> bool:
	city=scene
	var hud: Control=city.hud
	var processing: bool=city.is_processing()
	city.set_process(false)
	var before: Dictionary=city.core.simulation.snapshot(true)
	var language: String=city.language
	var facing: int=city.orientation
	var window:=DisplayServer.window_get_size()
	city.set_tool("hospital")
	hud.close_build_tray();hud.open_category("Health and water")
	for frame in 5:await city.get_tree().process_frame
	var spec: Dictionary=hud.build_entries.hospital
	check(hud.context_item.name=="hospital" and hud.get_node("%ContextTitle").text==hud.item_name(spec),"context identifies the selected native building")
	check(hud.get_node("%ContextFacts").text==city.tr("%d × %d tiles")%[spec.w,spec.h],"selected context shows native dimensions without cost amounts")
	check(not hud.get_node("%RotateRow").visible and not hud.get_node("%ContextHelp").visible,"choices omit rotation controls and instructions")
	check(absf(hud.get_node("%BottomBar").position.y-hud.get_node("%BuildTray").get_global_rect().end.y-5)<1,"choices sit five logical pixels above the dock")
	await move(hud.building_cards.fountain.get_global_rect().get_center())
	if hud.context_item.name!="fountain" or city.mode!="hospital":
		print("CONTEXT_HOVER item=",hud.context_item.name," mode=",city.mode," pointer=",hud.get_local_mouse_position()," fountain=",hud.building_cards.fountain.get_global_rect()," hovered=",city.get_viewport().gui_get_hovered_control())
	check(hud.context_item.name=="fountain" and city.mode=="hospital","hover previews another building without selecting its tool")
	await move(Vector2(500,120))
	check(hud.context_item.name=="hospital","leaving a building tile restores the selected context")
	await click(hud.get_node("%MapToggle"))
	check(not hud.get_node("%BuildTray").visible and hud.get_node("%MinimapPanel").visible and hud.get_node("%MapToggle").button_pressed,"one map click closes the tray and restores the live minimap")
	city.set_tool("wall");hud.close_build_tray();hud.open_category("Walls and defence")
	for frame in 5:await city.get_tree().process_frame
	check(hud.get_node("%WallFill").visible and not hud.get_node("%RotateRow").visible,"wall tool shows native fill options instead of facing controls")
	await click(hud.get_node("%WallFill"))
	check(city.road_drag.wall_fill and hud.get_node("%WallFill").button_pressed,"wall checkbox updates the existing native drag mode")
	city.road_drag.tool="wall"
	var candidate:=Vector2i(99999,99999)
	for point in city.tiles:
		if int(city.tiles[point][4])!=0:continue
		if city.core.query("preview hospital %d %d 0"%[point.x,point.y]).get("valid",false):
			candidate=point;break
	check(candidate.x!=99999,"native query finds a free footprint for contextual preview checks")
	if candidate.x!=99999:
		var end:=candidate+Vector2i(2,2)
		var filled: Dictionary=city.core.query(city.road_drag.preview_text(candidate,end))
		await click(hud.get_node("%WallFill"))
		var outline: Dictionary=city.core.query(city.road_drag.preview_text(candidate,end))
		check(filled.get("new",0)==9 and outline.get("new",0)==8 and int(filled.cost)>int(outline.cost),"fill checkbox quotes the native nine-piece fill and eight-piece outline")
		check(not city.road_drag.wall_fill and not hud.get_node("%WallFill").button_pressed,"wall checkbox returns to outline mode")
		city.set_tool("hospital");hud.close_build_tray()
		city.picked=candidate;city.refresh_placement()
		var text: Label=hud.get_node("%PlacementText")
		check(city.placement_result.valid and text.text.contains(str(int(city.placement_result.cost))) and text.text.contains(city.tr("Ready to place")),"placement badge shows the exact successful native quote")
		check(hud.get_node("%PlacementBadge").theme_type_variation=="PlacementGood","valid placement has the shared selected accent")
		var occupied: Dictionary=city.state.buildings.filter(func(b):return b.asset=="hospital")[0]
		city.picked=Vector2i(occupied.x,occupied.y);city.placement_key="";city.refresh_placement()
		check(not city.placement_result.valid and text.text.contains(city.reason_text(city.placement_result.reason)),"blocked badge explains the actual native placement restriction")
		check(hud.get_node("%PlacementBadge").theme_type_variation=="PlacementBad","blocked placement uses a distinct warning accent")
		for point in [Vector2(5,90),Vector2(hud.size.x-5,90),Vector2(500,hud.size.y-120)]:
			await move(point)
			hud._process(0)
			var badge: Control=hud.get_node("%PlacementBadge")
			var status: Rect2=hud.get_node("%StatusBar").get_global_rect()
			var dock: Rect2=hud.get_node("%BottomBar").get_global_rect()
			var city_area:=Rect2(Vector2(0,status.end.y),Vector2(hud.size.x,dock.position.y-status.end.y))
			if not (badge.visible and city_area.grow(1).encloses(badge.get_global_rect())):
				print("CONTEXT_BADGE_BOUNDS visible=",badge.visible," badge=",badge.get_global_rect()," city_area=",city_area)
			check(badge.visible and city_area.grow(1).encloses(badge.get_global_rect()),"cursor badge stays inside the map area at %s"%str(point))
		check(hud.get_node("%PlacementBadge").mouse_filter==Control.MOUSE_FILTER_IGNORE and text.mouse_filter==Control.MOUSE_FILTER_IGNORE,"placement information passes pointer input through to the map")
		city.pick_tile(Vector2(-10000,-10000))
		check(not hud.placement_feedback_active,"leaving native terrain clears stale placement feedback")
	city.set_tool("select")
	check(not hud.placement_feedback_active,"inspection clears placement feedback")
	for locale in ["en","ru"]:
		city.language=city.UiText.set_language(locale);hud.retranslate()
		for resolution in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(1920,1080)]:
			DisplayServer.window_set_size(resolution)
			for tool in ["hospital","wall","temple_zeus"]:
				if not hud.build_entries.has(tool):continue
				city.set_tool(tool)
				var category: String="Health and water" if tool=="hospital" else ("Walls and defence" if tool=="wall" else "Sanctuaries")
				hud.close_build_tray();hud.open_category(category)
				for frame in 6:await city.get_tree().process_frame
				var tray: Rect2=hud.get_node("%BuildTray").get_global_rect()
				var dock: Rect2=hud.get_node("%BottomBar").get_global_rect()
				check(Rect2(Vector2.ZERO,hud.size).encloses(tray) and tray.end.y<=dock.position.y-5,"%s %s %s contextual tray fits above the toolbar"%[locale,resolution,tool])
				check(not hud.get_node("%MinimapPanel").visible,"open tray keeps the minimap from covering construction controls")
	city.language=city.UiText.set_language(language);hud.retranslate()
	city.turn_placement(facing-city.orientation)
	DisplayServer.window_set_size(window)
	hud.close_build_tray();city.set_tool("select")
	city.set_process(processing)
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(before.money==after.money and before.time==after.time and before.buildings==after.buildings and before.walkers==after.walkers,"contextual UI changes leave treasury, clock, buildings and walkers unchanged")
	print("CONTEXT_UI_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	return okay
