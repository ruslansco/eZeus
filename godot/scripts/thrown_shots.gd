extends Node3D
# The arrows, spears and rocks that soldiers, archers, towers and triremes throw, as the SDL view draws them: each flies along the arc
# the engine gave it (the snapshot's `shots`: kind, native launch time, speed and the path's points, announced once at launch by the
# engine's missile observer) in the time the engine gives it (the path's length over the missile's speed, in native milliseconds), so a
# paused or sped-up city shows them paused or fast. An arrow or spear stays stuck in its target for a moment; a rock raises a puff of
# dust. Purely presentation: damage, targets and timing are the engine's. Three bounded MultiMeshes.

const MAX_ACTIVE := 96
const LINGER := 280.0           # native ms an arrow or spear stays where it struck
const SPEED_TO_MS := 40.0       # the engine moves a missile 0.025 tiles per millisecond at speed 1

var shots: Array = []
var last_id := 0
var arrows: MultiMesh
var spears: MultiMesh
var rocks: MultiMesh
var clock := 0.0
var from_clock := 0.0
var to_clock := 0.0
var clock_age := 0.0
var initialized := false
var running := false
var last_sequence := 0
var drawn := 0
var owner_city = null
var launches := 0

func _init() -> void:
	name = "ThrownShots"
	arrows = batch("arrows", shaft_mesh(1.0, .03, .16, Color(.55, .4, .22), Color(.72, .74, .78), Color(.92, .9, .84)))
	spears = batch("spears", shaft_mesh(1.8, .045, .3, Color(.45, .31, .17), Color(.78, .6, .3), Color(.7, .2, .15)))
	var ball := SphereMesh.new()
	ball.radius = .5
	ball.height = 1.0
	ball.radial_segments = 8
	ball.rings = 4
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(.5, .46, .4)
	stone.roughness = 1.0
	ball.material = stone
	rocks = batch("rocks", ball)

func batch(label: String, mesh: Mesh) -> MultiMesh:
	var group := MultiMesh.new()
	group.transform_format = MultiMesh.TRANSFORM_3D
	group.mesh = mesh
	group.instance_count = MAX_ACTIVE
	group.visible_instance_count = 0
	group.custom_aabb = AABB(Vector3(-400, -40, -400), Vector3(800, 120, 800))
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = group
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return group

# A missile lying along -Z with its tip at the origin's front: a shaft, a pointed head and two crossed fletchings, in vertex colours.
static func shaft_mesh(length: float, thickness: float, head: float, wood: Color, metal: Color, fletch: Color) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := thickness * .5
	var tail := length * .5
	var tip := -length * .5
	var neck := tip + head
	# The shaft: a square bar.
	var corners := [Vector3(-half, -half, 0), Vector3(half, -half, 0), Vector3(half, half, 0), Vector3(-half, half, 0)]
	for index in 4:
		var a: Vector3 = corners[index]
		var b: Vector3 = corners[(index + 1) % 4]
		var quad := [Vector3(a.x, a.y, neck), Vector3(b.x, b.y, neck), Vector3(b.x, b.y, tail), Vector3(a.x, a.y, tail)]
		var normal := Vector3((a.x + b.x) * .5, (a.y + b.y) * .5, 0).normalized()
		for pick in [0, 1, 2, 0, 2, 3]:
			surface.set_color(wood)
			surface.set_normal(normal)
			surface.add_vertex(quad[pick])
	# The head: a four-sided point.
	var spread := thickness * 1.7
	var base := [Vector3(-spread, 0, neck), Vector3(0, spread, neck), Vector3(spread, 0, neck), Vector3(0, -spread, neck)]
	for index in 4:
		var a: Vector3 = base[index]
		var b: Vector3 = base[(index + 1) % 4]
		var normal := Vector3((a.x + b.x) * .5, (a.y + b.y) * .5, -.5).normalized()
		for vertex in [Vector3(0, 0, tip), a, b]:
			surface.set_color(metal)
			surface.set_normal(normal)
			surface.add_vertex(vertex)
	# The fletching: two crossed vanes at the tail, drawn from both sides.
	var vane := thickness * 3.0
	var run := head * .9
	for angle in [0.0, PI * .5]:
		var across := Vector3(cos(angle), sin(angle), 0) * vane
		var quad := [Vector3.ZERO + Vector3(0, 0, tail - run), across + Vector3(0, 0, tail - run * .35), across + Vector3(0, 0, tail), Vector3(0, 0, tail)]
		var reverse := [Vector3(0, 0, tail - run), -across + Vector3(0, 0, tail - run * .35), -across + Vector3(0, 0, tail), Vector3(0, 0, tail)]
		for set in [quad, reverse]:
			for pick in [0, 1, 2, 0, 2, 3]:
				surface.set_color(fletch)
				surface.set_normal(Vector3(-sin(angle), cos(angle), 0))
				surface.add_vertex(set[pick])
	surface.index()
	var mesh := surface.commit()
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.roughness = .8
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, finish)
	return mesh

func receive(snapshot: Dictionary, city) -> void:
	owner_city = city
	var target := float(snapshot.get("time", 0))
	var sequence := int(snapshot.get("sequence", last_sequence))
	if initialized and (target < to_clock or sequence < last_sequence):
		shots.clear()
		last_id = 0
		initialized = false
	last_sequence = sequence
	running = bool(snapshot.get("running", false)) and not bool(snapshot.get("blocked", false))
	from_clock = clock if initialized and running and target >= to_clock else target
	to_clock = target
	clock_age = 0.0
	initialized = true
	if not running:
		clock = target
	for event in snapshot.get("shots", []):
		var id := int(event.id)
		if id <= last_id:
			continue
		last_id = id
		launches += 1
		var points: Array = event.path
		var path := PackedVector3Array()
		var lengths := PackedFloat64Array()
		var run := 0.0
		for index in points.size():
			var point: Array = points[index]
			var world: Vector3 = city.world_position(float(point[0]), float(point[1]), float(point[2]))
			world.y = maxf(world.y, city.terrain_height_world(world.x, world.z) + .15)
			if index > 0:
				run += Vector2(float(point[0]) - float(points[index - 1][0]), float(point[1]) - float(points[index - 1][1])).length()
			path.append(world)
			lengths.append(run)
		if run <= 0.0:
			continue
		if shots.size() >= MAX_ACTIVE:
			shots.pop_front()
		shots.append({"path": path, "lengths": lengths, "total": run, "kind": str(event.kind), "born": float(event.time), "duration": maxf(1.0, run * SPEED_TO_MS / maxf(.01, float(event.get("speed", 1)))), "seed": float(id), "struck": false})
	draw(city)

func advance(dt: float) -> void:
	if not initialized:
		return
	clock_age += dt
	clock = lerpf(from_clock, to_clock, clampf(clock_age / .1, 0, 1)) if running else to_clock
	draw(owner_city)

# The point and heading a given fraction of the way along a shot's path (along its ground distance).
static func along(shot: Dictionary, fraction: float) -> Array:
	var path: PackedVector3Array = shot.path
	var lengths: PackedFloat64Array = shot.lengths
	var distance := clampf(fraction, 0.0, 1.0) * float(shot.total)
	for index in range(1, path.size()):
		if distance <= lengths[index] or index == path.size() - 1:
			var span := maxf(lengths[index] - lengths[index - 1], .0001)
			var local := clampf((distance - lengths[index - 1]) / span, 0.0, 1.0)
			return [path[index - 1].lerp(path[index], local), path[index] - path[index - 1]]
	return [path[path.size() - 1], Vector3.FORWARD]

func draw(city) -> void:
	var arrow_count := 0
	var spear_count := 0
	var rock_count := 0
	for index in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[index]
		var age: float = clock - float(shot.born)
		var duration: float = shot.duration
		var stays: bool = shot.kind != "rock"
		if age > duration + (LINGER if stays else 0.0):
			if not bool(shot.struck) and not stays and city != null and city.has_method("model_contract"):
				burst(city, shot)
			shots.remove_at(index)
			continue
		if age < 0.0:
			continue
		var fraction := clampf(age / duration, 0.0, 1.0)
		if fraction >= 1.0 and not bool(shot.struck):
			shot.struck = true
			if not stays and city != null:
				burst(city, shot)
		var here := along(shot, fraction)
		var position: Vector3 = here[0]
		var heading: Vector3 = here[1]
		if heading.length() < .0001:
			heading = Vector3.FORWARD
		match str(shot.kind):
			"arrow":
				if arrow_count < MAX_ACTIVE:
					arrows.set_instance_transform(arrow_count, Transform3D(Basis.looking_at(heading.normalized(), Vector3.UP), position))
					arrow_count += 1
			"spear":
				if spear_count < MAX_ACTIVE:
					spears.set_instance_transform(spear_count, Transform3D(Basis.looking_at(heading.normalized(), Vector3.UP), position))
					spear_count += 1
			_:
				if rock_count < MAX_ACTIVE:
					var turn := Basis.from_euler(Vector3(age * .011 + float(shot.seed), age * .008, age * .013))
					rocks.set_instance_transform(rock_count, Transform3D(turn.scaled(Vector3(.2, .17, .2)), position))
					rock_count += 1
	arrows.visible_instance_count = arrow_count
	spears.visible_instance_count = spear_count
	rocks.visible_instance_count = rock_count
	drawn = arrow_count + spear_count + rock_count

# A rock that lands raises a small puff of dust (the disaster effects' puffs).
func burst(city, shot: Dictionary) -> void:
	shot.struck = true
	var effects = city.get("disaster_effects")
	if effects == null:
		return
	var path: PackedVector3Array = shot.path
	effects.dust_at(path[path.size() - 1], .55)
