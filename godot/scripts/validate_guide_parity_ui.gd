extends RefCounted
# The Zeus guide's gameplay in the running city's interface (windowed; validate_guide_parity.gd checks the engine side headless):
# the City window's storage page stockpiles a good with a tick (the original Distribution tab), its military page has Auto Defend and,
# with a wharf, Crew All; the Army panel's Auto Defend switch holds the player's own orders; the Enlist Forces dialog has a Navy
# section that names a city the sea does not reach; the oracle's prophecy is worded in the interface language.
# Run alone by review_original_keys.gd --parity (tools/review_original_keys.py --parity) and inside the full --validate run.

const CityDialog = preload("res://ui/city_dialog.gd")
const EnlistDialog = preload("res://ui/enlist_dialog.gd")
const BuildingInspector = preload("res://scripts/building_inspector.gd")

var city
var checks := 0
var okay := true

func check(condition: bool, message: String) -> void:
	checks += 1
	okay = okay and condition
	city.check(condition, message)

func wait(seconds: float) -> void:
	await city.get_tree().create_timer(seconds).timeout

func city_window() -> Window:
	for child in city.hud.get_children():
		if child is Window and child.visible and child.title == city.tr("City"):
			return child
	return null

func run(scene) -> bool:
	city = scene
	city.core.send("pause 1")
	await wait(.3)

	# ---------------------------------------------------------------- the storage page: stockpiling
	CityDialog.open(city.hud, city.core, func(id): city.set_overlay(id), func(cell): city.jump_to_cell(Vector2(cell)), "storage")
	await wait(.5)
	var window := city_window()
	check(window != null, "the City window opens on its storage page")
	if window != null:
		var boxes: Array = window.find_children("Stockpile*", "CheckBox", true, false)
		check(boxes.size() == 20 and boxes.all(func(box): return not box.button_pressed), "each of the twenty goods has a stockpile tick, none ticked (%d)" % boxes.size())
		var wheat: Array = boxes.filter(func(box): return box.name == "Stockpile64")
		if wheat.size() == 1:
			wheat[0].button_pressed = true
			await wait(.6)
			var data: Dictionary = city.core.query("city_data")
			var kept := false
			for page in data.pages:
				if page.id == "storage":
					for good in page.goods:
						kept = kept or (int(good.resource) == 64 and bool(good.stockpiled))
			check(kept and city.hint.text == city.tr("The good is stockpiled: it stays in the granaries and storehouses."), "ticking wheat stockpiles it in the city: %s" % city.hint.text)
			var again: Array = window.find_children("Stockpile64", "CheckBox", true, false)
			check(again.size() == 1 and again[0].button_pressed, "and the refreshed page shows it ticked")
			if again.size() == 1:
				again[0].button_pressed = false
				await wait(.6)
		window.show_page("military")
		await wait(.4)
		var defend: Array = window.find_children("AutoDefend", "CheckButton", true, false)
		check(defend.size() == 1 and not defend[0].button_pressed, "the military page has the Auto Defend switch, off")
		window.queue_free()
		await wait(.2)

	# ---------------------------------------------------------------- the Army panel's Auto Defend
	city.open_army()
	await wait(.3)
	var panel = city.army_panel
	check(panel.visible and panel.auto_defend_check != null and panel.auto_defend_check.text == city.tr("Auto Defend") and not panel.auto_defend_check.button_pressed, "the Army panel offers Auto Defend")
	if panel.auto_defend_check != null:
		panel.auto_defend_check.button_pressed = true
		await wait(.6)
		check(bool(city.core.query("army").get("auto_defend", false)) and panel.call_all.disabled, "switched on, the city defends itself and Call all out waits")
		var refused: Dictionary = city.core.query("army_call")
		check(refused.get("error", "") == "auto_defend" and city.reason_text("auto_defend") != "auto_defend", "the core refuses the player's call to arms, and the refusal has words: %s" % city.reason_text("auto_defend"))
		panel.auto_defend_check.button_pressed = false
		await wait(.6)
		check(not bool(city.core.query("army").get("auto_defend", true)) and not panel.call_all.disabled, "switched off, the orders are the player's again")
	if panel.visible:
		panel.close()

	# ---------------------------------------------------------------- the Navy in the Enlist Forces dialog
	var session := {"purpose": "raid", "city": 3, "event": 0, "cities": [{"id": 0, "name": "Home"}], "soldiers": [], "heroes": [], "allies": [], "plunder": [],
		"target": {"index": 3, "name": "Sparta"}, "ares": {"sanctuary": false},
		"triremes": [{"index": 0, "city": 0, "x": 1, "y": 1, "reachable": true}, {"index": 1, "city": 0, "x": 4, "y": 1, "reachable": false}]}
	var enlist = EnlistDialog.open(city.ui_layer, city.core, session)
	await wait(.3)
	var rows: Array = enlist.buttons.filter(func(entry): return entry.kind == "t")
	check(rows.size() == 2 and not rows[0].button.disabled and rows[1].button.disabled and rows[1].button.text.contains(city.tr("not accessible by sea")), "the dialog's Navy lists the manned triremes and says which cannot reach the city by sea")
	if rows.size() == 2:
		rows[0].button.button_pressed = true
		check(enlist.command_text().ends_with(" t:0") and enlist.summary.text.contains("1"), "a chosen trireme goes with the dispatch: %s" % enlist.command_text())
	enlist.close()

	# ---------------------------------------------------------------- the oracle's words
	var words: Array = [BuildingInspector.oracle_text({"granted": true, "kind": "invasion", "months": 7, "who": "Sparta"}),
		BuildingInspector.oracle_text({"granted": true, "kind": "calm"}), BuildingInspector.oracle_text({"granted": false, "ready": 40})]
	check(words[0].contains("7") and words[0].contains("Sparta") and words[1] != words[0] and words[2].contains("40"), "the prophecy names when and who; calm and silence have their own words: %s" % words[0])
	if city.language == "ru":
		check(words.all(func(text): return text.unicode_at(0) >= 0x0400), "in Russian")
	print("GUIDE_PARITY_UI_CHECKS ", "PASS" if okay else "FAIL", " checks=", checks)
	return okay
