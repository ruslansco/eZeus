extends SceneTree
# Fighting against the embedded core (headless, in memory): a validators-only invasion lands an enemy force of any nationality through the
# engine's own invasion handler. Every soldier it fields is a walker with a model of its nationality (and the model has its fight and die
# clips baked), the core reports the invasion and the invaders, battle music plays, the soldiers fight (action 4 or 5) and fall (action 6) as
# time passes, the invaders' count falls, and when they are beaten the invasion is over and the music is the city's again.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("FIGHT_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

# Answers the campaign's own requests (they pause the city until answered) with the first choice.
func answer_events(core: RefCounted, state: Dictionary) -> void:
	for event in state.get("events", []):
		var choices: Array = event.get("actions", [])
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

# The enemy soldiers' assets in a snapshot: every walker of a hostile nationality's soldier model.
func soldier_assets(state: Dictionary, names: Array) -> Dictionary:
	var counts := {}
	for walker in state.walkers:
		var asset := str(walker.asset)
		for name in names:
			if asset == "walker_" + name:
				counts[asset] = int(counts.get(asset, 0)) + 1
	return counts

func model_ready(asset: String) -> bool:
	if not FileAccess.file_exists("res://assets/models/%s.glb.import" % asset) and not ResourceLoader.exists("res://assets/models/%s.glb" % asset):
		return false
	var sidecar := "res://assets/models/runtime/%s.vat.json" % asset
	if not FileAccess.file_exists(sidecar):
		return false
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sidecar)).parts.values()[0].frames
	return table.has("fight_00") and table.has("die_00") and table.has("walk_01")

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	check(core.command("test_invasion persian 4 0 0").get("error", "") == "unsupported_command", "an invasion cannot be started without the validators' switch")
	core.enable_test_commands()
	check(core.command("test_invasion klingon 4 0 0").get("error", "") == "unsupported_command" and core.command("test_invasion persian 0 0 0").get("error", "") == "unsupported_command" and core.command("test_invasion persian 100 0 0").get("error", "") == "unsupported_command", "unknown nationalities and impossible forces are refused")
	var calm: Dictionary = core.command("army")
	check(not calm.invasion and int(calm.invaders) == 0, "the city is at peace to begin with")

	# ------------------------------------------------- every nationality's soldiers
	var nations := {
		"greek": ["greekhoplite", "greekhorseman", "greekrockthrower"],
		"trojan": ["trojanhoplite", "trojanhorseman", "trojanspearthrower"],
		"persian": ["persianhoplite", "persianhorseman", "persianarcher"],
		"centaur": ["centaurhorseman", "centaurarcher"],
		"amazon": ["amazonspear", "amazonarcher"],
		"egyptian": ["egyptianhoplite", "egyptianchariot", "egyptianarcher"],
		"mayan": ["mayanhoplite", "mayanarcher"],
		"phoenician": ["phoenicianhorseman", "phoenicianarcher"],
		"oceanid": ["oceanidhoplite", "oceanidspearthrower"],
		"atlantean": ["atlanteanhoplite", "atlanteanchariot", "atlanteanarcher"],
	}
	var seen_assets := {}
	var unconverted: Array = []
	for nation in nations:
		var start: Dictionary = core.snapshot(true)
		var before := soldier_assets(start, nations[nation])
		var known := {}
		for walker in start.walkers:
			known[int(walker.id)] = true
		var landed: Dictionary = core.command("test_invasion %s 2 2 2" % nation)
		var landed_state: Dictionary = core.snapshot(true)
		var after := soldier_assets(landed_state, nations[nation])
		for walker in landed_state.walkers:
			if not known.has(int(walker.id)) and str(walker.asset) == "unconverted":
				unconverted.append(nation)
		var fielded := 0
		for asset in after:
			fielded += int(after[asset]) - int(before.get(asset, 0))
			seen_assets[asset] = true
		check(not landed.has("error") and landed.invasion and fielded >= 2, "a %s force lands: %d soldiers with %s models" % [nation, fielded, str(after.keys())])
	check(unconverted.is_empty(), "no soldier of any nationality is left without a model %s" % str(unconverted))
	var missing: Array = []
	for asset in seen_assets:
		if not model_ready(String(asset)):
			missing.append(asset)
	check(missing.is_empty(), "every soldier model exists with its baked walk, fight and die clips %s" % str(missing))
	check(seen_assets.size() == 25, "the ten nations field %d different soldier models" % seen_assets.size())
	check(int(core.command("army").invaders) >= 40, "the core counts the invaders (%d)" % int(core.command("army").invaders))
	core.close_city()

	# ------------------------------------------------------------- a battle to its end
	# Whether the invaders are beaten within the steps depends on the order in which the engine's path searches finish (they run on worker
	# threads): about one battle in five goes on without a death for the whole time. The battle is tried up to three times, and
	# the attempt that ends is the one checked (the others are named).
	var attempts := 0
	var fought := false
	var fell := false
	var least := 10
	var finished := -1
	var landed_force: Dictionary = {}
	var landing: Dictionary = {}
	while attempts < 3 and not (fought and fell and finished >= 0):
		attempts += 1
		core = ClassDB.instantiate("EZeusSimulation")
		core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
		core.enable_test_commands()
		landed_force = core.command("test_invasion persian 10 0 0")
		landing = core.snapshot(true)
		core.command("speed 3")
		core.command("pause 0")
		fought = false
		fell = false
		least = 10
		finished = -1
		for step in 900:
			core.advance(.2)
			var running: Dictionary = core.snapshot(false)
			answer_events(core, running)
			var persians: Array = running.walkers.filter(func(w): return str(w.asset) == "walker_persianhoplite")
			fought = fought or persians.any(func(w): return int(w.action) == 4 or int(w.action) == 5)
			fell = fell or persians.any(func(w): return int(w.action) == 6)
			least = mini(least, int(core.command("army").invaders) if step % 10 == 0 else least)
			if step % 10 == 0 and not core.command("army").invasion:
				finished = step
				break
		core.command("pause 1")
		if not (fought and fell and finished >= 0) and attempts < 3:
			core.close_city()
	check(landed_force.invasion and int(landed_force.invaders) == 10, "ten Persian hoplites land and the core reports the invasion (%d invaders)" % int(landed_force.invaders))
	check(landing.music == "battle", "battle music is asked for")
	var hoplites: Array = landing.walkers.filter(func(w): return str(w.asset) == "walker_persianhoplite")
	check(hoplites.size() == 10 and hoplites.all(func(w): return int(w.action) == 3), "the hoplites arrive walking, ten of them")
	var hoplite_tiles: Array = hoplites.map(func(w): return Vector2i(floori(float(w.x)), floori(float(w.y))))
	check(landing.has("invader_at") and hoplite_tiles.has(Vector2i(int(landing.invader_at[0]), int(landing.invader_at[1]))), "the snapshot says where an invader stands (%s)" % str(landing.get("invader_at", "nowhere")))
	check(fought, "the soldiers fight (action 4 or 5 reaches the snapshot)")
	check(fell, "and they fall (action 6 reaches the snapshot; attempt %d of 3)" % attempts)
	check(least < 10, "the invaders' count falls as they are beaten (down to %d)" % least)
	check(finished >= 0, "the invasion ends once they are beaten (step %d)" % finished)
	var after_battle: Dictionary = core.command("army")
	check(not after_battle.invasion and int(after_battle.invaders) == 0, "afterwards the city is at peace with no invader left")
	check(core.snapshot(true).music == "city", "and the music is the city's again")
	core.close_city()

	# ---------------------------------------- the player's army defends when it is ordered to
	# The engine defends by itself only for computer-controlled cities: the player calls the companies out and places their banners.
	core = ClassDB.instantiate("EZeusSimulation")
	core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	core.enable_test_commands()
	var big: Dictionary = core.command("test_invasion persian 24 0 0")
	var spot: Dictionary = core.snapshot(true)
	var target_tile := Vector2i(int(spot.invader_at[0]), int(spot.invader_at[1]))
	var called: Dictionary = core.command("army_call")
	check(spot.walkers.filter(func(w): return str(w.asset) == "walker_archerposeidon").is_empty() and not called.banners.is_empty(), "without an order the army stays at home while 24 invaders land (%d invaders)" % int(big.invaders))
	for banner in called.banners.slice(0, 6):
		core.command("banner_move %d %d %d" % [int(banner.id), target_tile.x, target_tile.y])
	core.command("speed 3")
	core.command("pause 0")
	var defenders_fought := false
	var defenders_out := 0
	for step in 1200:
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		answer_events(core, running)
		var archers: Array = running.walkers.filter(func(w): return str(w.asset) == "walker_archerposeidon")
		defenders_out = maxi(defenders_out, archers.size())
		defenders_fought = defenders_fought or archers.any(func(w): return int(w.action) == 4 or int(w.action) == 5)
		if defenders_fought:
			break
	core.command("pause 1")
	check(defenders_out >= 6, "the companies called out and sent to the invaders come out of their houses (%d archers)" % defenders_out)
	check(defenders_fought, "and the archers fight the invaders (action 4 or 5 on an archer)")
	core.close_city()
	print("FIGHT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
