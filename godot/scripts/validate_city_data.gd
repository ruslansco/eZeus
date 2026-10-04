extends SceneTree
# The SDL side panel's data pages in the core (headless, in memory; the designated save is never written): `city_data` lists
# the twelve pages' lines with the native verdicts, the tax and wage rates, the workforce allocation and the finances in the
# core's language; asking never changes the city (the replay digest holds); set_tax, set_wage, set_priority and man_towers
# change the city as the SDL pages do (the workers are shared out again after a priority), refuse what the city does not
# offer and answer the new data.
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("CITY_DATA_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	return core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)

func page(data: Dictionary, id: String) -> Dictionary:
	for item in data.get("pages", []):
		if item.id == id:
			return item
	return {}

func sector(data: Dictionary, id: int) -> Dictionary:
	for item in data.workforce.sectors:
		if int(item.sector) == id:
			return item
	return {}

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		check(open(core, lang).has("protocol"), lang + " designated test city loads")
		var data: Dictionary = core.command("city_data")
		check(data.get("kind", "") == "city_data", lang + " city_data answers")
		var ids: Array = data.get("pages", []).map(func(p): return p.id)
		check(ids == ["overview", "population", "employment", "administration", "husbandry", "storage", "hygiene", "appeal", "culture", "science", "military"],
			lang + " the SDL pages are there (mythology is its own query) %s" % str(ids))
		var overview := page(data, "overview")
		check(overview.lines.size() == 6 and overview.lines.all(func(l): return not str(l.label).is_empty() and int(l.severity) in [0, 1, 2]), lang + " the overview has its six verdicts")
		check(overview.views.map(func(v): return v.overlay) == ["problems", "roads"], lang + " the overview's See buttons are problems and roads")
		var every_overlay := true
		for item in data.pages:
			for view in item.views:
				every_overlay = every_overlay and not str(view.label).is_empty() and not core.command("overlay " + str(view.overlay)).has("error")
		check(every_overlay, lang + " every page's See button opens a native overlay")
		check(data.tax.options.size() == 7 and data.tax.options.map(func(o): return int(o.percent)) == [0, 3, 7, 9, 11, 15, 20], lang + " the tax rates come in the order of their percentage %s" % str(data.tax.options.map(func(o): return int(o.percent))))
		check(data.wage.names.size() == 6 and data.workforce.sectors.size() == 8 and data.workforce.priorities.size() == 6, lang + " six wage rates, eight sectors and six priorities")
		check(data.finances.rows.size() == 16 and data.finances.rows[-1].kind == "net" and int(data.finances.rows[-1]["this"]) == int(data.finances.rows[7]["this"]) - int(data.finances.rows[14]["this"]),
			lang + " the finances add up (net = income - expenses)")
		check(page(data, "storage").goods.size() >= 15, lang + " the storage page lists the goods (%d)" % page(data, "storage").goods.size())
		var military := page(data, "military")
		check(military.soldiers.action in ["army_call", "army_home", ""] and not str(military.towers.text).is_empty(), lang + " the military page has its soldiers' and towers' buttons")
		if lang == "ru":
			check(str(overview.lines[0].label).unicode_at(0) >= 0x400 and str(data.finances.title).unicode_at(0) >= 0x400, "ru the pages are worded from the Russian native dictionary")
		# Asking changes nothing.
		var before: Dictionary = core.snapshot(true)
		for i in 4:
			core.command("city_data")
		var after: Dictionary = core.snapshot(true)
		check(after.money == before.money and after.time == before.time and after.buildings == before.buildings, lang + " city_data does not change the city")
		# Taxes: every rate the city offers, in turn; the answer is the new data.
		for option in data.tax.options:
			var answer: Dictionary = core.command("set_tax %d" % int(option.id))
			check(answer.get("kind", "") == "city_data" and int(answer.tax.rate) == int(option.id) and page(answer, "administration").lines[0].value == option.name, lang + " the tax rate becomes " + str(option.name))
		check(core.command("set_tax 7").has("error") and core.command("set_tax x").has("error") and core.command("set_tax 1 2").has("error"), lang + " an unknown tax rate is refused")
		core.command("set_tax %d" % int(data.tax.rate))
		# Wages.
		for rate in [0, 5, int(data.wage.rate)]:
			var answer: Dictionary = core.command("set_wage %d" % rate)
			check(int(answer.wage.rate) == rate and page(answer, "employment").lines[0].value == data.wage.names[rate], lang + " the wage rate becomes " + str(data.wage.names[rate]))
		check(core.command("set_wage 6").has("error"), lang + " an unknown wage rate is refused")
		# Priorities: with no priority, the sector gets no workers once they are shared out again; back to moderate, it gets them back.
		var husbandry_before := sector(data, 0)
		var none: Dictionary = core.command("set_priority 0 0")
		check(int(sector(none, 0).priority) == 0 and int(sector(none, 0).have) == 0 and int(husbandry_before.have) > 0,
			lang + " husbandry with no priority loses its workers (%d to %d)" % [int(husbandry_before.have), int(sector(none, 0).have)])
		var high: Dictionary = core.command("set_priority 0 5")
		check(int(sector(high, 0).priority) == 5 and int(sector(high, 0).have) >= int(husbandry_before.have), lang + " husbandry at very high priority gets at least the workers it had (%d)" % int(sector(high, 0).have))
		var back: Dictionary = core.command("set_priority 0 %d" % int(husbandry_before.priority))
		check(int(sector(back, 0).priority) == int(husbandry_before.priority), lang + " and back to its priority")
		check(core.command("set_priority 8 3").has("error") and core.command("set_priority 0 6").has("error") and core.command("set_priority 0").has("error"), lang + " an unknown sector or priority is refused")
		# Towers (the test city has none: the button says so, the setting still holds).
		var manned: Dictionary = core.command("man_towers 0")
		check(not bool(page(manned, "military").towers.manning) and bool(page(core.command("man_towers 1"), "military").towers.manning), lang + " towers are set to stand down and to be manned")
		check(core.command("man_towers 2").has("error"), lang + " man_towers takes 0 or 1")
		# The city runs on with its settings.
		core.command("set_tax 4")
		var ran: Dictionary = core.replay(300, 7)
		check(ran.has("digest") and int(core.command("city_data").tax.rate) == 4, lang + " the city runs 300 ticks and keeps its tax rate")
		core.close_city()
	# Asking for the pages leaves the replay unchanged.
	open(core, "en")
	var plain: Dictionary = core.replay(200, 7)
	core.close_city()
	open(core, "en")
	for i in 3:
		core.command("city_data")
	var asked: Dictionary = core.replay(200, 7)
	core.close_city()
	check(plain.has("digest") and plain.digest == asked.digest, "asking for city_data leaves the replay digest unchanged (%s)" % plain.get("digest", ""))
	print("CITY_DATA_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
