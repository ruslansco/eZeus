extends RefCounted
# Native observations, real UI actions, draft retention and isolated presentation-preference persistence.
var city
var okay:=true
var checks:=0
const InterfaceDialog=preload("res://ui/interface_dialog.gd")

func check(value: bool, text: String) -> void:
	checks+=1;okay=city.check(value,text) and okay

func frames(count:=6) -> void:
	for frame in count:await city.get_tree().process_frame

func click(control: Control) -> void:
	await frames()
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;city.get_viewport().push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		city.get_viewport().push_input(event,true)
	await frames()

func inspect(asset: String) -> Dictionary:
	var building: Dictionary=city.state.buildings.filter(func(item):return item.asset==asset)[0]
	city.inspected=Vector2i(building.x,building.y);city.refresh_inspection()
	return city.inspector_controls.value

func run(scene: Node3D) -> bool:
	city=scene
	var hud: Control=city.hud
	var access: Node=city.get_tree().root.get_node("UiAccess")
	var original_sizes:=Vector2i(access.ui_size,access.text_size)
	var original_locale: String=city.language
	var original_window:=DisplayServer.window_get_size()
	var processing: bool=city.is_processing()
	city.set_process(false);city.orbit.enabled=false
	var before: Dictionary=city.core.simulation.snapshot(true)
	var summary: VBoxContainer=hud.get_node("%InspectionSummary")
	for asset in ["hospital","warehouse","olive_press"]:
		var data:=inspect(asset)
		check(summary.visible and summary.metrics.workers.reading.text=="%d / %d"%[int(data.employees),int(data.max_employees)],asset+" summary shows the exact native staffing")
		check(summary.metrics.maintenance.reading.text=="%d%%"%int(data.maintenance) and summary.metrics.road.column.visible==(not data.road_access),asset+" maintenance is shown and the road chip appears only for an unconnected building")
		if data.has("production"):
			var observed: String=str(data.production.status)
			var allowed: Array=["operational","understaffed","waiting_dispatch"] if observed=="operational" else [observed]
			check(summary.status_id in allowed and data.production.status==observed and summary.status.text==city.tr(summary.STATUS.get(summary.status_id,summary.Guidance.TITLES.get(summary.status_id,"Building status"))),"production summary preserves native stop reasons and labels staffing or full-stock hints")
	var home: Dictionary=city.state.buildings.filter(func(b):return b.asset.begins_with("common_house_"))[0]
	city.inspected=Vector2i(home.x,home.y);city.refresh_inspection()
	var home_data: Dictionary=city.inspector_controls.value
	check(summary.metrics.residents.column.visible and summary.metrics.residents.reading.text=="%d / %d"%[home_data.residents,home_data.capacity] and (summary.needs.visible or summary.house_box.visible),"housing summary shows occupancy and the native next-level needs")
	await click(summary.views.get_child(0))
	check(city.overlay_view.mode=="supplies" and hud.current_overlay=="supplies","housing's related-view button opens the real supplies overlay")
	var service: VBoxContainer=hud.get_node("%OverlaySummary")
	check(service.data==city.overlay_view.data and service.readings.text.contains(str(city.overlay_view.data.supplies.size())),"overlay summary consumes the already-polled native supplies data")
	var low:=0
	for row in service.data.supplies:
		if int(row[1])!=(1<<int(row[2]))-1:low+=1
	check(service.readings.text.contains(city.tr("Low supplies: %d")%low),"low-stock counter matches native supply flags")
	await click(service.quick.water)
	check(city.overlay_view.mode=="water" and service.quick.water.button_pressed,"service shortcut changes the native view and highlights it")
	var lowest: int=service.data.columns.filter(func(row):return int(row[1])==0).size()
	check(service.readings.text.contains(city.tr("Lowest coverage: %d")%lowest),"water counter uses the core's displayed coverage levels")
	var index:=0;var colors_match:=true
	for row in city.overlay_view.data.columns:
		if not city.building_index.has(int(row[0])):continue
		var color: Color=city.overlay_view.columns.multimesh.get_instance_color(index)
		colors_match=colors_match and color.is_equal_approx(city.Overlays.SHORT if int(row[1])==0 else city.Overlays.TONES[5])
		index+=1
	check(colors_match and index>0,"water columns and legend use matching low/higher-coverage colours")
	await click(service.close_button)
	check(city.overlay_view.mode=="normal" and not hud.get_node("%OverlayPanel").visible,"closing the service panel restores native normal visibility")
	# Size preview must not replace a storage edit or its stale-action token.
	var store:=inspect("warehouse")
	var resource: int=store.storage.resources[0].resource
	var editor: VBoxContainer=city.inspector_controls
	var row: Dictionary=editor.rows[resource]
	var draft:=0 if int(row.limit.value)>0 else 4
	row.limit.value=draft;editor.edit_storage(resource,600000)
	var token: int=store.target_token
	access.apply(125,130);await frames();city.refresh_inspection()
	check(editor.rows[resource].dirty and int(editor.rows[resource].limit.value)==draft and int(editor.value.target_token)==token,"larger text/interface and live refresh preserve an unfinished storage edit")
	var focus: Vector2i=Vector2i(home.x,home.y)
	city.orbit.target=city.world_position(focus.x,focus.y,city.tiles[focus][2]);city.orbit.refresh()
	await city.get_tree().physics_frame
	city.pick_tile(city.orbit.camera.unproject_position(city.orbit.target))
	check(city.picked==focus,"native terrain picking still matches the projected world after UI enlargement")
	# The dialog is tested only against an isolated file, never the player's preferences.
	var had_path:=Engine.has_meta("ezeus_settings_path")
	var old_path: Variant=Engine.get_meta("ezeus_settings_path","")
	var scratch:=ProjectSettings.globalize_path("res://captures/status-settings-%d.cfg"%OS.get_process_id())
	Engine.set_meta("ezeus_settings_path",scratch)
	var config:=ConfigFile.new();config.set_value("interface","language","ru");config.set_value("sound","master",.73);config.set_value("other","keep","untouched");config.save(scratch)
	var hash_before:=FileAccess.get_sha256(scratch)
	var dialog: Window=InterfaceDialog.open(hud)
	dialog.sizes.ui.select(0);dialog.sizes.text.select(0);dialog.preview();await frames()
	check(access.ui_size==100 and access.text_size==100 and FileAccess.get_sha256(scratch)==hash_before,"size choices preview immediately without writing preferences")
	city.orbit.enabled=true;var yaw: float=city.orbit.yaw
	Input.action_press("orbit_right");city.orbit._process(.3);Input.action_release("orbit_right");city.orbit.enabled=false
	check(is_equal_approx(yaw,city.orbit.yaw),"interface dialog blocks camera keys while it is open")
	dialog.canceled.emit();await frames()
	check(access.ui_size==125 and access.text_size==130 and not access.dialog_open and FileAccess.get_sha256(scratch)==hash_before,"Cancel restores previous sizes and leaves the preferences file unchanged")
	dialog=InterfaceDialog.open(hud);dialog.sizes.ui.select(1);dialog.sizes.text.select(1);dialog.preview();await frames();dialog.confirmed.emit();await frames()
	config.load(scratch)
	check(config.get_value("interface","ui_size")==110 and config.get_value("interface","text_size")==115 and config.get_value("interface","language")=="ru" and is_equal_approx(config.get_value("sound","master"),.73) and config.get_value("other","keep")=="untouched","Apply saves sizes while preserving language, sound and other preferences")
	access.apply(100,100);access.load_preferences()
	check(access.ui_size==110 and access.text_size==115,"saved sizes restore on preference reload")
	config.set_value("interface","ui_size",9999);config.set_value("interface","text_size",[]);config.save(scratch);access.load_preferences()
	check(access.ui_size==100 and access.text_size==100,"unsupported or malformed size values safely fall back to defaults")
	DirAccess.remove_absolute(scratch)
	if had_path:Engine.set_meta("ezeus_settings_path",old_path)
	else:Engine.remove_meta("ezeus_settings_path")
	# Maximum and independent sizes, at each supported resolution and language.
	for locale in ["en","ru"]:
		city.language=city.UiText.set_language(locale);hud.retranslate()
		for resolution in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(1920,1080)]:
			DisplayServer.window_set_size(resolution)
			for sizes in [Vector2i(100,100),Vector2i(125,100),Vector2i(100,130),Vector2i(125,130)]:
				access.apply(sizes.x,sizes.y)
				inspect("warehouse");city.set_overlay("water")
				hud.close_build_tray();hud.open_category("Industry");city.set_tool("olive_press")
				await frames(8)
				var screen:=Rect2(Vector2.ZERO,hud.size)
				var fit:=true
				for name in ["BottomBar","StatusBar","BuildTray","Inspector","OverlayPanel","StatsGroup"]:
					var panel: Control=hud.get_node("%"+name)
					fit=fit and screen.grow(1).encloses(panel.get_global_rect())
				if not fit:
					print("STATUS_BOUNDS ",locale," ",resolution," ",sizes," screen=",screen)
					for name in ["BottomBar","StatusBar","BuildTray","Inspector","OverlayPanel","StatsGroup"]:print(name," ",hud.get_node("%"+name).get_global_rect())
				check(fit and not hud.inspector.get_global_rect().intersects(hud.get_node("%BuildTray").get_global_rect()),"%s %s UI/text %s panels fit and inspection clears construction"%[locale,resolution,sizes])
	city.language=city.UiText.set_language(original_locale);hud.retranslate()
	access.apply(original_sizes.x,original_sizes.y);DisplayServer.window_set_size(original_window)
	city.set_overlay("normal");hud.close_build_tray();city.close_inspection();city.set_tool("select")
	await frames(8)
	city.set_process(processing)
	var after: Dictionary=city.core.simulation.snapshot(true)
	check(before.money==after.money and before.time==after.time and before.buildings==after.buildings and before.walkers==after.walkers,"status, overlays and accessibility leave the native city unchanged")
	print("STATUS_UI_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	return okay
