extends SceneTree
# Continuous motion in the designated city. Save/settings hashes are checked by the launcher.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var city: Node3D=load("res://main.tscn").instantiate()
	root.add_child(city)
	while city.state.is_empty() or city.frame_count<80: await process_frame
	city.core.query("pause 1")
	city.set_process(false);city.core.set_process(false);city.orbit.enabled=false;city.ui_layer.visible=false
	DisplayServer.window_move_to_foreground()
	var initial: Dictionary=city.core.simulation.snapshot(true)
	# Choose a citizen who is actually travelling, rather than one waiting at a service stop.
	city.core.query("pause 0")
	for frame in 12:
		city.core.simulation.advance(1.0/30.0)
		if frame%3==0:city.receive_state(city.core.simulation.snapshot(false))
		city._process(1.0/30.0)
	city.core.query("pause 1")
	var observed: Dictionary=city.core.simulation.snapshot(true)
	var id := -1
	for role in ["physician","philosopher","transporter","walker_grower"]:
		for walker in observed.walkers:
			var candidate: Dictionary=city.walkers[int(walker.id)]
			if walker.asset==role and candidate.moving:id=int(walker.id);break
		if id>=0:break
	if id<0:
		for candidate_id in city.walkers:
			if city.walkers[candidate_id].get("human",false) and city.walkers[candidate_id].moving:id=int(candidate_id);break
	if id<0: push_error("No human route in the designated test city");quit(1);return
	var route: Dictionary=city.walkers[id]
	# This city may have no physician yet. A review-only physician follows an existing
	# human's native route; its replacement never changes the live role mapping or C++ state.
	var preview: Node3D=city.model("physician");city.world.add_child(preview)
	preview.position=route.node.position;preview.rotation=route.node.rotation;route.node.visible=false
	var citizen: Node3D=city.citizen_lod.instantiate_skeletal(city.static_batches,city.models)
	preview.add_child(citizen)
	var morphs: Array=preview.get_meta("vat_parts") if preview.has_meta("vat_parts") else []
	if morphs.is_empty():city.collect_morphs(preview,morphs)
	for part in morphs:part.node.visible=false
	var subject := {"node":preview,"skeletal":citizen,"morphs":morphs,"human":true,"travel":0.0,"idle":0.0,"walk_weight":0.0,"still_time":.08}
	city.orbit.distance=5;city.orbit.pitch=35;city.orbit.yaw=rad_to_deg(route.node.rotation.y)+180
	city.orbit.target=subject.node.position+Vector3.UP*.35;city.orbit.refresh()
	var base: Vector3=subject.node.position
	var native_before: Dictionary=city.core.simulation.snapshot(true)
	# One complete authored cycle with a matching presentation-only displacement.
	var report := {"preview_role":"physician","source_native_role":route.asset,"preview_substitution":true,"posed_native_state_unchanged":false,"samples":[],"live_distance":0.0,"presentation_update_usec":[]}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures/locomotion"))
	for frame in 32:
		subject.node.position=base+subject.node.basis*Vector3(0,0,-.64*frame/32.0)
		subject.travel=.64*frame/32.0;subject.walk_weight=1.0;subject.still_time=0.0
		if subject.skeletal!=null: subject.skeletal.get_meta("skeletal_citizen").travel=subject.travel
		city.animate_walker(subject,0,0)
		city.orbit.target=subject.node.position+Vector3.UP*.35;city.orbit.refresh()
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://captures/locomotion/pose-%02d.png"%frame)
	var native_after: Dictionary=city.core.simulation.snapshot(true)
	report.posed_native_state_unchanged=native_before.time==native_after.time and native_before.walkers==native_after.walkers and native_before.buildings==native_after.buildings and native_before.tiles==native_after.tiles and native_before.money==native_after.money
	# Restore the observation, then let C++ run its own route; no presentation movement command.
	subject.node.position=base;subject.travel=0
	if subject.skeletal!=null: subject.skeletal.get_meta("skeletal_citizen").travel=0
	city.core.query("pause 0")
	var previous: Vector3=base
	for frame in 180:
		city.core.simulation.advance(1.0/30.0)
		if frame%3==0: city.receive_state(city.core.simulation.snapshot(false))
		var start := Time.get_ticks_usec()
		city._process(1.0/30.0)
		report.presentation_update_usec.append(Time.get_ticks_usec()-start)
		if not city.walkers.has(id):break
		route=city.walkers[id]
		subject.node.position=route.node.position;subject.node.rotation=route.node.rotation
		city.orbit.yaw=rad_to_deg(route.node.rotation.y)+180
		var moved:=Vector2(subject.node.position.x-previous.x,subject.node.position.z-previous.z).length()
		report.live_distance+=moved
		city.animate_walker(subject,1.0/30.0,moved)
		previous=subject.node.position
		city.orbit.target=subject.node.position+Vector3.UP*.35;city.orbit.refresh()
		await RenderingServer.frame_post_draw
		if frame%2==0:
			get_root().get_texture().get_image().save_png("res://captures/locomotion/live-%03d.png"%frame)
			report.samples.append({"travel":subject.travel,"blend":subject.walk_weight,"position":[subject.node.position.x,subject.node.position.y,subject.node.position.z],"skeletal":subject.skeletal!=null})
	city.core.query("pause 1")
	report.native_ticks_advanced=city.core.simulation.snapshot(false).time-initial.time
	report.walker_count=city.walkers.size();report.vram=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var file:=FileAccess.open("res://captures/locomotion/review.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"))
	var okay: bool=report.posed_native_state_unchanged and report.live_distance>.1 and subject.skeletal!=null
	print("LOCOMOTION_REVIEW ","PASS" if okay else "FAIL"," distance=",report.live_distance," native_ticks=",report.native_ticks_advanced," walkers=",report.walker_count)
	quit(0 if okay else 1)
