extends SceneTree
# The hazard alert icons (ui/hazard_rail.gd): the core's snapshot lists an alert for every hazard event of the player's city
# (the SDL view's alert tiles) whether or not the event has words, and the rail makes one button per kind. Headless, in memory.
const HazardRail = preload("res://ui/hazard_rail.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("HAZARD_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://").path_join("..")
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol") and (initial.get("alerts", []) as Array).is_empty(), "the designated city opens with no alerts")
	core.enable_test_commands()
	var seen := {}
	for kind in ["fire", "collapse", "earthquake", "tidalWave", "lavaFlow", "plague", "invasion", "godInvasion", "godVisit", "heroArrival", "armyReturns", "monsterInCity", "lavaFlowGod", "sinkLand", "sinkLandGod", "landSlide", "areaCutOff", "invasion24", "invasion1", "monsterInvasion24", "monsterInvasion1", "riskWarning", "shortageWarning"]:
		var args := ""
		if kind in ["godInvasion", "godVisit"]: args = " god zeus"
		elif kind == "heroArrival": args = " hero hercules"
		elif kind == "monsterInCity" or kind.begins_with("monsterInvasion"): args = " monster hydra"
		var reply: Dictionary = core.command("test_raise " + kind + args)
		check(not reply.has("error"), kind + " is raised")
		for alert in reply.get("alerts", []):
			seen[str(alert.kind)] = int(alert.id)
	for kind in ["fire", "collapse", "earthquake", "tidalWave", "lavaFlow", "plague", "invasion", "godInvasion", "godVisit", "heroArrival", "armyReturns", "monsterInCity", "lavaFlowGod", "sinkLand", "sinkLandGod", "landSlide", "areaCutOff", "invasion24", "invasion1", "monsterInvasion24", "monsterInvasion1", "riskWarning"]:
		check(seen.has(kind), kind + " arrives as an alert")
		check(kind == "monsterInCity" or HazardRail.GROUP.has(kind), kind + " has a button in the rail")
	check(not seen.has("shortageWarning"), "a journal-only event raises no alert")

	# The rail: one button per kind, counts, dedup by place, ids once, dismissal.
	var column := VBoxContainer.new()
	root.add_child(column)
	column.add_child(Button.new())
	var rail: Node = HazardRail.new()
	root.add_child(rail)
	rail.attach(column, func(name): return load("res://ui/toolbar_icons/notice_%s.svg" % name.trim_prefix("alert_")))
	var jumped := []
	rail.go_requested.connect(func(cell): jumped.append(cell))
	rail.observe([{"id": 1, "kind": "fire", "at": [10, 12]}, {"id": 2, "kind": "fire", "at": [20, 22]}, {"id": 3, "kind": "tidalWave", "at": [-1, -1]}, {"id": 4, "kind": "monsterInCity", "at": [1, 1]}])
	check(rail.buttons.size() == 2 and column.get_child_count() == 3, "fire and flood each get a button of their own; monsters keep theirs")
	check(rail.buttons.fire.badge == "2" and rail.buttons.flood.badge == "", "the fire button counts two fires, the flood one has no count")
	rail.observe([{"id": 2, "kind": "fire", "at": [20, 22]}, {"id": 5, "kind": "fire", "at": [20, 22]}])
	check(rail.alerts.fire.size() == 2, "an old id is ignored and the same hazard at the same place is one alert")
	rail.buttons.fire.pressed.emit()
	rail.buttons.flood.pressed.emit()
	check(jumped == [Vector2i(20, 22)], "a button goes to its newest site; an alert with no place goes nowhere")
	check(HazardRail.GROUP.keys().all(func(kind): return HazardRail.ORDER.has(HazardRail.GROUP[kind])), "every kind has a place in the rail order")
	check(HazardRail.ORDER.all(func(group): return icon_exists(group)), "every kind has its icon")
	var remaining: float = rail.alerts.fire[0].left
	rail.suspended = true
	rail._process(HazardRail.LIFETIME+1)
	check(rail.alerts.fire[0].left==remaining,"a required correspondence modal holds hazard attention timers")
	rail.suspended = false
	root.get_node("UiAccess").dialog_open = true
	rail._process(HazardRail.LIFETIME+1)
	check(rail.alerts.fire[0].left==remaining,"other blocking dialogs also preserve hazard attention timers")
	root.get_node("UiAccess").dialog_open = false
	rail.buttons.fire.hide()
	rail._process(HazardRail.LIFETIME+1)
	check(rail.alerts.fire[0].left==remaining,"hidden hazard controls cannot expire before being seen")
	rail.buttons.fire.show()
	rail._process(HazardRail.LIFETIME + 1.0)
	check(rail.buttons.is_empty() and column.get_child_count() == 1, "alerts lapse and their buttons go")
	# Fire and plague stay while they last.
	var snapshot: Dictionary = core.snapshot(true)
	check(snapshot.has("plague") and int(snapshot.plague.houses) == 0, "the snapshot says how many houses the plague holds")
	var rail2: Node = HazardRail.new()
	root.add_child(rail2)
	var column2 := VBoxContainer.new()
	root.add_child(column2)
	column2.add_child(Button.new())
	rail2.attach(column2, func(name): return load("res://ui/toolbar_icons/notice_%s.svg" % name.trim_prefix("alert_")))
	rail2.set_persistent("plague", 3, Vector2i(5, 6))
	check(rail2.buttons.has("plague") and rail2.buttons.plague.badge == "3", "a plague in three houses shows its button with the count")
	rail2._process(HazardRail.LIFETIME * 5)
	check(rail2.buttons.has("plague"), "the plague button does not lapse while the plague lasts")
	var went := []
	rail2.go_requested.connect(func(cell): went.append(cell))
	rail2.buttons.plague.pressed.emit()
	check(went == [Vector2i(5, 6)], "it goes to a sick house")
	rail2._dismiss("plague")
	rail2.set_persistent("plague", 2, Vector2i(5, 6))
	check(not rail2.buttons.has("plague"), "a button put away stays away while the same plague lasts")
	rail2.set_persistent("plague", 0, null)
	rail2.set_persistent("plague", 1, Vector2i(1, 1))
	check(rail2.buttons.has("plague"), "a new plague brings it back")
	rail2.set_persistent("plague", 0, null)
	check(not rail2.buttons.has("plague"), "the button goes when the plague is over")
	root.get_node("UiAccess").reduced_motion = true
	rail2.set_persistent("fire",1,Vector2i(1,1))
	check(rail2.buttons.fire.attention==null,"Reduce interface motion suppresses the alert highlight")
	print("HAZARD_CHECK ", "PASS" if okay else "FAIL", " ", checks, " checks")
	quit(0 if okay else 1)

func icon_exists(group: String) -> bool:
	return load("res://ui/toolbar_icons/notice_%s.svg" % group) != null
