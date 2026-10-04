extends RefCounted
# Street readability for walkers. Presentation only: native positions, routes and the
# core's position track are never changed; the lane offset is added when drawing.
const WalkerCombat = preload("res://scripts/walker_combat.gd")
const SCALE := 1.12         # People read better between two-storey houses.
const LANE := .17           # Tiles to the right of the direction of travel, on roads.
const EASE := 5.0           # How quickly a walker drifts into or out of its lane, per second.
const HOVER_PIXELS := 26.0  # How near the mouse a walker's middle must be to be ringed.
var ring := MeshInstance3D.new()
var hovered := -1

func _init() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(.62, .62)
	ring.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/walker_ring.gdshader")
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false

static func person(entry: Dictionary) -> bool:
	return (entry.get("human", false) or entry.get("lod_role", false)) and not entry.get("god", false) and not entry.has("roll")

# Called once when a walker's model is made.
func dress(entry: Dictionary) -> void:
	if person(entry):
		entry.node.scale = Vector3.ONE * SCALE

# The eased sideways offset for this frame: walkers keep to the right of the road, so two
# passing each other no longer overlap. Off roads, in a fight, afloat or in a rite it is zero.
func lane(entry: Dictionary, delta: Vector3, dt: float, city: Node) -> Vector3:
	var current: Vector3 = entry.get("lane", Vector3.ZERO)
	var target := current
	var planar := Vector3(delta.x, 0, delta.z)
	if entry.waterborne or entry.get("god", false) or entry.has("roll") or WalkerCombat.fighting(entry) or not on_road(city, entry.native_position):
		target = Vector3.ZERO
	elif planar.length_squared() > .00000001:
		target = planar.normalized().cross(Vector3.UP) * LANE
	current = current.lerp(target, clampf(dt * EASE, 0, 1))
	entry.lane = current
	return current

static func on_road(city: Node, native_position: Vector3) -> bool:
	var x: float = native_position.x + city.origin.x + (city.extent.x - 1) * .5
	var y: float = -native_position.z + city.origin.y + (city.extent.y - 1) * .5
	var tile: Array = city.tiles.get(Vector2i(roundi(x), roundi(y)), [])
	return not tile.is_empty() and int(tile[4]) != 0

# Rings the person nearest the mouse, if any is close enough on screen. A review passes its own
# screen point, since a window without focus does not move the pointer when it is warped.
func hover(city: Node, point := Vector2.INF) -> void:
	var viewport: Viewport = city.get_viewport()
	var camera: Camera3D = city.orbit.camera
	hovered = -1
	if (point != Vector2.INF or viewport.gui_get_hovered_control() == null) and camera != null:
		var mouse := viewport.get_mouse_position() if point == Vector2.INF else point
		var best := HOVER_PIXELS
		for id in city.walkers:
			var entry: Dictionary = city.walkers[id]
			if not entry.node.visible or not person(entry):
				continue
			var middle: Vector3 = entry.node.global_position + Vector3.UP * .25 * SCALE
			if camera.is_position_behind(middle):
				continue
			var gap := camera.unproject_position(middle).distance_to(mouse)
			if gap < best:
				best = gap
				hovered = id
	ring.visible = hovered >= 0
	if ring.visible:
		ring.global_position = city.walkers[hovered].node.global_position + Vector3.UP * .03
