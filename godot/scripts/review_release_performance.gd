extends SceneTree
# Owned benchmark only: no script is installed into gameplay. Wall-clock frame
# intervals include drawing; the core and city script are timed separately.
const Graphics = preload("res://scripts/graphics_settings.gd")
const Settings = preload("res://scripts/user_settings.gd")
const Saves = preload("res://scripts/save_files.gd")
var city: Node
var okay := true
var checks := 0
var phase_seconds := 4.0
var soak_seconds := 0.0
var benchmark_size := Vector2i(1920,1080)
var report := {"schema":1, "phases":[], "reloads":[], "limits":[]}

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("RELEASE_PERF_CHECK ", "PASS " if value else "FAIL ", label)

func frames(count := 8) -> void:
	for i in count: await process_frame

func statistics(values: Array) -> Dictionary:
	if values.is_empty(): return {"available":false}
	var sorted := values.duplicate(); sorted.sort()
	var total := 0.0
	for value in sorted: total += value
	return {"available":true,"samples":sorted.size(),"mean":total/sorted.size(), "p50":sorted[int((sorted.size()-1)*.50)],"p95":sorted[int((sorted.size()-1)*.95)],"p99":sorted[int((sorted.size()-1)*.99)],"max":sorted[-1]}

func freeze_manual() -> void:
	city.core.set_process(false); city.set_process(false); city.orbit.set_process(false)
	city.autosave_interval = 0.0
	city.hud.set_minimap_open(false,false)
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	city.core.commands.clear()

func sample(label: String, preset: String, distance: float, moving: bool, speed := -1, duration := -1.0, focus_override := Vector2(-99999,-99999)) -> void:
	Graphics.apply(self,preset)
	city.core.snapshot_received.emit(city.core.query("speed %d" % maxi(speed,0)))
	city.core.snapshot_received.emit(city.core.query("pause %d" % (1 if speed < 0 else 0)))
	city.orbit.distance = distance; city.orbit.yaw = 45; city.orbit.pitch = 49
	var focus: Array = city.state.focus
	var anchor: Vector3 = city.world_position(focus[0],focus[1],0)
	if focus_override != Vector2(-99999,-99999): anchor = city.world_position(focus_override.x,focus_override.y,0)
	city.orbit.target = anchor; city.orbit.snap_to_ground()
	# Warm rendering independently of gameplay: do not throw away simulated time.
	await frames(30)
	var initial: Dictionary = city.core.simulation.snapshot(true)
	var diagnostic_start: Dictionary = city.core.simulation.diagnostics()
	var elapsed := []; var core_ms := []; var script_ms := []; var cpu_render_ms := []; var gpu_ms := []
	var draws := []; var triangles := []; var vram := []; var hitches := 0
	var began := Time.get_ticks_usec(); var last := began; var heartbeat := began
	var wanted := duration if duration > 0 else phase_seconds
	var blocked := false
	while (Time.get_ticks_usec()-began)/1000000.0 < wanted:
		await process_frame
		var now := Time.get_ticks_usec()
		var dt := (now-last)/1000000.0; last = now
		elapsed.append(dt*1000.0)
		if dt > .050: hitches += 1
		if moving:
			var age := (now-began)/1000000.0
			city.orbit.target = anchor+Vector3(10*sin(age*.6),0,10*cos(age*.6))
			city.orbit.clamp_target(); city.orbit.snap_to_ground()
		var started := Time.get_ticks_usec()
		city.core._process(dt)
		core_ms.append((Time.get_ticks_usec()-started)/1000.0)
		started = Time.get_ticks_usec(); city._process(dt)
		script_ms.append((Time.get_ticks_usec()-started)/1000.0)
		cpu_render_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		if gpu > 0: gpu_ms.append(gpu)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		triangles.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		vram.append(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0)
		if city.state.get("blocked",false): blocked = true; break
		if now-heartbeat > 5000000:
			print("RELEASE_PERF_PROGRESS ",preset," ",label," seconds=",(now-began)/1000000.0)
			heartbeat=now
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	var final: Dictionary = city.core.simulation.snapshot(true)
	if speed < 0:
		check(initial.time == final.time and initial.buildings == final.buildings and initial.walkers == final.walkers, preset+" "+label+": paused native state preserved")
	else:
		check(blocked or final.time > initial.time, preset+" "+label+": native simulation advanced or retained a required decision")
	var result := {"label":label,"preset":preset,"distance":distance,"moving":moving,"speed":speed,"seconds":(Time.get_ticks_usec()-began)/1000000.0,"requested_seconds":wanted,"blocked":blocked,"time_start":initial.time,"time_end":final.time,"frame_ms":statistics(elapsed),"core_and_snapshot_ms":statistics(core_ms),"city_script_ms":statistics(script_ms),"render_cpu_ms":statistics(cpu_render_ms),"render_gpu_ms":statistics(gpu_ms),"draw_calls":statistics(draws),"primitives":statistics(triangles),"video_memory_mib":statistics(vram),"frames_over_50ms":hitches,"diagnostics_before":diagnostic_start,"diagnostics_after":city.core.simulation.diagnostics()}
	report.phases.append(result)
	print("RELEASE_PERF_PHASE ",preset," ",label," ",JSON.stringify({"frame_ms":result.frame_ms,"video_memory_mib":result.video_memory_mib,"blocked":blocked}))
	if DisplayServer.get_name() != "headless" and label in ["pan_near","native_fire"]:
		DisplayServer.window_move_to_foreground()
		await RenderingServer.frame_post_draw
		var capture_directory := OS.get_environment("EZEUS_PERFORMANCE_REPORT").get_base_dir()
		DirAccess.make_dir_recursive_absolute(capture_directory)
		root.get_texture().get_image().save_png(capture_directory.path_join("performance-"+RenderingServer.get_current_rendering_method()+"-"+preset+"-"+label+".png"))
	if blocked: report.limits.append(preset+" "+label+": native decision/episode block stopped the phase; no reply was invented")

func reload_saved(path: String, label: String) -> bool:
	var previous: Node = city
	var started := Time.get_ticks_usec()
	city.load_game(path)
	var deadline := Time.get_ticks_msec()+45000
	while is_instance_valid(previous) and Time.get_ticks_msec()<deadline: await process_frame
	while (current_scene == null or current_scene.get("state") == null or current_scene.state.is_empty()) and Time.get_ticks_msec()<deadline: await process_frame
	if is_instance_valid(previous) or current_scene == null or current_scene.state.is_empty():
		check(false,"reload completed: "+label); return false
	city = current_scene; freeze_manual()
	await frames(20)
	var row := {"label":label,"milliseconds":(Time.get_ticks_usec()-started)/1000.0,"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"video_memory_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"tiles":city.tiles.size(),"buildings":city.state.buildings.size(),"walkers":city.state.walkers.size()}
	report.reloads.append(row); print("RELEASE_PERF_RELOAD ",JSON.stringify(row))
	check(city.tiles.size() == 25992 and city.state.paused,"reload retains the full native map and paused start")
	return true

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase-seconds="): phase_seconds=clampf(float(arg.get_slice("=",1)),1,60)
		if arg.begins_with("--soak-minutes="): soak_seconds=clampf(float(arg.get_slice("=",1)),0,240)*60
		if arg.begins_with("--width="): benchmark_size.x=clampi(int(arg.get_slice("=",1)),640,7680)
		if arg.begins_with("--height="): benchmark_size.y=clampi(int(arg.get_slice("=",1)),480,4320)
	Settings.set_value("game","autosave_minutes",0)
	root.size = benchmark_size
	# Desktop window managers may shrink a 1080p window to leave room for the
	# taskbar/title bar. Use the owned fullscreen window when the display matches.
	await frames(10)
	if DisplayServer.get_name() != "headless" and root.size != benchmark_size and DisplayServer.screen_get_size(root.current_screen) == benchmark_size:
		root.mode = Window.MODE_FULLSCREEN
		await create_timer(1.0).timeout
		await frames(10)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	DirAccess.make_dir_recursive_absolute(Saves.directory())
	var fixture := Saves.directory().path_join("performance fixture.ez")
	check(DirAccess.copy_absolute(source,fixture) == OK,"designated fixture copied into scratch storage")
	Engine.set_meta("ezeus_load",fixture)
	city = load("res://main.tscn").instantiate(); root.add_child(city); current_scene=city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	await frames(20)
	if city.state.is_empty(): check(false,"fixture loaded"); finish(); return
	freeze_manual()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	report["host"]={"os":OS.get_name(),"os_version":OS.get_version(),"cpu":OS.get_processor_name(),"logical_cpus":OS.get_processor_count(),"godot":Engine.get_version_info(),"display":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"resolution":str(root.size),"headless":DisplayServer.get_name()=="headless","vsync":false,"fps_cap":0,"seed":OS.get_environment("EZEUS_SEED")}
	report["fixture"]={"sha256":FileAccess.get_sha256(source),"tiles":city.tiles.size(),"buildings":city.state.buildings.size(),"walkers":city.state.walkers.size()}
	report.host["system_memory"] = OS.get_memory_info()
	report.host["requested_resolution"] = str(benchmark_size)
	report.host["resolution_matched"] = root.size == benchmark_size
	if root.size != benchmark_size: report.limits.append("The window manager fitted the requested resolution to this display. Use the actual recorded size; this run cannot qualify the larger requested resolution.")
	report.limits.append("Short owned benchmark; not minimum-hardware qualification. Other running applications may influence results. GPU timing is unavailable when the backend returns zero.")
	if DisplayServer.get_name()=="headless": report.limits.append("Headless timings do not measure graphics performance.")
	var saved: Dictionary = city.core.simulation.save_city("performance baseline",city.save_view())
	check(saved.has("saved"),"checked baseline written only to scratch storage")
	var baseline := Saves.directory().path_join("performance baseline.ez")
	var digest: String = city.core.simulation.replay(0).digest
	for preset in Graphics.ORDER:
		await sample("stationary",preset,33,false)
		await sample("pan_near",preset,33,true)
		await sample("pan_wide",preset,80,true)
		check(city.core.simulation.replay(0).digest==digest,preset+": matched paused workload preserved")
	# Same native start for each speed; a required decision stops rather than auto-answers.
	for speed in [1,3]:
		if not await reload_saved(baseline,"before_speed_%d"%speed): finish(); return
		await sample("running_pan_speed_%d"%speed,"balanced",33,true,speed)
	# Actual native fire, followed by actual rendered flames/smoke in the disposable city.
	if not await reload_saved(baseline,"before_fire"): finish(); return
	var house := {}
	for building in city.state.buildings:
		if str(building.asset).begins_with("common_house"): house=building; break
	city.core.simulation.enable_test_commands()
	var fire: Dictionary = city.core.query("test_fire %d %d"%[house.x,house.y]) if not house.is_empty() else {}
	check(fire.get("done",false),"native fire started only in the disposable fixture")
	city.core.snapshot_received.emit(city.core.simulation.snapshot(true))
	check(not city.building_fires.fires.is_empty(),"native fire has actual rendered flames/smoke")
	await sample("native_fire","balanced",33,true,1,-1,Vector2(float(house.x)+(int(house.w)-1)*.5,float(house.y)+(int(house.h)-1)*.5))
	for i in 3:
		if not await reload_saved(baseline,"repeated_load_%d"%i): finish(); return
		check(city.core.simulation.replay(0).digest==digest,"repeated load preserves gameplay digest")
	if soak_seconds>0: await sample("long_session","balanced",33,true,3,soak_seconds)
	check(city.core.simulation.replay(0).off_thread_draws==0,"no native RNG draws from workers")
	finish()

func finish() -> void:
	report["checks"]=checks; report["passed"]=okay
	var output:=FileAccess.open(OS.get_environment("EZEUS_PERFORMANCE_REPORT"),FileAccess.WRITE)
	if output == null: check(false,"report saved")
	else: output.store_string(JSON.stringify(report,"\t")); output.close()
	print("RELEASE_PERFORMANCE_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks)
	quit(0 if okay else 1)
