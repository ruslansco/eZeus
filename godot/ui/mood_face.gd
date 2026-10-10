extends Control
# The top bar's popularity mark: a round face that smiles, stays level or frowns with the city's native popularity (0..100),
# in the HUD's gold (content), bronze (uneasy) or terracotta (unhappy) by the native verdict's severity (eCityData::popularity: above 80 good, above 60 a warning, else bad).
const GOOD := Color(.90, .76, .46)
const FAIR := Color(.62, .52, .36)
const BAD := Color(.78, .36, .26)

var popularity := -1

func _init() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_popularity(value: int) -> void:
	if value != popularity:
		popularity = value
		queue_redraw()

static func colour_for(value: int) -> Color:
	return GOOD if value > 80 else FAIR if value > 60 else BAD

func _draw() -> void:
	if popularity < 0:
		return
	var radius := minf(size.x, size.y) * .5 - 1.0
	var centre := size * .5
	var colour := colour_for(popularity)
	draw_circle(centre, radius, colour)
	draw_arc(centre, radius, 0, TAU, 32, colour.darkened(.45), 1.2, true)
	var ink := Color(.08, .12, .1, .9)
	var eye := radius * .13
	draw_circle(centre + Vector2(-radius * .34, -radius * .2), eye, ink)
	draw_circle(centre + Vector2(radius * .34, -radius * .2), eye, ink)
	# The mouth bends from a frown (0) through level (70) to a broad smile (100).
	var bend := clampf((popularity - 70.0) / 30.0, -1.0, 1.0)
	var points := PackedVector2Array()
	for index in 9:
		var t := index / 8.0 * 2.0 - 1.0
		points.append(centre + Vector2(t * radius * .48, radius * .32 + (1.0 - t * t) * bend * radius * .26))
	draw_polyline(points, ink, maxf(1.4, radius * .14), true)
