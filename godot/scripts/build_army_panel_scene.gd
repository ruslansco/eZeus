extends SceneTree
# One-off generator for res://ui/army_panel.tscn: the army panel (the companies of the city, orders for all of them or
# one). It is added to the HUD, so it inherits the HUD's theme, and sits in the slot the building inspector uses. After
# generation the .tscn is the source of truth: edit the layout in the Godot editor, and do not rerun this script over
# those edits.
#   godot --headless --path godot --script res://scripts/build_army_panel_scene.gd

const OUTPUT := "res://ui/army_panel.tscn"
var root_node: PanelContainer

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

func button(node_name: String, parent: Node, variation := "") -> Button:
	var item: Button = make(Button, node_name, parent)
	item.custom_minimum_size = Vector2(0, 38)
	item.focus_mode = Control.FOCUS_NONE
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if variation != "":
		item.theme_type_variation = variation
	return item

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root_node = PanelContainer.new()
	root_node.name = "ArmyPanel"
	root_node.visible = false
	root_node.anchor_left = 1.0
	root_node.anchor_right = 1.0
	root_node.anchor_bottom = 1.0
	root_node.offset_left = -404
	root_node.offset_top = 72
	root_node.offset_right = -16
	root_node.offset_bottom = -180
	root_node.set_script(load("res://ui/army_panel.gd"))
	var column: VBoxContainer = make(VBoxContainer, "ArmyColumn", root_node, false)
	column.add_theme_constant_override("separation", 8)
	var header: HBoxContainer = make(HBoxContainer, "ArmyHeader", column, false)
	var title := label("ArmyTitle", header, "Heading")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := button("ArmyClose", header, "Quiet")
	close.custom_minimum_size = Vector2(30, 30)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label("ArmySummary", column, "Caption", true)
	var actions: HBoxContainer = make(HBoxContainer, "ArmyActions", column, false)
	actions.add_theme_constant_override("separation", 8)
	button("CallAll", actions, "Primary")
	button("HomeAll", actions)
	var scroll: ScrollContainer = make(ScrollContainer, "ArmyScroll", column, false)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list: VBoxContainer = make(VBoxContainer, "ArmyList", scroll)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	label("ArmyEmpty", column, "Caption", true)
	var detail: PanelContainer = make(PanelContainer, "ArmyDetail", column)
	detail.theme_type_variation = "Card"
	var detail_column: VBoxContainer = make(VBoxContainer, "DetailColumn", detail, false)
	detail_column.add_theme_constant_override("separation", 6)
	label("DetailName", detail_column, "Subheading", true)
	label("DetailInfo", detail_column, "Caption", true)
	var detail_row: HBoxContainer = make(HBoxContainer, "DetailRow", detail_column, false)
	detail_row.add_theme_constant_override("separation", 6)
	button("DetailGo", detail_row)
	button("DetailToggle", detail_row, "Primary")
	button("DetailPlace", detail_column)
	var scene := PackedScene.new()
	var error := scene.pack(root_node)
	if error != OK:
		push_error("Packing the army panel failed: %d" % error)
		quit(1)
		return
	error = ResourceSaver.save(scene, OUTPUT)
	print("ARMY_PANEL_SCENE ", "saved" if error == OK else "failed %d" % error)
	quit(0 if error == OK else 1)
