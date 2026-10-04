extends SceneTree
# One-off generator for res://ui/episode_card.tscn: the card every episode screen uses (the briefing before an episode,
# its result, the choice of colony, the end of the adventure, a defeat). After generation the .tscn is the source of
# truth: edit the layout in the Godot editor, and do not rerun this script over those edits.
#   godot --headless --path godot --script res://scripts/build_episode_card_scene.gd

const OUTPUT := "res://ui/episode_card.tscn"
var card_root: VBoxContainer

func make(type: Variant, node_name: String, parent: Node, unique := true) -> Node:
	var node: Node = type.new()
	node.name = node_name
	parent.add_child(node)
	node.owner = card_root
	if unique:
		node.unique_name_in_owner = true
	return node

func label(node_name: String, parent: Node, variation := "", wrap := true) -> Label:
	var item: Label = make(Label, node_name, parent)
	if variation != "":
		item.theme_type_variation = variation
	if wrap:
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func button(node_name: String, parent: Node, primary := false) -> Button:
	var item: Button = make(Button, node_name, parent)
	item.custom_minimum_size = Vector2(0, 46)
	if primary:
		item.theme_type_variation = "Primary"
	return item

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	card_root = VBoxContainer.new()
	card_root.name = "EpisodeCard"
	card_root.add_theme_constant_override("separation", 10)
	card_root.set_script(load("res://ui/episode_card.gd"))
	label("Heading", card_root, "Heading")
	label("Subtitle", card_root, "Subheading")
	var scroll: ScrollContainer = make(ScrollContainer, "Scroll", card_root)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 120)
	label("Body", scroll, "")
	var colonies: ItemList = make(ItemList, "Colonies", card_root)
	colonies.custom_minimum_size = Vector2(0, 150)
	colonies.visible = false
	label("GoalsHeading", card_root, "Subheading", false)
	make(VBoxContainer, "Goals", card_root)
	var difficulty := HBoxContainer.new()
	difficulty.name = "DifficultyRow"
	difficulty.unique_name_in_owner = true
	difficulty.add_theme_constant_override("separation", 12)
	card_root.add_child(difficulty)
	difficulty.owner = card_root
	var difficulty_label: Label = make(Label, "DifficultyLabel", difficulty)
	difficulty_label.theme_type_variation = "Caption"
	var down: Button = make(Button, "DifficultyDown", difficulty)
	down.text = "◀"
	down.focus_mode = Control.FOCUS_NONE
	var value: Label = make(Label, "DifficultyValue", difficulty)
	value.theme_type_variation = "Value"
	value.custom_minimum_size.x = 140
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var up: Button = make(Button, "DifficultyUp", difficulty)
	up.text = "▶"
	up.focus_mode = Control.FOCUS_NONE
	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 14)
	card_root.add_child(buttons)
	buttons.owner = card_root
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	spacer.owner = card_root
	button("Secondary", buttons).custom_minimum_size.x = 160
	button("Primary", buttons, true).custom_minimum_size.x = 200
	var scene := PackedScene.new()
	var packed := scene.pack(card_root)
	var saved := ResourceSaver.save(scene, OUTPUT)
	print("CARD packed=", packed, " saved=", saved, " nodes=", card_root.find_children("*", "", true, false).size())
	quit(0 if packed == OK and saved == OK else 1)
