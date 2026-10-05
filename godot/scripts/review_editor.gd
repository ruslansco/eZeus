extends SceneTree
# Captures of the adventure editor in the 3D city (windowed): a copy of The Founding of Athens in a scratch adventures folder is
# opened for editing and handed to the city scene as the start menu does; then the map with the terrain tools, a water stroke
# and raised ground painted through the panel, the episodes window, an episode's settings with an event, and the world map.
# Nothing is saved; the scratch folder is removed. Run: Godot --path godot --script res://scripts/review_editor.gd [--lang=ru]
var scratch := ""

func _initialize() -> void:
	call_deferred("run")

func copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	for file in DirAccess.get_files_at(from):
		DirAccess.copy_absolute(from.path_join(file), to.path_join(file))

func remove_tree(folder: String) -> void:
	for sub in DirAccess.get_directories_at(folder):
		remove_tree(folder.path_join(sub))
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)

func shot(name: String) -> void:
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://captures/editor-%s.png" % name)
	root.get_texture().get_image().save_png(path)
	print("EDITOR_REVIEW ", name)

func run() -> void:
	var lang := "en"
	for argument in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if argument.begins_with("--lang="):
			lang = argument.get_slice("=", 1)
	var engine := ProjectSettings.globalize_path("res://..").simplify_path()
	scratch = ProjectSettings.globalize_path("res://captures/editor-review-%d" % Time.get_ticks_usec())
	copy_tree(engine.path_join("Adventures/The Founding of Athens"), scratch.path_join("Adventures/The Founding of Athens"))
	Engine.set_meta("ezeus_save_directory", scratch.path_join("saves"))
	Engine.set_meta("ezeus_settings_path", scratch.path_join("settings.cfg"))
	Engine.set_meta("ezeus_language", lang)
	var editor: RefCounted = ClassDB.instantiate("EZeusSimulation")
	editor.set_adventures_directory(scratch.path_join("Adventures"))
	var opened: Dictionary = editor.open_editor(engine, "folder", "The Founding of Athens", lang)
	if opened.has("error"):
		print("EDITOR_REVIEW failed ", opened.error)
		quit(1)
		return
	Engine.set_meta("ezeus_simulation", editor)
	Engine.set_meta("ezeus_editor", true)
	change_scene_to_file("res://main.tscn")
	for i in 90:
		await process_frame
	var city = current_scene
	var panel = city.editor_panel
	if panel == null:
		print("EDITOR_REVIEW failed no panel")
		quit(1)
		return
	await shot("map")
	# A water stroke and raised ground near the middle of the view, through the panel's own stroke.
	var tiles := []
	for cell in city.tiles:
		tiles.append(cell)
	# The tile nearest the middle of the view.
	var target: Vector3 = city.orbit.target
	var best: Vector2i = tiles[0]
	var near := INF
	for cell in tiles:
		var at: Vector3 = city.world_position(cell.x, cell.y, 0)
		var d := Vector2(at.x - target.x, at.z - target.z).length()
		if d < near:
			near = d
			best = cell
	panel.choose("water")
	panel.brush_kind.select(1)
	panel.brush_size.value = 4
	panel.paint([best, best + Vector2i(2, 0), best + Vector2i(4, 1)])
	panel.choose("raise_high")
	panel.brush_kind.select(2)
	panel.paint([best + Vector2i(-8, 4), best + Vector2i(-4, 8)])
	panel.choose("forest")
	panel.brush_kind.select(0)
	panel.brush_size.value = 3
	panel.paint([best + Vector2i(6, -6), best + Vector2i(8, -5), best + Vector2i(10, -6)])
	panel.choose("water")
	await shot("painted")
	panel.choose("")
	panel.episodes.open()
	await shot("episodes")
	panel.episodes.open_settings("p", 0)
	var cid: int = panel.episodes.city_id()
	panel.query("editor_event_add p 0 %d 5" % cid)
	panel.episodes.episode = panel.query("editor_episode p 0")
	panel.episodes.show_episode()
	panel.episodes.tabs.current_tab = 1
	panel.episodes.show_event(panel.episodes.events_list.item_count - 1)
	await shot("event")
	panel.episodes.tabs.current_tab = 0
	await shot("goals")
	panel.episodes.close()
	panel.world.open()
	panel.world.choose(1)
	await shot("world")
	panel.world.close()
	editor.close_city()
	remove_tree(scratch)
	Engine.remove_meta("ezeus_save_directory")
	Engine.remove_meta("ezeus_settings_path")
	quit(0)
