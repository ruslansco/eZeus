extends Control
# This menu owns presentation input only. main.gd holds/restores the native clock and queue.
signal closed
signal action_requested(action: String)
signal language_requested

var hud: Control
var buttons := {}
var language_choice: OptionButton
var caption: Label
var headings := {}
var panel := PanelContainer.new()
var access: Node
var child_window: Window

func _ready() -> void:
	name="EscapeMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	access=get_tree().root.get_node("UiAccess")
	access.dialog_open=true
	var shade:=ColorRect.new()
	shade.color=Color(.015,.035,.05,.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	margin.add_child(scroll)
	var center:=CenterContainer.new()
	center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	panel.theme_type_variation="EscapeCard"
	center.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	panel.add_child(column)
	add_heading(column,"Game menu","Heading")
	var rule:=HSeparator.new();rule.theme_type_variation="EscapeRule"
	column.add_child(rule)
	caption=Label.new();caption.theme_type_variation="Caption"
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_child(caption)
	var body:=GridContainer.new();body.columns=2
	body.add_theme_constant_override("h_separation",20);body.add_theme_constant_override("v_separation",6)
	column.add_child(body)
	add_heading(body,"Your city","EscapeHeading");add_heading(body,"Settings","EscapeHeading")
	for pair in [["resume","display"],["save","interface"],["load","controls"],["quick_save","sound"],["quick_load","settings"],["main_menu","language"]]:
		for action in pair:
			if action=="language":
				language_choice=OptionButton.new();language_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				language_choice.add_item("English");language_choice.add_item("Русский")
				language_choice.item_selected.connect(func(index):
					var wanted: String="ru" if index==1 else "en"
					if TranslationServer.get_locale().get_slice("_",0)!=wanted:language_requested.emit()
					retranslate())
				body.add_child(language_choice)
			else:add_action(body,action)
	add_heading(column,"City views","EscapeHeading")
	var views:=GridContainer.new();views.columns=2
	views.add_theme_constant_override("h_separation",20);views.add_theme_constant_override("v_separation",6)
	column.add_child(views)
	for action in ["city","world","army","mythology","trade","attention","guide"]:add_action(views,action)
	access.changed.connect(fit)
	resized.connect(fit)
	retranslate();fit()
	buttons.resume.grab_focus()

func add_heading(parent: Control, text: String, variation: String) -> void:
	var label:=Label.new();label.theme_type_variation=variation
	parent.add_child(label);headings[text]=label

func add_action(parent: Control, action: String) -> void:
	var button:=Button.new()
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y=34
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.theme_type_variation="Primary" if action=="resume" else "EscapeAction"
	button.pressed.connect(func():
		if action=="resume":closed.emit()
		else:action_requested.emit(action))
	parent.add_child(button);buttons[action]=button

func retranslate() -> void:
	for text in headings:headings[text].text=tr(text)
	caption.text=str(hud.city_header.get("name",""))+" · "+tr("City paused · Escape to return")
	for action in buttons:buttons[action].text=tr("Return to city") if action=="resume" else hud.menu_action_text(action)
	language_choice.select(1 if TranslationServer.get_locale().begins_with("ru") else 0)
	language_choice.tooltip_text=tr("Interface language")
	fit()

func fit() -> void:
	if not is_node_ready():return
	panel.custom_minimum_size.x=minf(660,maxf(0,size.x-48))

func suspend() -> void:
	hide();access.dialog_open=false

func watch(window: Window, permanent := false) -> void:
	child_window=window
	access.dialog_open=true
	if permanent:
		window.visibility_changed.connect(func():
			if is_instance_valid(child_window) and child_window==window and not window.visible:restore.call_deferred(),CONNECT_ONE_SHOT)
	else:window.tree_exited.connect(func():restore.call_deferred(),CONNECT_ONE_SHOT)

func restore() -> void:
	if not is_inside_tree() or is_queued_for_deletion():return
	child_window=null;access.dialog_open=true;show();retranslate();buttons.resume.grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:return
	if (event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_ESCAPE or event.keycode==KEY_ESCAPE)) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT):
		get_viewport().set_input_as_handled();closed.emit()

func _exit_tree() -> void:
	if visible and is_instance_valid(access):access.dialog_open=false
