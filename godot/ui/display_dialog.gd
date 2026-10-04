extends ConfirmationDialog
# Apply previews; Keep changes commits. Escape, close, timeout and scene removal restore.
const DisplayOptions = preload("res://scripts/display_settings.gd")
const PREVIEW_SECONDS := 15.0
var choices: Dictionary = {}
var vsync: CheckBox
var options_column: VBoxContainer
var notice: Label
var write_error: Label
var access: Node
var original: Dictionary
var preview_options: Dictionary
var pending := false
var committed := false
var deadline := 0

static func open(parent: Node) -> Window:
	var service: Node = parent.get_tree().root.get_node("UiAccess")
	if service.dialog_open: return null
	var dialog: Window = load("res://ui/display_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered()
	return dialog

func _init() -> void:
	exclusive = true
	dialog_hide_on_ok = false

func _ready() -> void:
	access = get_tree().root.get_node("UiAccess")
	access.dialog_open = true
	original = DisplayOptions.capture(get_tree().root)
	title = tr("Display settings")
	ok_button_text = tr("Apply")
	cancel_button_text = tr("Cancel")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	options_column = VBoxContainer.new()
	options_column.add_theme_constant_override("separation", 12)
	column.add_child(options_column)
	var mode := option_row("mode", "Window mode")
	for item in ["Windowed", "Fullscreen"]: mode.add_item(tr(item))
	mode.select(1 if original.mode == "fullscreen" else 0)
	mode.item_selected.connect(func(_index): update_mode())
	var screen := option_row("screen", "Display")
	for index in DisplayServer.get_screen_count():
		var dimensions := DisplayServer.screen_get_size(index)
		screen.add_item(tr("Display %d · %d × %d") % [index + 1, dimensions.x, dimensions.y], index)
	screen.select(maxi(original.screen, 0))
	screen.disabled = screen.item_count <= 1
	screen.item_selected.connect(func(_index): refresh_sizes(selected_size()))
	option_row("window_size", "Window size")
	refresh_sizes(original.window_size)
	var cap := option_row("frame_limit", "Frame-rate limit")
	for limit in DisplayOptions.FRAME_LIMITS:
		cap.add_item(tr("Unlimited") if limit == 0 else tr("%d FPS") % limit, limit)
	cap.select(maxi(DisplayOptions.FRAME_LIMITS.find(original.frame_limit), 0))
	vsync = CheckBox.new()
	vsync.text = tr("VSync")
	vsync.tooltip_text = tr("Synchronize frames with the display to reduce tearing.")
	vsync.button_pressed = original.vsync
	options_column.add_child(vsync)
	notice = Label.new()
	notice.custom_minimum_size.x = 440
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.theme_type_variation = "Caption"
	column.add_child(notice)
	write_error = Label.new()
	write_error.text = tr("Could not save display settings. Revert to try again.")
	write_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	write_error.visible = false
	column.add_child(write_error)
	update_mode()
	confirmed.connect(apply_or_keep)
	canceled.connect(cancel)
	close_requested.connect(cancel)
	get_tree().root.size_changed.connect(recenter)

func option_row(key: String, caption: String) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = tr(caption)
	label.custom_minimum_size.x = 170
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var choice := OptionButton.new()
	choice.custom_minimum_size.x = 250
	row.add_child(choice)
	options_column.add_child(row)
	choices[key] = choice
	return choice

func selected_size() -> Vector2i:
	var choice: OptionButton = choices.window_size
	return choice.get_item_metadata(choice.selected) if choice.item_count > 0 else original.window_size

func refresh_sizes(wanted: Vector2i) -> void:
	var choice: OptionButton = choices.window_size
	choice.clear()
	var screen: int = choices.screen.get_selected_id()
	var available := DisplayOptions.usable_size(screen)
	var sizes: Array = DisplayOptions.available_sizes(screen, wanted)
	for dimensions in sizes:
		var text := "%d × %d" % [dimensions.x, dimensions.y]
		if dimensions == available: text += " · " + tr("Fit to display")
		choice.add_item(text)
		choice.set_item_metadata(choice.item_count - 1, dimensions)
	choice.select(sizes.find(DisplayOptions.fitted_size(wanted, available)))
	update_mode()

func update_mode() -> void:
	if not choices.has("window_size"): return
	choices.window_size.disabled = choices.mode.selected == 1
	if notice == null: return
	notice.text = tr("Fullscreen uses your desktop resolution. Window sizes fit the selected display. Apply previews for 15 seconds.")

func apply_or_keep() -> void:
	if pending:
		if DisplayOptions.commit(preview_options) != OK:
			write_error.show(); return
		committed = true
		pending = false
		queue_free()
		return
	preview_options = DisplayOptions.apply(get_tree().root, {
		"mode": "fullscreen" if choices.mode.selected == 1 else "windowed",
		"screen": choices.screen.get_selected_id(), "window_size": selected_size(),
		"vsync": vsync.button_pressed, "frame_limit": choices.frame_limit.get_selected_id()})
	pending = true
	deadline = Time.get_ticks_msec() + int(PREVIEW_SECONDS * 1000)
	options_column.hide()
	ok_button_text = tr("Keep changes")
	cancel_button_text = tr("Revert")
	update_countdown()
	recenter()

func _process(_delta: float) -> void:
	if not pending: return
	if Time.get_ticks_msec() >= deadline: revert(); return
	update_countdown()

func update_countdown() -> void:
	var remaining := maxi(ceili((deadline - Time.get_ticks_msec()) / 1000.0), 0)
	notice.text = tr("Keep these display settings? Reverting in %d seconds.") % remaining

func recenter() -> void:
	if visible and not is_queued_for_deletion() and get_tree().root.size.x > 0 and get_tree().root.size.y > 0:
		reset_size()
		popup_centered.call_deferred()

func revert() -> void:
	pending = false
	DisplayOptions.restore(get_tree().root, original)
	options_column.show()
	ok_button_text = tr("Apply")
	cancel_button_text = tr("Cancel")
	write_error.hide()
	update_mode()
	recenter()

func cancel() -> void:
	if pending: revert()
	else: queue_free()

func _exit_tree() -> void:
	if pending and not committed: DisplayOptions.restore.call_deferred(get_tree().root, original)
	if is_instance_valid(access): access.dialog_open = false

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		if pending: revert()
		queue_free()
