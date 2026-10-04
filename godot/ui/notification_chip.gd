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

func configure(id: int, title: String, body: String, seconds := 0.0, date := "") -> void:
	message_id = id; title_text = title; body_text = body; lifetime = seconds; remaining = seconds; date_text = date
	set_meta("id", id)

func _ready() -> void:
	theme_type_variation = "JournalRow" if history_row else "NoticeCard"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	heading = Button.new()
	heading.theme_type_variation = "NoticeButton"
	heading.text = title_text
	heading.toggle_mode = true
	heading.icon = preload("res://ui/icons/message.svg")
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.tooltip_text = title_text + "\n" + tr("Click to read the full message")
	heading.pressed.connect(func(): set_expanded(not expanded))
	row.add_child(heading)
	if lifetime > 0:
		var close := Button.new()
		close.theme_type_variation = "Quiet"
		close.icon = preload("res://ui/icons/close.svg")
		close.tooltip_text = tr("Dismiss notification")
		close.pressed.connect(func(): dismiss_requested.emit(message_id))
		row.add_child(close)
	if not date_text.is_empty():
		date_label = Label.new()
		date_label.theme_type_variation = "Detail"
		date_label.text = date_text
		date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(date_label)
	body_scroll = ScrollContainer.new()
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.visible = false
	column.add_child(body_scroll)
	var body := Label.new()
	body.theme_type_variation = "Caption"
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	set_process(lifetime > 0)

# Update in place so refreshes retain keyboard focus, reading and scroll identity.
func update_text(title: String, body: String, date: String) -> void:
	title_text = title; body_text = body; date_text = date
	heading.text = title
	heading.tooltip_text = title + "\n" + tr("Click to read the full message")
	body_scroll.get_child(0).text = body
	if date_label != null: date_label.text = date

func set_expanded(value: bool) -> void:
	expanded = value
	body_scroll.visible = value
	heading.button_pressed = value
	set_process(lifetime > 0 or value)
	if value:
		expansion_requested.emit(self)
	reset_size()

func _process(delta: float) -> void:
	if expanded:
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
