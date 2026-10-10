extends Node3D
# Read-only native launch/impact events, including shots completed between snapshots.
# Two bounded MultiMeshes; native coordinates/time remain authoritative. Green Hydra
# venom is a cosmetic finish, never an added poison rule or persistent damage area.

const SHADER = preload("res://shaders/monster_puff.gdshader")
const MAX_SHOTS := 32
const MAX_BURSTS := 64
const MAX_PUFFS := 512
const MAX_DEBRIS := 128
const MONSTERS := ["walker_calydonianboar", "walker_cerberus", "walker_chimera", "walker_cyclops", "walker_dragon", "walker_echidna", "walker_harpies", "walker_hector", "walker_hydra", "walker_kraken", "walker_maenads", "walker_medusa", "walker_minotaur", "walker_scylla", "walker_sphinx", "walker_talos", "walker_satyr"]

var shots: Dictionary = {}
var bursts: Array = []
var actions: Dictionary = {}
var last_event := 0
var last_sequence := 0
var clock := 0.0
var from_clock := 0.0
var to_clock := 0.0
var clock_age := 0.0
var initialized := false
var running := false
var puffs: MultiMesh
var debris: MultiMesh
var puff_count := 0
var debris_count := 0
var launches := 0
var impacts := 0
var collapses := 0
var minimum := Vector3.ZERO
var maximum := Vector3.ZERO

func _init() -> void:
	name = "MonsterEffects"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var finish := ShaderMaterial.new()
	finish.shader = SHADER
	puffs = make_batch(quad, finish, MAX_PUFFS, true)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var stone := StandardMaterial3D.new()
	stone.vertex_color_use_as_albedo = true
	stone.roughness = 1.0
	debris = make_batch(box, stone, MAX_DEBRIS, false)

func make_batch(mesh: Mesh, finish: Material, capacity: int, custom: bool) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.use_custom_data = custom
	batch.mesh = mesh
	batch.instance_count = capacity
	batch.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = finish
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return batch

static func tint_for(asset: String) -> Color:
	return Color(.46, .85, .13) if asset == "walker_hydra" else Color(1.0, .35, .10)

static func mouth_height(asset: String) -> float:
	return 1.52 if asset == "walker_hydra" else .7

static func mouth_forward(asset: String) -> float:
	return .94 if asset == "walker_hydra" else .2

func head_origin(city, asset: String, near: Vector3, head: int, fallback: Vector3) -> Vector3:
	if not city.has_method("model_contract"):
		return fallback
	var probes: Dictionary = city.model_contract(asset).get("monster", {}).get("pose_probes", {})
	if probes.is_empty():
		return fallback
	var nearest: Dictionary = {}
	var distance := 1.1
	for entry in city.walkers.values():
		if entry.asset != asset:
			continue
		var offset: Vector3 = entry.node.global_position - near
		var gap := Vector2(offset.x,offset.z).length()
		if gap < distance:
			distance = gap; nearest = entry
	if nearest.is_empty():
		return fallback
	var clip: String = "fight2" if int(nearest.action) == 5 else "fight" if int(nearest.action) == 4 else "idle"
	var count := 12 if clip == "idle" else 24
	var phase := fposmod(float(nearest.get("clip_time",0.0))*10.0, float(count)) if nearest.get("clip", "") == clip else 0.0
	var a: Array = probes.get("%s_%02d" % [clip,int(phase)],probes.get("idle_00",{})).get("mouths", [])
	var b: Array = probes.get("%s_%02d" % [clip,(int(phase)+1)%count],{}).get("mouths", a)
	if a.is_empty() or b.size() != a.size():
		return fallback
	head = posmod(head, a.size())
	var local := Vector3(float(a[head][0]),float(a[head][1]),float(a[head][2])).lerp(Vector3(float(b[head][0]),float(b[head][1]),float(b[head][2])),phase-floorf(phase))
	return nearest.node.global_transform * local

func point(value: Array, city, lift: float) -> Vector3:
	var p: Vector3 = city.world_position(float(value[0]), float(value[1]), float(value[2]))
	p.y = maxf(p.y, city.terrain_height_world(p.x, p.z)) + lift
	return p

func receive(snapshot: Dictionary, city) -> void:
	var target := float(snapshot.get("time", 0))
	var sequence := int(snapshot.get("sequence", last_sequence))
	if initialized and (target < to_clock or sequence < last_sequence):
		shots.clear(); bursts.clear(); actions.clear()
		last_event = 0
		launches = 0; impacts = 0; collapses = 0
		initialized = false
	last_sequence = sequence
	running = bool(snapshot.get("running", false)) and not bool(snapshot.get("blocked", false))
	from_clock = clock if initialized and running and target >= to_clock else target
	to_clock = target
	clock_age = 0.0
	initialized = true
	if not running:
		clock = target
	var alive := {}
	for walker in snapshot.get("walkers", []):
		var asset := str(walker.asset)
		if asset not in MONSTERS:
			continue
		var id := int(walker.id)
		alive[id] = true
		var action := int(walker.get("action", 1))
		if action in [4, 5] and actions.get(id, -1) != action:
			var origin: Vector3 = city.walker_world_position(walker)
			origin.y = maxf(origin.y, city.terrain_height_world(origin.x, origin.z)) + mouth_height(asset)
			var yaw := deg_to_rad(-180.0 + int(walker.get("orientation", 0)) * 45.0)
			var forward := Vector3(-sin(yaw), 0, -cos(yaw))
			var fallback := origin + forward * mouth_forward(asset)
			for head in (3 if asset == "walker_hydra" else 1):
				burst("breath", head_origin(city,asset,city.walker_world_position(walker),head,fallback), forward, tint_for(asset), target, 100.0, float(id)+head)
		actions[id] = action
	for id in actions.keys():
		if not alive.has(id):
			actions.erase(id)
	for event in snapshot.get("monster_effects", []):
		if int(event.event) <= last_event:
			continue
		last_event = int(event.event)
		if str(event.asset) not in MONSTERS:
			continue
		var id := int(event.id)
		var phase := str(event.phase)
		var tint := tint_for(str(event.asset))
		var source := point(event.start, city, mouth_height(str(event.asset)))
		var destination := point(event.target, city, .2)
		var footprint: Array = event.footprint
		# The native hit tile stays authoritative. Draw the contact at its building's
		# near facade so a ground-level target isn't hidden inside an opaque mesh.
		if float(footprint[2]) > 0 and float(footprint[3]) > 0:
			var toward := Vector2(float(event.start[0]) - float(event.target[0]), float(event.start[1]) - float(event.target[1])).normalized()
			var edge := INF
			if absf(toward.x) > .001:
				var boundary := float(footprint[0]) + float(footprint[2]) - .5 if toward.x > 0 else float(footprint[0]) - .5
				edge = minf(edge, (boundary - float(event.target[0])) / toward.x)
			if absf(toward.y) > .001:
				var boundary := float(footprint[1]) + float(footprint[3]) - .5 if toward.y > 0 else float(footprint[1]) - .5
				edge = minf(edge, (boundary - float(event.target[1])) / toward.y)
			if is_finite(edge):
				destination = point([float(event.target[0]) + toward.x * (maxf(0, edge) + .08), float(event.target[1]) + toward.y * (maxf(0, edge) + .08), float(event.target[2])], city, .7)
		var direction := (destination - source).normalized()
		source += Vector3(direction.x, 0, direction.z).normalized() * mouth_forward(str(event.asset))
		source = head_origin(city,str(event.asset),point(event.start,city,0),id%3,source)
		var time := float(event.time)
		if phase == "launch":
			if shots.size() >= MAX_SHOTS:
				shots.erase(shots.keys()[0])
			var length := Vector2(float(event.target[0]) - float(event.start[0]), float(event.target[1]) - float(event.start[1])).length()
			shots[id] = {"start": source, "target": destination, "time": time - float(event.get("age", 0)), "duration": maxf(1.0, length * 40.0 / maxf(.01, float(event.get("speed", 1)))), "end": INF, "tint": tint, "seed": float(id)}
			if float(event.get("age", 0)) == 0:
				burst("breath", source, direction, tint, time, 120.0, float(id))
			launches += 1
		elif phase in ["impact", "cancel"]:
			if shots.has(id):
				shots[id].end = time
			if phase == "cancel":
				continue
			impacts += 1
			burst("splash" if bool(event.get("water", false)) else "impact", destination, Vector3.UP, tint, time, 170.0, float(id))
			if bool(event.get("destroyed", false)):
				collapses += 1
				var foot: Array = event.footprint
				var centre := point([float(foot[0]) + (float(foot[2]) - 1.0) * .5, float(foot[1]) + (float(foot[3]) - 1.0) * .5, float(event.target[2])], city, .08)
				burst("collapse", centre, Vector3.UP, Color(.65, .58, .44), time, 330.0, float(id), clampf(sqrt(float(foot[2]) * float(foot[3])), 1, 4))
	render_effects()

func burst(kind: String, position: Vector3, direction: Vector3, tint: Color, time: float, life: float, seed: float, size := 1.0) -> void:
	if bursts.size() >= MAX_BURSTS:
		bursts.pop_front()
	bursts.append({"kind": kind, "position": position, "direction": direction, "tint": tint, "time": time, "life": life, "seed": seed, "size": size})

func advance(dt: float) -> void:
	if not initialized:
		return
	clock_age += dt
	clock = lerpf(from_clock, to_clock, clampf(clock_age / .1, 0, 1)) if running else to_clock
	render_effects()

func puff(position: Vector3, size: float, tint: Color, age: float, kind: float, seed: float) -> void:
	if puff_count >= MAX_PUFFS:
		return
	var basis := Basis.IDENTITY.rotated(Vector3.RIGHT, -PI * .5) if kind > 1.5 else Basis.IDENTITY
	puffs.set_instance_transform(puff_count, Transform3D(basis.scaled(Vector3(size, size, 1)), position))
	puffs.set_instance_color(puff_count, tint)
	puffs.set_instance_custom_data(puff_count, Color(kind, age, fposmod(seed * .6180339, 1), 0))
	puff_count += 1
	minimum = minimum.min(position - Vector3.ONE * size)
	maximum = maximum.max(position + Vector3.ONE * size)

func shard(position: Vector3, age: float, seed: float, size: float, tint: Color) -> void:
	if debris_count >= MAX_DEBRIS:
		return
	var basis := Basis.from_euler(Vector3(seed + age * 5, seed * 2 + age * 7, age * 3)).scaled(Vector3(size, size * .65, size * .8))
	debris.set_instance_transform(debris_count, Transform3D(basis, position))
	debris.set_instance_color(debris_count, tint)
	debris_count += 1

func render_effects() -> void:
	puff_count = 0
	debris_count = 0
	minimum = Vector3.INF
	maximum = -Vector3.INF
	for id in shots.keys():
		var shot: Dictionary = shots[id]
		var age: float = clock - float(shot.time)
		if clock >= float(shot.end) or age > float(shot.duration) + 40.0:
			shots.erase(id)
			continue
		if age < 0:
			continue
		var progress := clampf(age / float(shot.duration), 0, 1)
		for i in 6:
			var f := maxf(0, progress - float(i) * .035)
			var position: Vector3 = shot.start.lerp(shot.target, f) + Vector3.UP * sin(f * PI) * .15
			var tint: Color = shot.tint
			tint.a = .9 - float(i) * .12
			puff(position, .24 + float(i) * .055, tint, progress, 0 if i == 0 else 1, float(shot.seed) + i)
	for index in range(bursts.size() - 1, -1, -1):
		var effect: Dictionary = bursts[index]
		var age := (clock - float(effect.time)) / float(effect.life)
		if age > 1:
			bursts.remove_at(index)
			continue
		if age < 0:
			continue
		var base: Vector3 = effect.position
		var tint: Color = effect.tint
		tint.a = pow(1.0 - age, 1.5)
		var seed := float(effect.seed)
		var size := float(effect.size)
		if effect.kind == "breath":
			for i in 5:
				var drift: Vector3 = effect.direction * (.06 + age * (.7 + float(i) * .12))
				drift += Vector3(sin(seed + i) * .06, age * .15 + cos(seed + i) * .06, cos(seed + i) * .06)
				puff(base + drift, .18 + age * .32 + float(i) * .025, tint, age, 0 if i == 0 else 1, seed + i)
		elif effect.kind == "collapse":
			for i in 12:
				var angle := float(i) * 2.39996 + seed
				var radial := Vector3(cos(angle), 0, sin(angle))
				puff(base + radial * age * size * .65 + Vector3.UP * (.15 + age * 1.1), .45 + age * size * .6, tint, age, 1, seed + i)
				if age < .7:
					var t := age / .7
					var position := base + radial * t * size * .7 + Vector3.UP * sin(t * PI) * (.7 + float(i % 3) * .2)
					shard(position, age, seed + i, .13 * (1 - t) + .025, Color(.53 + float(i % 3) * .07, .47, .36))
		else:
			var water: bool = effect.kind == "splash"
			for i in 8:
				var angle := float(i) * TAU / 8 + seed
				var radial := Vector3(cos(angle), 0, sin(angle))
				var drop := base + radial * age * .85 + Vector3.UP * sin(age * PI) * (.55 if water else .35)
				puff(drop, .12 + age * .24, Color(.62, .82, .9, tint.a) if water else tint, age, 0, seed + i)
			var ring: Color = Color(.64, .85, .95, tint.a * .5) if water else Color(tint.r, tint.g, tint.b, tint.a * .5)
			puff(base + Vector3.UP * .02, .2 + age * 1.8, ring, age, 2, seed)
	puffs.visible_instance_count = puff_count
	debris.visible_instance_count = debris_count
	if puff_count > 0:
		var bounds := AABB(minimum - Vector3.ONE, maximum - minimum + Vector3.ONE * 2)
		puffs.custom_aabb = bounds
		debris.custom_aabb = bounds
