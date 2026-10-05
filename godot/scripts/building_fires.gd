extends Node3D
# Burning buildings, as the SDL view draws its fire overlays: the snapshot's `fires` ([x, y, w, h, altitude, ruins], sent whole when
# they change) light flames over each burning building, at its roof, with a column of smoke above and, for the first few, a
# flickering light. Smouldering ruins burn low. The fire itself, its spread, the collapse and the ruins it leaves are the engine's
# (eBuilding::timeChanged, collapse); this only shows it.

const FLAME := preload("res://shaders/building_fire.gdshader")
const SMOKE := preload("res://shaders/fire_smoke.gdshader")
const MAX_LIGHTS := 6
const TONGUES := 7

var fires: Dictionary = {}      # "x,y" -> the fire's root node
var lights: Array = []          # [OmniLight3D, seed]
var signature := ""
var flame_mesh: ArrayMesh
var smoke_mesh: QuadMesh

func _init() -> void:
	name = "BuildingFires"
	flame_mesh = tuft_mesh()
	smoke_mesh = QuadMesh.new()
	smoke_mesh.size = Vector2(1.0, 3.0)
	smoke_mesh.center_offset = Vector3(0, 1.5, 0)

func update(list: Array, city) -> void:
	var key := JSON.stringify(list)
	if key == signature:
		return
	signature = key
	# How tall each burning building is: its model's height, found by its corner tile.
	var heights := {}
	for record in city.building_index.values():
		var contract: Dictionary = city.model_contract(str(record.asset))
		if contract.has("bounds_blender"):
			heights["%d,%d" % [int(record.x), int(record.y)]] = float(contract.bounds_blender[1][2])
	var wanted := {}
	for fire in list:
		var id := "%d,%d" % [int(fire[0]), int(fire[1])]
		wanted[id] = true
		if not fires.has(id):
			fires[id] = make_fire(fire, float(heights.get(id, 1.0)), city)
	for id in fires.keys():
		if not wanted.has(id):
			var node: Node3D = fires[id]
			lights = lights.filter(func(entry): return is_instance_valid(entry[0]) and entry[0].get_parent() != node)
			node.queue_free()
			fires.erase(id)

func make_fire(fire: Array, height: float, city) -> Node3D:
	var x := float(fire[0])
	var y := float(fire[1])
	var w := float(fire[2])
	var d := float(fire[3])
	var rubble := int(fire[5]) == 1
	var root := Node3D.new()
	root.name = "Fire"
	var centre: Vector3 = city.world_position(x + (w - 1.0) * .5, y + (d - 1.0) * .5, float(fire[4]))
	centre.y = city.terrain_height_world(centre.x, centre.z)
	root.position = centre
	add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(x), int(y)))
	var top := clampf(height, .3, 3.0)
	var size := clampf(sqrt(w * d) * .75, .8, 2.4)
	# Flames over the roof (low among rubble), spread over the footprint.
	var count := 1 if rubble else clampi(int(w * d), 2, 7)
	for index in count:
		var tuft := MeshInstance3D.new()
		tuft.mesh = flame_mesh
		var finish := ShaderMaterial.new()
		finish.shader = FLAME
		tuft.material_override = finish
		tuft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tuft.extra_cull_margin = 1.0
		var spread := Vector3(rng.randf_range(-.35, .35) * w, 0, rng.randf_range(-.35, .35) * d)
		var lift := rng.randf_range(.05, .2) if rubble else top * rng.randf_range(.55, .9)
		var scale := rng.randf_range(.3, .5) if rubble else size * rng.randf_range(.7, 1.1)
		tuft.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), spread + Vector3.UP * lift)
		tuft.set_instance_shader_parameter("seed", rng.randf())
		root.add_child(tuft)
	# Smoke rising from the roof.
	for index in (1 if rubble else 2):
		var column := MeshInstance3D.new()
		column.mesh = smoke_mesh
		var finish := ShaderMaterial.new()
		finish.shader = SMOKE
		column.material_override = finish
		column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		column.extra_cull_margin = 4.0
		var grow := (.8 if rubble else size) * rng.randf_range(.9, 1.25)
		column.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(grow * 1.4, grow * 1.6, 1.0)),
			Vector3(rng.randf_range(-.2, .2) * w, (.2 if rubble else top * .8), rng.randf_range(-.2, .2) * d))
		column.set_instance_shader_parameter("seed", rng.randf())
		column.set_instance_shader_parameter("thickness", .55 if rubble else 1.0)
		root.add_child(column)
	if lights.size() < MAX_LIGHTS and not rubble:
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, .55, .22)
		glow.omni_range = 2.5 + size * 1.5
		glow.light_energy = 1.4
		glow.shadow_enabled = false
		glow.position = Vector3.UP * (top + .4)
		root.add_child(glow)
		lights.append([glow, rng.randf() * 10.0])
	return root

# The lights flicker with the flames.
func _process(_dt: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for entry in lights:
		var glow: OmniLight3D = entry[0]
		if is_instance_valid(glow):
			var phase: float = entry[1]
			glow.light_energy = 1.4 + .35 * sin(time * 9.0 + phase) + .25 * sin(time * 23.0 + phase * 2.3)

func count() -> int:
	return fires.size()

# Tongues of fire on crossed quads (UV.y 0 at the tip), each with its phase in COLOR.r: as the altar's tuft, about a tile tall.
static func tuft_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in TONGUES:
		var a := TAU * float(i) / TONGUES
		var base := Vector3(sin(a) * .16, 0, cos(a) * .16)
		var height := .75 + .35 * (.5 + .5 * sin(float(i) * 2.39))
		var width := .42 + .14 * (.5 + .5 * cos(float(i) * 1.71))
		for turn in [0.0, PI * .5]:
			var tangent := Vector3(cos(a + turn), 0, -sin(a + turn)) * width * .5
			var corners := [base - tangent, base + tangent, base + tangent + Vector3.UP * height, base - tangent + Vector3.UP * height]
			var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
			for index in [0, 1, 2, 0, 2, 3]:
				surface.set_normal(Vector3(0, 0, 1))
				surface.set_color(Color(float(i) / TONGUES, 1, 1))
				surface.set_uv(uvs[index])
				surface.add_vertex(corners[index])
	surface.index()
	return surface.commit()
