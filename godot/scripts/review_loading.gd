extends SceneTree
# Real menu transitions with disposable saves/settings and ordinary GUI input.
var loading_script: GDScript
var menu: Control
var language := "en"
var checks := 0
var okay := true
var fixture := ""
var fixture_hash := ""
const Leaders = preload("res://scripts/leaders.gd")
const SaveFiles = preload("res://scripts/save_files.gd")

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	Engine.set_meta("ezeus_menu_review", true)
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("LOADING_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 8) -> void:
	for i in count:
		await process_frame

func click(button: Control) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		event.set_meta("review_input", true)
		root.push_input(event, true)
		if pressed:
			await frames(2)

func capture(name: String) -> void:
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png("res://captures/loading-%s-%s.png" % [language, name])

func wait_for_menu() -> void:
	var deadline := Time.get_ticks_msec() + 90000
	while (current_scene == null or current_scene.scene_file_path != "res://ui/start_menu.tscn") and Time.get_ticks_msec() < deadline:
		await process_frame
	menu = current_scene
	await frames(12)

func transition(button: Control, name: String) -> Node:
	var old_menu := menu
	await click(button)
	var probe_deadline:=Time.get_ticks_msec()+45000
	while loading_script.current(self)==null and old_menu.entering_city and Time.get_ticks_msec()<probe_deadline:
		await process_frame
	var loading: CanvasLayer = loading_script.current(self)
	check(loading != null and current_scene == old_menu, name + ": screen appears before scene change")
	if loading == null:
		return null
	check(old_menu.entering_city and old_menu.process_mode == Node.PROCESS_MODE_DISABLED, name + ": menu input is held")
	var pending: Variant = Engine.get_meta("ezeus_load", "")
	old_menu.load_save(fixture)
	old_menu.go_city()
	check(loading_script.current(self) == loading and Engine.get_meta("ezeus_load", "") == pending, name + ": repeated actions preserve one transition and its chosen session")
	var page: String = old_menu.page
	for pressed in [true, false]:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = pressed
		escape.set_meta("review_input", true)
		root.push_input(escape, true)
	check(old_menu.page == page and loading_script.current(self) == loading, name + ": Escape cannot cancel or change the pending handoff")
	await process_frame
	capture(name)
	check(loading.surface.get_global_rect().encloses(Rect2(Vector2.ZERO, root.get_visible_rect().size)) and Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(loading.column.get_global_rect()), name + ": full screen and bounded content at current sizes")
	check(loading.heading.text == menu.tr("Loading your city") and loading.status.text == menu.tr("Preparing your city…") and not loading.back.visible, name + ": translated loading title and truthful status")
	var deadline := Time.get_ticks_msec() + 90000
	var held_ready_city := false
	while loading_script.current(self) != null and Time.get_ticks_msec() < deadline:
		if current_scene != null and current_scene.scene_file_path == "res://main.tscn":
			held_ready_city = held_ready_city or (not current_scene.state.is_empty() and current_scene.process_mode == Node.PROCESS_MODE_DISABLED)
		await process_frame
	var city: Node = current_scene
	if loading_script.current(self) != null:
		print("LOADING_PENDING ", name, " scene=", city.scene_file_path if city != null else "none", " status=", loading.status.text, " failed=", loading.failed)
	check(held_ready_city, name + ": city stays held after its full native snapshot is built")
	check(loading_script.current(self) == null and city != null and city.scene_file_path == "res://main.tscn" and not city.state.is_empty() and city.process_mode == Node.PROCESS_MODE_INHERIT, name + ": screen clears and city processing resumes")
	if city == null or city.scene_file_path != "res://main.tscn":
		return null
	city.core.set_process(false)
	check(city.state.paused and city.hud.visible and city.tiles.size() == city.state.tiles.size(), name + ": native pause, full terrain and HUD are ready")
	check(not Engine.has_meta("ezeus_load") and not Engine.has_meta("ezeus_simulation"), name + ": handoff consumed once")
	return city

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="):
			language = argument.get_slice("=", 1)
	Engine.set_meta("ezeus_language", language)
	loading_script = load("res://ui/loading_screen.gd")
	Leaders.create("Loading Review")
	Leaders.set_current("Loading Review")
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	fixture = SaveFiles.directory().path_join("Loading review.ez")
	check(DirAccess.copy_absolute(source, fixture) == OK, "designated city copied into disposable leader folder")
	fixture_hash = FileAccess.get_sha256(fixture)
	DisplayServer.window_set_size(Vector2i(1600, 1000) if language == "en" else Vector2i(1280, 720))
	if language == "ru":
		root.get_node("UiAccess").apply(125, 130)
	menu = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	await frames(20)
	menu.load_save(fixture + ".missing")
	check(loading_script.current(self) == null and not menu.entering_city, "missing file leaves menu available without a stuck loading screen")
	var city: Node = await transition(menu.continue_button, "continue")
	if city == null:
		quit(1)
		return
	check(city.tiles.size() == 25992, "Continue opens the complete designated city")
	capture("city")
	city.return_to_start()
	await wait_for_menu()
	menu.open_saves()
	await frames()
	city = await transition(menu.load_open, "load-save")
	if city == null:
		quit(1)
		return
	check(city.tiles.size() == 25992 and FileAccess.get_sha256(fixture) == fixture_hash, "selected Load save preserves the same complete city and its source bytes")
	city.return_to_start()
	await wait_for_menu()
	menu.open_adventures()
	menu.navigation.adventure_pager.select_index(0)
	await frames()
	menu.start_adventure()
	var deadline := Time.get_ticks_msec() + 30000
	while menu.page != "intro" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(menu.page == "intro" and menu.opened != null, "new adventure opens its native introduction")
	if menu.opened == null:
		quit(1)
		return
	var opened: RefCounted = menu.opened
	city = await transition(menu.intro_begin, "new-game")
	if city == null:
		quit(1)
		return
	check(city.core.simulation == opened and FileAccess.file_exists(SaveFiles.directory().path_join("autosave replay.ez")), "Begin adopts the same simulation and keeps the native retry save")
	city.return_to_start()
	await wait_for_menu()
	# Exercise the recovery controls without manufacturing a corrupt native campaign.
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	var loading: CanvasLayer = loading_script.open(self)
	var access: Node = root.get_node("UiAccess")
	access.reduced_motion = true
	var phase: float = loading.phase
	await frames()
	check(loading.phase == phase, "Reduce interface motion holds the activity indicator still")
	access.reduced_motion = false
	loading.fail(func(): menu.process_mode = Node.PROCESS_MODE_INHERIT)
	await frames()
	check(loading.failed and loading.back.visible and loading.heading.text == menu.tr("The city could not be loaded") and root.gui_get_focus_owner() == loading.back, "failure gives a translated, focused return action")
	capture("failure")
	await click(loading.back)
	await frames()
	check(loading_script.current(self) == null and menu.process_mode == Node.PROCESS_MODE_INHERIT, "failure recovery dismisses the screen and restores menu input")
	check(FileAccess.get_sha256(fixture) == fixture_hash, "all transitions preserve the disposable source save")
	print("LOADING_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks, " language=", language)
	quit(0 if okay else 1)
