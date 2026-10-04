extends RefCounted

# Matched model portraits and real-city pedestrians. Never move native entities.
func run(city: Node3D, phase: String, subjects: Array = []) -> void:
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.ui_layer.visible = false
	city.orbit.enabled = false
	city.world.visible = false
	var saved_environments := {}
	# Focused deity reviews use a quiet studio background; the real-city check
	# below still observes the designated native save.
	if not subjects.is_empty():
		city.horizon.visible = false
		for child in city.get_children():
			if child is WorldEnvironment:
				saved_environments[child] = child.environment
				child.environment = child.environment.duplicate()
				child.environment.background_mode = Environment.BG_COLOR
				child.environment.background_color = Color(.028,.043,.067)
				child.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
				child.environment.ambient_light_color = Color(.52,.66,.86)
				child.environment.ambient_light_energy = .55
				child.environment.fog_enabled = false
	var stage := Node3D.new()
	city.add_child(stage)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.0,1.4,-2.0)
	fill.light_energy = .7
	fill.omni_range = 6.0
	stage.add_child(fill)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	floor_mesh.mesh = plane
	floor_mesh.material_override = city.material(Color(.11,.14,.19) if not subjects.is_empty() else Color(.43, .43, .40))
	stage.add_child(floor_mesh)
	var samples := []
	var catalog: Array = ["philosopher", "physician", "transporter", "walker_grower", "walker_astronomer", "walker_aphrodite", "settlers1"] if subjects.is_empty() else subjects
	for asset in catalog:
		var subject: Node3D = city.model(asset)
		stage.add_child(subject)
		var height: float = city.model_contract(asset).bounds_blender[1][2]
		# Gods are authored at an enlarged scale. Frame their faces rather than
		# placing the portrait camera inside a full-height dress.
		var scale: float = 3.0 if height > 1.4 else 1.0
		for view in (["whole", "face", "portrait", "rear", "walk", "fight", "appear"] if asset == "walker_hades" else ["whole", "face", "rear", "walk"]):
			var close: bool = view in ["face", "portrait"]
			city.orbit.pitch = 6.0 if view == "portrait" else 8.0 if view == "face" else 16.0
			city.orbit.yaw = 180.0 if view == "portrait" else 145.0 if view != "rear" else 35.0   # 180: straight in front of the figure
			city.orbit.distance = (.64 if close else (2.5 if asset == "settlers1" else 2.0))*scale
			city.orbit.target = Vector3(0, (.795 if close else .49)*scale, 0)
			if not subjects.is_empty() or view in ["walk", "fight", "appear"]:
				var morphs: Array = subject.get_meta("vat_parts", [])
				if morphs.is_empty():
					city.collect_morphs(subject, morphs)
				for morph in morphs:
					var mesh: MeshInstance3D = morph.node
					var label: String = "disappear" if view == "appear" else view if view in ["walk", "fight"] else "idle"
					var frame: int = 15 if view == "appear" else 6 if view in ["walk", "fight"] else 0
					var shape: int = morph.table.get("%s_%02d" % [label, frame],-1)
					if shape >= 0:
						if morph.get("vat", false):
							mesh.set_instance_shader_parameter("vat_pose", Vector3(shape,-1,0))
						else:
							for index in mesh.mesh.get_blend_shape_count():
								mesh.set_blend_shape_value(index, float(index == shape))
			city.orbit.refresh()
			await city.get_tree().create_timer(.3).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/character-%s-%s-%s.png" % [phase, asset, view])
			await city.capture()
			samples.append({"asset":asset,"view":view,"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		subject.free()
	stage.free()
	city.world.visible = true
	city.horizon.visible = true
	for environment in saved_environments:
		environment.environment = saved_environments[environment]
	# A temporary presentation specimen beside an existing native route. It is
	# never added to the simulation, and the snapshot equality gate proves that.
	if "walker_hades" in subjects:
		for walker in initial.walkers:
			if walker.asset in ["walker_waterdistributor", "walker_firefighter", "walker_watchman"]:
				var specimen: Node3D = city.model("walker_hades")
				for part in specimen.get_meta("vat_parts", []):
					part.node.set_instance_shader_parameter("vat_pose", Vector3(part.table.idle_00,-1,0))
				specimen.position = city.walker_world_position(walker)
				city.add_child(specimen)
				city.orbit.target = specimen.position+Vector3.UP*1.35
				city.orbit.distance = 6.2
				city.orbit.pitch = 25
				city.orbit.yaw = 145
				city.orbit.refresh()
				await city.get_tree().create_timer(.3).timeout
				city.capture_path = ProjectSettings.globalize_path("res://captures/character-%s-city-walker_hades.png" % phase)
				await city.capture()
				samples.append({"asset":"walker_hades","view":"city","native_route":walker.asset,"presentation_only":true})
				# The same specimen from the closest view the player can zoom to (orbit_camera.gd MINIMUM_DISTANCE).
				city.orbit.target = specimen.position+Vector3.UP*1.75
				city.orbit.distance = city.orbit.MINIMUM_DISTANCE
				city.orbit.pitch = 40
				city.orbit.refresh()
				await city.get_tree().create_timer(.3).timeout
				city.capture_path = ProjectSettings.globalize_path("res://captures/character-%s-city-closest-walker_hades.png" % phase)
				await city.capture()
				samples.append({"asset":"walker_hades","view":"city_closest","native_route":walker.asset,"presentation_only":true})
				specimen.free()
				break
	# Gods float rather than walk: every god among the subjects is put through the city's own per-frame code (review_god_float.gd).
	if not subjects.is_empty():
		await preload("res://scripts/review_god_float.gd").new().run(city, subjects, phase, samples)
	for asset in (["transporter", "walker_grower", "walker_curator"] if subjects.is_empty() else []):
		for walker in initial.walkers:
			if walker.asset == asset:
				city.orbit.target = city.walker_world_position(walker) + Vector3.UP * .4
				city.orbit.distance = 2.1
				city.orbit.pitch = 30
				city.orbit.yaw = 145
				city.orbit.refresh()
				await city.get_tree().create_timer(.3).timeout
				city.capture_path = ProjectSettings.globalize_path("res://captures/character-%s-city-%s.png" % [phase, asset])
				await city.capture()
				break
	var final: Dictionary = city.core.simulation.snapshot(true)
	var intact: bool = final.tiles == initial.tiles and final.time == initial.time and final.money == initial.money and final.buildings == initial.buildings and final.walkers == initial.walkers
	var report := {"phase":phase,"native_state_unchanged":intact,"samples":samples}
	var file := FileAccess.open("res://captures/character-review-%s%s.json" % [phase,"" if subjects.is_empty() else "-subjects"], FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("CHARACTER_REVIEW ", "PASS " if intact else "FAIL ", JSON.stringify(report))
	city.get_tree().quit(0 if intact else 1)
