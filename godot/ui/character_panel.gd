extends Control
# The character window: a right click on a walker shows it here, as the SDL game's character window does (name,
# occupation, the line it speaks and its recorded voice, a cart's errand, the others on its tile). The words and the
# voice file come from the core (`character_info`, worded by engine/echaracterinfotext); this window only presents
# them. main.gd pauses the simulation while it is open and restores the clock when it closes.
signal closed
signal focus_requested(walker_id: int)

const PORTRAIT_SIZE := Vector2(296, 380)
const TYPE_RATE := 0.028       # Seconds per letter when the line has no voice to keep time with.
const TURN_SWAY := 0.32        # Radians the figure turns either way while idle.
const VOICE_ICON := preload("res://ui/icons/voice.svg")
const STOP_ICON := preload("res://ui/icons/stop.svg")
const PORTRAIT_DIR := "res://assets/portraits/"
const KIND_TEXT := {"god": "Olympian", "hero": "Hero", "monster": "Monster"}

var city: Node                 # main.gd: models, walker poses and the core link.
var info: Dictionary = {}
var access: Node
var card := PanelContainer.new()
var viewport := SubViewport.new()
var stage := Node3D.new()
var turntable := Node3D.new()
var camera := Camera3D.new()
var figure: Node3D
var plinth := MeshInstance3D.new()
var band := MeshInstance3D.new()
var halo := MeshInstance3D.new()   # The light a hovering Olympian casts on the plinth.
var voice_row := HBoxContainer.new()
var entry: Dictionary = {}     # A walker record for the figure, so main.gd's idle pose and god float apply.
var floating := false
var figure_height := 1.0
var figure_base := Vector3.ZERO # Where the figure stands; the god float raises it from here every frame.
var name_label := Label.new()
var role_label := Label.new()
var speech := Label.new()
var errand := Label.new()
var badge_label := Label.new()
var badge := PanelContainer.new()
var voice_button := Button.new()
var voice_bar := ProgressBar.new()
var voice_time := Label.new()
var others_row := HFlowContainer.new()
var others_box := VBoxContainer.new()
var others_caption := Label.new()
var paused_label := Label.new()
var goto_button := Button.new()
var close_button := Button.new()
var time := 0.0
var typing := 0.0              # Seconds the line takes to appear.
var typed := 0.0
var dragging := false
var drag_turn := 0.0
var speaking := false
var full_look := Vector3.ZERO
var full_offset := Vector3(0, 0, 3)
var bust_look := Vector3.ZERO
var bust_local := Vector3.ZERO  # the head in the figure's frame; the bust follows it as the figure turns
var bust_offset := Vector3(0, 0, 1)
var zoom := 0.0           # 0 the whole figure, 1 head and shoulders.
var zoom_target := 0.0
var can_zoom := false

func _ready() -> void:
	name = "CharacterPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	access = get_tree().root.get_node("UiAccess")
	access.dialog_open = true
	var shade := ColorRect.new()
	shade.color = Color(.015, .035, .05, .55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: closed.emit())
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	card.theme_type_variation = "CharacterCard"
	center.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)
	row.add_child(build_portrait())
	row.add_child(build_text())
	access.changed.connect(fit)
	resized.connect(fit)
	retranslate()
	fit()
	modulate.a = 0.0
	card.pivot_offset = card.size * .5
	card.scale = Vector2.ONE * .96
	var reduce: bool = access.reduced_motion
	var show := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	show.tween_property(self, "modulate:a", 1.0, 0.01 if reduce else .18)
	show.tween_property(card, "scale", Vector2.ONE, 0.01 if reduce else .22)
	close_button.grab_focus()

# ---- layout -------------------------------------------------------------------------------------------------
func build_portrait() -> Control:
	var frame := PanelContainer.new()
	frame.theme_type_variation = "CharacterFrame"
	frame.custom_minimum_size = PORTRAIT_SIZE
	var layers := Control.new()
	layers.custom_minimum_size = PORTRAIT_SIZE
	layers.clip_contents = true
	frame.add_child(layers)
	# A soft lit backdrop behind the figure: warm light high up fading into the panel's lapis.
	var backdrop := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(.36, .43, .44))
	gradient.set_color(1, Color(.035, .09, .12))
	gradient.add_point(.45, Color(.13, .23, .27))
	var glow := GradientTexture2D.new()
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(.5, .34)
	glow.fill_to = Vector2(1.08, 1.0)
	glow.width = 256; glow.height = 320
	backdrop.texture = glow
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layers.add_child(backdrop)
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.mouse_default_cursor_shape = Control.CURSOR_DRAG
	holder.tooltip_text = tr("Drag to turn · wheel or double-click to zoom")
	holder.gui_input.connect(portrait_input)
	layers.add_child(holder)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(viewport)
	build_stage()
	viewport.add_child(stage)
	# The kind of figure (Olympian, hero, monster) on a small plaque over the plinth.
	badge.theme_type_variation = "CharacterBadge"
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	badge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	badge.offset_bottom = -12
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_label.theme_type_variation = "Eyebrow"
	badge_label.add_theme_color_override("font_color", Color(.97, .87, .64))
	badge.add_child(badge_label)
	layers.add_child(badge)
	return frame

func build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(.62, .68, .74)
	environment.ambient_light_energy = .42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	stage.add_child(world_environment)
	# Key light from the upper left (the city's afternoon sun), a cool fill and a warm rim behind.
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, .93, .82)
	key.light_energy = 1.25
	key.shadow_enabled = true
	key.rotation = Vector3(deg_to_rad(-38), deg_to_rad(-34), 0)
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(.62, .76, .95)
	fill.light_energy = .38
	fill.rotation = Vector3(deg_to_rad(-12), deg_to_rad(58), 0)
	stage.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(1.0, .82, .55)
	rim.light_energy = .9
	rim.rotation = Vector3(deg_to_rad(-20), deg_to_rad(170), 0)
	stage.add_child(rim)
	# A marble plinth with a gold band for the figure to stand on.
	var drum := CylinderMesh.new()
	drum.top_radius = .5; drum.bottom_radius = .54; drum.height = .12; drum.radial_segments = 48
	plinth.mesh = drum
	var marble := StandardMaterial3D.new()
	marble.albedo_color = Color(.70, .68, .63)
	marble.roughness = .42
	plinth.material_override = marble
	plinth.position.y = -.06
	stage.add_child(plinth)
	var ring := TorusMesh.new()
	ring.inner_radius = .5; ring.outer_radius = .53; ring.rings = 48; ring.ring_segments = 8
	band.mesh = ring
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(.79, .62, .32)
	gold.metallic = .85; gold.roughness = .32
	band.material_override = gold
	band.position.y = -.01
	band.scale = Vector3(1, .4, 1)
	stage.add_child(band)
	var disc := QuadMesh.new()
	disc.size = Vector2(1.0, 1.0)
	disc.orientation = PlaneMesh.FACE_Y
	halo.mesh = disc
	var glow := ShaderMaterial.new()
	glow.shader = Shader.new()
	glow.shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, depth_draw_never, cull_disabled;\nuniform float pulse = 1.0;\nvoid fragment() {\n\tfloat r = length(UV - vec2(.5)) * 2.0;\n\tfloat a = smoothstep(1.0, .0, r) * .55 * pulse;\n\tALBEDO = vec3(1.0, .82, .45) * a;\n\tALPHA = a;\n}\n"
	halo.material_override = glow
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position.y = .004
	halo.visible = false
	stage.add_child(halo)
	stage.add_child(turntable)
	camera.fov = 28
	stage.add_child(camera)

func build_text() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size.x = 400
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_label.theme_type_variation = "CharacterRole"
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.theme_type_variation = "CharacterName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	column.add_child(role_label)
	var rule := HSeparator.new()
	rule.add_theme_constant_override("separation", 14)
	column.add_child(rule)
	speech.theme_type_variation = "CharacterSpeech"
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech.custom_minimum_size.y = 120
	speech.mouse_filter = Control.MOUSE_FILTER_STOP
	speech.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: typed = typing)
	column.add_child(speech)
	# The voice: play again or stop, and how far it has got.
	voice_row.add_theme_constant_override("separation", 10)
	voice_button.theme_type_variation = "Primary"
	voice_button.custom_minimum_size = Vector2(124, 34)
	voice_button.add_theme_constant_override("icon_max_width", 20)
	voice_button.pressed.connect(func(): stop_voice() if speaking else speak())
	voice_row.add_child(voice_button)
	voice_bar.theme_type_variation = "CharacterVoice"
	voice_bar.show_percentage = false
	voice_bar.custom_minimum_size.y = 6
	voice_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voice_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	voice_bar.max_value = 1.0
	voice_row.add_child(voice_bar)
	voice_time.theme_type_variation = "Detail"
	voice_time.custom_minimum_size.x = 44
	voice_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	voice_row.add_child(voice_time)
	column.add_child(voice_row)
	errand.theme_type_variation = "Caption"
	errand.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(errand)
	others_caption.theme_type_variation = "Eyebrow"
	others_box.add_child(others_caption)
	others_row.add_theme_constant_override("h_separation", 6)
	others_row.add_theme_constant_override("v_separation", 6)
	others_box.add_child(others_row)
	column.add_child(others_box)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	paused_label.theme_type_variation = "Detail"
	paused_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paused_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(paused_label)
	goto_button.custom_minimum_size = Vector2(96, 34)
	goto_button.pressed.connect(func(): focus_requested.emit(int(info.get("id", -1))); closed.emit())
	footer.add_child(goto_button)
	close_button.custom_minimum_size = Vector2(96, 34)
	close_button.pressed.connect(func(): closed.emit())
	footer.add_child(close_button)
	column.add_child(footer)
	return column

func fit() -> void:
	if not is_node_ready():
		return
	card.custom_minimum_size.x = minf(760, maxf(0, size.x - 48))

func retranslate() -> void:
	goto_button.text = tr("Go to")
	close_button.text = tr("Close")
	paused_label.text = tr("City paused · Escape to return")
	others_caption.text = tr("Also here")
	update_voice_button()

# ---- the character ------------------------------------------------------------------------------------------
# Shows a core `character_info` answer: the figure, the words and the voice.
func show_character(data: Dictionary) -> void:
	info = data
	name_label.text = str(data.get("name", ""))
	var occupation := str(data.get("occupation", ""))
	role_label.text = occupation
	role_label.visible = not occupation.is_empty() and occupation != name_label.text
	if name_label.text.is_empty():
		name_label.text = occupation
		role_label.visible = false
	var kind := str(data.get("kind", "person"))
	badge_label.text = tr(KIND_TEXT[kind]).to_upper() if KIND_TEXT.has(kind) else ""
	badge.visible = not badge_label.text.is_empty()
	var line := str(data.get("text", "")).strip_edges()
	speech.text = "“" + line + "”" if not line.is_empty() else ""
	speech.visible = not line.is_empty()
	var note := str(data.get("errand", ""))
	errand.text = note
	errand.visible = not note.is_empty()
	for child in others_row.get_children():
		child.queue_free()
	var others: Array = data.get("others", [])
	for other in others:
		var chip := Button.new()
		chip.theme_type_variation = "Tool"
		var title := str(other.get("name", ""))
		var job := str(other.get("occupation", ""))
		chip.text = title if not title.is_empty() else job
		chip.tooltip_text = job
		var other_id := int(other.get("id", -1))
		chip.pressed.connect(func(): select(other_id))
		others_row.add_child(chip)
	others_box.visible = not others.is_empty()
	set_figure(str(data.get("asset", "")))
	speak()

# Another walker on the same tile: ask the core about it.
func select(walker_id: int) -> void:
	var answer: Dictionary = city.core.query("character_info %d" % walker_id)
	if not answer.has("error"):
		stop_voice()
		show_character(answer)

func set_figure(asset: String) -> void:
	if figure != null:
		figure.queue_free()
		figure = null
	entry = {}
	if asset.is_empty():
		return
	figure = portrait_model(asset)
	if figure == null:
		figure = city.model(asset)
	if figure == null:
		return
	turntable.add_child(figure)
	var morphs: Array = figure.get_meta("vat_parts") if figure.has_meta("vat_parts") else []
	if morphs.is_empty():
		city.collect_morphs(figure, morphs)
	entry = city.new_walker_entry(figure, asset, int(info.get("type", -1)), Vector3.ZERO, 0.0, morphs)
	# On the plinth a god stands in its held pose and only bobs gently (see _process), instead of the city's full hover.
	floating = entry.god
	entry.god = false
	frame_figure()

# A man's portrait model (tools/godot_portrait_export.py): the same walker with a designed Greek face, curly hair and beard,
# in one held pose. Only this window shows it; the city keeps the crowd model. Null when the role has none.
func portrait_model(asset: String) -> Node3D:
	var path := PORTRAIT_DIR + asset + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var node: Node3D = scene.instantiate()
	city.character_appearance.apply(node, asset, city.model_contract(asset))
	var manifest := PORTRAIT_DIR + asset + ".json"
	if FileAccess.file_exists(manifest):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(manifest))
		if parsed is Dictionary and parsed.get("portrait", {}).has("eye"):
			var eye: Array = parsed.portrait.eye
			node.set_meta("portrait_eye", Vector3(eye[0], eye[1], eye[2]))
			node.set_meta("portrait_head", float(parsed.portrait.get("head_height", .26)))
	return node

# Frames the figure: its bounds decide the camera's distance, so a child and a giant both fill the portrait.
func frame_figure() -> void:
	var bounds := AABB()
	var found := false
	for node in figure.find_children("*", "VisualInstance3D", true, false):
		var local: AABB = figure.global_transform.affine_inverse() * node.global_transform * node.get_aabb()
		bounds = local if not found else bounds.merge(local)
		found = true
	if not found:
		bounds = AABB(Vector3(-.2, 0, -.2), Vector3(.4, .6, .4))
	var height := maxf(bounds.size.y, .2)
	var width := maxf(bounds.size.x, bounds.size.z)
	# The plinth is sized to the figure's footprint, the figure stands on it.
	var spread := maxf(width * .62, height * .3)
	plinth.scale = Vector3(spread, 1, spread)
	halo.scale = Vector3(spread, 1, spread) * .9
	halo.visible = floating
	band.scale = Vector3(spread, .4, spread)
	figure_base = Vector3(-(bounds.position.x + bounds.size.x * .5), -bounds.position.y, -(bounds.position.z + bounds.size.z * .5))
	figure.position = figure_base
	var aspect := PORTRAIT_SIZE.x / PORTRAIT_SIZE.y
	figure_height = height
	var pitch := deg_to_rad(9.0)
	var radius := .54 * spread
	# The plinth's front rim sits lowest on screen: below its base by the radius seen at the camera's pitch.
	var bottom := -.12 - radius * sin(pitch) * 1.6 - height * .03
	var top := height * (1.1 if floating else 1.06)
	var visible_height := maxf(top - bottom, (maxf(width, spread * 1.1)) * 1.15 / aspect)
	var distance := visible_height * .5 / tan(deg_to_rad(camera.fov * .5)) * 1.04
	full_look = Vector3(0, (top + bottom) * .5, 0)
	full_offset = Vector3(0, sin(pitch), cos(pitch)) * distance
	# Head and shoulders: about two and a half heads around the eyes, a little from above.
	var person: bool = entry.get("human", false) or entry.get("lod_role", false) or figure.has_meta("portrait_eye")
	var eye := Vector3(0, height * .92, 0)
	var head := height * .13
	if figure.has_meta("portrait_eye"):
		# The man's own eyes (a rider or a charioteer is not at the middle of his horse or chariot).
		eye = figure.get_meta("portrait_eye") + figure_base
		head = figure.get_meta("portrait_head")
	var bust_height := head * 2.7
	var bust_distance := bust_height * .5 / tan(deg_to_rad(camera.fov * .5))
	if floating:
		eye.y += height * .035   # the gentle hover's mean lift (see _process)
	bust_local = eye + Vector3(0, -head * .42, 0)
	bust_look = bust_local
	bust_offset = Vector3(0, sin(deg_to_rad(4.0)), cos(deg_to_rad(4.0))) * bust_distance
	zoom_target = 1.0 if person else 0.0
	can_zoom = person
	zoom = zoom_target
	place_camera()

func place_camera() -> void:
	bust_look = turntable.transform * bust_local
	var t := zoom * zoom * (3.0 - 2.0 * zoom)
	var look := full_look.lerp(bust_look, t)
	var offset := full_offset.lerp(bust_offset, t)
	camera.position = look + offset
	camera.look_at(look, Vector3.UP)
	camera.near = maxf(.005, offset.length() * .05)
	camera.far = offset.length() * 8.0

func _process(dt: float) -> void:
	time += dt
	# The figure faces the viewer and sways a little; a drag turns it freely.
	if not dragging:
		drag_turn = lerpf(drag_turn, 0.0, 1.0 - exp(-dt * 1.4))
	turntable.rotation.y = PI + sin(time * .55) * TURN_SWAY + drag_turn
	if absf(zoom - zoom_target) > .0005:
		zoom = move_toward(zoom, zoom_target, dt * (100.0 if access.reduced_motion else 2.6))
	if zoom > 0.0 or absf(zoom - zoom_target) > .0005:
		place_camera()
	if figure != null and not entry.is_empty():
		figure.position = figure_base
		city.animate_walker(entry, dt, 0.0)
		if floating:
			var bob := sin(time * TAU * .4)
			figure.position.y += figure_height * (.035 + .02 * bob)
			halo.material_override.set_shader_parameter("pulse", .85 - .15 * bob)
	if typed < typing:
		typed = minf(typing, typed + dt)
		speech.visible_ratio = typed / typing
	else:
		speech.visible_ratio = 1.0
	var player: AudioStreamPlayer = GameAudio.voice
	if speaking:
		var length := player.stream.get_length() if player.stream != null else 0.0
		if not player.playing:
			speaking = false
			voice_bar.value = 1.0
			update_voice_button()
		elif length > 0.0:
			voice_bar.value = clampf(player.get_playback_position() / length, 0.0, 1.0)
			voice_time.text = clock(maxf(0.0, length - player.get_playback_position()))

func portrait_input(event: InputEvent) -> void:
	# The wheel (or a double click) moves between the head and shoulders and the whole figure.
	if event is InputEventMouseButton and event.pressed and can_zoom and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_target = 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.0
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.double_click and can_zoom and event.button_index == MOUSE_BUTTON_LEFT:
		zoom_target = 0.0 if zoom_target > .5 else 1.0
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		drag_turn += event.relative.x * .012

# ---- the voice ----------------------------------------------------------------------------------------------
func speak() -> void:
	var path := str(info.get("voice", ""))
	speaking = not path.is_empty() and not GameAudio.muted() and GameAudio.play_voice(path) and GameAudio.voice.playing
	var length := GameAudio.voice.stream.get_length() if speaking and GameAudio.voice.stream != null else 0.0
	var letters := speech.text.length()
	# The words appear as they are spoken; without a voice they are typed at a steady pace.
	typing = clampf(length * .85, .6, 9.0) if length > 0.0 else clampf(letters * TYPE_RATE, .4, 3.0)
	typed = 0.0
	voice_bar.value = 0.0
	voice_row.visible = not path.is_empty()
	voice_time.text = clock(length) if length > 0.0 else ""
	voice_button.disabled = path.is_empty()
	update_voice_button()

func stop_voice() -> void:
	if speaking:
		GameAudio.stop_voice()
	speaking = false
	typed = typing
	update_voice_button()

func update_voice_button() -> void:
	voice_button.text = tr("Stop") if speaking else tr("Listen")
	voice_button.icon = STOP_ICON if speaking else VOICE_ICON
	if str(info.get("voice", "")).is_empty():
		voice_button.tooltip_text = tr("This character has no recorded voice.")
	elif GameAudio.muted():
		voice_button.tooltip_text = tr("Sound is muted (M).")
	else:
		voice_button.tooltip_text = ""

static func clock(seconds: float) -> String:
	var whole := int(ceilf(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var escape: bool = event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE)
	var right: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if escape or right:
		get_viewport().set_input_as_handled()
		closed.emit()

func _exit_tree() -> void:
	if speaking:
		GameAudio.stop_voice()
	if is_instance_valid(access):
		access.dialog_open = false
