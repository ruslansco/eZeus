extends SceneTree
# Real Metal city, designated save and actual viewport input. No save/settings
# writes; complete snapshots prove camera travel has no simulation authority.
var checks := 0
var okay := true
var language := "en"
var size := Vector2i(1600, 1000)
var city: Node
var images := 0
var captured: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1; okay = okay and value
	print("FLIGHT_CHECK ", "PASS " if value else "FAIL ", description)
func frames(count := 8) -> void:
	for i in count: await process_frame
func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new(); event.physical_keycode = code; event.pressed = pressed
		root.push_input(event, true)
func wheel(button: int) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = root.get_visible_rect().size * Vector2(.44, .45)
		event.button_index = button; event.pressed = pressed
		root.push_input(event, true)
func pinch(factor: float) -> void:
	var event := InputEventMagnifyGesture.new()
	event.position = root.get_visible_rect().size * Vector2(.44, .45); event.factor = factor
	root.push_input(event, true)
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true)
func capture(suffix: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://captures/world-flight-%s-%s.png" % [language, suffix]
	root.get_texture().get_image().save_png(path)
	captured.append(path)
	images += 1
func finish_flight(record := "") -> void:
	var last := -1
	var began := Time.get_ticks_msec()
	while city.world_flight.busy() and Time.get_ticks_msec() - began < 6000:
		await process_frame
		var slot := mini(14, int(city.world_flight.progress * 15.0))
		if record != "" and slot != last:
			last = slot
			await capture("%s-%02d" % [record, slot])
	check(not city.world_flight.busy(), "flight finishes within its bounded duration")
	await frames(4)
func same_city(a: Dictionary, b: Dictionary) -> bool:
	return a.tiles == b.tiles and a.buildings == b.buildings and a.walkers == b.walkers and a.money == b.money and a.time == b.time and a.events == b.events
func pose_matches(a: Dictionary) -> bool:
	var b: Dictionary = city.world_flight.pose(city.orbit)
	return (a.target as Vector3).distance_to(b.target) < .001 and absf(a.distance-b.distance) < .001 and absf(a.yaw-b.yaw) < .001 and absf(a.pitch-b.pitch) < .001

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.get_slice("=", 1)
		if arg.begins_with("--size="):
			var parts := arg.get_slice("=", 1).split("x"); size = Vector2i(int(parts[0]), int(parts[1]))
	Engine.set_meta("ezeus_language", language)
	if OS.has_environment("EZEUS_REVIEW_SETTINGS_PATH"): Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	TranslationServer.set_locale(language)
	root.size = size; root.content_scale_size = Vector2i(1440, 900)
	city = load("res://main.tscn").instantiate(); root.add_child(city); current_scene = city
	while city.state.is_empty() or city.frame_count < 60: await process_frame
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	var before: Dictionary = city.core.simulation.snapshot(true)
	var world_before: Dictionary = city.core.query("world")
	check(city.world_map.atlas.built and not city.world_map.atlas.active and city.world_map.atlas.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "relief is prepared during city load without hidden rendering")
	key(KEY_HOME); await frames()
	check(not city.world_map.visible and city.orbit.distance < city.orbit.maximum_distance, "Home keeps the bounded city overview")
	await capture("city-overview")
	var initial: float = city.orbit.distance
	wheel(MOUSE_BUTTON_WHEEL_UP); await frames(2)
	check(city.orbit.distance < initial and not city.world_map.visible, "ordinary zoom remains in the city")
	# First reach the limit without crossing it, then exercise real wheel input.
	city.orbit.distance = city.orbit.maximum_distance / 1.05; city.orbit.snap_to_ground()
	var saved: Dictionary = city.world_flight.pose(city.orbit)
	var world_visible: bool = city.world.visible
	var horizon_visible: bool = city.horizon.visible
	var mode_before: String = city.mode
	wheel(MOUSE_BUTTON_WHEEL_DOWN)
	check(city.world_flight.phase == "out" and city.world_map.visible, "outward wheel at city limit starts ascent into the native atlas")
	check(city.core.simulation.snapshot(true).paused and not city.orbit.enabled, "native hold and camera lock happen before the first flight frame")
	check(city.world_map.transitioning and city.world_map.atlas.cinematic and city.world_map.atlas.active, "both live scenes render while atlas input is locked")
	var age: float = city.world_flight.age
	var atlas_distance: float = city.world_map.atlas.desired_distance
	for i in 8: wheel(MOUSE_BUTTON_WHEEL_DOWN)
	key(KEY_SPACE); key(KEY_HOME); key(KEY_X); key(KEY_F5)
	check(city.world_flight.age == age and city.world_map.atlas.desired_distance == atlas_distance and city.mode == mode_before, "wheel momentum, Home, pause, demolition and save cannot restart or edit during ascent")
	var cloud: Vector3 = city.world_map.atlas.clouds[0].node.position
	await capture("out-00")
	await frames(10)
	check(city.orbit.distance > saved.distance and city.orbit.pitch > saved.pitch, "city camera rises and tilts smoothly toward the sky")
	check(city.world_map.atlas.clouds[0].node.position != cloud, "clouds keep moving during the cinematic camera flight")
	await finish_flight("out")
	check(city.world_map.visible and not city.world.visible and not city.horizon.visible and not city.orbit.enabled, "arrival suspends covered city rendering and camera")
	check(not city.world_map.transitioning and not city.world_map.atlas.cinematic and absf(city.world_map.atlas.distance - 40.0) < .001, "arrival restores interactive regional overview")
	check(city.hud.modulate.a == 1.0 and city.world_map.get_node("Themed").modulate.a == 1.0, "temporary fades and cloud veil are completely cleared")
	check(same_city(before, city.core.simulation.snapshot(true)) and city.core.query("world") == world_before, "ascent and live atlas preserve all native city/world observations")
	await capture("arrived")
	# Orbit the atlas before returning; this must not alter the city camera restore.
	city.world_map.atlas.yaw = .4; city.world_map.atlas.distance = 30; city.world_map.atlas.desired_distance = 30
	city.world_map.atlas.refresh_camera()
	key(KEY_ESCAPE)
	check(city.world_flight.phase == "in" and city.world_map.visible and not city.orbit.enabled, "Escape starts a live descent with input held")
	await capture("in-00")
	await finish_flight("in")
	check(not city.world_map.visible and not city.world_map.atlas.active and city.world_map.atlas.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "return stops hidden atlas rendering")
	check(city.world.visible == world_visible and city.horizon.visible == horizon_visible and city.orbit.enabled, "return restores exact original city visibility and camera input")
	check(pose_matches(saved), "return restores the original city target, zoom, orbit and tilt")
	check(same_city(before, city.core.simulation.snapshot(true)) and city.state.paused, "a paused city remains paused with native contents unchanged after descent")
	await capture("returned")
	var audio := root.get_node("GameAudio")
	var muted: bool = audio.muted()
	key(KEY_M)
	check(not city.world_map.visible and audio.muted() != muted, "M retains the established mute shortcut")
	audio.set_muted(muted)
	# A pinch crossing the same threshold uses the same path; Escape during the
	# first ascent queues a single safe descent rather than leaking pause/input.
	pinch(.5)
	check(city.world_flight.phase == "out", "trackpad pinch crossing the city limit starts the same flight")
	key(KEY_ESCAPE); key(KEY_ESCAPE)
	check(city.world_flight.close_after_arrival, "Escape during ascent queues one return")
	await finish_flight()
	check(not city.world_map.visible and pose_matches(saved) and city.state.paused, "interrupted ascent returns safely without camera or pause drift")
	# Existing dialogs own scroll and keyboard focus; no hidden travel from edits.
	var dialog = preload("res://ui/interface_dialog.gd").open(city.hud)
	await frames()
	pinch(.5)
	check(not city.world_flight.busy() and not city.world_map.visible, "an interface dialog suppresses the world-zoom transition")
	city.open_world()
	check(not city.world_map.visible, "direct world actions also respect the existing modal dialog")
	dialog.get_cancel_button().pressed.emit(); await frames()
	# Commands already accepted in the city are retained in order, but a queued
	# resume cannot release the native hold halfway through this presentation.
	city.core.send("pause 0")
	wheel(MOUSE_BUTTON_WHEEL_DOWN)
	var queued_hold: Dictionary = city.core.simulation.snapshot(true)
	await finish_flight()
	check(city.core.commands == ["pause 0"] and city.core.simulation.snapshot(true).time == queued_hold.time and city.state.paused, "accepted city commands wait without releasing the atlas hold")
	city.world_map.close(); await finish_flight(); await frames(10)
	check(not city.state.paused and city.core.commands.is_empty(), "accepted city commands resume in their original order after return")
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	# Running-state read must come from the core even before its UI snapshot polls.
	city.core.query("pause 0")
	key(KEY_F2)
	check(city.world_resume and city.core.simulation.snapshot(true).paused and city.world_flight.phase == "out", "F2 shares the flight and holds a running city synchronously")
	var held: Dictionary = city.core.simulation.snapshot(true)
	await finish_flight()
	check(city.core.simulation.snapshot(true).time == held.time, "native time stays fixed through the complete running-city ascent")
	click(city.world_map.get_node("%Back"))
	check(city.world_flight.phase == "in", "Back to city uses the matching descent")
	await finish_flight()
	check(not city.core.simulation.snapshot(true).paused and pose_matches(saved), "running state resumes only after the exact city view returns")
	city.core.snapshot_received.emit(city.core.query("pause 1"))
	print("WORLD_ATLAS_REVIEW ", JSON.stringify({"passed": okay, "checks": checks, "language": language, "mode": "flight", "captures": images, "capture_files": captured, "renderer": RenderingServer.get_current_rendering_method()}))
	city.free(); await frames(2); quit(0 if okay else 1)
