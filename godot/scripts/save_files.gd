extends RefCounted
# The player's saved games: one directory per user (user://saves), native .ez files inside it, newest first. Shared by
# the start menu and the in-game Game menu so both list the same files the same way.

# Tests point this at a scratch folder through Engine meta `ezeus_save_directory`; players never set it.
static func directory() -> String:
	if Engine.has_meta("ezeus_save_directory"):
		return str(Engine.get_meta("ezeus_save_directory"))
	return ProjectSettings.globalize_path("user://saves")

# [{name, path, modified, detail}] newest first; `detail` is the one-line description shown under the list.
static func list(folder := "") -> Array:
	var where := folder if not folder.is_empty() else directory()
	var entries: Array = []
	for file in DirAccess.get_files_at(where):
		if not file.ends_with(".ez"):
			continue
		var path := where.path_join(file)
		var modified := FileAccess.get_modified_time(path)
		var handle := FileAccess.open(path, FileAccess.READ)
		var size := handle.get_length() if handle != null else 0
		entries.append({"name": file.trim_suffix(".ez"), "path": path, "modified": modified,
			"detail": TranslationServer.translate("Saved %s  •  %.1f MB") % [Time.get_datetime_string_from_unix_time(modified, true).replace("T", " "), size / 1048576.0]})
	entries.sort_custom(func(a, b): return a.modified > b.modified)
	return entries

# The newest save, or an empty Dictionary.
static func latest(folder := "") -> Dictionary:
	var entries := list(folder)
	return entries[0] if not entries.is_empty() else {}
