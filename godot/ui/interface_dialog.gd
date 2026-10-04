extends ConfirmationDialog
# Live preview with explicit Apply/Cancel; only Apply saves sizes and motion preference.
var sizes: Dictionary={}
var original:=Vector2i(100,100)
var access: Node
var committed:=false
var original_motion := false
var write_error: Label

static func open(parent: Node) -> Window:
	var service: Node=parent.get_tree().root.get_node("UiAccess")
	if service.dialog_open:return null
	var dialog: Window=load("res://ui/interface_dialog.gd").new()
	parent.add_child(dialog)
	dialog.popup_centered()
	return dialog

func _init() -> void:exclusive=true

func _ready() -> void:
	access=get_tree().root.get_node("UiAccess")
	access.dialog_open=true
	original=Vector2i(access.ui_size,access.text_size)
	original_motion=access.reduced_motion
	title=tr("Interface options")
	ok_button_text=tr("Apply")
	cancel_button_text=tr("Cancel")
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",14)
	add_child(column)
	var note:=Label.new()
	note.text=tr("Preview changes now. Apply remembers them; Cancel restores your previous sizes.")
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x=420
	column.add_child(note)
	for spec in [["ui", "Interface size",access.UI_SIZES,access.ui_size],["text","Text size",access.TEXT_SIZES,access.text_size]]:
		var row:=HBoxContainer.new()
		var caption:=Label.new()
		caption.text=tr(spec[1]);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(caption)
		var choice:=OptionButton.new()
		for percent in spec[2]:choice.add_item("%d%%"%percent,percent)
		choice.select(spec[2].find(spec[3]))
		row.add_child(choice);column.add_child(row)
		sizes[spec[0]]=choice
		choice.item_selected.connect(func(_index):preview())
	var motion := CheckButton.new()
	motion.text = tr("Reduce interface motion")
	motion.button_pressed = access.reduced_motion
	motion.toggled.connect(func(value): access.reduced_motion=value)
	column.add_child(motion)
	var reset:=Button.new()
	reset.text=tr("Restore default sizes")
	reset.pressed.connect(func():
		sizes.ui.select(0);sizes.text.select(0);preview())
	column.add_child(reset)
	write_error=Label.new()
	write_error.text=tr("Could not save preferences. Your previous sizes will be restored when you cancel.")
	write_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	write_error.visible=false;column.add_child(write_error)
	dialog_hide_on_ok=false
	confirmed.connect(func():
		if access.save_preferences()!=OK:
			write_error.show();return
		committed=true;queue_free())
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

func preview() -> void:
	access.apply(sizes.ui.get_selected_id(),sizes.text.get_selected_id())
	reset_size()
	popup_centered.call_deferred()

func _exit_tree() -> void:
	# Restore after this embedded Window has left the tree, so Theme resize work cannot target it.
	if not committed:access.apply.call_deferred(original.x,original.y)
	if not committed:access.reduced_motion=original_motion
	access.dialog_open=false
