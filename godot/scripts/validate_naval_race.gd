extends SceneTree
# The navy, the races and the walkers that had no model (headless, in memory; the designated save is never written): every walker
# of the city has a model; the trireme wharf's inspector has the SDL page's lines and switch, and the switch shuts it down and sets it
# working; a trireme launched there is selectable and sails where it is sent (`trireme_move`); a closed hippodrome of four corner
# plates is inspected with the SDL page's lines and, with its horses, races: its chariots run the track in the walkers' list.
const NONE := Vector2i(99999, 99999)
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("NAVAL_RACE_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func open(core: RefCounted, lang: String) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), lang)
	core.enable_test_commands()
	return opened

func spot(core: RefCounted, state: Dictionary, tool: String, orientation := 0, buildable_only := true) -> Vector2i:
	for tile in state.tiles:
		if buildable_only and (not int(tile[5]) or int(tile[4])):
			continue
		if core.command("preview %s %d %d %d" % [tool, int(tile[0]), int(tile[1]), orientation]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return NONE

func walkers_with(state: Dictionary, prefix: String) -> Array:
	return state.walkers.filter(func(w): return str(w.asset).begins_with(prefix))

# A plate whose model is `asset`, on the 4x4 square at `at`: the turn picks among the plates that fit.
func plate(core: RefCounted, at: Vector2i, asset: String) -> bool:
	for turn in 8:
		var preview: Dictionary = core.command("preview hippodrome %d %d %d" % [at.x, at.y, turn])
		if preview.get("valid", false) and preview.asset == asset:
			return not core.command("build hippodrome %d %d %d" % [at.x, at.y, turn]).has("error")
	return false

func run() -> void:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	for lang in ["en", "ru"]:
		check(open(core, lang).has("protocol"), lang + " designated test city loads")
		var state: Dictionary = core.snapshot(true)
		var missing: Array = state.walkers.filter(func(w): return str(w.asset) == "unconverted" or not (ResourceLoader.exists("res://assets/models/%s.glb" % w.asset) or str(w.asset) == "sacrifice_goods"))
		check(missing.is_empty(), lang + " every walker in the city has a model %s" % str(missing.map(func(w): return w.asset).slice(0, 5)))
		for asset in ["trireme", "enemy_boat", "walker_greekchariot", "walker_racechariot0", "walker_racechariot1", "walker_racechariot2", "walker_racechariot3", "walker_silverminer", "walker_orichalcminer"]:
			check(ResourceLoader.exists("res://assets/models/%s.glb" % asset), lang + " model " + asset + " exists")

		# The trireme wharf: its SDL lines and switch, then a trireme that takes orders.
		var wharf_at := spot(core, state, "trireme_wharf", 0, false)
		check(wharf_at != NONE, lang + " a shore site for a trireme wharf")
		if wharf_at != NONE:
			var built: Dictionary = core.command("build trireme_wharf %d %d 0" % [wharf_at.x, wharf_at.y])
			check(not built.has("error"), lang + " the trireme wharf is built")
			var info: Dictionary = core.command("inspect %d %d" % [wharf_at.x + 1, wharf_at.y + 1])
			check(info.get("notes", []).size() >= 1 and info.has("switch") and info.switch.labels.size() == 2 and bool(info.switch.working),
				lang + " the wharf's inspector has the SDL page's lines and its switch: %s" % " / ".join(PackedStringArray(info.get("notes", []))))
			var off: Dictionary = core.command("building_switch %d %d %d 0" % [wharf_at.x + 1, wharf_at.y + 1, int(info.target_token)])
			check(not off.has("error") and not bool(off.switch.working) and bool(off.shut_down), lang + " the switch shuts the wharf down")
			var on: Dictionary = core.command("building_switch %d %d %d 1" % [wharf_at.x + 1, wharf_at.y + 1, int(info.target_token)])
			check(bool(on.switch.working) and not bool(on.shut_down), lang + " and sets it working again")
			check(core.command("building_switch %d %d %d 1" % [wharf_at.x + 1, wharf_at.y + 1, int(info.target_token) + 7]).has("error"), lang + " a stale token is refused")
			check(core.command("building_switch %d %d 0 1" % [wharf_at.x + 40, wharf_at.y + 40]).has("error"), lang + " a building without the switch is refused")
			# Its crew: the military first, as the SDL allocation window allows.
			core.command("set_priority 7 5")
			core.replay(200, 7)
			var launched: Dictionary = core.command("test_trireme %d %d" % [wharf_at.x + 1, wharf_at.y + 1])
			var triremes: Array = walkers_with(launched, "trireme") if launched.has("walkers") else []
			check(triremes.size() >= 1, lang + " the wharf launches a trireme (%s)" % launched.get("error", "%d" % triremes.size()))
			if triremes.size() >= 1:
				var ship: Dictionary = triremes[0]
				check(bool(ship.get("selectable", false)), lang + " the trireme may be given orders")
				# Water some way off, in the city.
				var target := NONE
				for tile in state.tiles:
					var at := Vector2i(int(tile[0]), int(tile[1]))
					if int(tile[3]) & 4 and not int(tile[4]) and Vector2(at).distance_to(Vector2(float(ship.x), float(ship.y))) > 6.0 and Vector2(at).distance_to(Vector2(float(ship.x), float(ship.y))) < 14.0:
						target = at
						break
				check(target != NONE, lang + " water to send the trireme to")
				if target != NONE:
					var start := Vector2(float(ship.x), float(ship.y))
					var sent: Dictionary = core.command("trireme_move %d %d %d" % [target.x, target.y, int(ship.id)])
					check(not sent.has("error"), lang + " the trireme takes the order (%s)" % sent.get("error", "ok"))
					core.replay(120, 7)
					var after: Array = walkers_with(core.snapshot(false), "trireme").filter(func(w): return int(w.id) == int(ship.id))
					var moved: float = Vector2(float(after[0].x), float(after[0].y)).distance_to(start) if after.size() == 1 else 0.0
					var closer: bool = after.size() == 1 and Vector2(float(after[0].x), float(after[0].y)).distance_to(Vector2(target)) < start.distance_to(Vector2(target))
					check(moved > 1.0 and closer, lang + " and sails toward the water it was sent to (%.1f tiles)" % moved)
				check(core.command("trireme_move 0 0 999999").has("error") and core.command("trireme_move 1 2").has("error"), lang + " an order for no trireme is refused")

		# The hippodrome: four corner plates make a closed track; with its horses its chariots race.
		core.command("test_allow hippodrome")
		state = core.snapshot(true)
		var square := NONE
		for tile in state.tiles:
			var at := Vector2i(int(tile[0]), int(tile[1]))
			if not int(tile[5]) or int(tile[4]):
				continue
			var fits := true
			for corner in [Vector2i(0, 0), Vector2i(4, 0), Vector2i(4, 4), Vector2i(0, 4)]:
				fits = fits and core.command("preview hippodrome %d %d 0" % [at.x + corner.x, at.y + corner.y]).get("valid", false)
			if fits:
				square = at
				break
		check(square != NONE, lang + " an 8x8 site for a hippodrome")
		if square != NONE:
			var laid := plate(core, square, "hippodrome_7") and plate(core, square + Vector2i(4, 0), "hippodrome_1") and plate(core, square + Vector2i(4, 4), "hippodrome_3") and plate(core, square + Vector2i(0, 4), "hippodrome_5")
			check(laid, lang + " the four corner plates are laid (7, 1, 3, 5)")
			core.replay(4, 7)
			var info: Dictionary = core.command("inspect %d %d" % [square.x + 1, square.y + 1])
			check(info.has("hippodrome") and bool(info.hippodrome.closed) and int(info.hippodrome.length) == 4 and int(info.hippodrome.needed) == 4,
				lang + " the track is closed, four plates long and needs four horses (%s)" % str(info.get("hippodrome", {})))
			check(not str(info.get("notes_title", "")).is_empty() and info.get("notes", []).size() >= 2, lang + " the inspector has the SDL hippodrome page: %s" % " / ".join(PackedStringArray(info.get("notes", []))))
			if lang == "ru":
				check(str(info.get("notes_title", "")).unicode_at(0) >= 0x400, "ru the hippodrome page is in Russian")
			var racing: Dictionary = core.command("test_race")
			var chariots: Array = walkers_with(racing, "walker_racechariot") if racing.has("walkers") else []
			var on_track: bool = chariots.all(func(w): return float(w.x) >= square.x - .5 and float(w.x) <= square.x + 8.5 and float(w.y) >= square.y - .5 and float(w.y) <= square.y + 8.5)
			check(chariots.size() >= 1 and on_track, lang + " the race starts: %d chariots on the track (%s)" % [chariots.size(), racing.get("error", "")])
			check(chariots.map(func(w): return str(w.asset)).all(func(a): return ResourceLoader.exists("res://assets/models/%s.glb" % a)), lang + " each in its team's colours")
			if chariots.size() >= 1:
				var first: Dictionary = chariots[0]
				core.replay(20, 7)
				var later: Array = walkers_with(core.snapshot(false), "walker_racechariot").filter(func(w): return int(w.id) == int(first.id))
				check(later.size() == 1 and Vector2(float(later[0].x), float(later[0].y)).distance_to(Vector2(float(first.x), float(first.y))) > .3, lang + " the chariots run the track")
				check(bool(core.command("inspect %d %d" % [square.x + 1, square.y + 1]).hippodrome.racing), lang + " the inspector says a race is on")
		core.close_city()
	print("NAVAL_RACE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
