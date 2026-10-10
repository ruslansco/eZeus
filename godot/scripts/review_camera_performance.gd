extends SceneTree
const Saves = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
const RefreshChecks = preload("res://scripts/refresh_performance_checks.gd")
var city: Node
var report := []
var checks := 0
var okay := true
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("CAMERA_PROFILE_CHECK ", "PASS " if value else "FAIL ", label)
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")
func frames(count := 20) -> void:
	for i in count: await process_frame
func stats(values: Array) -> Dictionary:
	var sorted := values.duplicate(); sorted.sort()
	var total := 0.0
	for value in sorted: total += value
	return {"mean":total/sorted.size(),"p50":sorted[sorted.size()/2],"p95":sorted[int((sorted.size()-1)*.95)],"max":sorted[-1]}
func sample(label: String, distance: float, moving: bool, render_3d := true, running := false) -> void:
	city.core.simulation.command("speed 1")
	city.core.simulation.command("pause %d" % (0 if running else 1))
	root.disable_3d = not render_3d
	city.orbit.distance = distance
	var focus: Array = city.state.focus
	var anchor: Vector3 = city.world_position(focus[0], focus[1], 0)
	city.orbit.target = anchor; city.orbit.snap_to_ground()
	await frames(40)
	var elapsed := []
	var core_ms := []
	var receive_samples := []
	var last_receive: Dictionary = city.receive_timing.duplicate()
	var script_ms := []
	var cpu_render_ms := []
	var draws := []
	var primitives := []
	var starting_walkers := native_tracks()
	city.sections.clear()
	var last := Time.get_ticks_usec()
	for i in 240:
		await process_frame
		var now := Time.get_ticks_usec()
		elapsed.append((now-last)/1000.0); last = now
		if moving:
			city.orbit.target = anchor + Vector3(8*sin(i*.03), 0, 8*cos(i*.03))
			city.orbit.snap_to_ground()
		var start := Time.get_ticks_usec()
		if running: city.core._process(.0166667)
		core_ms.append((Time.get_ticks_usec()-start)/1000.0)
		if running and city.state.get("blocked",false): break
		if city.receive_timing != last_receive:
			receive_samples.append(city.receive_timing.duplicate())
			last_receive = city.receive_timing.duplicate()
		start = Time.get_ticks_usec()
		city._process(.0166667)
		script_ms.append((Time.get_ticks_usec()-start)/1000.0)
		cpu_render_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var result := {"label":label,"distance":distance,"moving":moving,"running":running,"core_update_ms":stats(core_ms),"receive_samples":receive_samples,"frame_ms":stats(elapsed),"city_script_ms":stats(script_ms),"cpu_render_ms":stats(cpu_render_ms),"draws":stats(draws),"primitives":stats(primitives)}
	if not running: check(starting_walkers == native_tracks(), label + ": rendering leaves native walker tracks unchanged")
	result["sections"] = {}
	for section in city.sections: result.sections[section] = stats(city.sections[section])
	report.append(result); print("CAMERA_PROFILE ",JSON.stringify(result))
func run() -> void:
	Leaders.create("Camera Profile"); Leaders.set_current("Camera Profile")
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	var fixture := Saves.directory().path_join("camera profile.ez")
	if DirAccess.copy_absolute(source,fixture) != OK: quit(1); return
	Engine.set_meta("ezeus_load",fixture); Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city = load("res://main.tscn").instantiate(); city.set_script(load(OS.get_environment("EZEUS_CAMERA_PROFILE_SCRIPT"))); root.add_child(city); current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty(): await process_frame
	city.core.simulation.command("pause 1"); city.core.set_process(false)
	city.set_process(false); city.orbit.set_process(false)
	city.hud.set_minimap_open(false,false)
	DisplayServer.window_move_to_foreground(); root.warp_mouse(Vector2(960,500))
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	city.orbit.yaw=45; city.orbit.pitch=49
	await integration_checks()
	var refresh_checks := RefreshChecks.new()
	refresh_checks.run(self)
	checks += refresh_checks.checks; okay = okay and refresh_checks.okay
	await refresh_comparison()
	if "--refresh-only" in OS.get_cmdline_user_args():
		print("CAMERA_PROFILE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
		quit(0 if okay else 1); return
	await frames(45)
	for distance in [18.0,33.0,60.0,120.0,239.0]:
		city.orbit.distance=distance; city.orbit.target=Vector3.ZERO; city.orbit.snap_to_ground()
		var costs := []
		for i in 30:
			var start := Time.get_ticks_usec()
			city.view_footprint()
			costs.append((Time.get_ticks_usec()-start)/1000.0)
		print("CAMERA_FOOTPRINT ",distance," ",JSON.stringify(stats(costs)))
	await sample("stationary_near", 33, false)
	await sample("pan_near", 33, true)
	await sample("stationary_wide", 60, false)
	await sample("pan_wide", 60, true)
	await sample("pan_ui_only", 60, true, false)
	await sample("running_stationary_near", 33, false, true, true)
	await sample("running_pan_near", 33, true, true, true)
	print("CAMERA_NATIVE ",JSON.stringify(city.core.simulation.diagnostics()))
	var output := FileAccess.open("res://captures/camera-performance-review.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	print("CAMERA_PROFILE_DONE tiles=",city.tiles.size()," walkers=",city.walkers.size()," paused=",city.core.simulation.snapshot(false).paused)
	print("CAMERA_PROFILE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)

func native_tracks() -> Array:
	var rows := []
	for walker in city.core.simulation.snapshot(false).walkers:
		rows.append([walker.id, walker.asset, walker.x, walker.y, walker.altitude, walker.action])
	return rows

func refresh_comparison() -> void:
	# Alternating before/after CPU work on one paused native snapshot and frame.
	# Baseline batches are hidden and share the already loaded immutable templates;
	# only their old upload/recreation behavior differs. Nothing changes in C++.
	var before_native: Dictionary = city.core.simulation.snapshot(true)
	city.profile_legacy_batches = load(OS.get_environment("EZEUS_CAMERA_BASELINE_SCRIPT")).new()
	city.add_child(city.profile_legacy_batches)
	city.profile_legacy_batches.visible = false
	city.profile_legacy_batches.templates = city.static_batches.templates
	city.state.buildings_changed = true
	city.profile_legacy = true; city.update_buildings()
	city.profile_legacy = false; city.update_buildings()
	await frames(20)
	var previous := []; var current := []
	for i in 120:
		await process_frame
		for baseline in ([true,false] if i%2 == 0 else [false,true]):
			city.profile_legacy = baseline
			var started := Time.get_ticks_usec()
			city.update_buildings()
			(previous if baseline else current).append((Time.get_ticks_usec()-started)/1000.0)
	city.profile_legacy = false
	city.profile_legacy_batches.free()
	city.profile_legacy_batches = null
	var after_native: Dictionary = city.core.simulation.snapshot(true)
	check(before_native.time == after_native.time and before_native.buildings == after_native.buildings and before_native.walkers == after_native.walkers and before_native.tiles == after_native.tiles, "paired refresh benchmark leaves native time/buildings/walkers/terrain unchanged")
	var comparison := {"pairs":120,"baseline_ms":stats(previous),"optimized_ms":stats(current),"native_unchanged":true,"empty_agora_count":city.plaza_nodes.size()}
	var file := FileAccess.open("res://captures/building-refresh-comparison.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(comparison,"\t"))
	print("CAMERA_REFRESH_COMPARISON ",JSON.stringify(comparison))

func integration_checks() -> void:
	check(city.tiles.size() == 25992 and city.walkers.size() > 250, "designated full map and native crowd are loaded")
	var map_paints: int = city.hud.minimap.building_paints
	var paving: Dictionary = city.plaza_nodes.duplicate()
	var instances: Dictionary = city.static_batches.group_nodes.duplicate()
	var updates: int = city.building_render_updates
	var original: Dictionary = city.state.duplicate(true)
	var before := Time.get_ticks_usec()
	city.state.buildings_changed = true
	city.update_buildings()
	print("CAMERA_UNCHANGED_BUILDINGS_MS ", (Time.get_ticks_usec()-before)/1000.0)
	check(city.hud.minimap.building_paints == map_paints, "unchanged full-city footprints do not repaint the chart")
	check(paving == city.plaza_nodes, "full-city inventory refresh preserves existing Agora paving nodes")
	check(instances == city.static_batches.group_nodes and city.building_render_updates == updates, "an unchanged native building refresh skips every batch and worker update")
	var storage := {}
	for building in city.state.buildings:
		if building.asset == "warehouse" and not building.get("bays", []).is_empty(): storage = building; break
	var storage_id := int(storage.id)
	storage.bays[0].count += 1; storage.workers += 1
	city.update_buildings()
	check(city.building_render_updates == updates and city.building_index[storage_id].bays[0].count == storage.bays[0].count and city.building_index[storage_id].workers == storage.workers, "stock/staff totals refresh inspector records without changing rendered geometry")
	storage.working = not storage.working
	city.update_buildings()
	check(city.building_render_updates == updates+1 and city.static_batches.last_rebuilt == 0 and city.static_batches.last_activity_updates > 0, "a changed native work flag bypasses the filter and updates worker animation immediately")
	updates = city.building_render_updates
	storage.bays[0].good = "wood" if storage.bays[0].good != "wood" else "wheat"
	city.update_buildings()
	check(city.building_render_updates == updates+1 and city.static_batches.last_rebuilt > 0, "a changed occupied bay bypasses the filter and replaces its displayed goods immediately")
	updates = city.building_render_updates
	storage.x += 1
	city.update_buildings()
	check(city.building_render_updates == updates+1 and city.static_batches.last_rebuilt > 0, "a native footprint change refreshes geometry and cached placement immediately")
	var placement_key := "%d,%d" % [int(storage.x), int(storage.y)]
	var old_height: float = city.building_placements[placement_key].transform.basis.y.length()
	storage.grow = 50
	city.update_buildings()
	check(is_equal_approx(city.building_placements[placement_key].transform.basis.y.length(), old_height*.5), "native growth changes bypass the filter and update actual rendered scale")
	storage.erase("grow")
	city.update_buildings()
	updates = city.building_render_updates
	city.building_signature = 0
	city.update_buildings()
	check(city.building_render_updates == updates+1, "an explicit road/overlay rebuild bypasses the unchanged-render filter")
	# This save has no empty Agora spaces; inject only a disposable presentation
	# record to cover node reuse/replacement. Never issue a native build command.
	var agora := {"id":-99999,"asset":"agora_space","x":int(city.state.focus[0]),"y":int(city.state.focus[1]),"w":1,"h":1,"altitude":0}
	city.state.buildings.append(agora)
	city.update_buildings()
	var id := int(agora.id)
	var slab: MeshInstance3D = city.plaza_nodes[id]
	city.update_buildings()
	check(city.plaza_nodes[id] == slab, "an unchanged empty Agora retains its paving node")
	var slab_position := slab.position
	agora.altitude += 1
	city.update_buildings()
	check(city.plaza_nodes[id] == slab and slab.position.y > slab_position.y+.2, "changed native foundation height updates the existing paving node")
	agora.asset = "native_marker"
	city.update_buildings()
	check(not city.plaza_nodes.has(id) and not is_instance_valid(slab), "a replaced Agora space releases its paving even when the native ID survives")
	city.state = original
	city.state.buildings_changed = true
	city.update_buildings()
	check(city.plaza_nodes.size() == paving.size(), "restoring the disposable fixture reinstates all native paving")
	updates = city.building_render_updates
	city.set_overlay("water")
	check(city.overlay_view.active() and city.building_render_updates > updates, "opening a native city overlay invalidates the cached rendering state")
	updates = city.building_render_updates
	city.set_overlay("normal")
	check(not city.overlay_view.active() and city.building_render_updates > updates, "closing an overlay restores all normal geometry through the filter")
	var polygon: PackedVector2Array = city.view_footprint()
	var original_key: Array = city.footprint_key.duplicate()
	check(polygon.size() == 4 and polygon == city.view_footprint(), "an unchanged camera reuses the same ground footprint")
	city.orbit.target.x += 1.0; city.orbit.snap_to_ground()
	check(city.view_footprint() != polygon and city.footprint_key != original_key, "camera movement invalidates the ground footprint")
	original_key = city.footprint_key.duplicate()
	city.geometry_revision += 1
	city.view_footprint()
	check(city.footprint_key != original_key, "terrain geometry changes invalidate the ground footprint")
	original_key = city.footprint_key.duplicate()
	city.orbit.camera.fov += 1.0
	city.view_footprint()
	check(city.footprint_key != original_key, "projection changes invalidate the ground footprint")
	city.orbit.camera.fov = 48.0
	city.hud.set_minimap_open(false, false)
	var before_map: PackedVector2Array = city.hud.minimap.view.duplicate()
	city.orbit.target.x += 1.0; city.orbit.snap_to_ground()
	for i in 12: city._process(.0166667)
	check(city.hud.minimap.view == before_map, "a folded map skips its hidden footprint refresh")
	city.hud.set_minimap_open(true, false)
	for i in 12: city._process(.0166667)
	check(city.hud.minimap.view == city.view_footprint(), "opening the map restores the current footprint")
	city.hud.set_minimap_open(false, false)
	city.send_view_box()
	check(city.view_box_sent.begins_with("view_box "), "native on-screen sound bounds still receive the camera view")
	root.warp_mouse(Vector2(960,500))
	await frames(2)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP; wheel.pressed = true
	wheel.position = Vector2(960,500)
	var distance: float = city.orbit.distance
	city.orbit._unhandled_input(wheel)
	check(city.orbit.distance == distance and city.orbit.wheel_distance < distance and city.orbit.wheel_distance > 0.0, "the actual wheel handler queues an eased zoom")
	city.jump_to_cell(Vector2(city.state.focus[0],city.state.focus[1]))
	check(city.orbit.wheel_distance < 0.0, "Go to cancels pending wheel input")
