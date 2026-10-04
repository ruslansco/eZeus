extends SceneTree
var okay := true
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	print("INDUSTRY_CHECK ", "PASS " if condition else "FAIL ", message)
	okay = okay and condition

func _initialize() -> void:
	call_deferred("run")

func inspect(core: RefCounted, building: Dictionary) -> Dictionary:
	return core.command("inspect %d %d" % [int(building.x), int(building.y)])

func storage_command(info: Dictionary, goods: Dictionary, order: int, limit: int) -> String:
	return "storage %d %d %d %d %d %d" % [int(info.x), int(info.y), int(info.target_token), int(goods.resource), order, limit]

func industry_command(info: Dictionary, resource: int, shutdown: bool) -> String:
	return "industry %d %d %d %d %d" % [int(info.x), int(info.y), int(info.target_token), resource, 1 if shutdown else 0]

func inventory(info: Dictionary) -> Array:
	var counts := []
	for item in info.storage.resources:
		counts.append([int(item.resource), int(item.count), int(item.overflow)])
	return counts

func building_state(state: Dictionary) -> Dictionary:
	var result := {}
	for item in state.buildings:
		var building: Dictionary = item.duplicate()
		building.erase("id") # Session IDs and allocation order are not durable save identity.
		building.erase("animation_offset") # Cosmetic phase is chosen by the native renderer on load.
		result["%d:%d:%d" % [int(item.type), int(item.x), int(item.y)]] = building
	return result

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	for lang in ["en", "ru"]:
		var initial: Dictionary = core.open_city(engine, save, lang)
		check(initial.has("protocol"), lang + " test city loads")
		if not initial.has("protocol"):
			quit(1)
			return
		var stores := {}
		var processors := []
		var growers := {}
		for building in initial.buildings:
			if building.asset in ["warehouse", "granary"] and not stores.has(building.asset):
				stores[building.asset] = building
			if building.asset == "olive_press":
				processors.append(building)
			if building.asset == "growers_lodge":
				growers = building
		check(stores.size() == 2 and processors.size() > 1 and not growers.is_empty(), lang + " storage, shared growers and multiple processors are present")
		if stores.size() != 2 or processors.size() < 2:
			continue
		for kind in stores:
			var building: Dictionary = stores[kind]
			var info: Dictionary = inspect(core, building)
			check(info.has("storage") and info.can_edit and info.storage.bays == 8, lang + " " + kind + " native storage bays and edit permissions")
			check(info.storage.occupied_bays >= 0 and info.storage.occupied_bays <= info.storage.bays and not info.storage.resources.is_empty(), lang + " " + kind + " valid native inventory")
			var original := inventory(info)
			var first: Dictionary = info.storage.resources[0]
			var other: Dictionary = info.storage.resources[-1].duplicate()
			var child := building.duplicate()
			child.x = int(building.x) + 1
			var child_info: Dictionary = inspect(core, child)
			check(child_info.target_token == info.target_token and child_info.storage == info.storage, lang + " " + kind + " child tile resolves to the same object")
			for order in range(4):
				var result: Dictionary = core.command(storage_command(info, first, order, 0))
				info = inspect(core, building)
				check(not result.has("error") and int(info.storage.resources[0].order) == order and int(info.storage.resources[0].limit) == 0, "%s %s order %d uses native flags" % [lang, kind, order])
				check(inventory(info) == original and info.storage.resources[-1] == other, "%s %s order %d preserves stock and other goods" % [lang, kind, order])
			var token: int = info.target_token
			for bad in [[4, 0], [1, -4], [1, 999999], [1, 3]]:
				check(core.command(storage_command(info, first, bad[0], bad[1])).get("error") == "invalid_storage_order", lang + " invalid storage order/limit rejected")
			check(core.command(storage_command(info, first, 1, 4) + " trailing").has("error"), lang + " trailing malformed controls rejected")
			check(core.command("storage 2147483647 2147483647 %d 64 1 4" % token).get("error") == "out_of_map", lang + " extreme coordinates rejected safely")
			var unsupported: Dictionary = first.duplicate()
			unsupported.resource = 8388608
			check(core.command(storage_command(info, unsupported, 1, 4)).get("error") == "unsupported_resource", lang + " unsupported storage goods rejected")
			unsupported.resource = 3
			check(core.command(storage_command(info, unsupported, 1, 4)).get("error") == "invalid_resource", lang + " combined resources rejected")
			inspect(core, processors[0])
			check(core.command(storage_command(info, first, 1, 4)).get("error") == "inspection_target_changed", lang + " switched selection rejects old control token")
			info = inspect(core, building)
			check(core.command(storage_command(info, first, 1, int(first.max_limit))).has("protocol"), lang + " native maximum stock limit accepted")
			if kind == "warehouse":
				for goods in info.storage.resources:
					if int(goods.resource) == 131072:
						check(int(goods.step) == 1 and int(goods.max_limit) == 8 and core.command(storage_command(info, goods, 2, 7)).has("protocol"), lang + " sculptures use one sculpture per bay")
			check(inventory(inspect(core, building)) == original, lang + " all storage changes leave inventory untouched")
		var processor: Dictionary = processors[0]
		var info: Dictionary = inspect(core, processor)
		check(info.production.input.resource == 512 and info.production.input.capacity == 4 and info.production.input.per_output == 1, lang + " olive press exposes native input and recipe")
		check(info.production.outputs[0].resource == 2048 and info.production.outputs[0].capacity == 8, lang + " olive press exposes native output buffer")
		var stock: Dictionary = info.production.duplicate(true)
		var initial_shutdown: bool = info.production.industries[0].shut_down
		check(core.command(industry_command(info, 2048, true)).has("protocol"), lang + " native industry shutdown accepted")
		for peer in processors:
			var current: Dictionary = inspect(core, peer)
			if current.city == info.city:
				check(current.shut_down and int(current.employees) == 0 and current.production.status == "industry_paused", lang + " shutdown applies to every city oil producer and its workers")
		info = inspect(core, processor)
		check(info.production.input == stock.input and info.production.outputs == stock.outputs, lang + " shutdown preserves input and output stock")
		core.command(industry_command(info, 2048, true))
		check(inspect(core, processor).production == info.production, lang + " repeating industry shutdown is idempotent")
		check(core.command(industry_command(info, 1, false)).get("error") == "unsupported_industry", lang + " producer cannot modify unrelated industry")
		check(core.command(industry_command(info, 2048, false)).has("protocol"), lang + " native industry resumes and redistributes workers")
		info = inspect(core, processor)
		check(not info.shut_down and int(info.employees) > 0 and not info.production.industries[0].shut_down, lang + " resumed producer has native staffing")
		core.command(industry_command(info, 2048, initial_shutdown))
		if not growers.is_empty():
			info = inspect(core, growers)
			check(info.production.industries.size() == 2, lang + " shared grower exposes both industries")
			var a: Dictionary = info.production.industries[0].duplicate()
			var b: Dictionary = info.production.industries[1].duplicate()
			core.command(industry_command(info, int(a.resource), true))
			core.command(industry_command(info, int(b.resource), true))
			check(inspect(core, growers).shut_down, lang + " shared producer shuts down when both industries stop")
			core.command(industry_command(info, int(a.resource), false))
			check(not inspect(core, growers).shut_down, lang + " shared producer resumes when one industry resumes")
			core.command(industry_command(info, int(a.resource), a.shut_down))
			core.command(industry_command(info, int(b.resource), b.shut_down))
		var unchanged: Dictionary = core.snapshot(true)
		check(unchanged.time == initial.time and unchanged.money == initial.money and unchanged.tiles == initial.tiles, lang + " inspector actions never advance paused time or edit terrain/money")
		info = inspect(core, stores.warehouse)
		var old_command := storage_command(info, info.storage.resources[0], 0, 0)
		var reloaded: Dictionary = core.open_city(engine, save, lang)
		inspect(core, stores.warehouse)
		check(core.command(old_command).get("error") == "inspection_target_changed", lang + " reload rejects old inspector tokens")
		check(reloaded.money == initial.money and building_state(reloaded) == building_state(initial), lang + " reload discards all in-memory controls")
		var candidate := Vector2i(99999, 99999)
		for tile in reloaded.tiles:
			if not int(tile[5]) or int(tile[4]):
				continue
			var preview: Dictionary = core.command("preview warehouse %d %d 0" % [int(tile[0]), int(tile[1])])
			if preview.get("valid", false):
				candidate = Vector2i(int(tile[0]), int(tile[1]))
				break
		check(candidate != Vector2i(99999, 99999), lang + " stale-control fixture has a valid warehouse site")
		if candidate != Vector2i(99999, 99999):
			core.command("build warehouse %d %d 0" % [candidate.x, candidate.y])
			var built := {"x": candidate.x, "y": candidate.y}
			info = inspect(core, built)
			old_command = storage_command(info, info.storage.resources[0], 0, 0)
			core.command("demolish %d %d 0" % [candidate.x, candidate.y])
			check(core.command(old_command).get("error") == "inspection_target_changed", lang + " demolished target rejects queued storage control")
			core.command("build warehouse %d %d 0" % [candidate.x, candidate.y])
			inspect(core, built)
			check(core.command(old_command).get("error") == "inspection_target_changed", lang + " replacement on the same footprint rejects old target token")
			core.command("undo")
			check(core.command(old_command).get("error") == "inspection_target_changed", lang + " construction undo also invalidates the old target")
		core.open_city(engine, save, lang)
		# Pending native decisions must retain their original callbacks.
		info = inspect(core, processors[0])
		core.command("speed 3")
		core.command("pause 0")
		for tick in range(40):
			core.advance(.05)
		var pending: Dictionary = core.snapshot(false)
		check(pending.blocked and not pending.events.is_empty(), lang + " native decision remains pending")
		check(core.command(industry_command(info, 2048, true)).get("error") == "pending_decision", lang + " industry control cannot bypass a pending decision")
		check(core.snapshot(false).events == pending.events, lang + " rejected control retains native decision callbacks and data")
	core.close_city()
	print("INDUSTRY_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
