extends SceneTree
# Designated city in memory only. Scratch round trips keep the native save layout.
const Inspector = preload("res://scripts/building_inspector.gd")
const Summary = preload("res://ui/inspection_summary.gd")
var okay := true
var checks := 0

func check(value: bool, text: String) -> void:
	checks += 1
	okay = okay and value
	print("RUINS_CHECK ", "PASS " if value else "FAIL ", text)

func _initialize() -> void:
	call_deferred("run")

func command(core: RefCounted, action: String, cell: Vector2i) -> Dictionary:
	return core.command("%s %d %d" % [action, cell.x, cell.y])

func footprint(data: Array) -> Rect2i:
	return Rect2i(int(data[0]),int(data[1]),int(data[2]),int(data[3]))

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var before := FileAccess.get_sha256(save)
	var scratch := "/tmp/ezeus-ruins-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(scratch)
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		TranslationServer.set_locale(lang)
		core.set_save_directory(scratch)
		var initial: Dictionary = core.open_city(engine, save, lang)
		core.enable_test_commands()
		check(initial.has("protocol"), lang + " designated city opens")
		var tiles := {}
		for tile in initial.tiles: tiles[Vector2i(int(tile[0]), int(tile[1]))] = tile
		var site := Vector2i(99999, 99999)
		for cell in tiles:
			var clear := true
			for dx in 7:
				for dy in 3:
					var t: Array = tiles.get(cell + Vector2i(dx, dy), [])
					clear = clear and t.size() > 5 and int(t[5]) == 1 and int(t[4]) == 0
			if clear and core.command("preview gymnasium %d %d 0" % [cell.x, cell.y]).get("valid", false) and core.command("preview gymnasium %d %d 0" % [cell.x + 3, cell.y]).get("valid", false):
				site = cell
				break
		check(site.x != 99999, lang + " adjacent 3×3 native plots are found")
		if site.x == 99999: continue
		var other := site + Vector2i(3, 0)
		var park := site + Vector2i(6, 0)
		for cell in [site, other]:
			check(not core.command("build gymnasium %d %d 0" % [cell.x, cell.y]).has("error"), lang + " native gymnasium is built")
		core.command("build park %d %d 0" % [park.x, park.y])
		var standing: Dictionary = command(core, "inspect", site)
		var original_name := str(standing.name)
		var original_type := int(standing.type)
		for cell in [site, other]: command(core, "test_collapse", cell)
		var target: Dictionary = command(core, "inspect", site + Vector2i(2, 2))
		check(target.ruin.original_name == original_name and int(target.ruin.original_type) == original_type, lang + " ruins identify the former native building")
		check(footprint(target.footprint) == Rect2i(site,Vector2i(3,3)) and int(target.ruin.tiles) == 9, lang + " clicked corner selects the full original footprint")
		check(target.ruin.can_demolish and not target.has("production") and not target.has("employees"), lang + " ruined building has clearing controls rather than live production")
		var token := int(core.command("preview demolish %d %d 0" % [site.x,site.y]).target_token)
		for dx in 3:
			for dy in 3:
				var p: Dictionary = core.command("preview demolish %d %d 0" % [site.x + dx, site.y + dy])
				check(p.valid and p.x == site.x and p.y == site.y and p.w == 3 and p.h == 3 and int(p.target_token) == token and p.tiles.is_empty() and int(p.cost) == int(target.ruin.cost), lang + " hover %d,%d shows one stable whole-site selection" % [dx, dy])
		var single: Dictionary = core.command("preview_demolish_area %d %d %d %d" % [site.x + 1, site.y + 1, site.x + 1, site.y + 1])
		check(single.tiles.size() == 1 and footprint(single.tiles[0]) == Rect2i(site,Vector2i(3,3)) and int(single.count) == 9 and int(single.cost) == int(target.ruin.cost), lang + " press/drag preview lists one ruin plate at the full native cost")
		var inspector := Inspector.new()
		root.add_child(inspector)
		inspector.show_inspection(target)
		check(inspector.ruin_demolish_button != null and not inspector.ruin_demolish_button.disabled and inspector.ruin_demolish_button.text.contains(str(int(target.ruin.cost))), lang + " panel offers Demolish with full cost")
		var emitted: Array[String] = []
		inspector.action_requested.connect(func(text): emitted.append(text))
		inspector.ruin_demolish_button.pressed.emit()
		check(emitted == ["demolish_ruin %d %d %d %d" % [int(target.x),int(target.y),int(target.target_token),int(target.ruin.target_token)]], lang + " panel action carries both current target guards")
		check(inspector.pending and inspector.ruin_demolish_button.disabled, lang + " duplicate panel clearing is disabled while pending")
		inspector.command_done(emitted[0], false)
		check(not inspector.pending and not inspector.ruin_demolish_button.disabled, lang + " refused queue handoff releases the button")
		inspector.free()
		var summary := Summary.new()
		root.add_child(summary)
		summary.show_data(target)
		check(summary.status_id == "ruin" and not summary.metrics.maintenance.column.visible and not summary.metrics.road.column.visible and not summary.grid.visible and not summary.views.visible, lang + " ruin summary hides misleading maintenance and road readings")
		summary.free()
		var money := int(core.snapshot(true).money)
		command(core, "inspect", other)
		var stale: Dictionary = core.command(emitted[0])
		check(stale.get("error") == "inspection_target_changed" and int(core.snapshot(true).money) == money, lang + " stale inspector cannot clear a different target")
		core.command("preview demolish %d %d 0" % [other.x, other.y])
		check(core.command("demolish %d %d 0 %d" % [site.x, site.y, token]).get("error") == "demolition_target_changed", lang + " stale hover cannot clear a changed target")
		var other_hover: Dictionary = core.command("preview demolish %d %d 0" % [other.x,other.y])
		command(core,"inspect",site)
		check(int(core.command("preview demolish %d %d 0" % [other.x,other.y]).target_token) == int(other_hover.target_token), lang + " inspector refresh cannot invalidate another ruin's demolition hover")
		check(core.save_city("ruin roundtrip").has("saved"), lang + " native rubble saves to scratch")
		core.close_city()
		core.open_city(engine, scratch.path_join("ruin roundtrip.ez"), lang)
		core.enable_test_commands()
		for cell in [site, other]:
			var restored: Dictionary = command(core, "inspect", cell + Vector2i(2, 2))
			check(restored.ruin.original_name == original_name and footprint(restored.footprint) == Rect2i(cell,Vector2i(3,3)) and int(restored.ruin.tiles) == 9, lang + " saved adjacent ruins recover separate original buildings")
		check(core.command(emitted[0]).get("error") == "inspection_target_changed", lang + " pre-reload panel token is rejected")
		command(core, "test_fire", site + Vector2i(2, 2))
		var burning: Dictionary = command(core, "inspect", site)
		check(not burning.ruin.can_demolish and burning.ruin.reason == "on_fire", lang + " fire anywhere in the ruin blocks the whole clearing")
		check(core.command("preview demolish %d %d 0" % [site.x, site.y]).reason == "on_fire", lang + " fire rule matches hover")
		check(core.command("demolish %d %d 0" % [site.x, site.y]).get("error") == "on_fire", lang + " direct clearing cannot skip burning rubble")
		core.close_city()
		core.open_city(engine, scratch.path_join("ruin roundtrip.ez"), lang)
		target = command(core, "inspect", site)
		money = int(core.snapshot(true).money)
		var cleared: Dictionary = core.command("demolish_ruin %d %d %d %d" % [site.x,site.y,int(target.target_token),int(target.ruin.target_token)])
		check(not cleared.has("error") and int(cleared.money) == money - int(target.ruin.cost), lang + " panel clears whole site and charges exactly quoted native cost")
		check(not command(core, "inspect", site).has("footprint") and command(core, "inspect", other).has("ruin") and command(core, "inspect", park).has("footprint"), lang + " neighbor ruins and standing park survive")
		check(core.command("demolish %d %d 0" % [site.x,site.y]).get("error") == "nothing_to_demolish", lang + " repeated clearing is refused")
		target = command(core, "inspect", other)
		money = int(core.snapshot(true).money)
		cleared = core.command("demolish_area %d %d %d %d 0" % [other.x + 1,other.y + 1,other.x + 1,other.y + 1])
		check(not cleared.has("error") and int(cleared.money) == money - int(target.ruin.cost) and not cleared.undo_available, lang + " rectangle contact clears the remaining whole ruin without undo")
		var empty := true
		for dx in 6:
			for dy in 3: empty = empty and not command(core, "inspect", site + Vector2i(dx,dy)).has("footprint")
		check(empty and command(core, "inspect", park).has("footprint"), lang + " every rubble cell is cleared and neighboring property remains")
		core.close_city()
	check(FileAccess.get_sha256(save) == before, "designated source save is unchanged")
	for file in DirAccess.get_files_at(scratch): DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	print("RUINS_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
