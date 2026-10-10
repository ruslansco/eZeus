extends SceneTree
# Native read-only header data over a disposable full city. Pause/speed callbacks queue but never execute.
const Saves = preload("res://scripts/save_files.gd")
const Leaders = preload("res://scripts/leaders.gd")
const Bindings = preload("res://scripts/key_bindings.gd")
const Objective = preload("res://ui/objective_card.gd")
const HEADER_CAPTIONS := {"HousingCaption":"Housing", "TreasuryCaption":"Treasury", "MonthlyCaption":"Monthly balance", "PopulationCaption":"Population", "TimeCaption":"Date", "SpeedCaption":"Speed", "CityCaption":"Current city"}
var city: Node
var language := "en"
var checks := 0
var okay := true
var army_native := false
var notifications_only := false

class NoticeReviewHost extends Node:
	var hud: Control
	var core := {"commands":[]}
	var state := {"paused":true}

func _initialize() -> void:
	Engine.set_meta("ezeus_settings_path", OS.get_environment("EZEUS_REVIEW_SETTINGS_PATH"))
	Engine.set_meta("ezeus_save_directory", OS.get_environment("EZEUS_REVIEW_SAVE_DIRECTORY"))
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	okay = okay and value
	print("CHROME_CHECK ", "PASS " if value else "FAIL ", description)

func frames(count := 8) -> void:
	for i in count: await process_frame

func click(control: Control, button := MOUSE_BUTTON_LEFT) -> void:
	DisplayServer.window_move_to_foreground()
	await frames(3)
	# Godot rechecks hover against the physical cursor between down/up frames.
	# Keep it aligned with the marked injected event, as the toolbar review does.
	root.warp_mouse(control.get_global_rect().get_center())
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_rect().get_center()
	motion.set_meta("review_input", true)
	root.push_input(motion, true)
	await frames(3)
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = button
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
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://captures/chrome-%s-%s.png" % [language, label])

func bounds(label: String) -> void:
	var hud: Control = city.hud
	var screen := Rect2(Vector2.ZERO, hud.size)
	var ribbon: Rect2 = hud.get_node("%ResourceRibbon").get_global_rect()
	print("CHROME_LAYOUT ", JSON.stringify({"label":label, "viewport":str(hud.size), "overview":str(ribbon), "ui_size":root.get_node("UiAccess").ui_size, "text_size":root.get_node("UiAccess").text_size}))
	check(screen.encloses(ribbon), label + ": overview surface stays inside the viewport")
	var natural_width: float = hud.get_node("%CityPlaque").get_combined_minimum_size().x + hud.get_node("%StatsGroup").get_combined_minimum_size().x + 12 + hud.get_node("%ResourceRibbon").get_theme_stylebox("panel").get_minimum_size().x
	check(is_equal_approx(ribbon.position.x,16) and absf(ribbon.size.x-minf(hud.size.x-32,natural_width)) < 2, label + ": upper-left overview fits its content without the former empty span")
	check(is_equal_approx(hud.get_node("%ResourceRibbon").get_theme_stylebox("panel").bg_color.a,.9) and hud.get_node("%CityName").modulate.a == 1 and hud.treasury_label.modulate.a == 1, label + ": only the overview background is softened to 90 percent opacity")
	var controls: Array = [hud.treasury_label,hud.population_label,hud.get_node("%HousingText"),hud.get_node("%Income"),hud.get_node("%ResourcesToggle")]
	check(controls.all(func(control): return control.is_visible_in_tree() and ribbon.encloses(control.get_global_rect())), label + ": housing, money, population and resources fit the overview")
	var time: Rect2 = hud.get_node("%TimeBar").get_global_rect()
	var time_controls: Array = [hud.date_label,hud.pause_button]
	time_controls.append_array(hud.speed_buttons)
	check(screen.encloses(time) and not time.intersects(ribbon) and time_controls.all(func(control): return control.is_visible_in_tree() and time.encloses(control.get_global_rect())), label + ": pause, date and all speeds fit the separate bottom-left clock")
	check(hud.date_label.get_global_rect().position.y >= hud.pause_button.get_global_rect().end.y and (not hud.get_node("%MinimapPanel").visible or hud.get_node("%MinimapPanel").get_global_rect().end.y < time.position.y), label + ": speeds sit next to Play above the date, beneath the open map")
	check(hud.get_node("%BottomBar").get_global_rect().encloses(hud.get_node("%Jobs").get_global_rect()) and not ribbon.intersects(hud.get_node("%Jobs").get_global_rect()), label + ": Jobs fits after Layers in the bottom dock")
	var readable: Array = [hud.date_label, hud.treasury_label, hud.population_label, hud.get_node("%HousingText"), hud.get_node("%Income")]
	check(readable.all(func(control): return control.get_theme_font("font").get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size("font_size")).x <= control.size.x + 2), label + ": native dates and numbers fit their visible label widths")
	if hud.resources_open:
		var resources: Rect2 = hud.get_node("%ResourcesPanel").get_global_rect()
		check(screen.encloses(resources) and hud.resource_buttons.values().all(func(button): return button.is_visible_in_tree() and resources.encloses(button.get_global_rect())), label + ": expanded resources retain every stock item without clipping")
		check(not resources.intersects(ribbon), label + ": stock rows clear the overview after moving welfare controls into Layers")
		check(is_equal_approx(resources.position.x,ribbon.position.x), label + ": stocks open beneath the same upper-left strip")

func notification_checks(label: String) -> void:
	# The Russian fixture is the full message in the user's recording. English
	# stresses the same layout; neither fixture is injected into native events.
	var hud: Control = city.hud
	var title := "Истмийские игры закончились" if language == "ru" else "The Isthmian Games have ended"
	var text := "Какой позор для всего города, о Ruslan! Ваши философы выставили себя глупцами на Истмийских играх. Все смеялись над их речами! Если вы не хотите, чтобы вас опозорили и на следующих играх — постройте побольше академий и трибун!" if language == "ru" else "Your philosophers have returned from the Isthmian Games. Review their report and prepare your city for the next competition. Build academies and podiums to support their education."
	var short_text := "Нехватка жилья препятствует иммиграции" if language == "ru" else "Lack of housing hinders immigration"
	hud.show_toast(900010,"City",short_text)
	var short_card: Control = hud.toasts.get_child(0)
	root.warp_mouse(Vector2(16,200))
	await frames(24)
	check(short_card.heading == null and short_card.find_children("*","Button",true,false).is_empty() and short_card.body_scroll.get_child(0).text == short_text and short_card.size.y <= short_card.body_scroll.size.y + 24, label + ": instant notice is a slim message strip without title or Close")
	await capture(label + "-slim-notice")
	await click(short_card,MOUSE_BUTTON_RIGHT)
	check(hud.toasts.get_child_count() == 0 and city.core.commands == ["event 900010 -1"], label + ": right-click dismisses the slim notice through its original information callback")
	city.core.commands.clear()
	hud.show_toast(900011,title,text)
	var card: Control = hud.toasts.get_child(0)
	card.lifetime = 120; card.remaining = 120
	await frames(60)
	var width: float = card.size.x
	check(card.size.x >= hud.toasts.size.x-2 and card.body_scroll.size.x > 350 and hud.size.x > width and not card.get_global_rect().intersects(hud.get_node("%ResourceRibbon").get_global_rect()), label + ": notice stays readable below the compact header after 60 frames")
	check(card.body_scroll.get_child(0).text == text and card.body_scroll.get_child(0).get_theme_font_size("font_size") == root.get_node("UiAccess").shared.get_font_size("font_size","NoticeBody"), label + ": complete notice text respects the shared text-size preference")
	await capture(label + "-notice")
	await click(card)
	var remaining: float = card.remaining
	await frames(60)
	card._process(2)
	check(card.expanded and card.remaining == remaining and is_equal_approx(card.size.x,width), label + ": real message click pins reading and keeps the full width and timer")
	hud.show_toast(900012,"Queued report",text)
	check(hud.toasts.get_child_count() == 1 and hud.toasts.get_child(0) == card and hud.alert_queue.size() == 1, label + ": a later arrival queues without replacing the report being read")
	card.update_text(title,text.repeat(12),"")
	await frames(30)
	card.body_scroll.scroll_vertical = 100000
	await frames()
	var body: Label = card.body_scroll.get_child(0)
	var bar: VScrollBar = card.body_scroll.get_v_scroll_bar()
	check(body.text == text.repeat(12) and bar.max_value > bar.page and bar.value+bar.page >= bar.max_value-1, label + ": the final words of a long report remain reachable by scrolling")
	var reading_position: int = card.body_scroll.scroll_vertical
	card.update_text(title,body.text,"")
	await frames(30)
	check(card.body_scroll.scroll_vertical == reading_position and is_equal_approx(card.size.x,width), label + ": unchanged refresh preserves the reading position and width")
	await click(card)
	await frames(30)
	check(not card.expanded and card.body_scroll.visible and is_equal_approx(card.size.x,width), label + ": unpinning retains the complete readable open notice")
	# A hidden alert must retain its reading allowance while the journal is open.
	hud.set_messages_open(true)
	await frames()
	remaining = card.remaining
	card._process(2)
	check(not hud.get_node("%ToastScroll").visible and card.remaining == remaining, label + ": opening the journal holds the hidden report's timer")
	hud.set_messages_open(false)
	await frames()
	# Use real right-click input and inspect/discard its informational ack; never execute it.
	await click(card,MOUSE_BUTTON_RIGHT)
	check(hud.toasts.get_child_count() == 1 and hud.toasts.get_child(0).message_id == 900012 and hud.alert_queue.is_empty() and city.core.commands == ["event 900011 -1"], label + ": right-click dismisses only the visible information and advances the queued report")
	city.core.commands.clear()
	var next: Control = hud.toasts.get_child(0)
	await click(next,MOUSE_BUTTON_RIGHT)
	check(hud.toasts.get_child_count() == 0 and city.core.commands == ["event 900012 -1"] and city.state.paused, label + ": clearing informational reports preserves the city's paused state")
	city.core.commands.clear()
	hud.show_toast(900013,"City",short_text)
	await frames()
	root.warp_mouse(Vector2(16,200))
	await frames()
	var expiring: Control = hud.toasts.get_child(0)
	expiring.remaining = .01
	expiring._process(.02)
	check(hud.toasts.get_child_count() == 0 and city.core.commands == ["event 900013 -1"], label + ": unread slim notice still expires through its original information callback")
	city.core.commands.clear()

func native_values(before: Dictionary) -> void:
	var hud: Control = city.hud
	var header: Dictionary = before.city_header
	check(hud.city_header == header and hud.get_node("%CityName").text == str(header.name) and hud.get_node("%CityName").tooltip_text == str(header.name), "current native city and cached header remain exact")
	var signed_money: String = ("−" if int(before.money) < 0 else "") + hud.group_digits(absi(int(before.money)))
	check(hud.treasury_label.text.contains(signed_money) and hud.treasury_label.tooltip_text.contains(signed_money), "treasury displays the exact signed native amount with complete hover text")
	check(hud.population_label.text.contains(hud.group_digits(int(before.population))) and not hud.get_node("%Citizens").tooltip_text.is_empty(), "population retains its exact native count and explanatory hover text")
	var housing: Dictionary = header.get("housing", {})
	var free: int = int(housing.get("vacancies", 0))
	var total: int = int(housing.get("people", 0)) + free
	var housing_tip: String = hud.get_node("%Housing").tooltip_text
	check(hud.get_node("%HousingText").text == tr("%s free / %s") % [hud.group_digits(free), hud.group_digits(total)] and housing_tip.contains(hud.group_digits(free)) and housing_tip.contains(hud.group_digits(total)), "housing explicitly identifies native free places and retains the exact capacity explanation")
	check(is_equal_approx(float(hud.get_node("%HousingGauge").value), float(int(housing.get("people", 0))) / total if total > 0 else 0.0), "housing gauge still follows native residents and vacancies")
	var monthly: int = hud.monthly_balance(header.get("finances", {}), before.date)
	var balance: String = ("+" if monthly >= 0 else "−") + hud.group_digits(absi(monthly))
	check(hud.get_node("%Income").text.contains(balance) and hud.get_node("%Money").tooltip_text.contains(balance), "monthly balance preserves the existing native-ledger calculation and signed explanation")
	check(hud.date_label.text.contains(str(int(before.date[0]))) and hud.date_label.text.contains(str(absi(int(before.date[2])))), "date preserves the native day and year")
	var employment: Dictionary = header.get("employment", {})
	check(not hud.get_node("%Jobs").disabled and ["employed", "employable", "vacancies", "unemployed"].all(func(field): return hud.get_node("%Jobs").tooltip_text.contains(str(int(employment.get(field, 0)))) or hud.get_node("%Jobs").tooltip_text.contains(hud.group_digits(int(employment.get(field, 0))))), "jobs retain all native employment figures in hover text")
	var stocks: Array = header.get("stock", [])
	check(hud.resource_buttons.size() == stocks.size() and stocks.all(func(stock): return hud.resource_buttons.has(int(stock.resource)) and not hud.resource_buttons[int(stock.resource)].disabled and hud.resource_buttons[int(stock.resource)].text == hud.group_digits(int(stock.count))), "all native resource counts remain exact, including zeros")

func check_world_stocks(before: Dictionary) -> void:
	# worldInfo is a gift catalog: eGiftHelpers filters native goods and includes drachmas (1<<23).
	# Header stock deliberately excludes drachmas; eBoardCity::resourceCount returns the owning player's treasury for it.
	var header: Dictionary = before.city_header
	var world: Dictionary = city.core.query("world")
	var mine: Dictionary = world.mine.filter(func(current): return current.current)[0]
	var header_stock := {}
	var world_stock := {}
	for stock in header.stock: header_stock[int(stock.resource)] = int(stock.count)
	for stock in mine.stock: world_stock[int(stock.resource)] = int(stock.count)
	var mismatches: Array = []
	var compared := 0
	for resource in world_stock:
		var expected: int = int(before.money) if resource == (1 << 23) else int(header_stock.get(resource, -999999999))
		if resource != (1 << 23): compared += 1
		if world_stock[resource] != expected: mismatches.append({"resource":resource, "world":world_stock[resource], "expected":expected})
	var food_method := "merged"
	if world_stock.has(255):
		if world_stock[255] != header_stock[255]: mismatches.append({"resource":255, "world":world_stock[255], "expected":header_stock[255]})
	elif range(8).all(func(bit): return world_stock.has(1 << bit)):
		food_method = "eight individual food types"
		var food := 0
		for bit in 8: food += int(world_stock[1 << bit])
		if food != header_stock[255]: mismatches.append({"resource":255, "world_sum":food, "expected":header_stock[255]})
	else:
		food_method = "incomplete"
		mismatches.append({"food":"world gift catalog cannot independently represent all food"})
	print("CHROME_WORLD_STOCK ", JSON.stringify({"header_city":header.id, "world_city":mine.id, "gift_resource_ids":world_stock.keys(), "common_goods_compared":compared, "food_representation":food_method, "mismatches":mismatches}))
	check(compared > 0 and mismatches.is_empty() and int(mine.id) == int(header.id) and int(world.treasury) == int(before.money), "giftable stocks and food independently match the native world query, with drachmas matched to treasury")

func panel_checks(label: String, building: Dictionary) -> void:
	var hud: Control = city.hud
	var screen := Rect2(Vector2.ZERO, hud.size)
	city.close_inspection()
	city.game_action("army")
	await frames(16)
	var army = city.army_panel
	check(army.visible and army.rows.size() == city.banners.size() and army.title.text == tr("Army"), label + ": Army opens with every native company and its translated heading")
	if not city.banners.is_empty():
		army.select(int(city.banners[0].id))
		await frames(16)
	var army_rect: Rect2 = army.get_global_rect()
	check(screen.encloses(army_rect) and army_rect.position.y >= hud.get_node("%ResourceRibbon").get_global_rect().end.y and army_rect.end.y <= hud.get_node("%BottomBar").get_global_rect().position.y, label + ": Army fits between actual header and dock")
	var header_rect: Rect2 = army.header.get_global_rect()
	army.content.scroll_vertical = 100000
	await frames()
	check(army.header.get_global_rect() == header_rect and army_rect.encloses(army.close_button.get_global_rect()) and army.content.get_v_scroll_bar().value + army.content.get_v_scroll_bar().page >= army.content.get_v_scroll_bar().max_value - 1, label + ": Army header and Close stay fixed while the final detail can be reached")
	await capture(label + "-army")
	await click(army.close_button)
	check(not army.visible and city.core.commands.is_empty(), label + ": Close returns from Army without issuing an order")
	if building.is_empty():
		check(false, label + ": designated city supplies a native storage inspector")
		return
	city.inspected = Vector2i(int(building.x), int(building.y))
	city.refresh_inspection()
	await frames(16)
	var data: Dictionary = city.core.query("inspect %d %d" % [int(building.x), int(building.y)])
	var inspector_rect: Rect2 = hud.inspector.get_global_rect()
	var inspector_header: Rect2 = hud.get_node("%InspectorHeader").get_global_rect()
	check(hud.inspector.visible and hud.get_node("%InspectorTitle").text == str(data.name) and hud.get_node("%InspectorSubtitle").tooltip_text == tr("City: %s") % str(data.city), label + ": storage inspector heading and city context follow the exact native object")
	var context: Array[String] = []
	var footprint: Array = data.get("footprint", [])
	if footprint.size() >= 4: context.append(tr("%d × %d tiles") % [int(footprint[2]), int(footprint[3])])
	if int(data.get("max_employees", 0)) > 0: context.append(tr("Workers: %d / %d") % [int(data.employees), int(data.max_employees)])
	check(hud.get_node("%InspectorSubtitle").text == (" · ".join(context) if not context.is_empty() else tr("City: %s") % str(data.city)), label + ": inspector footprint and staffing caption follow native observations")
	var rows: Dictionary = city.inspector_controls.rows
	check(not rows.is_empty() and rows.keys().all(func(resource):
		var caption: Label = rows[resource].caption
		return caption.text == city.inspector_controls.resource_name(int(resource)) and caption.tooltip_text == caption.text and caption.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and not caption.clip_text and caption.get_minimum_size().y <= caption.size.y + 1), label + ": every stored-good name wraps fully and retains its native translated hover name")
	check(screen.encloses(inspector_rect) and inspector_rect.encloses(inspector_header) and inspector_rect.end.y <= hud.get_node("%BottomBar").get_global_rect().position.y, label + ": selected inspector clears both header and dock")
	var scroll: ScrollContainer = hud.get_node("%InspectorScroll")
	scroll.scroll_vertical = 100000
	await frames()
	check(scroll.follow_focus and hud.get_node("%InspectorHeader").get_global_rect() == inspector_header and inspector_rect.encloses(hud.get_node("%InspectorClose").get_global_rect()), label + ": inspector navigation follows focus and keeps its title and Close fixed")
	await capture(label + "-inspector")
	await click(hud.get_node("%InspectorClose"))
	city.refresh_inspection()
	check(not hud.inspector.visible and not city.selection.visible and city.core.commands.is_empty(), label + ": closing inspection clears selection and refresh cannot reopen it")

func hub_checks(label: String) -> void:
	var hud: Control = city.hud
	var screen := Rect2(Vector2.ZERO,hud.size)
	var rail: Control = hud.get_node("%EventRail")
	var journal: Button = hud.messages_button
	var goals: Button = hud.get_node("%ObjectivesButton")
	var dock: Rect2 = hud.get_node("%BottomBar").get_global_rect()
	var rail_position := rail.position
	check(not hud.goals_panel.visible and goals.visible and journal.text.is_empty() and goals.text.is_empty(),label+": journal and objectives start as illustrated icons without a permanent goals card")
	check(journal.icon.resource_path.ends_with("notice_journal.svg") and goals.icon.resource_path.ends_with("notice_objectives.svg") and journal.size==goals.size and journal.size.x>=44,label+": distinct colored art shares a consistent reachable hit area")
	hud.set_resources_open(true); await frames(24)
	check(rail.position==rail_position,label+": stock expansion leaves right-side controls in their fixed positions")
	hud.set_resources_open(false); await frames(24)
	await click(goals)
	check(hud.goals_panel.visible and hud.goals_list.visible and goals.button_pressed and hud.goals_list.get_child_count()==hud.goals_state.goals.size(),label+": real Objectives click opens every native goal")
	check(screen.encloses(hud.goals_panel.get_global_rect()) and not hud.goals_panel.get_global_rect().intersects(rail.get_global_rect()) and hud.goals_panel.get_global_rect().end.y<=dock.position.y,label+": objectives fit beside the rail above the dock")
	check(hud.get_node("%BottomBar").get_global_rect()==dock and city.core.commands.is_empty(),label+": reading goals neither shifts construction controls nor queues a native command")
	await capture(label+"-goals")
	await click(hud.goals_toggle)
	check(not hud.goals_panel.visible and not goals.button_pressed,label+": Close folds objectives back to their icon")
	var original: Dictionary = hud.goals_state.duplicate(true)
	var completed: Dictionary = original.duplicate(true)
	completed.met=int(original.met)+1
	hud.set_goals(completed); await frames()
	check(goals.badge=="1",label+": a newly completed goal adds a separate attention badge")
	await click(goals)
	check(goals.badge.is_empty(),label+": opening objectives clears their attention badge")
	hud.set_goals(original)
	await key(KEY_ESCAPE)
	check(not hud.goals_panel.visible and not is_instance_valid(city.escape_menu),label+": Escape closes the objectives disclosure before opening the game menu")
	hud.set_unread(8)
	check(journal.badge=="8" and journal.text.is_empty(),label+": unread count stays separate from the journal illustration")
	await click(journal)
	check(hud.message_panel.visible and journal.button_pressed and not hud.goals_panel.visible,label+": real Journal click opens history and closes the other disclosure")
	var original_entries: Array = hud.journal_entries.duplicate(true)
	var entries := [
		{"id":900101,"kind":"employees","title":"City report","text":"A full routine report.","date":"1 Jan","decision":false},
		{"id":900102,"kind":"fire","title":"Fire","text":"A full warning report.","date":"2 Jan","decision":false},
		{"id":900103,"kind":"request","title":"Request","text":"The full request and its history.","date":"3 Jan","decision":true}]
	hud.set_messages(entries); await frames()
	check(hud.message_list.get_child_count()==3,label+": All reports retains routine events, warnings and decisions")
	await click(hud.journal_filters.warnings)
	check(hud.message_list.get_child_count()==1 and hud.message_list.get_child(0).message_id==900102 and hud.journal_entries==entries,label+": Warnings filters the view without deleting full history")
	await click(hud.journal_filters.decisions)
	check(hud.message_list.get_child_count()==1 and hud.message_list.get_child(0).message_id==900103,label+": Decisions filter preserves the exact required-message history")
	await click(hud.journal_filters.all)
	check(screen.encloses(hud.message_panel.get_global_rect()) and hud.journal_filters.values().all(func(button): return hud.message_panel.get_global_rect().encloses(button.get_global_rect())),label+": journal title, filters and close control fit at the active UI/text scale")
	await capture(label+"-journal")
	hud.set_messages(original_entries)
	await key(KEY_ESCAPE)
	check(not hud.message_panel.visible and not journal.button_pressed and city.core.commands.is_empty(),label+": closing filtered history returns input without answering an event")
	var hazard: Node = city.hazard_rail
	hazard.set_process(false)
	var fixtures := []
	var id := 900200
	for kind in ["fire","collapse","earthquake","sinkLand","tidalWave","lavaFlow","plague","invasion","monsterInvasion1","godInvasion","riskWarning","godVisit","heroArrival","armyReturns"]:
		fixtures.append({"id":id,"kind":kind,"at":[10,12]}); id+=1
	hazard.observe(fixtures); await frames(24)
	var scroll: ScrollContainer = hud.get_node("%AlertScroll")
	check(hazard.buttons.size()==14 and scroll.get_v_scroll_bar().max_value>scroll.get_v_scroll_bar().page and screen.encloses(rail.get_global_rect()),label+": all native alert groups fit in a bounded scrolling rail")
	scroll.scroll_vertical=100000; await frames()
	check(scroll.get_global_rect().grow(1).encloses(hazard.buttons.army.get_global_rect()),label+": the last overflow alert is reachable")
	var remaining: float = hazard.alerts.fire[0].left
	hazard._process(1)
	check(hazard.alerts.fire[0].left==remaining,label+": clipped overflow alerts retain their reading time")
	hazard.buttons.army.grab_focus()
	remaining=hazard.alerts.army[0].left; hazard._process(1)
	check(hazard.alerts.army[0].left==remaining and hud._header_has_focus(),label+": focused alert holds its timer and camera keys during keyboard navigation")
	hazard.buttons.army.release_focus()
	await capture(label+"-alerts")
	hazard.clear(); hazard.set_process(true); scroll.scroll_vertical=0; await frames()
	check(not scroll.visible and screen.encloses(rail.get_global_rect()),label+": clearing alerts returns the rail to the compact utility icons")

func run_army_native(source: String, fixture: String) -> void:
	# Separate, explicitly requested branch: native orders mutate only the unsaved disposable city in memory.
	var before: Dictionary = city.core.simulation.snapshot(true)
	print("CHROME_ARMY_BASELINE ", JSON.stringify({"time":before.time, "money":before.money, "buildings":before.buildings.size(), "companies":city.banners.size()}))
	city.hud._release_header_focus()
	city.hud._release_toolbar_focus()
	city.close_inspection()
	city.army_panel.close()
	city.core.commands.clear()
	city.set_process(true)
	city.core.set_process(true)
	# Load after the project's autoloads exist; --check-only does not register GameAudio for this older validator.
	var validator = load("res://scripts/validate_main.gd").new()
	validator.city = city
	var passed: bool = await validator.run_army_checks()
	city.core.query("pause 1")
	city.core.set_process(false)
	city.set_process(false)
	city.game_action("army")
	if not city.banners.is_empty(): city.army_panel.select(int(city.banners[0].id))
	await frames(16)
	await capture("army-native")
	var after: Dictionary = city.core.simulation.snapshot(true)
	passed = passed and before.time == after.time and before.money == after.money and before.buildings == after.buildings and FileAccess.get_sha256(fixture) == FileAccess.get_sha256(source)
	print("CHROME_ARMY_NATIVE ", "PASS" if passed else "FAIL", " validator=run_army_checks; saved city unchanged; native orders ran only on scratch memory")
	quit(0 if passed else 1)

func run_notifications_fixture() -> void:
	# Actual HUD/notice widgets and GUI input, with synthetic reports and a callback sink.
	# This focused visual gate never starts or changes a native city.
	load("res://scripts/ui_text.gd").set_language(language)
	DisplayServer.window_set_title("Instant notices • owned review")
	DisplayServer.window_set_size(Vector2i(1920,1080))
	city = NoticeReviewHost.new()
	root.add_child(city)
	var backdrop := ColorRect.new()
	backdrop.color = Color(.18,.23,.20)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	city.add_child(backdrop)
	city.hud = load("res://ui/hud.tscn").instantiate()
	city.add_child(city.hud)
	city.hud.set_city_header({"name":"Atlantis"})
	city.hud.set_status([15,12,-3492],997163,795)
	city.hud.set_paused(true)
	city.hud.message_dismissed.connect(func(id): city.core.commands.append("event %d -1" % id))
	for dimensions in [Vector2i(1920,1080),Vector2i(1280,720)]:
		DisplayServer.window_set_size(dimensions)
		for sizing in [Vector2i(100,100),Vector2i(125,130)]:
			root.get_node("UiAccess").apply(sizing.x,sizing.y)
			await frames(24)
			await notification_checks("%d-%d" % [dimensions.x,sizing.x])
	check(city.core.commands.is_empty() and city.state.paused, "focused HUD fixture discards all synthetic callbacks and preserves its pause state")
	print("CHROME_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	quit(0 if okay else 1)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="): language = arg.get_slice("=", 1)
		elif arg == "--army-native": army_native = true
		elif arg == "--notifications-only": notifications_only = true
	Engine.set_meta("ezeus_language", language)
	if notifications_only:
		await run_notifications_fixture()
		return
	Leaders.create("Chrome Review")
	Leaders.set_current("Chrome Review")
	# A previous unversioned folded setting adopts the user's new open default.
	load("res://scripts/user_settings.gd").set_value("interface", "minimap_visible", false)
	var source := ProjectSettings.globalize_path("res://../Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez").simplify_path()
	var fixture := Saves.directory().path_join("chrome review.ez")
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
	var before: Dictionary = city.core.simulation.snapshot(true)
	var header: Dictionary = before.city_header
	var hud: Control = city.hud
	hud.set_goals(city.core.query("episode"))
	hud.set_status(before.date, int(before.money), int(before.population))
	hud.set_city_header(header)
	hud.set_paused(bool(before.paused))
	hud.set_speed(int(before.speed))
	city.state.paused = bool(before.paused)
	await frames(20)
	print("CHROME_NATIVE_STATS ", JSON.stringify({"city":header.get("name", ""), "date":before.date, "time":before.time, "treasury":before.money, "population":before.population, "housing":header.get("housing", {}), "employment":header.get("employment", {}), "popularity":header.get("popularity", -1), "monthly_balance":hud.monthly_balance(header.get("finances", {}), before.date), "building_records":before.buildings.size(), "actual_tiles":city.tiles.size()}))
	native_values(before)
	check(HEADER_CAPTIONS.keys().all(func(name): return not hud.get_node("%" + name).visible), "all seven requested header titles are removed from the visible layout")
	check(hud.get_node("%ResourcesToggle").text.contains(tr("Resources")) and hud.get_node("%ResourcesToggle").icon != null, "resource disclosure uses a readable translated name and its storage icon")
	check(Objective.number(12345) == ("12 345" if language == "ru" else "12,345") and hud.get_node("%InspectorScroll").follow_focus and hud.get_node("%MessageScroll").follow_focus, "objective counts follow locale while inspector and journal scrolling follow keyboard focus")
	check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible, "stock disclosure starts folded for the scratch profile")
	check(hud.get_node("%MinimapPanel").visible and hud.get_node("%MapToggle").button_pressed and not hud.get_node("%MapPeek").visible and hud.preferred_minimap_open() and not hud.get_node("%MapToggle").visible, "map starts visible and adopts the new default over old unversioned folded preferences without the removed corner shortcut")
	await click(hud.get_node("%MapClose"))
	check(not hud.get_node("%MinimapPanel").visible and not hud.get_node("%MapPeek").visible and not hud.preferred_minimap_open() and hud.get_node("%MapToggle").visible, "map fold uses real input and remembers the explicit choice without restoring the corner shortcut")
	await click(hud.get_node("%MapToggle"))
	check(hud.get_node("%MinimapPanel").visible and hud.preferred_minimap_open() and city.core.commands.is_empty(), "corner button reopens the map and remembers the choice without a native command")
	check(hud.speed_buttons.size() == 4, "all four native speed indices remain available")
	var base_income_font: int = hud.get_node("%Income").get_theme_font_size("font_size")
	var base_speed_font: int = hud.speed_buttons[0].get_theme_font_size("font_size")
	# These use actual GUI callbacks; each queued command is inspected, then discarded without execution.
	# The opposite pause presentation is a local fixture; the frozen core remains at its actual paused baseline.
	city.state.paused = true
	hud.set_paused(true)
	await click(hud.pause_button)
	check(city.core.commands == ["pause 0"], "Resume queues only the original native pause-zero callback")
	city.core.commands.clear()
	city.state.paused = false
	hud.set_paused(false)
	await click(hud.pause_button)
	check(city.core.commands == ["pause 1"], "Pause queues only the original native pause-one callback")
	city.core.commands.clear()
	city.state.paused = bool(before.paused)
	hud.set_paused(bool(before.paused))
	check(hud.pause_button.tooltip_text.contains(Bindings.label("pause")), "pause hover text retains the configured shortcut")
	for index in 4:
		await click(hud.speed_buttons[index])
		check(city.core.commands == ["speed %d" % index], "speed control %d preserves its native index %d" % [index + 1, index])
		city.core.commands.clear()
	hud.set_speed(int(before.speed))
	check(hud.speed_buttons[int(before.speed)].button_pressed and hud.speed_buttons.filter(func(button): return button.button_pressed).size() == 1, "chosen speed restores the exact native setting with a single marker")
	check(hud.speed_buttons.all(func(button): return not button.tooltip_text.is_empty()), "every native speed control has translated hover text")
	bounds("1920 × 1080 default")
	await capture("overview")
	# Treasury sign is a presentation fixture; its color must remain independent of the native monthly balance.
	var income_text: String = hud.get_node("%Income").text
	var income_color: Color = hud.get_node("%Income").get_theme_color("font_color")
	hud.set_status(before.date, -4250, int(before.population))
	hud.set_city_header(header)
	check(hud.treasury_label.text == "−" + hud.group_digits(4250) and hud.treasury_label.get_theme_color("font_color").is_equal_approx(hud.INCOME_DOWN), "negative treasury has its exact signed amount and debt color")
	check(hud.get_node("%Income").text == income_text and hud.get_node("%Income").get_theme_color("font_color").is_equal_approx(income_color), "treasury debt styling does not change the native monthly balance or its sign color")
	await capture("negative-treasury-fixture")
	hud.set_status(before.date, 4250, int(before.population))
	hud.set_city_header(header)
	check(not hud.treasury_label.get_theme_color("font_color").is_equal_approx(hud.INCOME_DOWN) and hud.get_node("%Income").text == income_text, "positive treasury remains independent of the native monthly balance sign")
	hud.set_status(before.date, int(before.money), int(before.population))
	hud.set_city_header(header)
	await click(hud.get_node("%ResourcesToggle"))
	await create_timer(.3).timeout
	check(hud.resources_open and hud.resources_fraction > .99, "actual resource disclosure callback fully opens the stock panel")
	var stock_ids: Array = header.stock.map(func(stock): return int(stock.resource))
	check(stock_ids.size() == 24 and range(23).all(func(bit): return stock_ids.has(1 << bit)) and stock_ids.has(255), "native cached stocks retain all 23 resource types through silver and the food total")
	check_world_stocks(before)
	# Header keyboard ownership intentionally holds the camera while stocks are being browsed.
	hud.set_resources_open(false)
	await create_timer(.3).timeout
	hud.get_node("%ResourcesToggle").grab_focus()
	await key(KEY_ENTER)
	await create_timer(.3).timeout
	check(hud.resources_open and hud._header_has_focus() and city.orbit.toolbar_input_blocked, "keyboard Resources activation opens stocks while retaining header navigation ownership")
	var camera_target: Vector3 = city.orbit.target
	var camera_distance: float = city.orbit.distance
	await key(KEY_HOME)
	check(city.orbit.target == camera_target and city.orbit.distance == camera_distance, "Home respects header ownership without changing the camera")
	var queue_before: Array = city.core.commands.duplicate()
	await key(KEY_ESCAPE)
	await create_timer(.3).timeout
	check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible and not hud._header_has_focus() and not city.orbit.toolbar_input_blocked and city.core.commands == queue_before, "Escape folds keyboard-opened stocks and releases camera focus without a pause or save callback")
	hud.get_node("%ResourcesToggle").grab_focus()
	await key(KEY_ENTER)
	await create_timer(.3).timeout
	var back := InputEventMouseButton.new()
	back.position = hud.get_node("%ResourcesToggle").get_global_rect().get_center()
	back.button_index = MOUSE_BUTTON_RIGHT
	back.pressed = true
	back.set_meta("review_input", true)
	root.push_input(back, true)
	await create_timer(.3).timeout
	check(not hud.resources_open and not hud._header_has_focus() and not city.orbit.toolbar_input_blocked and city.core.commands == queue_before, "right-click folds keyboard-opened stocks and returns camera ownership without a native command")
	hud.pause_button.grab_focus()
	await frames()
	check(hud._header_has_focus() and city.orbit.toolbar_input_blocked, "keyboard Pause focus protects the camera while navigating the header")
	await key(KEY_ESCAPE)
	check(not hud._header_has_focus() and not city.orbit.toolbar_input_blocked and city.core.commands == queue_before, "Escape from focused Pause returns input to the city without triggering Pause")
	hud.get_node("%Jobs").grab_focus()
	await frames()
	await click(hud.get_node("%Jobs"))
	check(hud.current_overlay == "industry" and city.overlay_view.mode == "industry" and not hud._header_has_focus() and not city.orbit.toolbar_input_blocked, "mouse Jobs selection retains the native industry view and returns camera input to the city")
	hud.activate_overlay("normal")
	city.core.commands.clear()
	hud.set_resources_open(true)
	await create_timer(.3).timeout
	hud.resource_buttons[255].grab_focus()
	await frames()
	await click(hud.resource_buttons[255])
	check(hud.current_overlay == "supplies" and city.overlay_view.mode == "supplies" and not hud._header_has_focus() and not city.orbit.toolbar_input_blocked, "mouse food-stock selection retains the native supplies view and releases header ownership")
	hud.activate_overlay("normal")
	city.core.commands.clear()
	bounds("1920 × 1080 resources")
	await capture("resources")
	var inspectors: Array = before.buildings.filter(func(building): return str(building.asset) == "warehouse")
	var inspector_building: Dictionary = inspectors[0] if not inspectors.is_empty() else {}
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		DisplayServer.window_set_size(dimensions)
		for sizing in [Vector2i(100, 100), Vector2i(125, 130)]:
			root.get_node("UiAccess").apply(sizing.x, sizing.y)
			await frames(24)
			bounds(str(dimensions) + " " + str(sizing))
			if sizing.y > 100:
				check(hud.get_node("%Income").get_theme_font_size("font_size") > base_income_font and hud.speed_buttons[0].get_theme_font_size("font_size") > base_speed_font, str(dimensions) + ": income and speed text respect the independent text-size preference")
			await capture("%d-%d-resources" % [dimensions.x, sizing.x])
			await click(hud.get_node("%ResourcesToggle"))
			await create_timer(.3).timeout
			check(not hud.resources_open and not hud.get_node("%ResourcesReveal").visible, str(dimensions) + " " + str(sizing) + ": stock disclosure folds and releases its space")
			bounds(str(dimensions) + " " + str(sizing) + " folded")
			await capture("%d-%d-overview" % [dimensions.x, sizing.x])
			await panel_checks("%d-%d" % [dimensions.x, sizing.x], inspector_building)
			await notification_checks("%d-%d" % [dimensions.x, sizing.x])
			await hub_checks("%d-%d" % [dimensions.x, sizing.x])
			hud.set_resources_open(true)
			await create_timer(.3).timeout
	root.get_node("UiAccess").apply(100, 100)
	hud.set_resources_open(false)
	await create_timer(.3).timeout
	native_values(before)
	var after: Dictionary = city.core.simulation.snapshot(true)
	check(before.time == after.time and before.money == after.money and before.population == after.population and before.buildings == after.buildings and before.city_header == after.city_header and before.paused == after.paused and before.speed == after.speed, "queued-only time callbacks, stock disclosure and scaling leave all native observations unchanged")
	check(city.core.commands.is_empty(), "no reviewed presentation callback remains queued for later execution")
	check(FileAccess.get_sha256(fixture) == FileAccess.get_sha256(source), "copied saved city is never written during the review")
	print("CHROME_VALIDATION ", "PASS" if okay else "FAIL", " checks=", checks)
	if army_native and okay:
		await run_army_native(source, fixture)
		return
	quit(0 if okay else 1)
