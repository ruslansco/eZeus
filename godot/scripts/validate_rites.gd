extends SceneTree
# The rite on a sanctuary's altar (headless, in memory, scratch saves only). The engine's altar sacrifices a sheep, a bull or goods now and then; the
# core shows each rite as walker records with a `scene` (a priestess and the animal or the goods) once the sanctuary is finished, a validators-only
# command begins one, and the presentation (scripts/altar_rite.gd) puts each part around the altar's centre and burns the braziers higher while it lasts.
# The priestess has a model with the stab (fight), the offering (fight2) and a fall (die) baked.
const AltarRite = preload("res://scripts/altar_rite.gd")
var okay := true
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	print("RITE_CHECK ", "PASS " if value else "FAIL ", message)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func scene_walkers(state: Dictionary) -> Array:
	return state.walkers.filter(func(w): return w.has("scene"))

func part(state: Dictionary, role: String) -> Dictionary:
	for walker in state.walkers:
		if str(walker.get("role", "")) == role:
			return walker
	return {}

func altars_of(state: Dictionary) -> Array:
	return state.buildings.filter(func(b): return str(b.asset) == "sanctuary_altar")

# A flame's `burn` level (0 until it was ever set).
func burn_of(tuft: MeshInstance3D) -> float:
	var value: Variant = tuft.get_instance_shader_parameter("burn")
	return 0.0 if value == null else float(value)

func site_for(core: RefCounted, state: Dictionary, tool: String) -> Vector2i:
	for tile in state.tiles:
		if not int(tile[5]) or int(tile[4]):
			continue
		if core.command("preview %s %d %d 0" % [tool, int(tile[0]), int(tile[1])]).get("valid", false):
			return Vector2i(int(tile[0]), int(tile[1]))
	return Vector2i(99999, 99999)

func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var designated := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	var designated_hash := FileAccess.get_sha256(designated)

	# ------------------------------------------------------------------------------------------ the model
	var sidecar := "res://assets/models/runtime/walker_priestess.vat.json"
	check(FileAccess.file_exists("res://assets/models/walker_priestess.glb") and FileAccess.file_exists(sidecar), "the priestess has a model and its baked poses")
	var frames: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sidecar)).parts.values()[0].frames
	check(frames.has("fight_23") and not frames.has("fight_24") and frames.has("fight2_11") and frames.has("die_00") and frames.has("walk_01"), "she has the stab (24 frames), the offering (12) and a fall baked")

	# ------------------------------------------------------------------------------------ the core: a finished sanctuary
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var initial: Dictionary = core.open_city(engine, designated, "en")
	check(initial.has("protocol"), "the designated test city loads paused")
	var first: Dictionary = core.snapshot(true)
	var altars := altars_of(first)
	check(altars.size() >= 2, "the city has altars (%d pieces called sanctuary_altar)" % altars.size())
	var altar: Dictionary = altars[0]
	var refused: Dictionary = core.command("test_sacrifice %d %d sheep" % [int(altar.x), int(altar.y)])
	check(refused.get("error", "") == "unsupported_command", "a rite cannot be begun without the validators' switch")
	core.enable_test_commands()
	# A pyramid's altar is the same model but takes no rite: the core says which pieces are a sanctuary's altar.
	var sanctuary_altar := {}
	for candidate in altars:
		if not core.command("test_sacrifice %d %d goods" % [int(candidate.x), int(candidate.y)]).has("error"):
			sanctuary_altar = candidate
			break
	check(not sanctuary_altar.is_empty(), "a sanctuary's altar takes a rite")
	var temple_tile: Dictionary = first.buildings.filter(func(b): return str(b.asset).begins_with("sanctuary_temple_"))[0]
	check(core.command("test_sacrifice %d %d sheep" % [int(temple_tile.x), int(temple_tile.y)]).get("error", "") == "no_altar", "a tile that is not an altar is refused")
	core.snapshot(false)

	# the goods began above; every kind is seen in turn
	var kinds := {
		"goods": {"victim": "", "offering": "sacrifice_goods", "action": 5},
		"sheep": {"victim": "animal_sheep_fleeced", "offering": "", "action": 4},
		"bull": {"victim": "animal_ox", "offering": "", "action": 4}}
	for kind in ["goods", "sheep", "bull"]:
		if kind != "goods":
			core.command("test_sacrifice %d %d %s" % [int(sanctuary_altar.x), int(sanctuary_altar.y), kind])
		var state: Dictionary = core.snapshot(false)
		var scene := scene_walkers(state)
		var priestess := part(state, "priestess")
		var other := part(state, "victim") if str(kinds[kind].victim) != "" else part(state, "offering")
		check(scene.size() >= 2 and not priestess.is_empty() and not other.is_empty(), "a %s rite shows a priestess and %s (%d scene records)" % [kind, "the animal" if kind != "goods" else "the goods", scene.size()])
		check(str(priestess.asset) == "walker_priestess" and int(priestess.action) == int(kinds[kind].action) and str(priestess.rite) == kind and int(priestess.type) == -1, "%s: the priestess %s (action %s)" % [kind, "stabs" if kind != "goods" else "raises her arms over the goods", str(priestess.get("action"))])
		var expected: String = kinds[kind].victim if str(kinds[kind].victim) != "" else str(kinds[kind].offering)
		check(str(other.asset) == expected, "%s: the other part is %s" % [kind, expected])
		check(is_equal_approx(float(priestess.x), float(sanctuary_altar.x) + float(sanctuary_altar.w) * .5) and is_equal_approx(float(priestess.y), float(sanctuary_altar.y) + float(sanctuary_altar.h) * .5) and int(priestess.size[0]) == 2 and int(priestess.size[1]) == 2, "%s: the scene stands at the altar's centre with its size" % kind)
		var again: Dictionary = core.snapshot(false)
		check(int(part(again, "priestess").id) == int(priestess.id) and int((part(again, "victim") if str(kinds[kind].victim) != "" else part(again, "offering")).id) == int(other.id), "%s: the parts keep their ids from snapshot to snapshot" % kind)
		check(int(priestess.id) != int(other.id), "%s: the two parts have distinct ids" % kind)
		# the scene belongs to the altar the rite is on only
		var elsewhere := scene_walkers(state).filter(func(w): return absf(float(w.x) - float(priestess.x)) > .01 or absf(float(w.y) - float(priestess.y)) > .01)
		check(elsewhere.is_empty(), "%s: no other altar has a scene" % kind)
	var real: Array = core.snapshot(false).walkers.filter(func(w): return not w.has("scene"))
	check(real.size() > 0 and real.all(func(w): return int(w.type) >= 0), "the city's own walkers carry no scene")

	# the rite ends as the engine ends it
	core.command("speed 3")
	core.command("pause 0")
	var started := Time.get_ticks_msec()
	var over := false
	for step in 600:
		if Time.get_ticks_msec() - started > 90000:
			break
		core.advance(.2)
		var running: Dictionary = core.snapshot(false)
		for event in running.get("events", []):
			var choices: Array = event.get("actions", [])
			core.command("event %d %d" % [int(event.id), int(choices[0].choice) if not choices.is_empty() else -1])
		if scene_walkers(running).is_empty():
			over = true
			break
	core.command("pause 1")
	check(over, "the rite ends and its scene leaves the city")
	core.close_city()

	# ------------------------------------------------------------------ a sanctuary that is not finished shows no rite
	core = ClassDB.instantiate("EZeusSimulation")
	var athens := {}
	for item in core.adventures(engine, "en").adventures:
		if str(item.title) == "The Founding of Athens":
			athens = item
	var state: Dictionary = core.open_adventure(engine, str(athens.kind), str(athens.ref), "en")
	core.enable_test_commands()
	core.command("test_allow temple_dionysus")
	var warehouse := site_for(core, state, "warehouse")
	core.command("build warehouse %d %d 0" % [warehouse.x, warehouse.y])
	core.command("test_stock 32768 60")
	state = core.snapshot(true)
	var site := site_for(core, state, "temple_dionysus")
	var plan: Dictionary = core.command("preview temple_dionysus %d %d 0" % [site.x, site.y])
	var altar_piece: Dictionary = plan.pieces.filter(func(p): return str(p.asset) == "sanctuary_altar")[0]
	for dx in [-1, int(plan.w)]:
		var at := Vector2i(int(plan.x) + dx, int(plan.y) + int(plan.h) / 2)
		if core.command("preview road %d %d 0" % [at.x, at.y]).get("valid", false):
			core.command("build road %d %d 0" % [at.x, at.y])
			break
	check(not core.command("build temple_dionysus %d %d 0" % [site.x, site.y]).has("error"), "a sanctuary is founded")
	check(not core.command("test_sacrifice %d %d sheep" % [int(altar_piece.x), int(altar_piece.y)]).has("error"), "its altar foundation takes a rite in the engine")
	check(scene_walkers(core.snapshot(true)).is_empty(), "an altar that is not built shows no rite")
	core.command("test_complete %d %d" % [site.x, site.y])
	core.command("test_sacrifice %d %d bull" % [int(altar_piece.x), int(altar_piece.y)])
	var finished: Dictionary = core.snapshot(true)
	var finished_priestess := part(finished, "priestess")
	check(not finished_priestess.is_empty() and str(part(finished, "victim").get("asset", "")) == "animal_ox", "once the sanctuary is finished the rite is shown")
	core.close_city()

	# ------------------------------------------------------------------------------------ the presentation's placement
	var sample := {"scene": "altar", "size": [2, 2], "role": "priestess", "rite": "sheep"}
	check(AltarRite.offset(sample).is_equal_approx(Vector3(0, 0, -1.12)) and is_equal_approx(AltarRite.lift(sample), AltarRite.STAIR_TOP) and AltarRite.roll(sample) == 0.0, "the priestess stands one tile out on the altar's +y stairs, upright")
	var victim := {"scene": "altar", "size": [2, 2], "role": "victim", "rite": "sheep"}
	check(is_equal_approx(AltarRite.lift(victim), AltarRite.TABLE) and is_equal_approx(AltarRite.roll(victim), deg_to_rad(90.0)) and AltarRite.offset(victim).z > 0.0, "the victim lies on its side on the table, moved back to its middle")
	var node := Node3D.new()
	var bull := {"scene": "altar", "size": [2, 2], "role": "victim", "rite": "bull"}
	AltarRite.dress(node, bull)
	check(node.scale.is_equal_approx(Vector3.ONE * AltarRite.VICTIM_SCALE.bull) and AltarRite.offset(bull).z > AltarRite.offset(victim).z, "a bull is smaller and lies further back than a sheep")
	node.free()
	var goods := AltarRite.goods_node()
	var meshes := goods.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() >= 10 and meshes.all(func(m): return m.mesh != null and m.mesh.get_surface_count() > 0), "the goods are made in code: amphorae, a dish and fruit (%d meshes)" % meshes.size())
	goods.free()

	# ---------------------------------------------------------------------------------------------------- the braziers
	var fires := AltarRite.Fires.new()
	root.add_child(fires)
	var key_a := Vector2i(309, -63)
	var key_b := Vector2i(400, 10)
	fires.refresh([{"id": 1, "transform": Transform3D(Basis.IDENTITY, Vector3(5, 0, 5)), "key": key_a}, {"id": 2, "transform": Transform3D(Basis(Vector3.UP, PI / 2), Vector3(9, 1, 2)), "key": key_b}])
	check(fires.tufts.size() == 2 and fires.tufts[1].size() == 3 and fires.get_child_count() == 6, "each finished altar has three flames, one for each brazier")
	check(fires.tufts[1][0].position.is_equal_approx(Vector3(5, 0, 5) + AltarRite.BRAZIERS[0]), "a flame stands where the model has its brazier")
	check(fires.tufts[2][0].position.is_equal_approx(Vector3(9, 1, 2) + Basis(Vector3.UP, PI / 2) * AltarRite.BRAZIERS[0]), "and follows the altar's turn and height")
	check(burn_of(fires.tufts[1][0]) == 0.0, "the flames rest while no rite is on")
	fires.burn({key_a: true})
	check(burn_of(fires.tufts[1][1]) == 1.0 and burn_of(fires.tufts[2][1]) == 0.0, "an altar with a rite on it burns high, the other does not")
	fires.refresh([{"id": 1, "transform": Transform3D(Basis.IDENTITY, Vector3(5, 0, 5)), "key": key_a}])
	check(fires.tufts.size() == 1 and burn_of(fires.tufts[1][2]) == 1.0, "a demolished altar loses its flames and the rest keep burning")
	fires.burn({})
	check(burn_of(fires.tufts[1][0]) == 0.0, "the flames settle when the rite is over")
	var tuft: MeshInstance3D = fires.tufts[1][0]
	check(tuft.material_override is ShaderMaterial and tuft.mesh.get_surface_count() == 1 and tuft.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "a flame is one shadowless mesh with the flame shader")
	fires.queue_free()
	await process_frame

	check(FileAccess.get_sha256(designated) == designated_hash, "the designated test save is untouched")
	print("RITE_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
