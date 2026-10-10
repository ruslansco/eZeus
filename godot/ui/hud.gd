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
signal demolition_spared
signal save_requested(save_name: String)
signal load_requested(path: String)
signal messages_toggled(open: bool)
signal goals_toggled(open: bool)
signal main_menu_confirmed
signal set_aside_requested(index: int)
signal overlay_selected(id: String)
# Explicit close, timeout or overflow dismisses informational news through main.gd; reading never does.
signal message_dismissed(id: int)
signal decision_visibility_changed(expanded: bool)
signal toolbar_focus_changed(blocked: bool)

const NoticeChip = preload("res://ui/notification_chip.gd")
const NotificationPolicy = preload("res://scripts/notification_policy.gd")
const HazardRail = preload("res://ui/hazard_rail.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")
const ThumbnailService = preload("res://ui/building_thumbnails.gd")
const UiText = preload("res://scripts/ui_text.gd")
const BuildCatalog = preload("res://scripts/build_catalog.gd")
const ObjectiveCard = preload("res://ui/objective_card.gd")
const Overlays = preload("res://scripts/overlays.gd")
const SPEEDS := ["Speed 1", "Speed 2", "Speed 3", "Speed 4"]
const MINIMAP_PREFERENCE_VERSION := 2
const MoodFace = preload("res://ui/mood_face.gd")
# The top bar's gauges: the month's progress behind the date, and the housing in use.
# The lapis-and-gold palette (scripts/build_ui_theme.gd): gauges fill in deep gold, a warning in terracotta.
const GAUGE_FILL := Color(.55, .43, .21)
const GAUGE_FULL := Color(.66, .29, .20)
const INCOME_UP := Color(.97, .87, .64)
const INCOME_DOWN := Color(.95, .48, .38)
const MONTH_DAYS := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
# The native popularity verdicts (eCityData::popularity), from the top.
const POPULARITY_WORDS := [[90, "Popularity is superb"], [85, "Popularity is great"], [80, "Popularity is high"], [75, "Popularity is good"], [70, "Popularity is ok"], [60, "Popularity is poor"], [50, "Popularity is bad"], [40, "Popularity is awful"], [-1, "Popularity is terrible"]]
# Original icon drawings; category labels are short, while tooltips keep the full native catalog heading.
const CATEGORY_ART := {
	"Housing and roads": ["homes", "Homes"], "Agriculture": ["food", "Food"],
	"Industry": ["industry", "Industry"], "Storage": ["storage", "Storage"],
	"Trade": ["trade", "Trade"], "Markets": ["markets", "Markets"],
	"Health and water": ["water", "Health"], "Administration and security": ["civic", "Civic"],
	"Walls and defence": ["defence", "Defence"], "Culture": ["culture", "Culture"],
	"Science": ["science", "Science"], "Sanctuaries": ["sanctuaries", "Temples"], "Pyramids": ["pyramids", "Pyramids"], "Shrines": ["shrines", "Shrines"], "Heroes' halls": ["heroes", "Heroes"], "Gardens and monuments": ["gardens", "Gardens"],
	"Other": ["build", "Other"]}
const TOOL_KEYS := {"house":"build_house", "road":"build_road", "roadblock":"build_roadblock", "demolish":"demolish"}
const TOOL_ART := {"select": "inspect", "road": "road", "house": "homes", "roadblock": "roadblock", "demolish": "demolish"}
const ToolbarButton = preload("res://ui/toolbar_button.gd")
const CATEGORY_HELP := {
	"Housing and roads": "Homes, roads, bridges and roadblocks.",
	"Agriculture": "Farms, orchards, livestock and fishing.",
	"Industry": "Workshops that turn raw materials into goods.",
	"Storage": "Store food and goods in granaries and warehouses.",
	"Trade": "Trade with other cities by land and sea.",
	"Markets": "Bring food and supplies to your citizens.",
	"Health and water": "Fountains, baths and care for your citizens.",
	"Administration and security": "Manage taxes, maintain buildings and keep order.",
	"Walls and defence": "Walls, towers, horses and the navy.",
	"Culture": "Education, theatre, athletics and races.",
	"Science": "Learning, research and invention.",
	"Sanctuaries": "Build a sanctuary for an Olympian god.",
	"Pyramids": "Raise the great monuments of Atlantis.",
	"Shrines": "Honor the gods with smaller places of worship.",
	"Heroes' halls": "Build the halls that welcome legendary heroes.",
	"Gardens and monuments": "Beautify your city with greenery and monuments.",
	"Other": "More buildings available to this city."}
const TOOL_HELP := {"select": "Inspect the city or select a building.", "road": "Connect your city. Click and drag to lay a road.", "house": "Homes, roads, bridges and roadblocks.", "roadblock": "Road Block", "demolish": "Remove buildings or drag across an area. Landmarks ask for confirmation."}
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
@onready var speed_row: HBoxContainer = %Speed
# One chevron button per native speed (0..3), lit up to the chosen one.
var speed_buttons: Array[Button] = []
var mood: Control
@onready var tool_row: HBoxContainer = %ToolButtons
@onready var build_menu: MenuButton = %BuildMenu
@onready var undo_button: Button = %Undo
@onready var overlay_menu: Button = %OverlayMenu
@onready var overlay_catalog: MenuButton = %OverlayCatalog
var layer_buttons: Dictionary = {}
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
# The dialog of a dragged area also offers to spare the landmarks in it.
var demolition_spare: Button
var demolition_area := false
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
var toolbar_context_width := 0.0
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
var decision_postponable := false
var resources_open := false
var resources_fraction := 0.0
var resources_tween: Tween
var automation := false
var toolbar_hovered: BaseButton
var toolbar_blocked := false
var journal_entries: Array = []
var journal_filter := "all"
var journal_filters := {}

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
	%Messages.icon = toolbar_icon("notice_journal")
	%ObjectivesButton.icon = toolbar_icon("notice_objectives")
	%ObjectivesButton.accent = Color("d6bc79")
	%ObjectivesButton.pressed.connect(func(): set_goals_expanded(not goals_list.visible))
	%DecisionReview.icon = toolbar_icon("notice_decision")
	%DecisionReview.accent = Color("f0b866")
	%DecisionReview.pressed.connect(func(): set_decision_expanded(true))
	%AlertScroll.get_v_scroll_bar().theme_type_variation = "NotificationScrollBar"
	var filters := HBoxContainer.new()
	%MessageColumn.add_child(filters)
	%MessageColumn.move_child(filters,1)
	for spec in [["all","All reports"],["warnings","Warnings"],["decisions","Decisions"]]:
		var button := ToolbarButton.new()
		button.theme_type_variation = "ToolbarTool"
		button.text = tr(spec[1])
		button.set_meta("title",spec[1])
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_pressed = spec[0] == journal_filter
		button.pressed.connect(func():
			journal_filter = spec[0]
			for id in journal_filters: journal_filters[id].set_pressed_no_signal(id == journal_filter)
			set_messages(journal_entries))
		filters.add_child(button)
		journal_filters[spec[0]] = button
	for index in HEADER_GOODS.size():
		var spec: Array = HEADER_GOODS[index]
		var button := ToolbarButton.new()
		button.theme_type_variation = "ResourcePill"
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = load("res://ui/resource_art/"+spec[2]+".png"); button.text = "—"
		button.focus_mode = Control.FOCUS_ALL
		button.help_detail = tr("Select a good to inspect its city supply view.")
		button.pressed.connect(func(): _choose_overlay("supplies" if spec[0] == 255 or spec[0] <= 128 else "distribution"))
		%ResourceGrid.add_child(button)
		resource_buttons[spec[0]] = button
	for spec in [["supplies","food"],["water","water"],["hygiene","health"],["hazards","risk"]]:
		var button := ToolbarButton.new()
		button.theme_type_variation = "WelfareButton"; button.icon = icon(spec[1])
		button.custom_minimum_size = Vector2(30,28)
		button.toggle_mode = true
		button.pressed.connect(func(): _choose_overlay(spec[0]))
		%WelfareButtons.add_child(button); welfare_buttons[spec[0]] = button
		_wire_toolbar_help(button)
	%ActiveToolClose.icon=icon("close")
	%ActiveToolClose.pressed.connect(func(): tool_selected.emit("select"))
	%Jobs.icon = toolbar_icon("industry")
	%ResourcesToggle.icon = toolbar_icon("storage")
	%Jobs.pressed.connect(func(): _choose_overlay("industry"))
	%InspectionSummary.overlay_selected.connect(func(id):overlay_selected.emit(id))
	%OverlaySummary.overlay_selected.connect(func(id):overlay_selected.emit(id))
	get_tree().root.get_node("UiAccess").changed.connect(func():
		if %BuildTray.visible:populate_build_cards()
		_measure_toolbar_context()
		_layout_panels.call_deferred())
	%RotateLeft.icon=icon("rotate_left"); %RotateRight.icon=icon("rotate_right")
	%RotateLeft.pressed.connect(func(): placement_turn_requested.emit(-1))
	%RotateRight.pressed.connect(func(): placement_turn_requested.emit(1))
	%WallFill.toggled.connect(func(filled): wall_fill_changed.emit(filled))
	automation = OS.get_cmdline_args().has("--script") or Array(OS.get_cmdline_user_args()).any(func(arg): return arg == "--validate" or arg == "--skip-start" or "-review" in arg)
	%MapToggle.set_pressed_no_signal(true if automation else preferred_minimap_open())
	%MapToggle.icon = toolbar_icon("map")
	%MapToggle.pressed.connect(func():
		set_minimap_open(true if %BuildTray.visible or message_panel.visible or decision_expanded else %MapToggle.button_pressed, true))
	%MapPeek.icon = icon("map")
	%MapPeek.pressed.connect(func(): set_minimap_open(true, true))
	%MapClose.icon = icon("minimize")
	%MapClose.pressed.connect(func(): set_minimap_open(false, true))
	envoy_portrait = load("res://ui/envoy_portrait.gd").new()
	%EnvoyHeader.add_child(envoy_portrait)
	%EnvoyHeader.move_child(envoy_portrait, 0)
	%DecisionToggle.icon = icon("message")
	%DecisionToggle.pressed.connect(func(): set_decision_expanded(not decision_expanded))
	%DecisionFold.icon = icon("minimize")
	%DecisionFold.pressed.connect(func(): set_decision_expanded(false))
	# Above the city's HUD, below subsequently opened character/settings panels. The shade consumes city clicks.
	move_child(%LayersPanel, get_child_count()-1)
	move_child(%DecisionShade, get_child_count()-1)
	move_child(events_box, get_child_count()-1)
	%TrayClose.icon = icon("close")
	%TrayClose.pressed.connect(close_build_tray)
	%InspectorClose.icon = icon("close")
	%InspectorClose.pressed.connect(func(): inspector_closed.emit())
	%BuildSearch.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			close_build_tray()
			get_viewport().set_input_as_handled())
	%BuildSearch.text_changed.connect(func(_text): populate_build_cards())
	%CitizensIcon.texture = toolbar_icon("population")
	%TreasuryIcon.texture = toolbar_icon("treasury")
	%MessageClose.icon = icon("close")
	%MessageClose.text = ""
	undo_button.icon = toolbar_icon("undo")
	build_menu.icon = toolbar_icon("build")
	overlay_menu.icon = toolbar_icon("layers")
	overlay_menu.pressed.connect(func(): set_layers_open(overlay_menu.button_pressed))
	%LayersClose.icon = icon("close")
	%LayersClose.pressed.connect(func(): set_layers_open(false))
	for button in [%MapToggle, undo_button, build_menu, overlay_menu, %Jobs]: _wire_toolbar_help(button)
	get_viewport().gui_focus_changed.connect(func(_control): _toolbar_context())
	messages_button.icon = toolbar_icon("notice_journal")
	%ResourceGrid.minimum_size_changed.connect(func():_layout_panels.call_deferred())
	resized.connect(_layout_panels)
	pause_button.pressed.connect(func(): pause_pressed.emit())
	build_top_bar()
	undo_button.pressed.connect(func(): undo_pressed.emit())
	overlay_catalog.get_popup().index_pressed.connect(func(index):
		var id = overlay_catalog.get_popup().get_item_metadata(index)
		if id is String:
			_choose_overlay(id))
	menu_dialog.confirmed.connect(func(): main_menu_confirmed.emit())
	goals_toggle.pressed.connect(func():
		set_goals_expanded(not goals_list.visible))
	%GoalsHeader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	demolition_dialog.confirmed.connect(func(): demolition_confirmed.emit())
	demolition_dialog.canceled.connect(func(): demolition_canceled.emit())
	demolition_spare = demolition_dialog.add_button("", true, "spare")
	demolition_spare.visible = false
	demolition_dialog.custom_action.connect(func(action: StringName):
		if action == &"spare":
			demolition_dialog.hide()
			demolition_spared.emit())
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
	retranslate()

# Only dock utility titles carry shortcuts; category artwork keeps its existing hover names.
func shortcut_title(title: String, action: String) -> String:
	if action.is_empty(): return title
	var keys := KeyBindings.label(action)
	if action == "demolish": keys += " / " + KeyBindings.text(KEY_DELETE)
	return "%s [%s]" % [title,keys]

func activate_dock_action(action: String) -> void:
	if action == "layers":
		set_layers_open(not %LayersPanel.visible)
		return
	var button: Button = %Jobs if action == "jobs" else tool_buttons.get({"build_house":"house","build_road":"road","build_roadblock":"roadblock"}.get(action,""))
	if button != null and button.visible and not button.disabled: button.pressed.emit()

# Builds the quick tool row. `entries` are [tool, English label].
func set_tools(entries: Array) -> void:
	tool_entries = entries
	var group := ButtonGroup.new()
	for entry in entries:
		var button := ToolbarButton.new()
		button.icon = toolbar_icon(TOOL_ART.get(entry[0], "build"))
		button.tooltip_text = shortcut_title(tr(entry[1]), TOOL_KEYS.get(entry[0],""))
		button.help_detail = tr(TOOL_HELP.get(entry[0], ""))
		button.theme_type_variation = "ToolbarTool"
		button.custom_minimum_size = Vector2(36, 32)
		button.focus_mode = Control.FOCUS_ALL
		button.visible = entry[0] != "select" # Normal city inspection remains the default and Escape destination.
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(func():
			set_layers_open(false)
			close_build_tray()
			tool_selected.emit(entry[0]))
		tool_row.add_child(button)
		_wire_toolbar_help(button)
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
	for tool in ["house", "road", "roadblock"]:
		if tool_buttons.has(tool): tool_buttons[tool].disabled = not build_entries.has(tool)
	populate_build_menu()
	populate_categories()
	if %BuildTray.visible:
		populate_build_cards()
	select_tool(current_tool, false)

func populate_build_menu() -> void:
	var menu := build_menu.get_popup()
	for child in menu.get_children():
		if child is PopupMenu:
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
		submenu.id_pressed.connect(func(index): _release_toolbar_focus(); tool_selected.emit(names[index]))
		menu.add_child(submenu)
		menu.add_submenu_node_item(tr(group.title), submenu)
	_attach_right_click_back(menu)

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
	build_menu.text = tr("Build")
	build_menu.tooltip_text = tr("Build")
	if build_entries.has(value):
		build_menu.tooltip_text = item_name(build_entries[value])
	for name in building_cards:
		building_cards[name].button_pressed = name == value
	if close_tray and value in ["select", "demolish"]:
		close_build_tray()
	show_selected_context()
	_toolbar_context()

var status_date: Array = [1, 1, -1]

func set_status(date: Array, money: int, population: int) -> void:
	status_date = date
	var year := int(date[2])
	var era := tr("%d %s %d BC") if year < 0 else tr("%d %s %d AD")
	var month := clampi(int(date[1]) - 1, 0, 11)
	date_label.text = era % [int(date[0]), tr(MONTHS[month]), absi(year)]
	%MonthProgress.value = clampf((int(date[0]) - 1.0) / MONTH_DAYS[month], 0.0, 1.0)
	treasury_label.text = ("−" if money < 0 else "") + group_digits(absi(money))
	treasury_label.add_theme_color_override("font_color", INCOME_DOWN if money < 0 else Color(.97,.94,.86))
	treasury_label.tooltip_text = tr("Treasury: %s drachmas") % treasury_label.text
	population_label.text = group_digits(population)

# ---- top bar ----------------------------------------------------------------------------------------------
func well_style(fill: Color, rim: Color, radius := 7, margin_x := 8, margin_y := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = rim
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.anti_aliasing = true
	return style

func style_gauge(gauge: ProgressBar, fill: Color) -> void:
	gauge.add_theme_stylebox_override("background", well_style(Color(.075, .09, .097, .9), Color(.79, .66, .41, .35), 2, 0, 0))
	var bar := well_style(fill, Color(.97, .87, .64, .55), 2, 0, 0)
	gauge.add_theme_stylebox_override("fill", bar)

# The time bar, native gauges and popularity face; header artwork uses static toolbar-style SVGs.
func build_top_bar() -> void:
	style_gauge(%MonthProgress, GAUGE_FILL)
	style_gauge(%HousingGauge, GAUGE_FILL)
	%HousingIcon.texture = toolbar_icon("homes")
	var group := ButtonGroup.new()
	for index in SPEEDS.size():
		var button := ToolbarButton.new()
		button.name = "Speed%d" % (index + 1)
		button.text = str(index + 1)
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_ALL
		button.theme_type_variation = "HeaderSpeed"
		button.custom_minimum_size = Vector2(28, 26)
		button.pressed.connect(func(): speed_selected.emit(index))
		speed_row.add_child(button)
		speed_buttons.append(button)
	mood = MoodFace.new()
	mood.name = "Mood"
	mood.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	%PopulationRow.add_child(mood)

# The native popularity as its verdict word (the SDL City window's words).
func popularity_word(value: int) -> String:
	for entry in POPULARITY_WORDS:
		if value > entry[0]: return tr(entry[1])
	return tr("Popularity is terrible")

# This year's money from taxes, trade and tribute less the running costs (wages, imports, gifts and bribes), construction
# left out as it is the player's choice; the monthly figure is the average of the last twelve months (this year's ledger
# plus the matching part of last year's), or this year's own average in a city's first year.
static func running_balance(year: Dictionary) -> int:
	return int(year.get("income", 0)) - (int(year.get("expenses", 0)) - int(year.get("construction", 0)))

static func monthly_balance(finances: Dictionary, date: Array) -> int:
	var this_year: Dictionary = finances.get("this_year", {})
	var last_year: Dictionary = finances.get("last_year", {})
	var month := clampi(int(date[1]) - 1, 0, 11) if date.size() > 1 else 0
	var elapsed := month + clampf((int(date[0]) - 1.0) / MONTH_DAYS[month], 0.0, 1.0) if date.size() > 1 else 1.0
	var now := running_balance(this_year)
	if int(last_year.get("income", 0)) == 0 and int(last_year.get("expenses", 0)) == 0:
		return roundi(now / maxf(elapsed, 1.0))
	return roundi((now + running_balance(last_year) * (12.0 - elapsed) / 12.0) / 12.0)

func set_top_bar(value: Dictionary, date: Array) -> void:
	var housing: Dictionary = value.get("housing", {})
	var people := int(housing.get("people", 0))
	var free := int(housing.get("vacancies", 0))
	var total := people + free
	%HousingGauge.value = float(people) / total if total > 0 else 0.0
	%HousingText.text = tr("%s free / %s") % [group_digits(free), group_digits(total)]
	var full := total > 0 and free == 0
	(%HousingGauge.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = GAUGE_FULL if full else GAUGE_FILL
	%Housing.tooltip_text = tr("Housing: %s free of %s places") % [group_digits(free), group_digits(total)] + "\n" + tr("Residents: %s") % group_digits(people) + "\n" + tr("The bar shows occupied housing.") + ("\n" + tr("No room left: new settlers cannot move in") if full else "")
	%HousingGauge.tooltip_text = %Housing.tooltip_text
	var finances: Dictionary = value.get("finances", {})
	var monthly := monthly_balance(finances, date)
	%Income.text = ("+" if monthly >= 0 else "−") + group_digits(absi(monthly))
	%Income.add_theme_color_override("font_color", INCOME_UP if monthly >= 0 else INCOME_DOWN)
	var this_year: Dictionary = finances.get("this_year", {})
	%Money.tooltip_text = treasury_label.tooltip_text + "\n" + tr("Monthly balance: %s (taxes, trade and tribute less wages and imports, over the last twelve months; construction not counted)") % %Income.text + "\n" + tr("This year: income %s, running costs %s, construction %s") % [group_digits(int(this_year.get("income", 0))), group_digits(int(this_year.get("expenses", 0)) - int(this_year.get("construction", 0))), group_digits(int(this_year.get("construction", 0)))]
	var popularity := int(value.get("popularity", -1))
	mood.visible = popularity >= 0
	if popularity >= 0:
		mood.set_popularity(popularity)
		mood.tooltip_text = tr("%s (%d of 100)") % [popularity_word(popularity), popularity]
	%Citizens.tooltip_text = tr("Population") + ((" · " + mood.tooltip_text) if popularity >= 0 else "")

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
	%Jobs.tooltip_text = shortcut_title(tr("Jobs"), "jobs") + "\n" + tr("Employed: %d / %d\nOpen jobs: %d\nUnemployed: %d") % [int(jobs.get("employed",0)),int(jobs.get("employable",0)),int(jobs.get("vacancies",0)),int(jobs.get("unemployed",0))]
	%Jobs.disabled = jobs.is_empty()
	set_top_bar(value, status_date)

func set_paused(value: bool) -> void:
	paused = value
	pause_button.text = ""
	pause_button.icon = icon("play" if paused else "pause")
	pause_button.tooltip_text = (tr("Resume") if paused else tr("Pause")) + " [%s]" % KeyBindings.label("pause")
	pause_button.help_detail = tr("Stop or resume city time. Required decisions still wait for your reply.")
	pause_button.button_pressed = paused

func set_speed(index: int) -> void:
	for button_index in speed_buttons.size():
		speed_buttons[button_index].set_pressed_no_signal(button_index == index)

func set_undo_available(available: bool) -> void:
	undo_button.disabled = not available
	undo_button.help_detail = tr("Undo the most recent construction.") if available else tr("There is no recent construction to undo.")

# ---- overlays ----------------------------------------------------------------------------------------------
func overlay_text(id: String) -> String:
	var label: String = tr(Overlays.MODES[id][0])
	var binding := "overlay_" + id if id != "normal" else "overlay_normal"
	return label if KeyBindings.definition(binding).is_empty() else "%s   [%s]" % [label, KeyBindings.label(binding)]

# One entry per overlay; Culture and Science are submenus. Rebuilt when the language changes.
func populate_overlay_menu() -> void:
	var menu := overlay_catalog.get_popup()
	for child in menu.get_children():
		if child is PopupMenu:
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
			submenu.index_pressed.connect(func(index): _choose_overlay(submenu.get_item_metadata(index)))
			menu.add_child(submenu)
			menu.add_submenu_node_item(tr(entry[0]), submenu)
	_attach_right_click_back(menu)
	for child in %LayerChoices.get_children(): child.free()
	layer_buttons.clear()
	for id in Overlays.MODES:
		if welfare_buttons.has(id): continue
		var button := ToolbarButton.new()
		button.theme_type_variation = "ToolbarTool"
		button.custom_minimum_size = Vector2(180, 34)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = tr(Overlays.MODES[id][0])
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = overlay_text(id)
		button.help_detail = tr(Overlays.MODES[id][1])
		button.toggle_mode = true
		button.pressed.connect(func(): _choose_overlay(id))
		%LayerChoices.add_child(button)
		_wire_toolbar_help(button)
		layer_buttons[id] = button
	set_overlay(current_overlay)

func set_layers_open(open: bool) -> void:
	var was_open: bool = %LayersPanel.visible
	if open:
		close_build_tray()
		set_goals_expanded(false)
		# Army and other inspectors are added after this HUD becomes ready. Bring
		# Layers above them for drawing and picking, retaining required decisions above it.
		move_child(%LayersPanel, get_child_count()-1)
		move_child(%DecisionShade, get_child_count()-1)
		move_child(events_box, get_child_count()-1)
	%LayersPanel.visible = open
	overlay_menu.set_pressed_no_signal(open)
	if not open and was_open: _release_toolbar_focus()
	_layout_panels()

func _choose_overlay(id: String) -> void:
	_release_header_focus()
	set_layers_open(false)
	_release_toolbar_focus()
	overlay_selected.emit(id)

func set_overlay(id: String) -> void:
	current_overlay = id
	for view in layer_buttons: layer_buttons[view].set_pressed_no_signal(view == id)
	for view in welfare_buttons:
		welfare_buttons[view].button_pressed = view == id
	overlay_menu.text = tr("Overlays")
	overlay_menu.tooltip_text = shortcut_title(tr("Overlays") if id == "normal" else tr(Overlays.MODES[id][0]), "layers")
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
	if entry[0] == overlay_catalog.get_popup():
		entry[0].index_pressed.emit(entry[1])
		return true
	entry[0].index_pressed.emit(entry[1])
	return true

# The episode's objectives (from the core's `episode` query): a checked or open line each, with live status. Hidden
# when the game has none (open play). Lines are rebuilt only when their text changes.
var goals_signature := ""
var goals_state: Dictionary = {}
var unseen_goals := 0

func set_goals(episode: Dictionary) -> void:
	var goals: Array = episode.get("goals", [])
	var met := int(episode.get("met", 0))
	var celebrate := not goals_state.is_empty() and met > int(goals_state.get("met", 0))
	if met < int(goals_state.get("met",0)): unseen_goals = 0
	if celebrate:
		if not goals_list.visible:
			unseen_goals += met-int(goals_state.get("met",0))
			%ObjectivesButton.highlight()
	goals_state = episode
	%ObjectivesButton.visible = not goals.is_empty()
	%ObjectivesButton.set_badge(str(unseen_goals) if unseen_goals > 0 else "")
	%ObjectivesButton.tooltip_text = tr("Objectives") + "\n" + tr("%d of %d achieved") % [met,int(episode.get("total",0))]
	%ObjectivesButton.help_detail = tr("Open your adventure goals and set aside required goods.")
	goals_panel.visible = goals_list.visible and not goals.is_empty() and not message_panel.visible
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
	%ObjectivesButton.set_progress(share)
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
	for spec in [["TimeCaption","Date"],["SpeedCaption","Speed"],["CityCaption","Current city"],["HousingCaption","Housing"],["TreasuryCaption","Treasury"],["MonthlyCaption","Monthly balance"],["PopulationCaption","Population"]]:
		(get_node("%"+spec[0]) as Label).text = tr(spec[1])
	%Jobs.help_detail = tr("Review staffing and open jobs in the industry view.")
	%WelfareCaption.text = tr("City views")
	%LayerTitle.text = tr("Overlays")
	%LayersClose.tooltip_text = tr("Close")
	%LayersClose.help_detail = tr("Close")
	%ResourcesToggle.help_detail = tr("Current city stocks. Select a good to inspect its supply view.")
	for button in resource_buttons.values(): button.help_detail = tr("Select a good to inspect its city supply view.")
	goals_signature = ""
	if not goals_state.is_empty():
		set_goals(goals_state)
	%MapPeek.text = tr("City map")
	%MapPeek.tooltip_text = tr("Show city map")
	%MapClose.tooltip_text = tr("Hide city map")
	%MapToggle.tooltip_text = tr("Show or hide the map")
	%MapToggle.help_detail = tr("Show or hide the map")
	build_menu.help_detail = tr("Browse every building available to this city.")
	overlay_menu.help_detail = tr("See services, supplies and conditions across your city.")
	set_undo_available(not undo_button.disabled)
	%BuildSearch.placeholder_text = tr("Search buildings…")
	%ResourcesToggle.tooltip_text = tr("Hide resources") if resources_open else tr("Show resources")
	%ResourcesToggle.text = tr("Resources") + (" ▴" if resources_open else " ▾")
	%RotateLeft.tooltip_text = tr("Turn left")
	%RotateRight.tooltip_text = tr("Turn right") + " (%s)" % KeyBindings.label("turn_placement")
	%WallFill.text = tr("Fill wall rectangle")
	%TrayClose.tooltip_text = tr("Close")
	%InspectorClose.tooltip_text = tr("Close")
	%MessageClose.tooltip_text = tr("Close")
	_decision_caption()
	%EnvoyPause.text = decision_pause_hint()
	%DecisionFold.tooltip_text = tr("Fold decision") + "\n" + tr("Paused · Awaiting your reply")
	%EmptySearch.text = tr("No matching buildings")
	goals_toggle.tooltip_text = tr("Close")
	goals_toggle.text = ""
	goals_toggle.icon = icon("close")
	set_unread(unread)
	for button in journal_filters.values(): button.text = tr(button.get_meta("title"))
	menu_dialog.title = tr("Main menu")
	menu_dialog.dialog_text = tr("Return to the main menu? Progress since your last save is lost.")
	menu_dialog.ok_button_text = tr("Main menu")
	menu_dialog.cancel_button_text = tr("Stay")

	set_paused(paused)
	for index in speed_buttons.size():
		speed_buttons[index].tooltip_text = tr(SPEEDS[index])
		speed_buttons[index].help_detail = tr("Choose the pace of city time. This does not resume a paused city.")
	for key in tool_buttons:
		for entry in tool_entries:
			if entry[0] == key:
				tool_buttons[key].tooltip_text = shortcut_title(tr(entry[1]), TOOL_KEYS.get(key,""))
				tool_buttons[key].help_detail = tr(TOOL_HELP.get(key, ""))
	populate_build_menu()
	populate_categories()
	if %BuildTray.visible:
		populate_build_cards()
	select_tool(current_tool, false)
	undo_button.text = ""
	undo_button.tooltip_text = shortcut_title(tr("Undo last construction"), "undo")
	%MonthProgress.tooltip_text = tr("Date") + " · " + tr("the bar fills as the month passes")
	population_label.tooltip_text = tr("Population")
	%ActiveToolClose.tooltip_text=tr("Close")
	for view in welfare_buttons:
		welfare_buttons[view].tooltip_text = overlay_text(view)
		welfare_buttons[view].help_detail = tr("Inspect this service across the city.")
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
	demolition_dialog.title = tr("Demolish these landmarks?") if demolition_area else tr("Demolish this landmark?")
	demolition_spare.text = tr("Spare landmarks")
	demolition_dialog.get_ok_button().text = tr("Demolish")
	demolition_dialog.get_cancel_button().text = tr("Keep")

# The demolition dialog is for one landmark (single click) or for the landmarks in a dragged area, which can be spared.
func set_demolition_area(area: bool) -> void:
	demolition_area = area
	demolition_spare.visible = area
	demolition_dialog.title = tr("Demolish these landmarks?") if area else tr("Demolish this landmark?")

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
	if open:
		set_layers_open(false)
		set_goals_expanded(false)
	message_panel.visible = open
	messages_button.set_pressed_no_signal(open)
	_layout_panels()
	messages_toggled.emit(open)

func set_unread(count: int) -> void:
	unread = count
	messages_button.text = ""
	messages_button.set_badge(str(count) if count > 0 else "")
	messages_button.tooltip_text = tr("City journal") + ("\n" + tr("Inbox (%d)") % count if count > 0 else "")
	messages_button.help_detail = tr("Read the full history of city reports, warnings and decisions.")

# History uses the same disclosure as news chips; it retains the complete native wording.
func set_messages(entries: Array) -> void:
	journal_entries = entries
	entries = entries.filter(func(entry):
		return journal_filter == "all" or (bool(entry.get("decision",false)) if journal_filter == "decisions" else NotificationPolicy.is_warning(entry)))
	var cards := {}
	for child in message_list.get_children():
		if child is NoticeChip: cards[child.message_id] = child
		else: child.free()
	if entries.is_empty():
		for card in cards.values(): card.free()
		var empty := Label.new()
		empty.theme_type_variation = "Detail"
		empty.text = tr("No messages yet") if journal_entries.is_empty() else tr("No reports in this view")
		message_list.add_child(empty)
		_layout_panels.call_deferred()
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
			card.notice_icon = toolbar_icon("notice_"+HazardRail.GROUP.get(str(entry.get("kind","")),"journal"))
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
func show_toast(id: int, title_text: String, body_text: String, kind := "") -> void:
	if toasts.get_children().any(func(card): return card.message_id == id) or alert_queue.any(func(entry): return entry.id == id): return
	if toasts.get_child_count() >= MAX_TOASTS:
		alert_queue.append({"id": id, "title": title_text, "text": body_text, "kind":kind})
		return
	var card := NoticeChip.new()
	# Shown in full at the top centre; the reading time grows with the text (about 25 letters a second, up to 24 s).
	card.open = true
	card.notice_icon = toolbar_icon("notice_"+HazardRail.GROUP.get(kind,"journal"))
	card.configure(id, title_text, body_text, clampf(TOAST_SECONDS + body_text.length() / 25.0, TOAST_SECONDS, 24.0))
	card.dismiss_requested.connect(func(_id): _close_toast(card))
	card.expansion_requested.connect(func(chip): _expand_notice(chip, toasts))
	toasts.add_child(card)

func _expand_notice(chip: Control, collection: Node) -> void:
	for other in collection.get_children():
		if other != chip and other.get("expanded") == true: other.set_expanded(false)

# Adopt the new open default without writing settings on launch. Later explicit folds remain remembered.
static func preferred_minimap_open() -> bool:
	if UserSettings.get_value("interface", "minimap_visibility_version", 0) != MINIMAP_PREFERENCE_VERSION:
		return true
	var preference: Variant = UserSettings.get_value("interface", "minimap_visible", true)
	return preference if preference is bool else true

func set_minimap_open(open: bool, persist := false) -> void:
	set_layers_open(false)
	%MapToggle.set_pressed_no_signal(open)
	if open:
		if decision_expanded: set_decision_expanded(false)
		close_build_tray()
		if message_panel.visible: set_messages_open(false)
	if persist and (not automation or Engine.has_meta("ezeus_settings_path")):
		UserSettings.set_value("interface", "minimap_visible", open)
		UserSettings.set_value("interface", "minimap_visibility_version", MINIMAP_PREFERENCE_VERSION)
	_layout_panels()

# Collapsing the presentation never answers, dismisses, or resumes a native decision.
func set_decision(decision: Dictionary, pending_count := 0) -> void:
	var next_id := int(decision.get("id", -1))
	if next_id != decision_id:
		decision_expanded = next_id >= 0
		%EventScroll.scroll_vertical = 0
	decision_id = next_id
	decision_count = pending_count
	decision_postponable = decision_can_postpone(decision)
	%EnvoyPause.text = decision_pause_hint()
	%EnvoyCity.text = str(decision.get("sender_name", ""))
	%EnvoyLeader.text = str(decision.get("sender_leader", ""))
	%EnvoyLeader.visible = not %EnvoyLeader.text.is_empty()
	envoy_portrait.set_sender(int(decision.get("sender_index", -1)), str(decision.get("sender_name", "")), str(decision.get("sender_leader", "")))
	if decision_expanded: set_goals_expanded(false)
	events_box.visible = not decision.is_empty() and decision_expanded
	var title_text:=str(decision.get("title",""))
	%DecisionToggle.text=title_text.substr(0,1).to_upper()+title_text.substr(1)
	%DecisionToggle.tooltip_text = tr("Fold decision") if decision_expanded else tr("Review decision") + "\n" + %DecisionToggle.text
	_decision_caption()
	_decision_visibility()
	events_box.reset_size()

func _decision_caption() -> void:
	%DecisionCaption.text = tr("Awaiting your decision") if decision_count <= 1 else tr("Awaiting your decision · %d pending") % decision_count

func set_decision_expanded(expanded: bool) -> void:
	decision_expanded = expanded and decision_id >= 0
	if decision_expanded: set_goals_expanded(false)
	_decision_visibility()
	%DecisionToggle.tooltip_text = tr("Fold decision") if decision_expanded else tr("Review decision") + "\n" + %DecisionToggle.text
	events_box.reset_size()
	_layout_panels()

func _decision_visibility() -> void:
	var opened: bool = decision_expanded and not %DecisionShade.visible
	%DecisionShade.visible = decision_expanded
	events_box.visible = decision_id >= 0 and decision_expanded
	%DecisionReview.visible = decision_id >= 0
	%DecisionReview.set_badge(str(maxi(decision_count,1)))
	%DecisionReview.tooltip_text = tr("Awaiting your decision") + "\n" + %DecisionToggle.text
	%DecisionReview.help_detail = tr("Right-click to postpone") if decision_postponable else tr("Paused · Awaiting your reply")
	%EnvoyContent.visible = decision_expanded
	%DecisionFooter.visible = decision_expanded
	%DecisionFold.visible = decision_expanded
	%EventScroll.visible = decision_expanded
	%DecisionToggle.theme_type_variation = "EnvoyTitleButton" if decision_expanded else "DecisionButton"
	%DecisionToggle.icon = null if decision_expanded else icon("message")
	events_box.theme_type_variation = "DecisionCard" if decision_expanded else "DecisionReminder"
	decision_visibility_changed.emit(decision_expanded)
	if opened:
		set_layers_open(false)
		%EventScroll.grab_focus()
	elif not decision_expanded:
		var focused := get_viewport().gui_get_focus_owner()
		if focused != null and events_box.is_ancestor_of(focused): focused.release_focus()
	_update_decision_focus.call_deferred()

func _update_decision_focus() -> void:
	# Tab stays inside this modal; opening a request never focuses a native answer.
	if not decision_expanded: return
	var controls: Array = [%EventScroll, %DecisionToggle, %DecisionFold]
	controls.append_array(%EventActions.get_children())
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i+1)%controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i-1,controls.size())])

# Native callback numbers carry meaning independently of the translated labels. Invasions have their own choices.
# A destination selector remains a group of equal choices; it must not imply a preferred recipient.
func decision_actions(decision: Dictionary) -> Array:
	var actions: Array = decision.get("actions", []).duplicate(true)
	var invasion: bool = str(decision.get("kind", "")) == "invasion"
	actions.sort_custom(func(a, b): return _decision_rank(int(a.choice), invasion) < _decision_rank(int(b.choice), invasion))
	return actions

func decision_can_postpone(decision: Dictionary) -> bool:
	return str(decision.get("kind", "")) != "invasion" and decision.get("actions", []).any(func(action): return int(action.choice) == 1)

func decision_pause_hint() -> String:
	return tr("Paused · Awaiting your reply") + (" · " + tr("Right-click to postpone") if decision_postponable else "")

func _decision_rank(choice: int, invasion: bool) -> int:
	if choice >= 1000: return 10 + choice
	if invasion: return choice # Surrender, bribe, defend (the native invasion callbacks).
	return {2:0, 1:1, 0:2, -2:2, -1:2}.get(choice, 3)

func decision_action_style(decision: Dictionary, choice: int) -> String:
	if str(decision.get("kind", "")) == "invasion": return "EnvoyPrimary" if choice == 2 else "EnvoyAction"
	if choice in [0, -2, -1]: return "EnvoyPrimary"
	if choice >= 1000 and decision.get("actions", []).filter(func(a): return int(a.choice)>=1000).size()==1: return "EnvoyPrimary"
	return "EnvoyAction"

func _close_toast(card: Node) -> void:
	if not is_instance_valid(card) or card.is_queued_for_deletion():
		return
	card.get_parent().remove_child(card)
	message_dismissed.emit(int(card.get_meta("id")))
	card.queue_free()
	if not alert_queue.is_empty():
		var next: Dictionary = alert_queue.pop_front()
		show_toast(int(next.id), str(next.title), str(next.text),str(next.get("kind","")))

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

func toolbar_icon(name: String) -> Texture2D:
	var key := "toolbar/"+name
	if not icon_cache.has(key): icon_cache[key] = load("res://ui/toolbar_icons/%s.svg" % name)
	return icon_cache[key]

func unavailable_toolbar_icon(name: String) -> Texture2D:
	var key := "toolbar/unavailable/" + name
	if not icon_cache.has(key):
		var image := toolbar_icon(name).get_image()
		image.adjust_bcs(1.0, 1.0, 0.0)
		icon_cache[key] = ImageTexture.create_from_image(image)
	return icon_cache[key]

func _wire_toolbar_help(button: BaseButton) -> void:
	button.mouse_entered.connect(func(): toolbar_hovered = button; _toolbar_context())
	button.mouse_exited.connect(func():
		if toolbar_hovered == button: toolbar_hovered = null
		_toolbar_context())
	button.focus_entered.connect(_toolbar_context)
	button.focus_exited.connect(_toolbar_context.call_deferred)

func toolbar_has_focus() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	if %LayersPanel.visible: return true
	if focused != null and (%BottomBar.is_ancestor_of(focused) or focused == %MapToggle): return true
	return _toolbar_popup(build_menu.get_popup()) or _toolbar_popup(overlay_catalog.get_popup())

func _release_toolbar_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and (%BottomBar.is_ancestor_of(focused) or %LayersPanel.is_ancestor_of(focused) or focused == %MapToggle): focused.release_focus()

func _release_header_focus() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and (%StatusBar.is_ancestor_of(focus) or %TimeBar.is_ancestor_of(focus) or %EventRail.is_ancestor_of(focus) or goals_panel.is_ancestor_of(focus)): focus.release_focus()

func _header_has_focus() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and (%StatusBar.is_ancestor_of(focus) or %TimeBar.is_ancestor_of(focus) or %EventRail.is_ancestor_of(focus) or goals_panel.is_ancestor_of(focus))

func _toolbar_popup(node: Node) -> bool:
	if node is PopupMenu and node.visible: return true
	for child in node.get_children():
		if _toolbar_popup(child): return true
	return false

func _toolbar_context() -> void:
	if not is_node_ready(): return
	var focused := get_viewport().gui_get_focus_owner()
	var button: BaseButton = toolbar_hovered if is_instance_valid(toolbar_hovered) and toolbar_hovered.is_visible_in_tree() else null
	if focused is BaseButton and (%BottomBar.is_ancestor_of(focused) or %LayersPanel.is_ancestor_of(focused)): button = focused
	if button != null:
		%ToolbarContext.text = button.tooltip_text.get_slice("\n",0)
	elif %BuildTray.visible:
		%ToolbarContext.text = tr(active_category)
	elif build_entries.has(current_tool):
		%ToolbarContext.text = item_name(build_entries[current_tool])
	else: %ToolbarContext.text = tr("Construction")
	%ToolbarContext.visible = not decision_expanded and not get_tree().root.get_node("UiAccess").dialog_open

func _measure_toolbar_context() -> void:
	var font: Font = %ToolbarContext.get_theme_font("font")
	var font_size: int = %ToolbarContext.get_theme_font_size("font_size")
	toolbar_context_width = font.get_string_size(tr("Construction"),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	for title in category_buttons:
		toolbar_context_width = maxf(toolbar_context_width,font.get_string_size(tr(title),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	toolbar_context_width = ceilf(toolbar_context_width)+24

func populate_categories() -> void:
	for child in %Categories.get_children():
		child.free()
	category_buttons.clear()
	# Stable positions across maps/chapters; native groups still contain only buildable entries.
	var titles: Array = BuildCatalog.CATEGORIES.map(func(category): return category[0])
	for group in build_groups:
		if not titles.has(group.title): titles.append(group.title)
	for title in titles:
		var available := build_groups.any(func(group): return group.title == title and not group.items.is_empty())
		var art: Array = CATEGORY_ART.get(title, CATEGORY_ART.Other)
		var button := ToolbarButton.new()
		button.theme_type_variation = "Category_" + str(art[0])
		button.custom_minimum_size = Vector2(44, 44)
		button.icon = toolbar_icon(art[0]) if available else unavailable_toolbar_icon(art[0])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.text = ""
		button.tooltip_text = tr(title)
		button.help_detail = tr(CATEGORY_HELP.get(title, CATEGORY_HELP.Other)) if available else tr("Unavailable") + "\n" + tr("No buildings in this category are currently available.")
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.disabled = not available
		button.add_theme_color_override("icon_disabled_color", Color(.75,.75,.75,.85))
		button.button_pressed = available and %BuildTray.visible and active_category == title
		button.pressed.connect(func(): open_category(title))
		%Categories.add_child(button)
		_wire_toolbar_help(button)
		category_buttons[title] = button
	_measure_toolbar_context()
	if not active_category.is_empty() and (not category_buttons.has(active_category) or category_buttons[active_category].disabled):
		close_build_tray()

func open_category(title: String) -> void:
	if not category_buttons.has(title) or category_buttons[title].disabled: return
	set_layers_open(false)
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
	_toolbar_context()
	_layout_panels()

func close_build_tray() -> void:
	%BuildTray.hide()
	%BuildSearch.release_focus()
	_release_toolbar_focus()
	for button in category_buttons.values():
		button.button_pressed = false
	_toolbar_context()
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
			button.tooltip_text = building_text(item) + " · " + building_dimensions(item)
			button.pressed.connect(func():
				%BuildSearch.release_focus()
				_release_toolbar_focus()
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
			preview.texture = preview_fallback(item, group.title)
			column.add_child(preview)
			var preview_key := ThumbnailService.key(item)
			if not card_previews.has(preview_key): card_previews[preview_key] = []
			card_previews[preview_key].append(preview)
			if thumbnails != null:
				var cached: Texture2D = thumbnails.request(item)
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
		%ActiveToolPrice.text=building_dimensions(item)
	if item.is_empty():
		for group in build_groups:
			if group.title==active_category and not group.items.is_empty():
				show_context(group.items[0],group.title);return
	for group in build_groups:
		if group.items.any(func(entry):return entry.name==current_tool):
			show_context(item,group.title);return

func preview_fallback(item: Dictionary, category: String) -> Texture2D:
	# Terrain tools have no standalone building mesh; identify them as roads rather
	# than accidentally showing the category's housing/shop glyph.
	return toolbar_icon("road" if item.asset == "road" else CATEGORY_ART.get(category, CATEGORY_ART.Other)[0])

func building_dimensions(item: Dictionary) -> String:
	if item.get("name","") in ["avenue","boulevard"]:
		return tr("Street width: %d tiles") % [3 if item.name=="boulevard" else 2]
	return tr("%d × %d tiles") % [int(item.get("w",1)),int(item.get("h",1))]

func show_context(item: Dictionary, category: String) -> void:
	if item.is_empty():return
	context_item=item
	%ContextCategory.text=tr(category).to_upper()
	%ContextTitle.text=item_name(item)
	%ContextTitle.tooltip_text=item_name(item)
	%ContextFacts.text=building_dimensions(item)
	%ContextPreview.texture=preview_fallback(item, category)
	if thumbnails!=null:
		var cached: Texture2D=thumbnails.request(item)
		if cached!=null:%ContextPreview.texture=cached
	var selected: bool=item.name==current_tool
	var tool: String=item.name.get_slice(":",0)
	%RotateRow.hide()
	%ContextHelp.hide()
	%RotateLeft.disabled=not selected; %RotateRight.disabled=not selected
	%Facing.text=tr("Facing: %d°")%[facing*90]
	# Wall filling remains available through Shift-drag, outside the building choices.
	%WallFill.hide()
	%WallFill.disabled=not selected
	if item.name=="road":%ContextHelp.text=tr("Click for one tile, or drag a road. The route follows the native grid.")
	elif item.name=="wall":%ContextHelp.text=tr("Drag a wall outline. Hold Shift to fill the whole rectangle.")
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

# Pages that list goods, stalls or needs need room for a table; the others keep the slim card.
var inspector_wide := false

func set_inspection_header(data: Dictionary) -> void:
	%InspectionSummary.show_data(data)
	var wide: bool = data.has("storage") or data.has("trade") or data.has("agora") or data.has("house")
	if wide != inspector_wide:
		inspector_wide = wide
		_layout_panels.call_deferred()
	inspector_text.visible=not data.has("footprint")
	%InspectorTitle.text = str(data.get("name", ""))
	if data.has("ruin") and not str(data.ruin.original_name).is_empty():
		%InspectorTitle.text = tr("Ruins of %s") % str(data.ruin.original_name)
	var footprint: Array = data.get("footprint", [])
	var context: Array[String] = []
	if footprint.size() >= 4: context.append(tr("%d × %d tiles") % [int(footprint[2]),int(footprint[3])])
	if int(data.get("max_employees",0)) > 0: context.append(tr("Workers: %d / %d") % [int(data.get("employees",0)),int(data.max_employees)])
	%InspectorSubtitle.text = " · ".join(context) if not context.is_empty() else tr("City: %s") % str(data.city)
	%InspectorSubtitle.tooltip_text = tr("City: %s") % str(data.city)
	%Workforce.visible = data.has("employees") and int(data.get("max_employees", 0)) > 0
	if %Workforce.visible:
		%Workforce.max_value = int(data.max_employees)
		%Workforce.value = int(data.employees)
		%Workforce.tooltip_text = tr("Workers: %d / %d") % [int(data.employees), int(data.max_employees)]

func set_goals_expanded(expanded: bool) -> void:
	expanded = expanded and not goals_state.get("goals",[]).is_empty()
	var was_open := goals_list.visible
	if expanded:
		set_layers_open(false)
		close_build_tray()
		if message_panel.visible: set_messages_open(false)
		unseen_goals = 0
		%ObjectivesButton.set_badge("")
	goals_list.visible = expanded
	%GoalsScroll.visible = expanded
	%ObjectivesButton.set_pressed_no_signal(expanded)
	goals_panel.visible = expanded
	if was_open != expanded: goals_toggled.emit(expanded)
	if not expanded:
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and goals_panel.is_ancestor_of(focus): focus.release_focus()
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
	%ResourcesToggle.text = tr("Resources") + (" ▴" if open else " ▾")
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

# Date and occupancy labels live over gauges, so the gauges must measure their text explicitly.
# Keep a content-sized city strip; wrap the stats only when the viewport cannot fit them.
func _layout_header() -> float:
	%MonthProgress.custom_minimum_size.x = maxf(150, date_label.get_minimum_size().x+16)
	%MonthProgress.custom_minimum_size.y = maxf(24, date_label.get_minimum_size().y+4)
	%HousingGauge.custom_minimum_size.x = maxf(128, %HousingText.get_minimum_size().x+14)
	%HousingGauge.custom_minimum_size.y = maxf(24, %HousingText.get_minimum_size().y+4)
	var city_font: Font = %CityName.get_theme_font("font")
	%CityName.custom_minimum_size.x = clampf(city_font.get_string_size(%CityName.text,HORIZONTAL_ALIGNMENT_LEFT,-1,%CityName.get_theme_font_size("font_size")).x,90,220)
	var frame_width: float = %ResourceRibbon.get_theme_stylebox("panel").get_minimum_size().x
	var wanted: float = %CityPlaque.get_combined_minimum_size().x + %StatsGroup.get_combined_minimum_size().x + 12
	var width: float = minf(size.x-32, wanted+frame_width)
	var room: float = width-frame_width
	var parent: Node = %ResourceLayout if wanted > room + .5 else %OverviewRow
	if %StatsGroup.get_parent() != parent:
		%StatsGroup.reparent(parent)
	%StatsGroup.size_flags_horizontal = Control.SIZE_EXPAND_FILL if parent == %ResourceLayout else Control.SIZE_FILL
	return width

func _layout_panels() -> void:
	if not is_node_ready():
		return
	var ribbon_width: float = _layout_header()
	var ribbon_left := 16.0
	# Stocks open beneath the compact strip; wrap instead of clipping or hiding goods.
	var available: float=maxf(100,ribbon_width-%ResourcesPanel.get_theme_stylebox("panel").get_minimum_size().x)
	var cell_width: float=56
	for button in resource_buttons.values():cell_width=maxf(cell_width,button.get_combined_minimum_size().x)
	var capacity: int=maxi(1,floori((available+3)/(cell_width+3)))
	var rows: int=ceili(float(HEADER_GOODS.size())/capacity)
	%ResourceGrid.columns=ceili(float(HEADER_GOODS.size())/rows)
	var ribbon_height: float=maxf(32,%ResourceRibbon.get_combined_minimum_size().y)
	%ResourceRibbon.offset_left=ribbon_left; %ResourceRibbon.offset_right=ribbon_left+ribbon_width
	%ResourceRibbon.offset_top=8; %ResourceRibbon.offset_bottom=8+ribbon_height
	var resource_height: float=%ResourcesPanel.get_combined_minimum_size().y
	%ResourcesPanel.offset_left=0; %ResourcesPanel.offset_right=ribbon_width
	%ResourcesPanel.offset_top=0; %ResourcesPanel.offset_bottom=resource_height
	%ResourcesReveal.offset_left=ribbon_left; %ResourcesReveal.offset_right=ribbon_left+ribbon_width
	%ResourcesReveal.offset_top=12+ribbon_height
	%ResourcesReveal.offset_bottom=%ResourcesReveal.offset_top+resource_height*resources_fraction
	%ResourcesReveal.visible=resources_fraction>0.001
	%ResourcesPanel.modulate.a=resources_fraction
	var secondary_top: float=16+ribbon_height+(resource_height+4)*resources_fraction
	var header_bottom: float=secondary_top
	%StatusBar.offset_bottom=header_bottom
	debug_panel.offset_top=header_bottom+10
	var content_top: float=header_bottom+12
	# The map and its time controls form a column at bottom left; construction stays at centre.
	var map_height:=maxf(192,%MinimapPanel.get_combined_minimum_size().y)
	var map_width:=maxf(192,%MinimapPanel.get_combined_minimum_size().x)
	goals_panel.visible = goals_list.visible and not goals_state.get("goals", []).is_empty() and not message_panel.visible and not decision_expanded
	# The objectives are a disclosure, so opening them never moves the dock.
	var corner_width: float=maxf(map_width,%TimeBar.get_combined_minimum_size().x)
	var dock_left: float=16+corner_width+12
	var dock_right: float=size.x-16
	# An ellipsized Label has almost no intrinsic minimum. Reserve its measured text
	# explicitly, even when a chapter exposes only a few building categories.
	var dock_padding: float = %BottomBar.get_theme_stylebox("panel").get_minimum_size().x+2
	var fixed_utilities: float = %ToolbarUtilities.get_combined_minimum_size().x-%ToolbarContext.get_combined_minimum_size().x
	%ToolbarContext.custom_minimum_size.x = minf(toolbar_context_width,maxf(0,dock_right-dock_left-dock_padding-fixed_utilities))
	var wanted_width: float=maxf(%ToolbarUtilities.get_combined_minimum_size().x,%Categories.get_combined_minimum_size().x)+%BottomBar.get_theme_stylebox("panel").get_minimum_size().x+2
	var dock_width: float=minf(wanted_width,dock_right-dock_left)
	var dock_centre: float=(dock_left+dock_right)*.5
	%BottomBar.offset_left=dock_centre-dock_width*.5-size.x*.5
	%BottomBar.offset_right=dock_centre+dock_width*.5-size.x*.5
	var dock_height: float=maxf(40,%BottomBar.get_combined_minimum_size().y)
	%BottomBar.offset_bottom=-12; %BottomBar.offset_top=-12-dock_height
	var footer_top: float=%BottomBar.position.y
	inspector.offset_top=content_top
	message_panel.offset_top=content_top
	events_box.offset_top=content_top
	inspector.offset_left=-16-minf(maxf(500.0 if inspector_wide else 340.0,inspector.get_combined_minimum_size().x),maxf(340.0,size.x*.48))
	var content_height: float = %InspectorColumn.get_combined_minimum_size().y + %InspectorContents.get_combined_minimum_size().y + 32
	var tray_height: float=%BuildTray.get_combined_minimum_size().y
	var tray_bottom: float=%BottomBar.position.y-size.y-5
	%BuildTray.offset_top=tray_bottom-tray_height
	%BuildTray.offset_bottom=tray_bottom
	var tray_width:=minf(980,size.x-32)
	%BuildTray.offset_left=-tray_width*.5; %BuildTray.offset_right=tray_width*.5
	%MinimapPanel.visible=%MapToggle.button_pressed and not %BuildTray.visible and not message_panel.visible and not decision_expanded
	%MapPeek.visible=false
	var time_height: float=%TimeBar.get_combined_minimum_size().y
	%TimeBar.position=Vector2(16,size.y-12-time_height)
	%TimeBar.size=Vector2(corner_width,time_height)
	var map_bottom: float=-12-time_height-6
	%MinimapPanel.anchor_left=0; %MinimapPanel.anchor_right=0
	%MinimapPanel.offset_left=16+(corner_width-map_width)*.5; %MinimapPanel.offset_right=%MinimapPanel.offset_left+map_width
	%MinimapPanel.offset_bottom=map_bottom; %MinimapPanel.offset_top=map_bottom-map_height
	var map_button_size: Vector2 = %MapToggle.get_combined_minimum_size()
	%MapToggle.visible = not %MinimapPanel.visible
	%MapToggle.position = Vector2(16,%TimeBar.position.y-map_button_size.y-6)
	%MapToggle.size = map_button_size
	var layers_width: float = minf(maxf(440,%WelfareGroup.get_combined_minimum_size().x+20),size.x-32)
	%LayersPanel.size.x = layers_width
	var layer_fixed_height: float = %LayersPanel.get_combined_minimum_size().y-%LayerScroll.get_combined_minimum_size().y
	%LayerScroll.custom_minimum_size.y = minf(%LayerChoices.get_combined_minimum_size().y,maxf(60,footer_top-header_bottom-layer_fixed_height-20))
	%LayersPanel.size.y = %LayersPanel.get_combined_minimum_size().y
	%LayersPanel.position = Vector2(clampf(%BottomBar.get_global_rect().end.x-layers_width,16,size.x-layers_width-16),footer_top-%LayersPanel.size.y-6)
	%EventRail.anchor_left=1; %EventRail.anchor_right=1
	%EventRail.offset_right=-16; %EventRail.offset_left=-16-%EventRail.get_combined_minimum_size().x
	# Stable utility positions; the stock drawer on the opposite side cannot move them.
	%EventRail.offset_top=8
	var alert_height: float = %AlertList.get_combined_minimum_size().y
	%AlertScroll.visible = %AlertList.get_children().any(func(button): return button.visible)
	%AlertScroll.custom_minimum_size.y = floorf(minf(alert_height,minf(240,size.y*.32)))
	%EventRail.offset_bottom=%EventRail.offset_top+%EventRail.get_combined_minimum_size().y
	var disclosure_right: float = %EventRail.position.x-8
	var disclosure_top: float = maxf(content_top,%ObjectivesButton.get_global_rect().end.y+8)
	message_panel.offset_right = disclosure_right-size.x
	message_panel.offset_top = disclosure_top
	goals_panel.offset_right = disclosure_right
	goals_panel.offset_left = disclosure_right-minf(maxf(380,goals_panel.get_combined_minimum_size().x),size.x-100)
	var goals_chrome: float = goals_panel.get_combined_minimum_size().y-%GoalsScroll.get_combined_minimum_size().y
	%GoalsScroll.custom_minimum_size.y = minf(goals_list.get_combined_minimum_size().y,maxf(60,footer_top-disclosure_top-goals_chrome-8))
	goals_panel.offset_top = disclosure_top
	goals_panel.offset_bottom = disclosure_top+goals_panel.get_combined_minimum_size().y
	var inspector_end: float=%BuildTray.position.y-8 if %BuildTray.visible else footer_top-8
	if goals_panel.visible and goals_panel.position.y > content_top:
		inspector_end=minf(inspector_end,goals_panel.position.y-8)
	var army: Control = get_node_or_null("ArmyPanel")
	if army != null and army.visible:
		army.fit_host(Rect2(Vector2(16,content_top), Vector2(size.x-32,maxf(0,inspector_end-content_top))))
	var inspector_available:=maxf(0,inspector_end-content_top)
	var minimum_height:=156.0 if inspector_text.visible else 220.0
	var inspection_height: float=minf(maxf(content_height,minimum_height),inspector_available)
	inspector.offset_top=inspector_end-inspection_height
	inspector.offset_bottom=inspector_end-size.y
	message_panel.offset_left=message_panel.offset_right-maxf(360,message_panel.get_combined_minimum_size().x)
	%ActiveToolCard.visible=build_entries.has(current_tool) and not %BuildTray.visible and not inspector.visible and not message_panel.visible and not decision_expanded
	var tool_card_end: float=inspector_end
	%ActiveToolCard.offset_top=tool_card_end-minf(%ActiveToolCard.get_combined_minimum_size().y,maxf(0,tool_card_end-content_top))
	%ActiveToolCard.offset_bottom=tool_card_end-size.y
	var journal_end: float = %BuildTray.position.y-8 if %BuildTray.visible else inspector_end
	var journal_top: float=message_panel.offset_top
	var journal_room: float = maxf(0,journal_end-journal_top)
	var journal_height: float = message_panel.get_combined_minimum_size().y + message_list.get_combined_minimum_size().y
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
	_layout_decision(content_top, notice_left)
	%ToastScroll.visible = not message_panel.visible and not decision_expanded and toasts.get_child_count() > 0
	# City notices sit at the top centre under the bar (and under the tool hint or invasion notice when they show), clear of
	# a waiting decision's reminder.
	# An open inspector or journal on the right keeps its side: the notice narrows and moves left of it.
	var toast_right: float=notice_right if (inspector.visible or message_panel.visible) else size.x-16
	var toast_width:=minf(560,maxf(240,toast_right-32))
	var toast_centre:=minf(size.x*.5,toast_right-toast_width*.5)-size.x*.5
	%ToastScroll.offset_left=toast_centre-toast_width*.5; %ToastScroll.offset_right=toast_centre+toast_width*.5
	var toast_top: float=notice_top
	if %Feedback.visible: toast_top=maxf(toast_top,%Feedback.offset_top+%Feedback.get_combined_minimum_size().y+8)
	if events_box.visible and events_box.get_global_rect().intersects(Rect2(size.x*.5+toast_centre-toast_width*.5,toast_top,toast_width,200)):
		toast_top=maxf(toast_top,events_box.position.y+events_box.size.y+8)
	%ToastScroll.offset_top=toast_top
	var stack_room:=maxf(44,(%BuildTray.position.y if %BuildTray.visible else %BottomBar.position.y)-%ToastScroll.position.y-8)
	if %MinimapPanel.visible and %MinimapPanel.position.x < %ToastScroll.get_global_rect().end.x and %MinimapPanel.get_global_rect().end.x > %ToastScroll.position.x:
		stack_room=minf(stack_room,maxf(44,%MinimapPanel.position.y-%ToastScroll.position.y-8))
	%ToastScroll.offset_bottom=%ToastScroll.offset_top+minf(toasts.get_combined_minimum_size().y,stack_room)
	# The tray never steals text entry or closes the selected construction tool.

func _layout_decision(content_top: float, notice_left: float) -> void:
	var width := minf(840, size.x-48) if decision_expanded else minf(400, size.x-notice_left-20)
	events_box.custom_minimum_size.x = width
	events_box.offset_left = -width*.5 if decision_expanded else notice_left-size.x*.5
	events_box.offset_right = events_box.offset_left+width
	var short := size.y < 650
	%EnvoyContent.vertical = width < 620
	%EnvoyHeader.custom_minimum_size.x = 128 if short else 152
	envoy_portrait.custom_minimum_size = Vector2(128,148) if short else Vector2(152,176)
	%EventActions.columns = mini(maxi(%EventActions.get_child_count(),1), 2 if width < 700 else 3)
	%EventActionScroll.custom_minimum_size.y = minf(%EventActions.get_combined_minimum_size().y, 110 if short else 156)
	var chrome: float = %DecisionHeader.get_combined_minimum_size().y + %DecisionFooter.get_combined_minimum_size().y + events_box.get_theme_stylebox("panel").get_minimum_size().y + 32
	var room := maxf(80, minf(340, size.y-48-chrome))
	var letter_room := maxf(80, room-%EnvoyLetter.get_theme_stylebox("panel").get_minimum_size().y)
	%EventScroll.custom_minimum_size.y = clampf(%Events.get_combined_minimum_size().y, minf(120, letter_room), letter_room)
	var height: float = events_box.get_combined_minimum_size().y
	var top := (size.y-height)*.5 if decision_expanded else content_top
	events_box.offset_top = top
	events_box.offset_bottom = top+height

func set_model_factory(factory: Callable) -> void:
	thumbnails = ThumbnailService.new()
	thumbnails.factory = factory
	add_child(thumbnails)
	thumbnails.thumbnail_ready.connect(func(asset, texture):
		if not context_item.is_empty() and ThumbnailService.key(context_item)==asset:%ContextPreview.texture=texture
		for preview in card_previews.get(asset, []):
			if is_instance_valid(preview): preview.texture = texture)

func _process(_delta: float) -> void:
	_layout_panels()
	_toolbar_context()
	var blocked := toolbar_has_focus() or _header_has_focus()
	if blocked != toolbar_blocked:
		toolbar_blocked = blocked
		toolbar_focus_changed.emit(blocked)
	var badge: PanelContainer=%PlacementBadge
	badge.visible=placement_feedback_active and get_viewport().gui_get_hovered_control()==null
	if badge.visible:
		var minimum:=Vector2(12,%StatusBar.size.y+8)
		var maximum:=Vector2(size.x-12,%BottomBar.position.y-8)-badge.size
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
	if action=="attention":return tr("City attention…")
	if action=="guide":return tr("Settlement guide…")
	var index: int=GAME_ACTIONS.find(action)
	if index<0:return ""
	var label: String=tr(GAME_LABELS[index])
	if GAME_KEYS.has(action):label+=" (%s)"%KeyBindings.label(GAME_KEYS[action])
	return label
