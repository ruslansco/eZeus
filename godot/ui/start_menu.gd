extends Control
# The start menu: the first thing a player sees. Continue the newest save, start a new game from one of the
# adventures, load a saved game, switch language or quit. Choosing hands one of three things to the city scene
# through Engine meta (a save path, or an adventure already opened here so it is read once), then changes scene.
# Launches for automation (validation, captures, reviews, the legacy bridge) skip the menu and open the city.
# The layout is ui/start_menu.tscn, styled by the one Theme ui/lapis_gold.tres; text is `tr()` keyed by its English
# source, so changing language re-applies it and never rebuilds a control.

const UiText = preload("res://scripts/ui_text.gd")
const SaveFiles = preload("res://scripts/save_files.gd")
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
	retranslate()
	refresh_main()
	show_page("main")
	GameAudio.play_music("menu")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		match page:
			"adventures", "load":
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
	refresh_main()

# The Continue button names the newest save, or is off while there is none.
func refresh_main() -> void:
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
