extends RefCounted

# Captures the Controls and Game settings dialogs over the city (interface on), with a scratch settings file so that nothing of the player's is
# touched: the Controls dialog as it opens, partway through asking for a key, and after a swap; the Game settings dialog. Files: captures/controls-<name>-*.png.
const KeyBindings = preload("res://scripts/key_bindings.gd")
const PlaySettings = preload("res://scripts/play_settings.gd")

func shot(city: Node3D, name: String) -> void:
	DisplayServer.window_move_to_foreground()
	await city.get_tree().create_timer(.6).timeout
	city.capture_path = ProjectSettings.globalize_path("res://captures/controls-%s.png" % name)
	await city.capture()

func key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	return event

func run(city: Node3D, phase: String) -> void:
	var scratch := ProjectSettings.globalize_path("res://captures/controls-review-%d.cfg" % Time.get_ticks_usec())
	Engine.set_meta("ezeus_settings_path", scratch)
	KeyBindings.reload()
	PlaySettings.reload()
	city.core.query("pause 1")
	city.ui_layer.visible = true
	await city.get_tree().create_timer(.5).timeout
	city.game_action("controls")
	var dialog: Window = city.hud.get_children().filter(func(child): return child is AcceptDialog and child.has_method("assign_from_event"))[0]
	await shot(city, phase + "-controls")
	dialog.begin_capture("turn_placement")
	await shot(city, phase + "-asking")
	dialog.assign_from_event(key_event(KEY_X))
	await shot(city, phase + "-swapped")
	dialog.scroll_to("overlay_water")
	await shot(city, phase + "-views")
	dialog.restore_defaults()
	dialog.close()
	await city.get_tree().process_frame
	city.game_action("settings")
	await shot(city, phase + "-settings")
	KeyBindings.reload()
	PlaySettings.reload()
	Engine.remove_meta("ezeus_settings_path")
	DirAccess.remove_absolute(scratch)
	print("CONTROLS_REVIEW PASS")
	city.get_tree().quit(0)
