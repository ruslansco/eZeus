extends SceneTree
# The world map against the embedded core (headless, in memory): `world` lists the cities on the map with their regard and what may be
# done with them, and the three economic dealings of the SDL world screen work through the core: asking a city for goods (regard
# falls by 10 everywhere), giving a gift (the goods leave the city at once, the city's regard rises when the gift arrives three months
# later) and fulfilling a request a city made. Military dealings (raid, conquest, aid) are reported as unavailable.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("WORLD_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func city_named(world: Dictionary, name: String) -> Dictionary:
	for city in world.cities:
		if city.name == name:
			return city
	return {}

# Answers the campaign's own requests (they pause the city until answered) with the first choice.
func answer_events(core: RefCounted, state: Dictionary) -> void:
	for event in state.get("events", []):
		var choices: Array = event.get("actions", [])
		core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	core.enable_test_commands()
	var before: Dictionary = core.snapshot(true)
	var world: Dictionary = core.command("world")
	check(world.kind == "world" and int(world.map) >= 0 and String(world.image).ends_with(".jpg") or String(world.image).ends_with(".JPG"), "the world names its map picture (%s)" % world.get("image", "?"))
	check(core.snapshot(true).money == before.money and core.snapshot(true).time == before.time, "asking for the world changes nothing")
	check(world.cities.size() >= 4 and world.cities.all(func(c): return float(c.x) >= 0.0 and float(c.x) <= 1.0 and float(c.y) >= 0.0 and float(c.y) <= 1.0), "the cities lie on the map (%d)" % world.cities.size())
	var current: Array = world.cities.filter(func(c): return c.current)
	check(current.size() == 1 and current[0].mine and not current[0].can_request and not current[0].can_gift, "the city being played is the player's own and cannot be asked or given to")
	check(world.mine.size() >= 1 and world.mine[0].current and world.mine[0].stock.any(func(s): return int(s.resource) == 8388608 and int(s.step) == 500), "the player's cities carry their stock, drachmas in steps of 500")
	check(world.cities.filter(func(c): return c.type == "foreign").all(func(c): return c.relationship in ["ally", "vassal", "rival"] and c.attitude_name != "" and c.sells is Array and c.buys is Array), "every foreign city has a relationship, a named regard and its goods")
	var regarded: Array = world.cities.filter(func(c): return c.regarded and c.can_request and not c.current)
	var cold: Array = world.cities.filter(func(c): return not c.regarded and c.can_request and not c.current)
	check(not regarded.is_empty() and not cold.is_empty(), "the test world has a city that regards the player and one that does not")
	var mine: int = int(world.mine[0].id)
	var friend: Dictionary = regarded[0]
	var stranger: Dictionary = cold[0]

	# ----------------------------------------------------------------- requests
	var offered: int = int(friend.sells[0].resource)
	check(core.command("world_request %d %d %d" % [stranger.index, offered, mine]).get("error", "") == "not_regarded", "a city that does not regard the player grants nothing (%s, regard %d)" % [stranger.name, stranger.attitude])
	check(core.command("world_request %d 8388607 %d" % [friend.index, mine]).get("error", "") == "not_offered", "only what the city sells (or drachmas) can be asked for")
	check(core.command("world_request %d %d %d" % [current[0].index, offered, mine]).get("error", "") == "world_dealings_unavailable", "the player's own city cannot be asked")
	check(core.command("world_request 999 %d %d" % [offered, mine]).get("error", "") == "unknown_city", "an unknown city is refused")
	check(core.command("world_request %d %d 99" % [friend.index, offered]).get("error", "") == "not_owned", "the goods can only be sent to one of the player's own cities")
	check(core.command("world_request %d" % friend.index).has("error"), "a malformed request is refused")
	var asked: Dictionary = core.command("world_request %d %d %d" % [friend.index, offered, mine])
	check(not asked.has("error") and asked.kind == "world", "asking a regarding city is accepted and answers with the world")
	# The native rule: every city on the map loses 10, and the city asked loses 10 more.
	check(int(city_named(asked, friend.name).attitude) == int(friend.attitude) - 20, "asking lowers the asked city's regard by 20 (%d to %d)" % [friend.attitude, int(city_named(asked, friend.name).attitude)])
	var lowered := true
	for city in world.cities:
		if city.current or city.name == friend.name:
			continue
		lowered = lowered and int(city_named(asked, city.name).attitude) == maxi(int(city.attitude) - 10, 0)
	check(lowered, "and every other city's regard by 10 (not below nothing)")

	# -------------------------------------------------------------------- gifts
	var gifted_world: Dictionary = core.command("world")
	var money_before: int = int(core.snapshot(false).money)
	var friend_now: Dictionary = city_named(gifted_world, friend.name)
	check(core.command("world_gift %d 8388608 501 %d" % [friend.index, mine]).get("error", "") == "invalid_gift", "a gift is a whole number of steps")
	check(core.command("world_gift %d 8388608 2000 %d" % [friend.index, mine]).get("error", "") == "invalid_gift", "and at most three steps")
	check(core.command("world_gift %d 8388608 0 %d" % [friend.index, mine]).get("error", "") == "invalid_gift", "and not nothing")
	check(core.command("world_gift %d 1 8 %d" % [friend.index, mine]).get("error", "") == "not_enough_goods", "goods the city does not hold cannot be given")
	check(core.command("world_gift %d 8388608 500 99" % friend.index).get("error", "") == "not_owned", "a gift comes from the player's own city")
	check(core.command("world_gift %d 8388608 500 %d" % [current[0].index, mine]).get("error", "") == "world_dealings_unavailable", "a gift to the city being played is refused")
	var gift: Dictionary = core.command("world_gift %d 8388608 1000 %d" % [friend.index, mine])
	check(not gift.has("error") and int(core.snapshot(false).money) == money_before - 1000, "a gift of two steps leaves the treasury at once (1000 drachmas)")
	check(int(city_named(gift, friend.name).attitude) == int(friend_now.attitude), "the city's regard rises only when the gift arrives")
	# Three months later the gift arrives and the regard rises (drachmas: 3 for each step).
	core.command("speed 3")
	core.command("pause 0")
	var arrived := false
	for step in 1500:
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		answer_events(core, running)
		if step % 25 == 0:
			var now: Dictionary = core.command("world")
			if int(city_named(now, friend.name).attitude) > int(friend_now.attitude):
				arrived = true
				break
	core.command("pause 1")
	check(arrived, "when the gift arrives the city regards the player more")

	# ---------------------------------------------------------------- fulfil
	var target: Dictionary = city_named(core.command("world"), friend.name)
	# The campaign may already have asked for something while the city ran: new requests are counted from there.
	var existing: int = core.command("world").requests.size()
	var requested: Dictionary = core.command("test_request %d 8388608 500" % target.index)
	var fresh: Dictionary = requested.requests[existing] if requested.requests.size() == existing + 1 else {}
	check(not fresh.is_empty() and fresh.city == target.index and int(fresh.count) == 500 and fresh.from.map(func(v): return int(v)).has(mine), "a request from a city is listed with the cities that can fill it")
	check(core.command("world_fulfil %d %d" % [existing + 5, mine]).get("error", "") == "unknown_request", "an unknown request is refused")
	check(core.command("world_fulfil %d 99" % existing).get("error", "") == "not_owned", "goods are sent from the player's own city")
	var huge: Dictionary = core.command("test_request %d 8388608 2000000000" % target.index)
	check(huge.requests.size() == existing + 2 and huge.requests[existing + 1].from.is_empty(), "a request the player cannot afford lists no sender")
	check(core.command("world_fulfil %d %d" % [existing + 1, mine]).get("error", "") == "not_enough_goods", "and cannot be fulfilled")
	money_before = int(core.snapshot(false).money)
	var done: Dictionary = core.command("world_fulfil %d %d" % [existing, mine])
	check(not done.has("error") and int(core.snapshot(false).money) == money_before - 500 and done.requests.size() == existing + 1, "fulfilling takes the goods and removes the request")
	core.close_city()
	print("WORLD_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
