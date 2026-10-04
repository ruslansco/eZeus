extends RefCounted
# Per-user presentation settings (user://settings.cfg, never the original game's settings.txt): the interface language,
# so the start menu and the city open in the language the player last chose, with their sound volumes and interface/text sizes.

const PATH := "user://settings.cfg"

# Tests point this at a scratch file through Engine meta `ezeus_settings_path`; players never set it.
static func path() -> String:
	return str(Engine.get_meta("ezeus_settings_path")) if Engine.has_meta("ezeus_settings_path") else PATH

static func language(fallback := "en") -> String:
	var file := ConfigFile.new()
	if file.load(path()) != OK:
		return fallback
	return str(file.get_value("interface", "language", fallback))

static func set_language(code: String) -> void:
	var file := ConfigFile.new()
	file.load(path())
	file.set_value("interface", "language", code)
	file.save(path())

# Any other per-user value (sound volumes and the mute flag live under "sound").
static func get_value(section: String, key: String, fallback: Variant) -> Variant:
	var file := ConfigFile.new()
	if file.load(path()) != OK:
		return fallback
	return file.get_value(section, key, fallback)

static func set_value(section: String, key: String, value: Variant) -> void:
	var file := ConfigFile.new()
	file.load(path())
	file.set_value(section, key, value)
	file.save(path())
