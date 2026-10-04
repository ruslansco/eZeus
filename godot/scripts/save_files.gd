extends RefCounted
# The player's saved games: a directory per leader (user://saves/<leader>, scripts/leaders.gd), native .ez files inside it,
# newest first. Shared by the start menu and the in-game Game menu so both list the same files the same way. Saves from
# before leaders existed stay in the root and are listed after the leader's own, marked as such.

const UserSettings = preload("res://scripts/user_settings.gd")

# Tests point this at a scratch folder through Engine meta `ezeus_save_directory`; players never set it.
static func root() -> String:
	if Engine.has_meta("ezeus_save_directory"):
		return str(Engine.get_meta("ezeus_save_directory"))
	return ProjectSettings.globalize_path("user://saves")

# The chosen leader's folder (the root while no leader is chosen).
static func directory() -> String:
	var leader := str(UserSettings.get_value("profile", "leader", ""))
	if leader.is_empty() or not DirAccess.dir_exists_absolute(root().path_join(leader)):
		return root()
	return root().path_join(leader)

# [{name, path, modified, detail, legacy}] newest first; `detail` is the one-line description shown under the list. The
# leader's own come first, then the saves from before leaders (only when listing the leader's folder by default).
static func list(folder := "") -> Array:
	var entries := entries_in(folder if not folder.is_empty() else directory())
	if folder.is_empty() and directory() != root():
		for entry in entries_in(root()):
			entry.legacy = true
			entry.detail += "  •  " + TranslationServer.translate("From before leaders")
			entries.append(entry)
	return entries

static func entries_in(where: String) -> Array:
	var entries: Array = []
	for file in DirAccess.get_files_at(where):
		if not file.ends_with(".ez"):
			continue
		var path := where.path_join(file)
		var modified := FileAccess.get_modified_time(path)
		var handle := FileAccess.open(path, FileAccess.READ)
		var size := handle.get_length() if handle != null else 0
		entries.append({"name": file.trim_suffix(".ez"), "path": path, "modified": modified, "legacy": false,
			"detail": TranslationServer.translate("Saved %s  •  %.1f MB") % [Time.get_datetime_string_from_unix_time(modified, true).replace("T", " "), size / 1048576.0]})
	entries.sort_custom(func(a, b): return a.modified > b.modified)
	return entries

# The newest save, or an empty Dictionary.
static func latest(folder := "") -> Dictionary:
	var entries := list(folder)
	return entries[0] if not entries.is_empty() else {}
