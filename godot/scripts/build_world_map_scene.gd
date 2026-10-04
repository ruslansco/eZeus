extends SceneTree
# One-off generator for res://ui/world_map.tscn: the world map screen (the map picture with its cities, and the panel of the
# selected city with the dealings the SDL world screen offers). After generation the .tscn is the source of truth: edit the
# layout in the Godot editor, and do not rerun this script over those edits.
#   godot --headless --path godot --script res://scripts/build_world_map_scene.gd

const OUTPUT := "res://ui/world_map.tscn"
var root_node: CanvasLayer

func make(type: Variant, node_name: String, parent: Node, unique := true) -> Node:
	var node: Node = type.new()
	node.name = node_name
	parent.add_child(node)
	node.owner = root_node
	if unique:
		node.unique_name_in_owner = true
	return node

func label(node_name: String, parent: Node, variation := "", wrap := false) -> Label:
	var item: Label = make(Label, node_name, parent)
	if variation != "":
		item.theme_type_variation = variation
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func button(node_name: String, parent: Node, text := "", variation := "") -> Button:
	var item: Button = make(Button, node_name, parent)
	item.text = text
	item.custom_minimum_size = Vector2(0, 40)
	item.focus_mode = Control.FOCUS_NONE
	if variation != "":
		item.theme_type_variation = variation
	return item

func fill(item: Control) -> void:
	item.set_anchors_preset(Control.PRESET_FULL_RECT)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root_node = CanvasLayer.new()
	root_node.name = "WorldMap"
	root_node.layer = 30
	root_node.visible = false
	root_node.set_script(load("res://ui/world_map.gd"))
	var themed: Control = make(Control, "Themed", root_node, false)
	fill(themed)
	themed.theme = load("res://ui/lapis_gold.tres")
	var sea: ColorRect = make(ColorRect, "Sea", themed, false)
	fill(sea)
	sea.color = Color(.03, .06, .12, 1)
	var margin: MarginContainer = make(MarginContainer, "Margin", themed, false)
	fill(margin)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	var row: HBoxContainer = make(HBoxContainer, "Row", margin, false)
	row.add_theme_constant_override("separation", 14)
	var frame: PanelContainer = make(PanelContainer, "MapFrame", row, false)
	frame.theme_type_variation = "Card"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box: Control = make(Control, "MapBox", frame)
	box.clip_contents = true
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map: TextureRect = make(TextureRect, "Map", box)
	fill(map)
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var markers: Control = make(Control, "Markers", box)
	fill(markers)
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side: PanelContainer = make(PanelContainer, "Side", row, false)
	side.theme_type_variation = "Card"
	side.custom_minimum_size = Vector2(380, 0)
	var column: VBoxContainer = make(VBoxContainer, "Column", side, false)
	column.add_theme_constant_override("separation", 8)
	var nav: HBoxContainer = make(HBoxContainer, "Nav", column, false)
	nav.add_theme_constant_override("separation", 6)
	var previous := button("Previous", nav, "◀")
	previous.custom_minimum_size.x = 44
	var header: VBoxContainer = make(VBoxContainer, "Header", nav, false)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in [["Relation", "Caption"], ["Name", "Heading"], ["Leader", "Caption"]]:
		var line := label(item[0], header, item[1], true)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next := button("Next", nav, "▶")
	next.custom_minimum_size.x = 44
	var regard_name := label("RegardName", column, "Value")
	regard_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var regard: ProgressBar = make(ProgressBar, "Regard", column)
	regard.min_value = 0
	regard.max_value = 100
	regard.show_percentage = false
	regard.custom_minimum_size = Vector2(0, 14)
	var scroll: ScrollContainer = make(ScrollContainer, "GoodsScroll", column, false)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var goods: VBoxContainer = make(VBoxContainer, "Goods", scroll)
	goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goods.add_theme_constant_override("separation", 4)
	label("Tribute", column, "Caption", true)
	var actions: GridContainer = make(GridContainer, "Actions", column, false)
	actions.columns = 3
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	for item in [["Request", "Request"], ["Fulfil", "Fulfil"], ["Gift", "Gift"], ["Raid", "Raid"], ["Conquer", "Conquer"], ["Aid", "Aid"]]:
		var action := button(item[0], actions, item[1])
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quests := button("Quests", column, "Quests of the gods")
	quests.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label("Status", column, "Caption", true)
	button("Back", column, "Back to city", "Primary")
	var scene := PackedScene.new()
	var packed := scene.pack(root_node)
	var saved := ResourceSaver.save(scene, OUTPUT)
	print("WORLD_SCENE packed=", packed, " saved=", saved, " nodes=", root_node.find_children("*", "", true, false).size())
	quit(0 if packed == OK and saved == OK else 1)
