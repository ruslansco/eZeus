extends RefCounted
# The play options that are not keys or sizes (user://settings.cfg, sections "game" and "camera"; never the original game's settings.txt):
# how often the city saves itself and how many autosaves are kept, voice language and camera pace.
# The earlier fullscreen API delegates to display_settings.gd so the shortcut and display dialog share one window policy.
# Every option has a default and a short list of values; anything else in the file is ignored. Automation always sees the defaults and never
# writes the player's file, unless a test points the settings at a scratch file (`ezeus_settings_path`).

const DisplayOptions = preload("res://scripts/display_settings.gd")
const Settings = preload("res://scripts/user_settings.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")

# key: [section, default, allowed values]
const OPTIONS := {
	"autosave_minutes": ["game", 5, [0, 2, 5, 10, 15, 30]],
	"autosave_slots": ["game", 3, [1, 3, 5, 10]],
	"fullscreen": ["game", false, [false, true]],
	"voice_language": ["game", "auto", ["auto", "en", "ru"]],
	"pan_percent": ["camera", 100, [50, 75, 100, 125, 150, 200]],
	"turn_percent": ["camera", 100, [50, 75, 100, 125, 150, 200]],
	"zoom_percent": ["camera", 100, [50, 75, 100, 125, 150, 200]],
}

static var values: Dictionary = {}
static var loaded := false

static func reload() -> void:
	loaded = false
	values = {}

static func _load() -> void:
	if loaded:
		return
	loaded = true
	values = {}
	if not KeyBindings.uses_player_settings():
		return
	for key in OPTIONS:
		var entry: Array = OPTIONS[key]
		var value: Variant = Settings.get_value(entry[0], key, entry[1])
		if typeof(value) == typeof(entry[1]) and value in entry[2]:
			values[key] = value

static func get_option(key: String) -> Variant:
	_load()
	return values.get(key, OPTIONS[key][1])

# False when the value is not one of the option's own.
static func set_option(key: String, value: Variant) -> bool:
	_load()
	var entry: Array = OPTIONS[key]
	if typeof(value) != typeof(entry[1]) or not (value in entry[2]):
		return false
	values[key] = value
	if KeyBindings.uses_player_settings():
		Settings.set_value(entry[0], key, value)
	return true

static func default_of(key: String) -> Variant:
	return OPTIONS[key][1]

# Seconds of unpaused play between autosaves; 0 when they are off.
static func autosave_seconds() -> float:
	return float(int(get_option("autosave_minutes")) * 60)

static func autosave_slots() -> int:
	return int(get_option("autosave_slots"))

# The camera's pace as a factor of the original (1.0 = as always).
static func pan_scale() -> float:
	return int(get_option("pan_percent")) * .01

static func turn_scale() -> float:
	return int(get_option("turn_percent")) * .01

static func zoom_scale() -> float:
	return int(get_option("zoom_percent")) * .01

# "en" or "ru" for the voices; the interface language when the option is "auto".
static func voice_language() -> String:
	var choice := str(get_option("voice_language"))
	return choice if choice != "auto" else TranslationServer.get_locale().left(2)

# ---- the window ------------------------------------------------------------------------------------------------------------
static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

static func apply_window() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null: DisplayOptions.startup(tree.root)

static func set_fullscreen(on: bool) -> void:
	set_option("fullscreen", on)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null: DisplayOptions.set_fullscreen(tree.root, on)
