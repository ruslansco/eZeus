extends SceneTree
# Interface text gate (headless, read-only): every literal passed to tr() by the scripts and the HUD must have
# a translation in each translated locale, no translation row may be orphaned, and the language list and
# digit grouping must behave. English source strings are the keys (scripts/ui_text.gd), so a missing row would
# silently show English inside a Russian interface; this fails instead.
const UiText = preload("res://scripts/ui_text.gd")
const SCAN := ["res://scripts", "res://ui"]
# Same in every language, so no translation row is needed.
const EXEMPT := ["", "%d", "%s", "Date"]
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("UI_TEXT_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func collect(path: String, out: Array) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			out.append(path.path_join(file))
	for folder in DirAccess.get_directories_at(path):
		collect(path.path_join(folder), out)

func literals(code: String) -> Array:
	var found := []
	var expression := RegEx.new()
	expression.compile("\\btr\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	for match in expression.search_all(code):
		found.append(String(match.get_string(1)).replace("\\n", "\n").replace("\\\"", "\""))
	return found

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var languages := UiText.languages()
	check(languages.size() >= 2 and languages[0] == "en" and languages.has("ru"), "English plus at least Russian are loaded (%s)" % str(languages))
	check(UiText.next_language("en") == languages[1] and UiText.next_language(languages[-1]) == "en", "the language button cycles through every language and wraps")
	var files: Array = []
	for root_path in SCAN:
		collect(root_path, files)
	var used := {}
	for path in files:
		for text in literals(FileAccess.get_file_as_string(path)):
			used[text] = path
	check(used.size() > 40, "the interface uses %d literal translated texts" % used.size())
	var rows := {}
	var file := FileAccess.open("res://data/ui_strings.csv", FileAccess.READ)
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and not row[0].is_empty():
			rows[row[0]] = row
	for locale in languages:
		if locale == "en":
			continue
		var column := header.find(locale)
		var missing: Array = []
		TranslationServer.set_locale(locale)
		for text in used:
			if text in EXEMPT:
				continue
			if not rows.has(text) or rows[text].size() <= column or String(rows[text][column]).is_empty():
				missing.append(text)
			elif TranslationServer.translate(text) == text and String(rows[text][column]) != text:
				missing.append(text + " (not loaded; run godot --headless --path godot --import)")
		check(missing.is_empty(), "every text has a %s translation %s" % [locale, str(missing.slice(0, 6))])
	TranslationServer.set_locale("en")
	# Texts reached through tables or formats (tool labels, reasons, goods, statuses) are not literal tr() calls, so
	# a row counts as used when its text appears as a string literal anywhere in the scripts.
	var sources := ""
	for path in files:
		sources += FileAccess.get_file_as_string(path)
	var orphans: Array = []
	for text in rows:
		var escaped := String(text).replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
		if not sources.contains("\"" + escaped + "\""):
			orphans.append(text)
	check(orphans.is_empty(), "no translation row is orphaned %s" % str(orphans.slice(0, 6)))
	var grouping := preload("res://ui/hud.gd").new()
	TranslationServer.set_locale("en")
	check(grouping.group_digits(1234567) == "1,234,567" and grouping.group_digits(-1200) == "-1,200" and grouping.group_digits(12) == "12", "digit grouping in English")
	TranslationServer.set_locale("ru")
	check(grouping.group_digits(1234567) == "1 234 567", "digit grouping in Russian uses a space")
	TranslationServer.set_locale("en")
	grouping.free()
	print("UI_TEXT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
