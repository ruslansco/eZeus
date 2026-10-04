extends AcceptDialog
# The SDL mythology page: the city's sanctuaries with the state of each (working, sacrificing, waiting for materials, being built), the gods
# that are attacking it and the monsters at large in it, each with a button that takes the camera there. The core words it (`mythology`
# query) from the game's own text table, so the headings follow its language.

static func open(parent: Node, core: Node, jump: Callable) -> Window:
	var dialog: Window = load("res://ui/mythology_dialog.gd").new()
	dialog.jump = jump
	parent.add_child(dialog)
	dialog.fill(core.query("mythology"))
	dialog.popup_centered(Vector2i(620, 520))
	return dialog

var jump: Callable
var rows := 0

func _ready() -> void:
	title = tr("Mythology")
	ok_button_text = tr("Done")
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

func heading(parent: Node, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "Subheading"
	label.text = text
	parent.add_child(label)

func row(parent: Node, text: String, detail: String, cell: Vector2i) -> void:
	rows += 1
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.text = text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	if detail != "":
		var state := Label.new()
		state.theme_type_variation = "Caption"
		state.text = detail
		line.add_child(state)
	var show := Button.new()
	show.text = tr("Show")
	show.focus_mode = Control.FOCUS_NONE
	show.pressed.connect(func():
		if jump.is_valid():
			jump.call(cell)
		queue_free())
	line.add_child(show)
	parent.add_child(line)

func none(parent: Node, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "Caption"
	label.text = text
	parent.add_child(label)

func fill(answer: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	scroll.add_child(column)
	var titles: Dictionary = answer.get("titles", {})
	heading(column, "%s  (%d / %d)" % [str(titles.get("sanctuaries", "")), answer.get("sanctuaries", []).size(), int(answer.get("max", 0))])
	if answer.get("sanctuaries", []).is_empty():
		none(column, str(titles.get("none", "")))
	for sanctuary in answer.get("sanctuaries", []):
		var detail := str(sanctuary.state)
		if not bool(sanctuary.finished):
			detail += "  %d%%" % int(sanctuary.progress)
		row(column, "%s — %s" % [str(sanctuary.god_name), str(sanctuary.name)], detail, Vector2i(int(sanctuary.x), int(sanctuary.y)))
	heading(column, str(titles.get("gods", "")))
	if answer.get("gods_attacking", []).is_empty():
		none(column, str(titles.get("none", "")))
	for god in answer.get("gods_attacking", []):
		row(column, str(god.name), "", Vector2i(int(god.x), int(god.y)))
	heading(column, str(titles.get("monsters", "")))
	if answer.get("monsters", []).is_empty():
		none(column, str(titles.get("none", "")))
	for monster in answer.get("monsters", []):
		row(column, str(monster.name), "", Vector2i(int(monster.x), int(monster.y)))
