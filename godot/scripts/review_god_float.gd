extends RefCounted
# Gods float through the real city (god_float.gd). Each god is injected as a presentation-only walker into the city's own
# per-frame code, as a snapshot would deliver it: it glides along a straight line at about full speed for 3.5 seconds and then
# hovers in place. Nothing is added to the simulation (the core's link is held while it runs, so no snapshot replaces the walker,
# and the caller's snapshot equality gate proves the native state is untouched). The heights, lean and pose of every god are
# measured, and the gods named in `shots` are captured gliding and at rest from the side, low, so the gap under the feet shows.
const GodFloat = preload("res://scripts/god_float.gd")
const SHOTS := ["walker_hades", "walker_zeus", "walker_poseidon"]
const SPEED := .9            # tiles per second of the injected glide
const GLIDE_SECONDS := 3.5
const TOTAL_SECONDS := 5.0

func run(city: Node, assets: Array, phase: String, samples: Array) -> void:
	city.core.set_process(false)
	# Start where a town walker is (on a street among houses, as the Hades specimen of the character review), else anywhere.
	var start: Dictionary = {}
	for walker in city.state.walkers:
		if start.is_empty() or str(walker.asset) in ["walker_waterdistributor", "walker_firefighter", "walker_watchman"]:
			start = walker
			if str(walker.asset) in ["walker_waterdistributor", "walker_firefighter", "walker_watchman"]:
				break
	if start.is_empty():
		samples.append({"view": "god_float", "error": "no native walker to start from"})
		return
	var number := 0
	for asset in assets:
		if not GodFloat.is_god(str(asset)):
			continue
		number += 1
		var id := 900000 + number
		var walker := {"id": id, "asset": asset, "x": float(start.x), "y": float(start.y), "altitude": start.altitude, "type": -1, "action": 1, "orientation": 6}
		city.state.walkers.append(walker)
		city.update_walkers()
		var entry: Dictionary = city.walkers[id]
		var moving_hover := []
		var rest_hover := []
		var lean_max := 0.0
		var blend_max := 0.0
		var step_max := 0.0
		var last_y := -1.0
		var time := 0.0
		var tick := 0.0
		var shot_moving := false
		var shot_rest := false
		while time < TOTAL_SECONDS:
			await city.get_tree().process_frame
			var dt: float = city.get_process_delta_time()
			time += dt
			tick += dt
			if tick >= .1:
				tick -= .1
				if time < GLIDE_SECONDS:
					walker.x += SPEED * .1
				city.update_walkers()
			var node: Node3D = entry.node
			var ground: float = city.walker_surface_position(entry.native_position, entry.offset, true).y
			var hover := node.position.y - ground
			if last_y >= 0.0:
				# The vertical speed between two consecutive frames, in tiles per second (a frame that follows a capture is skipped).
				step_max = maxf(step_max, absf(hover - last_y) / maxf(dt, 1.0 / 120.0))   # a frame shorter than 1/120 s is not divided by its own length
			last_y = hover if dt < .08 else -1.0
			lean_max = maxf(lean_max, -node.rotation.x)
			for morph in entry.morphs:
				var blend = morph.node.get_instance_shader_parameter("vat_walk_blend") if morph.has("vat") else null
				if blend != null:
					blend_max = maxf(blend_max, float(blend))
			if time > 2.5 and time < GLIDE_SECONDS:
				moving_hover.append(hover)
			elif time > 4.2:
				rest_hover.append(hover)
			var shoot: bool = asset in SHOTS
			if shoot and not shot_moving and time > 3.0:
				shot_moving = true
				await shoot_god(city, node, "god-float-%s-%s-gliding.png" % [phase, str(asset).trim_prefix("walker_")])
			elif shoot and not shot_rest and time > 4.5:
				shot_rest = true
				await shoot_god(city, node, "god-float-%s-%s-resting.png" % [phase, str(asset).trim_prefix("walker_")])
		var moved: float = SPEED * GLIDE_SECONDS
		var glide_avg := average(moving_hover)
		var rest_avg := average(rest_hover)
		var floats: bool = glide_avg > GodFloat.HOVER and rest_avg > GodFloat.HOVER - GodFloat.BOB - .01 and lean_max > deg_to_rad(5.0)
		var steps_taken: bool = float(entry.travel) > .0001 or blend_max > .0001
		var smooth: bool = step_max < 1.0
		var okay: bool = floats and not steps_taken and smooth
		print("GOD_FLOAT ", "PASS " if okay else "FAIL ", asset, " glide ", snappedf(glide_avg, .001), " rest ", snappedf(rest_avg, .001), " lean ", snappedf(rad_to_deg(lean_max), .1), " deg, travel ", snappedf(float(entry.travel), .0001), ", walk blend ", snappedf(blend_max, .001), ", fastest vertical move ", snappedf(step_max, .001), " tiles/s")
		samples.append({"asset": asset, "view": "god_float", "glide_hover": glide_avg, "rest_hover": rest_avg, "lean_degrees": rad_to_deg(lean_max), "walk_blend": blend_max, "gait_travel": float(entry.travel), "fastest_vertical_tiles_per_second": step_max, "tiles_glided": moved, "pass": okay})
		city.state.walkers.erase(walker)
		city.update_walkers()
	city.core.set_process(true)

func shoot_god(city: Node, node: Node3D, file: String) -> void:
	city.orbit.target = node.position + Vector3.UP * 1.7
	city.orbit.distance = 13.0
	city.orbit.pitch = 12.0
	city.orbit.yaw = 0.0
	city.orbit.refresh()
	await city.get_tree().create_timer(.05).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/" + file)
	await city.capture()

func average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / values.size()
