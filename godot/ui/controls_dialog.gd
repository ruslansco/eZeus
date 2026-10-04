extends AcceptDialog
# The controls: every key the player may rebind (scripts/key_bindings.gd), how fast the camera moves, and the controls that cannot change.
# A click on a key asks for the new one; Escape cancels; a key another control has is swapped with it. Changes apply at once and are remembered
# per user (user://settings.cfg). Built in code because it is a plain stack of rows, styled by the theme of the interface it opens in.

signal changed

const KeyBindings = preload("res://scripts/key_bindings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")

# What does not change, as [key or mouse text, what it does]; both are tr() keys.
const FIXED := [
	["Escape", "Cancel the tool, a drag or a window"],
	["Delete", "Demolition tool (as the demolition key)"],
	["Shift", "Pan faster; with a wall tool, fill the rectangle"],
	["Mouse wheel", "Zoom to the pointer"],
	["Middle button drag", "Orbit and tilt the camera"],
	["Left button", "Place a building or inspect it"],
	["Right button", "Cancel selection or close a panel; inspect a tile; move the selected banner"],
	["Left / Right", "On the world map: the previous and the next city"],
]
const SPEEDS := [["pan_percent", "Pan speed"], ["turn_percent", "Turn and tilt speed"], ["zoom_percent", "Zoom speed"]]

var key_buttons: Dictionary = {}
var scroller: ScrollContainer
var reset_buttons: Dictionary = {}
var speed_choices: Dictionary = {}
var message: Label
var waiting := ""
var access: Node

static func open(parent: Node) -> Window:
	var dialog: Window = load("res://ui/controls_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered(Vector2i(660, 620))
	return dialog

func _init() -> void:
	exclusive = false

func _ready() -> void:
	access = get_tree().root.get_node_or_null("UiAccess")
	title = tr("Controls")
	ok_button_text = tr("Done")
	var defaults := add_button(tr("Restore defaults"), false, "defaults")
	defaults.focus_mode = Control.FOCUS_NONE
	custom_action.connect(func(action): if action == "defaults": restore_defaults())
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(610, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	scroller = scroll
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	for group in KeyBindings.GROUPS:
		heading(column, group)
		for entry in KeyBindings.actions():
			if entry.group == group:
				column.add_child(key_row(entry))
		if group == "Camera":
			heading(column, "Camera speed")
			for spec in SPEEDS:
				column.add_child(speed_row(spec[0], spec[1]))
	heading(column, "Fixed controls")
	for line in FIXED:
		var row := HBoxContainer.new()
		var key := Label.new()
		key.text = tr(line[0])
		key.custom_minimum_size.x = 170
		row.add_child(key)
		var does := Label.new()
		does.text = tr(line[1])
		does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		does.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		does.theme_type_variation = "Caption"
		row.add_child(does)
		column.add_child(row)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(610, 44)
	message.text = tr("Click a key to change it; Escape cancels.")
	outer.add_child(message)
	window_input.connect(_on_window_input)
	confirmed.connect(close)
	canceled.connect(close)
	close_requested.connect(close)
	refresh()

func heading(parent: Control, text_key: String) -> void:
	var label := Label.new()
	label.text = tr(text_key)
	label.theme_type_variation = "Subheading"
	parent.add_child(label)

func key_row(entry: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = tr(entry.label)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var key := Button.new()
	key.custom_minimum_size.x = 150
	key.pressed.connect(func(): begin_capture(entry.id))
	row.add_child(key)
	var reset := Button.new()
	reset.text = tr("Reset")
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(func(): reset_key(entry.id))
	row.add_child(reset)
	key_buttons[entry.id] = key
	reset_buttons[entry.id] = reset
	return row

func speed_row(option: String, label_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = tr(label_key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var choice := OptionButton.new()
	choice.custom_minimum_size.x = 150
	choice.focus_mode = Control.FOCUS_NONE
	var values: Array = PlaySettings.OPTIONS[option][2]
	for percent in values:
		choice.add_item("%d%%" % int(percent), int(percent))
	choice.select(values.find(PlaySettings.get_option(option)))
	choice.item_selected.connect(func(index):
		PlaySettings.set_option(option, int(values[index])))
	row.add_child(choice)
	speed_choices[option] = choice
	return row

# Scrolls the list so that a control's row is in view (a reviewer's, and the keyboard's, convenience).
func scroll_to(id: String) -> void:
	await get_tree().process_frame
	scroller.ensure_control_visible(key_buttons[id])

# What each button says: the key now, or the request while one is being asked for.
func refresh() -> void:
	for id in key_buttons:
		var button: Button = key_buttons[id]
		button.text = tr("Press a key…") if id == waiting else KeyBindings.label(id)
		reset_buttons[id].visible = KeyBindings.is_custom(id)

# ---- asking for a key -------------------------------------------------------------------------------------------------------
func begin_capture(id: String) -> void:
	waiting = id
	if access != null:
		access.dialog_open = true
	message.text = tr("Press the new key for %s. Escape cancels.") % tr(KeyBindings.definition(id).label)
	refresh()

func end_capture() -> void:
	waiting = ""
	if access != null:
		access.dialog_open = false
	refresh()

func _on_window_input(event: InputEvent) -> void:
	if waiting == "" or not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		message.text = tr("Nothing was changed.")
		end_capture()
		return
	# A modifier on its own is the start of a combination: keep waiting.
	if event.physical_keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return
	assign_from_event(event)

# Gives the key of an event to the control being set (the dialog's own path, and the tests').
func assign_from_event(event: InputEventKey) -> Dictionary:
	if waiting == "":
		return {"ok": false, "reason": "not_waiting", "swapped": ""}
	var id := waiting
	var value := KeyBindings.encode(event)
	var result := KeyBindings.assign(id, value)
	var name := tr(KeyBindings.definition(id).label)
	var key_name := KeyBindings.text(value)
	if result.ok:
		if str(result.swapped) != "":
			message.text = tr("%s is now %s. %s took %s.") % [name, key_name, tr(KeyBindings.definition(str(result.swapped)).label), KeyBindings.label(str(result.swapped))]
		else:
			message.text = tr("%s is now %s.") % [name, key_name]
		changed.emit()
	elif result.reason == "reserved":
		message.text = tr("%s cannot be used for a control.") % key_name
	elif result.reason == "modifier":
		message.text = tr("%s takes a plain key, without Ctrl, Cmd or Alt.") % name
	else:
		message.text = tr("%s is used for %s, which cannot take %s.") % [key_name, tr(KeyBindings.definition(str(result.swapped)).label), KeyBindings.label(id)]
	end_capture()
	return result

func reset_key(id: String) -> void:
	if waiting != "":
		end_capture()
	if KeyBindings.reset(id):
		message.text = tr("%s is back to %s.") % [tr(KeyBindings.definition(id).label), KeyBindings.label(id)]
		changed.emit()
	else:
		message.text = tr("%s cannot go back to its key: another control that cannot take your key for it has it.") % tr(KeyBindings.definition(id).label)
	refresh()

func restore_defaults() -> void:
	if waiting != "":
		end_capture()
	KeyBindings.reset_all()
	for option in speed_choices:
		PlaySettings.set_option(option, PlaySettings.default_of(option))
		var values: Array = PlaySettings.OPTIONS[option][2]
		speed_choices[option].select(values.find(PlaySettings.default_of(option)))
	message.text = tr("All controls are back to their defaults.")
	changed.emit()
	refresh()

func close() -> void:
	if access != null:
		access.dialog_open = false
	queue_free()
