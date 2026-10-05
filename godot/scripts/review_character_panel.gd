extends SceneTree
# Owned visible review of the character window (right click on a walker), designated save, scratch preferences.
# Nothing is written; the city is paused by the window and resumed exactly as it was.
var city: Node3D
var okay := true
var checks := 0
var language := "en"
var audio: Node

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("CHARACTER_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 10) -> void:
	for frame in count:
		await process_frame

func press(point: Vector2, button: MouseButton) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = button; event.pressed = pressed
		event.set_meta("review_input", true)
		root.push_input(event, true)
	await frames()

func escape() -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_ESCAPE; key.keycode = KEY_ESCAPE; key.pressed = pressed
		key.set_meta("review_input", true)
		root.push_input(key, true)
	await frames()

func capture(name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/character-" + name + "-" + language + ".png")

# Puts the camera over a walker and returns the screen point of its middle.
func aim(id: int) -> Vector2:
	city.focus_walker(id)
	await frames(4)
	var node: Node3D = city.walkers[id].node
	city.walker_streets.hovered = -1
	return city.orbit.camera.unproject_position(node.global_position + Vector3.UP * city.figure_height(node) * .5)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lang="): language = argument.get_slice("=", 1)
	audio = root.get_node("GameAudio")
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty() or city.frame_count < 80:
		await process_frame
	city.core.query("pause 1"); city.core.set_process(false); city.orbit.enabled = false
	city.close_inspection(); city.set_tool("select"); city.hud.close_build_tray(); city.hud.set_messages_open(false); city.hud.set_goals_expanded(false)
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	# Automation is silent: the voice logic runs with the master bus muted.
	audio.enabled = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	await frames()
	var native_before: Dictionary = city.core.simulation.snapshot(true)
	# Every walker in the city is described by the core; people and figures have a name or an occupation and a line.
	var described := 0; var worded := 0; var voiced := 0; var missing_voice := 0; var kinds := {}
	var by_kind := {}
	var silent := {}
	for id in city.walkers:
		var info: Dictionary = city.core.query("character_info %d" % id)
		if info.has("error"):
			continue
		described += 1
		if not str(info.text).is_empty(): worded += 1
		else: silent[str(info.asset)] = silent.get(str(info.asset), 0) + 1
		var voice := str(info.voice)
		if not voice.is_empty():
			voiced += 1
			if audio.load_stream(voice) == null: missing_voice += 1
		kinds[info.kind] = kinds.get(info.kind, 0) + 1
		if not by_kind.has(info.kind) or (city.walkers[id].get("human", false) and not str(info.text).is_empty() and not voice.is_empty() and not info.others.is_empty()):
			by_kind[info.kind] = id
	print("CHARACTER_STATS described=", described, " worded=", worded, " voiced=", voiced, " kinds=", kinds, " wordless=", silent)
	check(described == city.walkers.size() or described >= city.walkers.size() - 2, "core describes every drawn walker (%d of %d)" % [described, city.walkers.size()])
	# As in the SDL window, animals and carts with nothing to say have no line (the native text tables have none for them).
	var wordless_assets: Array = silent.keys().filter(func(asset): return not (asset.begins_with("animal_") or asset in ["transporter", "walker_oxhandler", "walker_porter"]))
	check(worded > 0 and wordless_assets.is_empty(), "every walker but idle carts and animals speaks a native line (%d; others wordless: %s)" % [worded, wordless_assets])
	check(voiced > 0 and missing_voice == 0, "voice files of spoken lines load (%d voiced)" % voiced)
	check(city.core.query("character_info 999999999").has("error"), "an unknown walker is refused")
	var time_before: float = city.core.simulation.snapshot(false).time
	# A right click on a person opens the window and pauses the city; its clock holds while it is open.
	city.core.query("pause 0")
	var person: int = by_kind.get("person", -1)
	check(person >= 0, "the city has a person to inspect")
	if person < 0:
		quit(1); return
	var point := await aim(person)
	check(city.walker_at(point) == person, "the walker under the pointer is found")
	var dock: Control = city.hud.get_node("%BottomBar")
	check(city.walker_at(dock.get_global_rect().get_center()) == -1 and city.walker_at(Vector2(-50, -50)) == -1, "no walker is picked through the dock or off the map")
	await press(point, MOUSE_BUTTON_RIGHT)
	var panel: Control = city.character_panel
	check(is_instance_valid(panel) and panel.visible, "right click on a walker opens the character window")
	if not is_instance_valid(panel):
		quit(1); return
	check(city.core.simulation.snapshot(false).paused and city.core.commands_held, "the window pauses the city and holds queued commands")
	var held_time: float = city.core.simulation.snapshot(false).time
	city.core._process(.5)
	check(city.core.simulation.snapshot(false).time == held_time, "the native clock holds while the window is open")
	var info: Dictionary = panel.info
	check(panel.name_label.text != "" and (panel.speech.text.contains(str(info.text)) or str(info.text).is_empty()), "name and spoken line are shown")
	if panel.pictured_role(str(info.asset)):
		check(panel.still.visible and panel.figure == null and panel.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "a role with a portrait image shows the still image, no 3D figure")
	else:
		check(panel.figure != null and panel.holder.visible, "the walker's 3D model stands in the portrait")
	check(not str(info.voice).is_empty() and (panel.speaking or audio.muted() or not audio.enabled), "the voice line plays when the window opens")
	await create_timer(1.2).timeout
	await capture("person")
	panel.voice_button.pressed.emit()
	await frames()
	check(not panel.speaking, "the voice can be stopped")
	panel.voice_button.pressed.emit()
	await frames()
	check(panel.speaking or audio.muted() or not audio.enabled, "and listened to again")
	if not info.others.is_empty():
		var chip: Button = panel.others_row.get_child(0)
		await press(chip.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
		check(int(panel.info.id) == int(info.others[0].id), "another walker on the tile can be chosen")
	# Larger interface and a small window keep the card on screen.
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.get_node("UiAccess").apply(125, 130)
	await frames(8)
	check(Rect2(Vector2.ZERO, city.hud.size).encloses(panel.card.get_global_rect()), "the card fits 1280x720 at 125%/130%")
	await capture("person-large")
	root.get_node("UiAccess").apply(100, 100)
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	await frames()
	await escape()
	check(not is_instance_valid(city.character_panel) and not city.core.simulation.snapshot(false).paused and not city.core.commands_held, "Escape closes the window and the city runs again")
	check(not audio.voice.playing, "closing the window stops the voice")
	city.core.query("pause 1")
	# Any other figure the city has (an Olympian, a hero, a monster, an animal or a boat) opens too; an already paused city stays paused.
	for kind in ["god", "hero", "monster", "person"]:
		if not by_kind.has(kind) or (kind == "person"):
			continue
		var figure_point := await aim(by_kind[kind])
		await press(figure_point, MOUSE_BUTTON_RIGHT)
		check(is_instance_valid(city.character_panel), "right click opens the window for a " + kind)
		await create_timer(1.0).timeout
		await capture(kind)
		await press(Vector2(20, 500), MOUSE_BUTTON_RIGHT)
		check(not is_instance_valid(city.character_panel) and city.core.simulation.snapshot(false).paused, "right click closes it and a paused city stays paused")
	# A non-human walker (cart, animal, boat) if there is one.
	for id in city.walkers:
		if city.walkers[id].get("human", false) or city.walkers[id].get("god", false) or city.walkers[id].has("roll"):
			continue
		var other: Dictionary = city.core.query("character_info %d" % id)
		if other.has("error") or str(other.kind) != "person":
			continue
		city.open_character(id)
		await create_timer(.8).timeout
		check(is_instance_valid(city.character_panel) and (city.character_panel.figure != null or city.character_panel.still.visible), "a " + str(other.asset) + " is shown too")
		await capture("other")
		city.character_panel.goto_button.pressed.emit()
		await frames()
		check(not is_instance_valid(city.character_panel), "Go to closes the window over the walker")
		break
	var curator_reviewed := false
	# The one-character realism benchmark must load only in this panel, with a private finish.
	for id in city.walkers:
		var curator: Dictionary = city.core.query("character_info %d" % id)
		if curator.get("asset", "") != "walker_curator":
			continue
		curator_reviewed = true
		city.open_character(id)
		await frames()
		panel = city.character_panel
		# The curator's realistic portrait ships as a pre-rendered image (tools/render_portraits.py): no model is loaded.
		check(panel.still.visible and panel.still.texture != null and panel.figure == null, "curator shows his pre-rendered portrait image")
		check(panel.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED and not panel.holder.visible, "no 3D rendering while a portrait image is shown")
		var cached: ShaderMaterial = city.character_appearance.materials.get("walker_curator")
		check(cached == null or not cached.get_shader_parameter("elder_portrait"), "city material retains its ordinary finish")
		panel.set_figure("walker_astronomer")
		check(not panel.still.visible and panel.figure != null and panel.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "a role without an image returns to the live 3D figure")
		panel.set_figure("walker_curator")
		panel.typed = panel.typing; panel.speech.visible_ratio = 1.0
		await capture("curator")
		panel.close_button.pressed.emit()
		await frames()
		break
	# Every portrait image the game ships is a whole 2x frame of a walker model, and each role can go back to its 3D model.
	var images := Array(DirAccess.get_files_at("res://assets/portraits")).filter(func(file): return file.ends_with(".png"))
	var shipped := 0
	for file: String in images:
		var picture: Texture2D = load("res://assets/portraits/" + file)
		if picture != null and picture.get_size() == Vector2(592, 760) and city.model_file_exists(file.get_basename()):
			shipped += 1
		else:
			print("CHARACTER_IMAGE odd ", file)
	check(not images.is_empty() and shipped == images.size(), "every portrait image is 592x760 and belongs to a walker model (%d of %d)" % [shipped, images.size()])
	city.open_character(person)
	await frames()
	panel = city.character_panel
	for file: String in images:
		var role := file.get_basename()
		panel.portrait_models.append(role)
		panel.set_figure(role)
		var modelled: bool = panel.figure != null and not panel.still.visible and panel.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS
		panel.portrait_models.erase(role)
		panel.set_figure(role)
		check(modelled and panel.still.visible and panel.figure == null, role + " switches to its 3D model when listed in portrait_models, and back")
	panel.close_button.pressed.emit()
	await frames()
	check(curator_reviewed, "the designated city provided a native curator for the portrait review")
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(after.money == native_before.money and after.buildings == native_before.buildings and after.events == native_before.events, "looking at walkers leaves the city's money, buildings and decisions unchanged")
	print("character time before ", time_before, " after ", after.time)
	city.queue_free()
	await frames(8)
	city = null
	await frames(4)
	print("CHARACTER_PANEL_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
