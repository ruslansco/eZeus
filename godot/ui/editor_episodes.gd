extends RefCounted
# The adventure editor's episodes (the SDL editor's main page, eEpisodesWidget, and its settings menu, eEditorSettingsMenu):
#   The adventure: its start date, the players' starting funds and the prices of goods.
#   The parent city's episodes in order: each one's settings, whether the next episode is the parent city's or a colony's,
#   and (as the SDL right-click menu) insert one before it, delete it, or end the adventure with it; Add episode at the end.
#   The colony episodes: which colony each one is played in, and their settings.
#   An episode's settings: its goals, its events for each city on the map, each city's friendly gods, the buildings it may
#   build and how many sanctuaries; copy them from another episode, or clear them.
# Everything is changed by the core's `editor...` commands (eEditorSession); each answer is shown again.
const Form = preload("res://ui/editor_form.gd")
const Goods = preload("res://scripts/goods.gd")

var panel
var window: AcceptDialog
var list: VBoxContainer
var settings: AcceptDialog
var tabs: TabContainer
var city_choice: OptionButton
var goals_list: VBoxContainer
var goal_kind: OptionButton
var events_list: ItemList
var event_form: VBoxContainer
var event_kind: OptionButton
var event_title: Label
var gods_box: GridContainer
var buildings_box: GridContainer
var sanctuaries: SpinBox
var copy_choice: OptionButton
var prices_window: AcceptDialog
var episode_kind := "p"
var episode_index := 0
var episode: Dictionary = {}
var selected_event := -1
var refreshing := false

func attach(owner_panel, root: Control) -> void:
	panel = owner_panel
	window = AcceptDialog.new()
	window.name = "EditorEpisodes"
	window.title = tr("Episodes")
	window.get_ok_button().text = tr("Close")
	root.add_child(window)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	window.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	build_settings(root)
	prices_window = AcceptDialog.new()
	prices_window.name = "EditorPrices"
	prices_window.get_ok_button().text = tr("Close")
	root.add_child(prices_window)

func visible() -> bool:
	return window.visible or settings.visible or prices_window.visible

func close() -> void:
	window.hide()
	settings.hide()
	prices_window.hide()

func open() -> void:
	rebuild()
	window.popup_centered(Vector2i(860, 640))

func label(text: String, variation := "") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not variation.is_empty():
		l.theme_type_variation = variation
	return l

func button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if primary:
		b.theme_type_variation = "Primary"
	b.pressed.connect(action)
	return b

func command(text: String) -> Dictionary:
	var answer: Dictionary = panel.query(text)
	if not answer.has("error"):
		panel.mark_changed()
	return answer

# ---------------------------------------------------------------------------------------------------- the adventure page
func rebuild() -> void:
	var overview: Dictionary = panel.query("editor")
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if overview.has("error"):
		list.add_child(label(tr("The editor could not read the adventure")))
		return
	var labels: Dictionary = overview.labels
	# The adventure's own settings (the SDL editor shows them on the first episode's settings).
	list.add_child(label(tr("The adventure"), "Subheading"))
	if not str(overview.title).is_empty():
		list.add_child(label(str(overview.title), "Caption"))
	var date_row := HBoxContainer.new()
	date_row.name = "StartDate"
	date_row.add_theme_constant_override("separation", 8)
	date_row.add_child(label(tr("Start date")))
	var day := SpinBox.new()
	day.name = "Day"
	day.min_value = 1
	day.max_value = 31
	day.value = int(overview.date[0])
	var month := OptionButton.new()
	month.name = "Month"
	for index in overview.months.size():
		month.add_item(str(overview.months[index]), index)
	month.selected = int(overview.date[1])
	var year := SpinBox.new()
	year.name = "Year"
	year.min_value = -9999
	year.max_value = 9999
	year.value = int(overview.date[2])
	year.tooltip_text = tr("Years before Christ are negative")
	var send_date := func(_value = null): command("editor_date %d %d %d" % [int(day.value), month.selected, int(year.value)])
	day.value_changed.connect(send_date)
	month.item_selected.connect(send_date)
	year.value_changed.connect(send_date)
	for control in [day, month, year]:
		date_row.add_child(control)
	list.add_child(date_row)
	for fund in overview.funds:
		var row := HBoxContainer.new()
		row.add_child(label("%s: %s" % [str(labels.funds), str(fund.name)]))
		var amount := SpinBox.new()
		amount.name = "Funds%d" % int(fund.player)
		amount.max_value = 99999
		amount.value = int(fund.value)
		var player := int(fund.player)
		amount.value_changed.connect(func(v): command("editor_funds %d %d" % [player, int(v)]))
		row.add_child(amount)
		list.add_child(row)
	list.add_child(button(str(labels.prices), func(): open_prices()))
	list.add_child(HSeparator.new())
	# The parent city's episodes.
	list.add_child(label(str(labels.parent), "Subheading"))
	for item in overview.parent:
		var index := int(item.index)
		var row := HBoxContainer.new()
		row.name = "Parent%d" % index
		row.add_theme_constant_override("separation", 6)
		var name := label("%d.  %s" % [index + 1, str(item.title) if not str(item.title).is_empty() else tr("Episode %d") % (index + 1)])
		name.custom_minimum_size = Vector2(250, 0)
		row.add_child(name)
		row.add_child(button(str(labels.settings), func(): open_settings("p", index)))
		if not bool(item.last):
			var next := button(str(labels.next_parent) if str(item.next) == "parent" else str(labels.next_colony), func():
				command("editor_episode_next %d" % index)
				rebuild())
			next.name = "Next"
			next.tooltip_text = tr("What follows this episode: the parent city again, or a colony")
			row.add_child(next)
		row.add_child(button(str(labels.insert), func():
			command("editor_episode_insert %d" % index)
			rebuild()))
		if overview.parent.size() > 1:
			row.add_child(button(str(labels.delete), func():
				command("editor_episode_delete %d" % index)
				rebuild()))
		if not bool(item.last):
			row.add_child(button(str(labels.victory), func():
				command("editor_episode_victory %d" % index)
				rebuild()))
		list.add_child(row)
	var add := button(tr("Add episode"), func():
		command("editor_episode_add")
		rebuild())
	add.name = "AddEpisode"
	list.add_child(add)
	list.add_child(HSeparator.new())
	# The colony episodes.
	list.add_child(label(str(labels.colony), "Subheading"))
	for item in overview.colonies:
		var index := int(item.index)
		var row := HBoxContainer.new()
		row.name = "Colony%d" % index
		row.add_theme_constant_override("separation", 6)
		var name := label("%d.  %s" % [index + 1, str(item.title) if not str(item.title).is_empty() else tr("Colony %d") % (index + 1)])
		name.custom_minimum_size = Vector2(250, 0)
		row.add_child(name)
		var where := OptionButton.new()
		where.name = "City"
		where.add_item(tr("No colony chosen"), -1)
		for colony in overview.colony_cities:
			where.add_item(str(colony.name), int(colony.id))
			if int(colony.id) == int(item.city):
				where.selected = where.item_count - 1
		where.item_selected.connect(func(slot):
			var id := where.get_item_id(slot)
			if id >= 0:
				command("editor_colony_city %d %d" % [index, id]))
		row.add_child(where)
		row.add_child(button(str(labels.settings), func(): open_settings("c", index)))
		list.add_child(row)

func open_prices() -> void:
	var overview: Dictionary = panel.query("editor")
	prices_window.title = str(overview.labels.prices)
	for child in prices_window.get_children():
		prices_window.remove_child(child)
		child.queue_free()
	var column := VBoxContainer.new()
	prices_window.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 440)
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "Prices"
	grid.columns = 4
	scroll.add_child(grid)
	var boxes := {}
	for price in overview.prices:
		var name := Goods.name_of(int(price.resource))
		grid.add_child(label(name if not name.is_empty() else str(price.name)))
		var box := SpinBox.new()
		box.max_value = 99999
		box.value = int(price.value)
		var resource := int(price.resource)
		box.value_changed.connect(func(v): command("editor_price %d %d" % [resource, int(v)]))
		grid.add_child(box)
		boxes[resource] = box
	var reset := func():
		var answer := command("editor_prices_reset")
		for price in answer.get("prices", []):
			if boxes.has(int(price.resource)):
				boxes[int(price.resource)].set_value_no_signal(int(price.value))
	column.add_child(button(str(overview.labels.reset_prices), reset))
	prices_window.popup_centered(Vector2i(560, 560))

# ------------------------------------------------------------------------------------------------- an episode's settings
func build_settings(root: Control) -> void:
	settings = AcceptDialog.new()
	settings.name = "EditorEpisode"
	settings.get_ok_button().text = tr("Close")
	settings.visibility_changed.connect(func():
		if not settings.visible and window.visible:
			rebuild())
	root.add_child(settings)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(900, 600)
	settings.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	column.add_child(top)
	top.add_child(label(tr("City")))
	city_choice = OptionButton.new()
	city_choice.name = "EpisodeCity"
	city_choice.item_selected.connect(func(_slot): show_episode())
	top.add_child(city_choice)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	copy_choice = OptionButton.new()
	copy_choice.name = "CopyFrom"
	top.add_child(copy_choice)
	top.add_child(button(tr("Copy"), func():
		var from := copy_choice.get_item_id(copy_choice.selected) if copy_choice.selected >= 0 else -2
		if from >= -1:
			episode = command("editor_episode_copy %s %d %d" % [episode_kind, from, episode_index])
			show_episode()))
	tabs = TabContainer.new()
	tabs.name = "EpisodeTabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	# Goals.
	var goals_page := VBoxContainer.new()
	goals_page.name = "Goals"
	tabs.add_child(goals_page)
	var goals_scroll := ScrollContainer.new()
	goals_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	goals_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	goals_page.add_child(goals_scroll)
	goals_list = VBoxContainer.new()
	goals_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_list.add_theme_constant_override("separation", 10)
	goals_scroll.add_child(goals_list)
	var goal_row := HBoxContainer.new()
	goals_page.add_child(goal_row)
	goal_kind = OptionButton.new()
	goal_kind.name = "GoalKind"
	goal_row.add_child(goal_kind)
	var add_goal := func():
		if goal_kind.selected >= 0:
			episode = command("editor_goal_add %s %d %d" % [episode_kind, episode_index, goal_kind.get_item_id(goal_kind.selected)])
			show_episode()
	goal_row.add_child(button(tr("Add goal"), add_goal, true))
	# Events, for the city chosen above.
	var events_page := HBoxContainer.new()
	events_page.name = "Events"
	events_page.add_theme_constant_override("separation", 12)
	tabs.add_child(events_page)
	var events_left := VBoxContainer.new()
	events_left.custom_minimum_size = Vector2(320, 0)
	events_page.add_child(events_left)
	events_list = ItemList.new()
	events_list.name = "EventList"
	events_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	events_list.item_selected.connect(func(slot): show_event(slot))
	events_left.add_child(events_list)
	event_kind = OptionButton.new()
	event_kind.name = "EventKind"
	events_left.add_child(event_kind)
	var event_buttons := HBoxContainer.new()
	events_left.add_child(event_buttons)
	var add_event := func():
		if event_kind.selected < 0:
			return
		var answer := command("editor_event_add %s %d %d %d" % [episode_kind, episode_index, city_id(), event_kind.get_item_id(event_kind.selected)])
		if not answer.has("error"):
			episode = panel.query("editor_episode %s %d" % [episode_kind, episode_index])
			selected_event = int(answer.index)
			show_episode()
			show_event(selected_event)
	event_buttons.add_child(button(tr("Add event"), add_event, true))
	event_buttons.add_child(button(tr("Remove event"), func():
		if selected_event < 0:
			return
		episode = command("editor_event_remove %s %d %d %d" % [episode_kind, episode_index, city_id(), selected_event])
		selected_event = -1
		show_episode()))
	var event_right := VBoxContainer.new()
	event_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	events_page.add_child(event_right)
	event_title = label("", "Subheading")
	event_right.add_child(event_title)
	var event_scroll := ScrollContainer.new()
	event_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	event_right.add_child(event_scroll)
	event_form = VBoxContainer.new()
	event_form.name = "EventForm"
	event_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_scroll.add_child(event_form)
	# The city's friendly gods and how many sanctuaries it may build.
	var gods_page := VBoxContainer.new()
	gods_page.name = "Gods"
	tabs.add_child(gods_page)
	gods_box = GridContainer.new()
	gods_box.name = "GodList"
	gods_box.columns = 4
	gods_page.add_child(gods_box)
	var sanctuary_row := HBoxContainer.new()
	sanctuary_row.add_child(label(tr("Sanctuaries at most")))
	sanctuaries = SpinBox.new()
	sanctuaries.name = "MaxSanctuaries"
	sanctuaries.max_value = 16
	sanctuaries.value_changed.connect(func(v):
		if not refreshing:
			episode = command("editor_max_sanctuaries %s %d %d %d" % [episode_kind, episode_index, city_id(), int(v)]))
	sanctuary_row.add_child(sanctuaries)
	gods_page.add_child(sanctuary_row)
	# The buildings the episode lets the city build.
	var buildings_page := ScrollContainer.new()
	buildings_page.name = "Buildings"
	tabs.add_child(buildings_page)
	buildings_box = GridContainer.new()
	buildings_box.name = "BuildingList"
	buildings_box.columns = 3
	buildings_page.add_child(buildings_box)

func city_id() -> int:
	return city_choice.get_item_id(city_choice.selected) if city_choice.selected >= 0 else 0

func open_settings(kind: String, index: int) -> void:
	episode_kind = kind
	episode_index = index
	episode = panel.query("editor_episode %s %d" % [kind, index])
	if episode.has("error"):
		return
	var overview: Dictionary = panel.query("editor")
	var labels: Dictionary = overview.labels
	settings.title = "%s — %s %d" % [str(labels.settings), str(labels.colony if kind == "c" else labels.parent), index + 1]
	tabs.set_tab_title(0, str(labels.goals))
	tabs.set_tab_title(1, str(labels.events))
	tabs.set_tab_title(2, str(labels.gods))
	tabs.set_tab_title(3, str(labels.buildings))
	city_choice.clear()
	for item in episode.cities:
		city_choice.add_item(str(item.name), int(item.id))
	city_choice.selected = 0 if city_choice.item_count > 0 else -1
	goal_kind.clear()
	for kind_item in episode.goal_kinds:
		goal_kind.add_item(str(kind_item.label), int(kind_item.value))
	event_kind.clear()
	for kind_item in episode.event_kinds:
		event_kind.add_item(str(kind_item.label), int(kind_item.value))
	copy_choice.clear()
	var episodes: Array = overview.colonies if kind == "c" else overview.parent
	for item in episodes:
		if int(item.index) != index:
			copy_choice.add_item(tr("Copy from episode %d") % (int(item.index) + 1), int(item.index))
	copy_choice.add_item(str(labels.clear), -1)
	selected_event = -1
	show_episode()
	settings.popup_centered(Vector2i(960, 700))

func city_of(cid: int) -> Dictionary:
	for item in episode.get("cities", []):
		if int(item.id) == cid:
			return item
	return {}

# Shows the episode's goals and the chosen city's events, gods and buildings.
func show_episode() -> void:
	if episode.has("error"):
		return
	refreshing = true
	for child in goals_list.get_children():
		goals_list.remove_child(child)
		child.queue_free()
	for goal in episode.goals:
		var card := PanelContainer.new()
		card.name = "Goal%d" % int(goal.index)
		var column := VBoxContainer.new()
		card.add_child(column)
		var head := HBoxContainer.new()
		column.add_child(head)
		var text := label(str(goal.text) if not str(goal.text).is_empty() else str(goal.type_name), "Subheading")
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(text)
		var number := int(goal.index)
		head.add_child(button(tr("Remove"), func():
			episode = command("editor_goal_remove %s %d %d" % [episode_kind, episode_index, number])
			show_episode()))
		var form := VBoxContainer.new()
		column.add_child(form)
		# A change keeps the form (a number box is not rebuilt under the pointer); the goal's sentence follows.
		Form.build(form, goal.fields, func(id, value):
			var answer := command("editor_goal_set %s %d %d %s %d" % [episode_kind, episode_index, number, id, value])
			if answer.has("goals"):
				episode = answer
				for changed in answer.goals:
					if int(changed.index) == number:
						text.text = str(changed.text) if not str(changed.text).is_empty() else str(changed.type_name))
		goals_list.add_child(card)
	if episode.goals.is_empty():
		goals_list.add_child(label(tr("No goals yet: the episode is won by surviving its events."), "Caption"))
	var city := city_of(city_id())
	events_list.clear()
	for item in city.get("events", []):
		events_list.add_item(str(item.name))
	if selected_event >= events_list.item_count:
		selected_event = -1
	if selected_event >= 0:
		events_list.select(selected_event)
	else:
		event_title.text = tr("Choose an event, or add one")
		Form.build(event_form, [], Callable())
	for child in gods_box.get_children():
		gods_box.remove_child(child)
		child.queue_free()
	var friendly: Array = city.get("gods", [])
	for god in episode.gods:
		var tick := CheckBox.new()
		tick.name = "God%d" % int(god.value)
		tick.text = str(god.label)
		tick.button_pressed = friendly.any(func(g): return int(g) == int(god.value))
		tick.toggled.connect(func(_on): send_gods())
		gods_box.add_child(tick)
	sanctuaries.value = int(city.get("max_sanctuaries", 16))
	for child in buildings_box.get_children():
		buildings_box.remove_child(child)
		child.queue_free()
	for building in city.get("buildings", []):
		var tick := CheckBox.new()
		tick.name = "Building%d" % int(building.type)
		tick.text = str(building.name)
		tick.button_pressed = bool(building.available)
		var type := int(building.type)
		tick.toggled.connect(func(on):
			episode = command("editor_building %s %d %d %d %d" % [episode_kind, episode_index, city_id(), type, 1 if on else 0]))
		buildings_box.add_child(tick)
	refreshing = false

func send_gods() -> void:
	var chosen := PackedStringArray()
	for tick in gods_box.get_children():
		if tick.button_pressed:
			chosen.append(str(tick.name).trim_prefix("God"))
	episode = command("editor_gods %s %d %d %s" % [episode_kind, episode_index, city_id(), ",".join(chosen) if not chosen.is_empty() else "-"])

func show_event(slot: int) -> void:
	selected_event = slot
	var answer: Dictionary = panel.query("editor_event %s %d %d %d" % [episode_kind, episode_index, city_id(), slot])
	if answer.has("error"):
		return
	event_title.text = str(answer.name)
	Form.build(event_form, answer.fields, func(id, value):
		var changed := command("editor_event_set %s %d %d %d %s %d" % [episode_kind, episode_index, city_id(), slot, id, value])
		if not changed.has("error"):
			event_title.text = str(changed.name)
			events_list.set_item_text(slot, str(changed.name)))
