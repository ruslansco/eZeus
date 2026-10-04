extends SceneTree
# The heroes' halls against the embedded core (headless, in memory): the eight halls are in the build list with their own models and
# names, a god's quest lets the city build the hero's hall (the engine's `allowHero`), the hall is built and recorded as built, the
# inspection lists the hero's requirements with how far the city is from each (in the core's language) and the summon is refused until
# every requirement is met and for a stale inspection, the hero arrives (the engine's own arrival: the event with its words, the hero
# walker with its model), the hero fights and slays the monster he is the slayer of, and the quest a god asks of him is sent on its way
# through the world's `quests`. English and Russian.
var okay := true
var checks := 0

const HEROES := ["achilles", "atalanta", "bellerophon", "hercules", "jason", "odysseus", "perseus", "theseus"]
const HERO_NAMES := {"en": {"achilles": "Achilles", "atalanta": "Atalanta", "bellerophon": "Bellerophon", "hercules": "Hercules", "jason": "Jason", "odysseus": "Odysseus", "perseus": "Perseus", "theseus": "Theseus"}}

func check(value: bool, message: String) -> void:
	checks += 1
	print("HERO_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func has_cyrillic(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x0400 and code <= 0x04FF:
			return true
	return false

func spot(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		var query: Dictionary = core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])])
		if query.get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func model_ready(asset: String) -> bool:
	return FileAccess.file_exists("res://assets/models/%s.glb.import" % asset) or ResourceLoader.exists("res://assets/models/%s.glb" % asset)

func clip_ready(asset: String) -> bool:
	var sidecar := "res://assets/models/runtime/%s.vat.json" % asset
	if not FileAccess.file_exists(sidecar):
		return false
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sidecar)).parts.values()[0].frames
	return table.has("fight_00") and table.has("die_00") and table.has("walk_01")

func item_of(items: Array, name: String) -> Dictionary:
	for item in items:
		if str(item.name) == name:
			return item
	return {}

# Lets a monster loose and runs the city until it is gone; true when the hero fought and the monster fell and vanished.
func slay(core: RefCounted, hero_key: String, monster_kind: String) -> Dictionary:
	var hero_asset := "walker_" + hero_key
	var monster_asset := "walker_" + monster_kind.replace("_", "")
	core.command("test_monster " + monster_kind)
	core.command("speed 3")
	core.command("pause 0")
	var result := {"fought": false, "fell": false, "gone": -1}
	var started := Time.get_ticks_msec()
	for step in 1500:
		# A hero who could not reach the monster would keep searching for a path; the check ends rather than waits for it.
		if Time.get_ticks_msec() - started > 60000:
			break
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		for event in running.get("events", []):
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		var monster_here := false
		var trace := ""
		for walker in running.walkers:
			if str(walker.asset) == hero_asset:
				trace += " H(%.1f,%.1f a=%d)" % [float(walker.x), float(walker.y), int(walker.action)]
				if int(walker.action) == 4 or int(walker.action) == 5:
					result.fought = true
			if str(walker.asset) == monster_asset:
				monster_here = true
				trace += " M(%.1f,%.1f a=%d)" % [float(walker.x), float(walker.y), int(walker.action)]
				result.fell = result.fell or int(walker.action) == 6
		if step % 40 == 0 and OS.get_environment("HERO_TRACE") != "":
			print("HERO_TRACE ", hero_key, " vs ", monster_kind, " step ", step, trace)
		if not monster_here and step > 10:
			result.gone = step
			break
	core.command("pause 1")
	return result

func run_language(lang: String, engine: String) -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	check(initial.has("protocol"), lang + " designated test city loads paused")
	# A fixed seed: the hunt and the fight depend on the simulation's random draws, which a session that ran before would otherwise change.
	core.replay(0, 11)
	check(core.command("test_quest hades 1").get("error", "") == "unsupported_command" and core.command("test_hero perseus").get("error", "") == "unsupported_command" and core.command("test_allow hero_hall_jason").get("error", "") == "unsupported_command", lang + " the validators' hero commands need the validators' switch")
	core.enable_test_commands()

	# ------------------------------------------------------------------------------------------- the eight halls
	var items: Array = core.command("buildable").buildings
	var halls: Array = items.filter(func(item): return str(item.name).begins_with("hero_hall_"))
	check(halls.size() == 8 and halls.all(func(item): return str(item.asset) == str(item.name) and model_ready(str(item.asset))), lang + " the eight heroes' halls are listed, each with its own model")
	var named := true
	for hero in HEROES:
		var item := item_of(items, "hero_hall_" + hero)
		named = named and not item.is_empty() and (lang != "en" or str(item.label) == "Hero's Hall for " + str(HERO_NAMES.en[hero]).capitalize()) and (lang != "ru" or has_cyrillic(str(item.label)))
	check(named, lang + " each hall has its hero's name in the core's language")
	check(halls.all(func(item): return int(item.w) == 4 and int(item.h) == 4), lang + " a hall is four tiles by four")
	check(halls.all(func(item): return not bool(item.available)), lang + " the test city is offered none of them: a scenario decides which heroes may come")

	# ----------------------------------------------------------- a god's quest lets the city build the hero's hall
	var before: Dictionary = core.command("world")
	var asked: int = (before.quests as Array).size()
	var world: Dictionary = core.command("test_quest hades 1")
	var quest: Dictionary = (world.quests as Array)[(world.quests as Array).size() - 1]
	check((world.quests as Array).size() == asked + 1 and str(quest.hero_name) != "" and str(quest.god_name) != "" and str(quest.name) != "" and not bool(quest.ready), lang + " the god's quest is listed with its god, hero and name: %s asks %s: %s" % [str(quest.god_name), str(quest.hero_name), str(quest.name)])
	var hero_key: String = HEROES[int(quest.hero)]
	var offered: Dictionary = item_of(core.command("buildable").buildings, "hero_hall_" + hero_key)
	check(bool(offered.available) and not bool(quest.hall), lang + " the quest lets the city build %s's hall (the engine's allowHero)" % str(quest.hero_name))
	var refused: Dictionary = core.command("test_allow hero_hall_jason")
	check(bool(item_of(refused.buildings, "hero_hall_jason").available) and core.command("test_allow hero_hall_nobody").has("error"), lang + " the validators' switch can allow another hall and refuses an unknown one")

	# --------------------------------------------------------------------------------- building the hall
	var state: Dictionary = core.snapshot(true)
	var at := spot(core, state, "hero_hall_" + hero_key)
	check(at.x != 99999, lang + " the hall has a free site (%s)" % str(at))
	var built: Dictionary = core.command("build hero_hall_%s %d %d 0" % [hero_key, at.x, at.y])
	check(not built.has("error"), lang + " the hall is built (%s)" % str(built.get("error", "ok")))
	var after: Dictionary = core.snapshot(true)
	check(after.buildings.any(func(b): return str(b.asset) == "hero_hall_" + hero_key), lang + " the hall appears in the city with its model")
	check(not bool(item_of(core.command("buildable").buildings, "hero_hall_" + hero_key).available) and core.command("build hero_hall_%s %d %d 0" % [hero_key, at.x + 8, at.y]).get("error", "") == "building_not_available", lang + " a hero has one hall: it is recorded as built and no second is offered")

	# ------------------------------------------------------------------------------------ the inspection
	var inspection: Dictionary = core.command("inspect %d %d" % [at.x, at.y])
	var hall: Dictionary = inspection.get("hall", {})
	check(not hall.is_empty() and hall.stage == "none" and not bool(hall.on_quest) and not bool(hall.can_summon) and str(hall.hero_name) == str(quest.hero_name), lang + " the inspection of the new hall: stage none, nothing summoned")
	var requirements: Array = hall.get("requirements", [])
	check(requirements.size() >= 4 and requirements.all(func(r): return str(r.text).length() > 3 and str(r.status).length() > 0), lang + " it lists the hero's requirements with how far the city is from each (%d)" % requirements.size())
	check(requirements.any(func(r): return bool(r.met)) and requirements.any(func(r): return not bool(r.met)), lang + " some are met and some are not (%s)" % str(requirements.map(func(r): return bool(r.met))))
	if lang == "ru":
		check(requirements.all(func(r): return has_cyrillic(str(r.text))), "ru the requirements are in Russian: " + str(requirements[0].text))
	var token: int = int(inspection.target_token)
	check(core.command("hero_summon %d %d %d" % [at.x, at.y, token]).get("error", "") == "requirements_not_met", lang + " the hero cannot be summoned while a requirement is unmet")
	check(core.command("hero_summon %d %d %d" % [at.x, at.y, token + 1]).get("error", "") == "inspection_target_changed", lang + " a stale inspection token is refused")
	check(core.command("hero_summon %d %d %d" % [at.x + 20, at.y, token]).get("error", "") == "no_hall" or core.command("hero_summon %d %d %d" % [at.x + 20, at.y, token]).has("error"), lang + " nothing but a hall can be summoned from")
	check(core.command("hero_summon %d %d" % [at.x, at.y]).has("error"), lang + " a summon without a token is refused")

	# The hall the saved city already has, whose hero has come.
	var theseus: Dictionary = core.command("inspect 83 -11")
	check(theseus.has("hall") and theseus.hall.stage == "arrived" and theseus.hall.requirements.size() >= 4, lang + " the saved city's hall of Theseus shows his arrival and requirements")

	# ------------------------------------------------------------------------------------ the hero arrives
	var arrived: Dictionary = core.command("test_hero " + hero_key)
	check(arrived.get("hall", {}).get("stage", "") == "arrived", lang + " the hero arrives (stage arrived)")
	var arrival_state: Dictionary = core.snapshot(true)
	var hero_asset := "walker_" + hero_key
	var heroes: Array = arrival_state.walkers.filter(func(w): return str(w.asset) == hero_asset)
	check(heroes.size() == 1 and model_ready(hero_asset) and clip_ready(hero_asset), lang + " the hero walks the city with his model and its fight and die clips")
	var arrival_event := false
	for event in arrival_state.get("events", []):
		arrival_event = arrival_event or (str(event.text).length() > 20 and str(event.title).to_lower().contains(str(HERO_NAMES.en[hero_key]).to_lower()) if lang == "en" else str(event.text).length() > 20 and has_cyrillic(str(event.title)))
	check(arrival_event, lang + " the hero's arrival is announced in words")
	var ready: Dictionary = core.command("world")
	var ready_quest: Dictionary = {}
	for entry in ready.quests:
		if str(entry.hero_name) == str(quest.hero_name):
			ready_quest = entry
	check(not ready_quest.is_empty() and bool(ready_quest.hall) and bool(ready_quest.ready), lang + " the quest now says its hero is ready")

	# --------------------------------------------------------------------------- the hero slays his monster
	var monsters_of := {"achilles": "hector", "atalanta": "harpies", "bellerophon": "chimera", "hercules": "cerberus", "jason": "dragon", "odysseus": "cyclops", "perseus": "medusa", "theseus": "minotaur"}
	var slain_monster: String = monsters_of[hero_key]
	var slaying := slay(core, hero_key, slain_monster)
	check(slaying.fought, lang + " the hero fights the monster %s slays (action 4 or 5 on the hero)" % str(quest.hero_name))
	check(slaying.fell and int(slaying.gone) >= 0, lang + " and the monster falls and is gone (step %d)" % int(slaying.gone))
	check(int(core.command("army").monsters) == 0, lang + " the city has no monster left")

	# ----------------------------------------------------------------------------- sending the hero on a quest
	var quests: Array = core.command("world").quests
	var index := -1
	for entry in quests:
		if str(entry.hero_name) == str(quest.hero_name):
			index = int(entry.id)
	check(core.command("world_quest 99").get("error", "") == "unknown_quest", lang + " a quest that is not asked for is refused")
	var unready := -1
	for entry in quests:
		if not bool(entry.ready) and bool(entry.hall):
			unready = int(entry.id)
	if unready >= 0:
		check(core.command("world_quest %d" % unready).get("error", "") == "hero_not_ready", lang + " a hero who has not arrived cannot be sent")
	var sent: Dictionary = core.command("world_quest %d" % index)
	check(not sent.has("error") and (sent.quests as Array).size() == quests.size() - 1, lang + " the hero is sent on the quest and the quest leaves the list (%s)" % str(sent.get("error", "ok")))
	var away: Dictionary = core.command("inspect %d %d" % [at.x, at.y])
	check(bool(away.hall.on_quest), lang + " the hall says its hero is away on a quest")

	# --------------------------------------------------------------------- every hero slays his monsters (once)
	if lang == "en":
		var failures: Array = []
		var slayers := {"achilles": ["hector", "maenads"], "atalanta": ["harpies", "sphinx"], "bellerophon": ["chimera", "echidna"], "hercules": ["cerberus", "hydra"], "jason": ["dragon", "talos"], "odysseus": ["cyclops", "scylla"], "perseus": ["kraken"], "theseus": ["calydonian_boar", "minotaur"]}
		for other in HEROES:
			if other == hero_key:
				continue
			core.command("test_allow hero_hall_" + other)
			var other_spot := spot(core, core.snapshot(true), "hero_hall_" + other)
			if other_spot.x != 99999:
				core.command("build hero_hall_%s %d %d 0" % [other, other_spot.x, other_spot.y])
			if core.command("test_hero " + other).has("error"):
				failures.append(other + " (no hall)")
				continue
			for kind in slayers[other]:
				print("HERO_INFO slaying ", other, " vs ", kind)
				var result := slay(core, other, kind)
				if not (result.fought and result.fell and int(result.gone) >= 0):
					failures.append("%s vs %s (fought %s, fell %s, gone at %d)" % [other, kind, str(result.fought), str(result.fell), int(result.gone)])
		# The hero who went on his quest is not in the city; his monster is Perseus' second one.
		check(failures.is_empty(), "en each hero slays the monsters of his in the city %s" % str(failures))
	core.close_city()

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var only := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	if only != "ru":
		run_language("en", engine)
	if only != "en":
		run_language("ru", engine)
	print("HERO_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
