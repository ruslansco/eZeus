extends AcceptDialog
# A measured, paged native story. The full string remains available; no scroll bar.
var original := ""
var parts: Array[String] = []
var page := 0
var body: Label
var count: Label
var previous: Button
var next: Button
var computing := false
var slot: Control

static func open(host: Control, caption: String, text: String) -> Window:
	var reader = load("res://ui/menu_text_reader.gd").new()
	reader.original = text
	reader.title = caption
	reader.theme = host.theme
	host.add_child(reader)
	reader.popup_centered()
	return reader

func _ready() -> void:
	ok_button_text = tr("Back")
	exclusive = true
	get_ok_button().theme_type_variation = "ParchmentPageButton"
	var sheet := PanelContainer.new()
	sheet.theme_type_variation = "ParchmentSheet"
	add_child(sheet)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",16)
	sheet.add_child(layout)
	slot = Control.new()
	slot.clip_contents = true
	slot.custom_minimum_size = Vector2(620,300)
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(slot)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.theme_type_variation = "EpisodeBody"
	slot.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	layout.add_child(row)
	previous = Button.new(); previous.theme_type_variation = "ParchmentPageButton"; previous.text = tr("Previous page"); row.add_child(previous)
	count = Label.new(); count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; count.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(count)
	count.theme_type_variation = "AdventureBodyText"
	next = Button.new(); next.theme_type_variation = "ParchmentPageButton"; next.text = tr("Next page"); row.add_child(next)
	previous.pressed.connect(func(): page = maxi(0,page-1); show_text())
	next.pressed.connect(func(): page = mini(parts.size()-1,page+1); show_text())
	confirmed.connect(queue_free); canceled.connect(queue_free); close_requested.connect(queue_free)
	get_tree().root.size_changed.connect(fit)
	fit.call_deferred()

func fit() -> void:
	if computing: return
	var available := get_tree().root.get_visible_rect().size
	slot.custom_minimum_size = Vector2(minf(680,available.x-180),minf(370,available.y-240))
	size = Vector2i(slot.custom_minimum_size+Vector2(96,180))
	position = Vector2i((available-Vector2(size))*.5)
	paginate.call_deferred()

func paginate() -> void:
	computing = true
	await get_tree().process_frame
	await get_tree().process_frame
	parts.clear()
	var font := body.get_theme_font("font")
	var font_size := body.get_theme_font_size("font_size")
	var offset := 0
	while offset < original.length():
		var low := 1
		var high := original.length()-offset
		while low < high:
			var mid := (low+high+1)/2
			var height := font.get_multiline_string_size(original.substr(offset,mid),HORIZONTAL_ALIGNMENT_LEFT,maxf(100,body.size.x),font_size).y
			var lines := maxi(1,ceili(height/font.get_height(font_size)))
			height += (lines-1)*body.get_theme_constant("line_spacing")
			if height <= maxf(100,body.size.y)-12: low = mid
			else: high = mid-1
		var length := low
		if offset+length < original.length():
			var cut := original.substr(offset,length).rfind(" ")
			if cut > 0: length = cut+1
		parts.append(original.substr(offset,length))
		offset += length
	if parts.is_empty(): parts.append("")
	page = clampi(page,0,parts.size()-1)
	computing = false
	show_text()

func show_text() -> void:
	body.text = parts[page]
	count.text = tr("Page %d of %d") % [page+1,parts.size()]
	previous.disabled = page == 0
	next.disabled = page >= parts.size()-1
