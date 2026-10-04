extends SubViewportContainer
# A small golden laurel wreath in the objectives panel's header, a real 3D model in its own world.
# Its leaves grow in as the objectives are met (`set_progress`, 0..1): bare stems at the start, the full
# wreath when every objective is done. It sways gently, and turns once around when an objective is met.
const LEAVES := 14              # Per branch; two branches meet at the bottom under a ribbon.
const RADIUS := .62
const GOLD := Color(.86, .68, .32)
const STEM := Color(.42, .31, .15)
const RIBBON := Color(.62, .13, .11)

var viewport := SubViewport.new()
var pivot := Node3D.new()
var leaves: Array[MeshInstance3D] = []
var gold_leaf := metal(GOLD, .32)
var bud := metal(Color(.36, .30, .20), .7)
var shown := 0.0    # Leaves drawn, eased toward the target.
var target := 0.0
var spin := 0.0     # Remaining celebratory turn, in radians.
var clock := 0.0

func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(54, 54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.75
	camera.position = Vector3(0, 0, 3)
	viewport.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.6
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20, -140, 0)
	fill.light_energy = .5
	fill.light_color = Color(.6, .75, 1.0)
	viewport.add_child(fill)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(.55, .58, .62)
	environment.environment.ambient_light_energy = 1.3
	viewport.add_child(environment)
	viewport.add_child(pivot)
	build()

static func metal(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	# A small scene has nothing to reflect, so the gold is only half metal and glows a little.
	material.metallic = .4
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = color * .22
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

# One laurel leaf: a pointed, slightly folded blade along +Y, its base at the origin.
static func leaf_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length := .30
	var steps := 6
	var rows: Array = []
	for index in range(steps + 1):
		var t := float(index) / steps
		var width := sin(PI * pow(t, .8)) * .075
		var fold := width * .45
		rows.append([Vector3(-width, t * length, fold), Vector3(0, t * length, 0), Vector3(width, t * length, fold)])
	for index in range(steps):
		var a: Array = rows[index]
		var b: Array = rows[index + 1]
		for side in [[0, 1], [1, 2]]:
			for triangle in [[a[side[0]], a[side[1]], b[side[0]]], [a[side[1]], b[side[1]], b[side[0]]]]:
				for point in triangle:
					surface.add_vertex(point)
	# One-sided blade drawn from both sides (the materials disable culling; Godot flips the normal behind).
	surface.generate_normals()
	return surface.commit()

func build() -> void:
	var leaf := leaf_mesh()
	var gold := gold_leaf
	# The stem: a thin gold ring the leaves are bound to.
	var stem := MeshInstance3D.new()
	var tube := TorusMesh.new()
	tube.inner_radius = RADIUS - .022
	tube.outer_radius = RADIUS + .022
	tube.rings = 48
	stem.mesh = tube
	stem.material_override = metal(STEM.lerp(GOLD, .5), .45)
	stem.rotation_degrees = Vector3(90, 0, 0)
	pivot.add_child(stem)
	for side in [-1.0, 1.0]:
		for index in LEAVES:
			# From the bottom (angle -90°) up to about 70° above the side.
			var t := float(index) / (LEAVES - 1)
			var angle := deg_to_rad(-90.0 + t * 150.0)
			var position := Vector3(cos(angle) * RADIUS * side, sin(angle) * RADIUS, 0)
			for pair in [-1.0, 1.0]:
				var holder := MeshInstance3D.new()
				holder.mesh = leaf
				holder.material_override = gold
				# Each leaf leans along the branch, outward or inward, tilted a little out of the plane.
				# The leaf's +Y follows the branch upward (the circle's tangent), spread to either side.
				var spread: float = deg_to_rad(38.0) * pair
				holder.position = position
				holder.rotation = Vector3(deg_to_rad(18.0 * pair), deg_to_rad(10.0 * side), side * (angle + spread))
				holder.scale = Vector3.ONE * (1.0 - t * .35)
				holder.set_meta("order", index)
				pivot.add_child(holder)
				leaves.append(holder)
	# The ribbon where the branches meet.
	var knot := MeshInstance3D.new()
	var bead := SphereMesh.new()
	bead.radius = .085
	bead.height = .15
	knot.mesh = bead
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = RIBBON
	cloth.roughness = .6
	knot.material_override = cloth
	knot.position = Vector3(0, -RADIUS, .04)
	pivot.add_child(knot)
	for side in [-1.0, 1.0]:
		var tail := MeshInstance3D.new()
		var strip := BoxMesh.new()
		strip.size = Vector3(.07, .34, .02)
		tail.mesh = strip
		tail.material_override = cloth
		tail.position = Vector3(.09 * side, -RADIUS - .17, .03)
		tail.rotation_degrees = Vector3(0, 0, 18 * side)
		pivot.add_child(tail)
	apply()

# 0..1: the share of objectives met.
func set_progress(fraction: float, celebrate := false) -> void:
	target = clampf(fraction, 0.0, 1.0)
	if celebrate:
		spin = TAU

func apply() -> void:
	# Leaves fill from the bottom of both branches upward; a leaf not yet earned is a small dull bud.
	for holder in leaves:
		var order: int = holder.get_meta("order")
		var grown := clampf(shown * LEAVES - order, 0.0, 1.0)
		var base := 1.0 - float(order) / (LEAVES - 1) * .35
		# An earned leaf is gold and full size; one still to earn is a small dull bronze bud.
		holder.scale = Vector3.ONE * base * lerpf(.45, 1.0, grown)
		holder.material_override = gold_leaf if grown > .5 else bud

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	clock += delta
	if absf(shown - target) > .001:
		shown = move_toward(shown, target, delta * .8)
		apply()
	var turn := 0.0
	if spin > 0.0:
		var step := minf(spin, delta * TAU * .9)
		spin -= step
		turn = TAU - spin
	pivot.rotation.y = sin(clock * .9) * .32 + turn
	pivot.rotation.x = sin(clock * .6) * .08
