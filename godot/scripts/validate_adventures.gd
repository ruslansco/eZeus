extends SceneTree
# New games against the embedded core (headless, scratch saves only): every adventure the start menu lists opens
# paused with its first episode, a map, a treasury, a title and objectives, and a place to build near the starting
# view; saved games of three adventures reload to exactly the same gameplay state; a path or name that is not in the
# listing is refused; Russian lists the same adventures with their Russian titles.
#   --keep=<dir>   write the saves into <dir> and leave them (tools/save_roundtrip.py opens them in the SDL build)
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("ADVENTURE_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func buildable_near(state: Dictionary, radius: int) -> int:
	var focus: Array = state.focus
	var count := 0
	for tile in state.tiles:
		if int(tile[5]) and absi(int(tile[0]) - int(focus[0])) <= radius and absi(int(tile[1]) - int(focus[1])) <= radius:
			count += 1
	return count

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	var keep := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--keep="):
			keep = argument.get_slice("=", 1)
	var scratch := keep if not keep.is_empty() else ProjectSettings.globalize_path("res://captures/validation-adventures-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	var english: Dictionary = core.adventures(engine, "en")
	var list: Array = english.get("adventures", [])
	check(list.size() >= 24, "the listing offers %d adventures" % list.size())
	var kinds := {}
	for item in list:
		kinds[item.kind] = true
	check(kinds.has("pak") and kinds.has("folder"), "it mixes the original campaigns (pak) and the engine's own (folder)")
	var saved: Array = []
	var failures: Array = []
	var sparse: Array = []
	for item in list:
		var state: Dictionary = core.open_adventure(engine, item.kind, item.ref, "en")
		if state.has("error"):
			failures.append("%s: %s" % [item.title, state.error])
			core.close_city()
			continue
		var episode: Dictionary = core.command("episode")
		var problems: Array = []
		if state.tiles.size() < 10000: problems.append("tiles")
		if not state.paused: problems.append("not paused")
		if int(state.money) < 0: problems.append("treasury")
		if str(episode.get("title", "")).is_empty(): problems.append("title")
		if state.buildings.any(func(b): return b.asset == "unconverted"): problems.append("unconverted")
		if buildable_near(state, 25) < 100: sparse.append(item.title)
		if not problems.is_empty():
			failures.append("%s: %s" % [item.title, ", ".join(problems)])
		if item.title in ["The Founding of Athens", "Open Play Sandbox", "The Odyssey"]:
			saved.append(item)
			var written: Dictionary = core.save_city(str(item.title).replace(" ", "-"))
			var before: Dictionary = core.replay(0, 7)
			core.close_city()
			var reopened: Dictionary = core.open_city(engine, scratch.path_join(str(item.title).replace(" ", "-") + ".ez"), "en")
			var after: Dictionary = core.replay(0, 7)
			check(written.has("saved") and not reopened.has("error") and before.digest == after.digest, "%s saves and reloads to the same state (%s)" % [item.title, str(after.get("digest", ""))])
			if keep != "" and item.title == "The Founding of Athens":
				print("ADVENTURE_DIGEST ", after.digest, " file=", scratch.path_join("The-Founding-of-Athens.ez"))
		core.close_city()
	check(failures.is_empty(), "every adventure opens paused with a map, a treasury, a title and no placeholder buildings %s" % str(failures.slice(0, 4)))
	check(sparse.size() <= 2, "the starting view of nearly every adventure has room to build (thin: %s)" % str(sparse))
	# Only listed adventures can be opened.
	check(core.open_adventure(engine, "pak", "/etc/passwd", "en").has("error"), "a path outside the listing is refused")
	check(core.open_adventure(engine, "folder", "../Hippodamus", "en").has("error"), "a folder name outside the listing is refused")
	check(core.open_adventure(engine, "banana", "x", "en").has("error"), "an unknown kind is refused")
	core.close_city()
	# Russian: the same adventures, their titles in Russian.
	var russian: Dictionary = core.adventures(engine, "ru")
	var cyrillic := 0
	for item in russian.get("adventures", []):
		cyrillic += 1 if String(item.title).unicode_at(0) >= 0x400 else 0
	check(russian.get("adventures", []).size() == list.size() and cyrillic >= 15, "Russian lists the same adventures (%d with Russian titles)" % cyrillic)
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is untouched")
	if keep.is_empty():
		for file in DirAccess.get_files_at(scratch):
			DirAccess.remove_absolute(scratch.path_join(file))
		DirAccess.remove_absolute(scratch)
	print("ADVENTURE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
