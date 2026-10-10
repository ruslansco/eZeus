extends SceneTree
# Sound (headless, silent): the original game's files load in Godot, the core hands over the sounds its native rules ask
# for (as file names, never touching the simulation's random numbers), and the audio manager routes, limits and remembers
# them. Nothing is played aloud: headless runs have the manager switched off and only its log is read.
const Overlays = preload("res://scripts/overlays.gd")
var okay := true
var checks := 0
var audio: Node

func check(value: bool, description: String) -> void:
	checks += 1
	print("AUDIO_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func collect(path: String, extension: String, out: Array) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension().to_lower() == extension:
			out.append(path.path_join(file))
	for folder in DirAccess.get_directories_at(path):
		collect(path.path_join(folder), extension, out)

func open(core: RefCounted) -> Dictionary:
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	return core.open_city(engine, engine.path_join("Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"), "en")

func run() -> void:
	var scratch := ProjectSettings.globalize_path("res://captures/validation-audio-%d.cfg" % Time.get_ticks_usec())
	Engine.set_meta("ezeus_settings_path", scratch)
	audio = root.get_node_or_null("GameAudio")
	check(audio != null, "the GameAudio autoload exists")
	if audio == null:
		quit(1)
		return
	check(not audio.enabled, "headless runs are silent")
	# Exercise retained recordings explicitly; the original score is reviewed by
	# validate_city_clarity.gd alongside the new soundscape preference.
	audio.set_original_soundscape(false)
	check(audio.workspace.ends_with("Zeus & Poseidon") and DirAccess.dir_exists_absolute(audio.workspace.path_join("Audio")), "the manager finds the game's Audio folder")

	# The original files load.
	var wavs: Array = []
	collect(audio.workspace.path_join("Audio/Wavs"), "wav", wavs)
	collect(audio.workspace.path_join("Audio/Ambient"), "wav", wavs)
	var unreadable: Array = []
	for path in wavs:
		var stream: AudioStream = audio.load_stream(path)
		if stream == null or stream.get_length() <= 0.0:
			unreadable.append(path.get_file())
	check(wavs.size() >= 700 and unreadable.is_empty(), "all %d sound effects and ambient sounds load %s" % [wavs.size(), str(unreadable.slice(0, 5))])
	check(audio.general_tracks.size() >= 12, "the music list comes from Music.txt (%d tracks)" % audio.general_tracks.size())
	var music_bad: Array = []
	for track in audio.general_tracks + ["Audio/Music/Setup.mp3", "Audio/Music/Battle1.mp3", "Audio/Music/Battle_long.mp3"]:
		var stream: AudioStream = audio.load_stream(track)
		if stream == null or stream.get_length() < 10.0:
			music_bad.append(track)
	check(music_bad.is_empty(), "the menu, city and battle tracks load %s" % str(music_bad))
	for cue in ["mission_intro", "mission_victory", "campaign_victory"]:
		check(audio.load_stream("Audio/Music/%s.wav" % cue) != null, "the %s cue loads" % cue)
	check(audio.load_stream("Audio/Wavs/button.wav") != null, "the button click loads")

	# Voices follow the language.
	TranslationServer.set_locale("en")
	var english: String = audio.resolve("Audio/Voice/Campaign/C1_E2_i.mp3")
	TranslationServer.set_locale("ru")
	var russian: String = audio.resolve("Audio/Voice/Campaign/C1_E2_i.mp3")
	TranslationServer.set_locale("en")
	check(english.contains("Voice_en") and russian.contains("Voice_ru") and FileAccess.file_exists(russian), "voice lines resolve to the language folder")
	check(audio.resolve("Audio/Voice/nonsense/none.mp3").is_empty(), "a voice line that exists in no language resolves to nothing")

	# The core: the sounds of places, buildings and construction.
	var core: RefCounted = ClassDB.instantiate("EZeusSimulation")
	var first := open(core)
	check(first.has("sounds") and first.sounds.is_empty() and first.music == "city", "a snapshot carries `sounds` (none yet) and the music mode")
	var focus: Array = first.focus
	var heard := {}
	var missing: Array = []
	for i in 400:
		var answer: Dictionary = core.command("ambient %d %d" % [int(focus[0]) + randi_range(-40, 40), int(focus[1]) + randi_range(-40, 40)])
		for path in answer.get("sounds", []):
			heard[path] = true
			if audio.load_stream(path) == null:
				missing.append(path)
	check(heard.size() >= 20 and missing.is_empty(), "ambient queries bring %d different sounds and every file exists %s" % [heard.size(), str(missing.slice(0, 3))])
	var layer1 := 0
	var layer2 := 0
	for path in heard:
		layer1 += 1 if path.begins_with("Audio/Ambient/Layer1/") else 0
		layer2 += 1 if path.begins_with("Audio/Ambient/Layer2/") else 0
	check(layer1 > 0 and layer2 > 0, "both ambient layers are used (%d wind and bells, %d places)" % [layer1, layer2])
	var granary := {}
	var house := {}
	for b in first.buildings:
		if b.asset == "granary" and granary.is_empty():
			granary = b
		if str(b.asset).begins_with("common_house") and house.is_empty():
			house = b
	var storage: Dictionary = core.command("building_sound %d %d" % [granary.x, granary.y])
	var housing: Dictionary = core.command("building_sound %d %d" % [house.x, house.y])
	check(storage.sounds.size() == 1 and housing.sounds.size() == 1 and storage.sounds[0] != "" and audio.load_stream(storage.sounds[0]) != null, "clicking a building answers with that kind of building's sound")
	check(core.command("building_sound 99999 99999").has("error") and core.command("ambient x").has("error"), "bad sound requests are refused")
	# Construction: every building but a road answers with the place sound.
	var road_spot := Vector2i(99999, 99999)
	var house_spot := Vector2i(99999, 99999)
	for tile in first.tiles:
		if road_spot.x == 99999 and core.command("preview road %d %d 0" % [tile[0], tile[1]]).get("valid", false):
			road_spot = Vector2i(int(tile[0]), int(tile[1]))
		if house_spot.x == 99999 and not int(tile[4]) and core.command("preview fountain %d %d 0" % [tile[0], tile[1]]).get("valid", false):
			house_spot = Vector2i(int(tile[0]), int(tile[1]))
		if road_spot.x != 99999 and house_spot.x != 99999:
			break
	var road_built: Dictionary = core.command("build road %d %d 0" % [road_spot.x, road_spot.y])
	check(road_built.sounds.is_empty(), "a road is built in silence")
	var fountain_built: Dictionary = core.command("build fountain %d %d 0" % [house_spot.x, house_spot.y])
	check(fountain_built.sounds.size() == 1 and audio.load_stream(fountain_built.sounds[0]) != null, "a building is placed with the place sound (%s)" % str(fountain_built.sounds))
	check(core.snapshot(false).sounds.is_empty(), "sounds are handed over once")
	# The simulation's own random numbers are untouched by sounds.
	core.close_city()
	open(core)
	var plain: Dictionary = core.replay(300, 7)
	core.close_city()
	open(core)
	for i in 200:
		core.command("ambient %d %d" % [int(focus[0]) + randi_range(-30, 30), int(focus[1]) + randi_range(-30, 30)])
		if i % 10 == 0:
			core.command("building_sound %d %d" % [granary.x, granary.y])
	var asked: Dictionary = core.replay(300, 7)
	check(plain.digest == asked.digest, "asking for ambient and building sounds leaves the replay digest unchanged (%s)" % plain.digest)
	core.close_city()

	# New game: the campaign's introduction voice.
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	var voiced := 0
	var checked := 0
	for item in core.adventures(engine, "en").adventures:
		var state: Dictionary = core.open_adventure(engine, item.kind, item.ref, "en")
		var episode: Dictionary = core.command("episode")
		checked += 1
		if not str(episode.get("voice", "")).is_empty():
			voiced += 1 if audio.load_stream(episode.voice) != null else 0
		core.close_city()
	check(checked >= 24 and voiced >= 5, "adventures name their recorded introductions and the files exist (%d of %d)" % [voiced, checked])

	# The manager: routing, limiting, music and settings (silent).
	audio.log.clear()
	audio.last_played.clear()
	audio.play_native(["Audio/Wavs/fire.wav", "Audio/Wavs/fire.wav", "Audio/Ambient/Layer1/wind1.wav", "Audio/Voice/Walker/Zeus_ev_1.mp3"])
	var buses := {}
	for entry in audio.log:
		buses[entry.path.get_file()] = entry.bus
	check(buses.get("fire.wav", "") == "Effects" and buses.get("wind1.wav", "") == "Ambient" and audio.log.size() >= 2, "native sounds are routed to the Effects and Ambient buses and repeats in a burst are dropped (%s)" % str(buses))
	audio.log.clear()
	audio.last_played.clear()
	audio.play_effect("Audio/Wavs/button.wav")
	var again: bool = audio.play_effect("Audio/Wavs/button.wav")
	check(not again and audio.log.size() == 1, "the same file is not repeated within a moment")
	var button := Button.new()
	root.add_child(button)
	audio.last_played.clear()
	audio.log.clear()
	button.pressed.emit()
	check(audio.log.size() == 1 and audio.log[0].path.ends_with("button.wav"), "every button clicks")
	button.queue_free()
	audio.music_kind = ""
	audio.log.clear()
	audio.play_music("menu")
	check(audio.music_kind == "menu" and audio.log[0].path == "Audio/Music/Setup.mp3", "the menu plays its title tune")
	audio.play_music("city")
	var first_track: String = audio.music_track
	audio.music_kind = ""
	audio.play_music("city")
	check(first_track in audio.general_tracks and audio.music_track in audio.general_tracks and audio.music_track != first_track, "city music picks from the list and does not repeat a track at once")
	audio.play_music("battle")
	check(audio.music_kind == "battle" and audio.music_track.contains("Battle"), "battle music follows the core's request")
	audio.play_cue("mission_victory")
	check(audio.music_kind == "cue:mission_victory", "a victory cue replaces the music")
	audio.set_volume("Music", .5)
	audio.set_master_volume(.8)
	audio.set_muted(true)
	var music_bus := AudioServer.get_bus_index("Music")
	check(absf(AudioServer.get_bus_volume_db(music_bus) - linear_to_db(.5)) < .01 and AudioServer.is_bus_mute(0), "volumes and the mute switch drive the buses")
	check(absf(audio.volume("Music") - .5) < .001 and audio.muted() and FileAccess.file_exists(scratch), "they are remembered per user (in a scratch file here)")
	audio.set_muted(false)
	audio.set_volume("Music", .7)
	audio.set_master_volume(.9)
	DirAccess.remove_absolute(scratch)
	print("AUDIO_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
