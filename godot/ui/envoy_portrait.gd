extends Control
# Static renders of actual GLB busts: no continuous portrait rendering or native RNG.
const COUNT := 99
var portrait: Texture2D
var sender_index := -1
var picture: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(116, 136)
	picture = TextureRect.new()
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec2 p=(UV-vec2(0.5))*2.0; float mask=1.0-smoothstep(0.93,0.97,length(p)); COLOR=texture(TEXTURE,UV)*vec4(1.0,1.0,1.0,mask); }"
	var mask := ShaderMaterial.new(); mask.shader = shader; picture.material = mask
	add_child(picture)
	resized.connect(queue_redraw)

func set_sender(index: int) -> void:
	sender_index = index
	portrait = null
	if index >= 0:
		# Expanded custom sets can provide exact IDs above the original 99 slots.
		var path := "res://assets/envoys/envoy_%03d.png" % index
		if not ResourceLoader.exists(path): path = "res://assets/envoys/envoy_%03d.png" % (index % COUNT)
		if ResourceLoader.exists(path): portrait = load(path)
	if picture: picture.texture = portrait
	queue_redraw()

func _draw() -> void:
	var centre := size * .5
	var outline := PackedVector2Array()
	for i in 97:
		var angle := TAU * i / 96.0
		outline.append(centre + Vector2(cos(angle),sin(angle)) * (size*.49))
	draw_colored_polygon(outline, Color("122633"))
	draw_polyline(outline, Color("b4a07a"), 2, true)
	if not portrait:
		# Non-city events use correspondence, never an invented city speaker.
		var r := Rect2(centre - Vector2(23,16), Vector2(46,32))
		draw_rect(r, Color("c4b58e"), false, 2)
		draw_line(r.position, centre + Vector2(0,3), Color("c4b58e"), 2)
		draw_line(Vector2(r.end.x,r.position.y), centre + Vector2(0,3), Color("c4b58e"), 2)
