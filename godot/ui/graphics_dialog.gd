extends ConfirmationDialog
const Options = preload("res://scripts/graphics_settings.gd")
var choice: OptionButton
var description: Label
var write_error: Label
var original := Options.DEFAULT
var committed := false
var access: Node

static func open(parent: Node) -> Window:
	if parent.get_tree().root.get_node("UiAccess").dialog_open: return null
	var dialog: Window = load("res://ui/graphics_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered()
	return dialog

func _init() -> void:
	exclusive = true
	dialog_hide_on_ok = false

func _ready() -> void:
	access = get_tree().root.get_node("UiAccess")
	access.dialog_open = true
	original = Options.current
	title = tr("Graphics settings")
	ok_button_text = tr("Apply")
	cancel_button_text = tr("Cancel")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	var note := Label.new()
	note.text = tr("Preview the city now. Apply remembers this choice; Cancel restores the previous graphics.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 430
	column.add_child(note)
	choice = OptionButton.new()
	for caption in ["Balanced", "High"]: choice.add_item(tr(caption))
	choice.select(Options.ORDER.find(original))
	choice.item_selected.connect(func(_index): preview())
	column.add_child(choice)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 430
	description.theme_type_variation = "Caption"
	column.add_child(description)
	write_error = Label.new()
	write_error.text = tr("Could not save graphics settings. Cancel restores your previous choice.")
	write_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	write_error.hide()
	column.add_child(write_error)
	update_description()
	confirmed.connect(func():
		if Options.commit(Options.ORDER[choice.selected]) != OK:
			write_error.show(); return
		committed = true; queue_free())
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

func update_description() -> void:
	description.text = tr({
		"balanced": "The current city appearance: full 3D resolution, smooth edges, sun shadows and normal ground foliage.",
		"high": "Full 3D resolution, more detailed distant meshes, farther shadows and ground foliage. Uses more graphics power.",
	}[Options.ORDER[choice.selected]])

func preview() -> void:
	Options.apply(get_tree(), Options.ORDER[choice.selected])
	update_description()
	write_error.hide()
	reset_size()
	popup_centered.call_deferred()

func _exit_tree() -> void:
	if not committed: Options.apply(get_tree(), original)
	access.dialog_open = false
