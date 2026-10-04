extends SceneTree
# Seeded replay of the embedded core (headless, read-only).
#
# Opens the designated city, replays the shared simulation order for N ticks from a fixed seed and prints
# the gameplay-state digest. Run alone it checks that the embedded core is reproducible: the same seed gives
# the same digest in repeated sessions, a different seed gives a different one, and no random number is
# drawn from a worker thread. tools/replay_parity.py runs it with --ticks/--seed and compares the digest
# with the native SDL executable's EZEUS_REPLAY output.
#   --ticks=N   ticks per replay (default 200)       --seed=S   seed (default 7)
#   --print     only print "REPLAY_DIGEST <digest>" for the parity script, no checks
var okay := true

func check(value: bool, description: String) -> void:
	print("REPLAY_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func argument(name: String, fallback: int) -> int:
	for item in OS.get_cmdline_user_args():
		if item.begins_with("--%s=" % name):
			return int(item.get_slice("=", 1))
	return fallback

func replay(ticks: int, seed: int) -> Dictionary:
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var opened: Dictionary = core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")
	if opened.has("error"):
		print("REPLAY_OPEN_FAILED ", opened)
		return {}
	var result: Dictionary = core.replay(ticks, seed)
	core.close_city()
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var ticks := argument("ticks", 200)
	var seed := argument("seed", 7)
	if "--print" in OS.get_cmdline_user_args():
		var once := replay(ticks, seed)
		print("REPLAY_DIGEST ", once.get("digest", "none"), " sections=[", once.get("sections", ""), "] off_thread_draws=", once.get("off_thread_draws", -1))
		quit(0 if once.has("digest") else 1)
		return
	var first := replay(ticks, seed)
	var second := replay(ticks, seed)
	var other := replay(ticks, seed + 1)
	print("REPLAY_INFO ticks=", ticks, " seed=", seed, " digest=", first.get("digest", "none"), " sections=[", first.get("sections", ""), "]")
	check(first.has("digest") and second.has("digest"), "the designated city opens and replays")
	check(first.get("digest", "a") == second.get("digest", "b"), "the same seed reproduces the same gameplay state (%s)" % first.get("digest", ""))
	check(first.get("digest", "a") != other.get("digest", "a"), "a different seed gives a different state (the check is sensitive)")
	check(int(first.get("off_thread_draws", -1)) == 0 and int(second.get("off_thread_draws", -1)) == 0, "no random number is drawn from a worker thread")
	print("REPLAY_VALIDATION ", "PASS" if okay else "FAIL", " ticks=", ticks)
	quit(0 if okay else 1)
