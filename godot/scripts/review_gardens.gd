extends RefCounted

# Review real native garden placements, including every view of their 3D foliage.
func run(city: Node3D, phase: String) -> void:
	# macOS stops presenting an occluded window, which also stalls readback.
	DisplayServer.window_move_to_foreground()
	city.core.query("pause 1")
	var initial: Dictionary = city.core.simulation.snapshot(true)
	city.ui_layer.visible = false
	city.orbit.enabled = false
	city.orbit.pitch = 49
	var samples := []
	var complete := true
	var baseline := {}
	if phase == "after" and FileAccess.file_exists("res://captures/garden-review-before.json"):
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://captures/garden-review-before.json"))
		for sample in previous.samples:
			baseline[sample.asset] = sample.position
	for asset in ["deco_fish_pond", "deco_topiary", "deco_hedge_maze", "park", "deco_shell_garden", "deco_sundial", "deco_dolphin", "deco_orrery"]:
		var subject: Dictionary = {}
		var count := 0
		for building in initial.buildings:
			if building.asset == asset:
				count += 1
				if subject.is_empty():
					subject = building
				if baseline.has(asset) and building.x == baseline[asset][0] and building.y == baseline[asset][1]:
					subject = building
		if subject.is_empty():
			complete = false
			continue
		city.orbit.target = city.world_position(subject.x + (subject.w - 1) * .5, subject.y + (subject.h - 1) * .5, subject.altitude) + Vector3.UP * .3
		city.orbit.distance = maxf(float(subject.w) * 1.8, 3.0)
		for angle in [45.0, 135.0, 225.0, 315.0]:
			city.orbit.yaw = angle
			city.orbit.refresh()
			await city.get_tree().create_timer(.5).timeout
			city.capture_path = ProjectSettings.globalize_path("res://captures/garden-%s-%s-%d.png" % [phase, asset, angle])
			await city.capture()
			samples.append({"asset":asset, "count":count, "position":[subject.x,subject.y], "footprint":[subject.w,subject.h], "yaw":angle, "fps":Engine.get_frames_per_second(), "draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	var final: Dictionary = city.core.simulation.snapshot(true)
	var intact: bool = final.tiles == initial.tiles and final.time == initial.time and final.money == initial.money and final.buildings == initial.buildings and final.walkers == initial.walkers
	var report := {"phase":phase, "native_state_unchanged":intact, "all_garden_assets_present":complete, "tiles":initial.tiles.size(), "samples":samples}
	var file := FileAccess.open("res://captures/garden-review-%s.json" % phase, FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("GARDEN_REVIEW ", "PASS " if intact and complete else "FAIL ", JSON.stringify(report))
	city.get_tree().quit(0 if intact and complete else 1)
