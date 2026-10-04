extends SceneTree
# The words of the events that the SDL view writes in its own handlers (headless, in memory): gods' visits, invasions, help, quests,
# disasters and trade resumptions, the heroes' arrival, the monster and invasion timelines, the completion of sanctuaries, pyramids,
# monuments and shrines, and the replies to the requests of other cities. The core words them from the same message tables
# (presentation/eeventwords.h), so none of the 338 event kinds reaches the front end without title and text any more; the two that
# the SDL view only shows as alert tiles (playerInvasion, playerGodAttack) stay silent. A validators-only command raises an event with the
# god, monster, hero, city and time a caller names. English and Russian.
var okay := true
var checks := 0
var last_id := -1

const GODS := ["aphrodite", "apollo", "ares", "artemis", "athena", "atlas", "demeter", "dionysus", "hades", "hephaestus", "hera", "hermes", "poseidon", "zeus"]
const HEROES := ["achilles", "atalanta", "bellerophon", "hercules", "jason", "odysseus", "perseus", "theseus"]
# The satyr has no message tables in the game (it comes from no event).
const MONSTERS := ["calydonian_boar", "cerberus", "chimera", "cyclops", "dragon", "echidna", "harpies", "hector", "hydra", "kraken", "maenads", "medusa", "minotaur", "scylla", "sphinx", "talos"]
const MONUMENTS := ["modestPyramidComplete1", "pyramidComplete2", "greatPyramidComplete3", "majesticPyramidComplete4", "smallMonumentToTheSkyComplete5", "monumentToTheSkyComplete6", "grandMonumentToTheSkyComplete7", "minorShrineComplete8", "shrineComplete9", "majorShrineComplete10", "pyramidOfThePantheonComplete11", "altarOfOlympusComplete12", "templeOfOlympusComplete13", "observatoryKosmikaComplete14", "museumAtlantikaComplete15"]
const REQUESTS := ["generalRequest", "famine", "project", "festival", "financialWoes"]
const RELATIONS := ["Ally", "Rival", "Subject", "Parent"]
const REPLIES := ["Comply", "TooLate", "Refuse"]

func check(value: bool, message: String) -> void:
	checks += 1
	print("EVENT_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

# Raises an event; the new event it brought (an empty dictionary when it brought none: the event is silent).
func raise(core: RefCounted, command: String) -> Dictionary:
	var reply: Dictionary = core.command("test_raise " + command)
	if reply.has("error"):
		return {"error": reply.error}
	var events: Array = reply.get("events", [])
	if events.is_empty():
		return {}
	var latest: Dictionary = events[events.size() - 1]
	if int(latest.id) <= last_id:
		return {}
	last_id = int(latest.id)
	return latest

func sounds_of(core: RefCounted, command: String) -> Array:
	var reply: Dictionary = core.command("test_raise " + command)
	var events: Array = reply.get("events", [])
	if not events.is_empty():
		last_id = maxi(last_id, int(events[events.size() - 1].id))
	return reply.get("sounds", [])

# Words: a title and a text, with none of the placeholders this core fills left in.
func worded(event: Dictionary) -> bool:
	if event.is_empty() or event.has("error"):
		return false
	var text := str(event.get("text", ""))
	var title := str(event.get("title", ""))
	return text.length() > 10 and title.length() > 2 and not text.contains("[reason_phrase]") and not text.contains("[hero_needed]") and not text.contains("[time_until_attack]") and not text.contains("[god]") and not text.contains("[monster]")

func has_cyrillic(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x0400 and code <= 0x04FF:
			return true
	return false

func run_language(lang: String, engine: String) -> void:
	last_id = -1
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	check(initial.has("protocol"), lang + " designated test city loads paused")
	check(core.command("test_raise godVisit god zeus").get("error", "") == "unsupported_command", lang + " an event cannot be raised without the validators' switch")
	core.enable_test_commands()
	check(raise(core, "noSuchEvent").has("error") and raise(core, "godVisit god nobody").has("error") and raise(core, "godVisit monster nothing").has("error") and raise(core, "godVisit city 9999").has("error"), lang + " unknown events, gods, monsters and cities are refused")

	var audit: Dictionary = core.command("event_texts")
	check(int(audit.count) == 338 and (audit.without_text as Array).is_empty(), lang + " every one of the %d event kinds arrives with words (none without: %s)" % [int(audit.count), str(audit.without_text)])

	# A city for the tokens the SDL message box fills ([city_name], [leader_name] ...): the first city of the world map but the player's.
	var world: Dictionary = core.command("world")
	var city := -1
	var city_name := ""
	for entry in world.get("cities", []):
		if city < 0:
			city = int(entry.index)
			city_name = str(entry.name)
	var with_city := " city %d" % city if city >= 0 else ""

	# ----------------------------------------------------------------------------------------------- the gods
	var visits := {}
	for round in 4:
		var event := raise(core, "godVisit god zeus")
		visits[str(event.get("text", ""))] = true
		if round == 2:
			check(worded(event), lang + " a visit of Zeus is worded: " + str(event.get("title", "")))
	# The SDL view's counter runs wooing, jealousy, jealousy, jealousy again (a fourth step repeats the last text), so four visits say three things.
	check(visits.size() == 3, lang + " visits of one god say different things in turn (the SDL cycle of wooing and jealousy): %d texts in four visits" % visits.size())
	var failures: Array = []
	var voiced := 0
	for god in GODS:
		for kind in ["godInvasion", "godHelp", "godMonsterUnleash", "sanctuaryComplete", "godDisaster", "godDisasterEnds", "godVisit"]:
			var event := raise(core, "%s god %s%s" % [kind, god, with_city])
			if not worded(event):
				failures.append(kind + " " + god)
		for quest in ["1", "2"]:
			for kind in ["godQuest", "godQuestFulfilled"]:
				var event := raise(core, "%s god %s quest %s hero hercules%s" % [kind, god, quest, with_city])
				if not worded(event):
					failures.append("%s %s %s" % [kind, god, quest])
		if sounds_of(core, "godInvasion god " + god).any(func(path): return str(path).contains("Voice/Walker")):
			voiced += 1
	check(failures.is_empty(), lang + " all 14 gods have their visit, invasion, help, monster, sanctuary, disaster and both quest messages %s" % str(failures))
	check(voiced >= 12, lang + " the gods' voice lines are asked for with their messages (%d of 14 gods)" % voiced)
	var hades_quest := raise(core, "godQuest god hades quest 1 hero hercules")
	check(str(hades_quest.get("text", "")).contains(("Hercules" if lang == "en" else "Геракл")), lang + " a quest names the hero it needs: " + str(hades_quest.get("title", "")))
	check(hades_quest.has("brief") and str(hades_quest.brief).length() > 10 and str(hades_quest.brief).length() < str(hades_quest.text).length(), lang + " a message also carries the SDL view's condensed wording for the toast: " + str(hades_quest.get("brief", "-")))
	var resumes: Array = []
	for god in GODS:
		var event := raise(core, "godTradeResumes god " + god)
		if worded(event) != (god in ["zeus", "poseidon", "hermes"]):
			resumes.append(god)
	check(resumes.is_empty(), lang + " trade resumes for Zeus, Poseidon and Hermes, the only gods that stop it, and for no other god %s" % str(resumes))

	# ---------------------------------------------------------------------------------------------- the heroes
	failures = []
	var arrived := 0
	for hero in HEROES:
		if not worded(raise(core, "heroArrival hero " + hero + with_city)):
			failures.append(hero)
		if sounds_of(core, "heroArrival hero " + hero).any(func(path): return str(path).contains("Voice/Walker")):
			arrived += 1
	check(failures.is_empty() and arrived >= 6, lang + " each of the eight heroes arrives with words and a voice %s (%d voices)" % [str(failures), arrived])

	# --------------------------------------------------------------------------------------- the monster timeline
	failures = []
	for monster in MONSTERS:
		for kind in ["monsterInCity", "monsterInvasion24", "monsterInvasion12", "monsterInvasion6", "monsterInvasion1", "monsterInvasion", "monsterSlain"]:
			if not worded(raise(core, "%s monster %s%s" % [kind, monster, with_city])):
				failures.append(kind + " " + monster)
		var warning := raise(core, "monsterInvasionInitial monster %s time 18%s" % [monster, with_city])
		if not worded(warning) or not str(warning.text).contains("18"):
			failures.append("monsterInvasionInitial " + monster)
	check(failures.is_empty(), lang + " each of the 16 monsters has its warnings, arrival, in-city and slain messages, with the months in the first warning %s" % str(failures))
	check(raise(core, "monsterInvasion monster satyr").is_empty(), lang + " the satyr, which no event sends, has no words and stays silent")
	check(sounds_of(core, "monsterInvasion monster cerberus").any(func(path): return str(path).contains("Voice/Walker")), lang + " a monster's attack asks for its voice")
	var chimera := raise(core, "monsterInvasionInitial monster chimera time 12")
	check(worded(chimera), lang + " a text that names the reason twice has both filled in (the chimera)")

	# ---------------------------------------------------------------------------------------- the invasion timeline
	failures = []
	for kind in ["invasionInitial", "invasion24", "invasion12", "invasion6", "invasion1", "invasion"]:
		var event := raise(core, "%s time 9%s" % [kind, with_city])
		if not worded(event) or (city >= 0 and str(event.text).contains("[city_name]")):
			failures.append(kind)
	check(failures.is_empty(), lang + " the invasion warnings and the invasion itself are worded with the invader's city %s" % str(failures))
	var warning := raise(core, "invasion12%s" % with_city)
	check(city_name != "" and str(warning.get("text", "")).contains(city_name), lang + " the invasion warning names the invader's city and its army: " + str(warning.get("text", "")).substr(0, 80))
	var before := last_id
	check(raise(core, "playerInvasion").is_empty() and raise(core, "playerGodAttack").is_empty() and last_id == before, lang + " the player's own invasion and god attack are alerts only: no message box")

	# ---------------------------------------------------------------- monuments and the replies of other cities
	failures = []
	for kind in MONUMENTS:
		if not worded(raise(core, kind + with_city)):
			failures.append(kind)
	check(failures.is_empty(), lang + " all 15 pyramids, monuments and shrines have a completion message %s" % str(failures))
	failures = []
	var replies := 0
	var thanks := {}
	for request in REQUESTS:
		for relation in RELATIONS:
			for reply in REPLIES:
				var kind: String = request + relation + reply
				var event := raise(core, kind + with_city)
				replies += 1
				if not worded(event) or (city >= 0 and str(event.text).contains("[city_name]")):
					failures.append(kind)
				elif reply == "Comply":
					thanks[str(event.title)] = true
	for reply in REPLIES:
		replies += 1
		if not worded(raise(core, "generalRequestTribute" + reply + with_city)):
			failures.append("generalRequestTribute" + reply)
	check(failures.is_empty() and replies == 63, lang + " the 63 replies to requests (comply, too late, refuse) bring the favour message with their reason %s (%d)" % [str(failures), replies])
	var comply := raise(core, "famineAllyComply%s" % with_city)
	var refuse := raise(core, "famineAllyRefuse%s" % with_city)
	check(str(comply.title) != str(refuse.title), lang + " thanking and rebuking are different messages: %s / %s" % [str(comply.title), str(refuse.title)])
	if lang == "ru":
		check(has_cyrillic(str(comply.text)) and has_cyrillic(str(comply.title)), "ru the Russian message tables are used: " + str(comply.title))
	core.close_city()

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	run_language("en", engine)
	run_language("ru", engine)
	print("EVENT_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
