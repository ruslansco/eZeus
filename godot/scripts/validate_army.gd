extends SceneTree
# The army against the embedded core (headless, in memory): `army` lists the companies (banners) of the city with their kind,
# size, tile and whether they are called out; the snapshot carries the list when it changes; `army_call` / `army_home` and
# `banner_call` / `banner_home` call companies out to their banners and send them home (called-out soldiers appear as walkers
# with their models); `banner_move` places a banner; invalid and unknown orders are refused and change nothing.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("ARMY_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func companies(army: Dictionary, kind: String) -> Array:
	return army.banners.filter(func(b): return b.type == kind)

func soldiers(army: Dictionary, kind: String) -> int:
	var total := 0
	for banner in companies(army, kind):
		total += int(banner.count)
	return total

func walkers_of(core: RefCounted, asset: String) -> int:
	return core.snapshot(true).walkers.filter(func(w): return w.asset == asset).size()

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
	# Without the validators' switch the test command is refused.
	check(core.command("test_soldiers hoplite 4").get("error", "") == "unsupported_command", "soldiers cannot be added without the validators' switch")
	core.enable_test_commands()

	# ------------------------------------------------------------------ the list
	var army: Dictionary = core.command("army")
	check(army.kind == "army" and army.palace and int(army.capacity) == 20 and int(army.per_banner) == 8, "the army reports its palace, the 20 places for companies and 8 soldiers a company")
	check(not army.banners.is_empty(), "the city has companies (%d)" % army.banners.size())
	var kinds := ["hoplite", "horseman", "rock_thrower", "amazon", "ares_warrior"]
	check(army.banners.all(func(b): return b.type in kinds and String(b.name) != "" and String(b.kind_name) != "" and int(b.count) >= 0 and int(b.count) <= 8 and b.has("placed") and b.has("x") and b.has("y") and b.has("home") and b.has("abroad") and b.has("aid") and b.has("fighting") and b.has("atlantean")), "each company has a kind, names, a size up to 8, a tile and its state")
	var ids: Array = army.banners.map(func(b): return int(b.id))
	var distinct := {}
	for id in ids:
		distinct[id] = true
	check(distinct.size() == ids.size(), "every company has its own number")
	check(army.banners.all(func(b): return bool(b.home) and not bool(b.abroad) and not bool(b.fighting) and bool(b.placed)), "companies start at home on their tiles")
	check(int(army.rabble) == soldiers(army, "rock_thrower") and int(army.hoplites) == soldiers(army, "hoplite") and int(army.horsemen) == soldiers(army, "horseman"), "the soldier totals match the companies")
	var snapshot: Dictionary = core.snapshot(true)
	check(snapshot.has("banners") and snapshot.banners.map(func(b): return int(b.id)) == ids, "a full snapshot carries the companies")
	check(not core.snapshot(false).has("banners"), "a snapshot without a change leaves them out")
	var changed_before: Dictionary = core.snapshot(false)
	check(changed_before.money == snapshot.money and changed_before.time == snapshot.time, "asking changes nothing in the city")

	# ----------------------------------------------------------- soldiers join
	var before_hoplites: int = int(army.hoplites)
	var joined: Dictionary = core.command("test_soldiers hoplite 8")
	check(int(joined.hoplites) == before_hoplites + 8 and companies(joined, "hoplite").size() >= 1, "eight hoplites join the army in a company")
	joined = core.command("test_soldiers horseman 4")
	check(int(joined.horsemen) >= 4 and companies(joined, "horseman").size() >= 1, "horsemen join in a company of their own")
	var carried: Dictionary = core.snapshot(false)
	check(carried.has("banners") and carried.banners.size() == joined.banners.size(), "the snapshot carries the list again once it changed")
	check(not core.snapshot(false).has("banners"), "and then leaves it out again")
	check(core.command("test_soldiers archer 4").get("error", "") == "unsupported_command" and core.command("test_soldiers hoplite 0").get("error", "") == "unsupported_command", "unknown kinds and empty groups are refused")

	# ------------------------------------------------------ calling one company
	var hoplite_company: Dictionary = companies(joined, "hoplite")[0]
	check(walkers_of(core, "walker_hopliteposeidon") == 0, "no hoplite stands in the city while the company is at home")
	var called: Dictionary = core.command("banner_call %d" % int(hoplite_company.id))
	var now: Dictionary = companies(called, "hoplite").filter(func(b): return int(b.id) == int(hoplite_company.id))[0]
	check(not bool(now.home) and called.banners.filter(func(b): return not bool(b.home)).size() == 1, "calling one company calls only that company")
	# Soldiers walk out of the houses that supply them (hoplites from elite houses of level 2, horsemen from level 4, rock
	# throwers and archers from common houses of level 2); the test city has no elite houses, so those companies stay in the palace.
	check(walkers_of(core, "walker_hopliteposeidon") == 0, "a called-out company whose elite houses do not exist sends no soldier out")
	var sent: Dictionary = core.command("banner_home %d" % int(hoplite_company.id))
	check(sent.banners.all(func(b): return bool(b.home)), "sending it home brings every company home again")

	# ---------------------------------------------------------- calling everyone
	var everyone: Dictionary = core.command("army_call")
	check(everyone.banners.all(func(b): return not bool(b.home)), "calling the army calls every company out")
	check(walkers_of(core, "walker_chariotposeidon") == 0 and walkers_of(core, "walker_hopliteposeidon") == 0, "no hoplite or horseman walks out without elite houses to send them")
	check(walkers_of(core, "walker_archerposeidon") == soldiers(everyone, "rock_thrower"), "the archers appear with the archer model (%d)" % soldiers(everyone, "rock_thrower"))
	var home: Dictionary = core.command("army_home")
	check(home.banners.all(func(b): return bool(b.home)), "sending the army home brings every company home")

	# -------------------------------------------------------------- the banner
	var target := Vector2i(-1, -1)
	var anchor: Dictionary = home.banners[0]
	for tile in core.snapshot(true).tiles:
		var spot := Vector2i(int(tile[0]), int(tile[1]))
		if int(tile[5]) and Vector2(spot).distance_to(Vector2(int(anchor.x), int(anchor.y))) > 8.0 and Vector2(spot).distance_to(Vector2(int(anchor.x), int(anchor.y))) < 20.0:
			target = spot
			break
	check(target.x != -1, "a free tile away from the palace is found")
	var moved: Dictionary = core.command("banner_move %d %d %d" % [int(anchor.id), target.x, target.y])
	var after: Dictionary = moved.banners.filter(func(b): return int(b.id) == int(anchor.id))[0] if not moved.has("error") else {}
	check(not moved.has("error") and Vector2(int(after.x), int(after.y)).distance_to(Vector2(target)) <= 4.5, "a banner can be moved to a tile (%s)" % str(moved.get("error", "")))
	check(core.snapshot(false).banners.filter(func(b): return int(b.id) == int(anchor.id))[0].x == after.x, "the snapshot carries the banner's new tile")
	var others_unmoved: bool = true
	for banner in moved.banners:
		if int(banner.id) == int(anchor.id):
			continue
		var original: Dictionary = home.banners.filter(func(b): return int(b.id) == int(banner.id))[0]
		others_unmoved = others_unmoved and banner.x == original.x and banner.y == original.y
	check(others_unmoved, "the other banners stay where they were")
	var palace_move: Dictionary = core.command("banner_move %d %d %d" % [int(anchor.id), int(home.banners[1].x), int(home.banners[1].y)])
	var returned: Dictionary = palace_move.banners.filter(func(b): return int(b.id) == int(anchor.id))[0] if not palace_move.has("error") else {}
	check(not palace_move.has("error") and Vector2(int(returned.x), int(returned.y)).distance_to(Vector2(target)) > 4.5, "a banner sent to the palace area goes back to the palace")

	# ------------------------------------------------------------------ refusals
	var money: int = int(core.snapshot(false).money)
	check(core.command("banner_call 9999").get("error", "") == "unknown_banner" and core.command("banner_home 9999").get("error", "") == "unknown_banner" and core.command("banner_move 9999 %d %d" % [target.x, target.y]).get("error", "") == "unknown_banner", "an unknown company is refused")
	check(core.command("banner_move %d 99999 99999" % int(anchor.id)).get("error", "") == "out_of_map", "a tile off the map is refused")
	check(core.command("banner_move %d 5" % int(anchor.id)).get("error", "") == "invalid_banner_command" and core.command("banner_call x").get("error", "") == "invalid_banner_command", "malformed orders are refused")
	check(core.snapshot(false).money == money, "refused orders change nothing")

	# ------------------------------------------------------- time passes (last)
	core.command("army_call")
	core.command("speed 3")
	core.command("pause 0")
	var archers_out := 0
	for step in 300:
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		answer_events(core, running)
		if step == 100:
			archers_out = walkers_of(core, "walker_archerposeidon")
	core.command("pause 1")
	check(archers_out > 0, "called-out archers stay in the city while time passes (%d)" % archers_out)
	var final_army: Dictionary = core.command("army")
	check(final_army.banners.size() > 0 and final_army.banners.all(func(b): return int(b.count) <= 8), "the companies keep their limit of eight while the housing supplies soldiers")
	core.close_city()
	print("ARMY_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
