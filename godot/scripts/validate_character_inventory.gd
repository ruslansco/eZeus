extends SceneTree
var okay := true
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1; okay = okay and value
	print("CHARACTER_INVENTORY_CHECK ", "PASS " if value else "FAIL ", label)
func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	for lang in ["en","ru"]:
		core.open_city(engine,engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"),lang)
		# The saved city has no active peddler. Let its existing Agora create one
		# through ordinary native ticks; then hold the prepared in-memory city.
		core.command("speed 0"); core.command("pause 0")
		for tick in 200: core.advance(.05)
		core.command("pause 1")
		var before: Dictionary = core.snapshot(true)
		var seen := {}; var records := []
		for walker in before.walkers:
			var answer: Dictionary = core.command("character_inventory %d" % int(walker.id))
			if answer.has("error"): continue
			var inventory: Variant = answer.get("inventory")
			if not inventory is Dictionary: continue
			records.append({"walker":walker,"inventory":inventory})
			seen[str(inventory.kind)] = true
			if inventory.kind == "cargo" and inventory.unit == "loads" and walker.has("cargo_count"):
				check(inventory.items.size()==1 and int(inventory.items[0].count)==int(walker.cargo_count),lang+" actual transporter/trailer quantity matches its native rendered load")
			if inventory.kind == "agora":
				check(inventory.items.size()>=6 and inventory.available,lang+" peddler observes its own current Agora and every supply category")
				var stalls: Array = inventory.items.filter(func(item): return item.present)
				var site: Dictionary = stalls[0] if not stalls.is_empty() else inventory
				var inspected: Dictionary = core.command("inspect %d %d" % [int(site.x),int(site.y)])
				check(inspected.has("agora"),lang+" peddler's supply coordinates resolve to its native Agora inspector")
				if inspected.has("agora"):
					var equal: bool = inspected.agora.vendors.size()==inventory.items.size()
					for i in mini(inspected.agora.vendors.size(),inventory.items.size()):
						var a: Dictionary = inspected.agora.vendors[i]; var b: Dictionary = inventory.items[i]
						equal = equal and int(a.stock)==int(b.count) and int(a.capacity)==int(b.capacity) and bool(a.present)==bool(b.present)
					check(equal,lang+" peddler quantities, capacities and missing vendors match the existing Agora inspector")
		check(seen.has("agora") and seen.has("cargo"),lang+" real peddler and goods-carrying roles are covered")
		check(core.command("character_inventory 999999999").has("error"),lang+" expired/unknown walkers reject inventory access")
		var after: Dictionary = core.snapshot(true)
		before.erase("sequence"); after.erase("sequence")
		check(before==after,lang+" inventory queries do not change any native snapshot field")
		var out := FileAccess.open("/private/tmp/character-inventory-%s.json"%lang,FileAccess.WRITE)
		out.store_string(JSON.stringify(records)); out.close()
	core.close_city()
	print("CHARACTER_INVENTORY_VALIDATION ","PASS " if okay else "FAIL ","checks=",checks)
	quit(0 if okay else 1)
