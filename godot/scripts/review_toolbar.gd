extends SceneTree
# Read-only native toolbar routes over a copied full city. Tooltip/Undo availability are presentation fixtures.
const Saves = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
const Catalog = preload("res://scripts/build_catalog.gd")
const Bindings = preload("res://scripts/key_bindings.gd")
var city: Node
var language := "en"
var checks := 0
var okay := true

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("TOOLBAR_CHECK ", "PASS " if value else "FAIL ", description)

func finish() -> void:
	# Release loaded city/thumbnail resources while the renderer is still alive.
	while city.hud.thumbnails.busy or not city.hud.thumbnails.pending.is_empty(): await frames(2)
	city.core.simulation.close_city()
	city.queue_free()
	await frames(4)
	print("TOOLBAR_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)

func frames(count := 8) -> void:
	for i in count: await process_frame

func move_to(point: Vector2) -> void:
	# Keep the physical cursor aligned when Godot rechecks hover between frames.
	# The injected motion still exercises the normal enter/exit signal path.
	root.warp_mouse(point)
	var event := InputEventMouseMotion.new()
	event.position = point
	event.set_meta("review_input", true)
	root.push_input(event, true)
	await frames(3)
	# Observe the final injected motion before hardware cursor rechecks from other desktop work.
	root.push_input(event, true)

func hover(control: Control) -> void:
	DisplayServer.window_move_to_foreground()
	await move_to(control.get_global_rect().get_center())

func click(control: Control) -> void:
	await hover(control)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.set_meta("review_input", true)
		root.push_input(event, true)
		# A real pointer press spans frames; deferred focus changes must run before release.
		if pressed: await frames(2)
	await frames()

func key(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.set_meta("review_input", true)
		root.push_input(event, true)
	await frames()

func capture(label: String) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(12)
	RenderingServer.force_draw(true, .016)
	root.get_texture().get_image().save_png("res://captures/toolbar-%s-%s.png" % [language, label])

func ignores_pointer(node: Node) -> bool:
	if node is Control and node.mouse_filter != Control.MOUSE_FILTER_IGNORE: return false
	for child in node.get_children():
		if not ignores_pointer(child): return false
	return true

func preview_checks() -> void:
	var hud: Control = city.hud
	var service: Node = hud.thumbnails
	# Include scenario-unavailable designs without granting or building any of them.
	var specs: Array = city.core.query("buildable").get("buildings", [])
	var missing: Array = []
	var incomplete: Array = []
	var misplaced: Array = []
	var designs := 0
	for item in specs:
		if item.asset in ["road", "unconverted"]: continue
		var model: Node3D = city.building_preview_model(item)
		var boxes: Array[AABB] = []
		if model != null: service._bounds(model, Transform3D.IDENTITY, boxes)
		if boxes.is_empty(): missing.append(item.name)
		if city.BuildingPreview.composite(str(item.name)):
			var plan: Dictionary = city.building_preview_layout(str(item.name))
			if model == null or model.get_child_count() != plan.get("pieces", []).size(): incomplete.append(item.name)
			elif not plan.get("pieces", []).is_empty():
				var center: Vector3 = city.world_position(float(plan.x) + (float(plan.w) - 1) * .5, float(plan.y) + (float(plan.h) - 1) * .5, 0)
				for i in plan.pieces.size():
					var piece: Dictionary = plan.pieces[i]
					var expected: Vector3 = city.world_position(float(piece.x) + (float(piece.w) - 1) * .5, float(piece.y) + (float(piece.h) - 1) * .5, float(piece.get("lift", 0))) - center
					if model.get_child(i).position.distance_to(expected) > .0001:
						misplaced.append(item.name)
						break
		if item.name in ["common_agora", "grand_agora"]:
			check(model != null and int(model.get_meta("vendor_spaces", 0)) == (6 if item.name == "grand_agora" else 3), item.name + ": preview shows the native empty vendor plots, without bundled vendors")
		if model != null: model.free()
		designs += 1
	check(missing.is_empty(), "all %d converted catalog designs have preview geometry, including unavailable scenario designs: %s" % [designs, str(missing)])
	check(incomplete.is_empty(), "every composite picture contains its complete native placement layout: " + str(incomplete))
	check(misplaced.is_empty(), "composite pieces use the city's native coordinate conversion and relative heights: " + str(misplaced))
	var items: Array = []
	for group in hud.build_groups:
		for item in group.items:
			items.append(item)
			service.request(item)
	# Additional renders exercise shared-component designs outside this episode's
	# available cards, without granting them to the player.
	for tool in ["pyramid_modest", "pyramid_great", "pyramid_majestic", "shrine_minor_athena", "shrine_athena", "shrine_major_athena", "temple_zeus"]:
		var matches: Array = specs.filter(func(item): return item.name == tool)
		if not matches.is_empty() and not items.any(func(item): return item.name == tool):
			items.append(matches[0])
			service.request(matches[0])
	var deadline := Time.get_ticks_msec() + 90000
	while (service.busy or not service.pending.is_empty()) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not service.busy and service.pending.is_empty(), "the requested catalog render queue finishes")
	var absent: Array = []
	var clipped: Array = []
	var empty_faces: Array = []
	var unlit: Array = []
	var rendered := 0
	for item in items:
		var texture: Texture2D = service.request(item)
		if item.asset == "road":
			check(texture == null, str(item.name) + ": terrain tool retains its intentional road illustration")
			continue
		if texture == null:
			absent.append(item.name)
			continue
		var bitmap := texture.get_image()
		var used := bitmap.get_used_rect()
		if used.size.x < 2 or used.size.y < 2 or used.position.x < 1 or used.position.y < 1 or used.end.x >= bitmap.get_width() or used.end.y >= bitmap.get_height():
			clipped.append({"name":item.name, "bounds":str(used)})
		var painted := 0
		var brightness := 0.0
		for y in range(used.position.y, used.end.y):
			for x in range(used.position.x, used.end.x):
				var pixel := bitmap.get_pixel(x, y)
				if pixel.a > .1:
					painted += 1
					brightness += pixel.r * .2126 + pixel.g * .7152 + pixel.b * .0722
		if painted < used.get_area() * .08: empty_faces.append(item.name)
		if painted > 0 and brightness / painted < .025: unlit.append(item.name)
		bitmap.save_png("res://captures/building-preview-%s-%s.png" % [language, service.key(item)])
		rendered += 1
	check(absent.is_empty(), "all %d requested model-backed designs receive rendered pictures: %s" % [rendered, str(absent)])
	check(clipped.is_empty(), "complete model silhouettes fit inside transparent thumbnail margins: " + str(clipped))
	check(empty_faces.is_empty(), "thumbnails contain visible model surfaces rather than only detached edges: " + str(empty_faces))
	check(unlit.is_empty(), "thumbnail surfaces remain lit and readable against the dark cards: " + str(unlit))
	check(service.get_child_count() == 1 and service.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED and service.stage.get_child_count() == 0, "one shared thumbnail viewport is idle and retains no temporary buildings")
	for category in ["Markets", "Pyramids", "Shrines", "Sanctuaries", "Administration and security", "Walls and defence"]:
		if not hud.category_buttons.has(category): continue
		hud.close_build_tray()
		var button: Control = hud.category_buttons[category]
		hud.get_node("%CategoryScroll").ensure_control_visible(button)
		await frames()
		await click(button)
		var correct := true
		for item in hud.build_entries.values():
			if not hud.building_cards.has(item.name): continue
			var pictures: Array = hud.building_cards[item.name].find_children("*", "TextureRect", true, false)
			correct = correct and pictures.size() == 1 and pictures[0].texture == service.request(item)
		check(correct, category + ": every visible card displays its own completed picture")
		await capture("previews-" + category.to_lower().replace(" ", "-"))
	# Both agora tools used to share agora_space, so rendering one overwrote the other.
	for pair in [["common_agora", "grand_agora"], ["pyramid_modest", "pyramid_great"]]:
		var first: Texture2D = service.request(specs.filter(func(item): return item.name == pair[0])[0])
		var second: Texture2D = service.request(specs.filter(func(item): return item.name == pair[1])[0])
		check(first != null and second != null and first != second and first.get_image().get_data() != second.get_image().get_data(), str(pair) + ": shared component assets produce distinct building pictures")
	hud.close_build_tray()
	hud.open_category("Markets")
	await frames()
	for tool in ["common_agora", "grand_agora"]:
		if not hud.building_cards.has(tool): continue
		var card: Control = hud.building_cards[tool]
		hud.get_node("%BuildingScroll").ensure_control_visible(card)
		await frames()
		await hover(card)
		var item: Dictionary = hud.build_entries[tool]
		check(hud.context_item.name == tool and hud.get_node("%ContextPreview").texture == service.request(item), tool + ": hover context uses the matching building picture")
		await click(card)
		check(city.mode == tool and hud.current_tool == tool and city.core.commands.is_empty(), tool + ": pictured card still selects the original native placement tool")
		await capture("previews-" + tool)
	hud.close_build_tray()
	city.set_tool("select")

func toolbar_buttons() -> Array:
	var buttons: Array = city.hud.category_buttons.values()
	buttons.append_array(city.hud.tool_buttons.values().filter(func(button): return button.visible))
	for name in ["Undo", "OverlayMenu", "Jobs"]:
		buttons.append(city.hud.get_node("%" + name))
	return buttons

func context_checks() -> void:
	var hud: Control = city.hud
	# Initial trade availability schedules one native refresh after 1.5 seconds.
	# Let it settle before deliberately narrowing only the presentation catalog.
	await create_timer(1.6).timeout
	var original: Array = hud.build_groups.duplicate(true)
	var titles: Array = Catalog.CATEGORIES.map(func(category): return category[0])
	var sparse: Array = original.slice(0, mini(8, original.size()))
	hud.set_catalog(sparse)
	await frames(16)
	check(hud.category_buttons.keys() == titles, "sparse catalog retains all sixteen categories in canonical positions")
	var enabled: Array = sparse.map(func(group): return group.title)
	check(hud.category_buttons.keys().all(func(title): return hud.category_buttons[title].disabled == not enabled.has(title)), "category availability follows only the currently offered native groups")
	var unavailable: Array = titles.filter(func(title): return not enabled.has(title))
	var disabled: Button = hud.category_buttons[unavailable[0]]
	var image: Image = disabled.icon.get_image()
	var grayscale := true
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			var pixel := image.get_pixel(x,y)
			if pixel.a > .01 and (absf(pixel.r-pixel.g) > .01 or absf(pixel.g-pixel.b) > .01): grayscale = false
	check(grayscale and disabled.get_theme_color("icon_disabled_color").a > .5, "unavailable categories have readable grayscale artwork, without recoloring enabled icons")
	await hover(disabled)
	check(hud.toolbar_hovered == disabled and hud.get_node("%ToolbarContext").text == tr(unavailable[0]), "a disabled category still identifies itself on real pointer hover")
	var tooltip: Control = disabled._make_custom_tooltip(disabled.tooltip_text)
	var labels: Array = tooltip.find_children("*", "Label", true, false)
	check(labels.any(func(label): return label.text.contains(tr("Unavailable")) and label.text.contains(tr("No buildings in this category are currently available."))), "unavailable hover help explains the current restriction in the active language")
	tooltip.free()
	await click(disabled)
	check(hud.active_category.is_empty() and not hud.get_node("%BuildTray").visible and city.core.commands.is_empty(), "clicking a disabled category neither opens a tray nor queues a native action")
	await create_timer(.8).timeout
	await capture("context-unavailable")
	var selected: String = sparse[-1].title
	await click(hud.category_buttons[selected])
	await move_to(Vector2(hud.size.x*.5,180))
	await frames()
	check(hud.get_node("%ToolbarContext").text == tr(selected) and hud.active_category == selected, "selected category remains in the center after the pointer leaves the dock")
	bounds("sparse selected category")
	await capture("context-selected")
	var row_order: Array = hud.category_buttons.keys()
	hud.set_catalog([])
	await frames(16)
	check(hud.category_buttons.keys() == row_order and hud.category_buttons.values().all(func(button): return button.disabled) and not hud.get_node("%BuildTray").visible, "removing the selected category closes stale cards and retains disabled positions")
	var guide: Control = preload("res://ui/city_help_panel.gd").new()
	guide.city = city
	guide.tab = "guide"
	guide.step = 2
	var guide_action: Button = guide.build_action(2)
	check(guide.targets().is_empty() and guide_action == null, "settlement guidance skips unavailable category targets and actions")
	if guide_action != null: guide_action.free()
	guide.free()
	hud.set_catalog([sparse[0]])
	await frames(16)
	check(not hud.category_buttons[sparse[0].title].disabled and hud.category_buttons.keys() == row_order, "a newly available category enables in its original position")
	await click(hud.category_buttons[sparse[0].title])
	check(hud.active_category == sparse[0].title and hud.building_cards.size() == sparse[0].items.size(), "re-enabled category opens precisely its native building cards")
	for dimensions in [Vector2i(1920,1080), Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions)
		for sizing in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(sizing.x,sizing.y)
			hud.close_build_tray()
			hud.set_catalog(sparse)
			hud.open_category(selected)
			await move_to(Vector2(70,160))
			await frames(24)
			var label: Label = hud.get_node("%ToolbarContext")
			var text_width := label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
			check(label.is_visible_in_tree() and label.text == tr(selected) and label.size.x >= text_width, str(dimensions)+" "+str(sizing)+": selected category text fits without disappearing or truncation")
			bounds("sparse "+str(dimensions)+" "+str(sizing))
			await capture("context-%d-%d" % [dimensions.x,sizing.x])
	root.get_node("UiAccess").apply(100,100)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	hud.close_build_tray()
	hud.set_catalog(original)
	await frames(16)
	check(hud.build_groups == original and hud.category_buttons.keys() == row_order, "restoring the native catalog preserves canonical slot order")

func bounds(label: String) -> void:
	var hud: Control = city.hud
	var screen := Rect2(Vector2.ZERO, hud.size)
	var dock: Rect2 = hud.get_node("%BottomBar").get_global_rect()
	var categories: Rect2 = hud.get_node("%CategoryScroll").get_global_rect()
	var utilities: Rect2 = hud.get_node("%ToolbarUtilities").get_global_rect()
	var context: Rect2 = hud.get_node("%ToolbarContext").get_global_rect()
	check(screen.encloses(dock) and dock.encloses(categories) and dock.encloses(utilities), label + ": both toolbar rows stay inside the viewport")
	check(utilities.encloses(context) and categories.end.y <= utilities.position.y + 1 and context.size.x > 20 and hud.get_node("%ToolbarContext").horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, label + ": hover label fits below the distinct category row")
	check(toolbar_buttons().filter(func(button): return not hud.get_node("%Categories").is_ancestor_of(button)).all(func(button): return dock.encloses(button.get_global_rect())), label + ": all direct tools and utilities stay visible")
	var map_button: Control = hud.get_node("%MapToggle")
	var clock: Control = hud.get_node("%TimeBar")
	check(screen.encloses(clock.get_global_rect()) and not dock.intersects(clock.get_global_rect()) and not hud.get_node("%StatusBar").is_ancestor_of(clock), label + ": the time group stays below the map, outside the header and dock")
	if hud.get_node("%MinimapPanel").visible:
		check(not map_button.visible and hud.get_node("%MapClose").is_visible_in_tree() and hud.get_node("%MinimapPanel").get_global_rect().end.y + 4 <= clock.position.y, label + ": open map uses its fold button above the time controls")
	else:
		check(map_button.is_visible_in_tree() and screen.encloses(map_button.get_global_rect()) and not dock.intersects(map_button.get_global_rect()) and map_button.get_global_rect().end.y <= clock.position.y, label + ": hidden map keeps a reachable reopen button above the clock")
	var layers: Control = hud.get_node("%LayersPanel")
	if layers.visible:
		check(screen.encloses(layers.get_global_rect()) and layers.get_global_rect().end.y <= dock.position.y and layers.position.y >= hud.get_node("%StatusBar").get_global_rect().end.y, label + ": Layers fits between the actual header and dock")
		check(hud.welfare_buttons.values().all(func(button): return button.is_visible_in_tree() and layers.get_global_rect().encloses(button.get_global_rect())), label + ": all four relocated city-view buttons remain visible")
	var tray: Control = hud.get_node("%BuildTray")
	if tray.visible:
		check(screen.encloses(tray.get_global_rect()) and tray.get_global_rect().end.y <= dock.position.y, label + ": model tray clears the toolbar and stays inside the viewport")
		check(not hud.get_node("%BuildSearch").is_visible_in_tree(), label + ": category filtering keeps the intentionally hidden search control hidden")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.get_slice("=", 1)
	Engine.set_meta("ezeus_language", language)
	Leaders.create("Toolbar Review")
	Leaders.set_current("Toolbar Review")
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	var fixture := Saves.directory().path_join("toolbar review.ez")
	check(DirAccess.copy_absolute(source, fixture) == OK, "city copied only to a disposable leader profile")
	Engine.set_meta("ezeus_load", fixture)
	Engine.set_meta("ezeus_from_start", true)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	city = load("res://main.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	root.add_child(load("res://scripts/review_input_gate.gd").new())
	while city.state.is_empty(): await process_frame
	city.core.query("pause 1")
	city.core.set_process(false)
	city.set_process(false)
	city.core.commands.clear()
	city.close_inspection()
	city.hud.set_decision({}, 0)
	city.hud.set_messages_open(false)
	city.hud.set_goals_expanded(false)
	city.set_tool("select")
	city.hud.close_build_tray()
	await frames(20)
	var hud: Control = city.hud
	var before: Dictionary = city.core.simulation.snapshot(true)
	if "--context-only" in OS.get_cmdline_user_args():
		await context_checks()
		var after: Dictionary = city.core.simulation.snapshot(true)
		before.erase("sequence")
		after.erase("sequence")
		check(before == after and city.core.commands.is_empty(), "category availability, clicks, hover and scaling leave every native game-state field unchanged")
		check(FileAccess.get_sha256(fixture) == FileAccess.get_sha256(source), "copied city remains byte-identical to the protected source")
		await finish()
		return
	if "--previews-only" in OS.get_cmdline_user_args():
		await preview_checks()
		var after: Dictionary = city.core.simulation.snapshot(true)
		# Snapshot sequence advances on observation; every native game-state field must agree.
		before.erase("sequence")
		after.erase("sequence")
		if before != after: print("TOOLBAR_PREVIEW_STATE_DIFF ", str(before.keys().filter(func(field): return before[field] != after.get(field))))
		check(before == after, "catalog assembly, rendering, hovering and selection leave every native game-state field unchanged")
		check(FileAccess.get_sha256(fixture) == FileAccess.get_sha256(source), "copied city is never saved or overwritten during the review")
		await finish()
		return
	var native_groups: Array = Catalog.groups(city.core.query("buildable").get("buildings", []), Catalog.placeholders_wanted(), city.core.query("trade_partners").get("partners", []))
	check(hud.build_groups == native_groups and not hud.build_groups.is_empty(), "all available categories retain the exact native build catalog")
	check(hud.get_node("%Tools") is VBoxContainer and hud.get_node("%Categories") is HBoxContainer, "construction categories and utilities occupy separate authored rows")
	check(not hud.tool_buttons.select.visible and hud.tool_buttons.house.visible and hud.tool_buttons.roadblock.visible and not hud.build_menu.visible, "Inspect and Build tabs are removed; housing and roadblock shortcuts are visible")
	check(not hud.get_node("%StatusBar").is_ancestor_of(hud.get_node("%WelfareGroup")) and hud.get_node("%LayersPanel").is_ancestor_of(hud.get_node("%WelfareGroup")), "the upper-left City views strip moves inside Layers")
	check(hud.undo_button.get_index() == 0 and hud.tool_buttons.house.get_index() < hud.tool_buttons.road.get_index(), "Undo is first on the left, followed by housing, road, roadblock and demolition")
	check(toolbar_buttons().all(func(button): return button.get_script() != null and button.get_script().resource_path == "res://ui/toolbar_button.gd" and not button.tooltip_text.is_empty() and not String(button.help_detail).is_empty()), "every visible toolbar control has named custom hover help")
	check(hud.get_node("%OverlayMenu").text == tr("Overlays"), "Layers keeps its translated label")
	check(hud.get_node("%Jobs").get_parent() == hud.overlay_menu.get_parent() and hud.get_node("%Jobs").get_index() == hud.overlay_menu.get_index()+1 and not hud.get_node("%StatusBar").is_ancestor_of(hud.get_node("%Jobs")), "Jobs follows Layers in the bottom main row")
	for spec in [["house","build_house"],["road","build_road"],["roadblock","build_roadblock"],["demolish","demolish"]]:
		check(hud.tool_buttons[spec[0]].tooltip_text.contains(Bindings.label(spec[1])), spec[0]+": hover help shows its current working shortcut")
	check(hud.tool_buttons.demolish.tooltip_text.contains(Bindings.text(KEY_DELETE)) and hud.overlay_menu.tooltip_text.contains(Bindings.label("layers")) and hud.get_node("%Jobs").tooltip_text.contains(Bindings.label("jobs")), "main-row hover help includes Layers, Jobs and the alternate demolition key")
	var icon_paths: Array = hud.category_buttons.values().filter(func(button): return not button.disabled).map(func(button): return button.icon.resource_path if button.icon != null else "")
	var unique_paths: Dictionary = {}
	for path in icon_paths: unique_paths[path] = true
	check(unique_paths.size() == icon_paths.size() and icon_paths.all(func(path): return String(path).begins_with("res://ui/toolbar_icons/") and String(path).ends_with(".svg")), "every available building category has its own original illustrated icon")
	check(hud.category_buttons.values().all(func(button): return button.get_theme_color("icon_normal_color") == Color.WHITE), "colored category artwork is not tinted into identical gold glyphs")
	bounds("1920 × 1080 default")
	await capture("default")
	# Each category follows its actual GUI button and exposes the same available native models.
	for group in hud.build_groups:
		var button: Button = hud.category_buttons[group.title]
		hud.get_node("%CategoryScroll").ensure_control_visible(button)
		await frames(3)
		var prior_category: String = hud.active_category
		await hover(button)
		var hover_ok: bool = hud.toolbar_hovered == button and hud.get_node("%ToolbarContext").text == tr(group.title) and hud.active_category == prior_category
		if not hover_ok:
			var focus := root.gui_get_focus_owner()
			print("TOOLBAR_HOVER_DIAG ", JSON.stringify({"expected":str(button.get_path()), "expected_title":button.tooltip_text, "expected_rect":str(button.get_global_rect()), "hovered":str(hud.toolbar_hovered.get_path()) if is_instance_valid(hud.toolbar_hovered) else "none", "context":hud.get_node("%ToolbarContext").text, "focus":str(focus.get_path()) if focus != null else "none", "prior_category":prior_category, "actual_category":hud.active_category, "viewport_mouse":str(root.get_mouse_position()), "desktop_mouse":str(DisplayServer.mouse_get_position()), "window_position":str(DisplayServer.window_get_position()), "category_scroll":hud.get_node("%CategoryScroll").scroll_horizontal}))
		check(hover_ok, group.title + ": hover identifies the translated category immediately without selecting it")
		await click(button)
		var expected: Array = group.items.map(func(item): return item.name)
		check(hud.get_node("%BuildTray").visible and hud.active_category == group.title and hud.building_cards.size() == expected.size() and expected.all(func(name): return hud.building_cards.has(name)), group.title + ": clicking opens precisely its native building cards")
		check(button.button_pressed and hud.category_buttons.values().filter(func(category): return category.button_pressed).size() == 1, group.title + ": a single selected category marker matches its visible tray")
		check(button.tooltip_text == tr(group.title), group.title + ": full translated title remains available to the native tooltip")
		if group.title == "Walls and defence": await capture("walls")
	# Hover must remain read-only, including over a different category while the selected tray is open.
	var selected_category: String = hud.active_category
	var select_mode: String = hud.current_tool
	var hover_button: Button = hud.category_buttons.values()[0]
	hud.get_node("%CategoryScroll").ensure_control_visible(hover_button)
	await frames(3)
	await hover(hover_button)
	check(hud.active_category == selected_category and hud.current_tool == select_mode and city.core.commands.is_empty(), "hovering another category does not select a tool, switch the tray, or queue native actions")
	await move_to(Vector2(hud.size.x * .5, hud.size.y * .4))
	hud.close_build_tray()
	var keyboard_category: String = String(hud.build_groups[0].title)
	var keyboard_button: Button = hud.category_buttons[keyboard_category]
	city.orbit.dragging = true
	keyboard_button.grab_focus()
	await frames()
	check(hud.toolbar_has_focus() and city.orbit.toolbar_input_blocked and hud.get_node("%ToolbarContext").text == tr(keyboard_category), "keyboard focus identifies the category and blocks camera navigation")
	check(not city.orbit.dragging, "acquiring toolbar keyboard focus clears a preexisting camera drag")
	var old_target: Vector3 = city.orbit.target
	var old_yaw: float = city.orbit.yaw
	var camera_key := InputEventKey.new()
	camera_key.physical_keycode = KEY_Q
	camera_key.pressed = true
	city.orbit._unhandled_input(camera_key)
	city.orbit._process(.1)
	check(city.orbit.target == old_target and city.orbit.yaw == old_yaw, "camera does not orbit while the toolbar owns keyboard input")
	await key(KEY_ENTER)
	check(hud.active_category == keyboard_category and hud.get_node("%BuildTray").visible, "Enter on a focused category opens its native model tray")
	var item: Dictionary = hud.build_groups[0].items[0]
	await click(hud.building_cards[item.name])
	check(hud.current_tool == item.name and city.mode == String(item.name).get_slice(":", 0) and hud.building_cards[item.name].button_pressed, "clicking a model retains its original placement callback and selected marker")
	check(not hud.toolbar_has_focus() and not city.orbit.toolbar_input_blocked, "pointer selection of a model releases the category keyboard focus and camera hold")
	await capture("models")
	# Escape returns keyboard-driven construction browsing to the city rather than retaining an invisible hold.
	hud.close_build_tray()
	keyboard_button.grab_focus()
	await key(KEY_ENTER)
	check(hud.get_node("%BuildTray").visible and hud.toolbar_has_focus() and city.orbit.toolbar_input_blocked, "keyboard category activation holds input while its tray is open")
	await key(KEY_ESCAPE)
	check(not hud.get_node("%BuildTray").visible and not hud.toolbar_has_focus() and not city.orbit.toolbar_input_blocked and city.mode == String(item.name).get_slice(":", 0) and hud.current_tool == item.name, "Escape closes a keyboard-opened tray, releases toolbar and camera holds, and preserves the selected construction tool")
	keyboard_button.grab_focus()
	await key(KEY_ENTER)
	# An identical catalog refresh preserves the existing controls, focus, and scroll positions.
	var category_id: int = keyboard_button.get_instance_id()
	var card_id: int = hud.building_cards[item.name].get_instance_id()
	var building_scroll: ScrollContainer = hud.get_node("%BuildingScroll")
	building_scroll.scroll_horizontal = 40
	await frames()
	var scroll_before: int = building_scroll.scroll_horizontal
	keyboard_button.grab_focus()
	hud.set_catalog(hud.build_groups.duplicate(true))
	await frames()
	check(hud.category_buttons[keyboard_category].get_instance_id() == category_id and hud.building_cards[item.name].get_instance_id() == card_id and building_scroll.scroll_horizontal == scroll_before and root.gui_get_focus_owner() == keyboard_button, "unchanged native catalog preserves card controls, scroll position, and keyboard focus")
	# Direct tools retain their existing signal-to-city callback, without placing or demolishing anything.
	for tool in ["house", "road", "roadblock", "demolish"]:
		await click(hud.tool_buttons[tool])
		check(city.mode == tool and hud.current_tool == tool and hud.tool_buttons[tool].button_pressed and city.core.commands.is_empty(), tool + ": direct tool callback selects precisely the original native mode")
	# New shortcuts use the same native availability and tool callbacks as the buttons.
	city.set_tool("select")
	await move_to(Vector2(hud.size.x*.5,hud.size.y*.25))
	for spec in [[KEY_H,"house"],[KEY_B,"road"],[KEY_G,"roadblock"],[KEY_X,"demolish"]]:
		await key(spec[0])
		check(city.mode == spec[1] and hud.current_tool == spec[1] and city.core.commands.is_empty(), spec[1]+": physical shortcut selects the native tool without constructing anything")
	city.set_tool("select")
	await key(KEY_L)
	check(hud.get_node("%LayersPanel").visible and city.orbit.toolbar_input_blocked, "L opens Layers and protects camera input")
	await key(KEY_J)
	check(hud.current_overlay == "industry" and not hud.get_node("%LayersPanel").visible and not city.orbit.toolbar_input_blocked, "J selects the native Jobs view and closes Layers")
	hud.activate_overlay("normal")
	city.core.commands.clear()
	# Rebindings refresh the footer help even with the native simulation frozen.
	Bindings.assign("build_house",KEY_K)
	Bindings.assign("jobs",KEY_P)
	hud.retranslate()
	check(hud.tool_buttons.house.tooltip_text.contains("[K]") and hud.get_node("%Jobs").tooltip_text.contains("[P]"), "rebound Housing and Jobs shortcuts immediately update hover help")
	await key(KEY_K)
	check(city.mode == "house" and city.core.commands.is_empty(), "rebound Housing key follows the actual callback")
	Bindings.reset_all()
	hud.retranslate()
	keyboard_button = hud.category_buttons[keyboard_category]
	city.set_tool("select")
	hud.set_minimap_open(false)
	await click(hud.get_node("%MapToggle"))
	check(hud.get_node("%MapToggle").button_pressed and hud.get_node("%MinimapPanel").visible and not hud.get_node("%MapToggle").visible, "map utility retains the native map visibility callback")
	await click(hud.get_node("%MapClose"))
	check(not hud.get_node("%MapToggle").button_pressed and not hud.get_node("%MinimapPanel").visible, "map utility folds the map without changing the selected tool")
	# The availability fixture verifies only the Undo button route; queued undo is never executed.
	hud.set_undo_available(false)
	var undo: Button = hud.get_node("%Undo")
	var unavailable_help: String = undo.help_detail
	await hover(undo)
	await click(undo)
	check(undo.disabled and city.core.commands.is_empty() and not unavailable_help.is_empty(), "disabled Undo explains its availability and cannot queue an action")
	hud.set_undo_available(true)
	check(not undo.disabled and undo.help_detail != unavailable_help and undo.tooltip_text.contains(Bindings.label("undo")), "enabled Undo explains its construction action and current shortcut")
	await click(undo)
	check(city.core.commands == ["undo"], "enabled Undo queues exactly the existing native undo callback")
	city.core.commands.clear()
	hud.set_undo_available(bool(before.get("undo_available", false)))
	# Categories retain every native building route after removing the duplicate Build tab.
	var routed: String = String(hud.build_groups[-1].items[-1].name)
	check(hud.activate_building(routed) and hud.current_tool == routed and city.mode == routed.get_slice(":", 0), "retained catalog activation uses the original native building callback")
	city.set_tool("select")
	hud.overlay_menu.grab_focus()
	await frames()
	await key(KEY_ENTER)
	check(hud.get_node("%LayersPanel").visible and hud.toolbar_has_focus() and city.orbit.toolbar_input_blocked, "keyboard-opened Layers owns camera input while its panel is open")
	hud.welfare_buttons.water.grab_focus()
	await key(KEY_ENTER)
	check(hud.current_overlay == "water" and city.overlay_view.mode == "water" and not hud.get_node("%LayersPanel").visible and not hud.toolbar_has_focus() and not city.orbit.toolbar_input_blocked, "keyboard Water selection closes Layers and releases camera input")
	city.core.commands.clear()
	for view in ["supplies", "water", "hygiene", "hazards"]:
		await click(hud.overlay_menu)
		await click(hud.welfare_buttons[view])
		check(hud.current_overlay == view and city.overlay_view.mode == view and not hud.get_node("%LayersPanel").visible and hud.welfare_buttons[view].button_pressed, view + ": relocated quick button selects its exact native view and closes Layers")
		city.core.commands.clear()
	check(hud.layer_buttons.size() + hud.welfare_buttons.size() == hud.Overlays.MODES.size(), "Layers contains every native overlay, including culture and science")
	await click(hud.overlay_menu)
	hud.get_node("%LayerScroll").ensure_control_visible(hud.layer_buttons.actors)
	await frames()
	await click(hud.layer_buttons.actors)
	check(hud.current_overlay == "actors" and city.overlay_view.mode == "actors" and not hud.get_node("%LayersPanel").visible, "the Culture actors button retains its exact native callback")
	city.core.commands.clear()
	await click(hud.overlay_menu)
	await key(KEY_ESCAPE)
	check(not hud.get_node("%LayersPanel").visible and not hud.toolbar_has_focus() and not city.orbit.toolbar_input_blocked and not is_instance_valid(city.escape_menu), "Escape closes Layers before opening a game menu and restores camera input")
	await click(hud.overlay_menu)
	await click(hud.get_node("%LayersClose"))
	check(not hud.get_node("%LayersPanel").visible and not hud.overlay_menu.button_pressed, "Layers Close clears its disclosure and selected tab marker")
	city.set_tool("house")
	await click(hud.overlay_menu)
	await move_to(Vector2(hud.size.x*.5,hud.size.y*.25))
	var outside := InputEventMouseButton.new()
	outside.position = root.get_mouse_position()
	outside.button_index = MOUSE_BUTTON_LEFT
	outside.pressed = true
	outside.set_meta("review_input",true)
	root.push_input(outside,true)
	await frames(2)
	outside = outside.duplicate()
	outside.pressed = false
	root.push_input(outside,true)
	await frames()
	check(not hud.get_node("%LayersPanel").visible and city.mode == "house" and city.core.commands.is_empty(), "clicking terrain dismisses Layers without placing the active housing tool")
	city.set_tool("select")
	city.open_army()
	await frames()
	check(not city.army_panel.banners.is_empty(), "a native army company is available for the Layers dismissal interaction")
	if not city.army_panel.banners.is_empty():
		var banner_id: int = int(city.army_panel.banners[0].id)
		city.army_panel.select(banner_id,false)
		await click(hud.overlay_menu)
		check(hud.get_node("%LayersPanel").get_index() > city.army_panel.get_index() and hud.get_node("%LayersPanel").get_index() < hud.get_node("%DecisionShade").get_index(), "Layers draws and picks above the dynamic Army inspector while required decisions remain above it")
		await click(hud.get_node("%LayersClose"))
		check(not hud.get_node("%LayersPanel").visible and city.army_panel.visible and city.army_panel.selected_id == banner_id and city.core.commands.is_empty(), "Layers Close remains clickable over an open Army inspector without changing its native selection")
		await click(hud.overlay_menu)
		await move_to(Vector2(100,250))
		for pressed in [true,false]:
			var right := InputEventMouseButton.new()
			right.position = root.get_mouse_position()
			right.button_index = MOUSE_BUTTON_RIGHT
			right.pressed = pressed
			right.set_meta("review_input",true)
			root.push_input(right,true)
			if pressed: await frames(2)
		await frames()
		check(not hud.get_node("%LayersPanel").visible and city.army_panel.selected_id == banner_id and city.core.commands.is_empty(), "right click dismisses Layers before a selected native company can receive a terrain order")
	city.army_panel.select(-1,false)
	city.army_panel.close()
	await click(hud.overlay_menu)
	hud.get_node("%Jobs").grab_focus()
	await key(KEY_ENTER)
	check(hud.current_overlay == "industry" and not hud.get_node("%LayersPanel").visible and not city.orbit.toolbar_input_blocked, "keyboard Jobs selection closes Layers and returns camera input")
	hud.activate_overlay("normal")
	city.core.commands.clear()
	await frames()
	# A custom tooltip is shown as a local fixture because native tooltip windows are outside viewport captures.
	hud.close_build_tray()
	city.set_tool("select")
	await frames()
	hud.get_node("%CategoryScroll").ensure_control_visible(keyboard_button)
	await frames()
	await hover(keyboard_button)
	check(hud.toolbar_hovered == keyboard_button and hud.get_node("%ToolbarContext").text == tr(keyboard_category), "tooltip capture first observes the real translated hover label")
	await move_to(Vector2(hud.size.x * .5, hud.size.y * .4))
	var tooltip: Control = keyboard_button._make_custom_tooltip(keyboard_button.tooltip_text)
	hud.add_child(tooltip)
	await frames()
	var dock: Rect2 = hud.get_node("%BottomBar").get_global_rect()
	tooltip.position = Vector2(keyboard_button.get_global_rect().position.x, dock.position.y - tooltip.size.y - 12).clamp(Vector2(12, 72), hud.size - tooltip.size - Vector2(12, 12))
	check(ignores_pointer(tooltip) and tooltip.size.x <= minf(360, hud.size.x - 48) + 2, "custom category tooltip is bounded and passes pointer input through")
	var labels: Array = tooltip.find_children("*", "Label", true, false)
	check(labels.any(func(label): return label.text == tr(keyboard_category)) and labels.any(func(label): return label.text == keyboard_button.help_detail), "custom tooltip includes the exact translated title and explanatory help")
	await capture("hover-help")
	tooltip.queue_free()
	await frames()
	hud.set_minimap_open(true)
	# Independent UI/text sizes, including category scroll and the native model tray at a small window.
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		DisplayServer.window_set_size(dimensions)
		for sizing in [Vector2i(100, 100), Vector2i(125, 130)]:
			root.get_node("UiAccess").apply(sizing.x, sizing.y)
			await frames(24)
			hud.close_build_tray()
			hud.open_category(keyboard_category)
			await frames()
			bounds(str(dimensions) + " " + str(sizing))
			await capture("%d-%d" % [dimensions.x, sizing.x])
			await click(hud.overlay_menu)
			await frames()
			bounds(str(dimensions) + " " + str(sizing) + " Layers")
			await capture("layers-%d-%d" % [dimensions.x, sizing.x])
			hud.get_node("%LayerScroll").ensure_control_visible(hud.layer_buttons.all_science)
			await frames()
			await click(hud.layer_buttons.all_science)
			check(hud.current_overlay == "all_science" and not hud.get_node("%LayersPanel").visible, "last native science choice is reachable at " + str(dimensions) + " " + str(sizing))
			city.core.commands.clear()
			hud.activate_overlay("normal")
			city.core.commands.clear()
	root.get_node("UiAccess").apply(100, 100)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city.set_tool("select")
	hud.set_minimap_open(true)
	await frames(24)
	await move_to(Vector2(70,160))
	await capture("rearranged")
	await click(hud.overlay_menu)
	await move_to(Vector2(hud.size.x*.5,hud.size.y*.25))
	await capture("layers")
	hud.set_layers_open(false)
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(before.time == after.time and before.money == after.money and before.buildings == after.buildings and before.city_header == after.city_header, "hover, keyboard navigation, category/model selection, and scaling leave native time, treasury, and buildings unchanged")
	check(FileAccess.get_sha256(fixture) == FileAccess.get_sha256(source), "copied city is never saved or overwritten during the review")
	await finish()
