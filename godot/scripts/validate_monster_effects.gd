extends SceneTree

const Effects = preload("res://scripts/monster_effects.gd")
const Fixture = preload("res://scripts/monster_effects_fixture.gd")
var checks := 0
var okay := true

class Surface:
	extends RefCounted
	func world_position(x: float, y: float, h: float) -> Vector3:
		return Vector3(x, h * .22, -y)
	func terrain_height_world(_x: float, _z: float) -> float:
		return .4
	func walker_world_position(w: Dictionary) -> Vector3:
		return world_position(float(w.x) - .5, float(w.y) - .5, float(w.altitude))

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	okay = okay and value
	print("MONSTER_FX_CHECK ", "PASS " if value else "FAIL ", message)

func run() -> void:
	var surface := Surface.new()
	var fx: Effects = Effects.new()
	root.add_child(fx)
	check(Effects.MONSTERS.size() == 17, "all native monster profiles have the shared effect")
	check(Effects.tint_for("walker_hydra") != Effects.tint_for("walker_cerberus"), "Hydra has its own venom finish")
	var event := {"event": 1, "id": 1, "phase": "launch", "asset": "walker_hydra", "time": 100.0, "age": 0, "speed": 1, "start": [0, 0, 0], "target": [4, 0, 0], "footprint": [3, 0, 3, 3], "water": false, "destroyed": false}
	var snapshot := {"time": 100.0, "running": false, "monster_effects": [event]}
	fx.receive(snapshot, surface)
	check(fx.launches == 1 and fx.shots.size() == 1 and fx.puff_count > 0, "native launch creates visible breath and a projectile")
	check(fx.shots[1].start.y > .4 and fx.shots[1].target.y > .4, "effect follows the presented ground")
	fx.receive(snapshot, surface)
	check(fx.launches == 1, "a repeated snapshot cannot replay an attack")
	var transforms := fx.puffs.get_instance_transform(0)
	fx.advance(5.0)
	check(fx.clock == 100 and fx.puffs.get_instance_transform(0) == transforms, "paused effects freeze completely")
	fx.receive({"time": 140.0, "running": true}, surface)
	fx.advance(.05)
	check(is_equal_approx(fx.clock, 120.0), "effects interpolate native time")
	fx.receive({"time": 180.0, "running": true, "blocked": true}, surface)
	fx.advance(5.0)
	check(fx.clock == 180 and not fx.running, "a required decision freezes the effects")
	event = event.duplicate(true)
	event.event = 2; event.phase = "impact"; event.time = 180.0
	fx.receive({"time": 180.0, "running": false, "monster_effects": [event]}, surface)
	check(fx.impacts == 1 and fx.shots.is_empty() and fx.collapses == 0, "impact removes the projectile without inventing a collapse")
	event.event = 3; event.destroyed = true
	fx.receive({"time": 210.0, "running": false, "monster_effects": [event]}, surface)
	check(fx.collapses == 1 and fx.debris_count > 0, "native destruction creates dust and stone debris")
	fx.receive({"time": 1000.0, "running": false}, surface)
	check(fx.bursts.is_empty() and fx.puff_count == 0 and fx.debris_count == 0, "all transient geometry expires")
	event.event = 4; event.id = 2; event.phase = "launch"; event.time = 1000.0
	fx.receive({"time": 1000.0, "running": false, "monster_effects": [event]}, surface)
	event = event.duplicate(true); event.event = 5; event.phase = "cancel"
	var before := fx.impacts
	fx.receive({"time": 1000.0, "running": false, "monster_effects": [event]}, surface)
	check(fx.shots.is_empty() and fx.impacts == before, "cancelled attacks produce no impact or damage effect")
	for i in 300:
		fx.burst("collapse", Vector3.ZERO, Vector3.UP, Color.WHITE, 1000, 330, float(i))
	fx.advance(.01)
	check(fx.bursts.size() == Effects.MAX_BURSTS and fx.puff_count <= Effects.MAX_PUFFS and fx.debris_count <= Effects.MAX_DEBRIS, "burst and geometry budgets remain bounded")
	check(fx.get_child_count() == 2, "effects use only two shared draw batches")
	fx.receive({"time": 1000.0, "sequence": 20, "running": false}, surface)
	event.event = 1; event.id = 1; event.phase = "launch"; event.destroyed = false
	fx.receive({"time": 1000.0, "sequence": 1, "running": false, "monster_effects": [event]}, surface)
	check(fx.launches == 1 and fx.collapses == 0 and fx.bursts.size() == 1, "city reload clears prior effects and accepts restarted native event IDs")
	fx.queue_free()
	await process_frame
	if "--unit-only" in OS.get_cmdline_user_args():
		print("MONSTER_FX_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
		quit(0 if okay else 1)
		return
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var save := engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez")
	for language in ["en", "ru"]:
		var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
		var initial: Dictionary = core.open_city(engine, save, language)
		check(initial.has("protocol"), "designated city loads in " + language)
		check(core.command("test_monster_strike 1 0 0 1 1").get("error", "") == "unsupported_command", "strike fixture is unavailable in ordinary play " + language)
		core.enable_test_commands()
		var fixture := Fixture.prepare(core)
		check(not fixture.has("error"), "native Hydra attack prepared " + language + " " + str(fixture.get("error", "")))
		if fixture.has("error"):
			core.close_city(); continue
		var digest: Dictionary = core.replay(0)
		core.snapshot(true)
		check(core.replay(0).digest == digest.digest, "effect observation does not mutate native state " + language)
		core.command("speed 3"); core.command("pause 0")
		var events: Array = []
		var paired_batch := false
		var seen := {}
		for step in 80:
			core.advance(.2)
			var state: Dictionary = core.snapshot(false)
			var batch: Array = state.get("monster_effects", [])
			paired_batch = paired_batch or (batch.any(func(e): return e.phase == "launch") and batch.any(func(e): return e.phase == "impact"))
			for e in batch:
				if e.asset == "walker_hydra":
					events.append(e)
					check(not seen.has(int(e.event)), "native event delivered once " + language)
					seen[int(e.event)] = true
			if events.any(func(e): return bool(e.destroyed)):
				break
			if state.get("blocked", false):
				break
		core.command("pause 1")
		check(events.any(func(e): return e.phase == "launch") and events.any(func(e): return e.phase == "impact"), "real native launch and impact observed " + language)
		check(paired_batch, "short flight survives an entire launch/impact between snapshots " + language)
		check(events.any(func(e): return bool(e.destroyed)), "actual native building collapse is identified " + language)
		check(core.snapshot(true).get("monster_effects", []).is_empty(), "consumed effects are not replayed by full refresh " + language)
		var native_before: float = core.snapshot(false).time
		core.advance(.25)
		check(core.snapshot(false).time == native_before, "pause retains native time " + language)
		core.close_city()
	# Exercise every character-to-monster mapping through actual native missiles.
	# Sea creatures are moved to the disposable attack fixture only for transport
	# coverage; this is not a sea navigation or species-specific art review.
	for asset in Effects.MONSTERS:
		if asset == "walker_hydra":
			continue
		var kind: String = asset.trim_prefix("walker_")
		if kind == "calydonianboar":
			kind = "calydonian_boar"
		var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
		core.open_city(engine, save, "en")
		core.enable_test_commands()
		var fixture := Fixture.prepare(core, kind)
		check(not fixture.has("error"), "shared attack fixture prepared " + kind)
		if not fixture.has("error"):
			core.command("speed 3"); core.command("pause 0")
			var events: Array = []
			for step in 20:
				core.advance(.2)
				var state: Dictionary = core.snapshot(false)
				events.append_array(state.get("monster_effects", []).filter(func(e): return e.asset == asset))
				if events.any(func(e): return e.phase == "impact") or state.get("blocked", false):
					break
			check(events.any(func(e): return e.phase == "launch") and events.any(func(e): return e.phase == "impact"), "shared native launch/impact observed " + kind)
		core.close_city()
	print("MONSTER_FX_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
