extends PanelContainer
# A presentation-only disclosure. Reading a message never answers a native event.
signal dismiss_requested(id: int)
signal expansion_requested(chip: Control)

var message_id := -1
var title_text := ""
var body_text := ""
var date_text := ""
var lifetime := 0.0
var remaining := 0.0
var expanded := false
var heading: Button
var body_scroll: ScrollContainer
var progress: ProgressBar
var hovered := false
var date_label: Label
var history_row := false
var notice_icon: Texture2D
var pressed_button := MOUSE_BUTTON_NONE
# A city notice is shown in full from the start (set before it enters the tree); a click pins it open with more room.
var open := false
const OPEN_HEIGHT := 132.0
const PINNED_HEIGHT := 260.0

func configure(id: int, title: String, body: String, seconds := 0.0, date := "") -> void:
	message_id = id; title_text = title; body_text = body; lifetime = seconds; remaining = seconds; date_text = date
	set_meta("id", id)

func _ready() -> void:
	theme_type_variation = "JournalRow" if history_row else "NoticeCard"
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	add_child(column)
	if open:
		focus_mode = Control.FOCUS_ALL
		tooltip_text = _heading_tip(title_text)
	else:
		heading = Button.new()
		heading.theme_type_variation = "NoticeButton"
		heading.text = title_text
		heading.toggle_mode = true
		heading.icon = notice_icon if notice_icon != null else preload("res://ui/icons/message.svg")
		heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.tooltip_text = _heading_tip(title_text)
		heading.pressed.connect(func(): set_expanded(not expanded))
		column.add_child(heading)
	if not date_text.is_empty():
		date_label = Label.new()
		date_label.theme_type_variation = "Detail"
		date_label.text = date_text
		date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(date_label)
	body_scroll = ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.visible = open
	if open: body_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(body_scroll)
	var body := Label.new()
	body.theme_type_variation = "NoticeBody" if open else "Caption"
	body.text = _display_body()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_scroll.add_child(body)
	if lifetime > 0:
		progress = ProgressBar.new()
		progress.theme_type_variation = "NoticeProgress"
		progress.custom_minimum_size.y = 2
		progress.show_percentage = false
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.value = 100
		column.add_child(progress)
	if lifetime > 0 and not get_tree().root.get_node("UiAccess").reduced_motion:
		modulate.a = 0
		create_tween().tween_property(self, "modulate:a", 1.0, .18)
	if open: _fit_body.call_deferred()
	set_process(lifetime > 0)

# Update in place so refreshes retain keyboard focus, reading and scroll identity.
func update_text(title: String, body: String, date: String) -> void:
	title_text = title; body_text = body; date_text = date
	if heading != null:
		heading.text = title
		heading.tooltip_text = _heading_tip(title)
	else:
		tooltip_text = _heading_tip(title)
	body_scroll.get_child(0).text = _display_body()
	if date_label != null: date_label.text = date

func _heading_tip(title: String) -> String:
	var tip := title + "\n" + (tr("Click to keep this message open") if open else tr("Click to read the full message"))
	if open: tip += "\n" + tr("Right-click: %s") % tr("Dismiss notification")
	return tip

func _display_body() -> String:
	return title_text if open and body_text.is_empty() else body_text

# The compact notice itself owns release activation; its scroll bar still owns scrolling.
func _gui_input(event: InputEvent) -> void:
	if not open: return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.pressed:
			pressed_button = event.button_index
		else:
			var activate: bool = pressed_button == event.button_index and Rect2(Vector2.ZERO,size).has_point(event.position)
			pressed_button = MOUSE_BUTTON_NONE
			if activate:
				if event.button_index == MOUSE_BUTTON_LEFT: set_expanded(not expanded)
				elif lifetime > 0: dismiss_requested.emit(message_id)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		set_expanded(not expanded)
		accept_event()

# An open notice's text, up to OPEN_HEIGHT (PINNED_HEIGHT once pinned); longer text scrolls.
func _fit_body() -> void:
	if body_scroll == null: return
	var wanted: float = body_scroll.get_child(0).get_combined_minimum_size().y + 4
	var height := minf(PINNED_HEIGHT if expanded else OPEN_HEIGHT, wanted)
	if not is_equal_approx(body_scroll.custom_minimum_size.y, height):
		body_scroll.custom_minimum_size.y = height
	# The parent VBox owns our width. reset_size() discards its allotted width;
	# wrapped text then leaves a narrow minimum until another sort.

func set_expanded(value: bool) -> void:
	expanded = value
	body_scroll.visible = value or open
	if heading != null: heading.button_pressed = value
	set_process(lifetime > 0 or value)
	if value:
		expansion_requested.emit(self)

func _process(delta: float) -> void:
	if open:
		_fit_body()
	elif expanded:
		body_scroll.custom_minimum_size.y = minf(180, body_scroll.get_child(0).get_combined_minimum_size().y + 4)
	if lifetime <= 0 or not is_visible_in_tree() or expanded:
		return
	# A clipped chip is not being shown to the player. Static history rows need no per-frame work.
	var visible_area := get_global_rect().intersection(get_viewport_rect())
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			visible_area = visible_area.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	# Descendant buttons own hover, so use the visible card rectangle rather than mouse-enter signals.
	hovered = visible_area.has_point(get_global_mouse_position())
	if not visible_area.has_area() or hovered:
		return
	remaining = maxf(0, remaining - delta)
	progress.value = remaining / lifetime * 100
	if remaining == 0:
		set_process(false)
		dismiss_requested.emit(message_id)
