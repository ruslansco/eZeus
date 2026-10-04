extends SceneTree
# Captures authored GPU poses on real native building placements. The native city
# stays paused and unchanged throughout; these pose samples are visual evidence.
func _initialize() -> void:
	call_deferred("run")

func mesh_lods(node: Node, stats: Dictionary) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var info: Dictionary = RenderingServer.mesh_get_surface(node.mesh.get_rid(),surface)
			var stride := 4 if int(info.vertex_count)>65535 else 2
			stats.triangles += info.index_data.size()/stride/3
			stats.lods += info.get("lods",[]).size()
	for child in node.get_children():mesh_lods(child,stats)

func run() -> void:
	var city: Node3D = load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count < 100:await process_frame
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	await process_frame
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.set_process(false);city.core.set_process(false);city.ui_layer.visible=false;city.orbit.enabled=false
	var report := {"samples":[],"native_state_unchanged":false}
	var independent := false
	var probe := preload("res://scripts/building_batches.gd").new();root.add_child(probe)
	var placements := [{"transform":Transform3D.IDENTITY,"working":true,"animation_offset":3},{"transform":Transform3D.IDENTITY,"working":false,"animation_offset":6}]
	probe.rebuild({"warehouse|probe":placements})
	for node in probe.group_nodes["warehouse|probe"]:
		if node.multimesh.use_custom_data:
			independent = node.multimesh.get_instance_custom_data(0) == Color(1,3,0,0) and node.multimesh.get_instance_custom_data(1) == Color(0,6,0,0)
	probe.free();report.independent_instance_work = independent
	for asset in ["olive_press","timber_mill","warehouse"]:
		var subject := {}
		for building in initial.buildings:
			if building.asset == asset and building.working:subject=building;break
		if subject.is_empty():continue
		city.orbit.target=city.world_position(subject.x+(subject.w-1)*.5,subject.y+(subject.h-1)*.5,subject.altitude)+Vector3.UP*.3
		city.orbit.distance=maxf(float(subject.w)*1.7,3.5)
		city.orbit.pitch=38;city.orbit.yaw=135;city.orbit.refresh()
		for frame in range(16 if asset == "olive_press" else 4):
			var phase := float(frame)*.5 if asset == "olive_press" else float(frame)*2
			RenderingServer.global_shader_parameter_set("building_work_clock",phase)
			await create_timer(.12).timeout
			city.capture_path=ProjectSettings.globalize_path("res://captures/work-%s-%02d.png"%[asset,frame])
			await city.capture()
			report.samples.append({"asset":asset,"position":[subject.x,subject.y],"phase":phase,"workers":subject.workers,"working":subject.working,"fps":Engine.get_frames_per_second(),"vram":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		if asset == "olive_press":
			# Isolate the shader's inactive branch without editing the native city.
			var restored := []
			for key in city.static_batches.group_nodes:
				if not str(key).begins_with("olive_press|"):continue
				for node in city.static_batches.group_nodes[key]:
					var batch: MultiMesh=node.multimesh
					if not batch.use_custom_data:continue
					for index in batch.instance_count:
						var data:=batch.get_instance_custom_data(index)
						restored.append([batch,index,data])
						batch.set_instance_custom_data(index,Color(0,data.g,0,0))
			await create_timer(.12).timeout
			city.capture_path=ProjectSettings.globalize_path("res://captures/work-olive_press-inactive.png")
			await city.capture()
			for entry in restored:entry[0].set_instance_custom_data(entry[1],entry[2])
	var final: Dictionary=city.core.simulation.snapshot(true)
	report.native_state_unchanged=initial.time == final.time and initial.money == final.money and initial.tiles == final.tiles and initial.buildings == final.buildings and initial.walkers == final.walkers
	var geometry := [];var geometry_okay := true
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://..").path_join("tools/building_activity_assets.json")))
	for asset in names:
		var scene: Node = load(city.static_batches.activity.model_path(asset)).instantiate()
		var stats := {"asset":asset,"triangles":0,"lods":0}
		mesh_lods(scene,stats);scene.free()
		geometry_okay = geometry_okay and (stats.triangles<=5000 or stats.lods>0)
		geometry.append(stats)
	report.imported_geometry=geometry;report.imported_lods_pass=geometry_okay
	var file:=FileAccess.open("res://captures/building-activity-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	var okay: bool = report.native_state_unchanged and independent and geometry_okay and not report.samples.is_empty()
	print("BUILDING_ACTIVITY_REVIEW ","PASS" if okay else "FAIL", " ",JSON.stringify(report))
	quit(0 if okay else 1)
