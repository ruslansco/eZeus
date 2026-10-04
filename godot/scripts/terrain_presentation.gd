extends RefCounted

const WATER := 4
const MAX_DISTANCE := 8.0
var origin := Vector2i.ZERO
var extent := Vector2i.ZERO
var field_image: Image
var road_image: Image
var mineral_image: Image
var pattern_image: Image
var field_texture: ImageTexture
var road_texture: ImageTexture
var mineral_texture: ImageTexture
var pattern_texture: ImageTexture
var ground_material := ShaderMaterial.new()
var water_material := ShaderMaterial.new()
var flags_cache: Dictionary = {}
var coastline_rebuilds := 0

func _init() -> void:
	ground_material.shader = preload("res://shaders/ground.gdshader")
	water_material.shader = preload("res://shaders/water.gdshader")
	for surface in [ground_material, water_material]:
		surface.set_shader_parameter("surface_noise", preload("res://assets/terrain/surface_noise.tres"))
	ground_material.set_shader_parameter("ground_normal", preload("res://assets/terrain/ground_normal.tres"))

func update(tiles: Dictionary, map_origin: Vector2i, map_extent: Vector2i, changed: Array[Vector2i]) -> void:
	var initial := field_image == null or map_extent != extent or map_origin != origin
	if initial:
		origin = map_origin
		extent = map_extent
		field_image = Image.create(extent.x, extent.y, false, Image.FORMAT_RGBAH)
		# R road, G dressed paving, B median bed, A boulevard (see road_pattern).
		road_image = Image.create(extent.x, extent.y, false, Image.FORMAT_RGBA8)
		mineral_image = Image.create(extent.x,extent.y,false,Image.FORMAT_RGBA8)
		pattern_image = Image.create(extent.x,extent.y,false,Image.FORMAT_RGBA8)
		flags_cache.clear()
	var coast_changed := initial
	for cell in changed:
		var flags := int(tiles[cell][3])
		if not flags_cache.has(cell) or (int(flags_cache[cell]) & WATER) != (flags & WATER):
			coast_changed = true
		flags_cache[cell] = flags
	if coast_changed:
		rebuild_coast(tiles)
	for cell in changed:
		var tile: Array = tiles[cell]
		var pixel := cell - origin
		var flags := int(tile[3])
		var distance := field_image.get_pixelv(pixel).r
		# Fertile meadow (bit 8) shares the plain grassland; a weight of its own showed
		# as flat green patches with a dark forest-coloured fringe where it blended.
		var vegetation := 0.75 if flags & 16 else (0.3 if flags & 32 else 0.0)
		# Deposits no longer stain the ground: outcrop models mark them and quarries get
		# their own floor from the mineral field. B stays for future rock ground.
		var stone := 0.0
		var sand := 1.0 if flags & 2 else 0.0
		field_image.set_pixelv(pixel, Color(distance, vegetation, stone, sand))
		mineral_image.set_pixelv(pixel,mineral_color(flags))
		pattern_image.set_pixelv(pixel,mineral_pattern(flags))
	# Dressed paving depends on neighbouring medians, so changed cells refresh them too.
	var streets := {}
	for cell in changed:
		streets[cell] = true
		if not initial:
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if tiles.has(cell + offset):
					streets[cell + offset] = true
	for cell in streets:
		road_image.set_pixelv(cell - origin, road_pattern(tiles, cell))
	if initial:
		field_texture = ImageTexture.create_from_image(field_image)
		road_texture = ImageTexture.create_from_image(road_image)
		mineral_texture = ImageTexture.create_from_image(mineral_image)
		pattern_texture = ImageTexture.create_from_image(pattern_image)
		for surface in [ground_material, water_material]:
			surface.set_shader_parameter("terrain_data", field_texture)
			surface.set_shader_parameter("map_extent", Vector2(extent))
		ground_material.set_shader_parameter("road_data", road_texture)
		ground_material.set_shader_parameter("mineral_data",mineral_texture)
		ground_material.set_shader_parameter("mineral_pattern",pattern_texture)
	else:
		field_texture.update(field_image)
		road_texture.update(road_image)
		mineral_texture.update(mineral_image)
		pattern_texture.update(pattern_image)

static func road_kind(tile: Array) -> int:
	# Snapshot column 8: 1 road, 2 avenue, 3 boulevard. Older snapshots only say "road".
	if tile.is_empty() or not int(tile[4]):
		return 0
	return int(tile[8]) if tile.size() >= 9 else 1

func road_pattern(tiles: Dictionary, cell: Vector2i) -> Color:
	# An avenue or boulevard tile is the planted median the native tool lays beside its
	# streets (avenue: median + one street; boulevard: a street on each side). The streets
	# next to a median get dressed paving, so the whole avenue reads as one grand street.
	var kind := road_kind(tiles.get(cell, []))
	if kind == 0:
		return Color(0, 0, 0, 0)
	var dressed := kind >= 2
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		dressed = dressed or road_kind(tiles.get(cell + offset, [])) >= 2
	# R road, G dressed paving, B median bed, A boulevard (a lusher bed with flowers).
	return Color(1, 1 if dressed else 0, 1 if kind >= 2 else 0, 1 if kind == 3 else 0)

func mineral_color(flags: int) -> Color:
	# Only quarries get a floor: sawn white or black marble, whose inner cells have no
	# props. Other deposits sit on the green ground; their outcrop models mark them.
	if flags & 8192:
		return Color(.11,.12,.12,1)
	if flags & 1024:
		return Color(.74,.73,.68,1)
	return Color(0,0,0,0)

func mineral_pattern(flags: int) -> Color:
	# R marks the sawn quarry blocks in ground.gdshader.
	if flags & (1024|8192):
		return Color(1,0,0,0)
	return Color(0,0,0,0)

func rebuild_coast(tiles: Dictionary) -> void:
	coastline_rebuilds += 1
	var land := distances(tiles, false)
	var water := distances(tiles, true)
	# Extend the nearest actual terrain class through unused texture cells only.
	# No geometry/collision is emitted there; irregular map holes remain holes.
	for y in range(extent.y):
		for x in range(extent.x):
			var index := y * extent.x + x
			var tile: Array = tiles.get(origin + Vector2i(x, y), [])
			var wet: bool = (int(tile[3]) & WATER) != 0 if not tile.is_empty() else water[index] < land[index]
			var distance := minf(MAX_DISTANCE, maxf(0.5, (land[index] if wet else water[index]) - 0.5)) * (1 if wet else -1)
			var old := field_image.get_pixel(x, y)
			old.r = distance
			field_image.set_pixel(x, y, old)

func distances(tiles: Dictionary, to_water: bool) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	values.resize(extent.x * extent.y)
	values.fill(MAX_DISTANCE + 1.0)
	for cell in tiles:
		if bool(int(tiles[cell][3]) & WATER) == to_water:
			var pixel: Vector2i = cell - origin
			values[pixel.y * extent.x + pixel.x] = 0.0
	# Bounded two-pass chamfer transform: linear time, including diagonal shores.
	for direction in [1, -1]:
		for y in range(0 if direction == 1 else extent.y - 1, extent.y if direction == 1 else -1, direction):
			for x in range(0 if direction == 1 else extent.x - 1, extent.x if direction == 1 else -1, direction):
				var index := y * extent.x + x
				var best := values[index]
				var nx: int = x - direction
				var ny: int = y - direction
				if nx >= 0 and nx < extent.x:
					best = minf(best, values[y * extent.x + nx] + 1.0)
				if ny >= 0 and ny < extent.y:
					best = minf(best, values[ny * extent.x + x] + 1.0)
					for diagonal in [x - 1, x + 1]:
						if diagonal >= 0 and diagonal < extent.x:
							best = minf(best, values[ny * extent.x + diagonal] + 1.4142135624)
				values[index] = best
	return values

func water_height(tiles: Dictionary, cell: Vector2i) -> Variant:
	var tile: Array = tiles.get(cell, [])
	if tile.is_empty():
		return null
	if int(tile[3]) & WATER:
		return float(tile[2])
	# A one-cell presentation apron lets the contour round native tile corners.
	for y in range(-1, 2):
		for x in range(-1, 2):
			var neighbor: Array = tiles.get(cell + Vector2i(x, y), [])
			if not neighbor.is_empty() and int(neighbor[3]) & WATER:
				return float(neighbor[2])
	return null
