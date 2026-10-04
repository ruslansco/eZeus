extends SceneTree
# Per-user saves against the embedded core (headless): a saved city reloads to exactly the same gameplay state,
# saves go only into the configured directory, bad names and paths are refused, and the designated test save is
# never touched. Everything is written to a scratch directory that this script removes.
#   --keep=<dir>   write the saves into <dir> and leave them (tools/save_roundtrip.py compares them with the SDL build)
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("SAVE_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func road_count(state: Dictionary) -> int:
	var count := 0
	for tile in state.tiles:
		count += int(tile[4])
	return count

# A wall line, a gatehouse, mansions and parks on free ground (towers employ workers, which the native game redistributes on every load, so
# they are not part of this strict live-versus-reloaded comparison; validate_walls.gd saves and reloads one); returns where.
func build_defences(core: RefCounted, state: Dictionary, avoid: Vector2i) -> Dictionary:
	var result := {}
	var cells: Array = []
	for tile in state.tiles:
		if int(tile[5]):
			cells.append(Vector2i(int(tile[0]), int(tile[1])))
	var used: Array = []
	for what in ["gate", "wall"]:
		for cell in cells:
			if used.any(func(u): return absi(u.x - cell.x) < 8 and absi(u.y - cell.y) < 8) or absi(avoid.x - cell.x) < 8 and absi(avoid.y - cell.y) < 8:
				continue
			var ok: bool = core.command("preview gatehouse %d %d 0" % [cell.x, cell.y]).get("valid", false) if what == "gate" else core.command("preview_wall %d %d %d %d 0" % [cell.x, cell.y, cell.x + 5, cell.y]).get("new", 0) == 6
			if ok:
				result[what] = cell
				used.append(cell)
				break
	check(result.size() == 2, "free ground for a wall line and a gatehouse is found")
	core.command("build gatehouse %d %d 0" % [result.gate.x, result.gate.y])
	core.command("build_wall %d %d %d %d 0" % [result.wall.x, result.wall.y, result.wall.x + 5, result.wall.y])
	# A mansion grid and a block of parks (neither employs anyone).
	for what in ["elite_house", "park"]:
		for cell in cells:
			if used.any(func(u): return absi(u.x - cell.x) < 12 and absi(u.y - cell.y) < 12) or absi(avoid.x - cell.x) < 12 and absi(avoid.y - cell.y) < 12:
				continue
			var far: Vector2i = cell + (Vector2i(4, 4) if what == "elite_house" else Vector2i(3, 2))
			var plan: Dictionary = core.command("preview_area %s %d %d %d %d" % [what, cell.x, cell.y, far.x, far.y])
			if plan.get("complete", false) and int(plan.new) == (4 if what == "elite_house" else 12):
				used.append(cell)
				core.command("build_area %s %d %d %d %d 0" % [what, cell.x, cell.y, far.x, far.y])
				result[what] = cell
				break
	check(result.has("elite_house") and result.has("park"), "free ground for four mansions and twelve parks is found")
	return result

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	var keep := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--keep="):
			keep = argument.get_slice("=", 1)
	var directory := keep if keep != "" else ProjectSettings.globalize_path("user://validation_saves_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var refused: Dictionary = core.save_city("early")
	check(refused.has("error"), "saving before a city is open is refused")
	var initial: Dictionary = core.open_city(engine, designated, "en")
	check(initial.has("protocol"), "the designated test city opens")
	var early: Dictionary = core.save_city("no directory yet")
	check(early.get("error", "") == "save_directory_required", "saving needs a configured save directory")
	core.set_save_directory(directory)
	# A drag and a click change the city, so the round trip has something to prove.
	var site := Vector2i(99999, 99999)
	var finish := Vector2i(99999, 99999)
	for tile in initial.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var plan: Dictionary = core.command("preview_road %d %d %d %d" % [int(tile[0]), int(tile[1]), int(tile[0]) + 5, int(tile[1])])
		if plan.get("complete", false) and int(plan.new) == 6:
			site = Vector2i(int(tile[0]), int(tile[1]))
			finish = site + Vector2i(5, 0)
			break
	check(site != Vector2i(99999, 99999), "a free corridor exists for the round trip")
	var built: Dictionary = core.command("build_road %d %d %d %d" % [site.x, site.y, finish.x, finish.y])
	# Defences are saved too: a wall line and a gatehouse.
	var defences := build_defences(core, initial, site)
	built = core.snapshot(false)
	var money: int = built.money
	var roads := road_count(core.snapshot(true))
	var digest: String = core.replay(0, -1).digest
	var saved: Dictionary = core.save_city("first save")
	check(saved.get("saved", "") == "first save" and int(saved.get("bytes", 0)) > 100000, "the city is saved (%d bytes)" % int(saved.get("bytes", 0)))
	check(FileAccess.file_exists(directory.path_join("first save.ez")) and not FileAccess.file_exists(directory.path_join("first save.ez.tmp")), "the save is a finished .ez file with no leftover temporary")
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is unchanged")
	for bad in ["", ".hidden", "a/b", "..", "x".repeat(65), "tab\there", "a\\b", "a:b", "a*b", "a\"b"]:
		check(core.save_city(bad).get("error", "") == "invalid_save_name", "the save name %s is refused" % JSON.stringify(bad))
	check(DirAccess.get_files_at(directory).size() == 1, "refused names leave no file behind")
	core.close_city()
	var reopened: Dictionary = core.open_city(engine, directory.path_join("first save.ez"), "en")
	check(reopened.has("protocol") and int(reopened.money) == money and road_count(reopened) == roads, "the saved city reopens with the same treasury and roads")
	check(reopened.time == built.time and reopened.population == built.population, "and the same clock and population")
	check(core.replay(0, -1).digest == digest, "and the identical gameplay state (digest %s)" % digest)
	var back: Dictionary = core.snapshot(true)
	var gates: Array = back.buildings.filter(func(b): return b.asset == "gatehouse")
	check(gates.size() == 1 and int(gates[0].x) == defences.gate.x and int(gates[0].y) == defences.gate.y and int(gates[0].w) == 5, "the reopened city has its gatehouse where it was built")
	check(back.buildings.filter(func(b): return String(b.asset).begins_with("wall_")).size() >= 6, "and its wall line")
	check(back.buildings.filter(func(b): return String(b.asset).begins_with("elite_house_")).size() >= 4 and back.buildings.filter(func(b): return String(b.asset).begins_with("park")).size() >= 12, "and its mansions and parks")
	# Saving again overwrites that save; a second name is a second file.
	core.command("pause 0")
	var more: Dictionary = core.command("build road %d %d 0" % [finish.x + 1, finish.y])
	var overwritten: Dictionary = core.save_city("first save")
	check(overwritten.has("saved") and DirAccess.get_files_at(directory).size() == 1, "saving under the same name replaces the file")
	check(core.save_city("second.save-2").has("saved") and DirAccess.get_files_at(directory).size() == 2, "another name makes another file")
	check(core.save_city("Сохранение один").has("saved") and FileAccess.file_exists(directory.path_join("Сохранение один.ez")), "a name in another alphabet is saved as written")
	# Only the configured directory and the designated city can be opened.
	core.close_city()
	var outside := ProjectSettings.globalize_path("user://validation_outside_%d.ez" % Time.get_ticks_usec())
	DirAccess.copy_absolute(directory.path_join("first save.ez"), outside)
	check(core.open_city(engine, outside, "en").get("error", "") == "designated_test_save_required", "a save outside the save directory cannot be opened")
	check(core.open_city(engine, directory.path_join("missing.ez"), "en").has("error"), "a missing file cannot be opened")
	DirAccess.remove_absolute(outside)
	check(core.open_city(engine, designated, "en").has("protocol"), "the designated city still opens")
	check(core.save_city("after designated").has("saved"), "a city opened from the designated save can be saved to the directory")
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is still unchanged")
	core.close_city()
	if keep == "":
		for file in DirAccess.get_files_at(directory):
			DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	print("SAVE_DIGEST ", digest, " file=", directory.path_join("first save.ez"))
	print("SAVE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
