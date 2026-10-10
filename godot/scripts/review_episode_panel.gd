extends SceneTree
# Real native campaign data and commands over the designated saved city's owned, paused presentation.
# Saves/settings live only in a disposable profile. Test-win supplies a transition without playing hours.
var language := "en"
var checks := 0
var okay := true
var game: Node
var card: Control
const SaveFiles = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path",OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory",OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("EPISODE_PANEL_CHECK ","PASS " if value else "FAIL ",description)
func frames(count := 8) -> void:
	for i in count: await process_frame
func click(control: Control) -> void:
	control.grab_focus()
	await frames()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = control.get_global_rect().get_center()
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
	await frames()
func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta("review_input",true)
		root.push_input(event,true)
	await frames()
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/episode-panel-%s-%s.png" % [language,name])
func bounds(label: String) -> void:
	var panel: Control = card.get_parent()
	var viewport := Rect2(Vector2.ZERO,root.get_visible_rect().size)
	check(viewport.encloses(panel.get_global_rect()), label+": shell stays in viewport")
	check(panel.get_global_rect().encloses(card.primary.get_global_rect()) and card.primary.size.y >= 44, label+": primary action stays visible and usable")
	check(card.scroll.size.y >= 80 and card.get_node("%GoalScroll").size.y >= 80 and card.scroll.get_global_rect().end.x <= card.get_node("%GoalsPanel").get_global_rect().position.x, label+": story and objectives retain separate reading areas")
func goal_texts() -> Array:
	return card.goals.get_children().map(func(tile): return tile.get_child(0).get_child(0).get_child(1).text)
func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	Leaders.create("Episode Review")
	Leaders.set_current("Episode Review")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var fixture := SaveFiles.directory().path_join("campaign review.ez")
	var source := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	check(DirAccess.copy_absolute(source,fixture) == OK,"designated city copied only to disposable profile")
	var saved_hash := FileAccess.get_sha256(fixture)
	Engine.set_meta("ezeus_load",fixture)
	Engine.set_meta("ezeus_from_start",true)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	var deadline := Time.get_ticks_msec()+45000
	while game.state.is_empty() and Time.get_ticks_msec()<deadline: await process_frame
	game.core.query("pause 1")
	game.core.set_process(false)
	game.set_process(false)
	await frames(20)
	check(game.tiles.size() == 25992,"real full saved-city backdrop is loaded")
	var overlay = game.episode_overlay
	card = overlay.card
	var preview: Dictionary = game.core.query("preview_episode")
	overlay._brief(preview)
	overlay.visible = true
	await frames(20)
	check(card.mode == "intro" and card.phase.text == card.tr("Next chapter") and card.episode_progress.visible,"briefing separates chapter, campaign and native episode counter")
	check(language != "ru" or (card.phase.text != "Next chapter" and card.get_node("%StoryHeading").text != "Story" and card.difficulty_up.tooltip_text != "Higher difficulty"),"new Russian headings and difficulty hints are imported")
	check(card.body.text == str(preview.introduction) and goal_texts() == preview.goals.map(func(goal): return goal.text),"briefing preserves the full native story and every goal quantity")
	bounds("default briefing")
	await capture("briefing")
	var previous: int = int(game.core.query("difficulty").value)
	await click(card.difficulty_up)
	check(int(game.core.query("difficulty").value) == mini(previous+1,4) and card.difficulty == mini(previous+1,4),"pointer difficulty choice reaches the native campaign")
	card.difficulty_down.grab_focus()
	await key(KEY_ENTER)
	check(int(game.core.query("difficulty").value) == previous and card.difficulty_down.focus_mode == Control.FOCUS_ALL,"keyboard difficulty choice restores the native setting")
	for size in [Vector2i(1280,800),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size)
		root.get_node("UiAccess").apply(125,130)
		await frames(25)
		bounds("125% interface / 130% text "+str(size))
		check(card.get_node("%GoalScroll").get_global_rect().has_point(card.goals.get_child(0).get_global_rect().get_center()),"first objective stays visible before scrolling")
		await capture("large-%d" % size.y)
	root.get_node("UiAccess").apply(100,100)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await frames(20)
	game.core.simulation.enable_test_commands()
	game.core.query("test_win")
	var episode: Dictionary = game.core.query("episode")
	overlay.show_result(episode)
	await frames(20)
	check(card.mode == "victory" and card.get_node("%Medal").texture != null and not card.difficulty_row.visible,"result has a victory medallion and a clear Continue action")
	check(goal_texts() == episode.goals.map(func(goal): return goal.text),"result retains every exact native objective")
	var states: Array = card.goals.get_children().map(func(tile): return tile.theme_type_variation == "EpisodeGoalMet")
	check(states == episode.goals.map(func(goal): return bool(goal.met)),"completion cards and achieved count use native met flags")
	await capture("victory")
	card.scroll.scroll_vertical = 100000
	await frames()
	check(card.scroll.scroll_vertical > 0 and card.scroll.get_v_scroll_bar().value + card.scroll.get_v_scroll_bar().page >= card.scroll.get_v_scroll_bar().max_value-1,"long result story can be read through to its last paragraph")
	await capture("story-end")
	var frozen: Dictionary = game.core.simulation.snapshot(false)
	await frames(20)
	var after: Dictionary = game.core.simulation.snapshot(false)
	check(frozen.time == after.time,"reading and scrolling retain the paused native clock")
	# Presentation-only all-achieved fixture covers the normal victory heading's
	# longest Russian wrap. The native test-win command intentionally leaves met flags alone.
	var done := episode.duplicate(true)
	for goal in done.goals:
		goal.met = true
		goal.status = card.tr("Achieved")
	card.show_victory(done)
	DisplayServer.window_set_size(Vector2i(1280,720))
	root.get_node("UiAccess").apply(125,130)
	await frames(25)
	check(card.goals_heading.text == card.tr("Completed objectives") and card.goal_summary.text == card.tr("%d of %d achieved") % [done.goals.size(),done.goals.size()],"all-achieved fixture has a clear completed-objective heading")
	bounds("enlarged completed-result fixture")
	await capture("completed-fixture")
	check(game.core.query("episode").goals == episode.goals,"completed-result visual fixture never changes native goals")
	root.get_node("UiAccess").apply(100,100)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	card.show_victory(episode)
	await frames(20)
	await click(card.primary)
	if card.mode == "colonies":
		check(card.colonies.item_count > 0 and card.colonies.visible and not card.get_node("%GoalScroll").visible,"Continue presents the native colony choices")
		await capture("colonies")
		await click(card.primary)
	check(card.mode == "intro" and not card.secondary.visible and card.difficulty_row.visible,"Continue reaches the actual next native briefing")
	var next: Dictionary = game.core.query("preview_episode")
	check(goal_texts() == next.goals.map(func(goal): return goal.text) and card.body.text == str(next.introduction),"next briefing shows its own native goals and complete story")
	await frames(20)
	await capture("next-chapter")
	var starts := {"count":0}
	overlay.session_started.disconnect(game.switch_session)
	overlay.session_started.connect(func(): starts.count += 1)
	await click(card.primary)
	check(starts.count == 1 and not overlay.visible and not game.core.query("episode").victory,"Begin starts the pending native episode once and closes the card")
	# The retry/menu handlers are observed rather than changing the paused backdrop during this visible fixture.
	var actions := {"menu":0,"retry":""}
	overlay.main_menu_requested.disconnect(game.return_to_start)
	overlay.restart_requested.disconnect(game.load_game)
	overlay.main_menu_requested.connect(func(): actions.menu += 1)
	overlay.restart_requested.connect(func(path): actions.retry = path)
	overlay.show_result({"victory":false})
	await frames()
	check(card.mode == "defeat" and not card.get_node("%GoalsPanel").visible and not card.secondary.disabled,"defeat keeps the real episode-start retry available")
	await capture("defeat")
	await click(card.secondary)
	check(actions.retry == overlay.restart_path() and FileAccess.file_exists(actions.retry),"Restart requests only the native scratch episode-start save")
	card.show_complete({"title":next.title,"complete":episode.complete})
	await frames()
	check(card.mode == "complete" and not card.get_node("%GoalsPanel").visible and card.primary.text == card.tr("Main menu"),"campaign end retains full closing text and Main menu")
	await capture("complete")
	await click(card.primary)
	check(actions.menu == 1,"Main menu callback is retained")
	check(FileAccess.get_sha256(fixture) == saved_hash,"reviewing campaign panels does not overwrite the city copy")
	game.core.simulation.close_city()
	game.core.simulation = null
	game.queue_free()
	await frames(12)
	# The same authored card also serves the first briefing in the start menu.
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(20)
	menu.open_adventures()
	await frames(20)
	for i in menu.listing.size():
		if str(menu.listing[i].ref).contains("#The Birth of Atlantis"):
			menu.navigation.adventure_pager.select_index(i)
			menu.show_adventure(i)
			break
	await frames(20)
	await click(menu.adventure_start)
	check(menu.page == "intro" and menu.intro_card.secondary.visible and menu.intro_card.phase.text == menu.tr("Adventure briefing"),"first main-menu briefing reuses the new card and retains Back")
	root.get_node("UiAccess").apply(125,130)
	DisplayServer.window_set_size(Vector2i(1280,720))
	await frames(25)
	var menu_panel: Control = menu.intro_card.get_parent()
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(menu_panel.get_global_rect()) and menu_panel.get_global_rect().encloses(menu.intro_back.get_global_rect()) and menu_panel.get_global_rect().encloses(menu.intro_begin.get_global_rect()),"enlarged first briefing keeps Back, Begin and difficulty inside the viewport")
	await capture("menu-briefing")
	await click(menu.intro_back)
	check(menu.page == "adventures" and menu.opened == null,"first-briefing Back releases native ownership and returns to selected adventure")
	menu.queue_free()
	await frames(12)
	print("EPISODE_PANEL_VALIDATION ","PASS" if okay else "FAIL"," checks=",checks," language=",language)
	quit(0 if okay else 1)
