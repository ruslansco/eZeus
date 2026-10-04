extends SceneTree
var city: Node3D
var okay := true
var checks := 0
var language := "en"
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"));call_deferred("run")
func frames(count:=12) -> void:
	for frame in count:await process_frame
func check(value: bool, description: String) -> void:
	checks+=1;okay=okay and value;print("RESOURCE_BAR_CHECK ","PASS " if value else "FAIL ",description)
func click(button: Control) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		event.set_meta("review_input",true);root.push_input(event,true)
	await frames()
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground();await frames();await RenderingServer.frame_post_draw
	var frame:=root.get_texture().get_image();frame.save_png("res://captures/resources-"+name+"-"+language+".png")
	var rect: Rect2=city.hud.get_node("%ResourcesPanel").get_global_rect();var scale: Vector2=Vector2(frame.get_size())/city.hud.size
	frame.get_region(Rect2i(rect.position*scale,rect.size*scale)).save_png("res://captures/resources-"+name+"-detail-"+language+".png")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):language=arg.get_slice("=",1)
	city=load("res://main.tscn").instantiate();root.add_child(city);root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count<80:await process_frame
	city.core.query("pause 1");city.core.set_process(false);city.set_process(false);city.orbit.enabled=false
	if is_instance_valid(city.escape_menu):city.close_escape_menu()
	city.close_inspection();city.set_tool("select");city.hud.close_build_tray();city.hud.set_messages_open(false);city.hud.set_goals_expanded(false)
	var hud: Control=city.hud;var before: Dictionary=city.core.simulation.snapshot(true);var header: Dictionary=before.city_header
	check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible,"resources start folded beneath a compact overview bar")
	await capture("folded")
	await click(hud.get_node("%ResourcesToggle"));await create_timer(.3).timeout
	check(hud.resources_open and hud.resources_fraction>0.99,"arrow after jobs reveals resources smoothly")
	await click(hud.get_node("%ResourcesToggle"));await create_timer(.3).timeout
	check(not hud.get_node("%ResourcesReveal").visible,"second arrow click folds resources and releases the area")
	hud.set_resources_open(true);await frames(2);hud.set_resources_open(false);await create_timer(.3).timeout
	check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible,"rapid reversal finishes folded without a stale tween")
	var access: Node=root.get_node("UiAccess");var prior_motion: bool=access.reduced_motion
	access.reduced_motion=true;hud.set_resources_open(true)
	check(hud.resources_fraction==1 and hud.get_node("%ResourcesReveal").visible,"reduced motion opens resources immediately")
	hud.set_resources_open(false)
	check(hud.resources_fraction==0 and not hud.get_node("%ResourcesReveal").visible,"reduced motion folds resources immediately")
	access.reduced_motion=prior_motion
	hud.set_resources_open(true);await create_timer(.3).timeout
	var ids:=[]
	for entry in header.stock:ids.append(int(entry.resource))
	check(ids.size()==24 and range(23).all(func(bit):return ids.has(1<<bit)) and ids.has(255),"native header contains all 23 resource bits through silver plus food total")
	check(hud.resource_buttons.size()==24 and ids.all(func(id):return hud.resource_buttons.has(id) and not hud.resource_buttons[id].disabled),"every native resource has a visible, enabled item including zero stocks")
	var world: Dictionary=city.core.query("world");var mine: Dictionary=world.mine.filter(func(c):return c.current)[0];var matched:=true;var food:=0
	for item in mine.stock:
		if int(item.resource)<=128:food+=int(item.count)
		if hud.resource_buttons.has(int(item.resource)):
			matched=matched and header.stock.filter(func(r):return int(r.resource)==int(item.resource))[0].count==item.count
	matched=matched and header.stock.filter(func(r):return int(r.resource)==255)[0].count==food
	check(matched,"available native world stocks independently match header counts and food sum")
	var manifest: Array=JSON.parse_string(FileAccess.get_file_as_string("res://ui/resource_art/manifest.json"))
	check(manifest.size()==24 and manifest.all(func(item):return int(item.triangles)<=8192 and ResourceLoader.exists("res://ui/resource_art/"+item.model)),"24 original resource models have saved scenes and bounded geometry")
	check(hud.resource_buttons.values().all(func(button):return button.icon!=null and button.icon.get_size()==Vector2(128,128)),"every displayed icon uses its static 128-pixel 3D render")
	for size in [Vector2i(1920,1080),Vector2i(1600,1000),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size)
		for sizing in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(sizing.x,sizing.y);await frames()
			var ribbon: Rect2=hud.get_node("%ResourcesPanel").get_global_rect();var screen:=Rect2(Vector2.ZERO,hud.size)
			check(screen.encloses(ribbon) and hud.resource_buttons.values().all(func(button):return button.is_visible_in_tree() and ribbon.encloses(button.get_global_rect())),"all resources fit without scrolling "+str(size)+" "+str(sizing))
			check(hud.get_node("%ResourceRibbon").get_global_rect().encloses(hud.get_node("%StatsGroup").get_global_rect()) and not ribbon.intersects(hud.get_node("%WelfareGroup").get_global_rect()),"stats stay in top bar and welfare clears resources "+str(size)+" "+str(sizing))
			if sizing.x==100 or size==Vector2i(1280,720):await capture(str(size.x)+("-large" if sizing.x>100 else ""))
	root.get_node("UiAccess").apply(100,100);DisplayServer.window_set_size(Vector2i(1600,1000));await frames()
	await click(hud.resource_buttons[64]);check(city.overlay_view.mode=="supplies","food icon click retains native supplies shortcut")
	await click(hud.resource_buttons[8192]);check(city.overlay_view.mode=="distribution","material icon click retains distribution shortcut")
	city.set_overlay("normal")
	var large: Dictionary=header.duplicate(true);large.name="A long native city name · ".repeat(12)
	for item in large.stock:item.count=123456789
	hud.set_city_header(large);DisplayServer.window_set_size(Vector2i(1280,720));root.get_node("UiAccess").apply(125,130);await frames()
	var bounds: Rect2=hud.get_node("%ResourcesPanel").get_global_rect()
	check(Rect2(Vector2.ZERO,hud.size).encloses(bounds) and hud.resource_buttons.values().all(func(button):return bounds.encloses(button.get_global_rect()) and button.tooltip_text.contains(hud.group_digits(123456789))),"large exact counts wrap while retaining every item and full tooltips")
	check(hud.get_node("%CityName").tooltip_text==large.name,"long city title keeps its complete tooltip")
	hud.set_city_header(header);root.get_node("UiAccess").apply(100,100)
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(before.time==after.time and before.money==after.money and before.buildings==after.buildings and before.city_header==after.city_header,"header clicks/resizing/art leave native city state unchanged")
	print("RESOURCE_BAR_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks);quit(0 if okay else 1)
