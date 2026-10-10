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
			menu.navigation.adventure_pager.select_index(i)
			menu.adventure_list.ensure_current_is_visible()
			await settle()
			return
	check(false,"requested native adventure found: " + ref_part)
func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true,.016)
	root.get_texture().get_image().save_png("res://captures/adventure-card-%s-%s.png" % [language,name])
func all_goals_visible(goals: Container, area: Control) -> bool:
	return goals.get_children().all(func(row): return row.is_visible_in_tree() and area.get_global_rect().grow(1).encloses(row.get_global_rect()))
func contrast(ink: Color, surface: Color) -> float:
	var foreground := ink.srgb_to_linear().get_luminance()
	var background := surface.srgb_to_linear().get_luminance()
	return (maxf(foreground,background)+.05)/(minf(foreground,background)+.05)
func button_text_fits(button: Button) -> bool:
	var font := button.get_theme_font("font")
	var font_size := button.get_theme_font_size("font_size")
	var space := button.size - button.get_theme_stylebox("normal").get_minimum_size()
	return font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= space.x+1 and font.get_height(font_size) <= space.y+1
func briefing_bounds(description: String) -> void:
	var page: Control = menu.get_node("%IntroPage")
	var frame := page.get_global_rect()
	# The inner walnut area excludes the crest, carved corners and lower gold rail.
	var reading := frame.grow_individual(-frame.size.x*.075,-frame.size.y*.155,-frame.size.x*.075,-frame.size.y*.095)
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(frame),description+": frame stays on screen")
	check([menu.intro_card.heading,menu.intro_card.subtitle,menu.intro_card.episode_progress,menu.intro_card.difficulty_row,menu.intro_back,menu.intro_begin].all(func(control): return not control.is_visible_in_tree() or reading.encloses(control.get_global_rect())),description+": story header and footer stay inside the wood, clear of the frame")
	check(button_text_fits(menu.intro_back) and button_text_fits(menu.intro_begin),description+": complete footer labels fit their clean padded controls")
	check(all_goals_visible(menu.intro_goals,menu.intro_card.goal_scroll),description+": every objective is visible together")
	check(menu.intro_card.get_node("%GoalsPanel").find_children("*","Button",true,false).is_empty(),description+": objectives have no paging buttons")
func bounds(description: String) -> void:
	var page: Control = menu.get_node("%AdventurePage")
	var card: Control = menu.get_node("%AdventureDetail")
	if not Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(page.get_global_rect()):
		print("ADVENTURE_UI_BOUNDS ",page.get_global_rect()," minimum ",page.get_combined_minimum_size()," viewport ",root.get_visible_rect())
		for control in [card,menu.adventure_list.get_parent(),menu.adventure_scroll,menu.adventure_goals.get_parent()]:
			print("ADVENTURE_UI_BOUNDS ",control.name," ",control.size," minimum ",control.get_combined_minimum_size())
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(page.get_global_rect()), description + ": page fits viewport")
	check(page.get_global_rect().encloses(card.get_global_rect()) and card.position.x > menu.adventure_list.get_parent().position.x, description + ": card stays to the right")
	check(page.get_global_rect().encloses(menu.adventure_start.get_global_rect()) and menu.adventure_scroll.size.y >= 80, description + ": Start and paged details remain usable")
	check(button_text_fits(menu.adventure_start) and button_text_fits(menu.adventure_back),description+": Start and Back labels fit their padded controls")
	if not menu.adventure_goals.get_children().is_empty():
		check(all_goals_visible(menu.adventure_goals,menu.adventure_scroll), description + ": every objective is visible without scrolling")
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
	var surface: StyleBox = menu.adventure_scroll.get_parent().get_theme_stylebox("panel")
	check(surface is StyleBoxFlat and surface.bg_color.get_luminance() < .2,"adventure preview uses a dark bronze-edged surface without parchment")
	check(contrast(menu.adventure_text.get_theme_color("font_color"),surface.bg_color) >= 7 and contrast(menu.theme.get_color("font_color","AdventureGoalText"),surface.bg_color) >= 7 and contrast(menu.get_node("%AdventureGoalsHeading").get_theme_color("font_color"),surface.bg_color) >= 7,"preview description, objectives and heading have strong readable contrast")
	check(menu.opened == null and not Engine.has_meta("ezeus_simulation"), "selection adopts no live city")
	check(menu.adventure_goals.get_child_count() == menu.card_preview.episode.goals.size(), "all native opening objectives appear")
	var count := int(menu.card_preview.get("episode_total", 1))
	var parents := int(menu.card_preview.episode.get("episode_count", 1))
	var colonies := count - parents
	var expected_episodes := menu.tr("%d main episodes · %d colony scenarios") % [parents, colonies] if colonies > 0 else (menu.tr("1 episode") if count == 1 else menu.tr("%d episodes") % count)
	check(menu.adventure_episodes.text.begins_with(expected_episodes), "main episodes and alternative colony scenarios are explicit")
	bounds("default interface")
	await capture("campaign")
	var before: String = menu.adventure_title.text
	menu.adventure_list.grab_focus()
	await key(KEY_DOWN)
	await settle()
	check(menu.adventure_title.text != before and menu.adventure_title.text == menu.listing[menu.navigation.adventure_pager.selected_index].title, "arrow-key selection refreshes the card")
	await choose("#The Birth of Atlantis")
	check(menu.adventure_image.texture != null and String(menu.adventure_art.loaded_paths.get(int(menu.card_preview.bitmap),"")).begins_with("interface.e:"), "Poseidon campaign uses its packed native illustration")
	await capture("atlantis")
	await choose("}Open Play Sandbox.pak")
	check(menu.card_preview.sandbox and menu.adventure_mode.text == menu.tr("Sandbox · Open play") and menu.adventure_goals.get_child_count() == 0 and menu.adventure_empty_goals.visible, "sandbox is explicit and has no invented objectives")
	await capture("sandbox")
	await choose("The Founding of Athens")
	var reader: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var expected: Dictionary = reader.adventure_preview(menu.engine,menu.listing[menu.navigation.adventure_pager.selected_index].kind,menu.listing[menu.navigation.adventure_pager.selected_index].ref,language)
	var native_entry: Dictionary = reader.adventures(menu.engine,language).adventures.filter(func(entry): return entry.ref == "First Light Harbor")[0]
	var extensive: Dictionary = reader.adventure_preview(menu.engine,native_entry.kind,native_entry.ref,language)
	check(menu.card_preview.episode.goals == expected.episode.goals, "folder campaign shows its real first goals")
	var displayed: Array = menu.adventure_goals.get_children().map(func(row): return row.get_child(1).text)
	check(displayed == expected.episode.goals.map(func(goal): return goal.text), "goal rows retain every native quantity and wording")
	check(all_goals_visible(menu.adventure_goals,menu.adventure_scroll) and menu.adventure_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "all native objectives appear together without scrolling or page switches")

	var entries: int = menu.adventure_previews.size()
	menu.show_adventure(menu.navigation.adventure_pager.selected_index)
	await settle()
	check(menu.adventure_previews.size() == entries and not menu.preview_busy, "revisiting a selection uses its cached preview")
	await click(menu.adventure_start)
	await frames(20)
	check(menu.page == "intro" and menu.opened != null and menu.intro_goals.get_child_count() == expected.episode.goals.size(), "Start retains the native briefing and objectives")
	check("".join(menu.navigation.story_pages) == menu.navigation.story_original and menu.intro_card.scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and menu.intro_card.goal_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "briefing pagination preserves the full story and removes internal scrolling")
	check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(menu.get_node("%IntroPage").get_global_rect()), "paged briefing and Begin/Back fit the viewport")
	briefing_bounds("Athens briefing")
	await capture("briefing")
	menu.intro_card.difficulty_up.pressed.emit()
	check(menu.opened.command("difficulty").value == menu.intro_card.difficulty, "difficulty still goes to native campaign")
	await click(menu.intro_back)
	await settle()
	check(menu.page == "adventures" and menu.opened == null and menu.adventure_title.text == menu.listing[menu.navigation.adventure_pager.selected_index].title, "briefing Back preserves selected card and frees city")
	await choose("Stonewatch")
	await click(menu.adventure_start)
	await frames(20)
	briefing_bounds("Stonewatch briefing")
	check(menu.intro_card.scroll.get_parent().get_parent().get_theme_stylebox("panel") is StyleBoxTexture and menu.navigation.story_next.theme_type_variation == "ParchmentPageButton", "story retains its parchment and matching page controls")
	check(contrast(menu.navigation.story_count.get_theme_color("font_color"),Color("dbc18b")) >= 4.5,"story page numbers retain dark readable ink")
	await capture("stonewatch")
	await click(menu.intro_back)
	await settle()
	for size in [Vector2i(1280,800),Vector2i(1280,720)]:
		DisplayServer.window_set_size(size)
		root.get_node("UiAccess").apply(125,130)
		await frames(20)
		bounds("125%% interface / 130%% text at %s" % str(size))
		await capture("large-%d" % size.y)
		await click(menu.adventure_start)
		await frames(20)
		var briefing: Control = menu.get_node("%IntroPage")
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(briefing.get_global_rect()) and briefing.get_global_rect().encloses(menu.intro_begin.get_global_rect()),"enlarged briefing keeps Begin and Back on screen at "+str(size))
		briefing_bounds("Enlarged Stonewatch "+str(size))
		var readable := true
		for part in menu.navigation.story_pages.size():
			menu.navigation.story_page = part; menu.navigation.show_intro_story()
			await frames()
			readable = readable and menu.intro_text.size.y <= menu.intro_card.scroll.size.y
		check(readable and "".join(menu.navigation.story_pages) == menu.navigation.story_original,"all enlarged briefing pages fit and preserve the complete story")
		menu.navigation.story_page = 0; menu.navigation.show_intro_story()
		await frames()
		await capture("briefing-large-%d" % size.y)
		if size.y == 720:
			menu.intro_card.fill_goals(extensive.episode.goals,false)
			menu.navigation.fit_intro(menu.get_viewport_rect().size)
			await menu.navigation.paginate_intro()
			await frames()
			check(menu.intro_goals.get_child_count() >= 7,"stress fixture uses seven real native objectives")
			briefing_bounds("Seven native objectives at enlarged 720p")
			var full_pages: bool = menu.navigation.story_pages.size() < 50
			for part in menu.navigation.story_pages.size():
				menu.navigation.story_page = part; menu.navigation.show_intro_story(); await frames()
				full_pages = full_pages and menu.intro_text.get_minimum_size().y <= menu.navigation.story_slot.size.y+1
			check(full_pages and "".join(menu.navigation.story_pages) == menu.navigation.story_original,"seven objectives leave a readable story area with complete fitting pages")
			menu.navigation.story_page = 0; menu.navigation.show_intro_story(); await frames()
			await capture("seven-objectives")
		await click(menu.intro_back)
		await settle()
	root.get_node("UiAccess").apply(100,100)
	await frames()
	await key(KEY_ESCAPE)
	check(menu.page == "main", "Escape returns to main page")
	menu.open_adventures()
	var initial_preview: Dictionary = menu.card_preview.duplicate(true)
	menu.show_adventure(menu.listing.size()-1)
	menu.show_adventure(0)
	await settle()
	await create_timer(.15).timeout
	check(menu.adventure_title.text == menu.listing[0].title and menu.card_preview == initial_preview, "rapid selections discard stale preview work")
	menu.show_page("main")
	await frames(12)
	check(menu.opened == null and not Engine.has_meta("ezeus_simulation"), "leaving the library creates no city or adopted session")
	menu.open_adventures(true)
	await settle()
	check(menu.new_row.visible and menu.adventure_start.text == menu.tr("Edit") and menu.get_node("%AdventureDetail").visible, "editor entry keeps its original controls alongside card")
	menu.show_page("main")
	menu.queue_free()
	await frames(10)
	print("ADVENTURE_UI_VALIDATION ", "PASS" if okay else "FAIL", " checks=",checks," language=",language)
	quit(0 if okay else 1)
