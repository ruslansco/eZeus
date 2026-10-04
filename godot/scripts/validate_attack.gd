extends SceneTree
# A god sent against an enemy city (headless, in memory, scratch saves only): in a new game that has a rival city on the board (The Sands of Betrayal:
# Theron) a finished sanctuary's inspection offers "God Invasion" with the rival's name and the wait for the next attack; asking sends the god (the engine's
# own `askForAttack`: the god leaves, an attack event is raised in the rival city, the god's invasion is announced), the answer is the game's own words
# for the god, a second request is refused in words that follow how far the wait has come, an enemy that is not one is refused, a sanctuary in a city
# with no rival has no such offer; the inspector's section shows the button, the bar and the answer, and chooses between cities when there are several.
# English and Russian.
const BuildingInspector = preload("res://scripts/building_inspector.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("ATTACK_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func has_cyrillic(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x0400 and code <= 0x04FF:
			return true
	return false

# The first tile (searching the buildable ones) where `tool` can be placed.
func site_for(core: RefCounted, state: Dictionary, tool: String, skip := 0) -> Vector2i:
	var seen := 0
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		if core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
			if seen >= skip:
				return Vector2i(int(tile[0]), int(tile[1]))
			seen += 1
	return Vector2i(99999, 99999)

# A sanctuary of Dionysus finished at once beside a road, in a new game of `adventure`; its centre tile, or (99999, 99999).
func found_sanctuary(core: RefCounted, adventure: Dictionary, lang: String) -> Vector2i:
	var state: Dictionary = core.open_adventure(ProjectSettings.globalize_path("res://..").simplify_path(), str(adventure.kind), str(adventure.ref), lang)
	core.enable_test_commands()
	core.command("test_allow temple_dionysus")
	# Marble must be in a store (the engine takes a sanctuary's first marble when it is founded): a warehouse, stocked.
	var warehouse := site_for(core, state, "warehouse")
	if warehouse.x == 99999 or core.command("build warehouse %d %d 0" % [warehouse.x, warehouse.y]).has("error"):
		return Vector2i(99999, 99999)
	core.command("test_stock 32768 60")
	state = core.snapshot(true)
	var site := site_for(core, state, "temple_dionysus")
	if site.x == 99999:
		return site
	# A road beside the footprint (10x6 centred on the tile), where the god will appear.
	var plan: Dictionary = core.command("preview temple_dionysus %d %d 0" % [site.x, site.y])
	for dx in [-1, int(plan.w)]:
		var at := Vector2i(int(plan.x) + dx, int(plan.y) + int(plan.h) / 2)
		if core.command("preview road %d %d 0" % [at.x, at.y]).get("valid", false):
			core.command("build road %d %d 0" % [at.x, at.y])
			break
	if core.command("build temple_dionysus %d %d 0" % [site.x, site.y]).has("error"):
		return Vector2i(99999, 99999)
	core.command("test_complete %d %d" % [site.x, site.y])
	return site

func run_language(lang: String, engine: String, scratch: String) -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	core.set_save_directory(scratch)
	check(core.command("test_complete 1 1").get("error", "") != "", lang + " a monument cannot be finished at once without the validators' switch")
	var adventure := {}
	var plain := {}
	for item in core.adventures(engine, "en").adventures:
		if str(item.title) == "The Sands of Betrayal":
			adventure = item
		if str(item.title) == "The Founding of Athens":
			plain = item
	check(not adventure.is_empty() and not plain.is_empty(), lang + " the adventures with and without a rival on the board are listed")

	# ---------------------------------------------------------------- a city with no rival: no such offer
	var quiet_site := found_sanctuary(core, plain, lang)
	check(quiet_site.x != 99999, lang + " a sanctuary is founded and finished at once in a new game with no rival on the board")
	var quiet: Dictionary = core.command("inspect %d %d" % [quiet_site.x, quiet_site.y]).get("monument", {})
	check(bool(quiet.get("finished", false)) and not quiet.has("attack"), lang + " it is offered no attack: no enemy city is on the board")
	core.close_city()

	# ------------------------------------------------------------------------ the offer, with a rival on the board
	var at := found_sanctuary(core, adventure, lang)
	check(at.x != 99999, lang + " a sanctuary is founded and finished at once in The Sands of Betrayal (%s)" % str(at))
	var inspection: Dictionary = core.command("inspect %d %d" % [at.x, at.y])
	var monument: Dictionary = inspection.get("monument", {})
	check(bool(monument.get("finished", false)) and monument.has("attack") and str(monument.attack.label) != "", lang + " the finished sanctuary offers an attack: \"%s\"" % str(monument.get("attack", {}).get("label", "-")))
	if lang == "en":
		check(str(monument.attack.label) == "God Invasion", "en the offer is the game's own \"God Invasion\"")
	else:
		check(has_cyrillic(str(monument.attack.label)), "ru the offer is in Russian: " + str(monument.attack.label))
	var targets: Array = monument.attack.targets
	check(targets.size() == 1 and str(targets[0].name) == "Theron" and float(monument.attack.fraction) >= .99, lang + " the one enemy city is Theron and nothing has been asked yet (the wait is over: %s)" % str(monument.attack.fraction))
	var city: int = int(targets[0].city)

	# ----------------------------------------------------------------------------------------- the inspector's section
	var inspector: VBoxContainer = BuildingInspector.new()
	root.add_child(inspector)
	var sent: Array = []
	inspector.action_requested.connect(func(command): sent.append(command))
	inspection.can_control = true
	inspector.show_inspection(inspection)
	await process_frame
	check(inspector.monument_attack_button != null and inspector.monument_attack_button.text == str(monument.attack.label) and inspector.monument_attack_bar != null and inspector.monument_attack_result != null, lang + " the inspector shows the button, the bar of the wait and the line for the answer")
	check(inspector.monument_attack_popup.item_count == 1 and inspector.monument_attack_popup.get_item_text(0) == "Theron", lang + " the menu of cities lists Theron")
	inspector.monument_attack_button.pressed.emit()
	check(sent.size() == 1 and sent[0] == "sanctuary_attack %d %d %d %d" % [at.x, at.y, int(inspection.target_token), city], lang + " with one enemy city the button asks at once: %s" % str(sent))
	inspector.pending = false
	var two := inspection.duplicate(true)
	two.monument.attack.targets = [{"city": city, "name": "Theron"}, {"city": 99, "name": "Elsewhere"}]
	inspector.show_inspection(two)
	await process_frame
	check(inspector.monument_attack_popup.item_count == 2 and inspector.monument_attack_popup.get_item_text(1) == "Elsewhere", lang + " with several enemy cities the menu offers each of them")
	sent.clear()
	inspector.monument_attack_popup.id_pressed.emit(99)
	check(sent.size() == 1 and sent[0].ends_with(" 99"), lang + " choosing one asks for that city: %s" % str(sent))
	inspector.show_attack_answer({"granted": false, "text": "x"})
	check(inspector.monument_attack_result.text == "x", lang + " the answer shows under the bar")
	inspector.queue_free()

	# ----------------------------------------------------------------------------------------------- refusals
	var token: int = int(inspection.target_token)
	check(core.command("sanctuary_attack %d %d %d %d" % [at.x, at.y, token + 1, city]).get("error", "") == "inspection_target_changed", lang + " a stale token is refused")
	check(core.command("sanctuary_attack %d %d %d" % [at.x, at.y, token]).get("error", "") == "invalid_monument_command", lang + " a missing city is refused")
	check(core.command("sanctuary_attack %d %d %d 0" % [at.x, at.y, token]).get("error", "") == "not_an_enemy_city", lang + " a city that is not an enemy is refused (the player's own)")

	# ---------------------------------------------------------------------------------------------- the attack
	core.snapshot(true)
	var money_before := int(core.snapshot(false).money)
	var asked: Dictionary = core.command("sanctuary_attack %d %d %d %d" % [at.x, at.y, token, city])
	check(not asked.has("error") and asked.attack_answer != null and bool(asked.attack_answer.granted), lang + " the request is granted: %s" % str(asked.get("attack_answer", {}).get("text", asked.get("error", "-"))))
	var god_name := str(monument.god_name)
	check(str(asked.attack_answer.text).begins_with(god_name) and (lang != "ru" or has_cyrillic(str(asked.attack_answer.text))), lang + " and worded as the game words it, with the god's name")
	check(bool(asked.monument.god_abroad), lang + " the god is away (the inspection says so)")
	check(float(asked.monument.attack.fraction) < .1, lang + " the wait for the next attack starts again (%s)" % str(asked.monument.attack.fraction))
	var again: Dictionary = core.command("inspect %d %d" % [at.x, at.y])
	var second: Dictionary = core.command("sanctuary_attack %d %d %d %d" % [at.x, at.y, int(again.target_token), city])
	check(not bool(second.attack_answer.granted) and second.attack_answer.reason == "too_soon" and str(second.attack_answer.text).begins_with(god_name), lang + " asking again at once is refused in the god's words: %s" % str(second.attack_answer.text))
	check(core.command("mythology").gods_attacking.is_empty(), lang + " the mythology page, which lists the gods attacking this city, does not list one sent away")

	# ------------------------------------------------- the god is in the rival's city, the invasion is announced
	core.command("speed 3")
	core.command("pause 0")
	var announced := false
	var god_seen := false
	var started := Time.get_ticks_msec()
	for step in 400:
		if Time.get_ticks_msec() - started > 60000:
			break
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		for event in running.get("events", []):
			announced = announced or str(event.title).length() > 2 and (str(event.text).contains(god_name) or lang == "ru")
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		god_seen = god_seen or running.walkers.any(func(w): return str(w.asset) == "walker_dionysus")
		if announced and god_seen:
			break
	core.command("pause 1")
	check(announced, lang + " the god's invasion is announced")
	check(god_seen, lang + " the god walks the rival's land")
	core.close_city()

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var scratch := ProjectSettings.globalize_path("res://captures/validation-attack-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)
	await run_language("en", engine, scratch)
	await run_language("ru", engine, scratch)
	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is untouched")
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	print("ATTACK_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
