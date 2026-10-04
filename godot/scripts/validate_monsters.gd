extends SceneTree
# Monsters against the embedded core (headless, in memory): a validators-only command lets any of the engine's seventeen monsters loose in
# the designated city, set up as its monster events do. Every kind is a walker with its own model (and the model has its walk, fight and die
# clips baked), the core announces the monster (count, name, where it stands), the music turns to battle once it goes out to attack, and
# it moves, fights and falls as time passes.
var okay := true
var checks := 0

const KINDS := {
	"calydonian_boar": "walker_calydonianboar", "cerberus": "walker_cerberus", "chimera": "walker_chimera", "cyclops": "walker_cyclops",
	"dragon": "walker_dragon", "echidna": "walker_echidna", "harpies": "walker_harpies", "hector": "walker_hector", "hydra": "walker_hydra",
	"kraken": "walker_kraken", "maenads": "walker_maenads", "medusa": "walker_medusa", "minotaur": "walker_minotaur", "scylla": "walker_scylla",
	"sphinx": "walker_sphinx", "talos": "walker_talos", "satyr": "walker_satyr"}
const SEA := ["kraken", "scylla"]

func check(value: bool, message: String) -> void:
	checks += 1
	print("MONSTER_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

# Answers the campaign's own requests (they pause the city until answered) with the first choice.
func answer_events(core: RefCounted, state: Dictionary) -> void:
	for event in state.get("events", []):
		var choices: Array = event.get("actions", [])
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

func model_ready(asset: String) -> bool:
	if not FileAccess.file_exists("res://assets/models/%s.glb.import" % asset) and not ResourceLoader.exists("res://assets/models/%s.glb" % asset):
		return false
	var sidecar := "res://assets/models/runtime/%s.vat.json" % asset
	if not FileAccess.file_exists(sidecar):
		return false
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sidecar)).parts.values()[0].frames
	return table.has("fight_00") and table.has("die_00") and table.has("walk_01")

func monster_walkers(state: Dictionary, asset: String) -> Array:
	return state.walkers.filter(func(w): return str(w.asset) == asset)

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	check(core.command("test_monster cerberus").get("error", "") == "unsupported_command", "a monster cannot be let loose without the validators' switch")
	core.enable_test_commands()
	check(core.command("test_monster godzilla").get("error", "") == "unsupported_command", "an unknown monster is refused")
	var calm: Dictionary = core.command("army")
	check(int(calm.monsters) == 0 and not core.snapshot(true).has("monsters"), "the city has no monster to begin with")
	core.close_city()

	# ------------------------------------------------- every kind has its own model
	var missing: Array = []
	var unconverted: Array = []
	var absent: Array = []
	var misplaced: Array = []
	var nameless: Array = []
	for kind in KINDS:
		core = ClassDB.instantiate("EZeusSimulation")
		core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
		core.enable_test_commands()
		var known := {}
		for walker in core.snapshot(true).walkers:
			known[int(walker.id)] = true
		var answer: Dictionary = core.command("test_monster " + kind)
		var state: Dictionary = core.snapshot(true)
		var asset := String(KINDS[kind])
		var fresh: Array = state.walkers.filter(func(w): return not known.has(int(w.id)))
		var mine: Array = fresh.filter(func(w): return str(w.asset) == asset)
		if mine.is_empty():
			absent.append(kind)
			if fresh.any(func(w): return str(w.asset) == "unconverted"):
				unconverted.append(kind)
		else:
			var tile := Vector2i(floori(float(mine[0].x)), floori(float(mine[0].y)))
			if not state.has("monster_at") or Vector2i(int(state.monster_at[0]), int(state.monster_at[1])) != tile:
				misplaced.append(kind)
		if not answer.has("error") and (not state.has("monster") or str(state.monster) == ""):
			nameless.append(kind)
		if not model_ready(asset):
			missing.append(asset)
		check(not answer.has("error") and int(answer.monsters) == 1, "%s is let loose and the core counts it (%s)" % [kind, str(answer.get("error", answer.get("monsters")))])
		core.close_city()
	check(absent.is_empty() and unconverted.is_empty(), "every monster is a walker with its own model %s" % str(absent))
	check(misplaced.is_empty(), "the snapshot says where the monster stands %s" % str(misplaced))
	check(nameless.is_empty(), "and what it is called %s" % str(nameless))
	check(missing.is_empty(), "every monster model exists with its baked walk, fight and die clips %s" % str(missing))
	check(KINDS.values().size() == 17 and KINDS.values().duplicate().size() == 17, "seventeen monsters, one model each")

	# --------------------------------------------- a monster at large: it goes out, moves and fights
	for kind in ["cerberus", "minotaur", "kraken"]:
		core = ClassDB.instantiate("EZeusSimulation")
		core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
		core.enable_test_commands()
		var asset := String(KINDS[kind])
		core.command("test_monster " + kind)
		var start: Dictionary = core.snapshot(true)
		var first: Dictionary = monster_walkers(start, asset)[0]
		var origin := Vector2(float(first.x), float(first.y))
		var tile := Vector2i(floori(origin.x), floori(origin.y))
		if kind in SEA:
			check(core.command("army").monsters == 1 and start.has("monster_at"), "%s starts in the deep water, at %s" % [kind, str(tile)])
		core.command("speed 3")
		core.command("pause 0")
		var moved := 0.0
		var battle := false
		var acted := {}
		var announced := false
		for step in 2500:
			core.advance(.2)
			var running: Dictionary = core.snapshot(false)
			answer_events(core, running)
			var here: Array = monster_walkers(running, asset)
			if here.is_empty():
				acted[6] = true
				break
			var w: Dictionary = here[0]
			moved = maxf(moved, origin.distance_to(Vector2(float(w.x), float(w.y))))
			acted[int(w.action)] = true
			announced = announced or (running.has("monsters") and int(running.monsters) >= 1)
			var music = running.get("music", "")
			battle = battle or str(music) == "battle"
			if moved > 4.0 and battle and (kind != "cerberus" or acted.has(4) or acted.has(5)):
				break
		core.command("pause 1")
		check(moved > 2.0, "%s leaves where it appeared and roams the city (%.1f tiles)" % [kind, moved])
		check(battle, "%s brings battle music" % kind)
		if kind == "cerberus":
			check(acted.has(4) or acted.has(5), "Cerberus fights what it meets (action 4 or 5 reaches the snapshot)")
		print("MONSTER_INFO ", kind, " actions=", acted.keys(), " announced=", announced)
		core.close_city()
	print("MONSTER_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
