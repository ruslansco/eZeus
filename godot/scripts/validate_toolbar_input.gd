extends SceneTree
# Presentation-only mouse/keyboard regression. These ordinary, untagged events
# deliberately separate mouse-down from mouse-up, as hardware input does.
# A deferred focus release on mouse-down passed same-frame review clicks but
# canceled real Button activation before the later release arrived.
const ToolbarButton = preload("res://ui/toolbar_button.gd")
var okay := true
var checks := 0
var callbacks := {}

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("TOOLBAR_INPUT_CHECK ", "PASS " if value else "FAIL ", description)

func _initialize() -> void:
	root.size = Vector2i(640, 480)
	# A failed coroutine must not leave an owned validation process running.
	create_timer(15.0).timeout.connect(func():
		push_error("Toolbar input validation timed out")
		quit(2))
	run.call_deferred()

func frames(count := 2) -> void:
	for _index in count:
		await process_frame

func button_at(name: String, scripted: bool) -> Button:
	var button: Button = ToolbarButton.new() if scripted else Button.new()
	button.name = name
	button.text = name
	button.position = Vector2(40, 40)
	button.size = Vector2(180, 50)
	button.focus_mode = Control.FOCUS_ALL
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	callbacks[name] = 0
	button.pressed.connect(func(): callbacks[name] += 1)
	root.add_child(button)
	return button

func pointer(button: Button, pressed: bool, outside := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	event.position = button.position + (Vector2(button.size.x + 90, button.size.y + 70) if outside else button.size * .5)
	event.global_position = event.position
	root.push_input(event, true)

func motion(button: Button, outside: bool, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = button.position + (Vector2(button.size.x + 90, button.size.y + 70) if outside else button.size * .5)
	event.global_position = event.position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)

func enter(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = pressed
	root.push_input(event, true)

func free_button(button: Button) -> void:
	button.queue_free()
	await frames()

func run() -> void:
	var plain := button_at("Plain", false)
	await frames()
	pointer(plain, true)
	await frames()
	check(plain.has_focus() and callbacks.Plain == 0, "plain Button is armed across mouse-down frames")
	pointer(plain, false)
	await frames()
	check(callbacks.Plain == 1 and plain.has_focus(), "plain Button baseline activates once on later mouse-up")
	await free_button(plain)

	var button := button_at("Momentary", true)
	await frames()
	pointer(button, true)
	check(button.has_focus(), "scripted Button receives pointer focus on mouse-down")
	await frames(3)
	check(button.has_focus() and callbacks.Momentary == 0, "scripted Button retains focus and does not activate while held")
	pointer(button, false)
	check(callbacks.Momentary == 1, "scripted Button activates once before deferred pointer-focus release")
	await frames()
	check(not button.has_focus(), "scripted Button releases pointer focus after mouse-up")

	button.grab_focus()
	enter(true)
	await frames()
	check(button.has_focus(), "Enter-down retains keyboard focus")
	enter(false)
	await frames()
	check(callbacks.Momentary == 2 and button.has_focus(), "Enter activates once and retains focus for keyboard navigation")
	button.release_focus()

	pointer(button, true)
	await frames()
	motion(button, true, true)
	await frames()
	pointer(button, false, true)
	await frames()
	check(callbacks.Momentary == 2, "dragging and releasing outside cancels activation")
	check(not button.has_focus(), "canceled pointer click also returns focus to the city")
	motion(button, false, false)
	pointer(button, true)
	await frames()
	pointer(button, false)
	await frames()
	check(callbacks.Momentary == 3, "a normal click works after a canceled drag")
	await free_button(button)

	var toggle := button_at("Toggle", true)
	toggle.toggle_mode = true
	await frames()
	pointer(toggle, true)
	await frames()
	check(toggle.has_focus() and not toggle.button_pressed, "toggle waits for mouse-up while retaining pointer focus")
	pointer(toggle, false)
	await frames()
	check(toggle.button_pressed and callbacks.Toggle == 1 and not toggle.has_focus(), "first separated click switches toggle on once")
	pointer(toggle, true)
	await frames()
	check(toggle.has_focus() and toggle.button_pressed, "active toggle remains on during the next held press")
	pointer(toggle, false)
	await frames()
	check(not toggle.button_pressed and callbacks.Toggle == 2 and not toggle.has_focus(), "second separated click switches toggle off once")
	await free_button(toggle)

	var menu := MenuButton.new()
	menu.set_script(ToolbarButton)
	menu.name = "Menu"
	menu.text = "Menu"
	menu.position = Vector2(40, 40)
	menu.size = Vector2(180, 50)
	menu.focus_mode = Control.FOCUS_ALL
	menu.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	menu.switch_on_hover = false
	var selections := {"count":0}
	var popup := menu.get_popup()
	popup.add_item("First item", 0)
	popup.add_item("Second item", 1)
	popup.index_pressed.connect(func(_index): selections.count += 1)
	root.add_child(menu)
	await frames()
	pointer(menu, true)
	await frames(3)
	check(menu.has_focus() and not popup.visible, "scripted release-mode MenuButton stays armed without opening on mouse-down")
	pointer(menu, false)
	await frames(3)
	check(popup.visible, "scripted MenuButton opens its popup after a later mouse-up")
	check(selections.count == 0, "the opening click does not select a popup item")
	popup.hide()
	await frames()
	menu.queue_free()
	await frames()

	print("TOOLBAR_INPUT_COUNTS ", JSON.stringify(callbacks), " popup_items_selected=", selections.count)
	print("TOOLBAR_INPUT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
