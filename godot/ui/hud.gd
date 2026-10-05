extends Control
# The city HUD: bottom construction dock, slim top status strip, contextual build tray, compact corner
# inspection and native decisions. The simulation remains owned by main.gd/C++.
# The layout is ui/hud.tscn, styled by the one Theme ui/lapis_gold.tres. This script holds no game logic: it
# exposes signals and setters, and main.gd listens and feeds it state. Text is `tr()` keyed by its English
# source (see scripts/ui_text.gd). Language changes reapply text and rebuild catalog cards; native
# selections, callbacks and inspector drafts remain owned by the city controller.

signal tool_selected(tool_name: String)
signal placement_turn_requested(direction: int)
signal wall_fill_changed(filled: bool)
signal inspector_closed
signal pause_pressed
signal speed_selected(index: int)
signal undo_pressed
signal demolition_confirmed
signal demolition_canceled
signal save_requested(save_name: String)
signal load_requested(path: String)
signal messages_toggled(open: bool)
signal main_menu_confirmed
signal set_aside_requested(index: int)
signal overlay_selected(id: String)
# Explicit close, timeout or overflow dismisses informational news through main.gd; reading never does.
signal message_dismissed(id: int)

const NoticeChip = preload("res://ui/notification_chip.gd")
const NotificationPolicy = preload("res://scripts/notification_policy.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")
const ThumbnailService = preload("res://ui/building_thumbnails.gd")
const UiText = preload("res://scripts/ui_text.gd")
const BuildCatalog = preload("res://scripts/build_catalog.gd")
const ObjectiveCard = preload("res://ui/objective_card.gd")
const Overlays = preload("res://scripts/overlays.gd")
const SPEEDS := ["Speed 1", "Speed 2", "Speed 3", "Speed 4"]
# Original icon drawings; category labels are short, while tooltips keep the full native catalog heading.
const CATEGORY_ART := {
	"Housing and roads": ["homes", "Homes"], "Agriculture": ["food", "Food"],
	"Industry": ["industry", "Industry"], "Storage": ["storage", "Storage"],
	"Trade": ["trade", "Trade"], "Markets": ["markets", "Markets"],
	"Health and water": ["water", "Health"], "Administration and security": ["civic", "Civic"],
	"Walls and defence": ["defence", "Defence"], "Culture": ["culture", "Culture"],
	"Science": ["science", "Science"], "Sanctuaries": ["sanctuaries", "Temples"], "Pyramids": ["pyramids", "Pyramids"], "Shrines": ["shrines", "Shrines"], "Heroes' halls": ["heroes", "Heroes"], "Gardens and monuments": ["gardens", "Gardens"],
	"Other": ["build", "Other"]}
const TOOL_ART := {"select": "inspect", "road": "road", "house": "homes", "demolish": "demolish"}
const TOAST_SECONDS := 9.0
const MAX_TOASTS := 1
var alert_queue: Array = []
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const HEADER_GOODS := [[255,"Food","food_total"],
	[1,"Sea urchins","urchin"],
	[2,"Fish","fish"],
	[4,"Meat","meat"],
	[8,"Cheese","cheese"],
	[16,"Carrots","carrots"],
	[32,"Onions","onions"],
	[64,"Wheat","grain"],
	[128,"Oranges","oranges"],
	[256,"Grapes","grapes"],
	[512,"Olives","olives"],
	[1024,"Wine","wine"],
	[2048,"Olive oil","oil"],
	[4096,"Fleece","fleece"],
	[8192,"Timber","wood"],
	[16384,"Bronze","bronze"],
	[32768,"Marble","marble"],
	[65536,"Armor","arms"],
	[131072,"Sculptures","sculptures"],
	[262144,"Orichalcum","orichalcum"],
	[524288,"Black marble","black_marble"],
	[1048576,"Horses","horses"],
	[2097152,"Chariots","chariots"],
	[4194304,"Silver","silver"]]
var resource_buttons := {}
var city_header := {}
var welfare_buttons := {}

@onready var date_label: Label = %Date
@onready var treasury_label: Label = %Treasury
@onready var population_label: Label = %Population
@onready var pause_button: Button = %Pause
@onready var speed_button: OptionButton = %Speed
@onready var tool_row: HBoxContainer = %ToolButtons
@onready var build_menu: MenuButton = %BuildMenu
@onready var undo_button: Button = %Undo
@onready var overlay_menu: MenuButton = %OverlayMenu
@onready var overlay_legend: Label = %OverlaySummary.legend
@onready var hint: Label = %Hint
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var details: Label = %Details
@onready var events_box: PanelContainer = %EventsBox
@onready var events_panel: VBoxContainer = %Events
@onready var inspector: PanelContainer = %Inspector
@onready var inspector_text: Label = %InspectorText
@onready var inspector_controls: VBoxContainer = %InspectorControls
@onready var demolition_dialog: ConfirmationDialog = %DemolitionDialog
@onready var messages_button: Button = %Messages
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_title: Label = %MessageTitle
@onready var message_close: Button = %MessageClose
@onready var message_list: VBoxContainer = %MessageList
@onready var toasts: VBoxContainer = %Toasts
@onready var minimap: Control = %Minimap
@onready var save_dialog: ConfirmationDialog = %SaveDialog
@onready var save_name: LineEdit = %SaveName
@onready var save_prompt: Label = %SavePrompt
@onready var load_dialog: ConfirmationDialog = %LoadDialog
@onready var save_list: ItemList = %SaveList
@onready var save_info: Label = %SaveInfo
@onready var goals_panel: PanelContainer = %GoalsPanel
@onready var goals_title: Label = %GoalsTitle
@onready var goals_toggle: Button = %GoalsToggle
@onready var goals_list: VBoxContainer = %GoalsList
@onready var menu_dialog: ConfirmationDialog = %MenuDialog

const GAME_ACTIONS := ["save", "load", "", "quick_save", "quick_load", "", "city", "world", "army", "mythology", "trade", "sound", "display", "interface", "controls", "settings", "main_menu"]
const GAME_LABELS := ["Save game…", "Load game…", "", "Quick save", "Quick load", "", "City…", "World map…", "Army…", "Mythology…", "Trade partners…", "Sound…", "Display settings…", "Interface options…", "Controls…", "Game settings…", "Main menu"]
# The Game menu entries that have a key: their key's name follows the player's bindings (scripts/key_bindings.gd).
const GAME_KEYS := {"quick_save": "quick_save", "quick_load": "quick_load", "world": "world_map", "army": "army", "mythology": "mythology", "city": "city"}
var save_entries: Array = []
var tool_buttons: Dictionary = {}
var tool_entries: Array = []
# The Build menu: one submenu per category. `build_groups` is BuildCatalog.groups(); `build_entries` maps a
# building name to its entry and `build_popups` to the submenu holding it, with its item index.
var build_groups: Array = []
var build_entries: Dictionary = {}
var build_popups: Dictionary = {}
var thumbnails: Node
var card_previews: Dictionary = {}
var active_category := ""
var category_buttons: Dictionary = {}
var building_cards: Dictionary = {}
var icon_cache: Dictionary = {}
var current_tool := "select"
var current_overlay := "normal"
var overlay_popups: Dictionary = {}
var paused := true
var context_item: Dictionary = {}
var facing := 0
var placement_feedback_active := false
var envoy_portrait: Control
var decision_id := -1
var decision_expanded := false
var decision_count := 0
var resources_open := false
var resources_fraction := 0.0
var resources_tween: Tween
var automation := false

func _ready() -> void:
	# `hint` stays the city's message sink (hidden); the notice pill shows its own copy, since the placement line keeps
	# rewriting `hint` while a notice is up.
	hint.visible = false
	notice_label.theme_type_variation = "Caption"
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Feedback.add_child(notice_label)
	%Feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Feedback.visible = false
	get_tree().node_added.connect(func(child):
		if child is Window and is_ancestor_of(child): _attach_right_click_back.call_deferred(child))
	for child in get_children(): _attach_right_click_back(child)
	%ResourcesToggle.pressed.connect(func(): set_resources_open(%ResourcesToggle.button_pressed))
	for index in HEADER_GOODS.size():
		var spec: Array = HEADER_GOODS[index]
		var button := Button.new()
		button.theme_type_variation = "ResourcePill"
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = load("res://ui/resource_art/"+spec[2]+".png"); button.text = "—"
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func(): overlay_selected.emit("supplies" if spec[0] == 255 or spec[0] <= 128 else "distribution"))
		%ResourceGrid.add_child(button)
		resource_buttons[spec[0]] = button
	for spec in [["supplies","food"],["water","water"],["hygiene","health"],["hazards","risk"]]:
		var button := Button.new()
		button.theme_type_variation = "WelfareButton"; button.icon = icon(spec[1])
		button.custom_minimum_size = Vector2(30,28)
		button.toggle_mode = true
		button.pressed.connect(func(): overlay_selected.emit(spec[0]))
		%WelfareButtons.add_child(button); welfare_buttons[spec[0]] = button
	%ActiveToolClose.icon=icon("close")
	%ActiveToolClose.pressed.connect(func(): tool_selected.emit("select"))
	%Jobs.icon = icon("industry")
	%Jobs.pressed.connect(func(): overlay_selected.emit("industry"))
	%InspectionSummary.overlay_selected.connect(func(id):overlay_selected.emit(id))
	%OverlaySummary.overlay_selected.connect(func(id):overlay_selected.emit(id))
	get_tree().root.get_node("UiAccess").changed.connect(func():
		if %BuildTray.visible:populate_build_cards()
		_layout_panels.call_deferred())
	%RotateLeft.icon=icon("rotate_left"); %RotateRight.icon=icon("rotate_right")
	%RotateLeft.pressed.connect(func(): placement_turn_requested.emit(-1))
	%RotateRight.pressed.connect(func(): placement_turn_requested.emit(1))
	%WallFill.toggled.connect(func(filled): wall_fill_changed.emit(filled))
	automation = OS.get_cmdline_args().has("--script") or Array(OS.get_cmdline_user_args()).any(func(arg): return arg == "--validate" or arg == "--skip-start" or "-review" in arg)
	var map_preference: Variant = false if automation else UserSettings.get_value("interface", "minimap_visible", false)
	%MapToggle.set_pressed_no_signal(map_preference if map_preference is bool else false)
	%MapToggle.icon = icon("map")
	%MapToggle.pressed.connect(func():
		set_minimap_open(true if %BuildTray.visible else %MapToggle.button_pressed, true))
	%MapPeek.icon = icon("map")
	%MapPeek.pressed.connect(func(): set_minimap_open(true, true))
	%MapClose.icon = icon("minimize")
	%MapClose.pressed.connect(func(): set_minimap_open(false, true))
	envoy_portrait = load("res://ui/envoy_portrait.gd").new()
	%EnvoyHeader.add_child(envoy_portrait)
	%EnvoyHeader.move_child(envoy_portrait, 0)
	%DecisionToggle.icon = icon("message")
	%DecisionToggle.pressed.connect(func(): set_decision_expanded(not decision_expanded))
	%TrayClose.icon = icon("close")
	%TrayClose.pressed.connect(close_build_tray)
	%InspectorClose.icon = icon("close")
	%InspectorClose.pressed.connect(func(): inspector_closed.emit())
	%BuildSearch.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			close_build_tray()
			get_viewport().set_input_as_handled())
	%BuildSearch.text_changed.connect(func(_text): populate_build_cards())
	%MoneyIcon.texture = icon("coin")
	%CitizensIcon.texture = icon("people")
	%MessageClose.icon = icon("close")
	%MessageClose.text = ""
	undo_button.icon = icon("undo")
	build_menu.icon = icon("build")
	overlay_menu.icon = icon("layers")
	messages_button.icon = icon("message")
	%ResourceGrid.minimum_size_changed.connect(func():_layout_panels.call_deferred())
	resized.connect(_layout_panels)
	pause_button.pressed.connect(func(): pause_pressed.emit())
	speed_button.item_selected.connect(func(index): speed_selected.emit(index))
	# Keep the upward menu clear of its opening click at the bottom edge. Screen coordinates
	# include Window content scaling, so enlarged UI uses the same mouse/keyboard route.
	speed_button.get_popup().visibility_changed.connect(func():
		var popup: PopupMenu=speed_button.get_popup()
		if popup.visible:
			popup.position=Vector2i(speed_button.get_screen_position())-Vector2i(0,popup.size.y+8))
	undo_button.pressed.connect(func(): undo_pressed.emit())
	overlay_menu.get_popup().index_pressed.connect(func(index):
		var id = overlay_menu.get_popup().get_item_metadata(index)
		if id is String:
			overlay_selected.emit(id))
	menu_dialog.confirmed.connect(func(): main_menu_confirmed.emit())
	goals_toggle.pressed.connect(func():
		set_goals_expanded(not goals_list.visible))
	# The whole header opens and closes the list, not only the small button.
	%GoalsHeader.mouse_filter = Control.MOUSE_FILTER_STOP
	%GoalsHeader.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	%GoalsHeader.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			set_goals_expanded(not goals_list.visible)
			accept_event())
	demolition_dialog.confirmed.connect(func(): demolition_confirmed.emit())
	demolition_dialog.canceled.connect(func(): demolition_canceled.emit())
	save_dialog.confirmed.connect(func(): save_requested.emit(save_name.text.strip_edges()))
	save_name.text_submitted.connect(func(_text):
		save_dialog.hide()
		save_requested.emit(save_name.text.strip_edges()))
	load_dialog.confirmed.connect(_confirm_load)
	save_list.item_activated.connect(func(_index):
		load_dialog.hide()
		_confirm_load())
	save_list.item_selected.connect(func(index): save_info.text = save_entries[index].detail if index < save_entries.size() else "")
	messages_button.pressed.connect(toggle_messages)
	message_close.pressed.connect(func(): set_messages_open(false))
	for text in SPEEDS:
		speed_button.add_item(tr(text))
	retranslate()

# Builds the quick tool row. `entries` are [tool, English label].
func set_tools(entries: Array) -> void:
	tool_entries = entries
	var group := ButtonGroup.new()
	for entry in entries:
		var button := Button.new()
		button.icon = icon(TOOL_ART.get(entry[0], "build"))
		button.tooltip_text = tr(entry[1])
		button.theme_type_variation = "Tool"
		button.custom_minimum_size = Vector2(32, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(func(): tool_selected.emit(entry[0]))
		tool_row.add_child(button)
		tool_buttons[entry[0]] = button
	select_tool(current_tool, false)

# Fills the Build menu from BuildCatalog.groups(): a submenu per category, one item per building.
func set_catalog(groups: Array) -> void:
	# The delayed trade refresh often returns the same catalog. Keep hover, scroll and cached card Controls.
	if groups == build_groups: return
	build_groups = groups
	build_entries.clear()
	for group in groups:
		for item in group.items:
			build_entries[item.name] = item
	populate_build_menu()
	populate_categories()
	if %BuildTray.visible:
		populate_build_cards()
	select_tool(current_tool, false)

func populate_build_menu() -> void:
	var menu := build_menu.get_popup()
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu.clear()
	build_popups.clear()
	for group in build_groups:
		var submenu := PopupMenu.new()
		submenu.name = String(group.title).replace(" ", "")
		for item in group.items:
			submenu.add_item(building_text(item))
			build_popups[item.name] = [submenu, submenu.item_count - 1]
		var names: Array = group.items.map(func(item): return item.name)
		submenu.id_pressed.connect(func(index): tool_selected.emit(names[index]))
		menu.add_child(submenu)
		menu.add_submenu_node_item(tr(group.title), submenu)

# A building's name; a trade post or pier carries the partner city's name after it.
func item_name(item: Dictionary) -> String:
	return tr(item.label) + (": " + str(item.partner_name) if item.has("partner_name") else "")

func building_text(item: Dictionary) -> String:
	return "%s  —  %s" % [item_name(item), cost_text(item)]

# Chooses a building from the menu exactly as a click on its item does (used by validators).
func activate_building(building: String) -> bool:
	if not build_popups.has(building):
		return false
	var entry: Array = build_popups[building]
	entry[0].id_pressed.emit(entry[1])
	return true

func select_tool(value: String, close_tray := true) -> void:
	current_tool = value
	placement_feedback_active = false
	for key in tool_buttons:
		tool_buttons[key].button_pressed = key == value
	build_menu.text = ""
	build_menu.tooltip_text = tr("Build")
	if build_entries.has(value):
		build_menu.tooltip_text = item_name(build_entries[value])
	for name in building_cards:
		building_cards[name].button_pressed = name == value
	if close_tray and value in ["select", "demolish"]:
		close_build_tray()
	show_selected_context()

func set_status(date: Array, money: int, population: int) -> void:
	var year := int(date[2])
	var era := tr("%d %s %d BC") if year < 0 else tr("%d %s %d AD")
	date_label.text = era % [int(date[0]), tr(MONTHS[clampi(int(date[1]) - 1, 0, 11)]), absi(year)]
	treasury_label.text = tr("%s dr") % group_digits(money)
	population_label.text = tr("%s citizens") % group_digits(population)

# Native cached stock and employment in the current city; labels never infer welfare scores.
func set_city_header(value: Dictionary) -> void:
	city_header = value
	%CityName.text = str(value.get("name", "—"))
	%CityName.tooltip_text = %CityName.text
	var stocks := {}
	for entry in value.get("stock", []): stocks[int(entry.resource)] = int(entry.count)
	for spec in HEADER_GOODS:
		var button: Button = resource_buttons[spec[0]]
		button.disabled = not stocks.has(spec[0])
		var amount: int = stocks.get(spec[0],0)
		button.text = group_digits(amount) if stocks.has(spec[0]) else "—"
		button.tooltip_text = tr("City stock: %s — %s") % [tr(spec[1]),group_digits(amount)]
	var jobs: Dictionary = value.get("employment", {})
	%Jobs.text = tr("Jobs") + (" · %d" % int(jobs.get("vacancies",0)) if int(jobs.get("vacancies",0)) > 0 else "")
	%Jobs.tooltip_text = tr("Employed: %d / %d\nOpen jobs: %d\nUnemployed: %d") % [int(jobs.get("employed",0)),int(jobs.get("employable",0)),int(jobs.get("vacancies",0)),int(jobs.get("unemployed",0))]
	%Jobs.disabled = jobs.is_empty()

func set_paused(value: bool) -> void:
	paused = value
	pause_button.text = ""
	pause_button.icon = icon("play" if paused else "pause")
	pause_button.tooltip_text = (tr("Resume") if paused else tr("Pause")) + " [%s]" % KeyBindings.label("pause")
	pause_button.button_pressed = paused

func set_speed(index: int) -> void:
	speed_button.select(index)

func set_undo_available(available: bool) -> void:
	undo_button.disabled = not available

# ---- overlays ----------------------------------------------------------------------------------------------
func overlay_text(id: String) -> String:
	var label: String = tr(Overlays.MODES[id][0])
	var binding := "overlay_" + id if id != "normal" else "overlay_normal"
	return label if KeyBindings.definition(binding).is_empty() else "%s   [%s]" % [label, KeyBindings.label(binding)]

# One entry per overlay; Culture and Science are submenus. Rebuilt when the language changes.
func populate_overlay_menu() -> void:
	var menu := overlay_menu.get_popup()
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu.clear()
	overlay_popups.clear()
	for entry in Overlays.MENU:
		if entry is String:
			if entry == "":
				menu.add_separator()
			else:
				menu.add_item(overlay_text(entry))
				overlay_popups[entry] = [menu, menu.item_count - 1]
				menu.set_item_metadata(menu.item_count - 1, entry)
		else:
			var submenu := PopupMenu.new()
			submenu.name = String(entry[0]).replace(" ", "")
			for id in entry[1]:
				submenu.add_item(overlay_text(id))
				submenu.set_item_metadata(submenu.item_count - 1, id)
				overlay_popups[id] = [submenu, submenu.item_count - 1]
			submenu.index_pressed.connect(func(index): overlay_selected.emit(submenu.get_item_metadata(index)))
			menu.add_child(submenu)
			menu.add_submenu_node_item(tr(entry[0]), submenu)
	set_overlay(current_overlay)

func set_overlay(id: String) -> void:
	current_overlay = id
	for view in welfare_buttons:
		welfare_buttons[view].button_pressed = view == id
	overlay_menu.text = ""
	overlay_menu.tooltip_text = (tr("Overlays") if id == "normal" else tr(Overlays.MODES[id][0])) + " ▾"
	overlay_legend.text = tr(Overlays.MODES[id][1])
	overlay_legend.visible = id != "normal"
	%OverlayPanel.visible = id != "normal"
	%OverlaySummary.show_data(id,%OverlaySummary.data if %OverlaySummary.mode==id else {})
	if id!="normal" and goals_list.visible:set_goals_expanded(false)
	_layout_panels()

func set_overlay_data(data: Dictionary) -> void:
	%OverlaySummary.show_data(str(data.get("mode",current_overlay)),data)

# Chooses an overlay exactly as a click on its menu item does (used by validators).
func activate_overlay(id: String) -> bool:
	if not overlay_popups.has(id):
		return false
	var entry: Array = overlay_popups[id]
	if entry[0] == overlay_menu.get_popup():
		entry[0].index_pressed.emit(entry[1])
		return true
	entry[0].index_pressed.emit(entry[1])
	return true

# The episode's objectives (from the core's `episode` query): a checked or open line each, with live status. Hidden
# when the game has none (open play). Lines are rebuilt only when their text changes.
var goals_signature := ""
var goals_state: Dictionary = {}

func set_goals(episode: Dictionary) -> void:
	var goals: Array = episode.get("goals", [])
	var met := int(episode.get("met", 0))
	var celebrate := not goals_state.is_empty() and met > int(goals_state.get("met", 0))
	goals_state = episode
	goals_panel.visible = not goals.is_empty() and not message_panel.visible
	var signature := str(goals.hash())
	if signature == goals_signature:
		return
	goals_signature = signature
	var total := int(episode.get("total", 0))
	# The wreath and the header bar show the share of the way, partial objectives counted by their progress.
	var share := 0.0
	for goal in goals:
		share += 1.0 if goal.met else float(goal.get("progress", 0.0))
	share = share / maxf(goals.size(), 1)
	# The count lives on the summary line under the title ("1 of 4 achieved"), not in the title itself.
	goals_title.text = tr("Objectives")
	%GoalsSummary.text = tr("%d of %d achieved") % [met, total]
	%GoalsProgress.value = share
	%GoalsProgress.theme_type_variation = "ObjectiveBarDone" if met == total and total > 0 else "ObjectiveBar"
	%GoalsWreath.set_progress(share, celebrate)
	for child in goals_list.get_children():
		child.free()
	# Open objectives first, then the achieved ones.
	var ordered: Array = goals.filter(func(g): return not g.met) + goals.filter(func(g): return g.met)
	for goal in ordered:
		goals_list.add_child(ObjectiveCard.build(goal, tr, func(index): set_aside_requested.emit(index)))
	_size_goals.call_deferred()
	_layout_panels.call_deferred()

# The list scrolls only when it is taller than a third of the screen.
func _size_goals() -> void:
	%GoalsScroll.custom_minimum_size.y = clampf(goals_list.get_combined_minimum_size().y, 60.0, maxf(size.y * .45, 200.0))
	goals_panel.reset_size()
	_layout_panels.call_deferred()

func confirm_main_menu() -> void:
	menu_dialog.popup_centered()

# Re-applies every translatable text for the current locale. No control is rebuilt.
func retranslate() -> void:
	populate_overlay_menu()
	goals_signature = ""
	if not goals_state.is_empty():
		set_goals(goals_state)
	%MapPeek.text = tr("City map")
	%MapPeek.tooltip_text = tr("Show city map")
	%MapClose.tooltip_text = tr("Hide city map")
	%MapToggle.tooltip_text = tr("Show or hide the map")
	%BuildSearch.placeholder_text = tr("Search buildings…")
	%ResourcesToggle.tooltip_text = tr("Hide resources") if resources_open else tr("Show resources")
	%RotateLeft.tooltip_text = tr("Turn left")
	%RotateRight.tooltip_text = tr("Turn right") + " (%s)" % KeyBindings.label("turn_placement")
	%WallFill.text = tr("Fill wall rectangle")
	%TrayClose.tooltip_text = tr("Close")
	%InspectorClose.tooltip_text = tr("Close")
	%MessageClose.tooltip_text = tr("Close")
	_decision_caption()
	%EmptySearch.text = tr("No matching buildings")
	goals_toggle.tooltip_text = tr("Show or hide the objectives")
	goals_toggle.text = "+" if not goals_list.visible else "–"
	menu_dialog.title = tr("Main menu")
	menu_dialog.dialog_text = tr("Return to the main menu? Progress since your last save is lost.")
	menu_dialog.ok_button_text = tr("Main menu")
	menu_dialog.cancel_button_text = tr("Stay")

	set_paused(paused)
	for index in SPEEDS.size():
		speed_button.set_item_text(index, tr(SPEEDS[index]))
	for key in tool_buttons:
		for entry in tool_entries:
			if entry[0] == key:
				tool_buttons[key].tooltip_text = tr(entry[1])
	populate_build_menu()
	populate_categories()
	if %BuildTray.visible:
		populate_build_cards()
	select_tool(current_tool, false)
	undo_button.text = ""
	undo_button.tooltip_text = tr("Undo last construction") + " (%s)" % KeyBindings.label("undo")
	date_label.tooltip_text = tr("Date")
	treasury_label.tooltip_text = tr("Treasury")
	population_label.tooltip_text = tr("Population")
	%ActiveToolClose.tooltip_text=tr("Close")
	for view in welfare_buttons: welfare_buttons[view].tooltip_text = overlay_text(view)
	set_city_header(city_header)
	save_dialog.title = tr("Save game")
	save_dialog.get_ok_button().text = tr("Save")
	save_dialog.get_cancel_button().text = tr("Cancel")
	save_prompt.text = tr("Name of the save")
	load_dialog.title = tr("Load game")
	load_dialog.get_ok_button().text = tr("Load")
	load_dialog.get_cancel_button().text = tr("Cancel")
	message_title.text = tr("City journal")
	set_unread(unread)
	demolition_dialog.title = tr("Demolish this landmark?")
	demolition_dialog.get_ok_button().text = tr("Demolish")
	demolition_dialog.get_cancel_button().text = tr("Keep")

# 1234567 -> "1,234,567" (a no-break space groups digits in Russian).
func group_digits(value: int) -> String:
	var digits := str(absi(value))
	var separator := " " if TranslationServer.get_locale().begins_with("ru") else ","
	var result := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += separator
		result += digits[index]
	return ("-" if value < 0 else "") + result

# ---- messages ---------------------------------------------------------------------------------------------
var unread := 0

func toggle_messages() -> void:
	set_messages_open(not message_panel.visible)

func set_messages_open(open: bool) -> void:
	message_panel.visible = open
	_layout_panels()
	messages_toggled.emit(open)

func set_unread(count: int) -> void:
	unread = count
	messages_button.text = "" if count == 0 else str(count)
	messages_button.tooltip_text = tr("City journal") + ("\n" + tr("Inbox (%d)") % count if count > 0 else "")

# History uses the same disclosure as news chips; it retains the complete native wording.
func set_messages(entries: Array) -> void:
	var cards := {}
	for child in message_list.get_children():
		if child is NoticeChip: cards[child.message_id] = child
		else: child.free()
	if entries.is_empty():
		for card in cards.values(): card.free()
		var empty := Label.new()
		empty.theme_type_variation = "Detail"
		empty.text = tr("No messages yet")
		message_list.add_child(empty)
		return
	var rows: Array = NotificationPolicy.rows(entries)
	# If a row is being read, keep it and its neighbours in their current order until reading ends.
	var reading: bool = cards.values().any(func(card): return card.expanded)
	var retained := {}
	for index in range(rows.size() - 1, -1, -1):
		var entry: Dictionary = rows[index]
		var title := str(entry.title)
		var body := str(entry.text)
		if entry.occurrences.size() > 1:
			title += " · ×%d" % entry.occurrences.size()
			var occurrences: Array[String] = []
			for occurrence in entry.occurrences:
				occurrences.append(str(occurrence.date) + "\n" + str(occurrence.text))
			body = "\n\n".join(occurrences)
		var id := int(entry.id)
		var card: Control = cards.get(id)
		if card == null:
			card = NoticeChip.new()
			card.history_row = true
			card.configure(id, title, body, 0, str(entry.date))
			card.expansion_requested.connect(func(chip): _expand_notice(chip, message_list))
			message_list.add_child(card)
		else: card.update_text(title, body, str(entry.date))
		if not reading: message_list.move_child(card, rows.size() - 1 - index)
		retained[id] = true
	for id in cards:
		if not retained.has(id): cards[id].free()
	_layout_panels.call_deferred()

# One visible alert; later alerts queue. Hover, reading, or a hidden stack suspends the countdown.
func show_toast(id: int, title_text: String, body_text: String) -> void:
	if toasts.get_children().any(func(card): return card.message_id == id) or alert_queue.any(func(entry): return entry.id == id): return
	if toasts.get_child_count() >= MAX_TOASTS:
		alert_queue.append({"id": id, "title": title_text, "text": body_text})
		return
	var card := NoticeChip.new()
	card.configure(id, title_text, body_text, TOAST_SECONDS)
	card.dismiss_requested.connect(func(_id): _close_toast(card))
	card.expansion_requested.connect(func(chip): _expand_notice(chip, toasts))
	toasts.add_child(card)

func _expand_notice(chip: Control, collection: Node) -> void:
	for other in collection.get_children():
		if other != chip and other.get("expanded") == true: other.set_expanded(false)

func set_minimap_open(open: bool, persist := false) -> void:
	%MapToggle.set_pressed_no_signal(open)
	if open:
		if decision_expanded: set_decision_expanded(false)
		close_build_tray()
		if message_panel.visible: set_messages_open(false)
	if persist and (not automation or Engine.has_meta("ezeus_settings_path")):
		UserSettings.set_value("interface", "minimap_visible", open)
	_layout_panels()

# Collapsing the presentation never answers, dismisses, or resumes a native decision.
func set_decision(decision: Dictionary, pending_count := 0) -> void:
	var next_id := int(decision.get("id", -1))
	if next_id != decision_id: decision_expanded = next_id >= 0
	decision_id = next_id
	decision_count = pending_count
	%EnvoyCity.text = str(decision.get("sender_name", ""))
	%EnvoyLeader.text = str(decision.get("sender_leader", ""))
	%EnvoyLeader.visible = not %EnvoyLeader.text.is_empty()
	envoy_portrait.set_sender(int(decision.get("sender_index", -1)))
	%EventActionScroll.visible = decision_expanded
	%EnvoyHeader.visible = decision_expanded
	if decision_expanded: set_goals_expanded(false)
	events_box.visible = not decision.is_empty()
	var title_text:=str(decision.get("title",""))
	%DecisionToggle.text=title_text.substr(0,1).to_upper()+title_text.substr(1)
	%DecisionToggle.tooltip_text = tr("Fold decision") if decision_expanded else tr("Review decision") + "\n" + %DecisionToggle.text
	_decision_caption()
	%EventActionScroll.visible = decision_expanded
	%EnvoyHeader.visible = decision_expanded
	%EventScroll.visible = decision_expanded
	events_box.reset_size()

func _decision_caption() -> void:
	%DecisionCaption.text = tr("Awaiting your decision") if decision_count <= 1 else tr("Awaiting your decision · %d pending") % decision_count

func set_decision_expanded(expanded: bool) -> void:
	decision_expanded = expanded and decision_id >= 0
	if decision_expanded: set_goals_expanded(false)
	%EventActionScroll.visible = decision_expanded
	%EnvoyHeader.visible = decision_expanded
	%EventScroll.visible = decision_expanded
	%DecisionToggle.tooltip_text = tr("Fold decision") if decision_expanded else tr("Review decision") + "\n" + %DecisionToggle.text
	events_box.reset_size()
	_layout_panels()

func _close_toast(card: Node) -> void:
	if not is_instance_valid(card) or card.is_queued_for_deletion():
		return
	card.get_parent().remove_child(card)
	message_dismissed.emit(int(card.get_meta("id")))
	card.queue_free()
	if not alert_queue.is_empty():
		var next: Dictionary = alert_queue.pop_front()
		show_toast(int(next.id), str(next.title), str(next.text))

# ---- saving and loading ---------------------------------------------------------------------------------
func open_save_dialog(default_name: String) -> void:
	save_name.text = default_name
	save_dialog.popup_centered(Vector2i(460, 170))
	save_name.grab_focus()
	save_name.select_all()

# `entries` are dictionaries with name, path and detail (newest first); the first one is selected.
func open_load_dialog(entries: Array) -> void:
	save_entries = entries
	save_list.clear()
	for entry in entries:
		save_list.add_item(entry.name)
	save_info.text = ""
	load_dialog.get_ok_button().disabled = entries.is_empty()
	if entries.is_empty():
		save_info.text = tr("No saved games yet")
	else:
		save_list.select(0)
		save_info.text = entries[0].detail
	load_dialog.popup_centered(Vector2i(520, 400))

func _confirm_load() -> void:
	var selected := save_list.get_selected_items()
	if not selected.is_empty():
		load_requested.emit(save_entries[selected[0]].path)

# ---- construction dock -----------------------------------------------------------------------------------
# The price of a building: drachmas, and for a sanctuary the marble it takes from the stores.
func cost_text(item: Dictionary) -> String:
	# A pyramid, monument or shrine costs no drachmas: its materials come by cart as it is built. A roadblock, a
	# commemorative or a god's monument (granted by the scenario) is simply free, as in the SDL game.
	if int(item.cost) == 0 and int(item.get("marble", 0)) == 0:
		var name := str(item.get("name", ""))
		return tr("Materials by cart") if name.begins_with("pyramid_") or name.begins_with("shrine_") else tr("Free")
	var text: String = tr("%s dr") % group_digits(int(item.cost))
	if int(item.get("marble", 0)) > 0:
		text += " + " + tr("%d marble") % int(item.marble)
	return text

func icon(name: String) -> Texture2D:
	if not icon_cache.has(name):
		icon_cache[name] = load("res://ui/icons/%s.svg" % name)
	return icon_cache[name]

func populate_categories() -> void:
	for child in %Categories.get_children():
		child.free()
	category_buttons.clear()
	for group in build_groups:
		var art: Array = CATEGORY_ART.get(group.title, CATEGORY_ART.Other)
		var button := Button.new()
		button.theme_type_variation = "Category_" + str(art[0])
		button.custom_minimum_size = Vector2(32, 32)
		button.icon = icon(art[0])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.text = ""
		button.tooltip_text = tr(group.title)
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.button_pressed = %BuildTray.visible and active_category == group.title
		button.pressed.connect(func(): open_category(group.title))
		%Categories.add_child(button)
		category_buttons[group.title] = button
	if not active_category.is_empty() and not category_buttons.has(active_category):
		close_build_tray()

func open_category(title: String) -> void:
	if active_category == title and %BuildTray.visible:
		close_build_tray()
		return
	set_goals_expanded(false)
	active_category = title
	%BuildSearch.text = ""
	%BuildTray.show()
	%BuildingScroll.scroll_horizontal = 0
	for key in category_buttons:
		category_buttons[key].button_pressed = key == title
	populate_build_cards()
	_layout_panels()

func close_build_tray() -> void:
	%BuildTray.hide()
	%BuildSearch.release_focus()
	for button in category_buttons.values():
		button.button_pressed = false
	_layout_panels()

func populate_build_cards() -> void:
	for child in %BuildingCards.get_children():
		child.free()
	building_cards.clear()
	card_previews.clear()
	var query: String = ""
	%TrayTitle.text = tr(active_category) if query.is_empty() else tr("Search results")
	for group in build_groups:
		if query.is_empty() and group.title != active_category:
			continue
		for item in group.items:
			if not query.is_empty() and not item_name(item).to_lower().contains(query):
				continue
			var button := Button.new()
			button.theme_type_variation = "BuildingCard"
			var name_height:=ceilf(get_theme_font("font","CardName").get_height(get_theme_font_size("font_size","CardName")))*2
			var card_width:=maxf(112,112*get_theme_font_size("font_size","CardName")/12.0)
			button.custom_minimum_size = Vector2(card_width,maxf(110,54+maxf(32,name_height)+24))
			button.focus_mode = Control.FOCUS_NONE
			button.toggle_mode = true
			button.button_pressed = current_tool == item.name
			button.tooltip_text = building_text(item) + " · " + tr("%d × %d tiles") % [item.w, item.h]
			button.pressed.connect(func():
				%BuildSearch.release_focus()
				tool_selected.emit(item.name))
			button.mouse_entered.connect(func(): show_context(item, group.title))
			button.mouse_exited.connect(show_selected_context)
			%BuildingCards.add_child(button)
			building_cards[item.name] = button
			var column := VBoxContainer.new()
			column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			column.offset_left = 10; column.offset_right = -10
			column.offset_top = 8; column.offset_bottom = -8
			column.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(column)
			var preview := TextureRect.new()
			preview.custom_minimum_size = Vector2(92, 54)
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.texture = icon(CATEGORY_ART.get(group.title, CATEGORY_ART.Other)[0])
			column.add_child(preview)
			if not card_previews.has(item.asset): card_previews[item.asset] = []
			card_previews[item.asset].append(preview)
			if thumbnails != null:
				var cached: Texture2D = thumbnails.request(item.asset)
				if cached != null: preview.texture = cached
			var name_label := Label.new()
			name_label.text = item_name(item)
			name_label.theme_type_variation = "CardName"
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.max_lines_visible = 2
			name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			name_label.custom_minimum_size.y = maxf(32,name_height)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(name_label)
	%EmptySearch.visible = building_cards.is_empty()
	show_selected_context()

func show_selected_context() -> void:
	var item: Dictionary = build_entries.get(current_tool,{})
	if not item.is_empty():
		%ActiveToolTitle.text=item_name(item); %ActiveToolTitle.tooltip_text=item_name(item)
		%ActiveToolPrice.text=tr("%d × %d tiles") % [int(item.get("w",1)),int(item.get("h",1))]
	if item.is_empty():
		for group in build_groups:
			if group.title==active_category and not group.items.is_empty():
				show_context(group.items[0],group.title);return
	for group in build_groups:
		if group.items.any(func(entry):return entry.name==current_tool):
			show_context(item,group.title);return

func show_context(item: Dictionary, category: String) -> void:
	if item.is_empty():return
	context_item=item
	%ContextCategory.text=tr(category).to_upper()
	%ContextTitle.text=item_name(item)
	%ContextTitle.tooltip_text=item_name(item)
	%ContextFacts.text=tr("%d × %d tiles")%[item.w,item.h]
	%ContextPreview.texture=icon(CATEGORY_ART.get(category,CATEGORY_ART.Other)[0])
	if thumbnails!=null:
		var cached: Texture2D=thumbnails.request(item.asset)
		if cached!=null:%ContextPreview.texture=cached
	var selected: bool=item.name==current_tool
	var tool: String=item.name.get_slice(":",0)
	%RotateRow.hide()
	%ContextHelp.hide()
	%RotateLeft.disabled=not selected; %RotateRight.disabled=not selected
	%Facing.text=tr("Facing: %d°")%[facing*90]
	%WallFill.visible=tool=="wall"
	%WallFill.disabled=not selected
	if item.name=="road":%ContextHelp.text=tr("Click for one tile, or drag a road. The route follows the native grid.")
	elif item.name=="wall":%ContextHelp.text=tr("Drag an outline. Fill places the whole rectangle; Shift also fills it.")
	elif item.name in ["house","elite_house","park"]:%ContextHelp.text=tr("Click for one plot, or drag to place an area.")
	elif tool in ["pier","gatehouse"]:%ContextHelp.text=tr("Click to place. Facing follows the native connection; Esc returns to inspection.")
	else:%ContextHelp.text=tr("Click to place. T turns the preview; Esc returns to inspection.")
	if not selected:%ContextHelp.text=tr("Choose a building tile to start placement.")
	%ContextHelp.tooltip_text=%ContextHelp.text
	if item.name==current_tool:
		%ActiveToolHelp.text=%ContextHelp.text; %ActiveToolHelp.tooltip_text=%ContextHelp.text

func set_facing(value: int) -> void:
	facing=value
	%Facing.text=tr("Facing: %d°")%[facing*90]

func set_placement_feedback(text: String, valid: bool, active := true) -> void:
	placement_feedback_active=active and not text.is_empty()
	placement_source=text
	%PlacementText.text=text.replace("  •  ","\n")
	%PlacementBadge.theme_type_variation="PlacementGood" if valid else "PlacementBad"
	%PlacementBadge.reset_size()

func set_inspection_header(data: Dictionary) -> void:
	%InspectionSummary.show_data(data)
	inspector_text.visible=not data.has("footprint")
	%InspectorTitle.text = str(data.get("name", ""))
	%InspectorSubtitle.text = tr("City: %s") % str(data.city)
	%Workforce.visible = data.has("employees") and int(data.get("max_employees", 0)) > 0
	if %Workforce.visible:
		%Workforce.max_value = int(data.max_employees)
		%Workforce.value = int(data.employees)
		%Workforce.tooltip_text = tr("Workers: %d / %d") % [int(data.employees), int(data.max_employees)]

func set_goals_expanded(expanded: bool) -> void:
	goals_list.visible = expanded
	%GoalsScroll.visible = expanded
	goals_toggle.text = "–" if expanded else "+"
	if expanded:
		_size_goals.call_deferred()
	goals_panel.reset_size()
	_layout_panels.call_deferred()

func visible_popup(node: Node = null) -> PopupMenu:
	if node == null: node = self
	for child in node.get_children(true):
		if child is PopupMenu and child.visible: return child
		var found := visible_popup(child)
		if found != null: return found
	return null

# Untyped: a dialog freed before this deferred call arrives must be skipped, not fail the call.
func _attach_right_click_back(child) -> void:
	if not is_instance_valid(child): return
	for nested in child.get_children(true): _attach_right_click_back(nested)
	if child is Window and not child.has_node("RightClickBack"):
		var back := preload("res://ui/right_click_back.gd").new()
		back.name = "RightClickBack"
		child.add_child(back)
	# A dialog's confirming button (Apply, Done, Main menu…) is the gold Primary one; Cancel stays plain.
	if child is AcceptDialog and child.get_ok_button().theme_type_variation == &"":
		child.get_ok_button().theme_type_variation = "Primary"

func set_resources_open(open: bool) -> void:
	resources_open = open
	%ResourcesToggle.set_pressed_no_signal(open)
	%ResourcesToggle.text = "▴" if open else "▾"
	%ResourcesToggle.tooltip_text = tr("Hide resources") if open else tr("Show resources")
	if resources_tween != null: resources_tween.kill()
	var target := 1.0 if open else 0.0
	if get_tree().root.get_node("UiAccess").reduced_motion:
		resources_fraction = target
		_layout_panels()
		return
	%ResourcesReveal.show()
	resources_tween = create_tween()
	resources_tween.tween_method(func(value: float):
		resources_fraction = value
		_layout_panels(), resources_fraction, target, .24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	resources_tween.finished.connect(func(): _layout_panels())

func _layout_panels() -> void:
	if not is_node_ready():
		return
	# One surface contains the overview and every resource; wrap instead of clipping/scrolling goods.
	var available: float=maxf(100,size.x-48)
	var cell_width: float=56
	for button in resource_buttons.values():cell_width=maxf(cell_width,button.get_combined_minimum_size().x)
	var capacity: int=maxi(1,floori((available+3)/(cell_width+3)))
	var rows: int=ceili(float(HEADER_GOODS.size())/capacity)
	%ResourceGrid.columns=ceili(float(HEADER_GOODS.size())/rows)
	var ribbon_height: float=maxf(32,%ResourceRibbon.get_combined_minimum_size().y)
	%ResourceRibbon.offset_left=16; %ResourceRibbon.offset_right=size.x-16
	%ResourceRibbon.offset_top=8; %ResourceRibbon.offset_bottom=8+ribbon_height
	var resource_height: float=%ResourcesPanel.get_combined_minimum_size().y
	%ResourcesPanel.offset_left=0; %ResourcesPanel.offset_right=size.x-32
	%ResourcesPanel.offset_top=0; %ResourcesPanel.offset_bottom=resource_height
	%ResourcesReveal.offset_left=16; %ResourcesReveal.offset_right=size.x-16
	%ResourcesReveal.offset_top=12+ribbon_height
	%ResourcesReveal.offset_bottom=%ResourcesReveal.offset_top+resource_height*resources_fraction
	%ResourcesReveal.visible=resources_fraction>0.001
	%ResourcesPanel.modulate.a=resources_fraction
	var secondary_top: float=16+ribbon_height+(resource_height+4)*resources_fraction
	var welfare_height: float=maxf(28,%WelfareGroup.get_combined_minimum_size().y)
	%WelfareGroup.offset_left=16; %WelfareGroup.offset_right=16+%WelfareGroup.get_combined_minimum_size().x
	%WelfareGroup.offset_top=secondary_top; %WelfareGroup.offset_bottom=secondary_top+welfare_height
	var header_bottom: float=secondary_top+welfare_height
	%StatusBar.offset_bottom=header_bottom
	debug_panel.offset_top=header_bottom+10
	var content_top: float=header_bottom+12
	# Time/map at bottom left, construction at centre, objectives at bottom right.
	var time_width: float=maxf(180,%TimeGroup.get_combined_minimum_size().x)
	var time_height: float=maxf(54,%TimeGroup.get_combined_minimum_size().y)
	%TimeGroup.anchor_top=1; %TimeGroup.anchor_bottom=1
	%TimeGroup.offset_left=16; %TimeGroup.offset_right=16+time_width
	%TimeGroup.offset_bottom=-12; %TimeGroup.offset_top=-12-time_height
	goals_panel.visible = not goals_state.get("goals", []).is_empty()
	var goals_width: float=maxf(170,goals_panel.get_combined_minimum_size().x)
	var goals_height: float=goals_panel.get_combined_minimum_size().y
	goals_panel.offset_right=size.x-16; goals_panel.offset_left=goals_panel.offset_right-goals_width
	goals_panel.offset_top=size.y-12-goals_height; goals_panel.offset_bottom=size.y-12
	var dock_left: float=%TimeGroup.get_global_rect().end.x+12
	var dock_right: float=goals_panel.position.x-12 if goals_panel.visible else size.x-16
	# The dock's full width without scrolling: every control in the row at its own size, the categories unscrolled,
	# plus the frame's margins (measured, so the gold faces' padding is counted).
	var wanted_width: float=%Tools.get_combined_minimum_size().x-%CategoryScroll.get_combined_minimum_size().x+%Categories.get_combined_minimum_size().x+%BottomBar.get_theme_stylebox("panel").get_minimum_size().x+2
	# When the dock and the objectives do not fit side by side, the objectives move up rather than the dock scrolling.
	if dock_right-dock_left < wanted_width:
		goals_panel.offset_top=content_top; goals_panel.offset_bottom=content_top+goals_height
		dock_right=size.x-16
		if goals_panel.visible: content_top=goals_panel.get_global_rect().end.y+12
	var dock_width: float=minf(wanted_width,dock_right-dock_left)
	var dock_centre: float=(dock_left+dock_right)*.5
	%BottomBar.offset_left=dock_centre-dock_width*.5-size.x*.5
	%BottomBar.offset_right=dock_centre+dock_width*.5-size.x*.5
	var dock_height: float=maxf(40,%BottomBar.get_combined_minimum_size().y)
	%BottomBar.offset_bottom=-12; %BottomBar.offset_top=-12-dock_height
	var footer_top: float=minf(%TimeGroup.position.y,%BottomBar.position.y)
	inspector.offset_top=content_top
	message_panel.offset_top=content_top
	events_box.offset_top=content_top
	inspector.offset_left=-16-maxf(340,inspector.get_combined_minimum_size().x)
	var content_height: float = %InspectorColumn.get_combined_minimum_size().y + %InspectorContents.get_combined_minimum_size().y + 32
	var tray_height: float=%BuildTray.get_combined_minimum_size().y
	var tray_bottom: float=%BottomBar.position.y-size.y-5
	%BuildTray.offset_top=tray_bottom-tray_height
	%BuildTray.offset_bottom=tray_bottom
	var tray_width:=minf(980,size.x-32)
	%BuildTray.offset_left=-tray_width*.5; %BuildTray.offset_right=tray_width*.5
	%MinimapPanel.visible=%MapToggle.button_pressed and not %BuildTray.visible and not message_panel.visible and not decision_expanded
	%MapPeek.visible=not %MinimapPanel.visible and not %BuildTray.visible and not message_panel.visible
	var map_bottom: float=%TimeGroup.offset_top-8
	var map_height:=maxf(192,%MinimapPanel.get_combined_minimum_size().y)
	var map_width:=maxf(192,%MinimapPanel.get_combined_minimum_size().x)
	%MinimapPanel.anchor_left=0; %MinimapPanel.anchor_right=0
	%MinimapPanel.offset_left=16; %MinimapPanel.offset_right=16+map_width
	%MinimapPanel.offset_bottom=map_bottom; %MinimapPanel.offset_top=map_bottom-map_height
	%MapPeek.anchor_left=0; %MapPeek.anchor_right=0
	%MapPeek.offset_left=16; %MapPeek.offset_right=16+maxf(140,%MapPeek.get_combined_minimum_size().x)
	%MapPeek.offset_bottom=map_bottom
	%MapPeek.offset_top=map_bottom-maxf(30,%MapPeek.get_combined_minimum_size().y)
	%EventRail.anchor_left=1; %EventRail.anchor_right=1
	%EventRail.offset_right=-16; %EventRail.offset_left=-16-%EventRail.get_combined_minimum_size().x
	%EventRail.offset_top=secondary_top
	%EventRail.offset_bottom=%EventRail.offset_top+%EventRail.get_combined_minimum_size().y
	message_panel.offset_top=%EventRail.offset_bottom+8
	var inspector_end: float=%BuildTray.position.y-8 if %BuildTray.visible else footer_top-8
	if goals_panel.visible and goals_panel.position.y > content_top:
		inspector_end=minf(inspector_end,goals_panel.position.y-8)
	var inspector_available:=maxf(0,inspector_end-content_top)
	var minimum_height:=156.0 if inspector_text.visible else 220.0
	var inspection_height: float=minf(maxf(content_height,minimum_height),inspector_available)
	inspector.offset_top=inspector_end-inspection_height
	inspector.offset_bottom=inspector_end-size.y
	message_panel.offset_left=-16-maxf(360,message_panel.get_combined_minimum_size().x)
	%ActiveToolCard.visible=build_entries.has(current_tool) and not %BuildTray.visible and not inspector.visible and not message_panel.visible and not decision_expanded
	var tool_card_end: float=inspector_end
	%ActiveToolCard.offset_top=tool_card_end-minf(%ActiveToolCard.get_combined_minimum_size().y,maxf(0,tool_card_end-content_top))
	%ActiveToolCard.offset_bottom=tool_card_end-size.y
	var journal_end: float = %BuildTray.position.y-8 if %BuildTray.visible else inspector_end
	var journal_top: float=message_panel.offset_top
	var journal_room: float = maxf(0,journal_end-journal_top)
	var journal_height: float = %MessageHeader.get_combined_minimum_size().y + message_list.get_combined_minimum_size().y + 42
	message_panel.offset_bottom = -size.y + journal_top + minf(journal_height,minf(journal_room,(size.y-journal_top)*.55))
	# Notices hang as a short pill under the top bar (and under the invasion notice when it shows), centred.
	var notice_top: float=header_bottom+10
	var banner: Control=get_node_or_null("InvasionBanner")
	if banner!=null and banner.visible:notice_top=maxf(notice_top,banner.get_global_rect().end.y+8)
	var pill_width: float=minf(%Feedback.get_combined_minimum_size().x,minf(620,size.x-32))
	%Feedback.anchor_left=.5; %Feedback.anchor_right=.5; %Feedback.anchor_top=0; %Feedback.anchor_bottom=0
	%Feedback.offset_left=-pill_width*.5; %Feedback.offset_right=pill_width*.5
	%Feedback.offset_top=notice_top; %Feedback.offset_bottom=notice_top+%Feedback.get_combined_minimum_size().y
	%OverlayPanel.offset_top = header_bottom+12
	%OverlayPanel.visible = current_overlay != "normal"
	var overlay_end: float=%BuildTray.position.y-8 if %BuildTray.visible else %BottomBar.position.y-8
	%OverlaySummary.fit_height(overlay_end-%OverlayPanel.position.y-10)
	%OverlayPanel.reset_size()
	%OverlayPanel.offset_right=324
	# A single centre stack uses only its contents' height: the rest of the city still receives input.
	var notice_left: float=%OverlayPanel.get_global_rect().end.x+10 if %OverlayPanel.visible else 64
	var notice_right: float=message_panel.position.x-10 if message_panel.visible else (inspector.position.x-10 if inspector.visible else size.x-16)
	var notice_width:=minf(380,maxf(240,notice_right-notice_left))
	var notice_centre:=maxf(notice_left+notice_width*.5,notice_right-notice_width*.5)-size.x*.5
	# Envoy correspondence has a stable home on the left below welfare controls.
	var envoy_width := minf(440, maxf(260, size.x - notice_left - 20))
	events_box.custom_minimum_size.x = envoy_width
	events_box.offset_left = notice_left - size.x * .5
	events_box.offset_right = events_box.offset_left + envoy_width
	envoy_portrait.custom_minimum_size = Vector2(88,102) if size.y < 650 else Vector2(116,136)
	var decision_end := minf(%TimeGroup.position.y, %BottomBar.position.y) - 12
	if %BuildTray.visible: decision_end = minf(decision_end, %BuildTray.position.y - 12)
	var chrome: float = %DecisionCaption.get_combined_minimum_size().y + %DecisionToggle.get_combined_minimum_size().y + %EnvoyHeader.get_combined_minimum_size().y + 68
	var envoy_available := maxf(90, decision_end - events_box.position.y - chrome)
	%EventActionScroll.custom_minimum_size.y = minf(%EventActions.get_combined_minimum_size().y, minf(160,envoy_available * .55))
	%EventScroll.custom_minimum_size.y = clampf(events_panel.get_combined_minimum_size().y, 40, maxf(40,envoy_available-%EventActionScroll.custom_minimum_size.y))

	events_box.reset_size()
	%ToastScroll.visible = not message_panel.visible and not decision_expanded and toasts.get_child_count() > 0
	%ToastScroll.offset_left=notice_centre-notice_width*.5; %ToastScroll.offset_right=notice_centre+notice_width*.5
	%ToastScroll.offset_top=events_box.position.y+events_box.size.y+8 if events_box.visible else content_top
	var stack_room:=maxf(44,(%BuildTray.position.y if %BuildTray.visible else %BottomBar.position.y)-%ToastScroll.position.y-8)
	if %MinimapPanel.visible and %MinimapPanel.position.x < %ToastScroll.get_global_rect().end.x and %MinimapPanel.get_global_rect().end.x > %ToastScroll.position.x:
		stack_room=minf(stack_room,maxf(44,%MinimapPanel.position.y-%ToastScroll.position.y-8))
	%ToastScroll.offset_bottom=%ToastScroll.offset_top+minf(toasts.get_combined_minimum_size().y,stack_room)
	# The tray never steals text entry or closes the selected construction tool.

func set_model_factory(factory: Callable) -> void:
	thumbnails = ThumbnailService.new()
	thumbnails.factory = factory
	add_child(thumbnails)
	thumbnails.thumbnail_ready.connect(func(asset, texture):
		if context_item.get("asset","")==asset:%ContextPreview.texture=texture
		for preview in card_previews.get(asset, []):
			if is_instance_valid(preview): preview.texture = texture)

func _process(_delta: float) -> void:
	_layout_panels()
	var badge: PanelContainer=%PlacementBadge
	badge.visible=placement_feedback_active and get_viewport().gui_get_hovered_control()==null
	if badge.visible:
		var minimum:=Vector2(12,%StatusBar.size.y+8)
		var maximum:=Vector2(size.x-12,minf(%BottomBar.position.y,%TimeGroup.position.y)-8)-badge.size
		badge.position=(get_local_mouse_position()+Vector2(22,20)).clamp(minimum,maximum.max(minimum))
	if hint.text != notice_seen:
		notice_seen = hint.text
		if is_notice(hint.text):
			show_notice(hint.text)

# ---- notices ----------------------------------------------------------------------------------------------
# `hint` is where the city writes what just happened ("Autosaved", "The tax rate is set.", why a command was refused). Only real
# notices are shown, briefly, as a pill under the top bar: not the placement line (the badge at the pointer shows it), not the idle
# controls hint, not routine confirmations, and not the same words again within NOTICE_REPEAT seconds.
const NOTICE_SECONDS := 3.5
const NOTICE_REPEAT := 30.0
const QUIET_NOTICES := ["Built. Undo is available for the last construction.", "Demolished using the city's rules.", "Loading…"]
var notice_seen := ""
var notice_text := ""
var notice_at := -1000.0
var notice_tween: Tween
var placement_source := ""
var notice_label := Label.new()

func is_notice(text: String) -> bool:
	if text.is_empty() or text == KeyBindings.idle_hint() or text == placement_source:
		return false
	for quiet in QUIET_NOTICES:
		if text == tr(quiet):
			return false
	var now := Time.get_ticks_msec() / 1000.0
	return text != notice_text or now - notice_at > NOTICE_REPEAT

func show_notice(text: String) -> void:
	notice_text = text
	notice_at = Time.get_ticks_msec() / 1000.0
	var font := notice_label.get_theme_font("font")
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, notice_label.get_theme_font_size("font_size")).x > 580
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wide else TextServer.AUTOWRAP_OFF
	notice_label.custom_minimum_size.x = 580 if wide else 0
	notice_label.text = text
	var pill: Control = %Feedback
	if notice_tween != null: notice_tween.kill()
	pill.modulate.a = 1.0
	pill.visible = true
	pill.reset_size()
	notice_tween = pill.create_tween()
	notice_tween.tween_interval(NOTICE_SECONDS)
	notice_tween.tween_property(pill, "modulate:a", 0.0, .4)
	notice_tween.tween_callback(pill.hide)

# Shared Escape-menu labels preserve all native actions and rebindable shortcuts.
func menu_action_text(action: String) -> String:
	var index: int=GAME_ACTIONS.find(action)
	if index<0:return ""
	var label: String=tr(GAME_LABELS[index])
	if GAME_KEYS.has(action):label+=" (%s)"%KeyBindings.label(GAME_KEYS[action])
	return label
