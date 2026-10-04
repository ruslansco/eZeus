extends SceneTree
# The controls and play settings (headless, scratch settings files only): the table of rebindable controls has the defaults the game always had;
# a key is assigned, swapped with the control that had it, refused when it is reserved or carries a modifier a control cannot take, put back, and
# remembered in the player's settings file (never the original game's), which a damaged or hand-edited file cannot break; the held camera keys follow
# in the InputMap; the Controls and Game settings dialogs do all of that through their own rows; autosave, voices, fullscreen and the camera's pace
# take their options from the settings; everything the dialogs say is translated.
const KeyBindings = preload("res://scripts/key_bindings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")
const Settings = preload("res://scripts/user_settings.gd")
const Overlays = preload("res://scripts/overlays.gd")
const ControlsDialog = preload("res://ui/controls_dialog.gd")
const GameSettingsDialog = preload("res://ui/game_settings_dialog.gd")
const Orbit = preload("res://scripts/orbit_camera.gd")

var okay := true
var checks := 0
var scratch := ""

const DEFAULTS := {"orbit_left": KEY_Q, "orbit_right": KEY_E, "tilt_up": KEY_R, "tilt_down": KEY_F, "pan_forward": KEY_W, "pan_back": KEY_S, "pan_left": KEY_A, "pan_right": KEY_D,
	"camera_home": KEY_HOME, "turn_placement": KEY_T, "demolish": KEY_X, "undo": KEY_Z | KEY_MASK_CTRL, "pause": KEY_SPACE, "quick_save": KEY_F5, "quick_load": KEY_F9,
	"world_map": KEY_F2, "army": KEY_F4, "mythology": KEY_F6, "city": KEY_F7, "mute": KEY_M, "details": KEY_F3,
	"overlay_normal": KEY_0, "overlay_water": KEY_1, "overlay_supplies": KEY_2, "overlay_hygiene": KEY_3, "overlay_hazards": KEY_4, "overlay_appeal": KEY_5,
	"overlay_taxes": KEY_6, "overlay_unrest": KEY_7, "overlay_security": KEY_8, "overlay_roads": KEY_9, "overlay_problems": KEY_TAB, "overlay_normal_alt": KEY_QUOTELEFT}

func check(value: bool, message: String) -> void:
	checks += 1
	print("CONTROLS_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func key_event(key: int, modifiers := 0, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key as Key
	event.pressed = pressed
	event.ctrl_pressed = bool(modifiers & KEY_MASK_CTRL)
	event.alt_pressed = bool(modifiers & KEY_MASK_ALT)
	event.shift_pressed = bool(modifiers & KEY_MASK_SHIFT)
	return event

func has_cyrillic(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x0400 and code <= 0x04FF:
			return true
	return false

# Points the settings at a fresh scratch file and forgets what was read.
func fresh_settings(name: String) -> String:
	var path := scratch.path_join(name)
	DirAccess.remove_absolute(path)
	Engine.set_meta("ezeus_settings_path", path)
	KeyBindings.reload()
	PlaySettings.reload()
	return path

func stored(path: String, section: String, key: String) -> Variant:
	var file := ConfigFile.new()
	if file.load(path) != OK or not file.has_section_key(section, key):
		return null
	return file.get_value(section, key)

func run() -> void:
	scratch = ProjectSettings.globalize_path("res://captures/validation-controls-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var player_file := Settings.path()
	var player_before := FileAccess.get_sha256(player_file) if FileAccess.file_exists(player_file) else ""

	# ------------------------------------------------------------------------------------------------ the defaults
	if Engine.has_meta("ezeus_settings_path"):
		Engine.remove_meta("ezeus_settings_path")
	KeyBindings.reload()
	PlaySettings.reload()
	check(not KeyBindings.uses_player_settings(), "automation sees the defaults and never the player's settings")
	var wrong: Array = []
	for id in DEFAULTS:
		if KeyBindings.code(id) != int(DEFAULTS[id]):
			wrong.append(id)
	check(wrong.is_empty() and KeyBindings.actions().size() == DEFAULTS.size() + 1, "the table has the defaults the game always had (%d controls, plus Alt+Enter for fullscreen) %s" % [DEFAULTS.size(), str(wrong)])
	var seen := {}
	var duplicated: Array = []
	var illegal: Array = []
	for entry in KeyBindings.actions():
		if seen.has(KeyBindings.code(entry.id)):
			duplicated.append(entry.id)
		seen[KeyBindings.code(entry.id)] = true
		if not KeyBindings.problem(entry.id, KeyBindings.code(entry.id)).is_empty():
			illegal.append(entry.id)
	check(duplicated.is_empty() and illegal.is_empty(), "no two controls share a key and every default is allowed %s %s" % [str(duplicated), str(illegal)])
	var hotkeys := Overlays.hotkeys()
	var agree := true
	for code in hotkeys:
		agree = agree and KeyBindings.code("overlay_" + str(hotkeys[code])) == int(code)
	check(agree and hotkeys.size() == 11 and KeyBindings.code("overlay_normal") == KEY_0, "the overlay keys are the overlay table's own (%d)" % hotkeys.size())
	KeyBindings.apply_input_map()
	var held_ok := true
	for id in KeyBindings.HELD:
		var events := InputMap.action_get_events(id)
		held_ok = held_ok and events.size() == 1 and events[0] is InputEventKey and int(events[0].physical_keycode) == int(DEFAULTS[id])
	check(held_ok, "the eight held camera keys are InputMap actions with the original keys (Q E R F W A S D)")
	check(KeyBindings.label("pause") == "Space" and KeyBindings.label("quick_save") == "F5" and KeyBindings.label("turn_placement") == "T" and KeyBindings.label("undo").ends_with("+Z") and KeyBindings.label("fullscreen").ends_with("Enter"), "keys are named as printed: %s, %s, %s, %s" % [KeyBindings.label("pause"), KeyBindings.label("quick_save"), KeyBindings.label("undo"), KeyBindings.label("fullscreen")])

	# ----------------------------------------------------------------------------------------------- what an event is
	check(KeyBindings.matches(key_event(KEY_T), "turn_placement") and KeyBindings.matches(key_event(KEY_T, KEY_MASK_SHIFT), "turn_placement"), "a key matches with or without Shift")
	check(not KeyBindings.matches(key_event(KEY_T, KEY_MASK_CTRL), "turn_placement") and not KeyBindings.matches(key_event(KEY_T, KEY_MASK_ALT), "turn_placement"), "but not with Ctrl, Cmd or Alt")
	var echo := key_event(KEY_T)
	echo.echo = true
	check(not KeyBindings.matches(echo, "turn_placement") and not KeyBindings.matches(key_event(KEY_T, 0, false), "turn_placement"), "a held key's repeats and a release do not count")
	var meta_undo := key_event(KEY_Z)
	meta_undo.meta_pressed = true
	check(KeyBindings.matches(key_event(KEY_Z, KEY_MASK_CTRL), "undo") and KeyBindings.matches(meta_undo, "undo") and not KeyBindings.matches(key_event(KEY_Z), "undo"), "Undo is Ctrl or Cmd and Z, as always, and not Z alone")
	check(KeyBindings.overlay_for(key_event(KEY_1)) == "water" and KeyBindings.overlay_for(key_event(KEY_TAB)) == "problems" and KeyBindings.overlay_for(key_event(KEY_QUOTELEFT)) == "normal" and KeyBindings.overlay_for(key_event(KEY_0)) == "normal", "the digits, Tab and the back quote choose the overlays")
	check(KeyBindings.overlay_for(key_event(KEY_1, KEY_MASK_SHIFT)) == "" and KeyBindings.overlay_for(key_event(KEY_1, KEY_MASK_CTRL)) == "", "Shift or Ctrl with a digit is not an overlay")

	# --------------------------------------------------------------------------------------------- the rules of a key
	var path := fresh_settings("rules.cfg")
	check(KeyBindings.uses_player_settings() and not KeyBindings.any_custom(), "a test that points the settings at a scratch file reads them: none changed yet")
	var result := KeyBindings.assign("orbit_left", KEY_J)
	check(result.ok and str(result.swapped) == "" and KeyBindings.code("orbit_left") == KEY_J and KeyBindings.label("orbit_left") == "J", "a free key is assigned: Orbit left is J")
	var held := InputMap.action_get_events("orbit_left")
	check(held.size() == 1 and int(held[0].physical_keycode) == KEY_J, "and the held action follows in the InputMap, no longer on Q")
	check(int(stored(path, "keys", "orbit_left")) == KEY_J and stored(path, "keys", "orbit_right") == null, "it is remembered in the settings file (only what differs from the default)")
	result = KeyBindings.assign("orbit_right", KEY_J)
	check(result.ok and str(result.swapped) == "orbit_left" and KeyBindings.code("orbit_right") == KEY_J and KeyBindings.code("orbit_left") == KEY_E, "a key another control has is swapped: Orbit right takes J and Orbit left gets E")
	check(KeyBindings.owner_of(KEY_J) == "orbit_right" and KeyBindings.owner_of(KEY_E) == "orbit_left" and KeyBindings.owner_of(KEY_Q) == "", "every key still has one owner (and Q none)")
	var before := KeyBindings.code("pause")
	check(KeyBindings.assign("pause", KEY_ESCAPE).reason == "reserved" and KeyBindings.assign("pause", KEY_DELETE).reason == "reserved" and KeyBindings.assign("pause", KEY_SHIFT).reason == "reserved" and KeyBindings.code("pause") == before, "Escape, Delete and a modifier alone cannot be bound")
	check(KeyBindings.assign("pan_left", KEY_K | KEY_MASK_CTRL).reason == "modifier" and KeyBindings.assign("overlay_water", KEY_K | KEY_MASK_ALT).reason == "modifier" and KeyBindings.assign("camera_home", KEY_K | KEY_MASK_CTRL).reason == "modifier", "a held, overlay or overview key takes no Ctrl, Cmd or Alt")
	check(KeyBindings.assign("pause", KEY_P | KEY_MASK_CTRL).ok and KeyBindings.label("pause").ends_with("+P") and KeyBindings.matches(key_event(KEY_P, KEY_MASK_CTRL), "pause"), "but another control may: Pause is Ctrl or Cmd and P")
	var undo_before := KeyBindings.code("undo")
	result = KeyBindings.assign("undo", KEY_HOME)
	check(not result.ok and result.reason == "swap_refused" and str(result.swapped) == "camera_home" and KeyBindings.code("undo") == undo_before and KeyBindings.code("camera_home") == KEY_HOME, "a swap that the other control cannot take (Ctrl+Z for the plain Home key) is refused and nothing changes")
	check(KeyBindings.reset("orbit_right") and KeyBindings.code("orbit_right") == KEY_E and KeyBindings.code("orbit_left") == KEY_J, "putting a control back gives the key it takes back from whoever has it: Orbit right is E again and Orbit left J")
	KeyBindings.reset_all()
	var clean := true
	for id in DEFAULTS:
		clean = clean and KeyBindings.code(id) == int(DEFAULTS[id]) and stored(path, "keys", id) == null
	check(clean and not KeyBindings.any_custom(), "restoring all puts every default back and empties the settings file's keys")
	held = InputMap.action_get_events("orbit_left")
	check(held.size() == 1 and int(held[0].physical_keycode) == KEY_Q, "and the held keys are the originals in the InputMap")

	# -------------------------------------------------------------------------------- remembered, and a damaged file
	path = fresh_settings("remember.cfg")
	KeyBindings.assign("turn_placement", KEY_U)
	KeyBindings.assign("quick_save", KEY_F8)
	KeyBindings.reload()
	check(KeyBindings.code("turn_placement") == KEY_U and KeyBindings.code("quick_save") == KEY_F8 and KeyBindings.code("quick_load") == KEY_F9, "the choices come back the next time the settings are read")
	var damaged := ConfigFile.new()
	damaged.set_value("keys", "orbit_left", KEY_E)              # E is Orbit right's own key
	damaged.save(path)
	KeyBindings.reload()
	check(not KeyBindings.any_custom() and KeyBindings.code("orbit_left") == KEY_Q, "a file that gives one key to two controls is not believed: the defaults hold")
	damaged = ConfigFile.new()
	damaged.set_value("keys", "pause", KEY_ESCAPE)
	damaged.set_value("keys", "pan_left", KEY_K | KEY_MASK_CTRL)
	damaged.set_value("keys", "mute", "N")
	damaged.set_value("keys", "no_such_control", KEY_B)
	damaged.set_value("keys", "army", KEY_B)
	damaged.save(path)
	KeyBindings.reload()
	check(KeyBindings.code("pause") == KEY_SPACE and KeyBindings.code("pan_left") == KEY_A and KeyBindings.code("mute") == KEY_M and KeyBindings.code("army") == KEY_B and KeyBindings.owner_of(KEY_B) == "army", "reserved keys, a modifier on a held key, a word and an unknown control are ignored; the one good entry holds")
	check(Overlays.MODES.has("water") and KeyBindings.overlay_for(key_event(KEY_1)) == "water", "overlays are unaffected by the file")

	# --------------------------------------------------------------------------------------- the Controls dialog
	path = fresh_settings("dialog.cfg")
	var dialog: Window = ControlsDialog.open(root)
	await process_frame
	var rows: Array = dialog.key_buttons.keys()
	check(rows.size() == KeyBindings.actions().size() and dialog.key_buttons.pause.text == "Space" and not dialog.reset_buttons.pause.visible, "the dialog lists every control with its key, and offers Reset only for changed ones (%d rows)" % rows.size())
	dialog.begin_capture("turn_placement")
	var access: Node = root.get_node("UiAccess")
	check(dialog.waiting == "turn_placement" and dialog.key_buttons.turn_placement.text == tr("Press a key…") and access.dialog_open, "a click on a key asks for the new one, and the city's own keys wait")
	dialog._on_window_input(key_event(KEY_SHIFT))
	check(dialog.waiting == "turn_placement", "a modifier alone is the start of a combination: it keeps waiting")
	dialog._on_window_input(key_event(KEY_ESCAPE))
	check(dialog.waiting == "" and not access.dialog_open and KeyBindings.code("turn_placement") == KEY_T and dialog.message.text == tr("Nothing was changed."), "Escape cancels the request and changes nothing")
	var heard := {"changed": 0}
	dialog.changed.connect(func(): heard.changed += 1)
	dialog.begin_capture("turn_placement")
	var answer: Dictionary = dialog.assign_from_event(key_event(KEY_G))
	check(answer.ok and KeyBindings.code("turn_placement") == KEY_G and dialog.key_buttons.turn_placement.text == "G" and dialog.reset_buttons.turn_placement.visible and heard.changed == 1 and not access.dialog_open, "a key pressed becomes the control's: its button says G, Reset appears, the interface is told")
	dialog.begin_capture("demolish")
	dialog.assign_from_event(key_event(KEY_G))
	check(KeyBindings.code("demolish") == KEY_G and KeyBindings.code("turn_placement") == KEY_X and dialog.message.text.contains("G") and dialog.message.text.contains("X"), "a key someone has is swapped, and the dialog says so: %s" % dialog.message.text)
	dialog.begin_capture("pause")
	dialog.assign_from_event(key_event(KEY_ESCAPE))
	check(KeyBindings.code("pause") == KEY_SPACE and dialog.message.text.contains("Esc") , "a reserved key is refused in words: %s" % dialog.message.text)
	dialog.reset_key("demolish")
	check(KeyBindings.code("demolish") == KEY_X and KeyBindings.code("turn_placement") == KEY_G, "Reset puts one control back")
	check(dialog.speed_choices.size() == 3 and PlaySettings.get_option("pan_percent") == 100, "three camera speeds are offered, all at 100%")
	dialog.speed_choices.pan_percent.item_selected.emit(4)
	check(PlaySettings.get_option("pan_percent") == 150 and int(stored(path, "camera", "pan_percent")) == 150, "choosing one applies it and remembers it")
	dialog.restore_defaults()
	check(not KeyBindings.any_custom() and PlaySettings.get_option("pan_percent") == 100 and dialog.speed_choices.pan_percent.selected == 2 and dialog.message.text == tr("All controls are back to their defaults."), "Restore defaults puts back every key and every speed")
	dialog.close()
	await process_frame
	check(not is_instance_valid(dialog) or dialog.is_queued_for_deletion(), "the dialog closes")

	# ------------------------------------------------------------------------------- play settings and the Game settings dialog
	path = fresh_settings("play.cfg")
	check(PlaySettings.autosave_seconds() == 300.0 and PlaySettings.autosave_slots() == 3 and not bool(PlaySettings.get_option("fullscreen")) and PlaySettings.get_option("voice_language") == "auto" and PlaySettings.pan_scale() == 1.0, "the options start as the game has always been: autosave every 5 minutes into 3 slots, windowed, voices in the interface language, camera at 100%")
	check(not PlaySettings.set_option("autosave_minutes", 7) and not PlaySettings.set_option("voice_language", "de") and not PlaySettings.set_option("fullscreen", "yes") and PlaySettings.autosave_seconds() == 300.0, "a value that is not one of an option's own is refused")
	check(PlaySettings.set_option("autosave_minutes", 0) and PlaySettings.autosave_seconds() == 0.0 and PlaySettings.set_option("autosave_slots", 10) and PlaySettings.autosave_slots() == 10 and PlaySettings.set_option("zoom_percent", 50) and is_equal_approx(PlaySettings.zoom_scale(), .5), "autosave can be switched off, its slots and the zoom pace changed")
	PlaySettings.reload()
	check(PlaySettings.autosave_seconds() == 0.0 and PlaySettings.autosave_slots() == 10 and PlaySettings.get_option("zoom_percent") == 50 and int(stored(path, "game", "autosave_slots")) == 10, "and they come back from the settings file")
	var damaged_play := ConfigFile.new()
	damaged_play.set_value("game", "autosave_minutes", 7)
	damaged_play.set_value("game", "voice_language", 3)
	damaged_play.set_value("camera", "pan_percent", 100.5)
	damaged_play.save(path)
	PlaySettings.reload()
	check(PlaySettings.autosave_seconds() == 300.0 and PlaySettings.get_option("voice_language") == "auto" and PlaySettings.pan_scale() == 1.0, "values a damaged file gives that are not allowed are ignored")
	PlaySettings.reload()
	var voices := PlaySettings.voice_language()
	check(voices == TranslationServer.get_locale().left(2), "with 'same as the interface' the voices follow the language (%s)" % voices)
	PlaySettings.set_option("voice_language", "ru" if voices == "en" else "en")
	check(PlaySettings.voice_language() == ("ru" if voices == "en" else "en"), "or the language the player chose")
	var voice_file := ""
	var english_dir := DirAccess.open(root_path().path_join("Audio/Voice_en/Walker"))
	if english_dir != null:
		for name in english_dir.get_files():
			if FileAccess.file_exists(root_path().path_join("Audio/Voice_ru/Walker").path_join(name)):
				voice_file = name
				break
	if voice_file != "":
		PlaySettings.set_option("voice_language", "ru")
		var russian: String = root.get_node("GameAudio").resolve("Audio/Voice/Walker/" + voice_file)
		PlaySettings.set_option("voice_language", "en")
		var english: String = root.get_node("GameAudio").resolve("Audio/Voice/Walker/" + voice_file)
		check(russian.contains("Voice_ru") and english.contains("Voice_en"), "a voice line comes from the folder of the chosen language (%s)" % voice_file)
	PlaySettings.set_option("voice_language", "auto")
	PlaySettings.set_option("autosave_minutes", 5)
	var settings_dialog: Window = GameSettingsDialog.open(root)
	await process_frame
	var minutes: OptionButton = settings_dialog.choices.autosave_minutes
	check(settings_dialog.choices.size() == 3 and minutes.selected == PlaySettings.OPTIONS.autosave_minutes[2].find(5) and settings_dialog.choices.autosave_slots.selected == PlaySettings.OPTIONS.autosave_slots[2].find(3), "the Game settings dialog shows the options as they are")
	var told := {"n": 0}
	settings_dialog.changed.connect(func(): told.n += 1)
	minutes.item_selected.emit(0)
	check(PlaySettings.autosave_seconds() == 0.0 and told.n == 1 and int(stored(path, "game", "autosave_minutes")) == 0, "choosing 'Off' for autosave applies and is remembered, and the city is told")
	settings_dialog.queue_free()

	# -------------------------------------------------------------------------------------------------- the camera's pace
	path = fresh_settings("camera.cfg")
	var orbit: Node3D = Orbit.new()
	root.add_child(orbit)
	await process_frame
	orbit.yaw = 0.0
	orbit.step_orbit(1.0, 1.0)
	var normal_turn: float = orbit.yaw
	PlaySettings.set_option("turn_percent", 200)
	orbit.yaw = 0.0
	orbit.step_orbit(1.0, 1.0)
	check(is_equal_approx(normal_turn, 65.0) and is_equal_approx(orbit.yaw, 130.0), "turning at 200%% is twice as fast (%.0f against %.0f degrees a second)" % [orbit.yaw, normal_turn])
	orbit.pitch = 30.0
	orbit.step_tilt(1.0, .3)
	var tilted: float = orbit.pitch - 30.0
	check(is_equal_approx(tilted, 21.0), "and so is tilting (%.1f degrees in .3 s, where 100%% gives 10.5)" % tilted)
	PlaySettings.set_option("turn_percent", 100)
	var moved: Array = []
	for percent in [100, 200]:
		PlaySettings.set_option("pan_percent", percent)
		orbit.target = Vector3.ZERO
		orbit.bounds = Vector2(500, 500)
		Input.action_press("pan_forward")
		orbit._process(.5)
		Input.action_release("pan_forward")
		moved.append(orbit.target.length())
	check(moved[0] > .1 and is_equal_approx(moved[1] / moved[0], 2.0), "panning at 200%% is twice as fast (%.2f against %.2f)" % [moved[1], moved[0]])
	orbit.queue_free()

	# ------------------------------------------------------------------------------------------------------- the words
	var untranslated: Array = []
	var texts: Array = []
	for entry in KeyBindings.actions():
		texts.append(entry.label)
	for group in KeyBindings.GROUPS:
		texts.append(group)
	for spec in ControlsDialog.SPEEDS:
		texts.append(spec[1])
	for line in ControlsDialog.FIXED:
		texts.append(line[0])
		texts.append(line[1])
	texts.append_array(["Controls", "Game settings", "Controls…", "Game settings…", "Restore defaults", "Reset", "Press a key…", "Camera speed", "Fixed controls", "Autosave", "Off", "Every %d minutes", "Autosaves kept", "Voice language", "Same as the interface", "Fullscreen",
		"Click a key to change it; Escape cancels.", "Press the new key for %s. Escape cancels.", "Nothing was changed.", "%s is now %s.", "%s is now %s. %s took %s.", "%s cannot be used for a control.", "%s takes a plain key, without Ctrl, Cmd or Alt.",
		"%s is used for %s, which cannot take %s.", "%s is back to %s.", "All controls are back to their defaults.", "Autosaves count only while the game is running, and rotate through the slots.",
		"Select a building to inspect  ·  %s / %s orbit  ·  %s / %s tilt", "%s / %s orbit · %s / %s tilt up / down · %s pan · Wheel zoom · Middle drag orbit / tilt · %s pauses · %s city overview · %s turns placement"])
	TranslationServer.set_locale("ru")
	for text in texts:
		var russian := TranslationServer.translate(text)
		if russian == text and text not in ["Delete", "Shift", "Escape"]:
			untranslated.append(text)
	check(untranslated.is_empty(), "everything the dialogs say has Russian text %s" % str(untranslated.slice(0, 4)))
	var hint_ru := KeyBindings.idle_hint()
	check(has_cyrillic(hint_ru) and hint_ru.contains("Q") and hint_ru.contains("F"), "the hint that names the camera keys is in Russian with the player's keys: %s" % hint_ru)
	TranslationServer.set_locale("en")
	KeyBindings.assign("orbit_left", KEY_J)
	check(KeyBindings.idle_hint().contains("J / ") and KeyBindings.controls_hint().contains("J / "), "and follows a rebinding in English")
	KeyBindings.reset_all()

	# ------------------------------------------------------------------------------------------------ nothing of the player's was touched
	Engine.remove_meta("ezeus_settings_path")
	KeyBindings.reload()
	PlaySettings.reload()
	KeyBindings.assign("pause", KEY_B)
	PlaySettings.set_option("autosave_minutes", 0)
	check(str(Settings.get_value("keys", "pause", "")) == "" and str(Settings.get_value("game", "autosave_minutes", "")) == "", "with automation running, changes stay in memory and are never written to the player's settings")
	KeyBindings.reload()
	PlaySettings.reload()
	var player_after := FileAccess.get_sha256(player_file) if FileAccess.file_exists(player_file) else ""
	check(player_before == player_after, "the player's settings file is unchanged")
	for name in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(name))
	DirAccess.remove_absolute(scratch)
	print("CONTROLS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)

func root_path() -> String:
	return ProjectSettings.globalize_path("res://../..").simplify_path()
