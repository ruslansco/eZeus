extends Control
# The city minimap: native terrain, roads and buildings on a fixed 45-degree chart,
# with a small camera heading marker. Clicking or dragging reports native cells;
# main.gd owns the camera and supplies its target and ground footprint.

signal jump_requested(cell: Vector2)

const WATER := 4
const WATER_COLOUR := Color(.10, .31, .34)
const SAND_COLOUR := Color(.74, .64, .44)
const MEADOW_COLOUR := Color(.40, .50, .26)
const FOREST_COLOUR := Color(.24, .36, .20)
const CLEARED_COLOUR := Color(.55, .55, .32)
const STONE_COLOUR := Color(.52, .52, .50)
const ROAD_COLOUR := Color(.93, .85, .62)
const HOUSE_COLOUR := Color(.90, .60, .38)
const BUILDING_COLOUR := Color(.95, .93, .86)

var origin := Vector2i.ZERO
var extent := Vector2i.ZERO
var terrain: Image
var composed: Image
var texture: ImageTexture
var view: PackedVector2Array = PackedVector2Array()
var dragging := false
var draws := 0
var camera_cell := Vector2.ZERO
var camera_yaw := 0.0
var camera_known := false
var occupied_radius := 1.0

func _ready() -> void:
	clip_contents = true
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://ui/circular_map.gdshader")
	material = mask

func ground_colour(tile: Array) -> Color:
	var flags := int(tile[3])
	if int(tile[4]):
		return WATER_COLOUR if flags & WATER else ROAD_COLOUR
	if flags & WATER:
		return WATER_COLOUR
	if flags & (64 | 128 | 256 | 512 | 1024 | 4096 | 8192):
		return STONE_COLOUR
	if flags & 16:
		return FOREST_COLOUR
	if flags & 32:
		return CLEARED_COLOUR
	if flags & 8:
		return MEADOW_COLOUR
	return SAND_COLOUR

# Full rebuild from the tile dictionary of a city (the snapshot's tiles keyed by absolute cell).
func set_map(tiles: Dictionary, map_origin: Vector2i, map_extent: Vector2i) -> void:
	origin = map_origin
	extent = map_extent
	terrain = Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	terrain.fill(Color(0, 0, 0, 0))
	occupied_radius = 1.0
	for cell in tiles:
		var pixel := Vector2i(cell.x - origin.x, extent.y - 1 - (cell.y - origin.y))
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < extent.x and pixel.y < extent.y:
			terrain.set_pixelv(pixel, ground_colour(tiles[cell]))
			occupied_radius = maxf(occupied_radius,(Vector2(pixel)+Vector2(.5,.5)-Vector2(extent)*.5).length()+sqrt(2.0)*.5)
	composed = terrain.duplicate()
	texture = ImageTexture.create_from_image(composed)
	queue_redraw()

func paint_tiles(tiles: Dictionary, changed: Array) -> void:
	if terrain == null:
		return
	for cell in changed:
		if not tiles.has(cell):
			continue
		var pixel := Vector2i(cell.x - origin.x, extent.y - 1 - (cell.y - origin.y))
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < extent.x and pixel.y < extent.y:
			var colour := ground_colour(tiles[cell])
			terrain.set_pixelv(pixel, colour)
			composed.set_pixelv(pixel, colour)
	texture.update(composed)
	queue_redraw()

# Repaints the building layer over the terrain. `buildings` are the snapshot's building dictionaries.
func set_buildings(buildings: Array) -> void:
	if terrain == null:
		return
	composed.copy_from(terrain)
	for entry in buildings:
		var asset := str(entry.asset)
		if asset in ["native_marker", "terrain_road"]:
			continue
		var colour := HOUSE_COLOUR if asset.begins_with("common_house") or asset.begins_with("elite_house") else BUILDING_COLOUR
		for dy in int(entry.h):
			for dx in int(entry.w):
				var pixel := Vector2i(int(entry.x) + dx - origin.x, extent.y - 1 - (int(entry.y) + dy - origin.y))
				if pixel.x >= 0 and pixel.y >= 0 and pixel.x < extent.x and pixel.y < extent.y:
					composed.set_pixelv(pixel, colour)
	texture.update(composed)
	queue_redraw()

# The camera's ground footprint, as tile coordinates (x right, y up like the tiles).
func set_view(polygon: PackedVector2Array) -> void:
	view = polygon
	queue_redraw()

func set_camera(cell: Vector2, yaw_degrees: float) -> void:
	camera_cell = cell
	camera_yaw = yaw_degrees
	camera_known = true
	queue_redraw()

# The map is drawn turned 45 degrees, the way the default camera looks at it: the native map is a diamond in tile
# coordinates, so this makes it upright inside the circle. The camera marker follows the same turn.
const ROTATION := PI / 4.0

func map_scale() -> float:
	# Cover the circular viewport with the upright native chart; the shader crops its corners.
	return maxf(1.0, minf(size.x, size.y)) / (occupied_radius * 1.25)

func cell_to_point(cell: Vector2) -> Vector2:
	var local := Vector2(cell.x - origin.x + .5 - extent.x * .5, -(cell.y - origin.y + .5 - extent.y * .5))
	return size * .5 + local.rotated(ROTATION) * map_scale()

func point_to_cell(point: Vector2) -> Vector2:
	var local := ((point - size * .5) / map_scale()).rotated(-ROTATION)
	return Vector2(origin.x + extent.x * .5 + local.x - .5, origin.y + extent.y * .5 - local.y - .5)

func _draw() -> void:
	draws += 1
	if material != null:
		material.set_shader_parameter("center", get_global_rect().get_center())
		material.set_shader_parameter("radius", minf(size.x, size.y) * .5)
	draw_circle(size * .5, minf(size.x, size.y) * .5, Color(.055, .18, .24, .96))
	if texture == null:
		return
	draw_set_transform(size * .5, ROTATION, Vector2.ONE * map_scale())
	draw_texture_rect(texture, Rect2(-Vector2(extent) * .5, Vector2(extent)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if camera_known:
		var focus := cell_to_point(camera_cell)
		var forward := Vector2(-sin(deg_to_rad(camera_yaw)), -cos(deg_to_rad(camera_yaw))).rotated(ROTATION)
		var side := Vector2(-forward.y, forward.x)
		# Screen-sized navigation chevron: zoom never produces a giant viewport box.
		draw_circle(focus, 13, Color(.20, .76, .94, .07))
		draw_circle(focus, 9, Color(.20, .76, .94, .16))
		var marker := PackedVector2Array([
			focus + forward * 8,
			focus - forward * 5 + side * 4.5,
			focus - forward * 2,
			focus - forward * 5 - side * 4.5,
		])
		var edge := marker.duplicate()
		edge.append(marker[0])
		draw_polyline(edge, Color(.025, .10, .14, .92), 3, true)
		draw_colored_polygon(marker, Color(.87, .98, 1))
		draw_polyline(edge, Color(.62, .90, .98), .8, true)
	# The gold rim of the round map, inside the circular mask (colours from the theme's MapCard).
	var radius := minf(size.x, size.y) * .5
	draw_arc(size * .5, radius - 3.5, 0, TAU, 128, get_theme_color("rim_shadow", "MapCard"), 2.0, true)
	draw_arc(size * .5, radius - 1.6, 0, TAU, 128, get_theme_color("rim", "MapCard"), 2.6, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		dragging = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if event.pressed:
			jump_requested.emit(point_to_cell(event.position))
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		jump_requested.emit(point_to_cell(event.position))
		accept_event()

func _has_point(point: Vector2) -> bool:
	return point.distance_to(size*.5) <= minf(size.x,size.y)*.5
