extends Control
# The City History chart, as the SDL remaster's (widgets/ecityhistorywidget): one series of the city's monthly record over the
# last two years, ten years or all of it, with round gridlines, the years along the bottom and the month and value under the
# pointer. The record and its words are the core's (`city_history`).

const COLORS := [Color(1.0, .84, .47), Color(.96, .75, .27), Color(.63, .84, .43), Color(.47, .77, 1.0), Color(.94, .41, .33), Color(.49, .87, .69)]
const MONTHS := [24, 120, 0]

var history: Dictionary = {}
var series := 0
var span := 0
var hover := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 330)

func set_history(value: Dictionary) -> void:
	history = value
	queue_redraw()

func choose(index: int, range_index: int) -> void:
	series = index
	span = range_index
	queue_redraw()

# The months on show, oldest first.
func visible_samples() -> Array:
	var samples: Array = history.get("samples", [])
	var months: int = MONTHS[span]
	if months <= 0 or samples.size() <= months:
		return samples
	return samples.slice(samples.size() - months)

static func grouped(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	var separator := " " if TranslationServer.get_locale().begins_with("ru") else ","
	for index in range(digits.length() - 1, -1, -1):
		out = digits[index] + out
		count += 1
		if count % 3 == 0 and index > 0:
			out = separator + out
	return ("-" if value < 0 else "") + out

func value_text(value: int) -> String:
	var percent: bool = history.get("series", [])[series].get("percent", false) if series < history.get("series", []).size() else false
	return grouped(value) + ("%" if percent else "")

# A round step for about n gridlines over range.
static func nice_step(range_value: float, n: int) -> float:
	if range_value <= 0:
		return 1.0
	var raw := range_value / n
	var magnitude := pow(10.0, floor(log(raw) / log(10.0)))
	var fraction := raw / magnitude
	var nice := 1.0
	if fraction > 5:
		nice = 10.0
	elif fraction > 2:
		nice = 5.0
	elif fraction > 1:
		nice = 2.0
	return maxf(1.0, nice * magnitude)

func plot_rect() -> Rect2:
	return Rect2(Vector2(70, 14), size - Vector2(90, 44))

# The month under the pointer, read each frame (a pointer that only rests there, or was moved by a review, counts too).
func _process(_dt: float) -> void:
	if not is_visible_in_tree():
		return
	var point := get_local_mouse_position()
	var samples := visible_samples()
	var rect := plot_rect()
	var index := -1
	if samples.size() >= 1 and rect.grow(8).has_point(point):
		index = clampi(roundi((point.x - rect.position.x) / maxf(1.0, rect.size.x) * maxi(1, samples.size() - 1)), 0, samples.size() - 1)
	if index != hover:
		hover = index
		queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var small := maxi(11, font_size - 3)
	var rect := plot_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(.05, .09, .18, .55))
	var samples := visible_samples()
	if samples.is_empty():
		var lines: Array = history.get("empty", [])
		for index in lines.size():
			draw_string(font, Vector2(0, size.y * .45 + index * (font_size + 6)), str(lines[index]), HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(.8, .82, .88))
		return
	var values: Array = samples.map(func(s): return int(s["values"][series]))
	var low: int = values.min()
	var high: int = values.max()
	low = mini(low, 0)
	if high == low:
		high = low + 1
	var step := nice_step(high - low, 5)
	var bottom := floorf(low / step) * step
	var top := ceilf(high / step) * step
	var to_point := func(index: int, value: float) -> Vector2:
		var x := rect.position.x + (rect.size.x * index / maxf(1.0, samples.size() - 1) if samples.size() > 1 else rect.size.x * .5)
		return Vector2(x, rect.end.y - (value - bottom) / maxf(1.0, top - bottom) * rect.size.y)
	# Gridlines and their values.
	var line := bottom
	while line <= top + .5:
		var y: float = to_point.call(0, line).y
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(1, .85, .5, .14 if line != 0 else .35), 1.0)
		draw_string(font, Vector2(0, y + small * .35), value_text(int(line)), HORIZONTAL_ALIGNMENT_RIGHT, rect.position.x - 8, small, Color(.75, .78, .86))
		line += step
	# Years along the bottom: at each January, thinned to fit.
	var januaries: Array = []
	for index in samples.size():
		if int(samples[index].month) % 12 == 0:
			januaries.append(index)
	var every := maxi(1, ceili(januaries.size() / 8.0))
	for k in januaries.size():
		if k % every != 0:
			continue
		var index: int = januaries[k]
		var x: float = to_point.call(index, bottom).x
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(1, 1, 1, .06), 1.0)
		var name := str(samples[index].label)
		var year := name.substr(name.find(" ") + 1)
		draw_string(font, Vector2(x - 60, rect.end.y + small + 8), year, HORIZONTAL_ALIGNMENT_CENTER, 120, small, Color(.75, .78, .86))
	# The series: a soft area under its line.
	var color: Color = COLORS[series % COLORS.size()]
	var points := PackedVector2Array()
	for index in samples.size():
		points.append(to_point.call(index, float(values[index])))
	if points.size() >= 2:
		var area := points.duplicate()
		area.append(Vector2(points[-1].x, rect.end.y))
		area.append(Vector2(points[0].x, rect.end.y))
		var fill := color
		fill.a = .16
		draw_colored_polygon(area, fill)
		draw_polyline(points, color, 2.0, true)
	draw_circle(points[-1], 4.0, color)
	# The month under the pointer.
	if hover >= 0 and hover < samples.size():
		var at: Vector2 = points[hover]
		draw_line(Vector2(at.x, rect.position.y), Vector2(at.x, rect.end.y), Color(1, .9, .6, .5), 1.0)
		draw_circle(at, 5.0, Color(1, .95, .8))
		var text := "%s: %s" % [str(samples[hover].label), value_text(int(values[hover]))]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 16
		var box := Rect2(Vector2(clampf(at.x - width * .5, 0, size.x - width), rect.position.y - 4), Vector2(width, font_size + 10))
		draw_rect(box, Color(.08, .13, .26, .95))
		draw_rect(box, Color(.94, .78, .43, .8), false, 1.0)
		draw_string(font, box.position + Vector2(8, font_size + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, .93, .78))
