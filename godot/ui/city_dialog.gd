extends AcceptDialog
# The SDL side panel's data pages in one window (F7 or Game, City…): overview, population, employment with the wage rate and
# the workforce allocation (each sector's priority, need and workers; the industries short of workers), administration with
# the tax rate and the city's finances, husbandry, storage, hygiene and safety, appeal, culture, science, military (the
# soldiers' and towers' buttons) and mythology. The core words every line (`city_data`) with the verdicts the SDL pages use
# (engine/ecitydata), so the values follow its language; the tab titles are this interface's. Each page's "See …" buttons
# open its overlay. The window refreshes while it is open; a change is a queued command whose answer is the new data.
# The SDL remaster's extras follow as three more pages: the City Advisor's ranked problems with "Go there" (`city_advisor`), the
# City History chart (`city_history`) and the Trade Summary (`trade_summary`), opened from the summary and storage pages as in
# the SDL panel; the core words them with the same engine code as the SDL windows.

const Goods = preload("res://scripts/goods.gd")
const PAGES := [["overview", "Summary"], ["population", "Population"], ["employment", "Employment"], ["administration", "Administration"],
	["husbandry", "Husbandry"], ["storage", "Storage"], ["hygiene", "Hygiene and safety"], ["appeal", "Appeal"], ["culture", "Culture"],
	["science", "Science"], ["military", "Military"], ["mythology", "Mythology"], ["advisor", "Advisor"], ["history", "History"],
	["trade", "Trade"]]
const TONES := {"text": Color(.93, .90, .84), "dim": Color(.61, .67, .77), "green": Color(.50, .84, .57), "red": Color(.94, .43, .35),
	"amber": Color(1.0, .77, .43), "gold": Color(1.0, .87, .55), "label": Color(.78, .82, .87)}
const HistoryChart = preload("res://ui/history_chart.gd")
# Where each advice's "Go there" goes next, by its key (kept while the game runs, as the SDL view remembers it per problem).
static var advisor_steps := {}
const SEVERITY := [Color(.27, .78, .43), Color(.94, .71, .24), Color(.93, .30, .24)]
const REFRESH_SECONDS := 2.0

static func open(parent: Node, core: Node, overlay: Callable, jump: Callable, page := "overview") -> Window:
	var dialog: Window = load("res://ui/city_dialog.gd").new()
	dialog.core = core
	dialog.overlay = overlay
	dialog.jump = jump
	parent.add_child(dialog)
	dialog.build()
	dialog.show_page(page)
	dialog.refresh()
	dialog.popup_centered(Vector2i(1000, 600))
	return dialog

var core: Node
var overlay: Callable
var jump: Callable
var tabs: TabContainer
var bodies := {}
var data: Dictionary = {}
var age := 0.0
var history_chart: Control
var history_series := 0
var history_span := 0

func _ready() -> void:
	title = tr("City")
	ok_button_text = tr("Done")
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

func build() -> void:
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(960, 490)
	add_child(tabs)
	for page in PAGES:
		var scroll := ScrollContainer.new()
		scroll.name = tr(page[1])
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tabs.add_child(scroll)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)
		scroll.add_child(column)
		bodies[page[0]] = column
	tabs.tab_changed.connect(func(_index): fill())
	if core.has_signal("command_completed"):
		core.command_completed.connect(_on_command_completed)

func show_page(id: String) -> void:
	for index in PAGES.size():
		if PAGES[index][0] == id:
			tabs.current_tab = index

func current_page() -> String:
	return PAGES[tabs.current_tab][0]

func refresh() -> void:
	var answer: Dictionary = core.query("city_data")
	if answer.get("kind", "") == "city_data":
		data = answer
		fill()

func _process(dt: float) -> void:
	age += dt
	# A refresh rebuilds the page: not while one of its lists is open or a button is held.
	if age >= REFRESH_SECONDS and visible and not choosing() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		age = 0.0
		refresh()

func choosing() -> bool:
	for node in bodies[current_page()].find_children("*", "OptionButton", true, false):
		if (node as OptionButton).get_popup().visible:
			return true
	return false

func _on_command_completed(command: String, result: Dictionary) -> void:
	if not is_inside_tree():
		return
	if result.get("kind", "") == "city_data":
		data = result
		fill()
	elif command in ["army_call", "army_home"]:
		refresh()

func send(command: String) -> void:
	if not core.send(command):
		return
	age = 0.0

# ---- building blocks ---------------------------------------------------------------------------------------------
func clear(column: Node) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()

func heading(column: Node, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "Subheading"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)

func caption(column: Node, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = "Caption"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)

# One line of a page: a label and a value, the value tinted by how serious it is (0 good, 1 needs an eye, 2 trouble).
func line(column: Node, text: String, value: String, severity: int) -> void:
	if severity == -2:
		heading(column, text)
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := Label.new()
	name_label.text = text.strip_edges()
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	if value != "":
		var value_label := Label.new()
		value_label.name = "Value"
		value_label.text = value.strip_edges()
		if severity >= 0 and severity < SEVERITY.size():
			value_label.add_theme_color_override("font_color", SEVERITY[severity])
		row.add_child(value_label)
	column.add_child(row)

func views(column: Node, page: Dictionary) -> void:
	if page.get("views", []).is_empty():
		return
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	for view in page.views:
		var button := Button.new()
		button.text = str(view.label)
		button.focus_mode = Control.FOCUS_NONE
		var id := str(view.overlay)
		button.pressed.connect(func():
			if overlay.is_valid():
				overlay.call(id)
			queue_free())
		row.add_child(button)
	column.add_child(HSeparator.new())
	column.add_child(row)

func chooser(names: Array, selected: int, on_choice: Callable) -> OptionButton:
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	for index in names.size():
		option.add_item(str(names[index]), index)
	option.select(selected)
	option.item_selected.connect(on_choice)
	return option

func labelled(column: Node, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(control)
	column.add_child(row)

func page_data(id: String) -> Dictionary:
	for page in data.get("pages", []):
		if page.id == id:
			return page
	return {}

# ---- the pages ---------------------------------------------------------------------------------------------------
func fill() -> void:
	if data.is_empty():
		return
	var id := current_page()
	var column: VBoxContainer = bodies[id]
	if id == "history" and is_instance_valid(history_chart) and history_chart.is_inside_tree():
		fill_history(column)
		return
	clear(column)
	var page := page_data(id)
	match id:
		"employment":
			fill_employment(column, page)
		"administration":
			fill_administration(column, page)
		"storage":
			fill_storage(column, page)
		"military":
			fill_military(column, page)
		"mythology":
			fill_mythology(column)
			return
		"advisor":
			fill_advisor(column)
			return
		"history":
			fill_history(column)
			return
		"trade":
			fill_trade(column)
			return
		_:
			for item in page.get("lines", []):
				line(column, str(item.label), str(item.value), int(item.severity))
			if id == "overview":
				extras(column, [["advisor", "City advisor"], ["history", "City history"]])
				fill_requests(column)
	views(column, page)

# The SDL overview's requests: the goods the cities of the world ask for (sent from a city of the player's that has them),
# the heroes the gods ask for (sent once arrived) and the troops allies ask for, worded as on the world map.
func fill_requests(column: VBoxContainer) -> void:
	var world: Dictionary = core.query("world")
	var requests: Array = world.get("requests", [])
	var quests: Array = world.get("quests", [])
	var troops := int(world.get("troop_requests", 0))
	column.add_child(HSeparator.new())
	heading(column, str(data.get("requests_title", "")))
	if requests.is_empty() and quests.is_empty() and troops == 0:
		caption(column, tr("No one asks anything of you."))
		return
	var cities: Array = world.get("cities", [])
	var mine: Array = world.get("mine", [])
	for request in requests:
		var row := HBoxContainer.new()
		row.name = "Request"
		row.add_theme_constant_override("separation", 8)
		var asker := int(request.city)
		var name_label := Label.new()
		name_label.text = "%s:  %d  %s" % [str(cities[asker].name) if asker >= 0 and asker < cities.size() else "?", int(request.count), Goods.name_of(int(request.resource))]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var senders: Array = request.from.map(func(id): return int(id))
		if senders.is_empty():
			var none := Label.new()
			none.theme_type_variation = "Caption"
			none.text = tr("You do not have enough.")
			row.add_child(none)
		for entry in mine:
			if not int(entry.id) in senders:
				continue
			var button := Button.new()
			button.text = tr("Send from %s") % entry.name if mine.size() > 1 else tr("Send")
			button.focus_mode = Control.FOCUS_NONE
			var command := "world_fulfil %d %d" % [int(request.id), int(entry.id)]
			button.pressed.connect(func(): send(command); refresh())
			row.add_child(button)
		column.add_child(row)
	for quest in quests:
		var row := HBoxContainer.new()
		row.name = "Quest"
		row.add_theme_constant_override("separation", 8)
		var text := Label.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state := tr("You have no hall for %s.") if not bool(quest.hall) else (tr("%s has not arrived yet.") if not bool(quest.ready) else tr("%s waits in the city."))
		text.text = "%s — %s  ·  %s" % [str(quest.god_name), str(quest.name), state % str(quest.hero_name)]
		row.add_child(text)
		var go := Button.new()
		go.text = tr("Send %s") % str(quest.hero_name)
		go.disabled = not bool(quest.ready)
		go.focus_mode = Control.FOCUS_NONE
		var command := "world_quest %d" % int(quest.id)
		go.pressed.connect(func(): send(command); refresh())
		row.add_child(go)
		column.add_child(row)
	if troops > 0:
		caption(column, tr("%d of the world's cities ask you for troops: answer them on the world map.") % troops)

func fill_employment(column: VBoxContainer, page: Dictionary) -> void:
	var wage: Dictionary = data.get("wage", {})
	labelled(column, str(wage.get("label", "")), chooser(wage.get("names", []), int(wage.get("rate", 3)), func(index): send("set_wage %d" % index)))
	for item in page.get("lines", []).slice(1):
		line(column, str(item.label), str(item.value), int(item.severity))
	var workforce: Dictionary = data.get("workforce", {})
	column.add_child(HSeparator.new())
	heading(column, str(workforce.get("title", "")))
	var grid := GridContainer.new()
	grid.name = "Workforce"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	var columns: Array = workforce.get("columns", ["", "", "", ""])
	for text in [columns[1], columns[0], columns[2], columns[3]]:
		var label := Label.new()
		label.theme_type_variation = "Caption"
		label.text = str(text)
		grid.add_child(label)
	for sector in workforce.get("sectors", []):
		var name_label := Label.new()
		name_label.text = str(sector.name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		var which := int(sector.sector)
		grid.add_child(chooser(workforce.get("priorities", []), int(sector.priority), func(index): send("set_priority %d %d" % [which, index])))
		var need := Label.new()
		need.text = str(int(sector.need))
		grid.add_child(need)
		var have := Label.new()
		have.text = str(int(sector.have))
		if int(sector.have) < int(sector.need):
			have.add_theme_color_override("font_color", SEVERITY[1])
		grid.add_child(have)
	column.add_child(grid)
	var industries: Array = workforce.get("industries", [])
	if not industries.is_empty():
		column.add_child(HSeparator.new())
		heading(column, str(workforce.get("industry_title", "")))
		for industry in industries:
			line(column, str(industry.name), str(int(industry.vacancies)), 1)

func fill_administration(column: VBoxContainer, page: Dictionary) -> void:
	var tax: Dictionary = data.get("tax", {})
	var names: Array = []
	var selected := 0
	var options: Array = tax.get("options", [])
	for index in options.size():
		names.append("%s (%d%%)" % [str(options[index].name), int(options[index].percent)])
		if int(options[index].id) == int(tax.get("rate", 3)):
			selected = index
	labelled(column, str(tax.get("label", "")), chooser(names, selected, func(index): send("set_tax %d" % int(options[index].id))))
	for item in page.get("lines", []).slice(1):
		line(column, str(item.label), str(item.value), int(item.severity))
	var finances: Dictionary = data.get("finances", {})
	column.add_child(HSeparator.new())
	heading(column, str(finances.get("title", "")))
	var grid := GridContainer.new()
	grid.name = "Finances"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	for text in ["", str(finances.get("last", "")), str(finances.get("this", ""))]:
		var label := Label.new()
		label.theme_type_variation = "Caption"
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(label)
	for row in finances.get("rows", []):
		var kind := str(row.kind)
		var name_label := Label.new()
		name_label.text = str(row.label)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if kind != "row":
			name_label.theme_type_variation = "Subheading" if kind == "heading" else "HeaderSmall"
		grid.add_child(name_label)
		for key in ["last", "this"]:
			var value := Label.new()
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			if kind != "heading":
				value.text = str(int(row[key]))
				if kind == "net":
					value.add_theme_color_override("font_color", SEVERITY[0] if int(row[key]) >= 0 else SEVERITY[2])
			grid.add_child(value)
	column.add_child(grid)

func fill_storage(column: VBoxContainer, page: Dictionary) -> void:
	extras(column, [["trade", "Trade summary"]])
	var grid := GridContainer.new()
	grid.name = "Goods"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	for good in page.get("goods", []):
		var name_label := Label.new()
		name_label.text = str(good.name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(name_label)
		var count := Label.new()
		count.text = str(int(good.count))
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(count)
	column.add_child(grid)

func fill_military(column: VBoxContainer, page: Dictionary) -> void:
	for item in page.get("lines", []):
		line(column, str(item.label), str(item.value), int(item.severity))
	column.add_child(HSeparator.new())
	var soldiers: Dictionary = page.get("soldiers", {})
	var soldiers_button := Button.new()
	soldiers_button.name = "Soldiers"
	soldiers_button.text = str(soldiers.get("text", ""))
	soldiers_button.tooltip_text = str(soldiers.get("tooltip", ""))
	soldiers_button.disabled = str(soldiers.get("action", "")).is_empty()
	soldiers_button.focus_mode = Control.FOCUS_NONE
	var action := str(soldiers.get("action", ""))
	soldiers_button.pressed.connect(func(): send(action))
	column.add_child(soldiers_button)
	var towers: Dictionary = page.get("towers", {})
	var towers_button := Button.new()
	towers_button.name = "Towers"
	towers_button.text = str(towers.get("text", ""))
	towers_button.tooltip_text = str(towers.get("tooltip", ""))
	towers_button.disabled = int(towers.get("count", 0)) == 0
	towers_button.focus_mode = Control.FOCUS_NONE
	var manning := bool(towers.get("manning", false))
	towers_button.pressed.connect(func(): send("man_towers %d" % (0 if manning else 1)))
	column.add_child(towers_button)

# The mythology page is the core's `mythology` answer, as in the Mythology window.
func fill_mythology(column: VBoxContainer) -> void:
	var answer: Dictionary = core.query("mythology")
	var titles: Dictionary = answer.get("titles", {})
	var groups := [["sanctuaries", answer.get("sanctuaries", [])], ["gods", answer.get("gods_attacking", [])], ["monsters", answer.get("monsters", [])]]
	for group in groups:
		var heading_text := str(titles.get(group[0], ""))
		if group[0] == "sanctuaries":
			heading_text = "%s  (%d / %d)" % [heading_text, group[1].size(), int(answer.get("max", 0))]
		heading(column, heading_text)
		if group[1].is_empty():
			caption(column, str(titles.get("none", "")))
		for item in group[1]:
			var row := HBoxContainer.new()
			var label := Label.new()
			label.text = "%s — %s" % [str(item.god_name), str(item.name)] if group[0] == "sanctuaries" else str(item.name)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			if group[0] == "sanctuaries":
				var state := Label.new()
				state.theme_type_variation = "Caption"
				state.text = str(item.state) + ("" if bool(item.finished) else "  %d%%" % int(item.progress))
				row.add_child(state)
			var show := Button.new()
			show.text = tr("Show")
			show.focus_mode = Control.FOCUS_NONE
			var cell := Vector2i(int(item.x), int(item.y))
			show.pressed.connect(func():
				if jump.is_valid():
					jump.call(cell)
				queue_free())
			row.add_child(show)
			column.add_child(row)
	views(column, {"views": [{"label": str(data.get("mythology_view", "")), "overlay": "immortals"}]})

# ---- the SDL remaster's extras -----------------------------------------------------------------------------------
# Buttons that open other pages of this window (the SDL panel's advisor, chart and scales buttons).
func extras(column: VBoxContainer, pages: Array) -> void:
	var row := HFlowContainer.new()
	row.name = "Extras"
	row.add_theme_constant_override("h_separation", 6)
	for page in pages:
		var button := Button.new()
		button.name = "Open" + str(page[0]).capitalize()
		button.text = tr(page[1])
		button.focus_mode = Control.FOCUS_NONE
		var id := str(page[0])
		button.pressed.connect(func(): show_page(id))
		row.add_child(button)
	column.add_child(row)

func coloured(text: String, color: Color, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	if variation != "":
		label.theme_type_variation = variation
	return label

# The advisor: a card per problem, the most serious first, each with its detail, a hint and "Go there" stepping through the places.
func fill_advisor(column: VBoxContainer) -> void:
	var answer: Dictionary = core.query("city_advisor")
	heading(column, str(answer.get("title", "")))
	for advice in answer.get("advice", []):
		var card := PanelContainer.new()
		card.name = "Advice"
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var severity := int(advice.severity)
		var mark := ColorRect.new()
		mark.custom_minimum_size = Vector2(6, 0)
		mark.color = SEVERITY[clampi(severity, 0, 2)]
		row.add_child(mark)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 2)
		row.add_child(text)
		text.add_child(coloured(str(advice.title), [Color(.59, .89, .67), Color(1.0, .87, .55), Color(1.0, .67, .55)][clampi(severity, 0, 2)], "Subheading"))
		if not str(advice.detail).is_empty():
			text.add_child(coloured(str(advice.detail), Color(.93, .90, .84)))
		if not str(advice.hint).is_empty():
			text.add_child(coloured(str(advice.hint), Color(.61, .67, .77), "Caption"))
		var places: Array = advice.get("places", [])
		if not places.is_empty():
			var key := str(advice.key)
			var next := int(advisor_steps.get(key, 0)) % places.size()
			var go := Button.new()
			go.name = "GoThere"
			go.text = str(answer.get("go", "")) + ("  %d/%d" % [next + 1, places.size()] if places.size() > 1 else "")
			go.focus_mode = Control.FOCUS_NONE
			go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			go.pressed.connect(func():
				var place: Array = places[next]
				advisor_steps[key] = next + 1
				if jump.is_valid():
					jump.call(Vector2(float(place[0]), float(place[1])))
				queue_free())
			row.add_child(go)
		column.add_child(card)

# The chart: a button per series and per range above it; the chart keeps its pointer while the window refreshes.
func fill_history(column: VBoxContainer) -> void:
	var answer: Dictionary = core.query("city_history")
	if answer.get("kind", "") != "city_history":
		return
	if not (is_instance_valid(history_chart) and history_chart.is_inside_tree() and history_chart.get_parent() == column):
		clear(column)
		heading(column, str(answer.title))
		var choices := HBoxContainer.new()
		choices.name = "HistoryChoices"
		choices.add_theme_constant_override("separation", 6)
		var series_group := ButtonGroup.new()
		for index in answer.series.size():
			var button := Button.new()
			button.text = str(answer.series[index].label)
			button.toggle_mode = true
			button.button_group = series_group
			button.button_pressed = index == history_series
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(func():
				history_series = index
				history_chart.choose(history_series, history_span)
				summarize(column))
			choices.add_child(button)
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices.add_child(gap)
		var span_group := ButtonGroup.new()
		for index in answer.ranges.size():
			var button := Button.new()
			button.text = str(answer.ranges[index])
			button.toggle_mode = true
			button.button_group = span_group
			button.button_pressed = index == history_span
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(func():
				history_span = index
				history_chart.choose(history_series, history_span))
			choices.add_child(button)
		column.add_child(choices)
		var summary := Label.new()
		summary.name = "HistorySummary"
		column.add_child(summary)
		history_chart = HistoryChart.new()
		history_chart.name = "HistoryChart"
		history_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(history_chart)
		history_chart.choose(history_series, history_span)
	history_chart.set_history(answer)
	summarize(column)

# The latest value of the series and how it changed over a year (or since the record began).
func summarize(column: VBoxContainer) -> void:
	var summary: Label = column.get_node_or_null("HistorySummary")
	var history: Dictionary = history_chart.history
	var samples: Array = history.get("samples", [])
	if summary == null or samples.is_empty():
		if summary != null:
			summary.text = ""
		return
	var now := int(samples[-1].values[history_series])
	var back := mini(12, samples.size() - 1)
	var then := int(samples[-1 - back].values[history_series])
	var change := now - then
	var percent := bool(history.series[history_series].percent)
	var sign := "+" if change > 0 else ""
	summary.text = "%s: %s%s   (%s%s%s %s)" % [str(history.series[history_series].label), HistoryChart.grouped(now), "%" if percent else "",
		sign, HistoryChart.grouped(change), "%" if percent else "", str(history.in_a_year if back == 12 else history.since_start)]
	# Unrest is the one series that is better falling.
	var better := change < 0 if history_series == 4 else change > 0
	summary.add_theme_color_override("font_color", Color(.93, .90, .84) if change == 0 else (SEVERITY[0] if better else SEVERITY[2]))

# The trade summary: a card per partner, then the goods in storage with who would buy them; the core judges each line.
func fill_trade(column: VBoxContainer) -> void:
	var answer: Dictionary = core.query("trade_summary")
	heading(column, str(answer.get("title", "")))
	var target: VBoxContainer = column
	for item in answer.get("lines", []):
		if bool(item.header):
			target = column
			column.add_child(HSeparator.new())
			column.add_child(coloured(str(item.left), TONES.gold, "Subheading"))
			continue
		if bool(item.card):
			var card := PanelContainer.new()
			card.name = "Partner"
			column.add_child(card)
			target = VBoxContainer.new()
			target.add_theme_constant_override("separation", 2)
			card.add_child(target)
		elif int(item.indent) == 0:
			target = column
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(18 * int(item.indent), 0)
		row.add_child(gap)
		var left := coloured(str(item.left), TONES.get(str(item.left_tone), TONES.text), "Subheading" if bool(item.heading) else "")
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		if not str(item.right).is_empty():
			var right := coloured(str(item.right), TONES.get(str(item.right_tone), TONES.text))
			right.autowrap_mode = TextServer.AUTOWRAP_OFF
			if right.text.length() > 40:
				right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				right.custom_minimum_size = Vector2(420, 0)
			right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(right)
		target.add_child(row)
