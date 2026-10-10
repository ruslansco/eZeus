extends SceneTree
# Demolition dragged over a rectangle against the embedded core (headless, in memory): `preview_demolish_area` lists what the
# SDL erase tool would remove and what it costs, `demolish_area` removes it as the native rules do (each building once, forest
# tiles cleared, a landmark only with the player's confirmation and the token of the set that was shown), and nothing is
# written to the designated save.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("AREA_DEMOLITION_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func rect_text(a: Vector2i, b: Vector2i) -> String:
	return "%d %d %d %d" % [a.x, a.y, b.x, b.y]

func building_at(state: Dictionary, cell: Vector2i) -> bool:
	for b in state.buildings:
		if int(b.x) <= cell.x and cell.x < int(b.x) + int(b.w) and int(b.y) <= cell.y and cell.y < int(b.y) + int(b.h):
			return true
	return false

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var initial: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	check(initial.has("protocol"), "designated test city loads paused")
	var state: Dictionary = core.snapshot(true)

	# An ordinary block: a window around some building with several neighbours and no landmark in it.
	var low := Vector2i.ZERO
	var high := Vector2i.ZERO
	var plan: Dictionary = {}
	for b in state.buildings:
		var a := Vector2i(int(b.x) - 2, int(b.y) - 2)
		var z := Vector2i(int(b.x) + 3, int(b.y) + 3)
		var candidate: Dictionary = core.command("preview_demolish_area " + rect_text(a, z))
		if candidate.get("valid", false) and not candidate.protected and int(candidate.count) >= 3 and int(candidate.count) <= 80:
			low = a
			high = z
			plan = candidate
			break
	check(not plan.is_empty(), "a rectangle with several ordinary buildings is found")
	if plan.is_empty():
		core.close_city()
		quit(1)
		return
	var unit: int = plan.unit_cost
	check(int(plan.cost) == unit * int(plan.count) and int(plan.count) == int(plan.buildings) + int(plan.forests), "the plan's cost is the native demolition cost for every building and forest tile once")
	check(int(plan.tiles.size()) == int(plan.count) and not plan.confirmation_required, "every target is listed once and nothing asks for confirmation")
	var swapped: Dictionary = core.command("preview_demolish_area " + rect_text(high, low))
	check(int(swapped.count) == int(plan.count) and int(swapped.cost) == int(plan.cost), "the corners can be dragged in any order")
	var from_other_corner: Dictionary = core.command("preview_demolish_area " + rect_text(Vector2i(high.x, low.y), Vector2i(low.x, high.y)))
	check(int(from_other_corner.count) == int(plan.count), "so can the other diagonal")

	var money: int = state.money
	var before_count: int = state.buildings.size()
	var done: Dictionary = core.command("demolish_area %s 0" % rect_text(low, high))
	check(not done.has("error") and int(done.money) == money - int(plan.cost), "demolishing charges the quoted cost: %s" % str(done.get("error", "")))
	check(not done.get("undo_available", true), "area demolition, like single, cannot be undone and clears construction undo")
	var after: Dictionary = core.snapshot(true)
	check(after.buildings.size() <= before_count, "the snapshot's building list did not grow")
	var again: Dictionary = core.command("preview_demolish_area " + rect_text(low, high))
	check(not again.valid and again.reason == "nothing_to_demolish" and int(again.count) == 0, "the same rectangle then has nothing to demolish")
	var repeated: Dictionary = core.command("demolish_area %s 0" % rect_text(low, high))
	check(repeated.get("error", "") == "nothing_to_demolish" and int(core.snapshot(true).money) == int(done.money), "demolishing an empty rectangle is refused and charges nothing")

	# A rectangle with a landmark (a temple, the palace or a stocked agora): spared, or removed with the confirmation.
	var landmark_rect := ""
	var landmark_plan: Dictionary = {}
	for b in after.buildings:
		var a := Vector2i(int(b.x) - 1, int(b.y) - 1)
		var z := Vector2i(int(b.x) + int(b.w), int(b.y) + int(b.h))
		var candidate: Dictionary = core.command("preview_demolish_area " + rect_text(a, z))
		if candidate.get("valid", false) and int(candidate.protected) >= 1:
			landmark_rect = rect_text(a, z)
			landmark_plan = candidate
			break
	check(not landmark_plan.is_empty(), "a rectangle holding a landmark is found")
	if not landmark_plan.is_empty():
		check(landmark_plan.confirmation_required and int(landmark_plan.cost_spared) == int(landmark_plan.cost) - int(landmark_plan.protected) * unit, "the plan says it needs confirmation and quotes the price without the landmarks")
		var amber := 0
		for cell in landmark_plan.tiles:
			amber += 1 if int(cell[5]) == 2 else 0
		check(amber == int(landmark_plan.protected), "landmarks are listed apart from ordinary targets")
		var m0: int = core.snapshot(true).money
		var wrong: Dictionary = core.command("demolish_area %s 1 999999" % landmark_rect)
		check(wrong.get("error", "") == "demolition_target_changed", "a confirmation with a stale token is rejected")
		check(int(core.snapshot(true).money) == m0, "and charges nothing")
		var spared: Dictionary = core.command("demolish_area %s 0" % landmark_rect)
		check(not spared.has("error") or spared.error == "nothing_to_demolish", "without confirmation the rest goes")
		if not spared.has("error"):
			check(int(spared.money) == m0 - int(landmark_plan.cost_spared), "and only the rest is charged")
		var left: Dictionary = core.command("preview_demolish_area " + landmark_rect)
		check(int(left.protected) == int(landmark_plan.protected) and int(left.count) == int(left.protected), "the landmarks are still standing")
		var m1: int = core.snapshot(true).money
		var confirmed: Dictionary = core.command("demolish_area %s 1 %d" % [landmark_rect, int(left.target_token)])
		check(not confirmed.has("error") and int(confirmed.money) == m1 - int(left.cost), "with the current token the landmark is demolished and charged: %s" % str(confirmed.get("error", "")))
		# As in the SDL view, taking an agora away uncovers the street it stood on; that street goes with a second drag.
		var rest: Dictionary = core.command("preview_demolish_area " + landmark_rect)
		check(int(rest.protected) == 0 and not rest.confirmation_required, "no landmark is left in the rectangle")
		var m2: int = core.snapshot(true).money
		var sweep: Dictionary = core.command("demolish_area %s 0" % landmark_rect)
		check(not sweep.has("error") and int(sweep.money) == m2 - int(rest.cost) and int(core.command("preview_demolish_area " + landmark_rect).count) == 0, "a second drag clears what the landmark uncovered")

	# Bad input and the map's edge.
	check(core.command("demolish_area 1 2 3").has("error"), "a malformed command is rejected")
	check(core.command("preview_demolish_area 100000 100000 100010 100010").get("error", "") == "out_of_map", "a rectangle outside the map is refused")
	check(core.command("demolish_area 100000 100000 100010 100010 0").get("error", "") == "out_of_map", "and so is its demolition")
	var huge: Dictionary = core.command("preview_demolish_area -50 -50 5000 5000")
	check(huge.has("kind") and int(huge.tiles.size()) <= 3000, "a rectangle larger than the map is clamped and its list bounded")
	core.close_city()
	print("AREA_DEMOLITION_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
