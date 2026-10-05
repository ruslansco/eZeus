extends SceneTree
# Actual start-menu scene, parsed pointer/keyboard input, real native templates, disposable preferences.
var menu: Control
var language := "en"
var checks := 0
var okay := true
func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_menu_review", true)
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("ADVENTURE_UI_CHECK ", "PASS " if value else "FAIL ", description)
func frames(count := 8) -> void:
	for i in count: await process_frame
func settle() -> void:
	var until := Time.get_ticks_msec() + 10000
	while menu.preview_busy and Time.get_ticks_msec() < until:
		await process_frame
	await frames()
func click(button: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
	await frames()
func key(code: int) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
	await frames()
func choose(ref_part: String) -> void:
	for i in menu.listing.size():
		if String(menu.listing[i].ref).contains(ref_part):
			menu.adventure_list.select(i)
			menu.adventure_list.ensure_current_is_visible()
			menu.adventure_list.item_selected.emit(i)
			await settle()
			return
	check(false,"requested native adventure found: " + ref_part)
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/adventure-card-%s-%s.png" % [language,name])
func bounds(description: String) -> void:
	var page: Control = menu.get_node("%AdventurePage")
	var card: Control = menu.get_node("%AdventureDetail")
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(page.get_global_rect()), description + ": page fits viewport")
	check(page.get_global_rect().encloses(card.get_global_rect()) and card.position.x > menu.adventure_list.get_parent().position.x, description + ": card stays to the right")
	check(page.get_global_rect().encloses(menu.adventure_start.get_global_rect()) and menu.adventure_scroll.size.y >= 80, description + ": Start and scrollable details remain usable")
func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=",1)
	Engine.set_meta("ezeus_language",language)
	var leaders = load("res://scripts/leaders.gd")
	leaders.create("Card Review")
	leaders.set_current("Card Review")
	DisplayServer.window_set_size(Vector2i(1600,1000))
	menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(20)
	await click(menu.new_game_button)
	await settle()
	check(menu.page == "adventures" and menu.adventure_image.texture != null, "New game opens the illustrated library")
	check(menu.opened == null and not Engine.has_meta("ezeus_simulation"), "selection adopts no live city")
	check(menu.adventure_goals.get_child_count() == menu.card_preview.episode.goals.size(), "all native opening objectives appear")
	bounds("default interface")
	await capture("campaign")
	var before: String = menu.adventure_title.text
	menu.adventure_list.grab_focus()
	await key(KEY_DOWN)
	await settle()
	check(menu.adventure_title.text != before and menu.adventure_title.text == menu.listing[menu.adventure_list.get_selected_items()[0]].title, "arrow-key selection refreshes the card")
	await choose("#The Birth of Atlantis")
	check(menu.adventure_image.texture != null and String(menu.adventure_art.loaded_paths.get(int(menu.card_preview.bitmap),"")).begins_with("interface.e:"), "Poseidon campaign uses its packed native illustration")
	await capture("atlantis")
	await choose("}Open Play Sandbox.pak")
	check(menu.card_preview.sandbox and menu.adventure_mode.text == menu.tr("Sandbox · Open play") and menu.adventure_goals.get_child_count() == 0 and menu.adventure_empty_goals.visible, "sandbox is explicit and has no invented objectives")
	await capture("sandbox")
	await choose("The Founding of Athens")
	var reader: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var expected: Dictionary = reader.adventure_preview(menu.engine,menu.listing[menu.adventure_list.get_selected_items()[0]].kind,menu.listing[menu.adventure_list.get_selected_items()[0]].ref,language)
	check(menu.card_preview.episode.goals == expected.episode.goals, "folder campaign shows its real first goals")
	var entries: int = menu.adventure_previews.size()
	menu.show_adventure(menu.adventure_list.get_selected_items()[0])
	await settle()
	check(menu.adventure_previews.size() == entries and not menu.preview_busy, "revisiting a selection uses its cached preview")
	await click(menu.adventure_start)
	await frames(20)
	check(menu.page == "intro" and menu.opened != null and menu.intro_goals.get_child_count() == expected.episode.goals.size(), "Start retains the native briefing and objectives")
	menu.intro_card.difficulty_up.pressed.emit()
	check(menu.opened.command("difficulty").value == menu.intro_card.difficulty, "difficulty still goes to native campaign")
	await click(menu.intro_back)
	await settle()
	check(menu.page == "adventures" and menu.opened == null and menu.adventure_title.text == menu.listing[menu.adventure_list.get_selected_items()[0]].title, "briefing Back preserves selected card and frees city")
	for size in [Vector2i(1280,800),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size)
		root.get_node("UiAccess").apply(125,130)
		await frames(20)
		bounds("125%% interface / 130%% text at %s" % str(size))
		await capture("large-%d" % size.y)
	root.get_node("UiAccess").apply(100,100)
	await frames()
	await key(KEY_ESCAPE)
	check(menu.page == "main", "Escape returns to main page")
	menu.open_adventures(true)
	await settle()
	check(menu.new_row.visible and menu.adventure_start.text == menu.tr("Edit") and menu.get_node("%AdventureDetail").visible, "editor entry keeps its original controls alongside card")
	menu.show_page("main")
	menu.queue_free()
	await frames(10)
	print("ADVENTURE_UI_VALIDATION ", "PASS" if okay else "FAIL", " checks=",checks," language=",language)
	quit(0 if okay else 1)
