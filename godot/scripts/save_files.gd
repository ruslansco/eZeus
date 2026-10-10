extends RefCounted
# The player's saved games: a directory per leader (user://saves/<leader>, scripts/leaders.gd), native .ez files inside it,
# newest first. Shared by the start menu and the in-game Game menu so both list the same files the same way. Saves from
# before leaders existed stay in the root and are listed after the leader's own, marked as such.

const UserSettings = preload("res://scripts/user_settings.gd")
const Campaigns = preload("res://scripts/campaign_library.gd")
static var info_cache := {}

# Tests point this at a scratch folder through Engine meta `ezeus_save_directory`; players never set it.
static func root() -> String:
	if Engine.has_meta("ezeus_save_directory"):
		return str(Engine.get_meta("ezeus_save_directory"))
	return ProjectSettings.globalize_path("user://saves")

# The chosen leader's folder (the root while no leader is chosen).
static func profile_directory() -> String:
	var leader := str(UserSettings.get_value("profile", "leader", ""))
	if leader.is_empty() or leader.begins_with(".") or leader.contains("/") or leader.contains("\\"):
		return root()
	return root().path_join(leader)

static func scope(ref: String) -> String:
	return "campaign-"+ref.sha256_text().left(20)

static func activate(ref: String) -> void:
	if ref.is_empty(): Engine.remove_meta("ezeus_active_campaign")
	else: Engine.set_meta("ezeus_active_campaign",ref)

static func directory() -> String:
	var ref := str(Engine.get_meta("ezeus_active_campaign",""))
	return profile_directory().path_join(".campaigns").path_join(scope(ref)) if not ref.is_empty() else profile_directory()

# [{name, path, modified, detail, legacy}] newest first; `detail` is the one-line description shown under the list. The
# leader's own come first, then the saves from before leaders (only when listing the leader's folder by default).
static func list(folder := "") -> Array:
	if not folder.is_empty(): return entries_in(folder)
	var entries := entries_for_profile(profile_directory())
	if profile_directory() != root():
		for entry in entries_in(root()):
			entry.legacy = true
			entry.detail += "  •  " + TranslationServer.translate("From before leaders")
			entries.append(entry)
	var leader := str(UserSettings.get_value("profile","leader",""))
	for previous in Campaigns.previous_profile_roots():
		var folders := [previous]
		if not leader.is_empty(): folders.append(previous.path_join(leader))
		for where in folders:
			for entry in entries_for_profile(where):
				if entries.any(func(existing): return existing.path == entry.path): continue
				entry.previous_profile = true
				entry.detail += " · "+TranslationServer.translate("Previous campaign profile")
				entries.append(entry)
	entries.sort_custom(func(a,b):return a.modified>b.modified if a.modified!=b.modified else a.path<b.path)
	return entries

static func entries_for_profile(where: String) -> Array:
	var entries := entries_in(where)
	var scopes := where.path_join(".campaigns")
	if DirAccess.dir_exists_absolute(scopes):
		for name in DirAccess.get_directories_at(scopes):
			if name.begins_with("campaign-"): entries.append_array(entries_in(scopes.path_join(name)))
	return entries

static func entries_in(where: String) -> Array:
	var entries: Array = []
	if not DirAccess.dir_exists_absolute(where): return entries
	var families: Dictionary={}
	for file in DirAccess.get_files_at(where):
		if file.ends_with(".ez"):families[file]=true
		elif file.ends_with(".ez.bak0") or file.ends_with(".ez.bak1") or file.ends_with(".ez.bak2"):families[file.left(file.length()-5)]=true
		elif file.contains(".ez.tmp-"):families[file.left(file.rfind(".ez.tmp-")+3)]=true
	for file in families:
		var path := where.path_join(file)
		var copies:=candidates(path)
		if copies.is_empty():continue
		var primary: bool=FileAccess.file_exists(path)
		var modified := FileAccess.get_modified_time(path if primary else str(copies[0].path))
		var handle := FileAccess.open(path, FileAccess.READ)
		var size := handle.get_length() if handle != null else 0
		var entry := {"name": file.trim_suffix(".ez"), "path": path, "modified": modified, "legacy": false,
			"recovery":copies.size()>1 or not primary,
			"detail": (TranslationServer.translate("Saved %s  •  %.1f MB") % [Time.get_datetime_string_from_unix_time(modified, true).replace("T", " "), size / 1048576.0])+("  · "+TranslationServer.translate("Recovery copies available") if copies.size()>1 or not primary else "")}
		entry.info = summary(path if primary else str(copies[0].path))
		var progress := Campaigns.progress_text(entry.info)
		if not progress.is_empty(): entry.detail = progress+"\n"+str(entry.detail)
		entries.append(entry)
	entries.sort_custom(func(a, b): return a.modified > b.modified)
	return entries

static func summary(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {}
	var checksum := -1
	if file.get_length() >= 40:
		file.seek(file.get_length()-40)
		if file.get_buffer(16).get_string_from_ascii() == "EZ3DSAVE-END0001":
			file.seek(file.get_length()-8); checksum = file.get_32()
	var key := "%s:%d:%d:%d" % [path,FileAccess.get_modified_time(path),file.get_length(),checksum]
	if checksum >= 0 and info_cache.has(key): return info_cache[key]
	var core = ClassDB.instantiate("EZeusSimulation") if ClassDB.class_exists("EZeusSimulation") else null
	var info: Dictionary = core.save_info(path) if core != null and core.has_method("save_info") else {}
	if info.has("error"): info = {}
	if info_cache.size() > 256: info_cache.clear()
	if checksum >= 0: info_cache[key] = info
	return info

static func candidates(path: String) -> Array:
	var result: Array=[]
	if FileAccess.file_exists(path):result.append({"path":path,"kind":"primary","modified":FileAccess.get_modified_time(path)})
	var recovery: Array=[]
	for suffix in [".bak1",".bak2",".bak0"]:
		var copy: String=path+str(suffix)
		if FileAccess.file_exists(copy):recovery.append({"path":copy,"kind":"backup","modified":FileAccess.get_modified_time(copy)})
	for file in DirAccess.get_files_at(path.get_base_dir()):
		if file.begins_with(path.get_file()+".tmp-"):
			var copy:=path.get_base_dir().path_join(file)
			recovery.append({"path":copy,"kind":"pending","modified":FileAccess.get_modified_time(copy)})
	recovery.sort_custom(func(a,b):return a.modified>b.modified if a.modified!=b.modified else a.path<b.path)
	result.append_array(recovery);return result

static func staging() -> String:
	return root().path_join(".load-staging") if Engine.has_meta("ezeus_save_directory") else ProjectSettings.globalize_path("user://save-staging")

# The newest save, or an empty Dictionary.
static func latest(folder := "") -> Dictionary:
	var entries := list(folder)
	return entries[0] if not entries.is_empty() else {}
