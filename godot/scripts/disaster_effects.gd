extends Node3D
# What the SDL view draws for the engine's disasters, from the terrain changes they make (tile by tile, the front of a tidal wave, a
# lava flow, an earthquake or a landslide): white surf and spray sweeping over the land a tidal wave takes, lava blobs thrown in arcs
# that land in a glow with smoke, dust and falling stones over the ground an earthquake cracks, dust and tumbling stones where a
# landslide shifts the hillside. Purely presentation: the terrain, the collapses and the sounds are the engine's, and nothing here
# touches the simulation. Fed by main.gd's tile loop (`note`, then `flush`) and `note_alert`; bounded MultiMeshes used as ring buffers.

const FLAT := preload("res://shaders/disaster_flat.gdshader")
const BILLBOARD := preload("res://shaders/disaster_billboard.gdshader")
const PROJECTILE := preload("res://shaders/disaster_projectile.gdshader")
const WATER := 4
const QUAKE := 2048
const LAVA := 32768
const CAPACITY := 320
const SLIDE_WINDOW := 90.0
const MAX_NEW := 120

var clock := 0.0
var slide_until := -1.0
var last_alert := 0
var pending: Array = []        # [key, kind] with kind "surge", "recede", "lava", "quake" or "slide"
var surf: MultiMesh
var flash: MultiMesh
var puffs: MultiMesh
var blobs: MultiMesh
var stones: MultiMesh
var falling: MultiMesh
var cursor := {}
var materials: Array[ShaderMaterial] = []
var rng := RandomNumberGenerator.new()
var spawned := 0
var last_cell := Vector2i.ZERO   # the newest tile an effect was drawn on (reviews aim the camera at it)

func _init() -> void:
	name = "DisasterEffects"
	rng.seed = 90210
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var ball := SphereMesh.new()
	ball.radius = .5
	ball.height = 1.0
	ball.radial_segments = 8
	ball.rings = 4
	surf = batch("surf", plane, FLAT, 0, 0.0, 0.0)
	flash = batch("flash", plane, FLAT, 1, 0.0, 0.0)
	puffs = batch("puffs", quad, BILLBOARD, 0, 0.0, 0.0)
	blobs = batch("blobs", ball, PROJECTILE, 0, .85, 2.4)
	stones = batch("stones", ball, PROJECTILE, 1, .8, 1.5)
	falling = batch("falling", ball, PROJECTILE, 2, .55, 5.0)

func batch(label: String, mesh: Mesh, shader: Shader, mode: int, life: float, arc: float) -> MultiMesh:
	var group := MultiMesh.new()
	group.transform_format = MultiMesh.TRANSFORM_3D
	group.use_colors = true
	group.use_custom_data = true
	group.mesh = mesh
	group.instance_count = CAPACITY
	group.visible_instance_count = CAPACITY
	group.custom_aabb = AABB(Vector3(-400, -40, -400), Vector3(800, 120, 800))
	var finish := ShaderMaterial.new()
	finish.shader = shader
	if shader != BILLBOARD:
		finish.set_shader_parameter("mode", mode)
	if shader == PROJECTILE:
		finish.set_shader_parameter("life", life)
		finish.set_shader_parameter("arc", arc)
	materials.append(finish)
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = group
	node.material_override = finish
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	cursor[group] = 0
	# Nothing flies until it is spawned: every instance starts long expired (and scaled to nothing).
	for index in CAPACITY:
		group.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		group.set_instance_custom_data(index, Color(0, 0, -1.0e6, 0) if shader == PROJECTILE else Color(-1.0e6, 1, 0, 0))
	return group

func _process(delta: float) -> void:
	clock += delta
	for finish in materials:
		finish.set_shader_parameter("now", clock)

# The engine raised a landslide (the hillside shifts for a while): altitude changes now are its, not a pyramid's rising ground.
func note_alert(id: int, kind: String) -> void:
	if id <= last_alert:
		return
	last_alert = id
	if kind == "landSlide":
		slide_until = clock + SLIDE_WINDOW

# A small puff of dust at a point (a rock landing).
func dust_at(point: Vector3, size: float) -> void:
	put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), point), Color(.6, .52, .4, .6), Color(clock, .7, .3, rng.randf()))

# One tile of a snapshot, as it was and as it is: what changed decides the effect.
func note(key: Vector2i, old: Array, now_tile: Array) -> void:
	if old.is_empty() or now_tile.is_empty() or pending.size() >= MAX_NEW:
		return
	var before := int(old[3])
	var after := int(now_tile[3])
	if (after & LAVA) != 0 and (before & LAVA) == 0:
		pending.append([key, "lava"])
	elif (after & QUAKE) != 0 and (before & QUAKE) == 0:
		pending.append([key, "quake"])
	elif (after & WATER) != 0 and (before & WATER) == 0:
		pending.append([key, "surge"])
	elif (before & WATER) != 0 and (after & WATER) == 0:
		pending.append([key, "recede"])
	elif int(old[2]) != int(now_tile[2]) and clock < slide_until:
		pending.append([key, "slide"])

# After the whole snapshot is in `tiles`: draw what was noted.
func flush(city) -> void:
	if pending.is_empty():
		return
	var changed := {}
	for entry in pending:
		changed[entry[0]] = true
	for entry in pending:
		var key: Vector2i = entry[0]
		last_cell = key
		match entry[1]:
			"surge": spawn_surge(city, key, changed, false)
			"recede": spawn_surge(city, key, changed, true)
			"lava": spawn_lava(city, key)
			"quake": spawn_quake(city, key)
			"slide": spawn_slide(city, key)
	pending.clear()

func ground(city, key: Vector2i, lift: float) -> Vector3:
	var tile: Array = city.tiles.get(key, [])
	var altitude := float(tile[2]) if not tile.is_empty() else 0.0
	var point: Vector3 = city.world_position(float(key.x), float(key.y), altitude)
	point.y = maxf(point.y, city.terrain_height_world(point.x, point.z)) + lift
	return point

func slot(group: MultiMesh) -> int:
	var index: int = cursor[group]
	cursor[group] = (index + 1) % CAPACITY
	spawned += 1
	return index

func put(group: MultiMesh, transform: Transform3D, colour: Color, custom: Color) -> void:
	var index := slot(group)
	group.set_instance_transform(index, transform)
	group.set_instance_color(index, colour)
	group.set_instance_custom_data(index, custom)

# The foam crest runs along the wave's way: from a neighbour that was already water into the tile (a wave going back, the other way).
func spawn_surge(city, key: Vector2i, changed: Dictionary, recede: bool) -> void:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var near: Vector2i = key + offset
		if not city.tiles.has(near) or changed.has(near):
			continue
		var wet: bool = (int(city.tiles[near][3]) & WATER) != 0
		if wet != recede:
			# Coming in: from the wet neighbour into this tile. Going back: from this tile towards the wet neighbour.
			direction = Vector2(-offset) if not recede else Vector2(offset)
			break
	var turn := atan2(direction.y, direction.x)
	var point := ground(city, key, .1)
	var born := clock + rng.randf() * .1
	put(surf, Transform3D(Basis(Vector3.UP, turn).scaled(Vector3(1.5, 1.0, 1.5)), point), Color(1, 1, 1, 1.0 if not recede else .7), Color(born, 1.0 if not recede else .8, rng.randf(), 0))
	if rng.randf() < .45:
		var spray := point + Vector3(rng.randf_range(-.3, .3), .15, rng.randf_range(-.3, .3))
		put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(.7, 1.1)), spray), Color(.92, .96, .98, .55), Color(born + .15, .9, .7, rng.randf()))

func spawn_lava(city, key: Vector2i) -> void:
	var point := ground(city, key, .12)
	var born := clock + rng.randf() * .1
	for index in 2:
		var angle := rng.randf() * TAU
		var reach := rng.randf_range(1.2, 2.6)
		var landing := point + Vector3(rng.randf_range(-.25, .25), 0, rng.randf_range(-.25, .25))
		var size := rng.randf_range(.22, .38) if index == 0 else rng.randf_range(.12, .2)
		put(blobs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), landing), Color(1, 1, 1, 1), Color(cos(angle) * reach, sin(angle) * reach, born, rng.randf()))
	var landed := born + .85
	put(flash, Transform3D(Basis.IDENTITY.scaled(Vector3(2.0, 1.0, 2.0)), point + Vector3.UP * .02), Color(1.0, .45, .08, .95), Color(landed, .7, 0, 0))
	put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.2), point + Vector3.UP * .3), Color(.2, .17, .15, .5), Color(landed, 1.9, 1.6, rng.randf()))

func spawn_quake(city, key: Vector2i) -> void:
	var point := ground(city, key, .1)
	var born := clock + rng.randf() * .1
	put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(1.3, 2.0)), point + Vector3.UP * .2), Color(.62, .52, .4, .7), Color(born, 1.5, .9, rng.randf()))
	for index in 2:
		var offset := Vector3(rng.randf_range(-.4, .4), 0, rng.randf_range(-.4, .4))
		var size := rng.randf_range(.1, .2)
		var delay := rng.randf() * .35
		put(falling, Transform3D(Basis.IDENTITY.scaled(Vector3(size, size * .8, size)), point + offset), Color(1, 1, 1, 1), Color(0, 0, born + delay, rng.randf()))
		put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .45), point + offset + Vector3.UP * .08), Color(.6, .5, .38, .55), Color(born + delay + .5, .7, .35, rng.randf()))

func spawn_slide(city, key: Vector2i) -> void:
	var point := ground(city, key, .1)
	var born := clock + rng.randf() * .1
	put(puffs, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(1.8, 2.6)), point + Vector3.UP * .25), Color(.58, .49, .37, .75), Color(born, 2.0, 1.0, rng.randf()))
	for index in 3:
		var angle := rng.randf() * TAU
		var reach := rng.randf_range(.8, 1.8)
		var size := rng.randf_range(.1, .22)
		put(stones, Transform3D(Basis.IDENTITY.scaled(Vector3(size, size * .85, size)), point + Vector3(rng.randf_range(-.3, .3), 0, rng.randf_range(-.3, .3))), Color(1, 1, 1, 1), Color(cos(angle) * reach, sin(angle) * reach, born + rng.randf() * .3, rng.randf()))
