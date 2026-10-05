extends SceneTree
# Real template previews vs opened campaign goals in both languages. Scratch paths, no player saves.
var checks := 0
var okay := true
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("ADVENTURE_CARD_CHECK ", "PASS " if value else "FAIL ", description)
func run() -> void:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var art = load("res://scripts/adventure_art.gd").new()
	var count := 0
	var sandboxes: Array = []
	for language in ["en", "ru"]:
		var listing: Array = core.adventures(engine, language).get("adventures", [])
		check(listing.size() >= 26, "native %s catalog includes campaigns and maps" % language)
		for item in listing:
			var preview: Dictionary = core.adventure_preview(engine, item.kind, item.ref, language)
			check(not preview.has("error") and preview.episode.episode_number == 1 and not preview.episode.colony, "%s: first parent episode template (%s)" % [item.title, language])
			if preview.has("error"):
				continue
			check(core.snapshot().has("error") and core.command("episode").has("error"), "preview releases the core without entering a city")
			var picture: Texture2D = art.texture(engine, int(item.bitmap))
			check(picture != null and picture.get_width() <= 960, "correct native artwork ID %d loads within budget" % int(item.bitmap))
			var state: Dictionary = core.open_adventure(engine, item.kind, item.ref, language)
			var live: Dictionary = core.command("preview_episode")
			if live.goals.map(func(g): return g.text) != preview.episode.goals.map(func(g): return g.text):
				print("ADVENTURE_GOAL_DIFFERENCE ",item.title," preview=",JSON.stringify(preview.episode.goals)," live=",JSON.stringify(live.goals))
			check(not state.has("error") and live.goals.map(func(g): return g.text) == preview.episode.goals.map(func(g): return g.text) and live.episode_count == preview.episode.episode_count, "preview goals match the native new game's briefing exactly")
			if count == 0:
				var digest: Dictionary = core.replay(0, 241)
				var reader: RefCounted = ClassDB.instantiate("EZeusSimulation")
				check(reader.adventure_preview(engine, item.kind, item.ref, language).get("error") == "simulation_already_owned" and core.replay(0, 241).digest == digest.digest, "preview refuses an owned city and preserves its native state")
			core.close_city()
			if bool(preview.sandbox) and language == "en":
				sandboxes.append(item.title)
			count += 1
		check(core.adventure_preview(engine, "pak", "/etc/passwd", language).has("error") and core.adventure_preview(engine, "folder", "../Save", language).has("error") and core.adventure_preview(engine, "invalid", "x", language).has("error"), "unlisted paths and kinds refused (%s)" % language)
	check(sandboxes.has("Open Play Sandbox") and sandboxes.has("Open Play Sandbox 2"), "native objective-free maps are marked sandbox: %s" % str(sandboxes))
	for id in 18:
		check(art.texture(engine, id) != null, "artwork mapping %d includes packed Poseidon illustrations" % id)
	print("ADVENTURE_CARD_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks, " previews=", count)
	quit(0 if okay else 1)
