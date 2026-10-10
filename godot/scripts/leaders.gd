extends RefCounted
# The roster of leaders (the SDL game's eRosterOfLeaders): each leader has a folder of saves under the player's save root
# (user://saves/<leader>), the chosen one is remembered in user://settings.cfg, and its name is the one the city's messages
# address. Saves from before leaders existed stay in the root, untouched, and are offered to every leader.

const SaveFiles = preload("res://scripts/save_files.gd")
const UserSettings = preload("res://scripts/user_settings.gd")
const Campaigns = preload("res://scripts/campaign_library.gd")
const MAX_LENGTH := 24
const FORBIDDEN := ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]

static func root() -> String:
	return SaveFiles.root()

static func list() -> Array:
	var names: Array = []
	if DirAccess.dir_exists_absolute(root()):
		for name in DirAccess.get_directories_at(root()):
			if not name.begins_with("."):
				names.append(name)
	for name in Campaigns.previous_leaders():
		if not names.has(name): names.append(name)
	names.sort_custom(func(a, b): return String(a).naturalnocasecmp_to(String(b)) < 0)
	return names

static func current() -> String:
	var name := str(UserSettings.get_value("profile", "leader", ""))
	return name if not name.is_empty() and name in list() else ""

static func set_current(name: String) -> void:
	UserSettings.set_value("profile", "leader", name)

# Why a name cannot be a leader's ("" when it can): empty, too long, a character a folder may not have, or taken.
static func problem(name: String) -> String:
	var clean := name.strip_edges()
	if clean.is_empty():
		return "Enter a name"
	if clean.length() > MAX_LENGTH:
		return "That name is too long"
	if clean.begins_with("."):
		return "That name cannot be used"
	for character in FORBIDDEN:
		if clean.contains(character):
			return "That name cannot be used"
	for existing in list():
		if String(existing).to_lower() == clean.to_lower():
			return "There is a leader of that name already"
	return ""

static func create(name: String) -> bool:
	var clean := name.strip_edges()
	if not problem(clean).is_empty():
		return false
	return DirAccess.make_dir_recursive_absolute(root().path_join(clean)) == OK

# Removes a leader: the saves in its folder and the folder (nothing outside the save root is ever touched).
static func can_delete(name: String) -> bool:
	var directory := DirAccess.open(root())
	return directory != null and name in list() and not name in Campaigns.previous_leaders() and not directory.is_link(root().path_join(name)) and DirAccess.dir_exists_absolute(root().path_join(name))

static func remove_folder(folder: String) -> bool:
	var directory := DirAccess.open(folder)
	if directory == null: return false
	directory.include_hidden = true
	directory.include_navigational = false
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := folder.path_join(name)
		if directory.is_link(child):
			if DirAccess.remove_absolute(child) != OK: return false
		elif directory.current_is_dir():
			if not remove_folder(child): return false
		elif DirAccess.remove_absolute(child) != OK: return false
		name = directory.get_next()
	directory.list_dir_end()
	return DirAccess.remove_absolute(folder) == OK

static func delete(name: String) -> bool:
	if not can_delete(name):
		return false
	var folder := root().path_join(name)
	var removed := remove_folder(folder)
	if removed and str(UserSettings.get_value("profile", "leader", "")) == name:
		set_current("")
	return removed
