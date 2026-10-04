extends Control
# One city on the world map: a badge in the colour of its kind, the city's name beneath it and a ring when it is selected.
# Presentation only; the core owns every fact (`world` query): this draws what it is told and reports a click.

signal picked(index: int)

const SIZE_BOX := Vector2(130, 52)
const BADGE := Vector2(65, 15)
const GOLD := Color(.94, .78, .3)
const ALLY := Color(.35, .8, .5)
const VASSAL := Color(.45, .65, .95)
const RIVAL := Color(.9, .35, .3)
const NEUTRAL := Color(.72, .74, .8)
const PLACE := Color(.7, .5, .9)
# Compass directions of a distant city (the core's eDistantDirection, 1 north to 8 north-west).
const COMPASS := [Vector2.ZERO, Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1)]

var city: Dictionary = {}
var selected := false
var hovered := false

func setup(data: Dictionary) -> void:
	city = data
	custom_minimum_size = SIZE_BOX
	size = SIZE_BOX
	tooltip_text = String(data.name)
	mouse_entered.connect(func(): hovered = true; queue_redraw())
	mouse_exited.connect(func(): hovered = false; queue_redraw())
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

# The point of the map this marker stands on, inside the control.
func anchor() -> Vector2:
	return BADGE

func colour() -> Color:
	match String(city.type):
		"parent", "colony":
			return GOLD if bool(city.active) or String(city.type) == "parent" else Color(.5, .5, .55)
		"foreign":
			match String(city.relationship):
				"ally": return ALLY
				"vassal": return VASSAL
				"rival": return RIVAL
		"place": return PLACE
	return NEUTRAL

func _draw() -> void:
	if city.is_empty():
		return
	var tint:=colour()
	var font:=get_theme_default_font()
	var text:=String(city.name)
	var font_size:=clampi(get_theme_font_size("font_size","Caption"),14,20)
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var rect:=Rect2(Vector2(BADGE.x-width*.5-12,BADGE.y+7),Vector2(width+24,font_size+10))
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(.015,.06,.09,.9 if selected else .7)
	style.border_color=GOLD if selected else Color(tint,.48)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(5)
	style.shadow_color=Color(0,0,0,.35)
	style.shadow_size=3
	draw_style_box(style,rect)
	draw_circle(Vector2(rect.position.x+6,rect.get_center().y),2.0,tint)
	var origin:=Vector2(BADGE.x-width*.5+2,rect.position.y+font_size+1)
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(1,.91,.64) if selected else Color(.93,.95,.89))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(int(city.index))
		accept_event()
