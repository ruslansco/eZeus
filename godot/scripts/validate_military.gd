extends SceneTree
# The military dealings of the world map against the embedded core (headless, in memory): `world` says which cities may be raided,
# conquered (or sent reinforcements) and asked for aid, as the SDL world menu decides; a raid or a conquest asks the engine for the
# forces to send (`enlist`), `enlist_dispatch` sends them as the SDL dialog does (refusing an empty force, a second ally, forces that
# are not on offer or already abroad), the army travels, the engine's own events decide the outcome and the army comes home;
# defensive aid and a military strike are requested through their events; a troop request's "send troops" opens the same enlisting.
var okay := true
var checks := 0
var titles: Array = []

func check(value: bool, message: String) -> void:
	checks += 1
	print("MILITARY_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func city_at(world: Dictionary, index: int) -> Dictionary:
	for city in world.cities:
		if int(city.index) == index:
			return city
	return {}

func armies_of(world: Dictionary, reason: String) -> Array:
	return world.armies.filter(func(a): return a.reason == reason)

# Answers the campaign's own decisions with their first choice, but leaves a troop request alone (its "send troops" is the test's to use).
func answer_events(core: RefCounted, state: Dictionary, keep_troops := true) -> void:
	for event in state.get("events", []):
		titles.append(str(event.title))
		print("MILITARY_EVENT ", str(event.title), " | ", str(event.text).substr(0, 90).replace("\n", " "))
		var choices: Array = event.get("actions", [])
		if keep_troops and choices.any(func(c): return int(c.choice) == -2):
			continue
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

func ids_of(enlist: Dictionary) -> String:
	return ",".join(enlist.soldiers.filter(func(s): return not bool(s.abroad)).map(func(s): return str(int(s.id))))

# Runs the city on until the condition holds (stepping about four game days at a time), answering decisions; false when it never does.
func run_until(core: RefCounted, condition: Callable, steps := 400) -> bool:
	for step in steps:
		core.advance(.25)
		var state: Dictionary = core.snapshot(false)
		answer_events(core, state)
		if condition.call():
			return true
	return false

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	check(core.command("test_relationship 3 rival").get("error", "") == "unsupported_command" and core.command("test_troops 3 5").get("error", "") == "unsupported_command", "the test commands are refused without the validators' switch")
	core.enable_test_commands()

	# ------------------------------------------------------------------ what the world menu allows
	var world: Dictionary = core.command("world")
	var own := city_at(world, 0)
	var ally := city_at(world, 3)
	check(own.current and not own.can_raid and not own.can_conquer and own.aid == "", "the city being played can be neither raided, conquered nor asked for aid")
	check(world.cities.filter(func(c): return c.relationship == "ally" and c.can_raid and c.can_conquer and not c.reinforce).size() >= 3, "every ally on the map may be raided or conquered, as the SDL menu allows")
	check(city_at(world, 3).aid == "not_regarded" and city_at(world, 5).aid == "ok", "aid is offered only by a city that regards the player enough (%d and %d)" % [int(city_at(world, 3).attitude), int(city_at(world, 5).attitude)])
	check(world.rivals.is_empty() and world.armies.is_empty() and not world.enlisting, "the test world has no rival, no army on the road and nothing being enlisted")
	check(core.command("world_raid 0").get("error", "") == "military_unavailable" and core.command("world_conquer 0").get("error", "") == "military_unavailable", "the city played cannot be raided or conquered")
	check(core.command("world_raid 99").get("error", "") == "unknown_city" and core.command("world_raid").get("error", "") == "invalid_world_command", "an unknown city and a malformed order are refused")
	check(core.command("world_aid 3 0").get("error", "") == "not_regarded" and core.command("world_aid 0 0").get("error", "") == "world_dealings_unavailable" and core.command("world_aid 5 99").get("error", "") == "not_owned", "aid is refused for a cold city, for the city played and for a city that is not the player's")
	check(core.command("world_strike 5 3").get("error", "") == "not_a_rival", "a strike needs a rival to strike")
	check(core.command("enlist_dispatch -1 s:1").get("error", "") == "no_enlistment" and core.command("enlist").get("error", "") == "no_enlistment", "nothing can be dispatched when nothing is being enlisted")

	# ------------------------------------------------------------------------------------ a raid
	core.command("test_troops 3 5")
	core.command("test_soldiers hoplite 24")
	var enlist: Dictionary = core.command("world_raid 3")
	check(enlist.kind == "enlist" and enlist.purpose == "raid" and int(enlist.city) == 3 and enlist.cities.size() == 1, "asking to raid %s opens an enlisting for that raid" % ally.name)
	check(enlist.soldiers.size() >= 3 and enlist.soldiers.all(func(s): return s.type in ["hoplite", "horseman", "amazon", "ares_warrior"] and not bool(s.abroad)), "the hoplite companies can be enlisted (rock throwers cannot): %d companies" % enlist.soldiers.size())
	check(enlist.heroes.size() >= 1 and enlist.allies.size() >= 1 and enlist.plunder.size() >= 3 and int(enlist.plunder[0].resource) == -1 and int(enlist.plunder[1].resource) == 8388608, "heroes, allies and the plunder to ask for (anything, drachmas, the city's goods) are on offer")
	check(core.command("world").enlisting, "the world says an enlisting is waiting")
	check(core.command("enlist_dispatch -1").get("error", "") == "no_forces" and core.command("enlist_dispatch -1 a:%d" % int(enlist.allies[0].index)).get("error", "") == "no_forces", "nothing is sent without a soldier or a hero (an ally's troops alone are not a force)")
	check(core.command("enlist_dispatch -1 s:99999").get("error", "") == "not_enlistable" and core.command("enlist_dispatch -1 s:x").get("error", "") == "invalid_enlistment" and core.command("enlist_dispatch -1 q:1").get("error", "") == "invalid_enlistment", "forces that are not on offer and malformed choices are refused")
	if enlist.allies.size() >= 2:
		check(core.command("enlist_dispatch -1 s:%s a:%d a:%d" % [ids_of(enlist), int(enlist.allies[0].index), int(enlist.allies[1].index)]).get("error", "") == "one_ally_only", "only one allied city's troops may go along")
	check(core.command("enlist_dispatch 12345 s:%s" % ids_of(enlist)).get("error", "") == "not_offered", "plunder that the city does not offer cannot be asked for")
	check(core.command("enlist").kind == "enlist", "a refused dispatch leaves the enlisting waiting")
	var hero: Dictionary = enlist.heroes[0]
	var treasury_before: int = int(core.snapshot(false).money)
	var sent: Dictionary = core.command("enlist_dispatch 8388608 s:%s h:%d:%d" % [ids_of(enlist), int(hero.city), int(hero.hero)])
	check(not sent.has("error") and sent.kind == "world" and not sent.enlisting, "the forces are dispatched (%s)" % str(sent.get("error", "ok")))
	var raid_army: Array = armies_of(sent, "raid")
	check(raid_army.size() == 1 and int(raid_army[0].from) == 0 and int(raid_army[0].to) == 3 and raid_army[0].heroes.map(func(h): return int(h)).has(int(hero.hero)) and int(raid_army[0].size) >= 1, "an army is on the road from the player's city to %s with its hero" % ally.name)
	var abroad_after: Array = core.command("army").banners.filter(func(b): return b.abroad)
	check(abroad_after.size() >= 3, "the enlisted companies are abroad (%d)" % abroad_after.size())
	var again: Dictionary = core.command("world_raid 3")
	check(again.soldiers.filter(func(s): return bool(s.abroad)).size() >= 3 and again.heroes.any(func(h): return bool(h.abroad)), "enlisting again shows those companies and the hero as abroad")
	check(core.command("enlist_dispatch -1 s:%d" % int(abroad_after[0].id)).get("error", "") == "already_abroad", "a company that is abroad cannot be sent again")
	core.command("enlist_cancel")
	check(core.command("enlist").get("error", "") == "no_enlistment", "cancelling drops the enlisting")

	core.command("speed 3")
	core.command("pause 0")
	# Lambdas capture locals by value, so what the watch learns lives in a dictionary.
	var watch := {"fraction": 0.0, "plundered": false, "hated": false, "home": false}
	var raid_done := func():
		var w: Dictionary = core.command("world")
		for a in armies_of(w, "raid"):
			watch.fraction = maxf(float(watch.fraction), float(a.frac))
		watch.home = bool(watch.home) or not armies_of(w, "home").is_empty()
		watch.plundered = bool(watch.plundered) or titles.any(func(t): return str(t).contains("plundered"))
		watch.hated = bool(watch.hated) or titles.any(func(t): return str(t).contains("Allies hate you"))
		return w.armies.is_empty() and bool(watch.home) and bool(watch.plundered)
	var came_back := run_until(core, raid_done, 600)
	var seen_fraction: float = watch.fraction
	var plundered: bool = watch.plundered
	var hated: bool = watch.hated
	var returned_home: bool = watch.home
	check(seen_fraction > .3, "the army advances along the road (seen at %.2f of the way)" % seen_fraction)
	check(plundered, "the raid is paid in the plunder asked for (a message of drachmas plundered arrives)")
	check(hated, "the engine's own consequence of attacking an ally is reported (\"Allies hate you\")")
	check(returned_home and came_back, "the army returns home and leaves the road")
	var back: Dictionary = core.command("army")
	check(back.banners.filter(func(b): return b.abroad).is_empty(), "the companies are home again (none is abroad)")
	check(core.command("world_raid 3").heroes.all(func(h): return not bool(h.abroad)), "and the hero is back")
	core.command("enlist_cancel")

	# ------------------------------------------------------------------------------------ a conquest
	core.command("test_troops 4 5")
	core.command("test_soldiers hoplite 24")
	var conquest: Dictionary = core.command("world_conquer 4")
	check(conquest.purpose == "conquer" and int(conquest.city) == 4 and conquest.plunder.is_empty(), "asking to conquer opens an enlisting with no plunder to choose")
	var conquering: Dictionary = core.command("enlist_dispatch -1 s:%s" % ids_of(conquest))
	check(not conquering.has("error") and armies_of(conquering, "conquest").size() == 1, "the conquest army sets out (%s)" % str(conquering.get("error", "ok")))
	var vassal_now := func(): return city_at(core.command("world"), 4).relationship == "vassal"
	var conquered := run_until(core, vassal_now, 600)
	check(conquered, "the city is conquered by the engine's own rule (strength against troops) and becomes a vassal")
	var vassal := city_at(core.command("world"), 4)
	check(not vassal.can_raid and not vassal.can_conquer, "a vassal can be neither raided nor conquered again")
	var all_home := func(): return core.command("world").armies.is_empty() and core.command("army").banners.filter(func(b): return b.abroad).is_empty()
	run_until(core, all_home, 400)

	# ------------------------------------------------------------------------- aid and a strike
	# Attacking an ally cooled every ally's regard; the one asked for aid is warmed again.
	core.command("test_attitude 5 90")
	var attitudes_before := {}
	for city in core.command("world").cities:
		attitudes_before[int(city.index)] = int(city.attitude)
	var aid: Dictionary = core.command("world_aid 5 0")
	check(not aid.has("error"), "defensive aid is requested of a regarding city (%s)" % str(aid.get("error", "ok")))
	var cooled := true
	for city in aid.cities:
		if city.current or int(city.index) == 5:
			continue
		cooled = cooled and int(city.attitude) == maxi(int(attitudes_before[int(city.index)]) - 10, 0)
	check(cooled and int(city_at(aid, 5).attitude) == int(attitudes_before[5]) - 20, "every city's regard falls by 10 and the asked city's by 10 more, as the SDL dialog does")
	var aid_came := func(): return city_at(core.command("world"), 5).aid == "present"
	var arrived := run_until(core, aid_came, 120)
	check(arrived, "the aid arrives about a month later and the city's aid offer says it is present (%s)" % city_at(core.command("world"), 5).aid)
	core.command("test_relationship 3 rival")
	core.command("test_attitude 5 90")
	var strike_world: Dictionary = core.command("world")
	check(strike_world.rivals.map(func(r): return int(r)) == [3] and city_at(strike_world, 3).relationship == "rival", "a rival now exists on the map (%s, %s)" % [str(strike_world.rivals), city_at(strike_world, 3).relationship])
	core.command("test_troops 5 80")
	var struck: Dictionary = core.command("world_strike 5 3")
	check(not struck.has("error"), "a strike on the rival is requested of the regarding city (%s)" % str(struck.get("error", "ok")))
	check(core.command("world_strike 5 4").get("error", "") == "not_a_rival", "only a rival can be struck")

	# ------------------------------------------------------------------------------ a troop request
	core.command("test_soldiers hoplite 16")
	core.command("test_troops_request 5 3")
	var asked_for := false
	var request_id := -1
	for step in 300:
		core.advance(.25)
		var state: Dictionary = core.snapshot(false)
		answer_events(core, state, true)
		for event in state.get("events", []):
			if event.actions.any(func(c): return int(c.choice) == -2):
				asked_for = true
				request_id = int(event.id)
		if asked_for:
			break
	check(asked_for, "an ally's request for troops arrives as a decision with a \"send troops\" choice")
	var request_state: Dictionary = core.snapshot(false)
	check(request_state.blocked, "the city waits for the answer")
	var troops_enlist: Dictionary = core.command("event %d -2" % request_id)
	check(troops_enlist.get("purpose", "") == "troops" and int(troops_enlist.event) == request_id and not troops_enlist.soldiers.is_empty(), "choosing to send troops opens the same enlisting")
	check(not troops_enlist.allies.any(func(a): return int(a.index) == 5), "the city that asks is not among the allies that may go along")
	core.command("enlist_cancel")
	check(core.snapshot(false).events.any(func(e): return int(e.id) == request_id), "cancelling leaves the request waiting")
	troops_enlist = core.command("event %d -2" % request_id)
	var helping: Dictionary = core.command("enlist_dispatch -1 s:%s" % ids_of(troops_enlist))
	check(not helping.has("error") and armies_of(helping, "help").size() >= 1, "the troops set out to help (%s)" % str(helping.get("error", "ok")))
	var after_help: Dictionary = core.snapshot(false)
	check(not after_help.events.any(func(e): return int(e.id) == request_id) and not after_help.blocked, "the request is answered and the city runs on")
	core.close_city()
	print("MILITARY_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
