extends SceneTree
# Campaign progression against the embedded core (headless, scratch saves): every adventure is played from its first
# episode to its end by fulfilling each episode's goals with the test command (the same path the board's own goal check
# takes), through the commands the front end uses: finish_episode, choose_colony, begin_episode. Along the way the rules
# of the flow are checked (nothing starts early or twice, only offered colonies can be chosen), the city and treasury
# carry from one parent episode to the next, a colony is another city and the campaign returns to the parent afterwards,
# a game saved mid-campaign resumes at the same point, goods are set aside for a goal, and difficulty is kept.
var okay := true
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	print("CAMPAIGN_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func roads(state: Dictionary) -> int:
	var count := 0
	for tile in state.tiles:
		count += int(tile[4])
	return count

func free_tile(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if int(tile[5]) and not int(tile[4]) and core.command("preview %s %d %d 0" % [tool, tile[0], tile[1]]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func adventure(list: Array, title: String) -> Dictionary:
	for item in list:
		if item.title == title:
			return item
	return {}

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var scratch := ProjectSettings.globalize_path("res://captures/validation-campaign-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	var list: Array = core.adventures(engine, "en").adventures

	# The test commands are not part of the game.
	var athens := adventure(list, "The Founding of Athens")
	core.open_adventure(engine, athens.kind, athens.ref, "en")
	check(core.command("test_win").has("error") and core.command("test_stock 1 1").has("error"), "the test commands are refused unless a validator enables them")
	core.enable_test_commands()

	# The rules of the flow, on The Founding of Athens.
	var state: Dictionary = core.snapshot(true)
	var first: Dictionary = core.command("episode")
	check(first.episode_number == 1 and first.episode_count == 4 and not first.colony and not first.victory and not first.defeat and first.total == 4, "the first episode is 1 of 4 with four objectives")
	check(core.command("finish_episode").has("error") and core.command("begin_episode").has("error") and core.command("choose_colony 0").has("error"), "nothing in the campaign flow works before the goals are met")
	var levels: Dictionary = core.command("difficulty")
	check(levels.value == 2 and levels.names.size() == 5, "the difficulty starts at hero with five levels (%s)" % str(levels.names))
	var road_at := free_tile(core, state, "road")
	var cheap: Dictionary = core.command("preview road %d %d 0" % [road_at.x, road_at.y])
	core.command("difficulty 0")
	var easy: Dictionary = core.command("preview road %d %d 0" % [road_at.x, road_at.y])
	core.command("difficulty 4")
	var hard: Dictionary = core.command("preview road %d %d 0" % [road_at.x, road_at.y])
	check(int(easy.cost) < int(hard.cost) and core.command("difficulty 7").has("error") and core.command("episode").difficulty == 4, "difficulty changes the cost of building (%d beginner, %d olympian) and is refused out of range" % [easy.cost, hard.cost])
	core.command("difficulty 2")
	# Goods set aside.
	var warehouse_at := free_tile(core, state, "warehouse")
	core.command("build warehouse %d %d 0" % [warehouse_at.x, warehouse_at.y])
	var oil_goal := -1
	for goal in core.command("episode").goals:
		if str(goal.text).contains("olive oil") or str(goal.text).contains("oil"):
			oil_goal = int(goal.index)
	check(oil_goal >= 0 and core.command("set_aside %d" % oil_goal).get("error", "") == "not_enough_goods", "an empty store cannot set goods aside")
	core.command("test_stock 2048 15")
	check(core.command("set_aside %d" % oil_goal).get("error", "") == "not_enough_goods", "fifteen of sixteen is not enough")
	core.command("test_stock 2048 5")
	var before: Dictionary = core.command("episode")
	check(before.goals[oil_goal].set_aside and not before.goals[oil_goal].met, "with the goods in store the goal offers to set them aside")
	var after: Dictionary = core.command("set_aside %d" % oil_goal)
	check(after.goals[oil_goal].met and not after.goals[oil_goal].set_aside and core.command("set_aside %d" % oil_goal).has("error") and core.command("set_aside 99").has("error"), "setting aside meets the goal once; again, or an unknown goal, is refused")
	# The first episode is won; a road built on the way must survive into the next episode of the same city.
	var money_before := int(core.snapshot(false).money)
	var roads_before := roads(core.snapshot(true))
	core.command("build road %d %d 0" % [road_at.x, road_at.y])
	var road_cost := money_before - int(core.snapshot(false).money)
	var win: Dictionary = core.command("test_win")
	check(win.blocked and core.command("episode").victory and core.command("episode").finished, "a won episode stops the game and reports victory")
	var money_at_win := int(core.snapshot(false).money)
	var step: Dictionary = core.command("finish_episode")
	check(step.next == "colonies" and step.colonies.size() == 2 and core.command("finish_episode").has("error"), "after the first episode the campaign offers two colonies, and finishing twice is refused")
	check(core.command("begin_episode").get("error", "") == "no_colony_choice", "an episode cannot begin before a colony is chosen")
	check(core.command("choose_colony -1").has("error") and core.command("choose_colony 99").has("error"), "only an offered colony can be chosen")
	var thebes: Dictionary = core.command("choose_colony %d" % int(step.colonies[0].index))
	check(thebes.kind == "episode_preview" and thebes.colony and thebes.goals.size() >= 1 and not str(thebes.introduction).is_empty(), "choosing a colony previews its story and goals")
	check(not FileAccess.file_exists(scratch.path_join("autosave replay.ez")), "nothing is saved before an episode begins")
	var begun: Dictionary = core.command("begin_episode")
	var colony_state: Dictionary = core.snapshot(true)
	check(begun.kind == "episode_started" and begun.colony and colony_state.paused and colony_state.tiles.size() != state.tiles.size() and core.command("episode").colony, "beginning it opens the colony: another map, paused")
	check(FileAccess.file_exists(scratch.path_join("autosave replay.ez")), "the episode's start is saved so it can be tried again")
	# A game saved in the middle of the campaign resumes there.
	check(core.save_city("mid campaign").has("saved"), "the colony episode is saved")
	var colony_goals: Array = core.command("episode").goals.map(func(goal): return goal.text)
	core.close_city()
	var resumed: Dictionary = core.open_city(engine, scratch.path_join("mid campaign.ez"), "en")
	var resumed_episode: Dictionary = core.command("episode")
	check(not resumed.has("error") and resumed_episode.colony and resumed_episode.goals.map(func(goal): return goal.text) == colony_goals, "a game saved in a colony opens in that colony with the same objectives")
	core.enable_test_commands()
	core.command("test_win")
	var back: Dictionary = core.command("finish_episode")
	check(back.next == "episode" and not back.preview.colony and back.preview.episode_number == 2, "finishing the colony returns the campaign to the second parent episode")
	var difficulty_kept: int = int(core.command("difficulty").value)
	core.command("begin_episode")
	var second: Dictionary = core.snapshot(true)
	check(second.tiles.size() == state.tiles.size() and roads(second) == roads_before + 1 and core.command("episode").episode_number == 2, "the parent city is back with the road built in the first episode")
	check(difficulty_kept == 2 and core.command("episode").difficulty == 2, "the difficulty is kept")
	check(not core.command("episode").victory and not second.blocked, "the new episode is running, not finished")
	core.close_city()

	# Money carries from one parent episode to the next.
	var peloponnese := adventure(list, "The Peloponnesian War")
	core.open_adventure(engine, peloponnese.kind, peloponnese.ref, "en")
	core.enable_test_commands()
	var spot := free_tile(core, core.snapshot(true), "road")
	core.command("build road %d %d 0" % [spot.x, spot.y])
	var treasury := int(core.snapshot(false).money)
	core.command("test_win")
	core.command("finish_episode")
	core.command("begin_episode")
	check(int(core.snapshot(false).money) == treasury and treasury < 7500, "the treasury carries into the next episode (%d)" % treasury)
	core.close_city()

	# Every adventure, to its end.
	var finished := 0
	var with_colonies := 0
	var problems: Array = []
	var episodes_played := 0
	for item in list:
		var opened: Dictionary = core.open_adventure(engine, item.kind, item.ref, "en")
		core.enable_test_commands()
		var steps := 0
		var ended := false
		var saw_colony := false
		var last_parent_tiles := 0
		while steps < 40 and not ended:
			steps += 1
			episodes_played += 1
			var snapshot: Dictionary = core.snapshot(true)
			var episode: Dictionary = core.command("episode")
			if episode.colony:
				saw_colony = true
			else:
				if last_parent_tiles != 0 and snapshot.tiles.size() != last_parent_tiles:
					problems.append("%s: the parent city changed size" % item.title)
				last_parent_tiles = snapshot.tiles.size()
			if not snapshot.paused or snapshot.blocked or snapshot.tiles.size() < 3000:
				problems.append("%s: episode %d did not open paused and running" % [item.title, steps])
			core.command("test_win")
			var next: Dictionary = core.command("finish_episode")
			if next.has("error"):
				problems.append("%s: finish failed (%s)" % [item.title, next.error])
				break
			if next.next == "complete":
				ended = true
				if str(next.complete).is_empty() and str(next.title).is_empty():
					problems.append("%s: the end has no words" % item.title)
				break
			if next.next == "colonies":
				var chosen: Dictionary = core.command("choose_colony %d" % int(next.colonies[0].index))
				if chosen.has("error"):
					problems.append("%s: choosing failed (%s)" % [item.title, chosen.error])
					break
			var started: Dictionary = core.command("begin_episode")
			if started.has("error"):
				problems.append("%s: begin failed (%s)" % [item.title, started.error])
				break
		finished += 1 if ended else 0
		with_colonies += 1 if saw_colony else 0
		core.close_city()
	check(problems.is_empty(), "every adventure plays through its episodes without a fault %s" % str(problems.slice(0, 3)))
	check(finished == list.size() and with_colonies >= 15 and episodes_played >= 80, "all %d adventures reach their end (%d visit colonies, %d episodes played)" % [finished, with_colonies, episodes_played])
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	print("CAMPAIGN_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
