extends RefCounted
# The rite on a sanctuary's altar, as the SDL view shows it: a priestess in a saffron chiton stabs the sheep or the bull that lies on the altar,
# or raises her arms over an offering of goods, while the braziers at the altar's corners burn high. The core says what is happening
# (walker records with a `scene` of "altar", a `role`, the `rite` and the altar's `size`); this file knows where each part stands, how it lies,
# the offering's props and the braziers' flames. Everything here is presentation: nothing is sent to the core.

const FLAME := preload("res://shaders/ritual_flame.gdshader")
# The three tripod braziers of the altar model (art/sanctuary_altar/build_sprites.py), in the model's own frame: x, height of the bowl, z.
const BRAZIERS := [Vector3(.70, .46, -.70), Vector3(.70, .46, .40), Vector3(-.40, .46, -.70)]
const TONGUES := 5
# Where the parts stand. The altar's table top is .84 high and a person is .87 tall, so the priestess stands on the stairs of the altar's +y face (the
# stairs of art/sanctuary_altar/build_sprites.py rise to the table there): the core gives her orientation 0, facing tile -y across the table. The
# victim lies on the table along tile x.
const STAIR_TOP := .30
const TABLE := .84
# How far (in tiles, toward tile -y) each victim is moved to lie in the middle of the table once rolled, and how it is sized to it.
const VICTIM_SHIFT := {"sheep": .17, "bull": .26}
const VICTIM_SCALE := {"sheep": 1.0, "bull": .72}
# A multiply over the ox's own greyish-brown coat (exported in colour from 6 October; it was white before, when this was .42/.27/.18).
const BULL_COAT := Color(.92, .68, .52)

# Finishes a part's node when it is made: the bull is shrunk to the table and given a darker, redder coat (a multiply over the ox's own coat), the
# offering of goods is sized to the table.
static func dress(node: Node3D, walker: Dictionary) -> void:
	var rite := str(walker.get("rite", ""))
	if str(walker.get("role", "")) == "victim":
		node.scale = Vector3.ONE * float(VICTIM_SCALE.get(rite, 1.0))
		if rite == "bull":
			var tint := StandardMaterial3D.new()
			tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tint.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			tint.albedo_color = BULL_COAT
			_tint(node, tint)
	elif str(walker.get("role", "")) == "offering":
		node.scale = Vector3.ONE * .75

static func _tint(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = material
	for child in node.get_children():
		_tint(child, material)

# The part's position relative to the altar's centre, in the world's axes (tile x is world x; tile y is world -z).
static func offset(walker: Dictionary) -> Vector3:
	var size: Array = walker.get("size", [2, 2])
	match str(walker.get("role", "")):
		"priestess":
			return Vector3(0, 0, -(float(size[1]) * .5 + .12))
		"victim":
			# Rolled onto its side the body spreads toward tile +y by its own height: shifted back so that it lies in the middle of the table.
			return Vector3(0, 0, VICTIM_SHIFT.get(str(walker.get("rite", "")), .2))
		"offering":
			return Vector3(.02, 0, .02)
	return Vector3.ZERO

# How high above the ground (in tiles) the part stands: the priestess on the stairs, the rest on the table.
static func lift(walker: Dictionary) -> float:
	return STAIR_TOP if str(walker.get("role", "")) == "priestess" else TABLE

# The part's roll about its own forward axis, in radians: a victim lies on its side.
static func roll(walker: Dictionary) -> float:
	return deg_to_rad(90.0) if str(walker.get("role", "")) == "victim" else 0.0

# ---- the offering of goods ---------------------------------------------------------------------------------------------------
# Two amphorae and a bowl of fruit, lathed from a profile in code (there is no model for them): terracotta with a dark rim, in the
# altar's table.
static func goods_node() -> Node3D:
	var root := Node3D.new()
	root.name = "SacrificeGoods"
	var clay := _material(Color(.62, .30, .16), .78)
	var rim := _material(Color(.20, .10, .06), .8)
	var bowl := _material(Color(.80, .66, .34), .5)
	for placement in [[Vector3(-.28, 0, -.18), 0.0, 1.0], [Vector3(.22, 0, -.30), 0.35, .86], [Vector3(-.12, 0, .38), -.4, .92]]:
		var jar := MeshInstance3D.new()
		jar.mesh = _lathe([[.0, .0], [.06, .0], [.12, .06], [.15, .16], [.12, .30], [.06, .38], [.055, .46], [.08, .50], [.075, .52], [.045, .50], [.0, .50]])
		jar.material_override = clay
		jar.position = placement[0]
		jar.rotation.y = placement[1]
		jar.scale = Vector3.ONE * float(placement[2])
		jar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(jar)
		var lip := MeshInstance3D.new()
		lip.mesh = _lathe([[.062, .492], [.082, .508], [.074, .524], [.050, .510]])
		lip.material_override = rim
		lip.position = jar.position
		lip.rotation.y = jar.rotation.y
		lip.scale = jar.scale
		root.add_child(lip)
	var dish := MeshInstance3D.new()
	dish.mesh = _lathe([[.0, .0], [.10, .0], [.20, .07], [.23, .11], [.20, .11], [.17, .075], [.0, .05]])
	dish.material_override = bowl
	dish.position = Vector3(.26, 0, .26)
	root.add_child(dish)
	for fruit in [[Vector3(.22, .12, .24), Color(.70, .12, .10)], [Vector3(.31, .12, .27), Color(.86, .62, .14)], [Vector3(.27, .13, .33), Color(.48, .20, .44)], [Vector3(.28, .17, .27), Color(.70, .12, .10)]]:
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = .045
		sphere.height = .09
		sphere.radial_segments = 10
		sphere.rings = 5
		ball.mesh = sphere
		ball.material_override = _material(fruit[1], .55)
		ball.position = fruit[0]
		root.add_child(ball)
	return root

static func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

# A solid of revolution from (radius, height) pairs, bottom to top, smooth-shaded.
static func _lathe(profile: Array, segments := 16) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(0)
	for index in profile.size() - 1:
		var a: Array = profile[index]
		var b: Array = profile[index + 1]
		for step in segments:
			var s0 := TAU * float(step) / segments
			var s1 := TAU * float(step + 1) / segments
			var p00 := Vector3(cos(s0) * float(a[0]), float(a[1]), sin(s0) * float(a[0]))
			var p01 := Vector3(cos(s1) * float(a[0]), float(a[1]), sin(s1) * float(a[0]))
			var p10 := Vector3(cos(s0) * float(b[0]), float(b[1]), sin(s0) * float(b[0]))
			var p11 := Vector3(cos(s1) * float(b[0]), float(b[1]), sin(s1) * float(b[0]))
			for corner in [p00, p10, p11, p00, p11, p01]:
				tool.add_vertex(corner)
	tool.generate_normals()
	return tool.commit()

# ---- the braziers' flames ----------------------------------------------------------------------------------------------------
# One tuft of tongues per brazier of each finished altar, standing where the model has its bowls (the model's own static flame stays under it,
# so a flame never vanishes). `burn` follows whether a rite is on the altar.
class Fires extends Node3D:
	var tufts: Dictionary = {}     # altar id -> [MeshInstance3D, ...]
	var keys: Dictionary = {}      # altar id -> where its centre is (the key a rite's records use)
	var burning: Dictionary = {}   # the keys of the altars with a rite on them
	var tongue_mesh: ArrayMesh

	func _init() -> void:
		name = "AltarFires"
		tongue_mesh = _tuft_mesh()

	# `altars`: [{id, transform}], the finished altars as the city placed them (the transform is the model's: position and quarter turns).
	func refresh(altars: Array) -> void:
		var wanted := {}
		for altar in altars:
			wanted[int(altar.id)] = true
			keys[int(altar.id)] = altar.key
			var group: Array = tufts.get(int(altar.id), [])
			if group.is_empty():
				for anchor in BRAZIERS:
					var tuft := MeshInstance3D.new()
					tuft.mesh = tongue_mesh
					var finish := ShaderMaterial.new()
					finish.shader = FLAME
					tuft.material_override = finish
					tuft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					tuft.extra_cull_margin = .3
					add_child(tuft)
					group.append(tuft)
				tufts[int(altar.id)] = group
			for index in group.size():
				var tuft: MeshInstance3D = group[index]
				var xf: Transform3D = altar.transform
				tuft.transform = Transform3D(Basis.IDENTITY, xf * BRAZIERS[index])
		for id in tufts.keys():
			if not wanted.has(id):
				for tuft in tufts[id]:
					tuft.queue_free()
				tufts.erase(id)
				keys.erase(id)
		apply()

	# Sets the flames of the altars with a rite on them (the keys of their centres) burning high.
	func burn(rites: Dictionary) -> void:
		burning = rites
		apply()

	func apply() -> void:
		for id in tufts:
			var level := 1.0 if burning.has(keys[id]) else 0.0
			for tuft in tufts[id]:
				if tuft.get_instance_shader_parameter("burn") != level:
					tuft.set_instance_shader_parameter("burn", level)

	static func _tuft_mesh() -> ArrayMesh:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in TONGUES:
			var a := TAU * float(i) / TONGUES
			var base := Vector3(sin(a) * .035, 0, cos(a) * .035)
			var height := .30 + .10 * (.5 + .5 * sin(float(i) * 2.39))
			var width := .17 + .05 * (.5 + .5 * cos(float(i) * 1.71))
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
