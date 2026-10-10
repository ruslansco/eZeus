extends RefCounted
# Local private content index. Native templates remain the objective/rule authority.
const INDEX := "res://data/development_campaigns.json"

static func records() -> Array:
	var path := str(Engine.get_meta("ezeus_campaign_library_path",INDEX))
	if not FileAccess.file_exists(path): return []
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value.get("campaigns",[]) if value is Dictionary and int(value.get("schema_version",0)) == 1 else []

static func record(ref: String) -> Dictionary:
	var base := ref.get_file()
	for item in records():
		var iref := str(item.get("ref", ""))
		if iref == ref or iref == base or (not iref.is_empty() and ref.ends_with("/" + iref)):
			return item
	return {}

static func title(ref: String) -> String:
	var item := record(ref)
	var code := TranslationServer.get_locale().get_slice("_",0)
	return str(item.get("title",{}).get(code,item.get("title",{}).get("en",ref)))

static func chapter_title(ref: String, number: int) -> String:
	var item := record(ref)
	var code := TranslationServer.get_locale().get_slice("_",0)
	var chapters: Array = item.get("chapters",{}).get(code,item.get("chapters",{}).get("en",[]))
	return str(chapters[number-1]) if number > 0 and number <= chapters.size() else ""

static func previous_profile_roots() -> Array:
	# Explicit scratch/single-campaign roots never scan the player's other profiles.
	if Engine.has_meta("ezeus_save_directory") and not Engine.get_meta("ezeus_include_campaign_profiles",false): return []
	var result := []
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	for item in records():
		for relative in item.get("profile_roots",[]):
			var path: String = repo.path_join(str(relative)).simplify_path()
			if path.begins_with(repo+"/") and DirAccess.dir_exists_absolute(path): result.append(path)
	return result

static func previous_leaders() -> Array:
	var names := []
	for path in previous_profile_roots():
		for name in DirAccess.get_directories_at(path):
			if not name.begins_with(".") and not names.has(name): names.append(name)
	return names

static func progress_text(info: Dictionary) -> String:
	var ref := str(info.get("campaign_ref",""))
	if ref.is_empty(): return ""
	var number := int(info.get("episode_number",1))
	var chapter := chapter_title(ref,number)
	var label := TranslationServer.translate("Colony %d") if info.get("colony",false) else TranslationServer.translate("Chapter %d")
	return title(ref)+" · "+label%number+(" · "+chapter if not chapter.is_empty() else "")
