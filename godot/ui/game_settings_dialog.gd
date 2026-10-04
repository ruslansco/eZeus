extends AcceptDialog
# The play options that are neither keys nor sizes (scripts/play_settings.gd): how often the city saves itself and how many autosaves are kept,
# the language of the voices and links to display/interface/controls settings. Each change applies at once and is remembered per user (user://settings.cfg).

signal changed

const PlaySettings = preload("res://scripts/play_settings.gd")

var choices: Dictionary = {}
var settings_buttons: Dictionary = {}

static func open(parent: Node) -> Window:
	var dialog: Window = load("res://ui/game_settings_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered()
	return dialog

func _init() -> void:
	exclusive = true

func _ready() -> void:
	get_tree().root.get_node("UiAccess").dialog_open=true
	title = tr("Game settings")
	ok_button_text = tr("Done")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	option_row(column, "autosave_minutes", "Autosave", func(value): return tr("Off") if int(value) == 0 else tr("Every %d minutes") % int(value))
	option_row(column, "autosave_slots", "Autosaves kept", func(value): return "%d" % int(value))
	var note := Label.new()
	note.text = tr("Autosaves count only while the game is running, and rotate through the slots.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 420
	note.theme_type_variation = "Caption"
	column.add_child(note)
	option_row(column, "voice_language", "Voice language", func(value): return tr("Same as the interface") if str(value) == "auto" else ("English" if str(value) == "en" else "Русский"))
	for spec in [["display", "Display settings…", "res://ui/display_dialog.gd"],
		["interface", "Interface options…", "res://ui/interface_dialog.gd"],
		["controls", "Controls…", "res://ui/controls_dialog.gd"]]:
		var button := Button.new()
		button.text = tr(spec[1])
		button.pressed.connect(func(): open_settings(spec[2]))
		column.add_child(button)
		settings_buttons[spec[0]] = button
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

# One line: the caption and a choice among the option's own values, worded by `word`.
func option_row(parent: Control, option: String, caption: String, word: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := Label.new()
	label.text = tr(caption)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 190
	row.add_child(label)
	var choice := OptionButton.new()
	choice.custom_minimum_size.x = 210
	choice.focus_mode = Control.FOCUS_NONE
	var values: Array = PlaySettings.OPTIONS[option][2]
	for value in values:
		choice.add_item(str(word.call(value)))
	choice.select(values.find(PlaySettings.get_option(option)))
	choice.item_selected.connect(func(index):
		PlaySettings.set_option(option, values[index])
		changed.emit())
	row.add_child(choice)
	parent.add_child(row)
	choices[option] = choice

func open_settings(script: String) -> void:
	hide()
	get_tree().root.get_node("UiAccess").dialog_open=false
	var dialog: Window = load(script).open(get_parent())
	if dialog == null:
		get_tree().root.get_node("UiAccess").dialog_open=true
		popup_centered()
		return
	if dialog.has_signal("changed"): dialog.changed.connect(func(): changed.emit())
	dialog.tree_exited.connect(func():
		if is_inside_tree() and not is_queued_for_deletion():
			get_tree().root.get_node("UiAccess").dialog_open=true
			popup_centered.call_deferred())

func _exit_tree() -> void:
	get_tree().root.get_node("UiAccess").dialog_open=false
