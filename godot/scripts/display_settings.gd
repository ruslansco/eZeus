extends RefCounted
# Presentation only. Window sizes are client-area pixels, fullscreen uses the desktop.
# Preview never writes. Confirm preserves other ConfigFile sections; automation is isolated.
const Settings = preload("res://scripts/user_settings.gd")
const KeyBindings = preload("res://scripts/key_bindings.gd")
const DEFAULT_SIZE := Vector2i(1280, 800)
const SIZES := [Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1280, 800),
	Vector2i(1366, 768), Vector2i(1440, 900), Vector2i(1600, 900), Vector2i(1680, 1050),
	Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(2560, 1440), Vector2i(2560, 1600),
	Vector2i(3440, 1440), Vector2i(3840, 2160)]
const FRAME_LIMITS := [0, 30, 60, 120, 144]
const DEFAULTS := {"mode": "windowed", "window_size": DEFAULT_SIZE, "screen": -1, "vsync": true, "frame_limit": 0}

static func sanitize(raw: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in DEFAULTS:
		var value: Variant = raw.get(key)
		if typeof(value) != typeof(DEFAULTS[key]): continue
		match key:
			"mode":
				if value in ["windowed", "fullscreen"]: result[key] = value
			"window_size":
				if value.x >= 640 and value.y >= 480 and value.x <= 7680 and value.y <= 4320: result[key] = value
			"screen":
				if value >= -1 and value < 32: result[key] = value
			"frame_limit":
				if value in FRAME_LIMITS: result[key] = value
			"vsync": result[key] = value
	return result

static func load_preferences() -> Dictionary:
	if not KeyBindings.uses_player_settings(): return DEFAULTS.duplicate()
	var file := ConfigFile.new()
	if file.load(Settings.path()) != OK: return DEFAULTS.duplicate()
	var raw := {}
	for key in DEFAULTS: raw[key] = file.get_value("display", key, DEFAULTS[key])
	# Migrate the earlier fullscreen checkbox without changing any other preference.
	var legacy_fullscreen: Variant = file.get_value("game", "fullscreen", false)
	if not file.has_section_key("display", "mode") and typeof(legacy_fullscreen) == TYPE_BOOL and legacy_fullscreen:
		raw.mode = "fullscreen"
	return sanitize(raw)

static func screen_index(requested: int) -> int:
	var count := DisplayServer.get_screen_count()
	return requested if requested >= 0 and requested < count else DisplayServer.window_get_current_screen()

static func usable_size(screen: int) -> Vector2i:
	# Leave space for the title bar and desktop chrome when windowed.
	var usable := DisplayServer.screen_get_usable_rect(screen_index(screen)).size - Vector2i(16, 48)
	return Vector2i(maxi(usable.x, 1), maxi(usable.y, 1))

static func fitted_size(wanted: Vector2i, available: Vector2i) -> Vector2i:
	return Vector2i(mini(wanted.x, available.x), mini(wanted.y, available.y))

static func available_sizes(screen: int, current: Vector2i) -> Array:
	var available := usable_size(screen)
	var choices: Array = []
	for candidate in SIZES:
		if candidate.x <= available.x and candidate.y <= available.y: choices.append(candidate)
	var fitted := fitted_size(current, available)
	if not choices.has(fitted): choices.append(fitted)
	if not choices.has(available): choices.append(available)
	choices.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	return choices

static func capture(window: Window) -> Dictionary:
	var preferences := load_preferences()
	return {"mode": "fullscreen" if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else "windowed",
		"window_size": window.size if window.mode == Window.MODE_WINDOWED else preferences.window_size,
		"screen": window.current_screen, "vsync": DisplayServer.window_get_vsync_mode(window.get_window_id()) != DisplayServer.VSYNC_DISABLED,
		"frame_limit": Engine.max_fps, "position": window.position, "actual_size": window.size,
		"actual_mode": window.mode, "borderless": window.borderless,
		"vsync_mode": DisplayServer.window_get_vsync_mode(window.get_window_id())}

static func apply(window: Window, raw: Dictionary) -> Dictionary:
	var options := sanitize(raw)
	if DisplayServer.get_name() == "headless": return options
	options.screen = screen_index(options.screen)
	options.window_size = fitted_size(options.window_size, usable_size(options.screen))
	if options.mode == "fullscreen" and window.mode == Window.MODE_FULLSCREEN and window.current_screen == options.screen:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if options.vsync else DisplayServer.VSYNC_DISABLED, window.get_window_id())
		Engine.max_fps = options.frame_limit
		return options
	# Leaving fullscreen forces borderless in Godot; explicitly restore a normal window.
	if window.mode != Window.MODE_WINDOWED: window.mode = Window.MODE_WINDOWED
	if window.current_screen != options.screen: window.current_screen = options.screen
	window.borderless = false
	window.size = options.window_size
	var usable := DisplayServer.screen_get_usable_rect(options.screen)
	window.position = usable.position + (usable.size - window.size) / 2
	if options.mode == "fullscreen":
		window.grab_focus()
		window.mode = Window.MODE_FULLSCREEN
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if options.vsync else DisplayServer.VSYNC_DISABLED, window.get_window_id())
	Engine.max_fps = options.frame_limit
	return options

static func restore(window: Window, original: Dictionary) -> void:
	apply(window, original)
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_vsync_mode(original.vsync_mode, window.get_window_id())
	window.mode = original.actual_mode
	window.borderless = original.borderless
	if original.actual_mode == Window.MODE_WINDOWED:
		window.size = original.actual_size
		window.position = original.position

static func commit(options: Dictionary) -> Error:
	if not KeyBindings.uses_player_settings(): return OK
	var file := ConfigFile.new()
	file.load(Settings.path())
	var safe := sanitize(options)
	for key in DEFAULTS: file.set_value("display", key, safe[key])
	file.set_value("game", "fullscreen", safe.mode == "fullscreen")
	return file.save(Settings.path())

static func startup(window: Window) -> void:
	if KeyBindings.uses_player_settings(): apply(window, load_preferences())

static func set_fullscreen(window: Window, enabled: bool) -> void:
	var options := capture(window)
	options.mode = "fullscreen" if enabled else "windowed"
	commit(apply(window, options))
