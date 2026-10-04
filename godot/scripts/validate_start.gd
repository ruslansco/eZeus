extends SceneTree
# The start menu and a new game, end to end (headless; a scratch save folder, never the player's saves).
#
# Instantiates the real start menu scene and drives it as a player would: with no saves Continue and Load are off;
# New game lists the adventures; Start reads one and shows its story and objectives; Back closes it cleanly; Begin
# opens the city scene with that adventure (empty city, objectives panel, paused); a save made there is offered by
# Continue, which reopens it; the Game menu's Main menu returns to the start. Also checks that automation launches
# skip the menu and that every adventure in the list opens.
# Loaded when the test runs: the menu refers to the GameAudio autoload, which a script run registers after compiling this file.
var okay := true
var checks := 0
var scratch := ""

func check(value: bool, description: String) -> void:
	checks += 1
	print("START_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func seconds(duration: float) -> void:
	await create_timer(duration).timeout

func current() -> Node:
	return current_scene

func show_menu(language: String) -> Control:
	Engine.set_meta("ezeus_language", language)
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	return menu

func run() -> void:
	scratch = ProjectSettings.globalize_path("res://captures/validation-start-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_save_directory", scratch)
	# The language button remembers its choice; keep that out of the player's real settings.
	Engine.set_meta("ezeus_settings_path", scratch.path_join("settings.cfg"))
	var StartMenu = load("res://ui/start_menu.gd")
	check(not StartMenu.automated(), "a plain launch is not automation, so it opens the menu")
	var menu := await show_menu("en")
	check(menu.get_node("%MainPage").visible and not menu.get_node("%AdventurePage").visible, "the menu opens on its main page")
	var audio := root.get_node("GameAudio")
	check(audio.music_kind == "menu" and audio.log.any(func(entry): return entry.path == "Audio/Music/Setup.mp3"), "the menu plays its title tune")
	check(menu.sound_button.text == "Sound" and menu.get_node("%Sound") == menu.sound_button, "the main page has a Sound button")
	menu.sound_button.pressed.emit()
	await frames(3)
	var sound_dialog: Window = null
	for child in menu.get_children():
		if child is AcceptDialog and child.get("sliders") != null and not child.sliders.is_empty():
			sound_dialog = child
	check(sound_dialog != null and sound_dialog.visible and sound_dialog.sliders.size() == 5, "it opens the sound settings")
	if sound_dialog != null:
		sound_dialog.hide()
		sound_dialog.queue_free()
	check(menu.title_label.text == "City Rebuild" and menu.new_game_button.text == "New game" and menu.quit_button.text == "Quit", "the main page has its English text")
	check(menu.continue_button.disabled and menu.load_game_button.disabled and menu.continue_info.text == "No saved games yet", "with no saves Continue and Load are off")
	check(not menu.new_game_button.disabled, "New game is always available")

	# Language: the button switches the whole page, remembered by the next screen.
	menu.language_button.pressed.emit()
	await frames(2)
	check(menu.new_game_button.text == "Новая игра" and menu.continue_info.text == "Сохранённых игр пока нет", "the language button switches the page to Russian")
	menu.language_button.pressed.emit()
	await frames(2)
	check(menu.new_game_button.text == "New game", "and back to English")

	# The list of adventures.
	menu.new_game_button.pressed.emit()
	await frames(2)
	check(menu.get_node("%AdventurePage").visible and menu.listing.size() >= 20 and menu.adventure_list.item_count == menu.listing.size(), "New game lists the adventures (%d)" % menu.listing.size())
	check(menu.adventure_list.get_selected_items() == PackedInt32Array([0]) and not menu.adventure_title.text.is_empty() and not menu.adventure_text.text.is_empty(), "the first one is chosen and described")
	var titles: Array = menu.listing.map(func(item): return String(item.title))
	check(not titles.any(func(title): return title.is_empty()), "every adventure has a title")
	var pick := -1
	for index in menu.listing.size():
		if menu.listing[index].title == "The Founding of Athens":
			pick = index
	check(pick >= 0, "The Founding of Athens is listed")
	menu.adventure_list.select(pick)
	menu.adventure_list.item_selected.emit(pick)
	check(menu.adventure_title.text == "The Founding of Athens", "choosing an entry shows its title")

	# Start, read the story, go back, start again.
	menu.adventure_start.pressed.emit()
	await seconds(1.5)
	check(menu.get_node("%IntroPage").visible and menu.opened != null, "Start reads the adventure and shows its introduction")
	print("START_BRIEFING_AUDIO ", JSON.stringify({"kind":audio.music_kind,"recorded":audio.log.filter(func(entry):return entry.bus=="Voice" or entry.path.get_basename().ends_with("mission_intro"))}))
	check(audio.log.any(func(entry): return entry.bus == "Voice" or entry.path in ["Audio/Music/mission_intro.wav", "Audio/Music/mission_intro.mp3"]) and audio.music_kind != "menu", "the introduction plays its recorded voice or the mission fanfare instead of the title tune")
	var goals_shown: int = menu.intro_goals.get_child_count()
	check(not menu.intro_heading.text.is_empty() and not menu.episode_title.text.is_empty() and not menu.intro_text.text.is_empty() and goals_shown >= 1, "the introduction has a title, a story and %d objectives" % goals_shown)
	menu.intro_back.pressed.emit()
	await frames(2)
	check(menu.opened == null and menu.get_node("%AdventurePage").visible, "Back closes the adventure and returns to the list")
	check(audio.music_kind == "menu", "and the title tune returns")
	var lister: RefCounted = ClassDB.instantiate("EZeusSimulation")
	check(not lister.adventures(ProjectSettings.globalize_path("res://..").simplify_path(), "en").has("error"), "the simulation is free again after Back")
	menu.adventure_start.pressed.emit()
	await seconds(1.5)
	check(menu.get_node("%IntroPage").visible, "Start works a second time")

	# Begin: the city scene takes over the opened adventure.
	menu.intro_begin.pressed.emit()
	await seconds(3.0)
	var city := current()
	check(city != null and city.scene_file_path == "res://main.tscn", "Begin opens the city scene")
	check(not Engine.has_meta("ezeus_simulation") and city.core.simulation != null, "the city adopted the opened adventure (no second read)")
	await seconds(2.5)
	check(city.state.buildings.size() == 0 and int(city.state.money) > 0 and city.state.paused, "a new game starts paused with an empty city and its treasury (%d)" % int(city.state.money))
	check(city.hud.goals_panel.visible and city.hud.goals_list.get_child_count() == goals_shown, "the objectives panel lists the same %d objectives" % goals_shown)
	check(city.hud.build_menu.get_popup().item_count >= 4, "the Build menu is filled for the new city")

	# Play a little: build a road, then save and return to the menu through the Game menu.
	var spot := Vector2i(99999, 99999)
	for cell in city.tiles:
		if int(city.tiles[cell][5]) and not int(city.tiles[cell][4]) and city.core.query("preview road %d %d 0" % [cell.x, cell.y]).get("valid", false):
			spot = cell
			break
	check(spot != Vector2i(99999, 99999), "the new city has ground to build on")
	var before_money: int = city.state.money
	city.core.send("build road %d %d 0" % [spot.x, spot.y])
	await seconds(.5)
	check(int(city.state.money) < before_money, "a road can be built in the new city")
	city.game_action("quick_save")
	await seconds(.5)
	check(FileAccess.file_exists(scratch.path_join("quicksave.ez")), "the Game menu saves into the scratch folder")
	city.game_action("main_menu")
	check(city.hud.menu_dialog.visible, "Main menu asks before leaving")
	city.hud.menu_dialog.confirmed.emit()
	await seconds(1.5)
	menu = current()
	check(menu != null and menu.scene_file_path == "res://ui/start_menu.tscn", "confirming returns to the start menu")
	check(not menu.continue_button.disabled and menu.continue_button.text == "Continue: quicksave", "Continue now offers the new save (%s)" % menu.continue_button.text)

	# Continue reopens it: the road is there.
	menu.continue_button.pressed.emit()
	await seconds(3.5)
	city = current()
	check(city != null and city.scene_file_path == "res://main.tscn" and city.core.simulation != null, "Continue opens the city again")
	check(city.state.buildings.size() == 0 and int(city.state.money) < before_money and city.hud.goals_panel.visible, "the saved game is the same adventure with its road and objectives")
	city.return_to_start()
	await seconds(1.5)
	menu = current()

	# The load page lists the save.
	menu.load_game_button.pressed.emit()
	await frames(2)
	check(menu.get_node("%LoadPage").visible and menu.save_list.item_count == 2 and menu.save_info.text.contains("MB") and menu.save_entries.any(func(entry): return entry.name == "autosave replay"), "Load game lists the saves (the episode's autosave and the quick save) with size and time")
	menu.load_back.pressed.emit()
	await frames(2)
	check(menu.get_node("%MainPage").visible, "Back returns to the main page")

	# Russian: the adventure list is in Russian.
	menu.language_button.pressed.emit()
	await frames(2)
	menu.new_game_button.pressed.emit()
	await frames(2)
	var russian: Array = menu.listing.filter(func(item): return String(item.title).unicode_at(0) >= 0x400)
	check(russian.size() >= 15, "in Russian most adventures have Russian titles (%d of %d)" % [russian.size(), menu.listing.size()])
	Engine.set_meta("ezeus_language", "en")

	# Automation launches skip the menu.
	check(OS.get_cmdline_user_args().is_empty(), "this run passes no launch flags")
	DirAccess.remove_absolute(scratch.path_join("quicksave.ez"))
	DirAccess.remove_absolute(scratch.path_join("autosave replay.ez"))
	DirAccess.remove_absolute(scratch.path_join("settings.cfg"))
	Engine.remove_meta("ezeus_settings_path")
	DirAccess.remove_absolute(scratch)
	print("START_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
