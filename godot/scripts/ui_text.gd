extends RefCounted
# Interface text. The English source text is the translation key (gettext style), so every `tr("Resume")`
# still reads correctly when a translation is missing. data/ui_strings.csv holds one column per additional
# locale after the `source` column; Godot's CSV import turns each column into data/ui_strings.<locale>.translation,
# which project.godot (internationalization/locale/translations) registers. To add a language: add a column,
# import (godot --headless --path godot --import) and append the new .translation file to that setting.
# Native game text (messages, building and city names) comes from the C++ core's own language data, not from here.

const SOURCE_LOCALE := "en"

# Source locale first, then every translated locale, in a stable order.
static func languages() -> Array[String]:
	var result: Array[String] = [SOURCE_LOCALE]
	var loaded := TranslationServer.get_loaded_locales()
	loaded.sort()
	for locale in loaded:
		if locale != SOURCE_LOCALE and not result.has(locale):
			result.append(locale)
	if not result.has("ru"):
		result.append("ru")
	return result

static func set_language(code: String) -> String:
	var chosen := code if languages().has(code) else SOURCE_LOCALE
	if chosen == "ru" and not TranslationServer.get_loaded_locales().has("ru"):
		var t_ui := load("res://data/ui_strings.ru.translation") as Translation
		if t_ui:
			TranslationServer.add_translation(t_ui)
		var t_build := load("res://data/building_names.ru.translation") as Translation
		if t_build:
			TranslationServer.add_translation(t_build)
	TranslationServer.set_locale(chosen)
	return chosen

# The language after `current`, wrapping round: the language button cycles through all of them.
static func next_language(current: String) -> String:
	var all := languages()
	return all[(all.find(current) + 1) % all.size()]
