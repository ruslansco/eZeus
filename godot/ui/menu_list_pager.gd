extends RefCounted
# Catalog indexes remain authoritative; only visible rows are paged. No native
# observation, ownership, game state or save path is changed by filtering.
signal selected(index: int)
signal filtered(has_results: bool)
var list: ItemList
var search: LineEdit
var previous: Button
var next: Button
var counter: Label
var records: Array = []
var matches: Array[int] = []
var page := 0
var per_page := 8
var selected_index := -1
var label: Callable
var multiline := false
var rebuilding := false

func setup(view: ItemList, prompt: String, lines := false) -> void:
	list = view
	multiline = lines
	list.max_text_lines = 2 if lines else 1
	list.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	list.add_theme_constant_override("v_separation",8)
	search = LineEdit.new()
	search.name = "CatalogSearch"
	search.placeholder_text = tr(prompt)
	search.set_meta("prompt",prompt)
	var parent := list.get_parent()
	parent.add_child(search)
	parent.move_child(search,list.get_index())
	search.text_changed.connect(func(_text): filter_records())
	var bar := HBoxContainer.new()
	bar.name = "CatalogPages"
	bar.add_theme_constant_override("separation",8)
	parent.add_child(bar)
	parent.move_child(bar,list.get_index()+1)
	previous = Button.new()
	previous.theme_type_variation = "MainMenuUtility"
	previous.name = "PreviousPage"
	previous.text = "‹"
	previous.tooltip_text = tr("Previous page")
	previous.custom_minimum_size = Vector2(38,32)
	bar.add_child(previous)
	counter = Label.new()
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.theme_type_variation = "Caption"
	bar.add_child(counter)
	next = Button.new()
	next.theme_type_variation = "MainMenuUtility"
	next.name = "NextPage"
	next.text = "›"
	next.tooltip_text = tr("Next page")
	next.custom_minimum_size = Vector2(38,32)
	bar.add_child(next)
	previous.pressed.connect(func(): turn(-1))
	next.pressed.connect(func(): turn(1))
	list.item_selected.connect(func(index):
		if index < 0 or index >= list.item_count: return
		selected_index = int(list.get_item_metadata(index))
		selected.emit(selected_index))
	list.resized.connect(fit.call_deferred)
	list.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_PAGEDOWN: turn(1); list.accept_event()
			elif event.keycode == KEY_PAGEUP: turn(-1); list.accept_event())

func set_records(values: Array, display: Callable) -> void:
	records = values
	label = display
	search.text = ""
	selected_index = 0 if not records.is_empty() else -1
	filter_records(false)

func filter_records(notify := true) -> void:
	matches.clear()
	var query := search.text.strip_edges().to_lower()
	for i in records.size():
		if query.is_empty() or str(label.call(records[i])).to_lower().contains(query): matches.append(i)
	page = 0
	if not matches.has(selected_index): selected_index = matches[0] if not matches.is_empty() else -1
	rebuild()
	filtered.emit(not matches.is_empty())
	if notify and selected_index >= 0: selected.emit(selected_index)

func fit() -> void:
	if rebuilding or list.size.y < 1: return
	var font := list.get_theme_font("font")
	var row := font.get_height(list.get_theme_font_size("font_size"))*(2 if multiline else 1)+10
	var rows := clampi(floori((list.size.y-24)/row),1,12)
	if rows == per_page: return
	per_page = rows
	var found := matches.find(selected_index)
	page = found/per_page if found >= 0 else 0
	rebuild()

func rebuild() -> void:
	rebuilding = true
	list.clear()
	page = clampi(page,0,maxi(0,(matches.size()-1)/per_page))
	for offset in range(page*per_page,mini(matches.size(),(page+1)*per_page)):
		var index: int = matches[offset]
		var text := str(label.call(records[index]))
		list.add_item(text)
		list.set_item_metadata(list.item_count-1,index)
		list.set_item_tooltip(list.item_count-1,text)
		if index == selected_index: list.select(list.item_count-1)
	previous.disabled = page == 0
	next.disabled = (page+1)*per_page >= matches.size()
	counter.text = tr("No matches") if matches.is_empty() else tr("Page %d of %d") % [page+1,maxi(1,ceili(matches.size()/float(per_page)))]
	list.get_v_scroll_bar().value = 0
	rebuilding = false

func turn(by: int) -> void:
	var target := page+by
	if target < 0 or target*per_page >= matches.size(): return
	page = target
	selected_index = matches[page*per_page]
	rebuild()
	selected.emit(selected_index)
	list.grab_focus()

func select_index(index: int, notify := true) -> void:
	var found := matches.find(index)
	if found < 0: return
	selected_index = index
	page = found/per_page
	rebuild()
	if notify: selected.emit(index)
