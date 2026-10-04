extends Node
# Presentation-only travel between the two live 3D views. main.gd owns the
# synchronous native hold and exact visibility/running-state restoration.
signal arrived
signal returned

const OUT_SECONDS := 1.55
const IN_SECONDS := 1.20
const VeilShader = preload("res://shaders/world_flight.gdshader")
var city: Node
var phase := ""
var progress := 0.0
var age := 0.0
var city_view: Dictionary = {}
var atlas_view: Dictionary = {}
var close_after_arrival := false
var overlay := CanvasLayer.new()
var veil := ColorRect.new()
var veil_material := ShaderMaterial.new()
var hud_colour := Color.WHITE
var map_colour := Color.WHITE
var map_details: Array[CanvasItem] = []

func _ready() -> void:
	overlay.layer = 45
	add_child(overlay)
	overlay.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil_material.shader = VeilShader
	veil.material = veil_material
	veil.visible = false
	set_process(false)

func busy() -> bool:
	return phase != ""

func pose(camera_rig: Node) -> Dictionary:
	return {"target": camera_rig.target, "distance": camera_rig.distance,
		"yaw": camera_rig.yaw, "pitch": camera_rig.pitch}

func apply_pose(camera_rig: Node, view: Dictionary, regional := false) -> void:
	camera_rig.target = view.target
	camera_rig.distance = view.distance
	camera_rig.yaw = view.yaw
	camera_rig.pitch = view.pitch
	if regional:
		camera_rig.desired_distance = view.distance
		camera_rig.refresh_camera()
		camera_rig.camera_changed.emit()
	else:
		camera_rig.refresh()

func high_city_view() -> Dictionary:
	return {"target": city_view.target, "distance": maxf(city_view.distance * 2.8, city.orbit.maximum_distance * 1.5),
		"yaw": city_view.yaw + 7.0, "pitch": 76.0}

func city_anchor() -> Vector3:
	var current: Dictionary = city.world_map.find_city(city.world_map.default_city())
	return city.world_map.atlas.surface_point(Vector2(float(current.x), float(current.y))) if not current.is_empty() else Vector3.ZERO

func begin_open() -> void:
	city_view = pose(city.orbit)
	hud_colour = city.hud.modulate
	map_colour = city.world_map.get_node("Themed").modulate
	map_details.assign([city.world_map.markers, city.world_map.armies_layer,
		city.world_map.get_node("Themed/Margin/Row/Side"), city.world_map.get_node("Themed/Margin/Row/MapFrame/MapBox/AtlasHeading"),
		city.world_map.get_node("Themed/Margin/Row/MapFrame/MapBox/AtlasControls"), city.world_map.get_node("%AtlasHint")])
	# The local city and regional globe have independent scales; the atlas flight
	# originates at the native current-city anchor, never at a guessed Greek town.
	atlas_view = {"target": city_anchor(), "distance": 14.0, "yaw": -.10, "pitch": 1.36}
	city.orbit.dragging = false
	city.orbit.enabled = false
	city.world_map.atlas.dragging = false
	city.world_map.atlas.cinematic = true
	city.world_map.transitioning = true
	close_after_arrival = false
	start("out")

func begin_close() -> void:
	if busy():
		# Escape/F2 during ascent queues one return. Wheel momentum and repeated
		# key presses cannot restart, duplicate or reverse the native hold.
		if phase == "out": close_after_arrival = true
		return
	if city_view.is_empty(): return
	atlas_view = pose(city.world_map.atlas)
	city.world.visible = city.world_render_state.get("world", true)
	city.horizon.visible = city.world_render_state.get("horizon", true)
	apply_pose(city.orbit, high_city_view())
	city.world_map.atlas.dragging = false
	city.world_map.atlas.cinematic = true
	city.world_map.transitioning = true
	start("in")

func start(direction: String) -> void:
	phase = direction
	age = 0.0
	progress = 0.0
	veil.visible = true
	set_process(true)
	frame(0.0)

func smooth(from: float, to: float, value: float) -> float:
	return smoothstep(from, to, value)

func mix_pose(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	return {"target": (from.target as Vector3).lerp(to.target, weight),
		"distance": exp(lerpf(log(from.distance), log(to.distance), weight)),
		"yaw": lerpf(from.yaw, to.yaw, weight), "pitch": lerpf(from.pitch, to.pitch, weight)}

func frame(t: float) -> void:
	var map_alpha: float
	var detail_alpha: float
	var hud_alpha: float
	var atlas = city.world_map.atlas
	if phase == "out":
		apply_pose(city.orbit, mix_pose(city_view, high_city_view(), smooth(0.0, .78, t)))
		var regional := {"target": Vector3.ZERO, "distance": 40.0, "yaw": 0.0, "pitch": 1.03}
		apply_pose(atlas, mix_pose(atlas_view, regional, smooth(.18, 1.0, t)), true)
		map_alpha = smooth(.26, .82, t)
		detail_alpha = smooth(.70, 1.0, t)
		hud_alpha = 1.0 - smooth(0.0, .22, t)
	else:
		apply_pose(city.orbit, mix_pose(high_city_view(), city_view, smooth(.16, 1.0, t)))
		var local := {"target": city_anchor(), "distance": 12.0, "yaw": -.10, "pitch": 1.36}
		apply_pose(atlas, mix_pose(atlas_view, local, smooth(0.0, .85, t)), true)
		map_alpha = 1.0 - smooth(.16, .72, t)
		detail_alpha = 1.0 - smooth(0.0, .25, t)
		hud_alpha = smooth(.78, 1.0, t)
	city.world_map.get_node("Themed").modulate = Color(map_colour, map_colour.a * map_alpha)
	for control in map_details: control.modulate.a = detail_alpha
	city.world_map.get_node("Themed/Margin/Row/MapFrame").self_modulate.a = detail_alpha
	city.hud.modulate = Color(hud_colour, hud_colour.a * hud_alpha)
	veil_material.set_shader_parameter("flight", t if phase == "out" else 1.0 - t)
	veil_material.set_shader_parameter("amount", smooth(.10, .38, t) * (1.0 - smooth(.55, .93, t)))

func _process(delta: float) -> void:
	age += delta
	progress = minf(1.0, age / (OUT_SECONDS if phase == "out" else IN_SECONDS))
	frame(progress)
	if progress < 1.0: return
	var opening := phase == "out"
	phase = ""
	set_process(false)
	veil.visible = false
	city.world_map.transitioning = false
	city.world_map.atlas.cinematic = false
	city.hud.modulate = hud_colour
	city.world_map.get_node("Themed").modulate = map_colour
	for control in map_details: control.modulate.a = 1.0
	city.world_map.get_node("Themed/Margin/Row/MapFrame").self_modulate.a = 1.0
	apply_pose(city.orbit, city_view)
	if opening:
		arrived.emit()
		if close_after_arrival: begin_close()
	else:
		returned.emit()

func _input(event: InputEvent) -> void:
	if not busy(): return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE, KEY_F2]:
		begin_close()
	get_viewport().set_input_as_handled()
