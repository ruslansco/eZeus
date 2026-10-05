extends Node3D

signal world_zoom_requested

const PlaySettings = preload("res://scripts/play_settings.gd")

var camera := Camera3D.new()
var yaw := 45.0
var pitch := 49.0
var distance := 33.0
var target := Vector3.ZERO
var bounds := Vector2(18, 18)
var maximum_distance := 65.0
var dragging := false
var enabled := true
# Height of the land under a world x/z position, supplied by the city (a flat world at y = 0 until set).
# The orbit centre follows it, and zoom is anchored on the terrain surface rather than on y = 0.
var ground_height := Callable()
const GROUND_EASE := 9.0
const MAP_ZOOM_SCALE := 1.05
# The closest the player can zoom: about ten tiles of ground fill the view, so a god (3.5 tall) takes
# well under half of it. Closer than this the models' faces and hands outgrow the detail they carry.
# Only player input is held to it (wheel, pinch, Home, a new map); reviewers and validators may still set
# `distance` directly for close-ups.
const MINIMUM_DISTANCE := 10.0

func configure_map(extent: Vector2i) -> void:
	bounds = Vector2(extent)*.5
	maximum_distance = maxf(60.0, maxf(extent.x,extent.y)*MAP_ZOOM_SCALE)
	distance = clampf(distance,MINIMUM_DISTANCE,maximum_distance)

func overview(extent: Vector2i) -> void:
	target = Vector3.ZERO
	distance = clampf(maxf(extent.x,extent.y)*.95,MINIMUM_DISTANCE,maximum_distance)
	snap_to_ground()

func _ready() -> void:
	add_child(camera)
	camera.current = true
	camera.fov = 48.0
	camera.near = .1
	camera.far = 2000.0
	refresh()

func refresh() -> void:
	var a := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	camera.position = target + Vector3(sin(a) * cos(p), sin(p), cos(a) * cos(p)) * distance
	camera.look_at(target, Vector3.UP)

func step_orbit(axis: float, dt: float) -> void:
	yaw = fposmod(yaw + axis * 65.0 * dt * PlaySettings.turn_scale(), 360.0)
	refresh()

func adjust_pitch(degrees: float) -> void:
	pitch = clampf(pitch + degrees, 25.0, 75.0)
	refresh()

func step_tilt(axis: float, dt: float) -> void:
	adjust_pitch(axis * 35.0 * dt * PlaySettings.turn_scale())

func pan_vector(input: Vector2) -> Vector3:
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	forward.y = 0
	return right * input.x + forward.normalized() * input.y

func ground_point(screen: Vector2, height: float = 0.0) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if abs(direction.y) < .00001:
		return null
	var t := (height - origin.y) / direction.y
	return origin + direction * t if t > 0 else null

func height_at(x: float, z: float) -> float:
	return float(ground_height.call(x, z)) if ground_height.is_valid() else 0.0

# The first point where the ray under a screen position meets the terrain surface, or null.
func terrain_point(screen: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var step := clampf(distance * .02, .25, 1.0)
	var reach := distance * 4.0 + 80.0
	var previous := 0.0
	var t := 0.0
	while t <= reach:
		var point := origin + direction * t
		if point.y <= height_at(point.x, point.z):
			var near := previous
			var far := t
			for iteration in 18:
				var middle := (near + far) * .5
				var probe := origin + direction * middle
				if probe.y <= height_at(probe.x, probe.z):
					far = middle
				else:
					near = middle
			var hit := origin + direction * far
			hit.y = height_at(hit.x, hit.z)
			return hit
		previous = t
		t += step
	return null

func snap_to_ground() -> void:
	target.y = height_at(target.x, target.z)
	refresh()

func zoom_at(screen: Vector2, factor: float) -> void:
	# Only an outward player zoom crossing the city limit opens the atlas.
	# Home/configure and isolated camera users retain the bounded overview.
	if enabled and factor > 1.0 and distance * factor > maximum_distance and world_zoom_requested.has_connections():
		world_zoom_requested.emit()
		if not enabled:
			return
	var before = terrain_point(screen)
	distance = clampf(distance * factor, MINIMUM_DISTANCE, maximum_distance)
	snap_to_ground()
	if before != null:
		# Slide the orbit centre over the ground until the same surface point is under the cursor.
		# The surface is not a plane, so one correction is not exact; a few settle it.
		for iteration in 5:
			var after = terrain_point(screen)
			if after == null:
				break
			var error: Vector3 = before - after
			if Vector2(error.x, error.z).length() < .0005:
				break
			target.x += error.x
			target.z += error.z
			clamp_target()
			snap_to_ground()
	refresh()

func clamp_target() -> void:
	target.x = clampf(target.x, -bounds.x, bounds.x)
	target.z = clampf(target.z, -bounds.y, bounds.y)

func _process(dt: float) -> void:
	if not enabled:
		return
	var access:=get_tree().root.get_node_or_null("UiAccess")
	if access!=null and access.dialog_open:return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	step_orbit(Input.get_axis("orbit_left", "orbit_right"), dt)
	step_tilt(Input.get_axis("tilt_down", "tilt_up"), dt)
	var move := Vector2(Input.get_axis("pan_left", "pan_right"), Input.get_axis("pan_back", "pan_forward"))
	if move.length_squared() > 0:
		target += pan_vector(move.normalized()) * dt * distance * .42 * PlaySettings.pan_scale() * (2.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		clamp_target()
		refresh()
	# The orbit centre eases onto the ground so tilting and orbiting pivot on the surface.
	var ground := height_at(target.x, target.z)
	if absf(target.y - ground) > .0005:
		target.y = lerpf(target.y, ground, 1.0 - exp(-GROUND_EASE * dt))
		refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	var access:=get_tree().root.get_node_or_null("UiAccess")
	if access!=null and access.dialog_open:return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit: return
	# Godot passes wheel and gesture events on from a panel whose list cannot scroll any further
	# (mouse_force_pass_scroll_events), so over the HUD they must not zoom or pan the map.
	var scroll: bool = event is InputEventGesture or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT])
	if scroll and get_viewport().gui_get_hovered_control() != null: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(event.position, pow(.9, PlaySettings.zoom_scale()))
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(event.position, pow(1.1, PlaySettings.zoom_scale()))
	if event is InputEventMouseMotion and dragging:
		yaw = fposmod(yaw - event.relative.x * .25 * PlaySettings.turn_scale(), 360.0)
		adjust_pitch(event.relative.y * .2 * PlaySettings.turn_scale())
		refresh()
	# Trackpads have no middle button or wheel: pinch zooms, two-finger scroll pans (content follows
	# the fingers) and Option + two-finger scroll orbits and tilts.
	if event is InputEventMagnifyGesture:
		zoom_at(event.position, 1.0 / clampf(event.factor, .5, 2.0))
	if event is InputEventPanGesture:
		if Input.is_key_pressed(KEY_ALT):
			yaw = fposmod(yaw - event.delta.x * 2.0, 360.0)
			adjust_pitch(event.delta.y * 1.5)
		else:
			target += pan_vector(Vector2(event.delta.x, -event.delta.y)) * distance * .012
			clamp_target()
			snap_to_ground()
