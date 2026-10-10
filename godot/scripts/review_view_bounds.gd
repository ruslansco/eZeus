extends RefCounted
# Measures what the camera costs at different places: primitives, draw calls and GPU/CPU render time per view, with a capture
# each (captures/viewbounds-<tag>-<name>.png). Usage: run_godot_pilot.py --view-review <tag>.
func run(city: Node3D, tag: String) -> void:
	city.orbit.enabled = false
	var viewport := city.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var max_distance: float = city.orbit.maximum_distance
	var half: Vector2 = city.orbit.bounds
	# name, target, distance, pitch, yaw
	var views := [
		["play", Vector3.ZERO, 33.0, 49.0, 45.0],
		["overview", Vector3.ZERO, maxf(city.extent.x, city.extent.y) * .95, 49.0, 45.0],
		["max_centre_low", Vector3.ZERO, max_distance, 25.0, 45.0],
		["max_edge_low_out", Vector3(half.x, 0, half.y), max_distance, 25.0, 225.0],
		["max_edge_low_in", Vector3(half.x, 0, half.y), max_distance, 25.0, 45.0],
		["max_edge_high", Vector3(half.x, 0, half.y), max_distance, 75.0, 45.0],
	]
	var report := []
	for view in views:
		city.orbit.target = view[1]
		city.orbit.snap_to_ground()
		city.orbit.distance = view[2]
		city.orbit.pitch = view[3]
		city.orbit.yaw = view[4]
		city.orbit.refresh()
		await city.get_tree().create_timer(1.0).timeout
		var gpu := 0.0
		var cpu := 0.0
		var samples := 0
		for frame in 90:
			await RenderingServer.frame_post_draw
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport)
			samples += 1
		report.append({"view": view[0], "gpu_ms": gpu / samples, "cpu_ms": cpu / samples,
				"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		city.capture_path = ProjectSettings.globalize_path("res://captures/viewbounds-%s-%s.png" % [tag, view[0]])
		await city.capture()
	for entry in report:
		print("VIEWBOUNDS ", JSON.stringify(entry))
	city.get_tree().quit()
