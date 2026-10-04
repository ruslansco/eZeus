extends Node
# The game's sound: music, sound effects, ambient sound and voices, played from the original game's own files in the
# workspace Audio folder (WAV and MP3 read at run time; nothing is copied into the project). Registered as the autoload
# `GameAudio`, so music carries on across the start menu and the city.
#
# What plays is decided elsewhere and arrives here as file names:
#  * the simulation core hands over every sound the native rules ask for (fire, collapse, quarrying, gods and monsters,
#    combat) and chooses battle or peaceful music; main.gd forwards the snapshot's `sounds` and `music`;
#  * the core also picks the sound of a place (`ambient x y`, `building_sound x y`) with the native tables, and this
#    node asks it now and then while nothing else is audible, like the SDL game;
#  * the interface plays its own: button clicks (every BaseButton, found as it enters the tree) and the music cues.
# Automation (validation, captures, headless runs) is silent: `enabled` is off, and tests switch it on with the master
# bus muted to exercise the logic without a sound.

const UserSettings = preload("res://scripts/user_settings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")
const BUSES := ["Music", "Effects", "Ambient", "Voice"]
const POOL := 14
const SAME_SOUND_GAP := .12
const AMBIENT_ODDS := 1.0 / 250.0
const FADE := 1.0
const MENU_TRACK := "Audio/Music/Setup.mp3"
const BATTLE_TRACKS := ["Battle1", "Battle2", "Battle3", "Battle4", "Battle_long", "Battle_long2"]
const AUTOMATION := ["--validate", "--asset-review", "--bridge-port=", "--capture=", "--terrain-review=", "--garden-review=", "--sanctuary-review=", "--pyramid-review=", "--controls-review=", "--objectives-review=",
	"--character-review=", "--silent"]

signal music_changed(kind: String, track: String)

var enabled := true
var workspace := ""
var streams: Dictionary = {}
var pool: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_fading: AudioStreamPlayer
var voice: AudioStreamPlayer
var music_kind := ""
var music_track := ""
var general_tracks: Array = []
# What was asked to play, newest last: [{path, bus, time}]. Tests read it; it keeps the last 64.
var log: Array = []
var last_played: Dictionary = {}
var ambient_age := 0.0
var cue_playing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	workspace = ProjectSettings.globalize_path("res://../..").simplify_path()
	var automated := DisplayServer.get_name() == "headless"
	for argument in OS.get_cmdline_user_args():
		for prefix in AUTOMATION:
			if argument == prefix or (prefix.ends_with("=") and argument.begins_with(prefix)):
				automated = true
	enabled = not automated
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	music = _player("Music")
	music_fading = _player("Music")
	voice = _player("Voice")
	for i in POOL:
		pool.append(_player("Effects"))
	music.finished.connect(_player_finished.bind(music))
	music_fading.finished.connect(_player_finished.bind(music_fading))
	apply_settings()
	get_tree().node_added.connect(_node_added)
	general_tracks = _read_general_tracks()

func _player(bus: String) -> AudioStreamPlayer:
	var item := AudioStreamPlayer.new()
	item.bus = bus
	item.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(item)
	return item

# ---- settings ------------------------------------------------------------------------------------------------
# Volumes are linear 0..1 per bus, remembered per user.
func volume(bus: String) -> float:
	return float(UserSettings.get_value("sound", bus.to_lower(), 1.0 if bus != "Music" else .7))

func set_volume(bus: String, value: float) -> void:
	UserSettings.set_value("sound", bus.to_lower(), clampf(value, 0.0, 1.0))
	apply_settings()

func muted() -> bool:
	return bool(UserSettings.get_value("sound", "muted", false))

func set_muted(value: bool) -> void:
	UserSettings.set_value("sound", "muted", value)
	apply_settings()

func master_volume() -> float:
	return float(UserSettings.get_value("sound", "master", .9))

func set_master_volume(value: float) -> void:
	UserSettings.set_value("sound", "master", clampf(value, 0.0, 1.0))
	apply_settings()

func apply_settings() -> void:
	for bus in ["Master"] + BUSES:
		var index := AudioServer.get_bus_index(bus)
		var linear := master_volume() if bus == "Master" else volume(bus)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, .0001)))
		AudioServer.set_bus_mute(index, linear <= .001 or (bus == "Master" and muted()))

# ---- files ---------------------------------------------------------------------------------------------------
# A path relative to the game folder ("Audio/Wavs/fire.wav"), or absolute. Voices live in a folder per language; ask for
# Audio/Voice/... and the voice language's file is used (the interface language unless the player chose one: Game settings), English when it has none.
func resolve(path: String) -> String:
	if path.is_absolute_path():
		return path
	if path.begins_with("Audio/Voice/"):
		var rest := path.trim_prefix("Audio/Voice/")
		var language := PlaySettings.voice_language()
		for candidate in [language, "en"]:
			var full := workspace.path_join("Audio/Voice_" + candidate).path_join(rest)
			if FileAccess.file_exists(full):
				return full
		return ""
	return workspace.path_join(path)

func load_stream(path: String) -> AudioStream:
	var full := resolve(path)
	if full.is_empty() or not FileAccess.file_exists(full):
		return null
	if streams.has(full):
		return streams[full]
	var stream: AudioStream = null
	if full.get_extension().to_lower() == "mp3":
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(full)
		stream = mp3
	elif full.get_extension().to_lower() == "wav":
		stream = AudioStreamWAV.load_from_file(full)
	# Short sounds are kept; music and voices are read again when needed.
	if stream != null and stream.get_length() < 20.0:
		streams[full] = stream
	return stream

func _record(path: String, bus: String) -> void:
	log.append({"path": path, "bus": bus, "time": Time.get_ticks_msec()})
	if log.size() > 64:
		log.pop_front()

# ---- effects -------------------------------------------------------------------------------------------------
func busy_effects() -> int:
	var count := 0
	for item in pool:
		count += 1 if item.playing else 0
	return count

# Plays a sound file on a bus; returns false when it was skipped (disabled, missing, same sound just played, no free
# voice). The sounds the simulation asks for pile up in bursts, so the same file is not repeated within a moment.
func play_effect(path: String, bus := "Effects", gain_db := 0.0) -> bool:
	var now := Time.get_ticks_msec()
	if path.is_empty():
		return false
	if last_played.has(path) and now - int(last_played[path]) < SAME_SOUND_GAP * 1000.0:
		return false
	var stream := load_stream(path)
	if stream == null:
		return false
	last_played[path] = now
	_record(path, bus)
	if not enabled:
		return true
	for item in pool:
		if not item.playing:
			item.bus = bus
			item.volume_db = gain_db
			item.stream = stream
			item.play()
			return true
	return false

# The sounds of a snapshot or of an ambient/building query.
func play_native(paths: Array) -> void:
	var seen := {}
	for path in paths:
		var name := str(path)
		if seen.has(name):
			continue
		seen[name] = true
		if name.begins_with("Audio/Voice/"):
			play_voice(name)
		elif name.begins_with("Audio/Ambient/"):
			play_effect(name, "Ambient")
		else:
			play_effect(name, "Effects")

func ui_click() -> void:
	play_effect("Audio/Wavs/button.wav", "Effects", -4.0)

func _node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("ui_click"):
		node.set_meta("ui_click", true)
		node.pressed.connect(ui_click)

# ---- voice and cues ------------------------------------------------------------------------------------------
# A recorded voice line (a campaign introduction, a god). Music is lowered while it speaks.
func play_voice(path: String) -> bool:
	var stream := load_stream(path)
	if stream == null:
		return false
	_record(path, "Voice")
	if enabled:
		voice.stream = stream
		voice.play()
	return true

func stop_voice() -> void:
	voice.stop()

# The briefing of an episode: its recorded introduction speaks over a silent screen, or the mission fanfare plays.
func play_briefing(voice_path: String) -> void:
	stop_music(.4)
	if voice_path.is_empty() or not play_voice(voice_path):
		play_cue("mission_intro")

# The result of an episode or of the whole adventure: its recorded closing words, or the victory fanfare.
func play_result(voice_path: String, cue: String) -> void:
	stop_music(.4)
	if voice_path.is_empty() or not play_voice(voice_path):
		play_cue(cue)

# A music cue that replaces the music for its length ("mission_intro", "mission_victory", "campaign_victory").
func play_cue(name: String) -> bool:
	var path := "Audio/Music/%s.mp3" % name
	var stream := load_stream(path)
	if stream == null:
		path = "Audio/Music/%s.wav" % name
		stream = load_stream(path)
	if stream == null:
		return false
	stop_music(.3)
	music_kind = "cue:" + name
	_record(path, "Music")
	if enabled:
		music.stream = stream
		music.volume_db = 0.0
		music.play()
	cue_playing = true
	music_changed.emit(music_kind, name)
	return true

# ---- music ---------------------------------------------------------------------------------------------------
func _read_general_tracks() -> Array:
	var found: Array = []
	var path := workspace.path_join("Audio/Music.txt")
	if FileAccess.file_exists(path):
		var section := ""
		for line in FileAccess.get_file_as_string(path).split("\n"):
			var text := line.strip_edges()
			if text.is_empty() or text.begins_with(";"):
				continue
			if text.ends_with(".mp3"):
				if section == "GENERAL_MUSIC":
					found.append("Audio/Music/" + text)
			else:
				section = text
	if found.is_empty():
		for name in ["Afigisi", "Amolfi", "Eilavia", "Eplitha", "Fengari", "Iremos", "Mnimio", "Naoss", "Oyonos", "Perifanos", "Pnevma", "Proi"]:
			found.append("Audio/Music/%s.mp3" % name)
	return found

# "menu" loops the title tune; "city" and "battle" play random tracks one after another. Asking for what is already
# playing does nothing, so callers may repeat the request.
func play_music(kind: String) -> void:
	if kind == music_kind and (music.playing or not enabled or kind == "menu"):
		return
	var track := ""
	match kind:
		"menu":
			track = MENU_TRACK
		"city":
			track = _pick(general_tracks)
		"battle":
			var battle: Array = []
			for name in BATTLE_TRACKS:
				battle.append("Audio/Music/%s.mp3" % name)
			track = _pick(battle)
		_:
			return
	_start_music(kind, track)

func _pick(tracks: Array) -> String:
	var options: Array = tracks.filter(func(item): return item != music_track)
	if options.is_empty():
		options = tracks
	return options[randi() % options.size()] if not options.is_empty() else ""

func _start_music(kind: String, track: String) -> void:
	var stream := load_stream(track) if track != "" else null
	music_kind = kind
	music_track = track
	cue_playing = false
	if stream == null:
		music_changed.emit(kind, "")
		return
	_record(track, "Music")
	music_changed.emit(kind, track)
	if not enabled:
		return
	# Cross-fade: the old track fades out on the spare player while the new one fades in.
	if music.playing:
		var old := music
		music = music_fading
		music_fading = old
		var out := create_tween()
		out.tween_property(old, "volume_db", -60.0, FADE)
		out.tween_callback(old.stop)
	if stream is AudioStreamMP3:
		stream.loop = kind == "menu"
	music.stream = stream
	music.volume_db = -60.0
	music.play()
	create_tween().tween_property(music, "volume_db", 0.0, FADE)

func stop_music(fade := FADE) -> void:
	music_kind = ""
	if music.playing:
		var out := create_tween()
		out.tween_property(music, "volume_db", -60.0, fade)
		out.tween_callback(music.stop)

# A track ended: carry on with the next of the same kind. (A track faded out on the spare player ends silently.)
func _player_finished(player: AudioStreamPlayer) -> void:
	if player == music:
		_music_finished()

func _music_finished() -> void:
	cue_playing = false
	if music_kind == "city" or music_kind == "battle":
		var kind := music_kind
		music_kind = ""
		play_music(kind)

# ---- ambient -------------------------------------------------------------------------------------------------
# Called every frame by the city: when nothing else is audible, now and then (about every four seconds) ask the core
# for the sound of a place near the middle of the view.
func ambient_tick(dt: float, core: Node, tile: Vector2i) -> void:
	if core.simulation == null:
		return
	if busy_effects() > 0:
		return
	var chance := 1.0 - pow(1.0 - AMBIENT_ODDS, dt * 60.0)
	if randf() >= chance:
		return
	request_ambient(core, tile + Vector2i(randi_range(-3, 3), randi_range(-3, 3)))

func request_ambient(core: Node, tile: Vector2i) -> Array:
	var answer: Dictionary = core.query("ambient %d %d" % [tile.x, tile.y])
	var paths: Array = answer.get("sounds", [])
	play_native(paths)
	return paths

func request_building_sound(core: Node, tile: Vector2i) -> Array:
	var answer: Dictionary = core.query("building_sound %d %d" % [tile.x, tile.y])
	var paths: Array = answer.get("sounds", [])
	play_native(paths)
	return paths
