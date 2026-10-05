extends RefCounted
# The adventure editor in the 3D city (the SDL editor: eEditorMainMenu with its terrain panel, eTerrainEditMenu). The start
# menu opens an adventure for editing (`open_editor`); the city scene then shows its parent city's map, never running, and this
# panel instead of the game's interface: a bar with the adventure's title, Episodes (ui/editor_episodes.gd), World map
# (ui/editor_world.gd), Save and Quit, and the terrain tools on the left. A tool paints on the map: a brush or a square of its
# size along the drag, or the area dragged out; each stroke is one `editor_paint`, made by the engine's own editor code
# (engine/eterrainedit, shared with the SDL editor), and the map follows through the snapshot as any change does.
const Episodes = preload("res://ui/editor_episodes.gd")
const World = preload("res://ui/editor_world.gd")

# The SDL terrain panel's tools, by category; a tool with a number (a point's id, a spawner's) shows the number box, the
# territory tools the city box.
const CATEGORIES := [
	["Land", [["dry", "Dry land"], ["fertile", "Meadow"], ["beach", "Beach"], ["water", "Water"], ["marsh", "Marsh"]]],
	["Trees", [["forest", "Forest"], ["chopped_forest", "Cut forest"], ["rainforest", "Rainforest"], ["normal_forest", "Normal forest"]]],
	["Rocks and ores", [["flat_stones", "Flat rock"], ["tall_stones", "Tall rock"], ["marble", "Marble"], ["copper", "Copper ore"], ["silver", "Silver ore"], ["orichalc", "Orichalc"]]],
	["Scrub", [["scrub", "Scrub"], ["scrub_area", "Scrub area"], ["remove_scrub", "Remove scrub"], ["soften_scrub", "Soften scrub"]]],
	["Height", [["raise", "Raise"], ["lower", "Lower"], ["raise_high", "Raise high"], ["lower_high", "Lower high"], ["level_out", "Level out"], ["reset_elevation", "Reset height"], ["half_slope", "Half slope"], ["walkable", "Walkable slope"]]],
	["Wildlife", [["fish", "Fish"], ["urchin", "Urchins"], ["boar", "Boar spawn"], ["deer", "Deer spawn"]]],
	["Points", [["entry_point", "Entry point"], ["exit_point", "Exit point"], ["river_entry", "River entry"], ["river_exit", "River exit"], ["land_invasion", "Land invasion point"], ["sea_invasion", "Sea invasion point"], ["disembark", "Disembark point"], ["monster_point", "Monster point"], ["disaster_point", "Disaster point"], ["land_slide_point", "Landslide point"]]],
	["Disasters", [["quake", "Earthquake chasm"], ["lava", "Lava zone"], ["tidal_wave", "Tidal wave zone"], ["land_slide", "Landslide zone"], ["fire", "Fire"], ["ruins", "Ruins"]]],
	["Territory", [["territory", "Territory"], ["assign_territory", "Assign all territory"]]],
]
const NUMBERED := ["boar", "deer", "land_invasion", "sea_invasion", "disembark", "monster_point", "disaster_point", "land_slide_point"]
const CITY_TOOLS := ["territory", "assign_territory"]
const STROKE_COLOR := Color(1.0, .82, .32, .45)

var city
var layer: CanvasLayer
var bar: PanelContainer
var title_label: Label
var status: Label
var tools_panel: PanelContainer
var brush_kind: OptionButton
var brush_size: SpinBox
var number_row: HBoxContainer
var number_box: SpinBox
var city_row: HBoxContainer
var city_box: OptionButton
var tool_buttons: Dictionary = {}
var group := ButtonGroup.new()
var episodes
var world
var quit_dialog: ConfirmationDialog
var tool := ""
var pressing := false
var points: Array[Vector2i] = []
var markers: Node3D
var overview: Dictionary = {}

func attach(main) -> void:
	city = main
	layer = CanvasLayer.new()
	layer.name = "EditorLayer"
	layer.layer = 5
	city.add_child(layer)
	var root := Control.new()
	root.name = "Editor"
	root.theme = load("res://ui/lapis_gold.tres")
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	# The game's own interface has nothing to do here.
	city.hud.visible = false
	markers = Node3D.new()
	markers.name = "EditorStroke"
	city.world.add_child(markers)
	build_bar(root)
	build_tools(root)
	episodes = Episodes.new()
	episodes.attach(self, root)
	world = World.new()
	world.attach(self, root)
	quit_dialog = ConfirmationDialog.new()
	quit_dialog.name = "EditorQuit"
	quit_dialog.exclusive = true
	quit_dialog.ok_button_text = tr("Save and quit")
	quit_dialog.add_button(tr("Quit without saving"), true, "discard")
	quit_dialog.confirmed.connect(func():
		save()
		city.return_to_start())
	quit_dialog.custom_action.connect(func(action):
		if action == "discard":
			quit_dialog.hide()
			city.return_to_start())
	root.add_child(quit_dialog)
	refresh()

func query(command: String) -> Dictionary:
	return city.core.query(command)

# The adventure's overview (title, saved or not), from the core.
func refresh() -> void:
	overview = query("editor")
	if overview.has("error"):
		status.text = tr("The editor could not read the adventure")
		return
	var labels: Dictionary = overview.get("labels", {})
	var name := str(overview.get("title", ""))
	title_label.text = tr("Adventure editor") + ("  —  " + name if not name.is_empty() else "")
	bar.get_node("%EditorEpisodes").text = tr("Episodes")
	bar.get_node("%EditorWorld").text = str(labels.get("edit_world", tr("World map")))
	bar.get_node("%EditorSave").text = str(labels.get("save", tr("Save")))
	bar.get_node("%EditorQuitButton").text = str(labels.get("quit", tr("Quit")))
	quit_dialog.title = str(labels.get("save_question", tr("Save the adventure?")))
	quit_dialog.dialog_text = str(labels.get("save_detail", tr("Save your changes before quitting?")))
	status.text = tr("All changes saved") if bool(overview.get("saved", true)) else tr("Unsaved changes")

func build_bar(root: Control) -> void:
	bar = PanelContainer.new()
	bar.name = "EditorBar"
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-430, 12)
	bar.custom_minimum_size = Vector2(860, 0)
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	title_label = Label.new()
	title_label.theme_type_variation = "Subheading"
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(title_label)
	status = Label.new()
	status.theme_type_variation = "Caption"
	column.add_child(status)
	for entry in [["EditorEpisodes", func(): episodes.open()], ["EditorWorld", func(): world.open()], ["EditorSave", save], ["EditorQuitButton", ask_quit]]:
		var button := Button.new()
		button.name = entry[0]
		button.unique_name_in_owner = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[1])
		if entry[0] == "EditorSave":
			button.theme_type_variation = "Primary"
		row.add_child(button)
		button.owner = bar

func build_tools(root: Control) -> void:
	tools_panel = PanelContainer.new()
	tools_panel.name = "EditorTools"
	tools_panel.position = Vector2(12, 96)
	tools_panel.custom_minimum_size = Vector2(270, 0)
	root.add_child(tools_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(270, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tools_panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	var heading := Label.new()
	heading.theme_type_variation = "Subheading"
	heading.text = tr("Terrain")
	column.add_child(heading)
	var brush_row := HBoxContainer.new()
	column.add_child(brush_row)
	brush_kind = OptionButton.new()
	brush_kind.name = "BrushKind"
	for entry in [["brush", "Brush"], ["square", "Square"], ["apply", "Area"]]:
		brush_kind.add_item(tr(entry[1]))
		brush_kind.set_item_metadata(brush_kind.item_count - 1, entry[0])
	brush_kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brush_row.add_child(brush_kind)
	brush_size = SpinBox.new()
	brush_size.name = "BrushSize"
	brush_size.min_value = 1
	brush_size.max_value = 5
	brush_size.value = 1
	brush_size.tooltip_text = tr("Brush size")
	brush_row.add_child(brush_size)
	brush_kind.item_selected.connect(func(_slot):
		brush_size.editable = brush() != "apply"
		brush_size.max_value = 6 if brush() == "square" else 5)
	number_row = HBoxContainer.new()
	number_row.visible = false
	var number_label := Label.new()
	number_label.text = tr("Number")
	number_label.theme_type_variation = "Caption"
	number_row.add_child(number_label)
	number_box = SpinBox.new()
	number_box.name = "ToolNumber"
	number_box.min_value = 1
	number_box.max_value = 8
	number_box.value = 1
	number_row.add_child(number_box)
	column.add_child(number_row)
	city_row = HBoxContainer.new()
	city_row.visible = false
	city_box = OptionButton.new()
	city_box.name = "ToolCity"
	city_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	city_row.add_child(city_box)
	column.add_child(city_row)
	for category in CATEGORIES:
		var title := Label.new()
		title.text = tr(category[0])
		title.theme_type_variation = "Caption"
		column.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2
		column.add_child(grid)
		for entry in category[1]:
			var button := Button.new()
			button.name = "Tool_" + entry[0]
			button.text = tr(entry[1])
			button.toggle_mode = true
			button.button_group = group
			button.focus_mode = Control.FOCUS_NONE
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.tooltip_text = tr(entry[1])
			var id: String = entry[0]
			button.toggled.connect(func(on: bool):
				if on:
					choose(id)
				elif tool == id:
					choose(""))
			grid.add_child(button)
			tool_buttons[id] = button

func brush() -> String:
	return str(brush_kind.get_item_metadata(brush_kind.selected))

# Chooses a terrain tool ("" for none: the map's clicks go back to the camera and the inspector).
func choose(id: String) -> void:
	tool = id
	if id.is_empty():
		var pressed := group.get_pressed_button()
		if pressed != null:
			pressed.set_pressed_no_signal(false)
	elif tool_buttons.has(id) and not tool_buttons[id].button_pressed:
		tool_buttons[id].set_pressed_no_signal(true)
	number_row.visible = id in NUMBERED
	city_row.visible = id in CITY_TOOLS
	if city_row.visible and city_box.item_count == 0:
		city_box.add_item(tr("Neutral territory"), -1)
		for item in query("cities").get("cities", []):
			city_box.add_item(str(item.name), int(item.id))
		city_box.selected = mini(1, city_box.item_count - 1)
	clear_stroke()

func tool_number() -> int:
	if tool in CITY_TOOLS:
		return city_box.get_item_id(city_box.selected) if city_box.selected >= 0 else -1
	return int(number_box.value) if tool in NUMBERED else 1

# One stroke of the chosen tool over `cells` (the engine's editor code does the change). The answer, or an error.
func paint(cells: Array) -> Dictionary:
	if tool.is_empty() or cells.is_empty():
		return {"error": "no_tool"}
	var words := PackedStringArray(["editor_paint", tool, str(tool_number()), brush(), str(int(brush_size.value))])
	for cell in cells:
		words.append(str(cell.x))
		words.append(str(cell.y))
	var answer: Dictionary = query(" ".join(words))
	if answer.has("error"):
		status.text = tr("That cannot be painted there")
	else:
		status.text = tr("Unsaved changes")
	return answer

# The map's input while a tool is chosen: a stroke from press to release; the right button puts the tool down. True when used.
func input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if not tool.is_empty():
			choose("")
		elif episodes.visible() or world.visible():
			episodes.close()
			world.close()
		else:
			ask_quit()
		return true
	if tool.is_empty():
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		choose("")
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			city.pick_tile(event.position)
			if not city.tiles.has(city.picked):
				return true
			pressing = true
			points = [city.picked]
			draw_stroke()
		elif pressing:
			pressing = false
			var cells: Array = points.duplicate()
			if brush() == "apply" and cells.size() > 1:
				cells = [cells.front(), cells.back()]
			paint(cells)
			clear_stroke()
		return true
	if event is InputEventMouseMotion and pressing:
		city.pick_tile(event.position)
		if city.tiles.has(city.picked):
			if brush() == "apply":
				if points.size() > 1:
					points[1] = city.picked
				else:
					points.append(city.picked)
			elif points.is_empty() or points.back() != city.picked:
				points.append(city.picked)
			draw_stroke()
		return true
	return false

func clear_stroke() -> void:
	for child in markers.get_children():
		markers.remove_child(child)
		child.queue_free()

# Gold plates under the stroke so far: the dragged-out area, or a plate of the brush's size at each point.
func draw_stroke() -> void:
	clear_stroke()
	if points.is_empty():
		return
	var paint_material := StandardMaterial3D.new()
	paint_material.albedo_color = STROKE_COLOR
	paint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint_material.no_depth_test = true
	var cells: Array = []
	var span := 1.0
	if brush() == "apply":
		var a: Vector2i = points.front()
		var b: Vector2i = points.back()
		for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
			for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
				cells.append(Vector2i(x, y))
	else:
		cells = points
		span = brush_size.value * (1.4 if brush() == "brush" else 1.0)
	var plate := BoxMesh.new()
	plate.size = Vector3(span, .04, span)
	plate.material = paint_material
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = plate
	many.instance_count = cells.size()
	for index in cells.size():
		var cell: Vector2i = cells[index]
		var at: Vector3 = city.world_position(cell.x, cell.y, 0)
		at.y = city.terrain_height_world(at.x, at.z) + .08
		many.set_instance_transform(index, Transform3D(Basis(), at))
	var shown := MultiMeshInstance3D.new()
	shown.multimesh = many
	shown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	markers.add_child(shown)

func save() -> void:
	var answer: Dictionary = query("editor_save")
	status.text = tr("The adventure could not be saved") if answer.has("error") else tr("All changes saved")

func ask_quit() -> void:
	refresh()
	if bool(overview.get("saved", true)):
		city.return_to_start()
		return
	quit_dialog.popup_centered()

func mark_changed() -> void:
	status.text = tr("Unsaved changes")
