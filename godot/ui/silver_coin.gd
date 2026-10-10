extends SubViewportContainer
# The treasury's currency mark in the top bar: a silver drachma, a real 3D model in its own small world. The faces are
# struck: Athena's owl with an olive sprig and ΑΘΕ on the front, her helmeted profile's simplified crest on the back, raised
# from a height map drawn as SVG (`FRONT`, `BACK`) into a dense disc mesh, inside a beaded rim. The coin rests turned a little
# toward the light and flips once when the treasury grows (`flip`); it is only rendered while it moves, so it costs nothing at
# rest.
const RADIUS := .5
const THICKNESS := .075
const RELIEF := .035
const GRID := 72
const SILVER := Color(.88, .88, .89)
const REST := Vector3(deg_to_rad(-14.0), deg_to_rad(-22.0), 0.0)

# White is the highest relief, black the field; the 256-unit square maps onto the face inside the rim.
const FRONT := """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'>
<rect width='256' height='256' fill='black'/>
<g fill='#d0d0d0'>
<ellipse cx='140' cy='160' rx='46' ry='62'/>
<circle cx='140' cy='92' r='40'/>
<path d='M104 66 L96 36 L122 58 Z'/><path d='M176 66 L184 36 L158 58 Z'/>
<path d='M110 214 L104 236 L120 230 Z'/><path d='M168 214 L176 236 L160 230 Z'/>
</g>
<g fill='#8a8a8a'><path d='M108 150 Q140 124 172 150 L170 200 Q140 222 110 200 Z'/></g>
<g fill='#5a5a5a'><circle cx='124' cy='90' r='15'/><circle cx='156' cy='90' r='15'/></g>
<g fill='#ffffff'><circle cx='124' cy='90' r='7'/><circle cx='156' cy='90' r='7'/><path d='M140 98 L134 112 L146 112 Z'/></g>
<g fill='#bdbdbd'>
<path d='M44 74 Q70 60 82 92' stroke='#bdbdbd' stroke-width='5' fill='none'/>
<ellipse cx='52' cy='70' rx='12' ry='6' transform='rotate(-30 52 70)'/>
<ellipse cx='66' cy='64' rx='12' ry='6' transform='rotate(20 66 64)'/>
<ellipse cx='74' cy='80' rx='12' ry='6' transform='rotate(-50 74 80)'/>
<circle cx='60' cy='86' r='6'/>
</g>
<g stroke='#d8d8d8' stroke-width='9' fill='none' stroke-linecap='round' stroke-linejoin='round'>
<path d='M202 98 L214 64 L226 98 M206 88 L222 88'/>
<path d='M202 116 L226 116 M214 116 L214 150'/>
<path d='M224 160 L204 160 L204 194 L224 194 M204 177 L220 177'/>
</g>
</svg>"""
const BACK := """<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'>
<rect width='256' height='256' fill='black'/>
<path d='M70 196 Q60 120 112 80 Q150 52 188 74 Q204 92 192 116 L172 124 Q186 140 176 160 Q196 170 184 196 Z' fill='#c8c8c8'/>
<path d='M96 92 Q132 30 196 60 L188 74 Q150 52 112 80 Z' fill='#f0f0f0'/>
<circle cx='160' cy='104' r='8' fill='#ffffff'/>
<path d='M80 176 Q120 168 150 186' stroke='#7a7a7a' stroke-width='6' fill='none'/>
</svg>"""

var viewport := SubViewport.new()
var pivot := Node3D.new()
var turn := 0.0   # Remaining flip, in radians.

func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.12
	camera.position = Vector3(0, 0, 3)
	viewport.add_child(camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 35, 0)
	key.light_energy = 1.9
	viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(25, -150, 0)
	rim.light_energy = .6
	rim.light_color = Color(.7, .82, 1.0)
	viewport.add_child(rim)
	# A plain sky gives the metal something to reflect; the background stays transparent.
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(.38, .48, .62)
	sky_material.sky_horizon_color = Color(.92, .90, .86)
	sky_material.ground_horizon_color = Color(.55, .52, .48)
	sky_material.ground_bottom_color = Color(.18, .18, .2)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.sky = sky
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.environment.ambient_light_energy = .8
	environment.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	viewport.add_child(environment)
	viewport.add_child(pivot)
	build()
	pivot.rotation = REST
	# A new size (window or interface scale) needs one fresh frame.
	resized.connect(func():
		if turn <= 0.0: viewport.render_target_update_mode = SubViewport.UPDATE_ONCE)

static func silver(roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = SILVER
	material.metallic = .85
	material.roughness = roughness
	return material

func build() -> void:
	# The blank: a short cylinder (its axis turned toward the camera) with a raised, beaded rim.
	var body := MeshInstance3D.new()
	var blank := CylinderMesh.new()
	blank.top_radius = RADIUS
	blank.bottom_radius = RADIUS
	blank.height = THICKNESS
	blank.radial_segments = 64
	blank.rings = 1
	body.mesh = blank
	body.material_override = silver(.42)
	body.rotation_degrees = Vector3(90, 0, 0)
	pivot.add_child(body)
	var edge := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = RADIUS - .05
	ring.outer_radius = RADIUS + .004
	ring.rings = 64
	ring.ring_segments = 10
	edge.mesh = ring
	edge.material_override = silver(.3)
	edge.rotation_degrees = Vector3(90, 0, 0)
	edge.scale = Vector3(1, .6, 1)
	pivot.add_child(edge)
	var face_material := silver(.34)
	for side in [1.0, -1.0]:
		var face := MeshInstance3D.new()
		face.mesh = relief(FRONT if side > 0 else BACK)
		face.material_override = face_material
		face.position.z = (THICKNESS * .5 + .002) * side
		if side < 0:
			face.rotation_degrees = Vector3(0, 180, 0)
		pivot.add_child(face)
		# Beads just inside the rim, as on a struck coin.
		for index in 36:
			var angle := TAU * index / 36.0
			var bead := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = .016
			sphere.height = .02
			sphere.radial_segments = 8
			sphere.rings = 4
			bead.mesh = sphere
			bead.material_override = face_material
			bead.position = Vector3(cos(angle) * (RADIUS - .085), sin(angle) * (RADIUS - .085), THICKNESS * .5 * side)
			pivot.add_child(bead)

# A disc facing +Z whose height follows the SVG's brightness (smoothed once, so the strike has soft shoulders).
static func relief(svg: String) -> ArrayMesh:
	var image := Image.new()
	image.load_svg_from_string(svg, .5)
	image.convert(Image.FORMAT_L8)
	image.resize(48, 48, Image.INTERPOLATE_BILINEAR)
	image.resize(GRID + 1, GRID + 1, Image.INTERPOLATE_CUBIC)
	var inner := RADIUS - .11
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(0)
	var points: Array[Vector3] = []
	var inside: Array[bool] = []
	for row in GRID + 1:
		for column in GRID + 1:
			var u := float(column) / GRID
			var v := float(row) / GRID
			var point := Vector2(u * 2.0 - 1.0, 1.0 - v * 2.0) * inner
			var height := image.get_pixel(column, row).r * RELIEF if point.length() <= inner else 0.0
			points.append(Vector3(point.x, point.y, height))
			inside.append(point.length() <= inner * 1.04)
	for row in GRID:
		for column in GRID:
			var a := row * (GRID + 1) + column
			var b := a + 1
			var c := a + GRID + 1
			var d := c + 1
			# Clockwise as seen from +Z (Godot's front faces).
			for triangle in [[a, b, c], [b, d, c]]:
				if inside[triangle[0]] and inside[triangle[1]] and inside[triangle[2]]:
					for index in triangle:
						surface.add_vertex(points[index])
	surface.generate_normals()
	return surface.commit()

# Turns the coin over once (the treasury grew); rendering runs only while it turns.
func flip() -> void:
	if turn <= 0.0:
		turn = TAU
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _process(delta: float) -> void:
	if turn <= 0.0:
		return
	turn = maxf(0.0, turn - delta * TAU * 1.4)
	# Ease out: fast at first, settling onto its resting tilt.
	pivot.rotation = REST + Vector3(0, ease(1.0 - turn / TAU, .5) * TAU, 0)
	if turn <= 0.0:
		pivot.rotation = REST
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
