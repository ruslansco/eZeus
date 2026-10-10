extends Control
# Painted ruler art for map cards; correspondence retains its historical static fallback.
const COUNT := 99
var portrait: Texture2D
var sender_index := -1
var picture: TextureRect
var ruler_card := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_type_variation = "AtlasPortrait" if ruler_card else "EnvoyPortrait"
	custom_minimum_size = Vector2(116, 136)
	picture = TextureRect.new()
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := 14 if ruler_card else 8
	picture.offset_left = inset; picture.offset_top = inset
	picture.offset_right = -inset; picture.offset_bottom = -inset
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(picture)
	resized.connect(queue_redraw)

func _city_slug(raw_name: String) -> String:
	var s := raw_name.to_lower().strip_edges().replace(" ", "_").replace("'", "").replace("-", "_")
	match s:
		"stonewatch", "каменный_дозор": return "stonewatch"
		"lantern_reach", "фонарная_гавань": return "lantern_reach"
		"red_banner_league", "лига_красного_знамени": return "red_banner_league"
		"first_light", "first_light_harbor", "первый_луч": return "first_light"
		"reedhaven", "тростниковая_гавань": return "reedhaven"
		"bronze_river", "бронзовая_река": return "bronze_river"
		"willow_quay", "ивовая_пристань": return "willow_quay"
		"sunlit_terraces", "солнечные_террасы": return "sunlit_terraces"
		"amber_crossing", "янтарный_брод": return "amber_crossing"
		"tidebound_covenant", "морской_союз": return "tidebound_covenant"
		"far_shore", "дальний_берег": return "far_shore"
		"athens", "афины": return "athens"
		"sparta", "спарта": return "sparta"
		"troy", "троя": return "troy"
		"thebes", "фивы": return "thebes"
		"corinth", "коринф": return "corinth"
		"knossos", "кносс": return "knossos"
		"ithaca", "итака": return "ithaca"
		"iolcus", "иолк": return "iolcus"
		"atlantis", "атлантида": return "atlantis"
		"gades", "гадес": return "gades"
	return s

func _leader_slug(raw_leader: String) -> String:
	var s := raw_leader.to_lower().strip_edges().replace(" ", "_").replace("'", "").replace("-", "_")
	match s:
		"marshal_doreon", "маршал_дореон": return "marshal_doreon"
		"gadrius", "гадрий": return "gadrius"
	return s

func set_city(city: Dictionary) -> void:
	sender_index = int(city.get("index", -1))
	portrait = null
	if city.is_empty():
		if picture: picture.texture = null
		queue_redraw()
		return

	var is_my_city: bool = bool(city.get("current", false)) or bool(city.get("mine", false)) or String(city.get("type", "")) != "foreign"
	var c_slug := _city_slug(String(city.get("name", "")))
	var l_slug := _leader_slug(String(city.get("leader", "")))

	# Rulers have the same selection policy for foreign and owned cities. A city
	# landscape is not a ruler portrait, and a rendered bust is not painted art.
	var ruler_paths: Array[String] = [
		"res://assets/leaders/%s.png" % l_slug if l_slug != "" else "",
		"res://assets/leaders/leader_%s.png" % l_slug if l_slug != "" else "",
		"res://assets/leaders/%s.png" % c_slug,
		"res://assets/leaders/leader_%s.png" % c_slug,
		"res://assets/leaders/player_ruler.png" if is_my_city else "",
	]
	for path in ruler_paths:
		if not path.is_empty() and ResourceLoader.exists(path):
			portrait = load(path); break
	if ruler_card:
		if picture: picture.texture = portrait
		queue_redraw()
		return

	if is_my_city and not portrait:
		# When user selects 'My City', show an image of the city
		var city_paths: Array[String] = [
			"res://assets/cities/%s.png" % c_slug,
			"res://assets/cities/city_%s.png" % c_slug,
			"res://assets/campaigns/%s.png" % c_slug,
		]
		for p in city_paths:
			if ResourceLoader.exists(p):
				portrait = load(p)
				break
	elif not portrait:
		# For foreign cities, show the painted City Leader portrait
		var leader_paths: Array[String] = [
			"res://assets/leaders/%s.png" % l_slug if l_slug != "" else "",
			"res://assets/leaders/leader_%s.png" % l_slug if l_slug != "" else "",
			"res://assets/leaders/%s.png" % c_slug,
			"res://assets/leaders/leader_%s.png" % c_slug,
			"res://assets/envoys/%s.png" % l_slug if l_slug != "" else "",
			"res://assets/envoys/%s.png" % c_slug,
		]
		for p in leader_paths:
			if p != "" and ResourceLoader.exists(p):
				portrait = load(p)
				break

	# Fallback if no specific city view or leader portrait exists
	if not portrait and sender_index >= 0:
		var path := "res://assets/envoys/envoy_%03d.png" % sender_index
		if not ResourceLoader.exists(path): path = "res://assets/envoys/envoy_%03d.png" % (sender_index % COUNT)
		if ResourceLoader.exists(path): portrait = load(path)

	if picture: picture.texture = portrait
	queue_redraw()

func set_sender(index: int, sender_name: String = "", leader_name: String = "") -> void:
	sender_index = index
	portrait = null
	if leader_name != "" or sender_name != "":
		var l_slug := _leader_slug(leader_name)
		var s_slug := _city_slug(sender_name)
		var leader_paths: Array[String] = [
			"res://assets/leaders/%s.png" % l_slug if l_slug != "" else "",
			"res://assets/leaders/%s.png" % s_slug if s_slug != "" else "",
		]
		for p in leader_paths:
			if p != "" and ResourceLoader.exists(p):
				portrait = load(p)
				break
	if not portrait and index >= 0:
		# Expanded custom sets can provide exact IDs above the original 99 slots.
		var path := "res://assets/envoys/envoy_%03d.png" % index
		if not ResourceLoader.exists(path): path = "res://assets/envoys/envoy_%03d.png" % (index % COUNT)
		if ResourceLoader.exists(path): portrait = load(path)
	if picture: picture.texture = portrait
	queue_redraw()

func _draw() -> void:
	var centre := size * .5
	draw_style_box(get_theme_stylebox("panel"), Rect2(Vector2.ZERO, size))
	if not portrait:
		if ruler_card:
			# A neutral civic seal until matching supplied art is available. Never
			# substitute another ruler or silently return to the old 3D bust.
			var tint := Color("c4a86e")
			draw_circle(centre,28,Color("101e26"))
			draw_arc(centre,28,0,TAU,48,tint,1.5,true)
			draw_polyline(PackedVector2Array([centre+Vector2(-20,-8),centre+Vector2(0,-19),centre+Vector2(20,-8)]),tint,2,true)
			for x in [-13,0,13]: draw_line(centre+Vector2(x,-6),centre+Vector2(x,14),tint,2,true)
			draw_line(centre+Vector2(-20,17),centre+Vector2(20,17),tint,2,true)
			return
		# Non-city events use correspondence, never an invented city speaker.
		var r := Rect2(centre - Vector2(23,16), Vector2(46,32))
		draw_rect(r, Color("c4b58e"), false, 2)
		draw_line(r.position, centre + Vector2(0,3), Color("c4b58e"), 2)
		draw_line(Vector2(r.end.x,r.position.y), centre + Vector2(0,3), Color("c4b58e"), 2)
