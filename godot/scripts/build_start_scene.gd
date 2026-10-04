extends SceneTree
# One-off generator for res://ui/start_menu.tscn: the start menu's pages as real nodes (unique names the script reads
# as %Name). After generation the .tscn is the source of truth: edit the layout in the Godot editor, and do not rerun
# this script over those edits.
#   godot --headless --path godot --script res://scripts/build_start_scene.gd

const OUTPUT := "res://ui/start_menu.tscn"

var root_node: Control

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

func button(node_name: String, parent: Node, primary := false) -> Button:
	var item: Button = make(Button, node_name, parent)
	item.focus_mode = Control.FOCUS_ALL
	item.custom_minimum_size = Vector2(0, 46)
	if primary:
		item.theme_type_variation = "Primary"
	return item

func page(node_name: String, width: float, height := 0.0) -> PanelContainer:
	var card: PanelContainer = make(PanelContainer, node_name, root_node.get_node("Center"))
	card.custom_minimum_size = Vector2(width, height)
	card.visible = false
	return card

func row(node_name: String, parent: Node) -> HBoxContainer:
	var item: HBoxContainer = make(HBoxContainer, node_name, parent, false)
	item.add_theme_constant_override("separation", 14)
	return item

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root_node = Control.new()
	root_node.name = "StartMenu"
	root_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_node.theme = load("res://ui/lapis_gold.tres")
	root_node.set_script(load("res://ui/start_menu.gd"))

	var backdrop: TextureRect = make(TextureRect, "Backdrop", root_node, false)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sky := Gradient.new()
	sky.colors = PackedColorArray([Color(.02, .04, .1), Color(.05, .11, .24), Color(.12, .24, .38)])
	sky.offsets = PackedFloat32Array([0.0, .62, 1.0])
	var gradient := GradientTexture2D.new()
	gradient.gradient = sky
	gradient.fill_from = Vector2(.5, 0)
	gradient.fill_to = Vector2(.5, 1)
	gradient.width = 8
	gradient.height = 256
	backdrop.texture = gradient

	var center: CenterContainer = make(CenterContainer, "Center", root_node, false)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Main page: title, the four ways in, language and quit.
	var main_page := page("MainPage", 460)
	var main_column: VBoxContainer = make(VBoxContainer, "MainColumn", main_page, false)
	main_column.add_theme_constant_override("separation", 12)
	var title := label("Title", main_column, "Heading")
	title.add_theme_font_size_override("font_size", 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tagline := label("Tagline", main_column, "Caption")
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	make(HSeparator, "MainRule", main_column, false)
	var continue_button := button("Continue", main_column, true)
	var continue_info := label("ContinueInfo", main_column, "Detail")
	continue_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button("NewGame", main_column)
	button("LoadGame", main_column)
	var footer := row("MainFooter", main_column)
	var language: Button = button("Language", footer)
	language.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quit: Button = button("Quit", footer)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Adventure page: the list of adventures and what the chosen one is about.
	var adventure_page := page("AdventurePage", 1040, 560)
	var adventure_column: VBoxContainer = make(VBoxContainer, "AdventureColumn", adventure_page, false)
	adventure_column.add_theme_constant_override("separation", 12)
	label("AdventureHeading", adventure_column, "Heading")
	var adventure_body := row("AdventureBody", adventure_column)
	adventure_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var adventure_list: ItemList = make(ItemList, "AdventureList", adventure_body)
	adventure_list.custom_minimum_size = Vector2(380, 0)
	var adventure_detail: VBoxContainer = make(VBoxContainer, "AdventureDetail", adventure_body, false)
	adventure_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adventure_detail.add_theme_constant_override("separation", 10)
	label("AdventureTitle", adventure_detail, "Subheading", true)
	var adventure_scroll: ScrollContainer = make(ScrollContainer, "AdventureScroll", adventure_detail, false)
	adventure_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	adventure_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	label("AdventureText", adventure_scroll, "", true)
	label("AdventureStatus", adventure_column, "Detail", true)
	var adventure_buttons := row("AdventureButtons", adventure_column)
	var adventure_spacer: Control = make(Control, "AdventureSpacer", adventure_buttons, false)
	adventure_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("AdventureBack", adventure_buttons).custom_minimum_size.x = 140
	button("AdventureStart", adventure_buttons, true).custom_minimum_size.x = 200

	# Introduction page: the first episode's story and goals, before the city opens.
	var intro_page := page("IntroPage", 820, 580)
	var intro_column: VBoxContainer = make(VBoxContainer, "IntroColumn", intro_page, false)
	intro_column.add_theme_constant_override("separation", 10)
	label("IntroHeading", intro_column, "Heading", true)
	label("EpisodeTitle", intro_column, "Subheading", true)
	var intro_scroll: ScrollContainer = make(ScrollContainer, "IntroScroll", intro_column, false)
	intro_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	label("IntroText", intro_scroll, "", true)
	label("GoalsHeading", intro_column, "Subheading")
	make(VBoxContainer, "IntroGoals", intro_column)
	var intro_buttons := row("IntroButtons", intro_column)
	var intro_spacer: Control = make(Control, "IntroSpacer", intro_buttons, false)
	intro_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("IntroBack", intro_buttons).custom_minimum_size.x = 140
	button("IntroBegin", intro_buttons, true).custom_minimum_size.x = 200

	# Load page: the player's saved games.
	var load_page := page("LoadPage", 640, 520)
	var load_column: VBoxContainer = make(VBoxContainer, "LoadColumn", load_page, false)
	load_column.add_theme_constant_override("separation", 12)
	label("LoadHeading", load_column, "Heading")
	var save_list: ItemList = make(ItemList, "SaveList", load_column)
	save_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label("SaveInfo", load_column, "Detail", true)
	var load_buttons := row("LoadButtons", load_column)
	var load_spacer: Control = make(Control, "LoadSpacer", load_buttons, false)
	load_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("LoadBack", load_buttons).custom_minimum_size.x = 140
	button("LoadOpen", load_buttons, true).custom_minimum_size.x = 200

	var scene := PackedScene.new()
	var packed := scene.pack(root_node)
	var saved := ResourceSaver.save(scene, OUTPUT)
	print("START packed=", packed, " saved=", saved, " nodes=", root_node.find_children("*", "", true, false).size())
	quit(0 if packed == OK and saved == OK else 1)
