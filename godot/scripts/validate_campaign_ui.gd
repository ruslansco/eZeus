extends SceneTree
# The campaign through the real scenes (headless, scratch saves): a new game of The Founding of Athens is started from the
# menu; goods are set aside from the objectives panel; winning the first episode shows the result card, then the choice of
# colony, the colony's briefing (with a difficulty choice) and, on Begin, the colony city; winning that returns to the
# parent city, which kept what was built; a defeat card offers to retry the episode from its start; the last episode ends
# with the adventure's closing words and the way back to the menu.
var okay := true
var checks := 0
var scratch := ""

func check(value: bool, description: String) -> void:
	checks += 1
	print("CAMPAIGN_UI_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func seconds(duration: float) -> void:
	await create_timer(duration).timeout

func city() -> Node:
	return current_scene

# Waits until the city polled the core and the overlay shows (the poll is every two seconds).
func wait_for_overlay(limit := 6.0) -> bool:
	var waited := 0.0
	while waited < limit:
		await seconds(.5)
		waited += .5
		if city().episode_overlay.visible:
			return true
	return false

func roads(state: Dictionary) -> int:
	var count := 0
	for tile in state.tiles:
		count += int(tile[4])
	return count

func run() -> void:
	scratch = ProjectSettings.globalize_path("res://captures/validation-campaign-ui-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_save_directory", scratch)
	Engine.set_meta("ezeus_settings_path", scratch.path_join("settings.cfg"))
	Engine.set_meta("ezeus_language", "en")
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await seconds(.5)
	menu.new_game_button.pressed.emit()
	await seconds(.4)
	for index in menu.listing.size():
		if menu.listing[index].title == "The Founding of Athens":
			menu.adventure_list.select(index)
			menu.show_adventure(index)
	menu.adventure_start.pressed.emit()
	await seconds(1.5)
	check(menu.intro_card.mode == "intro" and menu.intro_card.difficulty_row.visible and menu.intro_card.secondary.visible, "the first briefing has a difficulty choice and a Back button")
	check(menu.intro_card.difficulty_value.text == "hero", "the difficulty starts at hero (%s)" % menu.intro_card.difficulty_value.text)
	menu.intro_card.difficulty_up.pressed.emit()
	await seconds(.1)
	check(menu.intro_card.difficulty_value.text == "titan" and menu.opened.command("difficulty").value == 3, "choosing a harder difficulty is applied to the campaign")
	menu.intro_card.difficulty_down.pressed.emit()
	menu.intro_begin.pressed.emit()
	await seconds(3.0)
	var game := city()
	game.core.simulation.enable_test_commands()
	check(game.scene_file_path == "res://main.tscn" and not game.episode_overlay.visible, "the city opens without a campaign screen")
	check(FileAccess.file_exists(scratch.path_join("autosave replay.ez")), "the first episode's start is saved for a retry")

	# Build something that must survive, and set goods aside from the objectives panel.
	var state: Dictionary = game.core.simulation.snapshot(true)
	var road_at := Vector2i(99999, 99999)
	var store_at := Vector2i(99999, 99999)
	for tile in state.tiles:
		if int(tile[5]) and not int(tile[4]):
			if road_at.x == 99999 and game.core.query("preview road %d %d 0" % [tile[0], tile[1]]).get("valid", false):
				road_at = Vector2i(int(tile[0]), int(tile[1]))
			if store_at.x == 99999 and game.core.query("preview warehouse %d %d 0" % [tile[0], tile[1]]).get("valid", false):
				store_at = Vector2i(int(tile[0]), int(tile[1]))
		if road_at.x != 99999 and store_at.x != 99999:
			break
	game.core.query("build road %d %d 0" % [road_at.x, road_at.y])
	game.core.query("build warehouse %d %d 0" % [store_at.x, store_at.y])
	var roads_first := roads(game.core.simulation.snapshot(true))
	game.core.query("test_stock 2048 16")
	await seconds(2.6)
	var aside_buttons := 0
	for line in game.hud.goals_list.get_children():
		for node in line.get_children():
			aside_buttons += 1 if node is Button and node.text == "Set aside" else 0
	check(aside_buttons == 1, "the objectives panel offers to set the olive oil aside once it is in store")
	for line in game.hud.goals_list.get_children():
		for node in line.get_children():
			if node is Button and node.text == "Set aside":
				node.pressed.emit()
	await seconds(.5)
	var oil_met := false
	for goal in game.core.query("episode").goals:
		oil_met = oil_met or (str(goal.text).contains("oil") and goal.met)
	check(oil_met and game.hint.text == game.tr("The goods are set aside"), "pressing it sets the goods aside and meets the objective")

	# A defeat card offers the retry; the retry reloads the episode's start (without the road).
	game.episode_overlay.show_result({"victory": false})
	check(game.episode_overlay.visible and game.episode_overlay.card.mode == "defeat" and not game.episode_overlay.card.secondary.disabled, "a defeat shows its card with a retry")
	game.episode_overlay.card.secondary.pressed.emit()
	await seconds(3.5)
	game = city()
	check(game.scene_file_path == "res://main.tscn" and roads(game.core.simulation.snapshot(true)) == roads_first - 1 and not game.episode_overlay.visible, "the retry reloads the episode from its start (the road is gone)")
	game.core.simulation.enable_test_commands()
	game.core.query("build road %d %d 0" % [road_at.x, road_at.y])

	# Victory: result, colonies, briefing, the colony.
	var parent_tiles: int = game.core.simulation.snapshot(true).tiles.size()
	game.core.query("test_win")
	check(await wait_for_overlay() and game.episode_overlay.card.mode == "victory", "winning the episode shows the victory card")
	check(game.episode_overlay.card.goals.get_child_count() == 4 and game.episode_overlay.card.primary.text == "Continue", "with its objectives and a Continue button")
	game.episode_overlay.card.primary.pressed.emit()
	await seconds(.3)
	var card = game.episode_overlay.card
	check(card.mode == "colonies" and card.colonies.item_count == 2 and card.colonies.visible, "Continue offers the two colonies")
	card.colonies.select(1)
	card.primary.pressed.emit()
	await seconds(.3)
	check(card.mode == "intro" and not card.secondary.visible and card.difficulty_row.visible and not str(card.body.text).is_empty(), "the chosen colony is briefed, with no way back and a difficulty choice")
	card.difficulty_up.pressed.emit()
	await seconds(.1)
	check(game.core.query("difficulty").value == 3, "its difficulty choice reaches the campaign")
	game.core.query("difficulty 2")
	card.primary.pressed.emit()
	await seconds(3.5)
	game = city()
	var colony_state: Dictionary = game.core.simulation.snapshot(true)
	check(game.scene_file_path == "res://main.tscn" and colony_state.tiles.size() != parent_tiles and game.core.query("episode").colony and not game.episode_overlay.visible, "Begin opens the colony city (another map)")
	check(game.hud.goals_panel.visible, "the colony has its own objectives")
	game.core.simulation.enable_test_commands()
	game.core.query("test_win")
	check(await wait_for_overlay(), "winning the colony shows its result")
	game.episode_overlay.card.primary.pressed.emit()
	await seconds(.3)
	check(game.episode_overlay.card.mode == "intro" and game.episode_overlay.card.subtitle.text.contains("2"), "the campaign goes on with the second parent episode (%s)" % game.episode_overlay.card.subtitle.text)
	game.episode_overlay.card.primary.pressed.emit()
	await seconds(3.5)
	game = city()
	var back: Dictionary = game.core.simulation.snapshot(true)
	check(back.tiles.size() == parent_tiles and roads(back) == roads_first and game.core.query("episode").episode_number == 2, "the parent city is back with the road the player built")

	# The rest of the campaign, to the end.
	var guard := 0
	while guard < 10:
		guard += 1
		game.core.simulation.enable_test_commands()
		game.core.query("test_win")
		if not await wait_for_overlay():
			break
		var overlay = game.episode_overlay
		overlay.card.primary.pressed.emit()
		await seconds(.3)
		if overlay.card.mode == "complete":
			break
		if overlay.card.mode == "colonies":
			overlay.card.primary.pressed.emit()
			await seconds(.3)
		overlay.card.primary.pressed.emit()
		await seconds(3.5)
		game = city()
	var ending = game.episode_overlay.card
	check(ending.mode == "complete" and not str(ending.body.text).is_empty() and ending.primary.text == "Main menu", "the last episode ends with the adventure's closing words and the way back to the menu")
	ending.primary.pressed.emit()
	await seconds(1.5)
	check(city().scene_file_path == "res://ui/start_menu.tscn", "the way back leads to the start menu")
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	Engine.remove_meta("ezeus_settings_path")
	print("CAMPAIGN_UI_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
