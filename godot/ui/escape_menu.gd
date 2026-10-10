extends Control
# Presentation pages only. main.gd holds/restores the native clock and command queue.
signal closed
signal action_requested(action: String)

const PAGE_TITLES := {"home":"Game menu", "saves":"Saved games", "settings":"Settings", "city":"City views", "help":"Help"}
const PAGE_ACTIONS := {
	"saves":["save","load","quick_save","quick_load"],
	"settings":["display","graphics","sound","interface","controls","settings"],
	"city":["city","world","army","mythology","trade"],
	"help":["attention","guide"],
}
const SETTING_LABELS := {"display":"Display", "graphics":"Graphics", "sound":"Sound", "interface":"Interface", "controls":"Controls", "settings":"Gameplay"}
var hud: Control
var buttons := {}
var navigation_buttons := {}
var pages := {}
var grids := {}
var page := "home"
var last_action := "resume"
var caption: Label
var title_label: Label
var back_button: Button
var panel := PanelContainer.new()
var access: Node
var child_window: Window
var shade := ColorRect.new()

func _ready() -> void:
	name = "EscapeMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	access = get_tree().root.get_node("UiAccess")
	access.dialog_open = true
	shade.color = Color(.015,.035,.05,.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the scenic shade behind native child windows while the page is hidden.
	hud.add_child(shade); hud.move_child(shade,get_index())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	panel.theme_type_variation = "EscapeCard"
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	title_label = Label.new()
	title_label.theme_type_variation = "GameMenuTitle"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	caption = Label.new()
	caption.theme_type_variation = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(caption)
	var rule := HSeparator.new(); rule.theme_type_variation = "EscapeRule"
	column.add_child(rule)
	var home := page_column(column,"home")
	add_action(home,"resume")
	var home_grid := page_grid(home,"home")
	for destination in ["saves","settings","city","help"]:
		var button := make_button("GameMenuAction")
		button.pressed.connect(func(): show_page(destination))
		home_grid.add_child(button); navigation_buttons[destination] = button
	var exit_rule := HSeparator.new(); exit_rule.theme_type_variation = "EscapeRule"
	home.add_child(exit_rule)
	add_action(home,"main_menu")
	for destination in PAGE_ACTIONS:
		var body := page_column(column,destination)
		var grid := page_grid(body,destination)
		for action in PAGE_ACTIONS[destination]: add_action(grid,action)
	back_button = make_button("GameMenuAction")
	back_button.pressed.connect(go_back)
	column.add_child(back_button)
	access.changed.connect(fit)
	resized.connect(fit)
	retranslate(); show_page("home")

func page_column(parent: Control, destination: String) -> VBoxContainer:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	parent.add_child(body); pages[destination] = body
	return body

func page_grid(parent: Control, destination: String) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",12)
	parent.add_child(grid); grids[destination] = grid
	return grid

func make_button(variation: String) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 52
	button.theme_type_variation = variation
	return button

func add_action(parent: Control, action: String) -> void:
	var button := make_button("GameMenuPrimary" if action == "resume" else "GameMenuAction")
	button.pressed.connect(func():
		last_action = action
		if action == "resume": closed.emit()
		else: action_requested.emit(action))
	parent.add_child(button); buttons[action] = button

func show_page(destination: String) -> void:
	page = destination
	for key in pages: pages[key].visible = key == page
	back_button.visible = page != "home"
	retranslate()
	link_focus()
	panel.reset_size()
	if page == "home": buttons.resume.grab_focus()
	else: buttons[PAGE_ACTIONS[page][0]].grab_focus()

func focus_controls() -> Array:
	if page == "home": return [buttons.resume,navigation_buttons.saves,navigation_buttons.settings,navigation_buttons.city,navigation_buttons.help,buttons.main_menu]
	var controls: Array = PAGE_ACTIONS[page].map(func(action): return buttons[action])
	controls.append(back_button)
	return controls

func link_focus() -> void:
	var controls := focus_controls()
	for index in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index-1+controls.size())%controls.size()])

func go_back() -> void:
	if page == "home": closed.emit(); return
	var previous := page
	show_page("home")
	navigation_buttons[previous].grab_focus()

func retranslate() -> void:
	title_label.text = tr(PAGE_TITLES[page])
	caption.text = str(hud.city_header.get("name",""))+" · "+tr("City paused · Escape to return" if page == "home" else "City paused · Escape to go back")
	for action in buttons:
		buttons[action].text = tr("Return to city") if action == "resume" else (tr(SETTING_LABELS[action]) if SETTING_LABELS.has(action) else hud.menu_action_text(action))
	for destination in navigation_buttons: navigation_buttons[destination].text = tr(PAGE_TITLES[destination])
	back_button.text = tr("Back")
	fit()

func fit() -> void:
	if not is_node_ready(): return
	# Columns and frame width adapt to measured text; fonts never shrink to fit.
	var width := 620.0
	for destination in grids:
		var grid: GridContainer = grids[destination]
		var longest := 0.0
		for button in grid.get_children(): longest = maxf(longest,button.get_combined_minimum_size().x)
		grid.columns = 2 if longest*2+102 <= size.x-48 else 1
		if destination == page: width = maxf(width,longest*grid.columns+102)
	panel.custom_minimum_size.x = minf(width,maxf(0,size.x-48))
	panel.reset_size()

func suspend() -> void:
	hide(); access.dialog_open = false

func watch(window: Window, permanent := false) -> void:
	child_window = window
	if window is AcceptDialog:
		window.theme = access.shared.duplicate()
		for kind in ["AcceptDialog","ConfirmationDialog"]:
			window.theme.set_constant("buttons_min_height",kind,48)
			window.theme.set_constant("buttons_min_width",kind,150)
		window.get_ok_button().theme_type_variation = "GameMenuPrimary"
		for button in window.get_ok_button().get_parent().get_children(true):
			if button is Button and button != window.get_ok_button(): button.theme_type_variation = "GameMenuAction"
		window.reset_size(); window.popup_centered()
	if preload("res://ui/settings_shell.gd").accepts(window) and not window.has_meta("settings_shell"):
		preload("res://ui/settings_shell.gd").new().setup(window,self,true)
	access.dialog_open = true
	if permanent:
		window.visibility_changed.connect(func():
			if is_instance_valid(child_window) and child_window == window and not window.visible: restore.call_deferred(),CONNECT_ONE_SHOT)
	else: window.tree_exited.connect(func(): restore.call_deferred(),CONNECT_ONE_SHOT)

func restore() -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	child_window = null; access.dialog_open = true; show(); retranslate()
	buttons[last_action].grab_focus()

func _input(event: InputEvent) -> void:
	if not visible: return
	if (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE)) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		get_viewport().set_input_as_handled(); go_back()

func _exit_tree() -> void:
	if is_instance_valid(shade): shade.queue_free()
	if visible and is_instance_valid(access): access.dialog_open = false
