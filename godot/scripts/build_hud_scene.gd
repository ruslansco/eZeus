extends SceneTree
# One-off generator for res://ui/hud.tscn: lays out the player's interface as real nodes (named, with unique
# names the script reads as %Name) and packs them into a scene. After generation the .tscn is the source of
# truth: edit the layout in the Godot editor, and do not rerun this script over those edits.
#   godot --headless --path godot --script res://scripts/build_hud_scene.gd

const OUTPUT := "res://ui/hud.tscn"

var hud_root: Control

func make(type: Variant, node_name: String, parent: Node, unique := true) -> Node:
	var node: Node = type.new()
	node.name = node_name
	parent.add_child(node)
	node.owner = hud_root
	if unique:
		node.unique_name_in_owner = true
	return node

func label(node_name: String, parent: Node, variation := "") -> Label:
	var item: Label = make(Label, node_name, parent)
	if variation != "":
		item.theme_type_variation = variation
	return item

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	hud_root = Control.new()
	hud_root.name = "Hud"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.theme = load("res://ui/lapis_gold.tres")
	hud_root.set_script(load("res://ui/hud.gd"))

	# Top bar: date, treasury, citizens on the left; pause, speed and language on the right.
	var top: PanelContainer = make(PanelContainer, "TopBar", hud_root, false)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	var top_row: HBoxContainer = make(HBoxContainer, "TopRow", top, false)
	top_row.add_theme_constant_override("separation", 30)
	for pair in [["Date", "Value"], ["Treasury", "Value"], ["Population", "Value"]]:
		var item := label(pair[0], top_row, pair[1])
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	var spacer: Control = make(Control, "Spacer", top_row, false)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pause: Button = make(Button, "Pause", top_row)
	pause.focus_mode = Control.FOCUS_NONE
	pause.custom_minimum_size.x = 130
	var speed: OptionButton = make(OptionButton, "Speed", top_row)
	speed.focus_mode = Control.FOCUS_NONE
	var language: Button = make(Button, "Language", top_row)
	language.focus_mode = Control.FOCUS_NONE

	# Bottom bar: tools and the one-line hint.
	var bottom: PanelContainer = make(PanelContainer, "BottomBar", hud_root, false)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -112
	bottom.offset_bottom = -16
	var column: VBoxContainer = make(VBoxContainer, "BottomColumn", bottom, false)
	column.add_theme_constant_override("separation", 8)
	var tools: HBoxContainer = make(HBoxContainer, "Tools", column, false)
	tools.add_theme_constant_override("separation", 9)
	var tool_buttons: HBoxContainer = make(HBoxContainer, "ToolButtons", tools)
	tool_buttons.add_theme_constant_override("separation", 9)
	var build_menu: MenuButton = make(MenuButton, "BuildMenu", tools)
	build_menu.flat = false
	build_menu.focus_mode = Control.FOCUS_NONE
	var undo: Button = make(Button, "Undo", tools)
	undo.focus_mode = Control.FOCUS_NONE
	var hint := label("Hint", column, "Caption")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Developer overlay (F3): frame rate and coverage, hidden from players.
	var debug: PanelContainer = make(PanelContainer, "DebugPanel", hud_root)
	debug.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	debug.offset_left = 24
	debug.offset_top = -158
	debug.offset_bottom = -124
	debug.visible = false
	var details := label("Details", debug, "Detail")
	details.text = ""

	# Events panel (top left), hidden until the core reports something.
	var events_box: PanelContainer = make(PanelContainer, "EventsBox", hud_root)
	events_box.position = Vector2(24, 88)
	events_box.custom_minimum_size.x = 370
	events_box.visible = false
	make(VBoxContainer, "Events", events_box)

	# Inspector (right): selection text and the building's own controls.
	var inspector: PanelContainer = make(PanelContainer, "Inspector", hud_root)
	inspector.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inspector.anchor_bottom = 1
	inspector.offset_left = -454
	inspector.offset_right = -24
	inspector.offset_top = 88
	inspector.offset_bottom = -128
	inspector.visible = false
	var scroll: ScrollContainer = make(ScrollContainer, "InspectorScroll", inspector, false)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var contents: VBoxContainer = make(VBoxContainer, "InspectorContents", scroll, false)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 14)
	var inspector_text := label("InspectorText", contents)
	inspector_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var controls: VBoxContainer = make(VBoxContainer, "InspectorControls", contents)
	controls.set_script(load("res://scripts/building_inspector.gd"))

	var dialog: ConfirmationDialog = make(ConfirmationDialog, "DemolitionDialog", hud_root)
	dialog.visible = false

	var scene := PackedScene.new()
	var packed := scene.pack(hud_root)
	var saved := ResourceSaver.save(scene, OUTPUT)
	print("HUD packed=", packed, " saved=", saved, " nodes=", hud_root.find_children("*", "", true, false).size())
	quit(0 if packed == OK and saved == OK else 1)
