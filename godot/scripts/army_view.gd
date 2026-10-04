extends RefCounted
# The soldiers' banners on the map: one flag per company at the tile its banner stands on (the palace area while the company
# is at home), drawn over the terrain surface. The selected company has a gold ring. Banners the core lists as not placed
# (companies abroad) are not drawn. The flags are presentation only; the companies, their tiles and their orders belong to the core.

const KIND_COLORS := {
	"hoplite": Color(.80, .12, .10),
	"horseman": Color(.16, .34, .78),
	"rock_thrower": Color(.96, .72, .14),
	"amazon": Color(.58, .22, .70),
	"ares_warrior": Color(.45, .06, .06),
}
const POLE_HEIGHT := 2.0
const CLOTH := Vector2(.95, .62)
const WIND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 albedo : source_color = vec4(.7, .1, .1, 1.0);
uniform float phase = 0.0;
void vertex() {
	float k = UV.x;
	VERTEX.z += sin(TIME * 3.2 + phase + VERTEX.x * 5.0) * .07 * k;
	VERTEX.y += sin(TIME * 2.4 + phase + VERTEX.x * 4.0) * .025 * k;
}
void fragment() {
	ALBEDO = albedo.rgb * (.82 + .18 * UV.x);
	EMISSION = albedo.rgb * .18;
	ROUGHNESS = .85;
}
"""

var root := Node3D.new()
var flags: Dictionary = {}
var selected := -1
var shader: Shader
var pole_mesh: CylinderMesh
var finial_mesh: SphereMesh
var cloth_mesh: ArrayMesh
var trim_mesh: ArrayMesh
var ring_mesh: TorusMesh
var wood: StandardMaterial3D
var gold: StandardMaterial3D
var ring_material: StandardMaterial3D
var elapsed := 0.0

func _init() -> void:
	root.name = "Banners"
	shader = Shader.new()
	shader.code = WIND_SHADER
	pole_mesh = CylinderMesh.new()
	pole_mesh.top_radius = .022
	pole_mesh.bottom_radius = .03
	pole_mesh.height = POLE_HEIGHT
	pole_mesh.radial_segments = 8
	finial_mesh = SphereMesh.new()
	finial_mesh.radius = .06
	finial_mesh.height = .12
	finial_mesh.radial_segments = 10
	finial_mesh.rings = 6
	cloth_mesh = strip(CLOTH.x, CLOTH.y, 0.0)
	trim_mesh = strip(CLOTH.x, .06, 0.0)
	ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = .5
	ring_mesh.outer_radius = .56
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 4
	wood = StandardMaterial3D.new()
	wood.albedo_color = Color(.36, .24, .13)
	wood.roughness = .9
	gold = StandardMaterial3D.new()
	gold.albedo_color = Color(.86, .66, .24)
	gold.metallic = .6
	gold.roughness = .35
	ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(1, .82, .3)
	ring_material.emission_enabled = true
	ring_material.emission = Color(1, .72, .2)
	ring_material.emission_energy_multiplier = 1.4
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

# A flat cloth hanging from the pole: UV.x runs from the pole (0) to the free edge (1) so the shader waves the far end most.
func strip(width: float, height: float, top: float) -> ArrayMesh:
	var columns := 8
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for column in columns + 1:
		var u := float(column) / columns
		vertices.append(Vector3(u * width, top, 0))
		vertices.append(Vector3(u * width, top - height, 0))
		uvs.append(Vector2(u, 0))
		uvs.append(Vector2(u, 1))
		normals.append(Vector3.BACK)
		normals.append(Vector3.BACK)
	for column in columns:
		var a := column * 2
		indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func cloth_material(kind: String, id: int) -> ShaderMaterial:
	var item := ShaderMaterial.new()
	item.shader = shader
	item.set_shader_parameter("albedo", KIND_COLORS.get(kind, Color(.5, .5, .5)))
	item.set_shader_parameter("phase", float(id) * 1.7)
	return item

func make_flag(banner: Dictionary) -> Dictionary:
	var node := Node3D.new()
	node.name = "Banner%d" % int(banner.id)
	var pole := MeshInstance3D.new()
	pole.mesh = pole_mesh
	pole.material_override = wood
	pole.position.y = POLE_HEIGHT * .5
	node.add_child(pole)
	var finial := MeshInstance3D.new()
	finial.mesh = finial_mesh
	finial.material_override = gold
	finial.position.y = POLE_HEIGHT + .05
	node.add_child(finial)
	var cloth := MeshInstance3D.new()
	cloth.mesh = cloth_mesh
	cloth.material_override = cloth_material(str(banner.type), int(banner.id))
	cloth.position = Vector3(.03, POLE_HEIGHT - .12, 0)
	node.add_child(cloth)
	for bar in [0.0, CLOTH.y - .06]:
		var trim := MeshInstance3D.new()
		trim.mesh = trim_mesh
		trim.material_override = gold
		trim.position = Vector3(.03, POLE_HEIGHT - .12 - bar, .004)
		node.add_child(trim)
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.material_override = ring_material
	ring.position.y = .04
	ring.visible = false
	node.add_child(ring)
	root.add_child(node)
	return {"node": node, "ring": ring, "kind": str(banner.type), "cell": Vector2i(-99999, -99999)}

# Brings the flags in line with the core's list. `main` supplies the tile-to-world conversion on the surface.
func update(main: Node, banners: Array) -> void:
	var alive := {}
	for banner in banners:
		var id := int(banner.id)
		if not bool(banner.get("placed", false)):
			continue
		alive[id] = true
		if flags.has(id) and flags[id].kind != str(banner.type):
			flags[id].node.queue_free()
			flags.erase(id)
		if not flags.has(id):
			flags[id] = make_flag(banner)
		var entry: Dictionary = flags[id]
		var cell := Vector2i(int(banner.x), int(banner.y))
		if entry.cell != cell:
			entry.cell = cell
			entry.node.position = main.walker_surface_position(main.world_position(cell.x, cell.y, 0), 0.0, true)
		entry.ring.visible = id == selected
	for id in flags.keys():
		if not alive.has(id):
			flags[id].node.queue_free()
			flags.erase(id)

func select(id: int) -> void:
	selected = id
	for key in flags:
		flags[key].ring.visible = key == id

func banner_at(cell: Vector2i) -> int:
	for id in flags:
		if flags[id].cell == cell:
			return int(id)
	return -1

func clear() -> void:
	for id in flags:
		flags[id].node.queue_free()
	flags.clear()
	selected = -1

func process(dt: float) -> void:
	elapsed += dt
	if selected >= 0 and flags.has(selected):
		var ring: MeshInstance3D = flags[selected].ring
		var pulse := 1.0 + .08 * sin(elapsed * 4.0)
		ring.scale = Vector3(pulse, 1.0, pulse)
