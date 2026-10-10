extends RefCounted
# Street readability for walkers. Presentation only: native positions, routes and the
# core's position track are never changed; the lane offset is added when drawing.
const WalkerCombat = preload("res://scripts/walker_combat.gd")
const Streets = preload("res://scripts/street_layout.gd")
const SCALE := 1.12         # People read better between two-storey houses.
const LANE := .17           # Tiles to the right of the direction of travel, on roads.
const EASE := 5.0           # How quickly a walker drifts into or out of its lane, per second.
const HOVER_PIXELS := 26.0  # How near the mouse a walker's middle must be to be ringed.
var ring := MeshInstance3D.new()
var hovered := -1
var wide_cells := {}
var topology_ready := false

# Index only road-kind changes; field growth and citizen movement never rescan
# the map. Most citizens are on ordinary roads, where four repeated neighborhood
# searches used to dominate their placement cost.
func update_tiles(tiles: Dictionary, changed: Array[Vector2i], initial := false) -> void:
	if initial:
		wide_cells.clear()
		for cell in changed:
			if Streets.kind(tiles, cell) < 2: continue
			wide_cells[cell] = true
			for direction in Streets.SIDES:
				if Streets.kind(tiles, cell + direction) > 0:
					wide_cells[cell + direction] = true
	else:
		var dirty := {}
		for cell in changed:
			dirty[cell] = true
			for direction in Streets.SIDES: dirty[cell + direction] = true
		for cell in dirty:
			if Streets.wide(tiles, cell): wide_cells[cell] = true
			else: wide_cells.erase(cell)
	topology_ready = true

static func wide_cell(city: Node, cell: Vector2i) -> bool:
	var streets = city.get("walker_streets")
	if streets != null and streets.topology_ready:
		return streets.wide_cells.has(cell)
	return Streets.wide(city.tiles, cell)

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
	if not entry.get("perch", {}).is_empty():
		entry.lane = Vector3.ZERO
		entry.lane_raw = Vector3.ZERO
		entry.wide_road = false
		return Vector3.ZERO
	var current: Vector3 = entry.get("lane_raw",entry.get("lane",Vector3.ZERO))
	var target := current
	var planar := Vector3(delta.x, 0, delta.z)
	var revision = city.get("surface_revision")
	if entry.get("road_position") != entry.native_position or entry.get("road_revision", -1) != revision:
		entry.wide_road = wide_road(city, entry.native_position)
		entry.road_position = entry.native_position
		entry.road_revision = revision
	var wide_native: bool = entry.wide_road
	if entry.waterborne or entry.get("god", false) or entry.has("roll") or WalkerCombat.fighting(entry) or not (wide_native or on_road(city, entry.native_position)):
		target = Vector3.ZERO
	elif planar.length_squared() > .00000001:
		target = planar.normalized().cross(Vector3.UP) * LANE
	current = current.lerp(target, clampf(dt * EASE, 0, 1))
	# Keep easing state separate from the positional corner constraint. Otherwise
	# a paused figure at a corner would repeatedly multiply its offset and drift.
	entry.lane_raw = current
	# Wide roads share the same native tile centres as single roads. At a bend or
	# cross-lane turn, the eased right-hand offset must not put feet beyond a kerb.
	if wide_native:
		current = bounded_lane(city,entry.native_position,current)
	entry.lane = current
	return current

static func cell_at(city: Node, position: Vector3) -> Vector2i:
	return Vector2i(roundi(position.x+city.origin.x+(city.extent.x-1)*.5),roundi(-position.z+city.origin.y+(city.extent.y-1)*.5))

static func wide_road(city: Node, position: Vector3) -> bool:
	if wide_cell(city,cell_at(city,position)): return true
	# Rounding a diagonal corner can choose the one unpaved cell beside three
	# paved ones. Use the ground shader's continuous field there, rather than
	# briefly abandoning the lane and heading constraint for that single frame.
	var native := Vector2(position.x+city.origin.x+(city.extent.x-1)*.5,-position.z+city.origin.y+(city.extent.y-1)*.5)
	var lower := Vector2i(floori(native.x),floori(native.y))
	var fraction := native-Vector2(lower)
	var paving := 0.0; var wide := 0.0
	for x in 2:
		for y in 2:
			var cell := lower+Vector2i(x,y)
			var weight: float=(fraction.x if x else 1.0-fraction.x)*(fraction.y if y else 1.0-fraction.y)
			if Streets.kind(city.tiles,cell): paving+=weight
			if wide_cell(city,cell): wide+=weight
	return paving>=.65 and wide>=.35

static func bounded_lane(city: Node, position: Vector3, offset: Vector3) -> Vector3:
	var cell := cell_at(city,position)
	var native := Vector2(position.x+city.origin.x+(city.extent.x-1)*.5,-position.z+city.origin.y+(city.extent.y-1)*.5)
	# Merge opposing lanes smoothly at diagonal crossings; following the native
	# corner must not snap from one tile's clamped box into the next one's box.
	var corner := minf(absf(native.x-cell.x),absf(native.y-cell.y))
	var shown := position+offset*(1.0-smoothstep(.20,.46,corner))
	var x: float = shown.x+city.origin.x+(city.extent.x-1)*.5
	var y: float = -shown.z+city.origin.y+(city.extent.y-1)*.5
	# Only outside borders need clamping; connected tiles stay continuous.
	if not border_connected(city.tiles,cell,Vector2i.LEFT): x=maxf(x,cell.x-Streets.CLEAR_HALF_WIDTH)
	if not border_connected(city.tiles,cell,Vector2i.RIGHT): x=minf(x,cell.x+Streets.CLEAR_HALF_WIDTH)
	if not border_connected(city.tiles,cell,Vector2i.UP): y=maxf(y,cell.y-Streets.CLEAR_HALF_WIDTH)
	if not border_connected(city.tiles,cell,Vector2i.DOWN): y=minf(y,cell.y+Streets.CLEAR_HALF_WIDTH)
	return Vector3(x-position.x-city.origin.x-(city.extent.x-1)*.5,0,-y-position.z+city.origin.y+(city.extent.y-1)*.5)

static func border_connected(tiles: Dictionary, cell: Vector2i, direction: Vector2i) -> bool:
	var across := Vector2i(-direction.y,direction.x)
	return Streets.kind(tiles,cell+direction)>0 or Streets.kind(tiles,cell+direction+across)>0 or Streets.kind(tiles,cell+direction-across)>0

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
