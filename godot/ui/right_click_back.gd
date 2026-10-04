extends Node
# Route back through each Window's existing Escape/Cancel/Revert path.
func _ready() -> void:
	var popup := get_parent() as PopupMenu
	if popup != null: popup.window_input.connect(_popup_input)

func _popup_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		get_parent().hide()

func _input(event: InputEvent) -> void:
	var window := get_parent() as Window
	if window == null or not window.visible or window is PopupMenu: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		_dispatch_back.call_deferred(event.get_meta("review_input", false))

func _dispatch_back(review: bool) -> void:
	if not is_inside_tree(): return
	var window := get_parent() as Window
	if window == null or not window.visible: return
	for pressed in [true, false]:
		var back := InputEventKey.new()
		back.physical_keycode = KEY_ESCAPE
		back.keycode = KEY_ESCAPE
		back.pressed = pressed
		if review: back.set_meta("review_input", true)
		get_tree().root.push_input(back, true)
