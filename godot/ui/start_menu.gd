extends Control
# The start menu: the first thing a player sees. Continue the newest save, start a new game from one of the
# adventures, load a saved game, switch language or quit. Choosing hands one of three things to the city scene
# through Engine meta (a save path, or an adventure already opened here so it is read once), then changes scene.
# Launches for automation (validation, captures, reviews, the legacy bridge) skip the menu and open the city.
# The layout is ui/start_menu.tscn, styled by the one Theme ui/lapis_gold.tres; text is `tr()` keyed by its English
# source, so changing language re-applies it and never rebuilds a control.

const UiText = preload("res://scripts/ui_text.gd")
const SaveFiles = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const SoundDialog = preload("res://ui/sound_dialog.gd")
const GameSettingsDialog=preload("res://ui/game_settings_dialog.gd")
const CITY := "res://main.tscn"
const AUTOMATION := ["--validate", "--asset-review", "--bridge-port=", "--capture=", "--terrain-review=", "--garden-review=", "--sanctuary-review=", "--pyramid-review=", "--controls-review=", "--objectives-review=",
	"--character-review=", "--skip-start"]

@onready var pages := {
	"main": %MainPage, "adventures": %AdventurePage, "intro": %IntroPage, "load": %LoadPage}
@onready var title_label: Label = %Title
@onready var tagline: Label = %Tagline
@onready var continue_button: Button = %Continue
@onready var continue_info: Label = %ContinueInfo
@onready var new_game_button: Button = %NewGame
@onready var load_game_button: Button = %LoadGame
@onready var language_button: Button = %Language
@onready var quit_button: Button = %Quit
@onready var sound_button: Button = %Sound
@onready var adventure_heading: Label = %AdventureHeading
@onready var adventure_list: ItemList = %AdventureList
@onready var adventure_title: Label = %AdventureTitle
@onready var adventure_text: Label = %AdventureText
@onready var adventure_status: Label = %AdventureStatus
@onready var adventure_back: Button = %AdventureBack
@onready var adventure_start: Button = %AdventureStart
@onready var intro_card = %IntroCard
# The roster of leaders (built here, see build_leaders): the page and the main page's leader line.
var leader_page: PanelContainer
var leader_heading: Label
var leader_list: ItemList
var leader_name: LineEdit
var leader_create: Button
var leader_delete: Button
var leader_proceed: Button
var leader_back: Button
var leader_status: Label
var leader_line: Label
var leader_change: Button
var leader_confirm: ConfirmationDialog
# The introduction page is the shared episode card; these names point at its parts.
@onready var intro_heading: Label = intro_card.heading
@onready var episode_title: Label = intro_card.subtitle
@onready var intro_text: Label = intro_card.body
@onready var goals_heading: Label = intro_card.goals_heading
@onready var intro_goals: VBoxContainer = intro_card.goals
@onready var intro_back: Button = intro_card.secondary
@onready var intro_begin: Button = intro_card.primary
@onready var load_heading: Label = %LoadHeading
@onready var save_list: ItemList = %SaveList
@onready var save_info: Label = %SaveInfo
@onready var load_back: Button = %LoadBack
@onready var load_open: Button = %LoadOpen

var language := "en"
var engine := ""
var page := "main"
var listing: Array = []
var save_entries: Array = []
var latest_save: Dictionary = {}
# The adventure opened for the introduction page, until Begin hands it to the city or Back closes it.
var opened: RefCounted

static func automated() -> bool:
	for argument in OS.get_cmdline_user_args():
		for prefix in AUTOMATION:
			if argument == prefix or (prefix.ends_with("=") and argument.begins_with(prefix)):
				return true
	return false

func _ready() -> void:
	if automated():
		get_tree().change_scene_to_file.call_deferred(CITY)
		return
	engine = ProjectSettings.globalize_path("res://..").simplify_path()
	var requested := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="):
			requested = argument.get_slice("=", 1)
	if Engine.has_meta("ezeus_language"):
		requested = str(Engine.get_meta("ezeus_language"))
	language = UiText.set_language(requested if not requested.is_empty() else UserSettings.language())
	continue_button.pressed.connect(func(): load_save(latest_save.get("path", "")))
	new_game_button.pressed.connect(open_adventures)
	load_game_button.pressed.connect(open_saves)
	language_button.pressed.connect(change_language)
	quit_button.pressed.connect(func(): get_tree().quit())
	sound_button.pressed.connect(func(): SoundDialog.open(self))
	%Interface.icon=load("res://ui/icons/gear.svg")
	%Interface.pressed.connect(func():GameSettingsDialog.open(self))
	adventure_back.pressed.connect(func(): show_page("main"))
	adventure_start.pressed.connect(start_adventure)
	adventure_list.item_selected.connect(show_adventure)
	adventure_list.item_activated.connect(func(_index): start_adventure())
	intro_card.secondary_pressed.connect(close_intro)
	intro_card.primary_pressed.connect(begin)
	intro_card.difficulty_changed.connect(func(value):
		if opened != null:
			opened.command("difficulty %d" % value))
	load_back.pressed.connect(func(): show_page("main"))
	load_open.pressed.connect(func(): open_selected_save())
	save_list.item_selected.connect(func(index): save_info.text = save_entries[index].detail if index < save_entries.size() else "")
	save_list.item_activated.connect(func(_index): open_selected_save())
	build_leaders()
	retranslate()
	refresh_main()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--start-review="):
			start_review.call_deferred()
			return
	# As in the SDL game, a player without a leader names one first.
	if Leaders.current().is_empty():
		open_leaders()
	else:
		show_page("main")
	GameAudio.play_music("menu")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		match page:
			"adventures", "load":
				show_page("main")
			"leaders":
				if not Leaders.current().is_empty():
					show_page("main")
			"intro":
				close_intro()
		get_viewport().set_input_as_handled()

func core_language() -> String:
	return language if language in ["en", "ru"] else "en"

func show_page(name: String) -> void:
	page = name
	for key in pages:
		pages[key].visible = key == name
	match name:
		"main":
			refresh_main()
			(continue_button if not continue_button.disabled else new_game_button).grab_focus()
		"adventures":
			adventure_list.grab_focus()
		"intro":
			intro_begin.grab_focus()
		"load":
			save_list.grab_focus()
		"leaders":
			(leader_list if leader_list.item_count > 0 else leader_name).grab_focus()

# Re-applies every translatable text for the current locale. No control is rebuilt.
func retranslate() -> void:
	title_label.text = tr("City Rebuild")
	tagline.text = tr("Raise a city of ancient Greece")
	continue_button.text = tr("Continue")
	new_game_button.text = tr("New game")
	load_game_button.text = tr("Load game")
	language_button.text = UiText.next_language(TranslationServer.get_locale()).to_upper()
	language_button.tooltip_text = tr("Switch language")
	quit_button.text = tr("Quit")
	sound_button.text = tr("Sound")
	%Interface.tooltip_text=tr("Game settings")
	adventure_heading.text = tr("Choose an adventure")
	adventure_back.text = tr("Back")
	adventure_start.text = tr("Start")
	load_heading.text = tr("Load game")
	load_back.text = tr("Back")
	load_open.text = tr("Load")
	leader_heading.text = tr("Roster of leaders")
	leader_name.placeholder_text = tr("New leader's name")
	leader_create.text = tr("Create leader")
	leader_delete.text = tr("Delete leader")
	leader_proceed.text = tr("Proceed")
	leader_back.text = tr("Back")
	leader_change.text = tr("Change leader")
	refresh_main()

# The Continue button names the newest save, or is off while there is none.
func refresh_main() -> void:
	if leader_line != null:
		leader_line.text = tr("Leader: %s") % Leaders.current() if not Leaders.current().is_empty() else tr("No leader chosen")
	latest_save = SaveFiles.latest()
	continue_button.disabled = latest_save.is_empty()
	continue_button.text = tr("Continue") if latest_save.is_empty() else tr("Continue: %s") % latest_save.name
	continue_info.text = tr("No saved games yet") if latest_save.is_empty() else latest_save.detail
	load_game_button.disabled = latest_save.is_empty()

func change_language() -> void:
	language = UiText.set_language(UiText.next_language(language))
	UserSettings.set_language(language)
	Engine.set_meta("ezeus_language", language)
	retranslate()

func go_city() -> void:
	Engine.set_meta("ezeus_language", language)
	Engine.set_meta("ezeus_from_start", true)
	get_tree().change_scene_to_file(CITY)

func load_save(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	Engine.set_meta("ezeus_load", path)
	go_city()

func open_saves() -> void:
	save_entries = SaveFiles.list()
	save_list.clear()
	for entry in save_entries:
		save_list.add_item(entry.name)
	save_info.text = ""
	if not save_entries.is_empty():
		save_list.select(0)
		save_info.text = save_entries[0].detail
	show_page("load")

func open_selected_save() -> void:
	var chosen := save_list.get_selected_items()
	if not chosen.is_empty():
		load_save(save_entries[chosen[0]].path)

# The adventures come from the simulation core (the SDL game's own list, in the interface language).
func open_adventures() -> void:
	var lister: RefCounted = ClassDB.instantiate("EZeusSimulation") if ClassDB.class_exists("EZeusSimulation") else null
	var result: Dictionary = lister.adventures(engine, core_language()) if lister != null else {"error": "embedded_query_required"}
	listing = []
	for item in result.get("adventures", []):
		if not String(item.title).is_empty():
			listing.append(item)
	listing.sort_custom(func(a, b): return String(a.title).naturalnocasecmp_to(String(b.title)) < 0)
	adventure_list.clear()
	for item in listing:
		adventure_list.add_item(item.title)
	adventure_status.text = "" if not listing.is_empty() else tr("No adventures were found")
	adventure_start.disabled = listing.is_empty()
	adventure_title.text = ""
	adventure_text.text = ""
	if not listing.is_empty():
		adventure_list.select(0)
		show_adventure(0)
	show_page("adventures")

func show_adventure(index: int) -> void:
	if index < 0 or index >= listing.size():
		return
	adventure_title.text = listing[index].title
	adventure_text.text = listing[index].introduction

# Reads the chosen adventure's campaign (a moment), then shows its first episode's story and goals.
func start_adventure() -> void:
	var chosen := adventure_list.get_selected_items()
	if chosen.is_empty():
		return
	var item: Dictionary = listing[chosen[0]]
	adventure_status.text = tr("Loading…")
	adventure_start.disabled = true
	await get_tree().process_frame
	await get_tree().process_frame
	opened = ClassDB.instantiate("EZeusSimulation")
	opened.set_save_directory(SaveFiles.directory())
	var result: Dictionary = opened.open_adventure(engine, item.kind, item.ref, core_language())
	if not result.has("error") and not Leaders.current().is_empty():
		opened.command("player_name " + Leaders.current())
	adventure_start.disabled = false
	if result.has("error"):
		opened.close_city()
		opened = null
		adventure_status.text = tr("That adventure could not be opened")
		return
	adventure_status.text = ""
	var episode: Dictionary = opened.command("episode")
	intro_card.show_intro(episode, true)
	var levels: Dictionary = opened.command("difficulty")
	intro_card.set_difficulty(int(levels.get("value", 2)), levels.get("names", []))
	# The campaign's recorded introduction speaks over a silent menu; without one the mission fanfare plays.
	GameAudio.play_briefing(str(episode.get("voice", "")))
	show_page("intro")

func close_intro() -> void:
	GameAudio.stop_voice()
	GameAudio.play_music("menu")
	if opened != null:
		opened.close_city()
		opened = null
	show_page("adventures")

# The opened adventure goes to the city scene, which adopts it instead of opening a city of its own.
func begin() -> void:
	if opened == null:
		return
	GameAudio.stop_voice()
	# The state each episode can be retried from (the SDL game's "autosave replay").
	opened.save_city("autosave replay")
	Engine.set_meta("ezeus_simulation", opened)
	opened = null
	go_city()

# ---- the roster of leaders -----------------------------------------------------------------------------------------
# Built in code with the menu's Theme (ui/start_menu.tscn is edited by hand and not regenerated): a page listing the
# leaders, a name to create one, Delete (after a confirmation: it removes that leader's saves) and Proceed; the main page
# names the leader and offers to change.
func build_leaders() -> void:
	leader_page = PanelContainer.new()
	leader_page.name = "LeaderPage"
	leader_page.custom_minimum_size = Vector2(560, 520)
	leader_page.visible = false
	# Centred like the load page (the main page has its own anchor at the side).
	get_node("Center").add_child(leader_page)
	pages["leaders"] = leader_page
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	leader_page.add_child(column)
	leader_heading = Label.new()
	leader_heading.theme_type_variation = "Heading"
	column.add_child(leader_heading)
	leader_list = ItemList.new()
	leader_list.name = "LeaderList"
	leader_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	leader_list.item_activated.connect(func(_index): proceed_leader())
	leader_list.item_selected.connect(func(_index): leader_delete.disabled = false; leader_proceed.disabled = false)
	column.add_child(leader_list)
	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 10)
	column.add_child(create_row)
	leader_name = LineEdit.new()
	leader_name.name = "LeaderName"
	leader_name.max_length = Leaders.MAX_LENGTH
	leader_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_name.text_submitted.connect(func(_text): create_leader())
	create_row.add_child(leader_name)
	leader_create = Button.new()
	leader_create.name = "LeaderCreate"
	leader_create.custom_minimum_size = Vector2(170, 46)
	leader_create.pressed.connect(create_leader)
	create_row.add_child(leader_create)
	leader_status = Label.new()
	leader_status.theme_type_variation = "Detail"
	column.add_child(leader_status)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	leader_delete = Button.new()
	leader_delete.name = "LeaderDelete"
	leader_delete.custom_minimum_size = Vector2(150, 46)
	leader_delete.pressed.connect(ask_delete_leader)
	buttons.add_child(leader_delete)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	leader_back = Button.new()
	leader_back.name = "LeaderBack"
	leader_back.custom_minimum_size = Vector2(120, 46)
	leader_back.pressed.connect(func(): show_page("main"))
	buttons.add_child(leader_back)
	leader_proceed = Button.new()
	leader_proceed.name = "LeaderProceed"
	leader_proceed.theme_type_variation = "Primary"
	leader_proceed.custom_minimum_size = Vector2(170, 46)
	leader_proceed.pressed.connect(proceed_leader)
	buttons.add_child(leader_proceed)
	leader_confirm = ConfirmationDialog.new()
	leader_confirm.confirmed.connect(delete_leader)
	add_child(leader_confirm)
	# The main page's leader line, under the tagline.
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 10)
	leader_line = Label.new()
	leader_line.name = "LeaderLine"
	leader_line.theme_type_variation = "Caption"
	line.add_child(leader_line)
	leader_change = Button.new()
	leader_change.name = "LeaderChange"
	leader_change.flat = true
	leader_change.pressed.connect(open_leaders)
	line.add_child(leader_change)
	tagline.get_parent().add_child(line)
	tagline.get_parent().move_child(line, tagline.get_index() + 1)

func open_leaders() -> void:
	leader_list.clear()
	var names := Leaders.list()
	for name in names:
		leader_list.add_item(name)
	var current := Leaders.current()
	if current in names:
		leader_list.select(names.find(current))
	leader_delete.disabled = leader_list.get_selected_items().is_empty()
	leader_proceed.disabled = leader_list.get_selected_items().is_empty()
	leader_back.visible = not current.is_empty()
	leader_status.text = "" if not names.is_empty() else tr("Name a leader to begin")
	leader_name.text = ""
	show_page("leaders")

func selected_leader() -> String:
	var chosen := leader_list.get_selected_items()
	return leader_list.get_item_text(chosen[0]) if not chosen.is_empty() else ""

func create_leader() -> void:
	var name := leader_name.text.strip_edges()
	var problem := Leaders.problem(name)
	if not problem.is_empty():
		leader_status.text = tr(problem)
		return
	if not Leaders.create(name):
		leader_status.text = tr("That name cannot be used")
		return
	Leaders.set_current(name)
	open_leaders()
	leader_status.text = tr("Leader %s is ready") % name

func ask_delete_leader() -> void:
	var name := selected_leader()
	if name.is_empty():
		return
	leader_confirm.title = tr("Delete leader")
	leader_confirm.dialog_text = tr("Delete %s and all of that leader's saved games?") % name
	leader_confirm.ok_button_text = tr("Delete")
	leader_confirm.cancel_button_text = tr("Keep")
	leader_confirm.popup_centered()

func delete_leader() -> void:
	var name := selected_leader()
	if name.is_empty() or not Leaders.delete(name):
		return
	open_leaders()
	leader_status.text = tr("%s was deleted") % name

func proceed_leader() -> void:
	var name := selected_leader()
	if name.is_empty():
		return
	Leaders.set_current(name)
	show_page("main")

# ---- review (run_godot_pilot.py --start-review leaders) ----------------------------------------------------------------
# Captures the roster and the main page in a scratch profile (never the player's own saves or settings), then opens The Sands
# of Betrayal with money for its city for sale and hands it to the city, whose `cities` review takes over.
func start_review() -> void:
	var folder := ProjectSettings.globalize_path("res://captures/start-review-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(folder.path_join("saves"))
	Engine.set_meta("ezeus_save_directory", folder.path_join("saves"))
	Engine.set_meta("ezeus_settings_path", folder.path_join("settings.cfg"))
	refresh_main()
	open_leaders()
	await get_tree().create_timer(.8).timeout
	await review_capture("roster-empty")
	leader_name.text = "Pericles"
	create_leader()
	await get_tree().create_timer(.5).timeout
	await review_capture("roster")
	proceed_leader()
	await get_tree().create_timer(.5).timeout
	await review_capture("main")
	var engine_root := engine
	var lister: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var sands := {}
	for item in lister.adventures(engine_root, core_language()).get("adventures", []):
		if str(item.title).contains("Sands") or str(item.title).contains("Песк"):
			sands = item
	opened = ClassDB.instantiate("EZeusSimulation")
	opened.set_save_directory(SaveFiles.directory())
	opened.open_adventure(engine_root, sands.kind, sands.ref, core_language())
	opened.command("player_name " + Leaders.current())
	opened.enable_test_commands()
	opened.command("test_money 20000")
	Engine.set_meta("ezeus_cities_review", true)
	Engine.set_meta("ezeus_simulation", opened)
	opened = null
	print("START_REVIEW PASS leaders captured, opening ", sands.get("title", "?"))
	go_city()

func review_capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://captures/start-review-%s-%s.png" % [language, name]))
