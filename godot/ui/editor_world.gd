extends RefCounted
# The adventure editor's world map (the SDL editor's eWorldWidget in editor mode and its city settings, eCitySettingsWidget):
# the world picture with every city on it, invisible ones included; a city is chosen with a click and moved by dragging it;
# Add city puts a new one in the middle, Next map changes the picture. The chosen city's settings: its name and leader (typed,
# or one of the game's own), its kind, relationship, people, regard, direction, whether it is active and visible, its armies
# and wealth, its tribute, and the goods it buys and sells with the most it takes in a year.
const Form = preload("res://ui/editor_form.gd")
const MAP_DIRECTORY := "Textures/Zeus_Data_Images"

var panel
var window: AcceptDialog
var picture: TextureRect
var markers: Control
var details: VBoxContainer
var form: VBoxContainer
var name_edit: LineEdit
var leader_edit: LineEdit
var trades: VBoxContainer
var world: Dictionary = {}
var selected := -1
var dragging := -1
var textures := {}

func attach(owner_panel, root: Control) -> void:
	panel = owner_panel
	window = AcceptDialog.new()
	window.name = "EditorWorld"
	window.get_ok_button().text = tr("Close")
	root.add_child(window)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	window.add_child(row)
	var left := VBoxContainer.new()
	row.add_child(left)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(640, 480)
	frame.clip_contents = true
	left.add_child(frame)
	picture = TextureRect.new()
	picture.name = "WorldPicture"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(picture)
	markers = Control.new()
	markers.name = "WorldCities"
	markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	markers.gui_input.connect(map_input)
	frame.add_child(markers)
	var buttons := HBoxContainer.new()
	left.add_child(buttons)
	var add := Button.new()
	add.name = "AddCity"
	add.focus_mode = Control.FOCUS_NONE
	add.pressed.connect(func():
		var answer: Dictionary = command("editor_city_add 0.5 0.5")
		if answer.has("cities"):
			show_world(answer)
			choose(answer.cities.size() - 1))
	buttons.add_child(add)
	var next := Button.new()
	next.name = "NextMap"
	next.focus_mode = Control.FOCUS_NONE
	next.text = tr("Next map")
	next.pressed.connect(func(): show_world(command("editor_world_map")))
	buttons.add_child(next)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)
	details = VBoxContainer.new()
	details.name = "CityDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)

func visible() -> bool:
	return window.visible

func close() -> void:
	window.hide()

func command(text: String) -> Dictionary:
	var answer: Dictionary = panel.query(text)
	if not answer.has("error"):
		panel.mark_changed()
	return answer

func open() -> void:
	show_world(panel.query("editor_world"))
	choose(selected if selected >= 0 and selected < world.get("cities", []).size() else -1)
	window.popup_centered(Vector2i(1140, 640))

func show_world(answer: Dictionary) -> void:
	if answer.has("error") or not answer.has("cities"):
		return
	world = answer
	window.title = panel.overview.get("labels", {}).get("edit_world", tr("World map"))
	for child in window.find_children("AddCity", "Button", true, false):
		child.text = str(answer.labels.add)
	var image := str(answer.image)
	if not textures.has(image):
		var path := ProjectSettings.globalize_path("res://..").simplify_path().get_base_dir().path_join(MAP_DIRECTORY).path_join(image)
		var loaded := Image.load_from_file(path) if FileAccess.file_exists(path) else null
		textures[image] = ImageTexture.create_from_image(loaded) if loaded != null else null
	picture.texture = textures[image]
	place_markers()

func place_markers() -> void:
	for child in markers.get_children():
		markers.remove_child(child)
		child.queue_free()
	for city in world.get("cities", []):
		var marker := Button.new()
		marker.name = "City%d" % int(city.index)
		marker.text = str(city.label)
		marker.focus_mode = Control.FOCUS_NONE
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.modulate = Color(1, 1, 1, 1.0 if bool(city.visible) else .55)
		if int(city.index) == selected:
			marker.theme_type_variation = "Primary"
		markers.add_child(marker)
		marker.reset_size()
		marker.position = Vector2(float(city.x), float(city.y)) * markers.size - marker.size * .5

# A click chooses the city under the pointer; dragging moves it (the move is sent once, on release).
func map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = -1
			for marker in markers.get_children():
				if Rect2(marker.position, marker.size).has_point(event.position):
					dragging = int(str(marker.name).trim_prefix("City"))
			if dragging >= 0:
				choose(dragging)
		elif dragging >= 0:
			var at: Vector2 = (event.position / markers.size).clamp(Vector2.ZERO, Vector2.ONE)
			show_world(command("editor_city_move %d %f %f" % [dragging, at.x, at.y]))
			dragging = -1
	elif event is InputEventMouseMotion and dragging >= 0:
		var marker: Control = markers.get_node_or_null("City%d" % dragging)
		if marker != null:
			marker.position = event.position - marker.size * .5

func choose(index: int) -> void:
	selected = index
	place_markers()
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	if index < 0:
		var hint := Label.new()
		hint.text = tr("Choose a city on the map")
		hint.theme_type_variation = "Caption"
		details.add_child(hint)
		return
	show_city(panel.query("editor_city %d" % index))

func show_city(city: Dictionary) -> void:
	if city.has("error"):
		return
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	var index := int(city.index)
	name_edit = text_row(tr("Name"), str(city.name), city.names, func(text): show_city(command("editor_city_name %d %s" % [index, text])))
	leader_edit = text_row(tr("Leader"), str(city.leader), city.leaders, func(text): show_city(command("editor_city_leader %d %s" % [index, text])))
	form = VBoxContainer.new()
	form.name = "CityForm"
	details.add_child(form)
	Form.build(form, city.fields, func(id, value):
		var answer := command("editor_city_set %d %s %d" % [index, id, value])
		# A new kind of city has other settings (the SDL settings show and hide them the same way).
		if id in ["type", "relationship"]:
			show_city.call_deferred(answer)
		place_markers_later())
	for side in ["buys", "sells"]:
		var heading := Label.new()
		heading.text = str(world.get("labels", {}).get(side, side))
		heading.theme_type_variation = "Subheading"
		details.add_child(heading)
		for trade in city[side]:
			var row := HBoxContainer.new()
			var name := Label.new()
			name.text = str(trade.name)
			name.custom_minimum_size = Vector2(160, 0)
			row.add_child(name)
			var most := SpinBox.new()
			most.max_value = 999
			most.value = int(trade.max)
			var resource := int(trade.resource)
			var which: String = side
			most.value_changed.connect(func(v):
				if int(v) > 0:
					command("editor_city_trade %d %s %d %d" % [index, which, resource, int(v)]))
			row.add_child(most)
			var remove := Button.new()
			remove.text = tr("Remove")
			remove.focus_mode = Control.FOCUS_NONE
			remove.pressed.connect(func(): show_city(command("editor_city_trade %d %s %d 0" % [index, which, resource])))
			row.add_child(remove)
			details.add_child(row)
		var add_row := HBoxContainer.new()
		var good := OptionButton.new()
		good.name = "Add" + side.capitalize()
		for option in city.resources:
			good.add_item(str(option.label), int(option.value))
		add_row.add_child(good)
		var add := Button.new()
		add.text = tr("Add")
		add.focus_mode = Control.FOCUS_NONE
		var which_side: String = side
		add.pressed.connect(func():
			if good.selected >= 0:
				show_city(command("editor_city_trade %d %s %d 12" % [index, which_side, good.get_item_id(good.selected)])))
		add_row.add_child(add)
		details.add_child(add_row)

func place_markers_later() -> void:
	var answer: Dictionary = panel.query("editor_world")
	if answer.has("cities"):
		world = answer
		place_markers.call_deferred()

# A line for a name: typed (sent on Enter or when it loses focus) or picked from the game's own names.
func text_row(caption: String, value: String, choices: Array, submit: Callable) -> LineEdit:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.max_length = 64
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(text):
		if not text.strip_edges().is_empty() and text != value:
			submit.call(text.strip_edges()))
	edit.focus_exited.connect(func():
		if not edit.text.strip_edges().is_empty() and edit.text != value:
			submit.call(edit.text.strip_edges()))
	row.add_child(edit)
	if not choices.is_empty():
		var pick := OptionButton.new()
		pick.custom_minimum_size = Vector2(40, 0)
		pick.fit_to_longest_item = false
		pick.add_item("…", -1)
		for index in choices.size():
			pick.add_item(str(choices[index]), index)
		pick.item_selected.connect(func(slot):
			if slot > 0:
				submit.call(pick.get_item_text(slot)))
		row.add_child(pick)
	details.add_child(row)
	return edit
