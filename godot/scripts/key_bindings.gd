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
const GROUPS := ["Camera", "Construction", "Game", "City views"]
# Held actions are InputMap actions and take no modifier; "bare" ones take none either; the others may carry Ctrl/Cmd and Alt.
const DOCK_ACTIONS := ["build_house", "build_road", "build_roadblock", "layers", "jobs"]
const HELD := ["orbit_left", "orbit_right", "tilt_up", "tilt_down", "pan_forward", "pan_back", "pan_left", "pan_right"]
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

static var table: Array = []
static var index: Dictionary = {}
static var custom: Dictionary = {}
static var loaded := false

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
	return table

static func definition(id: String) -> Dictionary:
	if index.is_empty():
		for entry in actions():
			index[entry.id] = entry
	return index.get(id, {})

static func default_code(id: String) -> int:
	return int(definition(id).get("default", 0))

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

static func _load() -> void:
	if loaded:
		return
	loaded = true
	custom = {}
	if not uses_player_settings():
		return
	var found := {}
	for entry in actions():
		var value: Variant = Settings.get_value(SECTION, entry.id, "")
		if typeof(value) == TYPE_INT and problem(entry.id, int(value)).is_empty() and int(value) != int(entry.default):
			found[entry.id] = int(value)
	# Validate legacy bindings first. Adding dock defaults must not displace an
	# existing custom key; a newly occupied shortcut stays unassigned until rebound.
	var seen := {}
	for entry in actions():
		if entry.id in DOCK_ACTIONS: continue
		var effective := int(found.get(entry.id, entry.default))
		if effective == 0: continue
		if seen.has(effective):
			push_warning("key bindings: %s is bound twice; the defaults are used" % OS.get_keycode_string(effective & KEY_CODE_MASK))
			return
		seen[effective] = entry.id
	for id in DOCK_ACTIONS:
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
		if entry.group == "City views" and code(entry.id) == value:
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

# The hint that names the camera keys, in the player's own (translated) words.
static func idle_hint() -> String:
	return TranslationServer.translate("Select a building to inspect  ·  %s / %s orbit  ·  %s / %s tilt") % [label("orbit_left"), label("orbit_right"), label("tilt_up"), label("tilt_down")]

static func controls_hint() -> String:
	return TranslationServer.translate("%s / %s orbit · %s / %s tilt up / down · %s pan · Wheel zoom · Middle drag orbit / tilt · %s pauses · %s city overview · %s turns placement") % [
		label("orbit_left"), label("orbit_right"), label("tilt_up"), label("tilt_down"),
		" ".join([label("pan_forward"), label("pan_left"), label("pan_back"), label("pan_right")]), label("pause"), label("camera_home"), label("turn_placement")]
