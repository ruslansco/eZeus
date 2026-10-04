extends SceneTree
# Trade posts through the real interface (headless, scratch saves): in a new game of The Founding of Athens (two sea
# partners) the Build menu lists a Trade category with a pier for each; choosing one shows the pier and its trade post
# on the shore, a click builds both for the post's cost, the partner leaves the menu, the post's panel offers its partner's
# goods and an order is applied through it; undo brings the partner back. The Peloponnesian War (land partners) places a
# land trade post the same way.
const BuildCatalog = preload("res://scripts/build_catalog.gd")
var okay := true
var checks := 0
var scratch := ""

func check(value: bool, description: String) -> void:
	checks += 1
	print("TRADE_UI_CHECK ", "PASS " if value else "FAIL ", description)
	okay = okay and value

func _initialize() -> void:
	call_deferred("run")

func seconds(duration: float) -> void:
	await create_timer(duration).timeout

func city() -> Node:
	return current_scene

func start(title: String) -> void:
	var menu: Control = load("res://ui/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await seconds(.5)
	menu.new_game_button.pressed.emit()
	await seconds(.4)
	for index in menu.listing.size():
		if menu.listing[index].title == title:
			menu.adventure_list.select(index)
			menu.show_adventure(index)
	menu.adventure_start.pressed.emit()
	await seconds(1.5)
	menu.intro_begin.pressed.emit()
	await seconds(4.0)

func tile_screen(cell: Vector2i) -> Vector2:
	var game := city()
	return game.orbit.camera.unproject_position(game.world_position(cell.x, cell.y, game.tiles[cell][2]))

func mouse_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	return event

func look_at_tile(cell: Vector2i) -> void:
	var game := city()
	game.orbit.target = game.world_position(cell.x + 1, cell.y + 1, game.tiles[cell][2])
	game.orbit.distance = 20
	game.orbit.yaw = 45
	game.orbit.snap_to_ground()
	await create_timer(.3).timeout

func trade_group(game: Node) -> Dictionary:
	for group in game.hud.build_groups:
		if group.title == "Trade":
			return group
	return {}

func run() -> void:
	scratch = ProjectSettings.globalize_path("res://captures/validation-trade-ui-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(scratch)
	Engine.set_meta("ezeus_save_directory", scratch)
	Engine.set_meta("ezeus_settings_path", scratch.path_join("settings.cfg"))
	Engine.set_meta("ezeus_language", "en")

	# Sea trade: a pier for a sea partner.
	await start("The Founding of Athens")
	var game = city()
	var group: Dictionary = trade_group(game)
	check(not group.is_empty() and group.items.size() == 2 and group.items.all(func(item): return item.name.begins_with("pier:") and item.has("partner_name")), "the Build menu has a Trade category with a pier for each of the two sea partners")
	check(group.items[0].label == "Pier" and game.hud.building_text(group.items[0]).contains(group.items[0].partner_name) and game.hud.building_text(group.items[0]).contains("dr"), "each entry reads \"Pier: <partner>\" with its cost (%s)" % game.hud.building_text(group.items[0]))
	var item: Dictionary = group.items[0]
	var state: Dictionary = game.core.simulation.snapshot(true)
	var shore := Vector2i(99999, 99999)
	for tile in state.tiles:
		if int(tile[5]) and game.core.query("preview pier %d %d 0 %d" % [tile[0], tile[1], item.partner]).get("valid", false):
			shore = Vector2i(int(tile[0]), int(tile[1]))
			break
	check(shore != Vector2i(99999, 99999), "the shore has room for a pier")
	await look_at_tile(shore)
	check(game.hud.activate_building(item.name) and game.mode == "pier" and game.trade_partner == int(item.partner) and game.hud.build_menu.tooltip_text.contains(item.partner_name), "choosing the entry selects the pier tool for that partner")
	game.pick_tile(tile_screen(shore))
	game.refresh_placement()
	check(game.placement_result.get("valid", false) and game.footprint_cells.get_child_count() == 20 and game.hint.text.contains("100"), "the pointer shows the pier and its trade post (20 tiles) with their cost")
	# Few tiles take a pier, so the pointer is helped: two tiles away from the spot the preview still finds it.
	game.picked = shore + Vector2i(-1, 1)
	game.placement_key = ""
	game.refresh_placement()
	check(game.placement_result.get("valid", false) and game.footprint_cells.get_child_count() == 20 and game.placement_cell != game.picked, "near the shore the pier snaps to the fitting spot (%s from %s)" % [game.placement_cell, game.picked])
	game.pick_tile(tile_screen(shore))
	game.refresh_placement()
	var money_before: int = int(game.state.money)
	var posts_before: int = game.state.buildings.filter(func(b): return b.asset == "trade_post").size()
	game._unhandled_input(mouse_event(tile_screen(shore), true))
	await seconds(.8)
	check(int(game.state.money) == money_before - 100 and game.mode == "select", "a click builds it for the quoted cost and ends the tool")
	check(game.state.buildings.filter(func(b): return b.asset == "trade_post").size() == posts_before + 1 and game.state.buildings.any(func(b): return b.asset == "harbour"), "a pier and a trade post stand on the shore")
	await seconds(.8)
	var left: Dictionary = trade_group(game)
	check(left.items.size() == 1 and left.items[0].partner != item.partner, "the partner has its post and left the menu")

	# The post's panel.
	var post := {}
	for b in game.state.buildings:
		if b.asset == "trade_post":
			post = b
	game.set_tool("select")
	game.inspected = Vector2i(int(post.x), int(post.y))
	game.refresh_inspection()
	await seconds(.5)
	var panel = game.inspector_controls
	check(panel.value.has("trade") and not panel.trade_rows.is_empty() and panel.trade_rows.size() == panel.value.trade.imports.size() + panel.value.trade.exports.size(), "the panel lists the partner's goods (%d rows)" % panel.trade_rows.size())
	var key: String = panel.trade_rows.keys()[0]
	var row: Dictionary = panel.trade_rows[key]
	row.toggle.select(1)
	row.toggle.item_selected.emit(1)
	check(row.dirty and not row.apply.disabled, "changing a row enables Apply")
	row.apply.pressed.emit()
	await seconds(.8)
	var info: Dictionary = game.core.query("inspect %d %d" % [post.x, post.y])
	var listed: Array = info.trade.imports + info.trade.exports
	check(listed.any(func(g): return g.enabled) and game.hint.text == game.tr("Trade orders updated. Traders will follow them."), "Apply sends the order to the core and the hint confirms it")
	check(panel.trade_rows[key].toggle.selected == 1 and not panel.trade_rows[key].dirty, "the panel shows it as set")

	# Undo brings the partner back.
	game.core.query("pause 0")
	game.core.send("undo")
	await seconds(3.0)
	check(trade_group(game).items.size() == 2, "undo returns the partner to the menu")
	root.remove_child(game)
	game.queue_free()
	await seconds(.5)

	# Land trade: a trade post for a land partner.
	await start("The Peloponnesian War")
	game = city()
	group = trade_group(game)
	check(group.items.size() == 5 and group.items.all(func(it): return it.name.begins_with("trade_post:")), "the Peloponnesian War's Trade category lists five land trading posts")
	var land: Dictionary = group.items[1]
	state = game.core.simulation.snapshot(true)
	var plot := Vector2i(99999, 99999)
	for tile in state.tiles:
		if int(tile[5]) and game.core.query("preview trade_post %d %d 0 %d" % [tile[0], tile[1], land.partner]).get("valid", false):
			plot = Vector2i(int(tile[0]), int(tile[1]))
			break
	await look_at_tile(plot)
	game.hud.activate_building(land.name)
	game.pick_tile(tile_screen(plot))
	game.refresh_placement()
	check(game.mode == "trade_post" and game.placement_result.get("valid", false) and game.footprint_cells.get_child_count() == 16 and game.placement_result.asset == "trade_post", "a land trade post shows its 4x4 footprint")
	money_before = int(game.state.money)
	game._unhandled_input(mouse_event(tile_screen(plot), true))
	await seconds(.8)
	check(int(game.state.money) == money_before - 100 and game.state.buildings.any(func(b): return b.asset == "trade_post"), "a click builds the post")
	await seconds(.8)
	check(trade_group(game).items.size() == 4, "its partner left the menu")
	for file in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch.path_join(file))
	DirAccess.remove_absolute(scratch)
	Engine.remove_meta("ezeus_settings_path")
	print("TRADE_UI_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)
