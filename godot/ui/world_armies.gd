extends Control
# The armies on their way between cities, drawn over the world map picture: a dashed road from the city they left to the city
# they go to, and a disc on it at the part of the way they have covered (`frac`), with a head toward where they are going and a pip
# for each step of their size. Raids are orange, conquests red, help green and armies coming home grey. The core reports them
# (`armies` in the `world` query); nothing here decides anything.

const COLORS := {"raid": Color(.96, .52, .22), "conquest": Color(.88, .22, .22), "help": Color(.38, .78, .48), "home": Color(.78, .8, .86)}

var armies: Array = []
var positions: Dictionary = {}
var rect := Rect2()
var projection := Callable()

func _init() -> void:
	name = "Armies"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

# `cities` is the world's list (each with `index`, `x`, `y` as fractions of the picture); `picture` is where the picture lies.
func set_state(world_armies: Array, cities: Array, picture: Rect2) -> void:
	armies = world_armies
	rect = picture
	positions.clear()
	for city in cities:
		positions[int(city.index)] = Vector2(float(city.x), float(city.y))
	queue_redraw()

func point(index: int) -> Vector2:
	var fraction: Vector2 = positions.get(index, Vector2(.5, .5))
	if projection.is_valid(): return projection.call(fraction)
	return rect.position + fraction * rect.size

func _draw() -> void:
	for army in armies:
		var from := point(int(army.from))
		var to := point(int(army.to))
		var color: Color = COLORS.get(String(army.reason), Color.WHITE)
		var at := from.lerp(to, float(army.frac))
		if projection.is_valid():
			var a:Vector2=positions.get(int(army.from),Vector2(.5,.5))
			var b:Vector2=positions.get(int(army.to),Vector2(.5,.5))
			for segment in 24:
				var start:Vector2=projection.call(a.lerp(b,float(segment)/24))
				var finish:Vector2=projection.call(a.lerp(b,float(segment+1)/24))
				draw_dashed_line(start,finish,Color(color,.55),2.0,7.0)
			at=projection.call(a.lerp(b,float(army.frac)))
		else:
			draw_dashed_line(from,to,Color(color,.55),2.0,7.0)
		var direction := (to - from).normalized() if to.distance_to(from) > .5 else Vector2.RIGHT
		draw_circle(at, 11.0, Color(.05, .08, .14, .9))
		draw_circle(at, 8.5, color)
		var normal := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([at + direction * 7.0, at - direction * 3.0 + normal * 5.0, at - direction * 3.0 - normal * 5.0]), Color(.05, .08, .14, .95))
		for pip in int(army.size):
			draw_circle(at + normal * 15.0 + direction * (float(pip) - float(int(army.size) - 1) * .5) * 6.0, 2.2, color)
