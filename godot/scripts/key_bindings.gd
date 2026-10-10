extends RefCounted
# The keys of the city view, as the player has set them (user://settings.cfg, section "keys"; never the original game's settings.txt).
#
# Every key is stored as a physical key (its place on the keyboard, so QWERTY and Cyrillic layouts behave alike) plus the modifiers that
# matter: Ctrl or Cmd (one flag, as the game always treated them) and Alt. Shift is never part of a binding: it stays the fast-pan and
# wall-fill modifier, and a key matches with or without it. A binding is one code: key | modifier flags.
#
# The held camera keys (orbit, tilt, pan) are InputMap actions, polled every frame; every other action is matched in the handlers with
# `matches(event, id)`. A key belongs to one action: `assign` hands the key over and gives the other action the key the first one gave up.
# Escape, Delete (a second demolition key), the modifier keys alone and, for held and view keys, any modifier, cannot be bound.
# Automation (validation, captures) always sees the defaults, unless a test points the settings at a scratch file (`ezeus_settings_path`).

const Settings = preload("res://scripts/user_settings.gd")
const Overlays = preload("res://scripts/overlays.gd")

const SECTION := "keys"
const CMD := KEY_MASK_CTRL    # Ctrl or Cmd
const ALT := KEY_MASK_ALT
const MODIFIERS := KEY_MASK_CTRL | KEY_MASK_ALT
const GROUPS := ["Camera", "Construction", "Game", "Build tabs", "Bookmarks", "Companies", "City views"]
# Held actions are InputMap actions and take no modifier; "bare" ones take none either; the others may carry Ctrl/Cmd and Alt.
# "held2" is a held action's second key (the arrows for panning): no modifier either, but it may be left unassigned.
const DOCK_ACTIONS := ["build_house", "build_road", "build_roadblock", "layers", "jobs"]
const HELD := ["orbit_left", "orbit_right", "tilt_up", "tilt_down", "pan_forward", "pan_back", "pan_left", "pan_right"]
# A held action's second key, fed into the same InputMap action.
const SECOND := {"pan_forward": "pan_forward_alt", "pan_back": "pan_back_alt", "pan_left": "pan_left_alt", "pan_right": "pan_right_alt"}
# The two key layouts: this game's own ("ezeus", the default) and the original Zeus: Master of Olympus keys ("classic").
# Choosing a layout puts every control on that layout's key; the player's own changes are kept per layout choice.
const LAYOUTS := ["ezeus", "classic"]
const LAYOUT_NAMES := {"ezeus": "eZeus (this game)", "classic": "Classic Zeus"}
const LAYOUT_SECTION := "controls"
const RESERVED := [KEY_ESCAPE, KEY_DELETE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_UNKNOWN, KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK]

# [group, label (a tr() key), default code, kind: "held", "bare" or "free"]
const FIXED := {
	"orbit_left": ["Camera", "Orbit left", KEY_Q, "held"],
	"orbit_right": ["Camera", "Orbit right", KEY_E, "held"],
	"tilt_up": ["Camera", "Tilt up", KEY_R, "held"],
	"tilt_down": ["Camera", "Tilt down", KEY_F, "held"],
	"pan_forward": ["Camera", "Pan forward", KEY_W, "held"],
	"pan_back": ["Camera", "Pan back", KEY_S, "held"],
	"pan_left": ["Camera", "Pan left", KEY_A, "held"],
	"pan_right": ["Camera", "Pan right", KEY_D, "held"],
	"camera_home": ["Camera", "City overview", KEY_HOME, "bare"],
	"turn_placement": ["Construction", "Turn the placement", KEY_T, "free"],
	"build_house": ["Construction", "Housing", KEY_H, "free"],
	"build_road": ["Construction", "Road", KEY_B, "free"],
	"build_roadblock": ["Construction", "Road Block", KEY_G, "free"],
	"layers": ["Game", "Overlays", KEY_L, "free"],
	"jobs": ["Game", "Jobs", KEY_J, "free"],
	"demolish": ["Construction", "Demolition tool", KEY_X, "free"],
	"undo": ["Construction", "Undo last construction", KEY_Z | KEY_MASK_CTRL, "free"],
	"pause": ["Game", "Pause or resume", KEY_SPACE, "free"],
	"quick_save": ["Game", "Quick save", KEY_F5, "free"],
	"quick_load": ["Game", "Quick load", KEY_F9, "free"],
	"world_map": ["Game", "World map", KEY_F2, "free"],
	"army": ["Game", "Army", KEY_F4, "free"],
	"mythology": ["Game", "Mythology", KEY_F6, "free"],
	"city": ["Game", "City", KEY_F7, "free"],
	"mute": ["Game", "Mute all sound", KEY_M, "free"],
	"details": ["Game", "City details", KEY_F3, "free"],
	"fullscreen": ["Game", "Fullscreen", KEY_ENTER | KEY_MASK_ALT, "free"],
}
# The second key that returns to the normal view (the SDL game's back quote).
const NORMAL_ALTERNATE := "overlay_normal_alt"
# The original game's keys (the Zeus guide's hotkey list) that came after the table above. Their defaults are this game's; a key only
# Zeus had is given in both layouts where it is free, and a key that clashes with one of this game's is the Classic layout's only.
# They are given out after the player's older choices (see `_load`), so a key the player already uses stays theirs.
const EXTRA := {
	"pan_forward_alt": ["Camera", "Pan forward (second key)", KEY_UP, "held2"],
	"pan_back_alt": ["Camera", "Pan back (second key)", KEY_DOWN, "held2"],
	"pan_left_alt": ["Camera", "Pan left (second key)", KEY_LEFT, "held2"],
	"pan_right_alt": ["Camera", "Pan right (second key)", KEY_RIGHT, "held2"],
	"rotate_left": ["Camera", "Turn the city a quarter left", KEY_PAGEUP, "free"],
	"rotate_right": ["Camera", "Turn the city a quarter right", KEY_PAGEDOWN, "free"],
	"face_north": ["Camera", "Face north", 0, "free"],
	"freeze_footprint": ["Construction", "Hold the placement in place", 0, "free"],
	"pause_alt": ["Game", "Pause or resume (second key)", KEY_P, "free"],
	"speed_up": ["Game", "Faster game speed", KEY_BRACKETRIGHT, "free"],
	"speed_down": ["Game", "Slower game speed", KEY_BRACKETLEFT, "free"],
	"overview_map": ["Game", "Show or hide the city map", 0, "free"],
	"screenshot": ["Game", "Screenshot", KEY_F12, "free"],
	"quit_game": ["Game", "Exit the game", KEY_X | KEY_MASK_ALT, "free"],
	"window_800": ["Game", "Window 800 × 600", 0, "free"],
	"window_1024": ["Game", "Window 1024 × 768", 0, "free"],
	"category_1": ["Build tabs", "Population tab", 0, "bare"],
	"category_2": ["Build tabs", "Husbandry tab", 0, "bare"],
	"category_3": ["Build tabs", "Industry tab", 0, "bare"],
	"category_4": ["Build tabs", "Distribution tab", 0, "bare"],
	"category_5": ["Build tabs", "Hygiene and safety tab", 0, "bare"],
	"category_6": ["Build tabs", "Administration tab", 0, "bare"],
	"category_7": ["Build tabs", "Culture tab", 0, "bare"],
	"category_8": ["Build tabs", "Mythology tab", 0, "bare"],
	"category_9": ["Build tabs", "Military tab", 0, "bare"],
	"category_10": ["Build tabs", "Aesthetics tab", 0, "bare"],
	"bookmark_go_1": ["Bookmarks", "Go to bookmark 1", KEY_F1 | KEY_MASK_ALT, "free"],
	"bookmark_go_2": ["Bookmarks", "Go to bookmark 2", KEY_F2 | KEY_MASK_ALT, "free"],
	"bookmark_go_3": ["Bookmarks", "Go to bookmark 3", KEY_F3 | KEY_MASK_ALT, "free"],
	"bookmark_go_4": ["Bookmarks", "Go to bookmark 4", KEY_F4 | KEY_MASK_ALT, "free"],
	"bookmark_set_1": ["Bookmarks", "Set bookmark 1", KEY_F1 | KEY_MASK_CTRL, "free"],
	"bookmark_set_2": ["Bookmarks", "Set bookmark 2", KEY_F2 | KEY_MASK_CTRL, "free"],
	"bookmark_set_3": ["Bookmarks", "Set bookmark 3", KEY_F3 | KEY_MASK_CTRL, "free"],
	"bookmark_set_4": ["Bookmarks", "Set bookmark 4", KEY_F4 | KEY_MASK_CTRL, "free"],
	"company_set_1": ["Companies", "Give the chosen company key 1", KEY_1 | KEY_MASK_CTRL, "free"],
	"company_set_2": ["Companies", "Give the chosen company key 2", KEY_2 | KEY_MASK_CTRL, "free"],
	"company_set_3": ["Companies", "Give the chosen company key 3", KEY_3 | KEY_MASK_CTRL, "free"],
	"company_set_4": ["Companies", "Give the chosen company key 4", KEY_4 | KEY_MASK_CTRL, "free"],
	"company_set_5": ["Companies", "Give the chosen company key 5", KEY_5 | KEY_MASK_CTRL, "free"],
	"company_select_1": ["Companies", "Choose company 1", KEY_1 | KEY_MASK_ALT, "free"],
	"company_select_2": ["Companies", "Choose company 2", KEY_2 | KEY_MASK_ALT, "free"],
	"company_select_3": ["Companies", "Choose company 3", KEY_3 | KEY_MASK_ALT, "free"],
	"company_select_4": ["Companies", "Choose company 4", KEY_4 | KEY_MASK_ALT, "free"],
	"company_select_5": ["Companies", "Choose company 5", KEY_5 | KEY_MASK_ALT, "free"],
	"switch_view": ["City views", "Switch views (normal and the last overlay)", 0, "free"],
}
# The Classic Zeus layout: the original game's keys (P pauses, Space switches views, 1-0 open the build tabs, - the overview,
# Tab the city map, Home faces north, PgUp/PgDn turn the city, F1-F4 go to bookmarks, F5 windowed, F6/F7 the old window sizes,
# Print Screen, Alt+X, Ctrl/Alt+1-5 the companies, M holds a sanctuary's footprint). Controls not named keep this game's key;
# the ones the original keys displace get a free key of their own (or none: the overlays are chosen from Layers there).
const CLASSIC := {
	"pause": KEY_P, "pause_alt": 0, "switch_view": KEY_SPACE, "face_north": KEY_HOME, "camera_home": KEY_END,
	"overview_map": KEY_TAB, "freeze_footprint": KEY_M, "mute": KEY_M | KEY_MASK_ALT, "fullscreen": KEY_F5,
	"quick_save": KEY_S | KEY_MASK_CTRL, "window_800": KEY_F6, "window_1024": KEY_F7, "screenshot": KEY_PRINT,
	"world_map": KEY_F8, "army": KEY_F10, "mythology": KEY_F11, "city": KEY_MINUS, "details": 0,
	"bookmark_go_1": KEY_F1, "bookmark_go_2": KEY_F2, "bookmark_go_3": KEY_F3, "bookmark_go_4": KEY_F4,
	"category_1": KEY_1, "category_2": KEY_2, "category_3": KEY_3, "category_4": KEY_4, "category_5": KEY_5,
	"category_6": KEY_6, "category_7": KEY_7, "category_8": KEY_8, "category_9": KEY_9, "category_10": KEY_0,
	"overlay_normal": 0, "overlay_water": 0, "overlay_supplies": 0, "overlay_hygiene": 0, "overlay_hazards": 0, "overlay_appeal": 0,
	"overlay_taxes": 0, "overlay_unrest": 0, "overlay_security": 0, "overlay_roads": 0, "overlay_problems": 0,
}

static var table: Array = []
static var index: Dictionary = {}
static var custom: Dictionary = {}
static var loaded := false
static var current_layout := "ezeus"

# ---- the table of actions ---------------------------------------------------------------------------------------------
# [{id, group, label, default, kind}] in the order the Controls dialog lists them.
static func actions() -> Array:
	if not table.is_empty():
		return table
	for id in FIXED:
		var entry: Array = FIXED[id]
		table.append({"id": id, "group": entry[0], "label": entry[1], "default": int(entry[2]), "kind": entry[3]})
	for id in Overlays.MODES:
		var key := int(Overlays.MODES[id][2])
		if key != 0:
			table.append({"id": "overlay_" + id, "group": "City views", "label": Overlays.MODES[id][0], "default": key, "kind": "bare"})
	table.append({"id": NORMAL_ALTERNATE, "group": "City views", "label": "Normal view (second key)", "default": KEY_QUOTELEFT, "kind": "bare"})
	for id in EXTRA:
		var entry: Array = EXTRA[id]
		table.append({"id": id, "group": entry[0], "label": entry[1], "default": int(entry[2]), "kind": entry[3]})
	return table

static func definition(id: String) -> Dictionary:
	if index.is_empty():
		for entry in actions():
			index[entry.id] = entry
	return index.get(id, {})

# The key a control has in the layout in use (or in the one named) before the player changes it.
static func default_code(id: String, in_layout := "") -> int:
	var name := in_layout if in_layout != "" else layout()
	if name == "classic" and CLASSIC.has(id):
		return int(CLASSIC[id])
	return int(definition(id).get("default", 0))

# ---- the key layout ---------------------------------------------------------------------------------------------------
static func layout() -> String:
	_load()
	return current_layout

# Puts every control on the named layout's keys: the player's own changes are forgotten (they were made against the other
# layout's keys), and the choice is remembered when automation is not running.
static func set_layout(name: String) -> bool:
	if name not in LAYOUTS:
		return false
	_load()
	for entry in actions():
		custom.erase(entry.id)
		if uses_player_settings():
			Settings.set_value(SECTION, entry.id, null)
	current_layout = name
	if uses_player_settings():
		Settings.set_value(LAYOUT_SECTION, "layout", name)
	apply_input_map()
	return true

# ---- reading and writing the player's choices -------------------------------------------------------------------------
static func uses_player_settings() -> bool:
	if Engine.has_meta("ezeus_settings_path"):
		return true
	if OS.get_cmdline_args().has("--script"):
		return false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--validate") or argument.begins_with("--skip-start") or argument.contains("-review"):
			return false
	return true

# Forgets what was read, so that the next question reads the settings again (a test switches the settings file).
static func reload() -> void:
	loaded = false
	custom = {}
	current_layout = "ezeus"

static func _load() -> void:
	if loaded:
		return
	loaded = true
	custom = {}
	current_layout = "ezeus"
	if not uses_player_settings():
		return
	var chosen: Variant = Settings.get_value(LAYOUT_SECTION, "layout", "ezeus")
	if typeof(chosen) == TYPE_STRING and chosen in LAYOUTS:
		current_layout = chosen
	var found := {}
	for entry in actions():
		var value: Variant = Settings.get_value(SECTION, entry.id, "")
		if typeof(value) == TYPE_INT and problem(entry.id, int(value)).is_empty() and int(value) != default_code(entry.id):
			found[entry.id] = int(value)
	# Validate legacy bindings first. Adding dock defaults (and the original game's keys) must not displace an
	# existing custom key; a newly occupied shortcut stays unassigned until rebound.
	var late: Array = DOCK_ACTIONS + EXTRA.keys()
	var seen := {}
	for entry in actions():
		if entry.id in late: continue
		var effective := int(found.get(entry.id, default_code(entry.id)))
		if effective == 0: continue
		if seen.has(effective):
			push_warning("key bindings: %s is bound twice; the defaults are used" % OS.get_keycode_string(effective & KEY_CODE_MASK))
			return
		seen[effective] = entry.id
	for id in late:
		var effective := int(found.get(id,default_code(id)))
		if effective == 0: continue
		if seen.has(effective): found[id] = 0
		else: seen[effective] = id
	custom = found

static func code(id: String) -> int:
	_load()
	return int(custom.get(id, default_code(id)))

static func is_custom(id: String) -> bool:
	_load()
	return custom.has(id)

static func any_custom() -> bool:
	_load()
	return not custom.is_empty()

# Remembers a choice in memory, and in the player's settings when automation is not running (which must never write them).
static func _store(id: String, value: int) -> void:
	if value == default_code(id):
		custom.erase(id)
		if uses_player_settings():
			Settings.set_value(SECTION, id, null)
	else:
		custom[id] = value
		if uses_player_settings():
			Settings.set_value(SECTION, id, value)

# ---- keys as text and as events ---------------------------------------------------------------------------------------
# "Q", "F5", "Cmd+Z" (Ctrl+Z off macOS), "Alt+Enter": the physical key's name as the Latin layout prints it.
static func text(value: int) -> String:
	if value == 0: return TranslationServer.translate("Unassigned")
	var parts: Array[String] = []
	if value & CMD:
		parts.append("Cmd" if OS.get_name() == "macOS" else "Ctrl")
	if value & ALT:
		parts.append("Alt")
	parts.append(OS.get_keycode_string(value & KEY_CODE_MASK))
	return "+".join(parts)

static func label(id: String) -> String:
	return text(code(id))

# What an event is as a binding: its physical key (the typed one when a layout has no physical code) with Ctrl/Cmd and Alt.
static func encode(event: InputEventKey) -> int:
	var key := int(event.physical_keycode) if int(event.physical_keycode) != 0 else int(event.keycode)
	if event.ctrl_pressed or event.meta_pressed:
		key |= CMD
	if event.alt_pressed:
		key |= ALT
	return key

static func matches(event: InputEvent, id: String) -> bool:
	return code(id) != 0 and event is InputEventKey and event.pressed and not event.echo and encode(event) == code(id)

# The overlay whose key this is ("water", "problems", ...; "normal" for either of its keys), or "".
static func overlay_for(event: InputEvent) -> String:
	# Shift stays out of it, as it always did: Shift and a digit are not an overlay.
	if not (event is InputEventKey) or not event.pressed or event.echo or event.shift_pressed:
		return ""
	var value := encode(event)
	for entry in actions():
		if entry.group == "City views" and str(entry.id).begins_with("overlay_") and code(entry.id) == value:
			return "normal" if entry.id == NORMAL_ALTERNATE else str(entry.id).trim_prefix("overlay_")
	return ""

# ---- the rules of a binding -------------------------------------------------------------------------------------------
# "" when the key may be given to the action, else why not: "reserved" (Escape, Delete and the modifier keys) or "modifier" (a held, view
# or overview key takes no Ctrl/Cmd or Alt).
static func problem(id: String, value: int) -> String:
	var key := value & KEY_CODE_MASK
	if key in RESERVED or (key == 0 and str(definition(id).get("kind","free")) == "held"):
		return "reserved"
	var kind := str(definition(id).get("kind", "free"))
	if kind != "free" and value & MODIFIERS:
		return "modifier"
	return ""

# The action that has this key, or "".
static func owner_of(value: int) -> String:
	if value == 0: return ""
	for entry in actions():
		if code(entry.id) == value:
			return entry.id
	return ""

# Gives a key to an action. {ok, reason, swapped}: when another action had the key it takes the one this action leaves (if that key suits it, else
# the change is refused: "swap_refused"); `swapped` names that action.
static func assign(id: String, value: int) -> Dictionary:
	_load()
	var refusal := problem(id, value)
	if not refusal.is_empty():
		return {"ok": false, "reason": refusal, "swapped": ""}
	var holder := owner_of(value)
	if holder == id:
		return {"ok": true, "reason": "", "swapped": ""}
	var old := code(id)
	if holder != "":
		if not problem(holder, old).is_empty():
			return {"ok": false, "reason": "swap_refused", "swapped": holder}
		_store(holder, old)
	_store(id, value)
	apply_input_map()
	return {"ok": true, "reason": "", "swapped": holder}

# Back to the original key. If another action holds it now, that action takes the key this one leaves (when that suits it); else false.
static func reset(id: String) -> bool:
	_load()
	var original := default_code(id)
	var holder := owner_of(original)
	if holder != "" and holder != id:
		if not problem(holder, code(id)).is_empty():
			return false
		_store(holder, code(id))
	_store(id, original)
	apply_input_map()
	return true

static func reset_all() -> void:
	_load()
	for entry in actions():
		custom.erase(entry.id)
		if uses_player_settings():
			Settings.set_value(SECTION, entry.id, null)
	apply_input_map()

# The held camera actions of the InputMap follow the bindings.
static func apply_input_map() -> void:
	for id in HELD:
		if not InputMap.has_action(id):
			InputMap.add_action(id)
		InputMap.action_erase_events(id)
		var event := InputEventKey.new()
		event.physical_keycode = (code(id) & KEY_CODE_MASK) as Key
		InputMap.action_add_event(id, event)
		# The second key (the arrows for panning) drives the same action.
		if SECOND.has(id) and code(SECOND[id]) != 0:
			var second := InputEventKey.new()
			second.physical_keycode = (code(SECOND[id]) & KEY_CODE_MASK) as Key
			InputMap.action_add_event(id, second)

# The hint that names the camera keys, in the player's own (translated) words.
static func idle_hint() -> String:
	return TranslationServer.translate("Select a building to inspect  ·  %s / %s orbit  ·  %s / %s tilt") % [label("orbit_left"), label("orbit_right"), label("tilt_up"), label("tilt_down")]

static func controls_hint() -> String:
	return TranslationServer.translate("%s / %s orbit · %s / %s tilt up / down · %s pan · Wheel zoom · Middle drag orbit / tilt · %s pauses · %s city overview · %s turns placement") % [
		label("orbit_left"), label("orbit_right"), label("tilt_up"), label("tilt_down"),
		" ".join([label("pan_forward"), label("pan_left"), label("pan_back"), label("pan_right")]), label("pause"), label("camera_home"), label("turn_placement")]
