extends Node3D
# The states the SDL view paints over a building: the plague over a sick house (a sickly green miasma billowing over the roof with flies
# circling in it, on a pulsing green stain on the ground), a blessing (a golden beam with sparkles rising from a glowing ring) and a
# curse (dark purple wisps with red sparks). The snapshot's `auras` ([x, y, w, h, altitude, kind], kind 0 plague, 1 blessed, 2 cursed;
# sent whole when they change) drive it. The sickness, the blessing and their spread are the engine's; this only shows them.

const COLUMN := preload("res://shaders/building_aura_column.gdshader")
const GROUND := preload("res://shaders/building_aura_ground.gdshader")
const BADGE := preload("res://shaders/building_aura_badge.gdshader")

var auras: Dictionary = {}      # "x,y" -> the aura's root node
var signature := ""
var column_mesh: QuadMesh
var ground_mesh: PlaneMesh
var badge_mesh: QuadMesh

func _init() -> void:
	name = "BuildingAuras"
	column_mesh = QuadMesh.new()
	column_mesh.size = Vector2(1.0, 3.0)
	column_mesh.center_offset = Vector3(0, 1.5, 0)
	ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2.ONE
	badge_mesh = QuadMesh.new()
	badge_mesh.size = Vector2.ONE

func update(list: Array, city) -> void:
	var key := JSON.stringify(list)
	if key == signature:
		return
	signature = key
	var heights := {}
	for record in city.building_index.values():
		var contract: Dictionary = city.model_contract(str(record.asset))
		if contract.has("bounds_blender"):
			heights["%d,%d" % [int(record.x), int(record.y)]] = float(contract.bounds_blender[1][2])
	var wanted := {}
	for aura in list:
		var id := "%d,%d,%d" % [int(aura[0]), int(aura[1]), int(aura[5])]
		wanted[id] = true
		if not auras.has(id):
			auras[id] = make_aura(aura, float(heights.get("%d,%d" % [int(aura[0]), int(aura[1])], 1.0)), city)
	for id in auras.keys():
		if not wanted.has(id):
			auras[id].queue_free()
			auras.erase(id)

func make_aura(aura: Array, height: float, city) -> Node3D:
	var x := float(aura[0])
	var y := float(aura[1])
	var w := float(aura[2])
	var d := float(aura[3])
	var kind := int(aura[5])
	var root := Node3D.new()
	root.name = ["Plague", "Blessed", "Cursed"][clampi(kind, 0, 2)]
	var centre: Vector3 = city.world_position(x + (w - 1.0) * .5, y + (d - 1.0) * .5, float(aura[4]))
	centre.y = city.terrain_height_world(centre.x, centre.z)
	root.position = centre
	add_child(root)
	var seed := fmod(hash(Vector2i(int(x), int(y))) * .000001, 1.0)
	var top := clampf(height, .4, 3.0)
	var size := clampf(sqrt(w * d) * .8, .9, 2.6)
	# The stain or ring on the ground, a little wider than the building.
	var ground := MeshInstance3D.new()
	ground.mesh = ground_mesh
	var ground_finish := ShaderMaterial.new()
	ground_finish.shader = GROUND
	ground.material_override = ground_finish
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(w + 1.8, 1.0, d + 1.8)), Vector3.UP * .07)
	ground.set_instance_shader_parameter("seed", seed)
	ground.set_instance_shader_parameter("mode", float(kind))
	root.add_child(ground)
	# The cloud, beam or wisps over the roof.
	var column := MeshInstance3D.new()
	column.mesh = column_mesh
	var column_finish := ShaderMaterial.new()
	column_finish.shader = COLUMN
	column.material_override = column_finish
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.extra_cull_margin = 4.0
	# A miasma or wisps hug the roof (wider than tall); a blessing is a taller beam.
	var spread := size * (1.7 if kind != 1 else 1.2)
	var rise := size * (.8 if kind != 1 else 1.4)
	column.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(spread, rise, 1.0)), Vector3.UP * (top * (.25 if kind != 1 else .4)))
	column.set_instance_shader_parameter("seed", seed)
	column.set_instance_shader_parameter("mode", float(kind))
	root.add_child(column)
	# The badge above the roof: it keeps a readable size when the camera is far.
	var badge := MeshInstance3D.new()
	badge.mesh = badge_mesh
	var badge_finish := ShaderMaterial.new()
	badge_finish.shader = BADGE
	badge.material_override = badge_finish
	badge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	badge.extra_cull_margin = 8.0
	badge.position = Vector3.UP * (top + .9)
	badge.set_instance_shader_parameter("seed", seed)
	badge.set_instance_shader_parameter("mode", float(kind))
	root.add_child(badge)
	return root

func count() -> int:
	return auras.size()
