extends SceneTree
# Loading a saved city through the real scene start (the restart a load performs), headless:
# a save made in one session opens in the next with the same state, a missing or broken file falls back to the
# test city with a notice, and nothing is left behind. The designated save is only read.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("LOAD_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func start_city() -> Node:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var waited := 0
	while scene.state.is_empty() and waited < 600:
		await process_frame
		waited += 1
	for i in 10:
		await process_frame
	return scene

func roads(scene) -> int:
	var count := 0
	for cell in scene.tiles:
		count += int(scene.tiles[cell][4])
	return count

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	var name := "load test %d" % Time.get_ticks_usec()
	var first = await start_city()
	check(not first.state.is_empty(), "the test city starts")
	var directory: String = first.save_directory()
	var path := directory.path_join(name + ".ez")
	var untouched_money: int = first.state.money
	var untouched_roads := roads(first)
	# Change the city, then save it.
	var site := Vector2i(99999, 99999)
	for cell in first.tiles:
		if int(first.tiles[cell][5]) and not int(first.tiles[cell][4]) and first.core.query("preview road %d %d 0" % [cell.x, cell.y]).get("valid", false):
			site = cell
			break
	first.core.send("build road %d %d 0" % [site.x, site.y])
	for i in 40:
		await process_frame
	var saved_money: int = first.state.money
	check(saved_money < untouched_money and roads(first) == untouched_roads + 1, "a road is built before saving")
	check(first.save_game(name) and FileAccess.file_exists(path), "the changed city is saved")
	var saved_time: int = first.state.time
	first.free()
	await process_frame
	# The next session opens that file.
	Engine.set_meta("ezeus_load", path)
	var second = await start_city()
	check(not Engine.has_meta("ezeus_load"), "the pending load is consumed, so the next start is the default again")
	check(second.state.money == saved_money and roads(second) == untouched_roads + 1 and second.state.time == saved_time, "the loaded city has the saved treasury, road and clock")
	check(second.hud.undo_button.disabled and second.state.paused, "a loaded city starts paused with nothing to undo")
	check(second.hud.minimap.texture != null and second.hud.minimap.terrain.get_size() == Vector2i(second.extent), "the interface is rebuilt for the loaded city")
	second.free()
	await process_frame
	# The default start is still the test city, unchanged.
	var third = await start_city()
	check(third.state.money == untouched_money and roads(third) == untouched_roads, "starting without a load opens the test city as before")
	third.free()
	await process_frame
	# A broken file falls back to the test city.
	var broken := directory.path_join(name + " broken.ez")
	var file := FileAccess.open(broken, FileAccess.WRITE)
	file.store_string("this is not a city")
	file.close()
	Engine.set_meta("ezeus_load", broken)
	var fourth = await start_city()
	check(not fourth.state.is_empty() and fourth.state.money == untouched_money, "a broken save falls back to the test city")
	check(fourth.hint.text != "", "and says so")
	fourth.free()
	await process_frame
	# The live path: a running game asks to load, and the scene restarts around the file (the old city must be
	# released before the new one opens).
	var live = await start_city()
	current_scene = live
	live.core.send("build road %d %d 0" % [site.x, site.y])
	for i in 40:
		await process_frame
	var live_money: int = live.state.money
	live.save_game(name)
	live.load_game(path)
	for i in 240:
		await process_frame
		if current_scene != live and current_scene != null and not current_scene.state.is_empty():
			break
	var restarted = current_scene
	check(restarted != live and restarted != null and not restarted.state.is_empty(), "the running game restarts into the loaded city")
	if restarted != null and restarted != live and not restarted.state.is_empty():
		check(restarted.state.money == saved_money and roads(restarted) == untouched_roads + 1, "the restarted game has the saved city (treasury %d)" % int(restarted.state.money))
		check(restarted.hud.date_label.text != "" and restarted.language == "en", "and keeps its interface language")
		restarted.free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(broken)
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is unchanged")
	print("LOAD_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
