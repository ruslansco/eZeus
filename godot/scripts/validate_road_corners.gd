extends SceneTree
# GPU probes use the actual ground contour include, not a CPU copy of its formula.
const Setback = preload("res://scripts/street_setback.gd")
var okay := true
var checks := 0
var viewport: SubViewport
var material: ShaderMaterial
var image: Image

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("ROAD_CORNER_CHECK ", "PASS " if value else "FAIL ", label)

func render(tiles: Dictionary, radius := .18) -> void:
	var data := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	for cell in tiles: data.set_pixelv(cell, Color(float(tiles[cell][4]), 0, 0, 0))
	material.set_shader_parameter("road_data", ImageTexture.create_from_image(data))
	material.set_shader_parameter("road_inner_radius", radius)
	for frame in 3: await process_frame
	RenderingServer.force_draw(true, .016)
	image = viewport.get_texture().get_image()

func sample(point: Vector2) -> float:
	return image.get_pixel(clampi(int(point.x * 256), 0, 767), clampi(int(point.y * 256), 0, 767)).r

func fixture() -> Dictionary:
	var tiles := {}
	for x in 3:
		for y in 3: tiles[Vector2i(x, y)] = [x, y, 0, 1, 0, 1, 0, 0, 0]
	return tiles

func run() -> void:
	viewport = SubViewport.new(); viewport.size = Vector2i(768, 768)
	viewport.disable_3d = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var panel := ColorRect.new(); panel.size = Vector2(768, 768)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode unshaded;
uniform sampler2D road_data : filter_linear, repeat_disable;
uniform vec2 map_extent = vec2(3.0);
#include "res://shaders/road_contour.gdshaderinc"
void fragment() { float value = road_contour(UV, texture(road_data, UV).r); COLOR = vec4(vec3(value), 1.0); }
"""
	material = ShaderMaterial.new(); material.shader = shader; panel.material = material
	viewport.add_child(panel)
	for corner in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		var tiles := fixture()
		for offset in [Vector2i(corner.x, 0), Vector2i(0, corner.y), corner]:
			tiles[Vector2i.ONE + offset][4] = 1
		var point := Vector2(1.5, 1.5) + Vector2(corner) * .38
		await render(tiles, 0.0)
		check(sample(point) > .55, "%s: original shading reproduces the road over a building corner" % corner)
		await render(tiles)
		check(sample(point) < .48, "%s: existing .12-tile building corner clears the rendered road" % corner)
		check(sample(Vector2(1.5, 1.5) + Vector2(corner) * .49) > .5, "%s: the inside bend remains rounded" % corner)
		# A corner must have one continuous kerb across BOTH native tile borders.
		# The first correction cleared the plot but jumped back to the old field on
		# the road side, which left stacked kerb ends in the actual city capture.
		var vertex := Vector2(1.5, 1.5) + Vector2(corner) * .5
		var joined := true
		for step in 7:
			var along := .02 + step * .03
			var x_cross := Vector2(vertex.x, vertex.y - corner.y * along)
			var y_cross := Vector2(vertex.x - corner.x * along, vertex.y)
			joined = joined and absf(sample(x_cross - Vector2(1.0 / 256, 0)) - sample(x_cross + Vector2(1.0 / 256, 0))) < .018
			joined = joined and absf(sample(y_cross - Vector2(0, 1.0 / 256)) - sample(y_cross + Vector2(0, 1.0 / 256))) < .018
		check(joined, "%s: both tile joins keep one continuous kerb field" % corner)
		# Remove the diagonal to cover a crossing with no connected inside bulge.
		tiles[Vector2i.ONE + corner][4] = 0
		await render(tiles)
		check(sample(point) < .5, "%s: disconnected diagonal cannot invent paving over a plot" % corner)
	# Small plots can be capped to .075 per side when roads surround them.
	var surrounded := fixture()
	for cell in surrounded: surrounded[cell][4] = 0 if cell == Vector2i.ONE else 1
	var plot := {"asset": "park", "x": 1, "y": 1, "w": 1, "h": 1}
	var before: Dictionary = surrounded.duplicate(true)
	var transform := Setback.apply(surrounded, plot, Transform3D.IDENTITY)
	await render(surrounded)
	var clear := true
	for x in [-.5, .5]:
		for y in [-.5, .5]:
			var corner := transform * Vector3(x, 0, y)
			clear = clear and sample(Vector2(1.5 + corner.x, 1.5 - corner.z)) < .49
	check(clear, "all corners of the smallest capped plot stay outside paving")
	check(surrounded == before, "rendering and building fitting retain native observations")
	var straight := fixture()
	for y in 3: straight[Vector2i(1, y)][4] = 1
	await render(straight, 0.0)
	var original := image.duplicate()
	await render(straight)
	var unchanged := true
	for x in range(50, 718, 5):
		unchanged = unchanged and absf(image.get_pixel(x, 384).r - original.get_pixel(x, 384).r) < .008
	check(unchanged, "straight road width and both edge gradients are unchanged")
	var outside := fixture(); outside[Vector2i.ONE][4] = 1
	await render(outside, 0.0); original = image.duplicate()
	await render(outside)
	unchanged = true
	for x in range(128, 640, 7):
		for y in range(128, 640, 7):
			unchanged = unchanged and absf(image.get_pixel(x, y).r - original.get_pixel(x, y).r) < .008
	check(unchanged, "convex outside road corners retain their original rounding")
	print("ROAD_CORNERS ", "PASS " if okay else "FAIL ", checks, " checks")
	viewport.queue_free(); await process_frame; await process_frame
	quit(0 if okay else 1)
