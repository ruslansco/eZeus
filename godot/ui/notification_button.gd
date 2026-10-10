extends "res://ui/toolbar_button.gd"
# Static illustrated art, with an independent count badge and optional progress.
# All input uses the original Button; the overlays cannot intercept its pointer.
var badge := ""
var accent := Color("88bbc5")
var progress := -1.0
var attention: Tween

func _ready() -> void:
	super._ready()
	theme_type_variation = "NotificationButton"
	custom_minimum_size = Vector2(44,44)
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_ALL

func set_badge(value: String) -> void:
	badge = value
	queue_redraw()

func set_progress(value: float) -> void:
	progress = value
	queue_redraw()

func highlight() -> void:
	if attention != null: attention.kill()
	self_modulate = Color.WHITE
	if not is_inside_tree() or get_tree().root.get_node("UiAccess").reduced_motion: return
	attention = create_tween().set_loops(2)
	attention.tween_property(self,"self_modulate",Color(1.25,1.18,.92),.25)
	attention.tween_property(self,"self_modulate",Color.WHITE,.25)

func _draw() -> void:
	if progress >= 0:
		draw_line(Vector2(6,size.y-4),Vector2(size.x-6,size.y-4),Color("445050"),2)
		draw_line(Vector2(6,size.y-4),Vector2(6+(size.x-12)*clampf(progress,0,1),size.y-4),accent,2)
	if badge.is_empty(): return
	var font := get_theme_font("font")
	var pixels := get_theme_font_size("font_size")
	var shown := badge if badge.length() <= 3 else "99+"
	var measured := font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels)
	var width := maxf(17,measured.x+6)
	var area := Rect2(size.x-width-1,1,width,maxf(17,font.get_height(pixels)))
	var face := StyleBoxFlat.new()
	face.bg_color = Color("192326")
	face.border_color = accent
	face.set_border_width_all(1)
	face.set_corner_radius_all(4)
	draw_style_box(face,area)
	draw_string(font,Vector2(area.position.x+(width-measured.x)*.5,area.position.y+font.get_ascent(pixels)),shown,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,accent)
